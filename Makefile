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
	source env/bin/activate
	pip3 install -Ur tests/requirements.txt

tests/bash_unit:
	curl -s https://raw.githubusercontent.com/pgrange/bash_unit/master/bash_unit -o tests/bash_unit
	chmod +x tests/bash_unit

.PHONY: test_py
test_py: env
	source env/bin/activate
	python3 -m pytest tests/

.PHONY: test_sh
test_sh: tests/bash_unit
	tests/bash_unit tests/test_ft.sh

.PHONY: test
test: test_py test_sh

.PHONY: clean
clean:
	rm -f tests/bash_unit