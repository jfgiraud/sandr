.ONESHELL:
SHELL=bash

.PHONY: usage
usage:
	echo $$DOCKER_USER
	@cat - <<EOF
		Targets:
		* test: run all tests (you must be inside the container)
	EOF

.PHONY: test
test:
	tests/bash_unit tests/validate.sh
