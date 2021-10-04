#!/usr/bin/python3

import unittest

class UnitTests(unittest.TestCase):

    def test_parse_field_slice(self):
#        same_case('Hello', 'bonjour')
        self.assertEqual('a', 'a', 'message')


if __name__ == '__main__':
    unittest.main()
