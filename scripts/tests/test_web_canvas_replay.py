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
const calls = [];
class HTMLCanvasElement {
  getContext(type, attrs) { calls.push({ type, attrs: attrs ?? null }); return {}; }
}
const sandbox = { HTMLCanvasElement, URLSearchParams, location: { search: '', pathname: '/', hash: '' },
  history: { replaceState() {} }, sessionStorage: { setItem() {} }, navigator: {}, window: {} };
vm.createContext(sandbox);
for (const source of JSON.parse(process.argv[1])) vm.runInContext(source, sandbox);
const canvas = new sandbox.HTMLCanvasElement();
const callerAttrs = { antialias: true };
canvas.getContext('webgl2', callerAttrs);
canvas.getContext('webgl');
canvas.getContext('experimental-webgl', { preserveDrawingBuffer: false });
canvas.getContext('2d', { alpha: false });
canvas.getContext('bitmaprenderer');
console.log(JSON.stringify({ calls, callerAttrs }));
"""


def inline_scripts():
    return re.findall(r"<script>(.*?)</script>", INDEX, flags=re.S)


@unittest.skipUnless(shutil.which("node"), "node is required to run the page script")
class WebCanvasReplayTest(unittest.TestCase):
    def run_page(self):
        out = subprocess.run(
            ["node", "-e", HARNESS, json.dumps(inline_scripts())],
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

    def test_patch_runs_before_flutter_creates_its_canvas(self):
        patch = next(i for i, s in enumerate(INDEX.split("<script")) if "preserveDrawingBuffer" in s)
        boot = next(i for i, s in enumerate(INDEX.split("<script")) if "flutter_bootstrap.js" in s)
        self.assertLess(patch, boot)


if __name__ == "__main__":
    unittest.main()
