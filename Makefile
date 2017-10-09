html := talk.html
ocaml_lib := _build/default/lightweightstaticcapabilities.cma
java_lib := SortedList.class

$(html): README.md $(ocaml_lib) $(java_lib)
	pandoc -t revealjs --smart --highlight-style zenburn -s -o $@ $<

$(ocaml_lib): impl.ml
	jbuilder build @install

$(java_lib): SortedList.java
	javac $<

.PHONY: clean

clean:
	rm -rf _build $(java_lib) $(html)
