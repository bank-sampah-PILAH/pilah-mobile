"""The web shell keeps WebGL pixels readable so PostHog replay is not blank on iOS Safari."""
import json
import pathlib
import re
import shutil
import subprocess
import unittest

ROOT = pathlib.Path(__file__).resolve().parents[2]
INDEX = (ROOT / "web/index.html").read_text()

# Runs the page's inline scripts against a fake canvas and prints the attributes
# each getContext call reaches the browser with.
HARNESS = """
const vm = require('node:vm');
const vendor = process.argv[1];
const calls = [];
class HTMLCanvasElement {
  getContext(type, attrs) { calls.push({ type, attrs: attrs ?? null }); return {}; }
}
const sandbox = { HTMLCanvasElement, URLSearchParams, location: { search: '', pathname: '/', hash: '' },
  history: { replaceState() {} }, sessionStorage: { setItem() {} }, navigator: { vendor }, window: {} };
vm.createContext(sandbox);
const original = HTMLCanvasElement.prototype.getContext;
for (const source of JSON.parse(process.argv[2])) vm.runInContext(source, sandbox);
const canvas = new sandbox.HTMLCanvasElement();
const callerAttrs = { antialias: true };
canvas.getContext('webgl2', callerAttrs);
canvas.getContext('webgl');
canvas.getContext('experimental-webgl', { preserveDrawingBuffer: false });
canvas.getContext('2d', { alpha: false });
canvas.getContext('bitmaprenderer');
console.log(JSON.stringify({ calls, callerAttrs, untouched: HTMLCanvasElement.prototype.getContext === original }));
"""


# navigator.vendor as reported by Playwright's WebKit, Chromium and Firefox. Every
# iOS browser reports Apple's because it must use WebKit.
APPLE = "Apple Computer, Inc."


def inline_scripts():
    return re.findall(r"<script(?![^>]*\bsrc=)[^>]*>(.*?)</script>", INDEX, flags=re.S)


@unittest.skipUnless(shutil.which("node"), "node is required to run the page script")
class WebCanvasReplayTest(unittest.TestCase):
    def run_page(self, vendor=APPLE):
        out = subprocess.run(
            ["node", "-e", HARNESS, vendor, json.dumps(inline_scripts())],
            check=True, capture_output=True, text=True,
        ).stdout
        return json.loads(out)

    def test_webgl_contexts_keep_their_buffer_so_the_canvas_can_be_read_later(self):
        calls = self.run_page()["calls"]
        for call in calls[:3]:
            with self.subTest(context=call["type"]):
                self.assertIs(call["attrs"]["preserveDrawingBuffer"], True)

    def test_other_context_requests_are_left_alone(self):
        calls = self.run_page()["calls"]
        self.assertEqual(calls[3], {"type": "2d", "attrs": {"alpha": False}})
        self.assertEqual(calls[4], {"type": "bitmaprenderer", "attrs": None})

    def test_attributes_the_engine_asked_for_survive_and_are_not_mutated(self):
        result = self.run_page()
        self.assertEqual(result["calls"][0]["attrs"]["antialias"], True)
        self.assertEqual(result["callerAttrs"], {"antialias": True})

    def test_browsers_that_are_not_webkit_keep_their_original_getcontext(self):
        for vendor in ("Google Inc.", ""):
            with self.subTest(vendor=vendor):
                result = self.run_page(vendor)
                self.assertIs(result["untouched"], True)
                self.assertEqual(result["calls"][0], {"type": "webgl2", "attrs": {"antialias": True}})
                self.assertEqual(result["calls"][1], {"type": "webgl", "attrs": None})
                self.assertEqual(result["calls"][2]["attrs"], {"preserveDrawingBuffer": False})

    def test_apple_vendor_is_patched(self):
        result = self.run_page(APPLE)
        self.assertIs(result["untouched"], False)

    def test_patch_runs_before_flutter_creates_its_canvas(self):
        patch = next(i for i, s in enumerate(INDEX.split("<script")) if "preserveDrawingBuffer" in s)
        boot = next(i for i, s in enumerate(INDEX.split("<script")) if "flutter_bootstrap.js" in s)
        self.assertLess(patch, boot)


if __name__ == "__main__":
    unittest.main()
