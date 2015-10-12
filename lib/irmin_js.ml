(* Copyright (C) 2015, Thomas Leonard.
   See the README file for details. *)

(** Implements Irmin_js_api. *)

open Lwt
open Irmin_js_api

let lwt_of_js_promise p =
  match Js.typeof p |> Js.to_string with
  | "object" ->
      let lwt : _ Lwt.t Js.Optdef.t = Js.Unsafe.get p (Js.string "lwtThread") in
      Js.Optdef.get lwt (fun () -> failwith "Not an irmin-js promise!")
  | "undefined" ->
      return (Obj.magic ())
  | ty -> failwith (Printf.sprintf "callback should return a promise object, not %S" ty)

(** Wrap an Lwt promise to provide a Javascript promise object. *)
let rec js_promise_of (type a) (t:a Lwt.t) : a promise Js.t =
  let and_then cb =
    js_promise_of begin
      t >>= fun v ->
      Js.Unsafe.fun_call cb [| Js.Unsafe.inject v |] |> lwt_of_js_promise
    end in
  let to_string () =
    let state =
      match Lwt.state t with
      | Sleep -> "unresolved"
      | Fail ex -> Printexc.to_string ex
      | Return _ -> "ok" in
    Js.string (Printf.sprintf "<promise:%s>" state) in
  let promise = Js.Unsafe.obj [||] in
  promise##lwtThread <- t;
  let promise = (promise :> a promise Js.t) in
  promise##_then <- Js.wrap_callback and_then |> Obj.magic;
  promise##toString <- Js.wrap_callback to_string;
  promise

let id_task t = t

let commit_metadata owner msg =
  let owner = Js.to_string owner in
  let msg = Js.to_string msg in
  let date = Unix.gettimeofday () |> Int64.of_float in
  Irmin.Task.create ~date ~owner msg

(* Irmin currently requires commit metadata for all operations, but it's only
   used for writes. For reads, we use this dummy value. *)
let dummy_msg =
  Irmin.Task.create ~date:0L ~owner:"irmin-js" "unused"

let key_of_js arr =
  Js.to_array arr |> Array.to_list |> List.map Js.to_string

let key_to_js segs =
  segs |> List.map Js.string |> Array.of_list |> Js.array

module Repo (Store : Irmin.BASIC with type key = string list and type value = string) = struct
  module View = Irmin.View(Store)

  let read store key =
    js_promise_of begin
      let key = key_of_js key in
      Store.read (store dummy_msg) key >|= function
      | None -> Js.Opt.empty
      | Some value -> Js.Opt.return (Js.string value)
    end

  let list store path =
    js_promise_of begin
      Store.list (store dummy_msg) (key_of_js path) >|= fun keys ->
      keys |> List.map key_to_js |> Array.of_list |> Js.array
    end

  let commit repo hash =
    let str_hash = Irmin.Hash.SHA1.to_hum hash in
    Store.of_commit_id id_task hash repo >>= fun store ->
    let c : commit Js.t = Js.Unsafe.obj [||] in
    c##hash <- Js.string str_hash;
    c##toString <- Js.wrap_callback (fun () -> Printf.sprintf "<commit %S>" str_hash |> Js.string);
    c##read <- Js.wrap_callback (read store);
    c##list <- Js.wrap_callback (list store);
    return c

  let wrap_view v =
    let view : view Js.t = Js.Unsafe.obj [||] in
    let update key value =
      js_promise_of begin
        let key = key_of_js key in
        let value = Js.to_string value in
        View.update v key value
      end in
    let read key =
      js_promise_of begin
        let key = key_of_js key in
        View.read v key >|= function
        | None -> Js.Opt.empty
        | Some value -> Js.Opt.return (Js.string value)
      end in
    let list path =
      js_promise_of begin
        View.list v (key_of_js path) >|= fun keys ->
        keys |> List.map key_to_js |> Array.of_list |> Js.array
      end in
    view##toString <- Js.wrap_callback (fun () -> Js.string "<view>");
    view##update <- Js.wrap_callback update;
    view##read <- Js.wrap_callback read;
    view##list <- Js.wrap_callback list;
    view

  let with_merge_view store metadata key cb =
    let key = key_of_js key in
    js_promise_of begin
      Irmin.with_hrw_view (module View) (store metadata) ~path:key `Merge (fun v ->
        let view = wrap_view v in
        Js.Unsafe.fun_call cb [| Js.Unsafe.inject view |] |> lwt_of_js_promise
      ) >|= function
      | `Ok () -> Js.Opt.empty
      | `Conflict msg -> Js.Opt.return (Js.string msg)
    end

  let branch repo name =
    js_promise_of begin
      let name = Js.to_string name in
      Store.of_branch_id id_task name repo >>= fun store ->
      let b : branch Js.t = Js.Unsafe.obj [||] in
      let head () =
        js_promise_of begin
          Store.head (store dummy_msg) >>= function
          | None -> return Js.Opt.empty
          | Some hash ->
              commit repo hash >|= Js.Opt.return
        end in
      let update task key value =
        js_promise_of begin
          let key = key_of_js key in
          let value = Js.to_string value in
          Store.update (store task) key value
        end in
      b##head <- Js.wrap_callback head;
      b##toString <- Js.wrap_callback (fun () -> Printf.sprintf "<branch %S>" name |> Js.string);
      b##update <- Js.wrap_callback update;
      b##read <- Js.wrap_callback (read store);
      b##list <- Js.wrap_callback (list store);
      b##withMergeView <- Js.wrap_callback (with_merge_view store);
      return b
    end

  let repo s =
    let repo : repo Js.t = Js.Unsafe.obj [||] in
    repo##branch <- Js.wrap_callback (branch s);
    repo##toString <- Js.wrap_callback (fun () -> Js.string "<repo>");
    return repo
end

let mem_repo () = js_promise_of begin
    let module Store = Irmin_mem.Make(Irmin.Contents.String)(Irmin.Ref.String)(Irmin.Hash.SHA1) in
    let module R = Repo(Store) in
    let config = Irmin_mem.config () in
    Store.Repo.create config >>= R.repo
  end

let idb_repo name = js_promise_of begin
    let module Store = Irmin_IDB.Make(Irmin.Contents.String)(Irmin.Ref.String)(Irmin.Hash.SHA1) in
    let module R = Repo(Store) in
    let config = Irmin_IDB.config (Js.to_string name) in
    Store.Repo.create config >>= R.repo
  end

let resolve x = js_promise_of (return x)

let () =
  let irmin : irmin Js.t = Js.Unsafe.obj [||] in
  irmin##resolve <- Js.wrap_callback resolve;
  irmin##memRepo <- Js.wrap_callback mem_repo;
  irmin##idbRepo <- Js.wrap_callback idb_repo;
  irmin##commitMetadata <- Js.wrap_callback commit_metadata;
  Js.Unsafe.global##irmin <- irmin;
