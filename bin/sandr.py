#!/usr/bin/python3 -u

import difflib
import getopt
import os
import os.path
import re
import sys
import io
import tempfile
import shutil
import stat
import difflib
import subprocess
import shlex


# python sandr.py -e -S '((\w+)jour)' -r 'helLO\1' -i aaa
# python sandr.py -e -s BONjour -r helLO -i aaa
# bug python sandr.py -e -s '((\w+)jour)' -r 'helLO\1' -i aaa


def usage(retval=0):
    print('''NAME:

        %(program)s - perform pattern replacement in files

SYNOPSYS:

        %(program)s
             -h, --help                 display help
             -s, --search               the string to search
             -S, --search-regexp        the pattern to search
             -r, --replace              the string (or the pattern) used to replace all matches 
             -e, --extract-map          extract from file or standard input all matches of searched
                                        string or pattern.
                                        a map created with found matches is displayed on standard 
                                        output. entries of this map will be set with a default
                                        value
             -i, --ignore-case          search ignoring case
             -a, --apply-map            use a file containing the map to perform replacement
             -c, --case                 apply transformations to try to keep the same case after 
                                        replacement (useful with -i option)
             -l, --min-matching-length  for case transformations, ignore matching group when the
                                        size is less than de specified value (default 3)
             -t, --simulate             perform a simulation for replacements
                                        the results will be displayed on standard output
             -d, --diff                 compare files before and after replacements
             -R, --rename               rename files if path matches searched string or pattern
             -x, --execute              execute a command and replace with the result. the command
                                        is a pattern.
        
With no FILE, or when FILE is -, read standard input.

AUTHOR
    
    Written by Jean-François Giraud.

COPYRIGHT

    Copyright (c) 2012-2014 Jean-François Giraud.  
    License GPLv3+: GNU GPL version 3 or later <https://www.gnu.org/licenses/gpl-3.0.html>.
    This is free software: you are free to change and redistribute it.  
    There is NO WARRANTY, to the extent permitted by law.
''' % {'program': os.path.basename(sys.argv[0])})
    sys.exit(retval)


def error(message):
    print(message, file=sys.stderr)
    sys.exit(1)


def extract(file_object):
    found = set()
    re_flags = re.I if flag_ignore_case else 0
    pattern = re.compile(search if flag_use_regexp else re.escape(search), re_flags)
    for a_line in file_object:
        found.update([m.group(0) for m in pattern.finditer(a_line)])
    return found


colors = {'old-value': '\033[1;31m',
          'new-value': '\033[1;32m',
          'box': '\033[1;34m',
          'reset': '\033[0;m'}


def colorize_value(text, color_name):
    color = colors[color_name]
    if color:
        return '%s%s%s' % (colors[color_name], text, colors['reset'])
    else:
        return text


def colorize(old, new):
    res = ss(old, new, d=matching_min_length)
    s = ''
    for part_a, part_b in zip(res[0], res[1]):
        cra, crb = part_a.endswith('\n'), part_b.endswith('\n')
        part_a, part_b = part_a.rstrip('\n'), part_b.rstrip('\n')
        if part_a != part_b:
            s += '%s%s%s%s%s%s%s' % (colorize_value('{', 'box'),
                                     colorize_value(part_a, 'old-value'),
                                     ('\n' if cra else ''),
                                     colorize_value('=>', 'box'),
                                     colorize_value(part_b, 'new-value'),
                                     ('\n' if crb else ''),
                                     colorize_value('}', 'box'))
        else:
            s += part_a
    return s


def apply_on_file(file, pattern, repl):
    (use_stdout_ori, filename) = file
    use_stdout = use_stdout_ori
    move = False
    with open(filename, 'rt') as fd_in:
        if use_stdout or flag_simulate:
            fd_out = open(sys.stdout.fileno(), 'w', closefd=False)
        else:
            (fno, temporary_file) = tempfile.mkstemp()
            fd_out = open(fno, 'wt')
            move = True
        with fd_out:
            for line in fd_in:
                if pattern:
                    old_line = line
                    line = re.sub(pattern, repl, line)
                    if flag_diff:
                        if line != old_line:
                            print(colorize(old_line, line), end='\n')
                        else:
                            print(line, end='')
                    else:
                        fd_out.write(line)
                else:
                    fd_out.write(line)
    renamed_filename = None
    if not use_stdout and flag_rename_file and pattern:
        renamed_filename = re.sub(pattern, repl, filename)
        if filename != renamed_filename:
            move = True
            if flag_diff:
                print('File %s will be renamed to %s (%s)' % (
                    filename, renamed_filename, colorize(filename, renamed_filename)), file=sys.stderr)
        else:
            renamed_filename = None
    if not flag_simulate and move:
        shutil.move(temporary_file, filename)
        if renamed_filename is not None:
            print('Processed: %s (file renamed to %s)' % (filename, renamed_filename), file=sys.stderr)
            shutil.move(filename, renamed_filename)
        else:
            print('Processed: %s' % (filename,), file=sys.stderr)


