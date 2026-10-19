"""Play track promotion must reuse a bundle already present in Play."""
import hashlib
import pathlib
import tempfile
import unittest

from scripts.promote_play_release import promote_existing_release, read_release_metadata


class Response:
    def __init__(self, body=None):
        self.body = body or {}

    def raise_for_status(self):
        return None

    def json(self):
        return self.body


class FakeSession:
    def __init__(self, bundles):
        self.bundles = bundles
        self.calls = []

    def post(self, url, **kwargs):
        self.calls.append(("POST", url, kwargs))
        if url.endswith("/edits"):
            return Response({"id": "edit-123"})
        if url.endswith(":commit"):
            return Response({"id": "edit-123"})
        raise AssertionError(f"Unexpected POST {url}")

    def get(self, url, **kwargs):
        self.calls.append(("GET", url, kwargs))
        self.assert_no_bundle_upload()
        return Response({"bundles": self.bundles})

    def put(self, url, **kwargs):
        self.calls.append(("PUT", url, kwargs))
        return Response(kwargs.get("json"))

    def assert_no_bundle_upload(self):
        if any(method == "POST" and "/bundles" in url for method, url, _ in self.calls):
            raise AssertionError("promotion must not upload another bundle")


class PromoteExistingReleaseTest(unittest.TestCase):
    def setUp(self):
        self.session = FakeSession([{"versionCode": 7, "sha256": "a" * 64}])

    def test_updates_track_assignment_and_commits_existing_version_code(self):
        promote_existing_release(
            self.session,
            package_name="com.mobile.pilahapp",
            track="production",
            release_tag="v1.0.3",
            version_code=7,
            expected_sha256="A" * 64,
        )

        track_update = next(call for call in self.session.calls if call[0] == "PUT")
        self.assertIn("/tracks/production", track_update[1])
        self.assertEqual(
            track_update[2]["json"],
            {
                "track": "production",
                "releases": [
                    {"name": "v1.0.3", "versionCodes": ["7"], "status": "completed"}
                ],
            },
        )
        commit = next(call for call in self.session.calls if call[0] == "POST" and call[1].endswith(":commit"))
        self.assertEqual(commit[2]["params"], {"changesInReviewBehavior": "ERROR_IF_IN_REVIEW"})
        self.assertFalse(any(method == "POST" and "/bundles" in url for method, url, _ in self.session.calls))

    def test_refuses_missing_or_mismatched_existing_bundle_before_track_update(self):
        cases = (
            [],
            [{"versionCode": 8, "sha256": "a" * 64}],
            [{"versionCode": 7, "sha256": "b" * 64}],
        )
        for bundles in cases:
            with self.subTest(bundles=bundles):
                session = FakeSession(bundles)
                with self.assertRaises(ValueError):
                    promote_existing_release(
                        session,
                        package_name="com.mobile.pilahapp",
                        track="beta",
                        release_tag="v1.0.3",
                        version_code=7,
                        expected_sha256="a" * 64,
                    )
                self.assertFalse(any(method == "PUT" for method, _, _ in session.calls))
                self.assertFalse(any(method == "POST" and url.endswith(":commit") for method, url, _ in session.calls))

    def test_release_metadata_binds_tag_code_and_downloaded_bundle_digest(self):
        bundle = b"release bundle bytes"
        checksum = hashlib.sha256(bundle).hexdigest()
        with tempfile.TemporaryDirectory() as directory:
            bundle_path = pathlib.Path(directory, "app-release.aab")
            metadata_path = pathlib.Path(directory, "release-metadata.txt")
            bundle_path.write_bytes(bundle)
            metadata_path.write_text(
                "Tag: v1.0.3\nVersion name: 1.0.3\nVersion code: 7\nAAB SHA-256: " + checksum + "\n"
            )

            self.assertEqual(
                read_release_metadata(metadata_path, "v1.0.3", bundle_path),
                (7, checksum),
            )
            metadata_path.write_text(
                "Tag: v1.0.3\nVersion name: 1.0.3\nVersion code: 7\nAAB SHA-256: " + "0" * 64 + "\n"
            )
            with self.assertRaisesRegex(ValueError, "does not match"):
                read_release_metadata(metadata_path, "v1.0.3", bundle_path)


if __name__ == "__main__":
    unittest.main()
