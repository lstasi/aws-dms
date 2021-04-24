"""Unit test file for app.py"""
from app import return_back_string
import unittest


class TestApp(unittest.TestCase):
    """Unit tests defined for app.py"""

    def test_return_backwards_string(self):
        """Test return backwards simple string"""
        random_string = "This is my test string"
        random_string_reversed = "gnirts tset ym si sihT"
        self.assertEqual(random_string_reversed, return_back_string(random_string))


if __name__ == "__main__":
    unittest.main()
