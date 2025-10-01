#!/usr/bin/env python3
"""Provision staging/production DNS records on Cloudflare.
Requires env vars: CF_API_TOKEN, CF_ACCOUNT_ID, CF_ZONE_ID_STAGING, CF_ZONE_ID_PROD.
"""
import os
import sys
import requests

API_BASE = "https://api.cloudflare.com/client/v4"

REQUIRED_ENV = [
    "CF_API_TOKEN",
    "CF_ACCOUNT_ID",
    "CF_ZONE_ID_STAGING",
    "CF_ZONE_ID_PROD",
    "CF_ZONE_NAME_STAGING",
    "CF_ZONE_NAME_PROD",
]

for key in REQUIRED_ENV:
    if not os.getenv(key):
        print(f"Missing environment variable {key}", file=sys.stderr)
        sys.exit(1)

token = os.environ["CF_API_TOKEN"]
account_id = os.environ["CF_ACCOUNT_ID"]
zone_staging = os.environ["CF_ZONE_ID_STAGING"]
zone_prod = os.environ["CF_ZONE_ID_PROD"]
zone_name_staging = os.environ["CF_ZONE_NAME_STAGING"].rstrip(".")
zone_name_prod = os.environ["CF_ZONE_NAME_PROD"].rstrip(".")

HEADERS = {
    "Authorization": f"Bearer {token}",
    "Content-Type": "application/json",
}

STAGING_RECORDS = [
    {"type": "CNAME", "name": "app", "content": "ewh-stg-app-web-frontend.osc-fr1.scalingo.io", "proxied": True},
    {"type": "CNAME", "name": "api", "content": "ewh-stg-svc-api-gateway.osc-fr1.scalingo.io", "proxied": True},
    {"type": "CNAME", "name": "admin", "content": "ewh-stg-app-admin-console.osc-fr1.scalingo.io", "proxied": True}
]

PROD_RECORDS = [
    {"type": "CNAME", "name": "app", "content": "ewh-prod-app-web-frontend.osc-fr1.scalingo.io", "proxied": True},
    {"type": "CNAME", "name": "api", "content": "ewh-prod-svc-api-gateway.osc-fr1.scalingo.io", "proxied": True},
    {"type": "CNAME", "name": "admin", "content": "ewh-prod-app-admin-console.osc-fr1.scalingo.io", "proxied": True},
    {"type": "CNAME", "name": "*.app", "content": "ewh-prod-svc-site-renderer.osc-fr1.scalingo.io", "proxied": True},
]

DMARC_RECORD = {
    "type": "TXT",
    "name": "_dmarc",
    "content": "v=DMARC1; p=none; rua=mailto:dmarc@ewhsaas.it",
    "proxied": False,
}

SSL_SETTINGS = {
    "ssl\n\n": "full",
    "always_use_https": True,
}


def ensure_record(zone_id: str, zone_name: str, record: dict) -> None:
    name = record["name"]
    resp = requests.get(
        f"{API_BASE}/zones/{zone_id}/dns_records",
        headers=HEADERS,
        params={"name": f"{name}.{zone_name}" if not name.endswith(zone_name) else name},
    )
    resp.raise_for_status()
    results = resp.json()["result"]
    data = {
        "type": record["type"],
        "name": name,
        "content": record["content"],
        "proxied": record.get("proxied", False),
        "ttl": record.get("ttl", 300),
    }
    if results:
        record_id = results[0]["id"]
        print(f"Updating {name}")
        requests.put(
            f"{API_BASE}/zones/{zone_id}/dns_records/{record_id}",
            headers=HEADERS,
            json=data,
        ).raise_for_status()
    else:
        print(f"Creating {name}")
        requests.post(
            f"{API_BASE}/zones/{zone_id}/dns_records",
            headers=HEADERS,
            json=data,
        ).raise_for_status()


def apply_records(zone_id: str, zone_name: str, records: list[dict]) -> None:
    for record in records:
        ensure_record(zone_id, zone_name, record)
    ensure_record(zone_id, zone_name, DMARC_RECORD)


def update_ssl(zone_id: str) -> None:
    for setting, value in SSL_SETTINGS.items():
        setting_key = setting.strip()
        print(f"Setting {setting_key} => {value}")
        resp = requests.patch(
            f"{API_BASE}/zones/{zone_id}/settings/{setting_key}",
            headers=HEADERS,
            json={"value": value},
        )
        try:
            resp.raise_for_status()
        except requests.HTTPError as exc:
            if resp.status_code == 403:
                print(f"Warning: cannot set {setting_key} (403 Forbidden)")
            else:
                raise exc


if __name__ == "__main__":
    apply_records(zone_staging, zone_name_staging, STAGING_RECORDS)
    update_ssl(zone_staging)

    apply_records(zone_prod, zone_name_prod, PROD_RECORDS)
    update_ssl(zone_prod)

    print("Cloudflare DNS/CDN configuration applied.")
