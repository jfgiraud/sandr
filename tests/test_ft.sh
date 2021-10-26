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

function test_reuse_case_use_regexp() {
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr -i -c -S '([aeiouy])' -r'<\1>')
  assert_equals "H<e>ll<o> J<o>hn D<O><E>" "$actual" "bad substitution"
}

function test_extract_map() {
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr -e -i -c -S '([aeiouy])' -r'<\1>' | tr '\n' '#')
  assert_equals "-E#+<E>#---#-O#+<O>#---#-e#+<e>#---#-o#+<o>#---#" "$actual" "bad substitution"
}

#$ printf $"Alors c'est comme ça\nla vie\nà la campagne ?\n" | ./bin/sandr -S '(.)\n(.)' -r 'x\1x\ny\2y' -e
#-a
#-l
#+xax
#+yly
#---
#-e
#-à
#+xex
#+yày
#---

function test_use_map() {
  map=$(mktemp)
  cat > $map <<EOF
-Hello
+Bonjour
---
-DOE
+Durand
---
EOF
  actual=$(echo "Hello John DOE" | $ROOTDIR/bin/sandr -a $map)
  assert_equals "Bonjour John Durand" "$actual" "bad substitution"
  rm -f $map
}

function test_simulate_replacements() {
  map=$(mktemp)
  echo 'Hello john doe' > $map
  actual=$($ROOTDIR/bin/sandr -t -i -s hello -r bye $map)
  assert_equals "bye john doe" "$actual" "bad substitution"
  rm -f $map
}

function suppress_color() {
  sed 's/\x1B\[[0-9;]\{1,\}[A-Za-z]//g'
}

function test_use_map_with_newlines() {
  map=$(mktemp)
  cat > $map <<EOF
-a
+It is a sentence
+on 2 lines
---
-b
+And another sentence on one line
---
EOF
  actual=$(echo "ab" | $ROOTDIR/bin/sandr -a $map | tr '\n' '#')
  assert_equals "It is a sentence#on 2 linesAnd another sentence on one line#" "$actual" "bad substitution"
  rm -f $map
}

function test_simulate_and_view_replacements() {
  map=$(mktemp)
  echo 'Hello john doe' > $map
  actual=$($ROOTDIR/bin/sandr -d -i -s hello -r bye $map | suppress_color | tr -d '\n')
  assert_equals "{Hello=>bye} john doe" "$actual" "bad substitution"
  rm -f $map
}

function test_simulate_and_view_replacements_renaming_file() {
  map=/tmp/hello_john_doe.txt
  echo 'Hello john doe' > $map
  actual=$($ROOTDIR/bin/sandr -R -d -i -s hello -r bye /tmp/hello_john_doe.txt |& suppress_color | tr '\n' '#')
  assert_equals "{Hello=>bye} john doe#File /tmp/hello_john_doe.txt will be renamed to /tmp/bye_john_doe.txt (/tmp/{hello=>bye}_john_doe.txt)#" "$actual" "bad substitution"
  rm -f $map
}

#https://pastebin.com/raw/2bLUvFKZ