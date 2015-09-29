## Irmin

[Irmin][] provides a Git-like API for data-storage.
It can be compiled to Javascript using [js_of_ocaml][] and run in the browser, using IndexedDB for local storage, which can be used offline and later sync'd with a remote server.
See [CueKeeper][] for an example of an application using Irmin.

`irmin-js` makes Irmin available as a regular Javascript library (without requiring your application to be written in OCaml).
It can be used client-side in the browser, or server-side with Node.js.



### Conditions

Copyright (c) 2015 Thomas Leonard <talex5@gmail.com>

Permission to use, copy, modify, and distribute this software for any
purpose with or without fee is hereby granted, provided that the above
copyright notice and this permission notice appear in all copies.

THE SOFTWARE IS PROVIDED "AS IS" AND THE AUTHOR DISCLAIMS ALL WARRANTIES
WITH REGARD TO THIS SOFTWARE INCLUDING ALL IMPLIED WARRANTIES OF
MERCHANTABILITY AND FITNESS. IN NO EVENT SHALL THE AUTHOR BE LIABLE FOR
ANY SPECIAL, DIRECT, INDIRECT, OR CONSEQUENTIAL DAMAGES OR ANY DAMAGES
WHATSOEVER RESULTING FROM LOSS OF USE, DATA OR PROFITS, WHETHER IN AN
ACTION OF CONTRACT, NEGLIGENCE OR OTHER TORTIOUS ACTION, ARISING OUT OF
OR IN CONNECTION WITH THE USE OR PERFORMANCE OF THIS SOFTWARE.

[Irmin]: https://github.com/mirage/irmin/
[js_of_ocaml]: http://ocsigen.org/js_of_ocaml/
[CueKeeper]: http://roscidus.com/blog/blog/2015/04/28/cuekeeper-gitting-things-done-in-the-browser/
