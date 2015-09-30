(* Copyright (C) 2015, Thomas Leonard.
   See the README file for details. *)

(** Defines the API exposed by this library to its Javascript clients.
    Note that the types are from the perspective of the library: writeonly
    means that the library *provides* the member; from the client's point
    of view the property is read-only. *)

open Js

type 'a export = (unit, 'a) meth_callback writeonly_prop

type commit_metadata = Irmin.task
type path = js_string t js_array t
type value = js_string t
type hash = js_string t
type branch_name = js_string t
type user = js_string t
type mergeConflict = js_string t Opt.t

class type printable = object
  method toString : (unit -> js_string t) export
end

class type ['a] promise = object
  inherit printable

  method _then : (('a -> 'b promise t) -> 'b promise t) export
  (** When this promise resolves, pass the value to the given callback.
   * The callback should return another promise. If you have an immediate value instead,
   * use [irmin.resolve] to turn it into a promise.
   * As a convenience, returning [undefined] automatically uses [irmin.resolve(undefined)]. *)
end

class type commit = object
  inherit printable

  method hash : hash writeonly_prop
  (** Get the hash of the commit. *)

  method read : (path -> value Opt.t promise t) export
  (** Read a file from the head commit. *)
end

class type view = object
  inherit printable

  method read : (path -> value Opt.t promise t) export
  (** Read a file from the view. *)

  method update : (path -> value -> unit promise t) export
  (** Update a file in the view. *)
end

class type branch = object
  inherit printable

  method head : (unit -> commit t Opt.t promise t) export
  (** Get the commit currently at the tip of the branch.
   * [null] if the branch does not exist. *)

  method read : (path -> value Opt.t promise t) export
  (** Read a file from the head commit. *)

  method update : (commit_metadata -> path -> value -> unit promise t) export
  (** Write a file to a new commit and add it to the branch. *)

  method list : (path -> path js_array t promise t) export
  (** List the direct children of [path]. *)

  method withMergeView : (commit_metadata -> path -> (view t -> unit t) -> mergeConflict promise t) export
  (** [withMergeView(msg, path, fn)] creates a view of the tip of the branch and calls the
   * supplied function. When that resolves, the view is merged back into the branch. *)
end

class type repo = object
  inherit printable

  method branch : (branch_name -> branch t promise t) export
  (** Access the named branch, which need not yet exist. *)
end

(** Available as [window.irmin] from Javascript. *)
class type irmin = object
  method memRepo : (unit -> repo t promise t) export
  (** Create a new in-memory Irmin repository. *)

  method idbRepo : (js_string t -> repo t promise t) export
  (** Open (or create) an IndexedDB database with the given name and
   * return an Irmin repository for it. *)

  method commitMetadata : (user -> js_string t -> commit_metadata) export
  (** [commit_metadata user msg] creates commit metadata with the current time and
      the given user and log message. *)

  method resolve : ('a -> 'a promise t) export
  (** Convert an immediate value into a promise (e.g. [promise.then]'s callback needs
   * a promise, but you might just want to return a value you have already. *)
end
