"""The upload context must contain only public web output and server config."""
import pathlib
import shutil
import subprocess
import tempfile
import unittest
import uuid

ROOT = pathlib.Path(__file__).resolve().parents[2]


class WebBuildContextTest(unittest.TestCase):
    def test_exclude_private_environment_and_native_files_from_context(self):
        name = "pil335-context-" + uuid.uuid4().hex[:12]
        with tempfile.TemporaryDirectory() as directory:
            context = pathlib.Path(directory)
            shutil.copy(ROOT / ".dockerignore", context / ".dockerignore")
            for file in (".env", "android/app/google-services.json", ".agents/private.txt",
                         "build/app/private.apk", "build/web/index.html", "build/web/assets/.env",
                         "deploy/web/nginx.conf"):
                path = context / file
                path.parent.mkdir(parents=True, exist_ok=True)
                path.write_text("test-only")
            (context / "Dockerfile").write_text('''FROM busybox:1.36
COPY . /context/
RUN test ! -e /context/.env && test ! -e /context/android && \\
    test ! -e /context/.agents && test ! -e /context/build/app && \\
    test -f /context/build/web/index.html && \\
    test -f /context/build/web/assets/.env && \\
    test -f /context/deploy/web/nginx.conf
''')
            try:
                subprocess.run(["docker", "build", "-q", "-t", name, str(context)], check=True)
            finally:
                subprocess.run(["docker", "image", "rm", name], capture_output=True)


if __name__ == "__main__":
    unittest.main()
