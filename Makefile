# make JFLAGS="--pretty --noinline"
JFLAGS =

# Let ocamlbuild figure out the build dependencies
.PHONY: irmin_js

all: test
	
test: _build/lib/irmin_js.js
	if [ -f /usr/bin/nodejs ]; then nodejs examples/node.js; else node examples/node.js; fi

_build/lib/irmin_js.js: irmin_js
	js_of_ocaml ${JFLAGS} +weak.js lib/helpers.js _build/lib/irmin_js.byte -o "$@"

irmin_js:
	ocamlbuild -use-ocamlfind -no-links lib/irmin_js.byte

clean:
	rm -rf _build
