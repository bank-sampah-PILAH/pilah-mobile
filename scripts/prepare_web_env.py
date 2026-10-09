"""Write a minimal public Flutter dotenv from APP_ENV_FILE; never source it."""
import os
import pathlib
import re
import sys
from urllib.parse import urlsplit


def prepare(flavor, target):
    if flavor not in ("staging", "production"):
        raise ValueError("expected staging or production")
    key = "BASE_URL_DEV" if flavor == "staging" else "BASE_URL_PROD"
    required = {key, "GOOGLE_SERVER_CLIENT_ID"}
    values = {}
    for line in os.environ.get("APP_ENV_FILE", "").splitlines():
        name, separator, value = line.partition("=")
        name = name.strip()
        if not separator or name not in required:
            continue
        if name in values:
            raise ValueError("duplicate " + name)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[name] = value
    if any(not values.get(name) for name in required):
        raise ValueError("APP_ENV_FILE must provide " + key + " and GOOGLE_SERVER_CLIENT_ID")
    api = values[key]
    url = urlsplit(api)
    if (url.scheme != "https" or not url.hostname or url.username or url.password
            or url.query or url.fragment or url.path not in ("", "/", "/api/v1/")
            or not re.fullmatch(r"[a-zA-Z0-9.-]+", url.netloc)
            or url.hostname in ("localhost", "dummyjson.com")):
        raise ValueError(key + " must be an HTTPS API origin, optionally ending in /api/v1/")
    api_origin = f"{url.scheme}://{url.netloc}"
    if flavor == "staging" and api_origin != "https://pilah-be-staging.fly.dev":
        raise ValueError("staging API must use pilah-be-staging.fly.dev")
    client = values["GOOGLE_SERVER_CLIENT_ID"]
    if not re.fullmatch(r"[0-9]+-[a-zA-Z0-9-]+\.apps\.googleusercontent\.com", client):
        raise ValueError("GOOGLE_SERVER_CLIENT_ID must be a Web OAuth client ID")
    # .env is an asset, not a secret store: discard every other supplied value.
    pathlib.Path(target).write_text(f"{key}={api_origin}\nGOOGLE_SERVER_CLIENT_ID={client}\nENABLE_DEMO_LOGIN=false\n")


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("usage: prepare_web_env.py staging|production OUTPUT")
        prepare(*sys.argv[1:])
    except ValueError as error:
        print("Web environment error: " + str(error), file=sys.stderr)
        sys.exit(1)
