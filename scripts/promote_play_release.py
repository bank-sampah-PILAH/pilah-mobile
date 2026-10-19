"""Assign a bundle already uploaded to Google Play to a selected release track."""
import argparse
import hashlib
import json
import os
import pathlib
import re
import sys
from urllib.parse import quote


API_ROOT = "https://androidpublisher.googleapis.com/androidpublisher/v3/applications"
ANDROID_PUBLISHER_SCOPE = "https://www.googleapis.com/auth/androidpublisher"
ALLOWED_TRACKS = {"alpha", "beta", "production"}


def promote_existing_release(
    session,
    *,
    package_name,
    track,
    release_tag,
    version_code,
    expected_sha256,
):
    """Validate the existing Play bundle, assign its version code, then commit."""
    if track not in ALLOWED_TRACKS:
        raise ValueError(f"Unsupported Play track: {track}")
    if not re.fullmatch(r"[0-9a-fA-F]{64}", expected_sha256):
        raise ValueError("Expected AAB SHA-256 must be a 64-character hexadecimal digest")

    base_url = f"{API_ROOT}/{quote(package_name, safe='')}"
    edit_response = session.post(f"{base_url}/edits", json={}, timeout=60)
    edit_response.raise_for_status()
    edit_id = edit_response.json().get("id")
    if not edit_id:
        raise RuntimeError("Google Play did not return an edit ID")
    edit_url = f"{base_url}/edits/{quote(str(edit_id), safe='')}"

    bundles_response = session.get(f"{edit_url}/bundles", timeout=60)
    bundles_response.raise_for_status()
    expected_code = int(version_code)
    matching_bundle = next(
        (
            bundle
            for bundle in bundles_response.json().get("bundles", [])
            if int(bundle.get("versionCode", -1)) == expected_code
        ),
        None,
    )
    if matching_bundle is None:
        raise ValueError(
            f"Version code {expected_code} is not present in Google Play; refusing to upload it"
        )
    if matching_bundle.get("sha256", "").lower() != expected_sha256.lower():
        raise ValueError(
            f"Google Play's bundle digest for version code {expected_code} does not match the release AAB"
        )

    track_resource = {
        "track": track,
        "releases": [
            {
                "name": release_tag,
                "versionCodes": [str(expected_code)],
                "status": "completed",
            }
        ],
    }
    track_response = session.put(
        f"{edit_url}/tracks/{quote(track, safe='')}",
        json=track_resource,
        timeout=60,
    )
    track_response.raise_for_status()

    commit_response = session.post(
        f"{edit_url}:commit",
        params={"changesInReviewBehavior": "ERROR_IF_IN_REVIEW"},
        timeout=60,
    )
    commit_response.raise_for_status()


def read_release_metadata(metadata_path, release_tag, bundle_path):
    metadata = {}
    for line in pathlib.Path(metadata_path).read_text().splitlines():
        key, separator, value = line.partition(":")
        if separator:
            metadata[key.strip()] = value.strip()

    if metadata.get("Tag") != release_tag:
        raise ValueError("Release metadata tag does not match the requested release tag")
    if not re.fullmatch(r"v[0-9]+\.[0-9]+\.[0-9]+", release_tag):
        raise ValueError("Release tag must use vMAJOR.MINOR.PATCH format")
    try:
        version_name = metadata["Version name"]
        version_code = int(metadata["Version code"])
    except (KeyError, ValueError) as error:
        raise ValueError("Release metadata has no valid version name or code") from error
    if release_tag != f"v{version_name}":
        raise ValueError("Release metadata version name does not match the requested tag")
    if version_code <= 0:
        raise ValueError("Release version code must be positive")

    expected_sha256 = metadata.get("AAB SHA-256", "")
    if not re.fullmatch(r"[0-9a-fA-F]{64}", expected_sha256):
        raise ValueError("Release metadata has no valid AAB SHA-256")
    actual_sha256 = hashlib.sha256(pathlib.Path(bundle_path).read_bytes()).hexdigest()
    if actual_sha256.lower() != expected_sha256.lower():
        raise ValueError("Downloaded AAB does not match the release metadata SHA-256")
    return version_code, expected_sha256


def main(argv=None):
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--package-name", required=True)
    parser.add_argument("--track", required=True, choices=sorted(ALLOWED_TRACKS))
    parser.add_argument("--release-tag", required=True)
    parser.add_argument("--bundle", required=True)
    parser.add_argument("--metadata", required=True)
    args = parser.parse_args(argv)

    try:
        version_code, expected_sha256 = read_release_metadata(
            args.metadata, args.release_tag, args.bundle
        )
        service_account_json = os.environ.get("PLAY_SERVICE_ACCOUNT_JSON", "")
        if not service_account_json:
            raise ValueError("PLAY_SERVICE_ACCOUNT_JSON is required")

        from google.auth.transport.requests import AuthorizedSession
        from google.oauth2 import service_account

        credentials = service_account.Credentials.from_service_account_info(
            json.loads(service_account_json), scopes=[ANDROID_PUBLISHER_SCOPE]
        )
        session = AuthorizedSession(credentials)
        promote_existing_release(
            session,
            package_name=args.package_name,
            track=args.track,
            release_tag=args.release_tag,
            version_code=version_code,
            expected_sha256=expected_sha256,
        )
    except Exception as error:
        print(f"::error::{error}", file=sys.stderr)
        return 1
    print(
        f"Assigned existing Play version code {version_code} to {args.track} "
        f"for {args.release_tag}; no bundle was uploaded."
    )
    return 0


if __name__ == "__main__":
    raise SystemExit(main())
