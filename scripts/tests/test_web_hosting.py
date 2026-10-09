"""Exercise the shipped static image, not a Python substitute server."""
import pathlib
import shutil
import subprocess
import tempfile
import time
import unittest
import urllib.error
import urllib.request
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[2]


class WebHostingTest(unittest.TestCase):
    def test_static_assets_revalidate_and_missing_paths_are_not_spa_html(self):
        name = "pil335-test-" + uuid.uuid4().hex[:12]
        with tempfile.TemporaryDirectory() as directory:
            context = pathlib.Path(directory)
            shutil.copytree(ROOT / "deploy/web", context / "deploy/web")
            web = context / "build/web"
            web.mkdir(parents=True)
            for asset in ("index.html", "main.dart.js", "flutter_bootstrap.js",
                          "assets/.env", "assets/logo.png", "vendor/passkeys-2.4.0/bundle.js"):
                path = web / asset
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("fixture: " + asset)
            subprocess.run(["docker", "build", "-q", "-t", name, "-f",
                            "deploy/web/Dockerfile", str(context)], check=True)
            try:
                subprocess.run(["docker", "run", "-d", "--name", name, "-p",
                                "127.0.0.1::8080", name], check=True, capture_output=True)
                port = subprocess.check_output(["docker", "port", name, "8080"], text=True).strip().split(":")[-1]
                base = "http://127.0.0.1:" + port
                for _ in range(50):
                    try:
                        urllib.request.urlopen(base + "/healthz", timeout=1).close()
                        break
                    except (OSError, urllib.error.URLError):
                        time.sleep(.1)
                for path in ("/", "/index.html", "/main.dart.js", "/flutter_bootstrap.js",
                             "/assets/.env", "/assets/logo.png", "/vendor/passkeys-2.4.0/bundle.js"):
                    with self.subTest(path=path), urllib.request.urlopen(base + path) as response:
                        self.assertEqual(response.status, 200)
                        self.assertEqual(response.headers["Cache-Control"], "no-cache")
                        etag = response.headers["ETag"]
                    with self.assertRaises(urllib.error.HTTPError) as cached:
                        urllib.request.urlopen(urllib.request.Request(base + path, headers={"If-None-Match": etag}))
                    self.assertEqual(cached.exception.code, 304)
                    cached.exception.close()
                with urllib.request.urlopen(base + "/healthz") as response:
                    self.assertEqual(response.read(), b"ok\n")
                for path in ("/missing.js", "/dashboard", "/assets/missing.png"):
                    with self.subTest(path=path), self.assertRaises(urllib.error.HTTPError) as missing:
                        urllib.request.urlopen(base + path)
                    self.assertEqual(missing.exception.code, 404)
                    missing.exception.close()
            finally:
                subprocess.run(["docker", "rm", "-f", name], capture_output=True)
                subprocess.run(["docker", "image", "rm", name], capture_output=True)


if __name__ == "__main__":
    unittest.main()
