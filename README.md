# sandr

`sandr` is a tool to replace strings in files or standard streams.

It supports replacements for *fixed strings* and *regular expressions*, ignoring case or not.

For *regular expressions*, matching groups can be reused in replacement string.

Some options permit to :
- preview modifications
- allow files renaming
- extract matches and apply mass replacement

### use option `-s` to search fixed string 
```
$ echo 'Hello John DOE' | sandr -s o -r'<o>'
Hell<o> J<o>hn DOE
```

### add option `-i` to ignore case
```
$ echo 'Hello John DOE' | sandr -i -s o -r'<o>'
Hell<o> J<o>hn D<o>E
```

### add option `-c` to try to reuse same case when replacing
```
$ echo 'Hello John DOE' | sandr -i -c -s o -r'<o>'
Hell<o> J<o>hn D<O>E
```

### use option `-S` to search a pattern, the `-r` option can contain a reference to a matched group
```
$ echo 'Hello John DOE' | sandr -i -c -S '([aeiouy])' -r'<\1>'
H<e>ll<o> J<o>hn D<O><E>
```
