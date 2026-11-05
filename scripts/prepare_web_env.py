"""Write a minimal public Flutter dotenv from APP_ENV_FILE; never source it."""
import os
import pathlib
import re
import sys
from urllib.parse import urlsplit

ANALYTICS_KEYS = ("ENABLE_POSTHOG", "POSTHOG_API_KEY", "POSTHOG_HOST", "POSTHOG_ENVIRONMENT")


def analytics_lines(flavor, values):
    """Analytics settings to ship, or nothing: it stays off unless explicitly enabled."""
    if values.get("ENABLE_POSTHOG", "").lower() != "true":
        return ""
    api_key = values.get("POSTHOG_API_KEY", "")
    host = values.get("POSTHOG_HOST") or "https://us.i.posthog.com"
    environment = values.get("POSTHOG_ENVIRONMENT", "")
    # Project keys start with phc_; phx_ is a personal key and must never ship.
    if not re.fullmatch(r"phc_[A-Za-z0-9]{20,}", api_key):
        raise ValueError("POSTHOG_API_KEY must be a PostHog project key")
    if host != "https://us.i.posthog.com":
        raise ValueError("POSTHOG_HOST must be https://us.i.posthog.com")
    if environment != flavor:
        raise ValueError("POSTHOG_ENVIRONMENT must be " + flavor)
    return (f"ENABLE_POSTHOG=true\nPOSTHOG_API_KEY={api_key}\n"
            f"POSTHOG_HOST={host}\nPOSTHOG_ENVIRONMENT={environment}\n")


def prepare(flavor, target):
    if flavor not in ("staging", "production"):
        raise ValueError("expected staging or production")
    key = "BASE_URL_DEV" if flavor == "staging" else "BASE_URL_PROD"
    required = {key, "GOOGLE_SERVER_CLIENT_ID"}
    allowed = required | set(ANALYTICS_KEYS)
    values = {}
    for line in os.environ.get("APP_ENV_FILE", "").splitlines():
        name, separator, value = line.partition("=")
        name = name.strip()
        if not separator or name not in allowed:
            continue
        if name in values:
            raise ValueError("duplicate " + name)
        value = value.strip()
        if len(value) >= 2 and value[0] == value[-1] and value[0] in "\"'":
            value = value[1:-1]
        values[name] = value
    overrides = {name: os.environ[name] for name in ANALYTICS_KEYS if name in os.environ}
    if overrides:
        if len(overrides) != len(ANALYTICS_KEYS):
            raise ValueError("all PostHog environment secrets must be set")
        values.update(overrides)
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
    pathlib.Path(target).write_text(
        f"{key}={api_origin}\nGOOGLE_SERVER_CLIENT_ID={client}\nENABLE_DEMO_LOGIN=false\n"
        + analytics_lines(flavor, values))


if __name__ == "__main__":
    try:
        if len(sys.argv) != 3:
            raise ValueError("usage: prepare_web_env.py staging|production OUTPUT")
        prepare(*sys.argv[1:])
    except ValueError as error:
        print("Web environment error: " + str(error), file=sys.stderr)
        sys.exit(1)
