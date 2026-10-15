"""Keep the Android release build above the rejected Play version code."""
import pathlib
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]


class ReleaseVersionTest(unittest.TestCase):
    def test_play_version_is_newer_than_rejected_version_code(self):
        pubspec = (ROOT / "pubspec.yaml").read_text()
        self.assertIn("version: 1.0.3+7", pubspec)


if __name__ == "__main__":
    unittest.main()
