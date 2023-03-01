DESTDIR ?= /usr/local
REPOSITORY_NAME ?= sandr
SCRIPTS = sandr
GENERATED_FILES = doc/generated/man/man1/sandr.1 doc/generated/txt/sandr.1.txt doc/generated/md/sandr.md
VERSION ?= $(shell cat doc/VERSION)
FILE_VERSION ?= $(shell cat doc/VERSION)
TESTS = tests/test_ft.sh tests/test_ut.py


.ONESHELL:
SHELL=bash

.PHONY: usage
usage:
	@cat - <<EOF
		Targets:
		* install: install scripts in /usr/local/bin (you must call this target with sudo)
		* uninstall: remove scripts from /usr/local/bin
		* test: run all tests
		* archive: create a tgz (used in github pipeline for release)
		* commit-release VERSION=X.Y.Z: commit files and create a release
		* update-doc: update man pages and usages
		* update-version VERSION=X.Y.Z: update man pages and usages
		* install-dependencies: install dependencies (you must call this target with sudo)
	EOF

.PHONY: install-dependencies
install-dependencies:
	apt install asciidoctor
	apt install pandoc

/usr/bin/asciidoctor:
	echo "You must install dependencies."
	echo "sudo make install-dependencies"

doc/generated/man/man1/%.1: doc/%.adoc doc/VERSION
	@echo "Create $@"
	@asciidoctor -b manpage -a release-version="$(VERSION)" $< -o $@

doc/generated/md/%.md: doc/%.adoc doc/VERSION
	@echo "Create $@"
	@SCRIPT=$(shell basename "$@" | sed 's/\..*//')
	@asciidoctor -b docbook doc/$$SCRIPT.adoc -o doc/generated/md/$$SCRIPT.xml
	@pandoc -t gfm+footnotes -f docbook -t markdown_strict doc/generated/md/$$SCRIPT.xml -o doc/generated/md/$$SCRIPT.md
	@rm -f doc/generated/md/$$SCRIPT.xml

doc/generated/txt/%.1.txt: doc/generated/man/man1/%.1 doc/VERSION
	@echo "Create $@"
	@man -l $< | sed -e 's#\\#\\\\#g' > $@
	@SCRIPT=$(shell basename "$@" | sed 's/\..*//')
	@echo "Rewrite usage in $$SCRIPT"
	@awk -i inplace -v input="$@" 'BEGIN { p = 1 } /#BEGIN_DO_NOT_MODIFY:make update-doc/{ print; p = 0; while(getline line<input){print line} } /#END_DO_NOT_MODIFY:make update-doc/{ p = 1 } p' bin/$$SCRIPT

README.md: doc/generated/md/readme.md
	@echo "Move to README.md"
	@mv -f doc/generated/md/readme.md README.md

.PHONY: update-version
update-version:
	[[ "$(VERSION)" == "$(FILE_VERSION)" ]] && echo "Change version number! (make update-version VERSION=X.Y.Z)" && exit 1
	@echo "Modify version in doc/VERSION"
	@echo "$(VERSION)" > doc/VERSION
	make update-doc

.PHONY: update-doc
update-doc: $(GENERATED_FILES) README.md

.PHONY: commit-release
commit-release: update-version
	@echo "Update documentation"
	make update-doc
	@echo "Commit release $$VERSION"
	git add -u .
	git commit -m "Commit for creating tag v$$VERSION"
	git push
	git tag "v$$VERSION" -m "Tag v$$VERSION"
	git push --tags

$(REPOSITORY_NAME).tar.gz: $(REPOSITORY_NAME).tar
	@echo "Compress archive $@"
	@gzip -f $<

$(REPOSITORY_NAME).tar: update-doc
	@echo "Create archive $@"
	@tar cf $(REPOSITORY_NAME).tar --exclude=__pycache__ bin/*
	@tar rf $(REPOSITORY_NAME).tar LICENSE --transform 's,^,share/doc/$(REPOSITORY_NAME)/,'
	@tar rf $(REPOSITORY_NAME).tar doc/generated/man/man1/*.1 --transform 's,^doc/generated/,,'

.PHONY: archive
archive: $(REPOSITORY_NAME).tar.gz

.PHONY: install
install: $(REPOSITORY_NAME).tar.gz
	@echo "Install software to $(DESTDIR)"
	tar zxvf $(REPOSITORY_NAME).tar.gz -C $(DESTDIR)

.PHONY: uninstall
uninstall:
	@echo "Uninstall software from $(DESTDIR)"
	@for script in $(SCRIPTS); do
	@	rm -f $(DESTDIR)/bin/$$script $(DESTDIR)/man/man1/$$script.1
	@done
	@rm -rf $(DESTDIR)/share/doc/$(REPOSITORY_NAME)/

.pip_cache: venv/bin/activate
	source venv/bin/activate
	mkdir -p .pip_cache
	python -m pip download -r tests/requirements.txt -d .pip_cache

venv/bin/activate:
	test -d venv || python3 -m venv venv

tests/bash_unit:
	curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/bash_unit -o tests/bash_unit
	chmod +x tests/bash_unit

tests/%.sh: tests/bash_unit
	@echo "Run $@"
	@tests/bash_unit $@

tests/%.py: .pip_cache
	@echo "Run $@"
	@source venv/bin/activate
	@python -m pip install --no-index --find-links .pip_cache -r tests/requirements.txt
	@python3 -m pytest $@

.PHONY: test
test:
	@echo "Run tests"
	@for t in $(TESTS); do
	@echo "Run $$t"
	@	make $$t
	@done

.PHONY: clean
clean:
	@echo "Clean files"
	@rm -f $(REPOSITORY_NAME).tar.gz
	rm -rf tests/bash_unit .pip_cache *.whl env venv