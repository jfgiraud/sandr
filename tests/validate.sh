#!/bin/bash

function check_programs() {
  for program in "cat"; do
    if ! which $program > /dev/null; then
      fail "program '$program' is not installed"
    fi
  done
}

function teardown_suite() {
  :
}

function setup_suite() {
  check_programs
  export ROOTDIR=$(readlink -f ..)
}

function setup() {
  :
}

function test_substitution() {
  actual=$(echo "Hello Jeff" | $ROOTDIR/bin/sandr -s 'Hello' -r 'Bonjour')
  assert_equals "Bonjour Jeff" "$actual" "bad substitution"
}

function test_substitution_ignoring_case() {
  actual=$(echo "Hello Jeff" | $ROOTDIR/bin/sandr -i -s 'hello' -r 'Bonjour')
  assert_equals "Bonjour Jeff" "$actual" "bad substitution"
}