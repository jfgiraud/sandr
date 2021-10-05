#!/usr/bin/python3

import unittest

from bin.sandr import same_case


class SandrTest(unittest.TestCase):

    def test_capitalize(self):
        c = same_case('Hello', 'bonjour')
        self.assertEqual(c, 'Bonjour', 'Capitalize')


if __name__ == '__main__':
    unittest.main()
