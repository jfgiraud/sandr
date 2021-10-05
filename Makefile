.ONESHELL:
SHELL=bash

.PHONY: usage
usage:
	@cat - <<EOF
		Targets:
		* test: run all tests
	EOF

env: tests/requirements.txt
	test -d env || python3 -m venv env
	env/bin/pip3 install -Ur tests/requirements.txt

.PHONY: test_py
test_py: env
	env/bin/python3 -m pytest tests/

.PHONY: test_sh
test_sh:
	curl https://raw.githubusercontent.com/pgrange/bash_unit/master/bash_unit -o tests/bash_unit
	tests/bash_unit tests/test_ft.sh

.PHONY: test
test: test_py test_sh