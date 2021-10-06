.ONESHELL:
SHELL=bash

.PHONY: usage
usage:
	@cat - <<EOF
		Targets:
		* test: run all tests
	EOF


.pip_cache: env/bin/activate
	source env/bin/activate
	mkdir -p .pip_cache
	python -m pip download -r tests/requirements.txt -d .pip_cache

env/bin/activate:
	test -d env || python3 -m venv env

tests/bash_unit:
	curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/bash_unit -o tests/bash_unit
	chmod +x tests/bash_unit

.PHONY: test_py
test_py: .pip_cache
	source env/bin/activate
	python -m pip install --no-index --find-links .pip_cache -r tests/requirements.txt
	python3 -m pytest tests/

.PHONY: test_sh
test_sh: tests/bash_unit
	bash -x tests/bash_unit tests/test_ft.sh

.PHONY: test
test: test_py test_sh

.PHONY: clean
clean:
	rm -rf tests/bash_unit .pip_cache *.whl env