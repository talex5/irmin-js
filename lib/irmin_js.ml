open Lwt

type 'a export = (unit, 'a) Js.meth_callback Js.writeonly_prop

type js_string = Js.js_string Js.t

class type printable = object
  method toString : (unit -> js_string) export
end

class type ['a] promise = object
  inherit printable
  method _then : (('a -> 'b promise Js.t) -> 'b promise Js.t) export
end

type 'a p = 'a promise Js.t

type 'a js_opt = 'a Js.Opt.t

class type branch = object
  inherit printable
  method head : (unit -> js_string js_opt p) export
  method update : (js_string -> js_string -> unit p) export
  method read : (js_string -> js_string js_opt p) export
end

class type repo = object
  inherit printable
  method branch : (js_string -> branch Js.t p) export
end

let rec js_promise_of (type a) (t:a Lwt.t) : a p =
  let and_then (cb : a -> 'b p) : 'b p =
    js_promise_of (t >>= fun v -> Js.Unsafe.fun_call cb [| Js.Unsafe.inject v |]) in
  let to_string () =
    Js.string "<promise>" in
  let promise : a p = Js.Unsafe.obj [||] in
  promise##_then <- Js.wrap_callback and_then |> Obj.magic;
  promise##toString <- Js.wrap_callback to_string;
  promise

let task msg =
  let date = Unix.gettimeofday () |> Int64.of_float in
  Irmin.Task.create ~date ~owner:"irmin_js" msg

module Repo (Store : Irmin.BASIC with type key = string list and type value = string) = struct
  let key_of_js k = [Js.to_string k] (* TODO: use paths *)

  let branch config name =
    js_promise_of begin
      let name = Js.to_string name in
      Store.of_tag config task name >>= fun store ->
      let b : branch Js.t = Js.Unsafe.obj [||] in
      let head () =
        js_promise_of begin
          Store.head (store "head") >|= function
          | None -> Js.Opt.empty
          | Some head -> Js.Opt.return (Js.string (Irmin.Hash.SHA1.to_hum head))
        end in
      let read key =
        js_promise_of begin
          let key = key_of_js key in
          Store.read (store "update") key >|= function
          | None -> Js.Opt.empty
          | Some value -> Js.Opt.return (Js.string value)
        end in
      let update key value =
        js_promise_of begin
          let key = key_of_js key in
          let value = Js.to_string value in
          Store.update (store "update") key value
        end in
      b##head <- Js.wrap_callback head;
      b##toString <- Js.wrap_callback (fun () -> Printf.sprintf "<branch %S>" name |> Js.string);
      b##update <- Js.wrap_callback update;
      b##read <- Js.wrap_callback read;
      return b
    end

  let repo s =
    let repo : repo Js.t = Js.Unsafe.obj [||] in
    repo##branch <- Js.wrap_callback (branch s);
    repo##toString <- Js.wrap_callback (fun () -> Js.string "<repo>");
    return repo
end

let mem_repo () = js_promise_of begin
    let module Store = Irmin.Basic(Irmin_mem.Make)(Irmin.Contents.String) in
    let module R = Repo(Store) in
    let config = Irmin_mem.config () in
    R.repo config
  end

let () =
  Js.Unsafe.global##irmin <-
    Js.Unsafe.obj [|
      ("mem_repo", Js.Unsafe.inject (Js.wrap_meth_callback mem_repo));
    |]
