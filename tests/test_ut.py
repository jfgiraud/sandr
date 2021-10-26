#!/usr/bin/python3

import unittest
import tempfile
import importlib
import os

file_path = os.path.abspath(os.path.join(os.path.dirname(__file__), '..', 'bin/sandr'))
importlib.machinery.SOURCE_SUFFIXES.append('')  # empty string to allow any file
spec = importlib.util.spec_from_file_location("sandr", file_path)
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

same_case = getattr(module, "same_case")
read_replacements_in_file = getattr(module, "read_replacements_in_file")


class SandrTest(unittest.TestCase):

    def test_capitalize(self):
        c = same_case('Hello', 'bonjour')
        self.assertEqual(c, 'Bonjour', 'capitalize')

    def test_upper(self):
        c = same_case('HELLO', 'bonjour')
        self.assertEqual(c, 'BONJOUR', 'upper')

    def test_lower(self):
        c = same_case('hello', 'BONJOUR')
        self.assertEqual(c, 'bonjour', 'lower')

    def test_read_replacements_in_file(self):
        fno, tmp = tempfile.mkstemp()
        with open(tmp, 'wt') as fd:
            fd.write('-hello\n')
            fd.write('+bonjour\n')
        self.assertEqual({'hello': 'bonjour'}, read_replacements_in_file(tmp))
        os.remove(tmp)


if __name__ == '__main__':
    unittest.main()
