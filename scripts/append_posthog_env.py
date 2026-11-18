"""Add validated, public PostHog client settings to a Flutter dotenv."""

import os
import pathlib
import sys

from prepare_web_env import ANALYTICS_KEYS, analytics_lines


def append(flavor, target):
    if flavor not in ("staging", "production"):
        raise ValueError("expected staging or production")

    values = {name: os.environ.get(name, "") for name in ANALYTICS_KEYS}
    settings = analytics_lines(flavor, values)
    if not settings:
        raise ValueError("ENABLE_POSTHOG must be true")

    path = pathlib.Path(target)
    if not path.is_file():
        raise ValueError("dotenv file must exist")
    lines = path.read_text().splitlines()
    lines = [
        line for line in lines if line.partition("=")[0].strip() not in ANALYTICS_KEYS
    ]
    lines.extend(settings.rstrip("\n").splitlines())
    path.write_text("\n".join(lines) + "\n")


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("usage: append_posthog_env.py staging|production DOTENV")
        append(*sys.argv[1:])
    except ValueError as error:
        print("PostHog environment error: " + str(error), file=sys.stderr)
        sys.exit(1)
