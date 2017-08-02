PREFIX ?= /usr

all:

install: install-files install-doc

install-files: $(PREFIX)/bin/git-sequencer-status

install-doc: $(PREFIX)/share/man/man1/git-sequencer-status.1

$(PREFIX)/share/man/man1/%: doc/%
	@mkdir -p $$(dirname $@)
	install -m 0644 $< $@

$(PREFIX)/bin/git-sequencer-status: sequencer-status
	@mkdir -p $$(dirname $@)
	install -m 0755 $< $@

doc: doc/git-sequencer-status.1

doc/%.1: doc/%.xml
	xmlto -o $$(dirname $@) man $<
doc/git-sequencer-status.xml: doc/git-sequencer-status.txt
	asciidoc -b docbook -d manpage -o $@ $<

clean:
	rm -f doc/*.xml doc/*.1
