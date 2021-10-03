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
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr -s o -r'<o>')
  assert_equals "Hell<o> J<o>hn DOE" "$actual" "bad substitution"
}

function test_substitution_ignoring_case() {
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr -i -s o -r'<o>')
  assert_equals "Hell<o> J<o>hn D<o>E" "$actual" "bad substitution"
}

function test_reuse_case() {
  actual=$(echo "Hello John Doe and Jane DOE" | $ROOTDIR/bin/sandr -i -c -s 'doe' -r 'smith')
  assert_equals "Hello John Smith and Jane SMITH" "$actual" "bad substitution"
}