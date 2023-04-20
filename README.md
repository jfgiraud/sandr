![<https://github.com/jfgiraud/sandr/actions>](https://img.shields.io/github/actions/workflow/status/jfgiraud/sandr/main.yml?label=CI)

Description
===========

**sandr** is a tool to replace strings in files or standard streams.

It supports replacements for **fixed strings** and **regular
expressions**, ignoring case or not.

For **regular expressions**, matching groups can be reused in
replacement string.

Some options permit to :

-   extract an association map (matches/replacements)

-   apply an association map for mass replacements

-   try to keep the character case

-   preview modifications

-   allow file renaming

Installation
============

The destination directory will contain 3 sub-directories: `bin`, `share`
and `man`.

**Using git repo.**

    $ git clone https://github.com/jfgiraud/sandr.git
    $ cd sandr
    $ sudo make install DESTDIR=/usr/local

**Using latest tarball release.**

    $ curl -s -L https://api.github.com/repos/jfgiraud/sandr/releases/latest | grep browser_download_url | cut -d':' -f2- | tr -d ' ",' | xargs wget -O sandr.tgz
    $ sudo tar zxvf sandr.tgz -C /usr/local

Usage
=====

**Use man.**

    $ man sandr

**Use option.**

    $ sandr -h

Examples
====

**Use option `-s` to search fixed string.**

    $ echo 'Hello John DOE' | sandr -s o -r'<o>'
    Hell<o> J<o>hn DOE

**Add option `-i` to ignore case.**

    $ echo 'Hello John DOE' | sandr -i -s o -r'<o>'
    Hell<o> J<o>hn D<o>E

**Add option `-c` to try to reuse same case when replacing.**

    $ echo 'Hello John Doe and Jane DOE' | sandr -i -c -s 'doe' -r 'smith'
    Hello John Smith and Jane SMITH

**Use option `-S` to search a pattern, the `-r` option can contain a
reference to a matched group.**

    $ echo 'Hello John DOE' | sandr -i -c -S '([aeiouy])' -r'<\1>'
    H<e>ll<o> J<o>hn D<O><E>

**Use option `-e` to extract a replacements map witch can be reused
later.**

    $ echo 'Hello John DOE' | sandr -e -i -c -S '([aeiouy])' -r'<\1>' > map
    $ cat map
    -E
    +<E>
    ---
    -O
    +<O>
    ---
    -e
    +<e>
    ---
    -o
    +<o>

**Use option `-a` to apply a replacements map on files or standard
streams.**

The given map can be handwritten or generated with the `-e` option.

    $ cat map
    -Hello
    +Bonjour
    ---
    -DOE
    +Durand
    ---
    $ echo 'Hello John DOE' | sandr -a map
    Bonjour John Durand

The map can contain multiline keys or values.

    $ cat map
    -a
    +X
    +X
    ---
    -b
    +Y
    ---
    -c
    +Z
    +Z
    +Z

is equivalent to (python syntax) :

    { 'a': 'X\nX', 'b': 'Y', 'c': 'Z\nZ\nZ' }

So the result of the replacement is :

    $ echo "abc" | sandr -a map
    X
    XYZ
    Z
    Z

**Use option `-m` to toggle **on** the multiline mode.**

You can use `\n` in patterns

    $ printf "Hello John Doe\nAnd Jane\nDOE.\n" | sandr -m -S '((J\w+)\s+(D\w+))' -r '\1' -e > map
    $ cat map
    -Jane
    -DOE
    +Jane
    +DOE
    ---
    -John Doe
    +John Doe
    ---

**Use option `-t` to simulate replacements.**

    $ echo 'Hello john doe' > hello_john_doe.txt
    $ sandr -t -i -s hello -r bye hello_john_doe.txt
    bye john doe

**Use option `-d` to simulate and view replacements.**

    $ sandr -d -i -s hello -r bye hello_john_doe.txt
    {Hello=>bye} john doe

**Use option `-R` to rename file when replacements can be done in
filename.**

    $ sandr -R -d -i -s hello -r bye hello_john_doe.txt
    {Hello=>bye} john doe
    File hello_john_doe.txt will be renamed to bye_john_doe.txt ({hello=>bye}_john_doe.txt)
    $ sandr -R -i -s hello -r bye hello_john_doe.txt
    Processed: hello_john_doe.txt (file renamed to bye_john_doe.txt)
    $ ls
    bye_john_doe.txt   sandr
    $ cat bye_john_doe.txt
    bye john doe

**Use option `-x` to execute a command defined with `-r` and replace the
result.**

The option is not compatible with `-a`

    $ cat file.txt
    Hello John Doe
    And Jane
    DOE.
    $ cat file.txt | sandr -m -S '((J\w+)\s+(D\w+))' -r "echo -n '\2' | tr 'aeiouyAEIOUY' '*'" -x
    Hello J*hn
    And J*n*.
