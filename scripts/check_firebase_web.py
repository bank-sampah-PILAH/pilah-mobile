"""Check the Firebase edge against the expected Cloud Run web revision."""

import argparse
import time
import urllib.request


HEADERS = {
    "Cache-Control": "no-cache",
    "Content-Security-Policy": "frame-ancestors 'none';",
    "Referrer-Policy": "strict-origin-when-cross-origin",
    "X-Content-Type-Options": "nosniff",
    "X-Frame-Options": "DENY",
}


def verify(base_url, revision):
    paths = {"/health": "ok", "/": None, "/flutter_bootstrap.js": None}
    if revision:
        paths["/revision.txt"] = revision
    for path, expected_body in paths.items():
        with urllib.request.urlopen(base_url + path, timeout=30) as response:
            if response.status != 200:
                raise ValueError(f"{path}: expected HTTP 200, got {response.status}")
            for header, expected in HEADERS.items():
                if response.headers.get(header) != expected:
                    raise ValueError(f"{path}: expected {header} to be {expected!r}")
            if expected_body is not None and response.read().decode().strip() != expected_body:
                raise ValueError(f"{path}: unexpected response body")


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("url")
    parser.add_argument("revision", nargs="?")
    args = parser.parse_args()
    for attempt in range(5):
        try:
            verify(args.url.rstrip("/"), args.revision)
            break
        except (OSError, ValueError):
            if attempt == 4:
                raise
            time.sleep(5)