def ss(x, y, f=None, d=3):
    if f is not None:
        s = getattr(x, f)()
        t = getattr(y, f)()
    else:
        s, t = x, y
    opts = [x for x in difflib.SequenceMatcher(None, s, t).get_matching_blocks()]
    i1, j1 = 0, 0
    res = [[], []]
    while opts:
        i2, j2, size = opts.pop(0)
        if size == 0:
            if x[i1:] and y[j1:]:
                res[0].append(x[i1:])
                res[1].append(y[j1:])
            break
        if size < d:
            continue
        res[0].append(x[i1:i2])
        res[1].append(y[j1:j2])
        res[0].append(x[i2:i2 + size])
        res[1].append(y[j2:j2 + size])
        i1 = i2 + size
        j1 = j2 + size
    return res


def same_case(x, y, d=3):
    res = ss(x, y, 'lower', d)
    w = ''
    for a, b in zip(res[0], res[1]):
        if a.lower() == b.lower():
            w += a
        else:
            for f in ['upper', 'lower', 'title', 'capitalize']:
                if getattr(a, f)() == a:
                    w += getattr(b, f)()
                    break
            else:
                w += b
    return w


def extract_map(files):
    extracted = set()
    re_flags = re.I if flag_ignore_case else 0
    for _, file in files:
        with open(file, 'rt') as fd_in:
            extracted.update(extract(fd_in))
            if flag_rename_file:
                extracted.update(extract([file]))
    replacements = {}
    for match in extracted:
        if type(match) == tuple:
            match = match[0]
        if flag_use_regexp:
            to_replace = re.sub(search, replace, match, flags=re_flags)
            if flag_detect:
                to_replace = same_case(match, to_replace, d=matching_min_length)
            replacements[match] = to_replace
        else:
            to_replace = re.sub(re.escape(search), replace, match, flags=re_flags)
            if flag_detect:
                to_replace = same_case(match, to_replace, d=matching_min_length)
            replacements[match] = to_replace
    return replacements


def create_tmp_and_init(fd_in):
    (fno, absolute_path) = tempfile.mkstemp()
    with open(fno, 'wt') as fd_out:
        for line in fd_in:
            fd_out.write(line)
    return absolute_path


def op(filename):
    if filename == '-':
        return True, create_tmp_and_init(sys.stdin)
    else:
        with open(filename, 'rt') as fd_in:
            if stat.S_ISFIFO(os.fstat(fd_in.fileno()).st_mode):
                return True, create_tmp_and_init(fd_in)
            else:
                return False, filename


def apply_replacements(config):
    pattern = '|'.join(map(re.escape, sorted(config, reverse=True)))
    repl = lambda matchobj: config[matchobj.group(0)]
    for file in args:
        apply_on_file(file, pattern, repl)


def write_multiline(s):
    return s.replace('\n', '\n| ')


if __name__ == '__main__':
    search = None
    replace = None
    flag_use_regexp = False
    flag_ignore_case = False
    flag_simulate = False
    flag_extract_map = False
    flag_detect = False
    flag_diff = False
    flag_rename_file = False
    matching_min_length = 3
    apply_map = None
    flag_execute = False

    try:
        opts, args = getopt.getopt(sys.argv[1:], "hs:S:r:itea:cl:dRx", ["help", "search=", "search-regexp=", "replace=",
                                                                        "ignore-case", "simulate", "extract-map",
                                                                        "apply-map=", "case", "min-matching-length=",
                                                                        "diff", "rename", "execute"])
    except getopt.GetoptError:
        usage(2)

    if len(opts) == 0:
        usage()

    for o, a in opts:
        if o in ("-h", "--help"):
            usage()
        if o in ("-s", "--search"):
            search = a
        if o in ("-r", "--replace"):
            replace = a
        if o in ("-S", "--search-regexp"):
            search = a
            flag_use_regexp = True
        if o in ("-i", "--ignore-case"):
            flag_ignore_case = True
        if o in ("-t", "--simulate"):
            flag_simulate = True
        if o in ("-d", "--diff"):
            flag_simulate = True
            flag_diff = True
        if o in ("-e", "--extract-map"):
            flag_extract_map = True
        if o in ("-a", "--apply-map"):
            apply_map = a
        if o in ("-c", "--case"):
            flag_detect = True
        if o in ("-R", "--rename"):
            flag_rename_file = True
        if o in ("-x", "--execute"):
            flag_execute = True
        if o in ("-l", "--min-matching-length"):
            matching_min_length = int(a)

    if flag_extract_map and flag_simulate:
        error("setting option --simulate makes no sense with option --extract-map")

    if flag_extract_map and apply_map:
        error("--extract-map and --apply-map option are mutually exclusives")

    if flag_extract_map and (search is None or replace is None):
        error("setting option --extract-map implies to set options --search and --replace")

    if (apply_map is None) and (search is None or replace is None):
        error("--search and --replace are required when --apply-map is not used")

    if len(args) == 0:
        args = ["-"]

    args = [op(x) for x in args]

    if flag_extract_map:
        replacements = extract_map(args)
        for replacement in replacements:
            print(replacement, write_multiline(replacements[replacement]), sep=' => ')
    elif apply_map is not None:
        config = {}
        with open(apply_map, 'rt') as fd:
            flag_use_regexp = None
            for line in fd:
                line = line.strip()
                if not line.startswith("| "):
                    (k, v) = line.split(' => ', 2)
                    config[k] = v
                else:
                    config[k] += '\n' + line[2:]
        apply_replacements(config)
    else:
        config = extract_map(args)
        apply_replacements(config)
