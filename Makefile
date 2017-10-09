talk.html: README.md impl.ml SortedList.class
	jbuilder build @install && pandoc -t revealjs --smart --highlight-style zenburn -s -o $@ $<

SortedList.class: SortedList.java
	javac SortedList.java
