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
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr.py -s o -r'<o>')
  assert_equals "Hell<o> J<o>hn DOE" "$actual" "bad substitution"
}

function test_substitution_ignoring_case() {
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr.py -i -s o -r'<o>')
  assert_equals "Hell<o> J<o>hn D<o>E" "$actual" "bad substitution"
}

function test_reuse_case() {
  actual=$(echo "Hello John Doe and Jane DOE" | $ROOTDIR/bin/sandr.py -i -c -s 'doe' -r 'smith')
  assert_equals "Hello John Smith and Jane SMITH" "$actual" "bad substitution"
}

function test_reuse_case_use_regexp() {
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr.py -i -c -S '([aeiouy])' -r'<\1>')
  assert_equals "H<e>ll<o> J<o>hn D<O><E>" "$actual" "bad substitution"
}

function test_extract_map() {
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr.py -e -i -c -S '([aeiouy])' -r'<\1>' | sort | tr '\n' '#')
  assert_equals "e => <e>#E => <E>#o => <o>#O => <O>#" "$actual" "bad substitution"
}

function test_use_map() {
  map=$(mktemp)
  cat > $map <<EOF
Hello => Bonjour
DOE => Durand
EOF
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr.py -a $map)
  assert_equals "Bonjour John Durand" "$actual" "bad substitution"
  rm -f $map
}

function test_simulate_replacements() {
  map=$(mktemp)
  echo 'Hello john doe' > $map
  actual=$($ROOTDIR/bin/sandr.py -t -i -s hello -r bye $map)
  assert_equals "bye john doe" "$actual" "bad substitution"
  rm -f $map
}

function suppress_color() {
  sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
}

function test_use_map_multiline() {
  map=$(mktemp)
  cat > $map <<EOF
a => Ceci est une phrase
| sur 2 lignes
b => Et celle-ci une autre phrase sur une ligne
EOF
  actual=$(echo "ab" | $ROOTDIR/bin/sandr.py -a $map | tr '\n' '#')
  assert_equals "Ceci est une phrase#sur 2 lignesEt celle-ci une autre phrase sur une ligne#" "$actual" "bad substitution"
  rm -f $map
}

function test_simulate_and_view_replacements() {
  map=$(mktemp)
  echo 'Hello john doe' > $map
  actual=$($ROOTDIR/bin/sandr.py -d -i -s hello -r bye $map | suppress_color | tr -d '\n')
  assert_equals "{Hello=>bye} john doe" "$actual" "bad substitution"
  rm -f $map
}

function test_simulate_and_view_replacements_renaming_file() {
  map=/tmp/hello_john_doe.txt
  echo 'Hello john doe' > $map
  actual=$($ROOTDIR/bin/sandr.py -R -d -i -s hello -r bye /tmp/hello_john_doe.txt |& suppress_color | tr '\n' '#')
  assert_equals "{Hello=>bye} john doe#File /tmp/hello_john_doe.txt will be renamed to /tmp/bye_john_doe.txt (/tmp/{hello=>bye}_john_doe.txt)#" "$actual" "bad substitution"
  rm -f $map
}
