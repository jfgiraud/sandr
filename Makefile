.ONESHELL:
SHELL=bash

.PHONY: usage
usage:
	echo $$DOCKER_USER
	@cat - <<EOF
		Targets:
		* test: run all tests (you must be inside the container)
	EOF

env: tests/requirements.txt
	test -d env || python3 -m venv env
	env/bin/pip3 install -Ur tests/requirements.txt

.PHONY: test_py
test_py: env
	env/bin/python3 -m pytest tests/unit_tests.py

.PHONY: test_sh
test_sh:
	tests/bash_unit tests/functional_tests.sh

.PHONY: test
test: test_py test_sh