#!/usr/bin/python3

import unittest

from bin.sandr import same_case


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

if __name__ == '__main__':
    unittest.main()
