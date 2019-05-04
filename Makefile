# -*- Makefile -*-

# --------------------------------------------------------------------
.PHONY: all merlin build build-deps run clean

# --------------------------------------------------------------------
all: build merlin

build: plugin archetypeLib compiler

compiler:
	$(MAKE) -C src compiler.exe
	cp -f src/_build/default/compiler.exe .

archetypeLib:
	$(MAKE) -C src archetypeLib
	cp -f src/_build/default/archetypeLib.* .

plugin:
	$(MAKE) -C src archetypeLib plugin
	cp -f src/_build/default/archetype.cmxs ./why3/

extract:
	$(MAKE) -C src/liq extract.exe

merlin:
	$(MAKE) -C src merlin

run:
	$(MAKE) -C src run

clean:
	$(MAKE) -C src clean
	rm -fr compiler.exe archetypeLib.*
	rm -fr ./why3/plugin/archetype.cmxa

check:
	./check_pp.sh

build-deps:
	opam install dune menhir why3.1.2.0 ppx_deriving ppx_deriving_yojson

dev-package:
	opam install tuareg merlin ocp-indent
