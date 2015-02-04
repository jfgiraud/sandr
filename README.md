# sandr

### Description

`sandr` is a tool to replace strings in files or standard streams.

It supports replacements for *fixed strings* and *regular expressions*, ignoring case or not.

For *regular expressions*, matching groups can be reused in replacement string.

Some options permit to :
- extract an association map (matches/replacements)
- apply an association map for mass replacements
- try to keep the character case
- preview modifications
- allow file renaming

### Options and examples

#### use option `-s` to search fixed string 
```
$ echo 'Hello John DOE' | sandr -s o -r'<o>'
Hell<o> J<o>hn DOE
```

#### add option `-i` to ignore case
```
$ echo 'Hello John DOE' | sandr -i -s o -r'<o>'
Hell<o> J<o>hn D<o>E
```

#### add option `-c` to try to reuse same case when replacing
```
$ echo 'Hello John DOE' | sandr -i -c -s o -r'<o>'
Hell<o> J<o>hn D<O>E
```

#### use option `-S` to search a pattern, the `-r` option can contain a reference to a matched group
```
$ echo 'Hello John DOE' | sandr -i -c -S '([aeiouy])' -r'<\1>'
H<e>ll<o> J<o>hn D<O><E>
```

#### use option `-e` to extract a replacements map witch can be reused later
```
$ echo 'Hello John DOE' | sandr -e -i -c -S '([aeiouy])' -r'<\1>' > map
$ cat map
e => <e>
E => <E>
o => <o>
O => <O>
```

#### use option `-a` to apply a replacements map on files or standard streams

The given map can be handwritten or generated with the `-e` option.
```
$ cat map
Hello => Bonjour
DOE => Durand
$ echo 'Hello John DOE' | sandr -a map
Bonjour John Durand
```

#### use option `-t` to simulate replacements
```
$ echo 'Hello john doe' > hello_john_doe.txt
$ sandr -t -i -s hello -r bye hello_john_doe.txt 
bye john doe
```

#### use option `-d` to simulate and view replacements
```
$ sandr -d -i -s hello -r bye hello_john_doe.txt 
{Hello=>bye} john doe
```

#### use option `-R` to rename file when replacements can be done in filename
```
$ sandr -R -d -i -s hello -r bye hello_john_doe.txt 
{Hello=>bye} john doe
File hello_john_doe.txt will be renamed to bye_john_doe.txt ({hello=>bye}_john_doe.txt)
$ sandr -R -i -s hello -r bye hello_john_doe.txt 
Processed: hello_john_doe.txt (file renamed to bye_john_doe.txt)
$ ls
bye_john_doe.txt   sandr
$ cat bye_john_doe.txt 
bye john doe
```
