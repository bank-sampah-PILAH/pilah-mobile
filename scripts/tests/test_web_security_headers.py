"""Security headers of the shipped static image: HSTS and a real Content-Security-Policy."""
import contextlib
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


@contextlib.contextmanager
def served_web_image():
    """Build and run deploy/web exactly as shipped, with a fixture instead of the app."""
    name = "web-headers-test-" + uuid.uuid4().hex[:12]
    with tempfile.TemporaryDirectory() as directory:
        context = pathlib.Path(directory)
        shutil.copytree(ROOT / "deploy/web", context / "deploy/web")
        web = context / "build/web"
        web.mkdir(parents=True)
        (web / "index.html").write_text("fixture")
        subprocess.run(["docker", "build", "-q", "-t", name, "-f",
                        "deploy/web/Dockerfile", str(context)], check=True, capture_output=True)
        try:
            subprocess.run(["docker", "run", "-d", "--name", name, "-p",
                            "127.0.0.1::8080", name], check=True, capture_output=True)
            port = subprocess.check_output(["docker", "port", name, "8080"], text=True).strip().split(":")[-1]
            base = "http://127.0.0.1:" + port
            for _ in range(50):
                try:
                    urllib.request.urlopen(base + "/health", timeout=1).close()
                    break
                except (OSError, urllib.error.URLError):
                    time.sleep(.1)
            yield base
        finally:
            subprocess.run(["docker", "rm", "-f", name], capture_output=True)
            subprocess.run(["docker", "image", "rm", name], capture_output=True)


def headers_of(base, path):
    try:
        with urllib.request.urlopen(base + path) as response:
            return response.headers
    except urllib.error.HTTPError as error:
        error.close()
        return error.headers


def policy(header):
    directives = {}
    for part in header.split(";"):
        tokens = part.split()
        if tokens:
            directives[tokens[0]] = tokens[1:]
    return directives


class WebSecurityHeadersTest(unittest.TestCase):
    @classmethod
    def setUpClass(cls):
        cls._served = served_web_image()
        cls.base = cls._served.__enter__()

    @classmethod
    def tearDownClass(cls):
        cls._served.__exit__(None, None, None)

    def test_every_response_asks_browsers_to_insist_on_https(self):
        for path in ("/", "/index.html", "/health", "/missing.js"):
            with self.subTest(path=path):
                value = headers_of(self.base, path).get("Strict-Transport-Security", "")
                self.assertRegex(value, r"^max-age=[1-9]\d*$")

    def test_csp_shuts_plugins_base_tag_form_posts_and_framing(self):
        for path in ("/", "/main.dart.js", "/missing.js"):
            with self.subTest(path=path):
                csp = policy(headers_of(self.base, path).get("Content-Security-Policy", ""))
                self.assertEqual(csp.get("default-src"), ["'self'"])
                self.assertEqual(csp.get("object-src"), ["'none'"])
                self.assertEqual(csp.get("base-uri"), ["'self'"])
                self.assertEqual(csp.get("form-action"), ["'self'"])
                self.assertEqual(csp.get("frame-ancestors"), ["'none'"])

