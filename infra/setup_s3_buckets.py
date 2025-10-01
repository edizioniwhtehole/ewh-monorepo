#!/usr/bin/env python3
"""Provision Wasabi buckets for static assets and user-generated content per service."""
import json
import os
import sys
from pathlib import Path

CONFIG_FILE = Path(__file__).with_name("wasabi_buckets.json")
REGION = os.getenv("WASABI_REGION", "eu-west-2")
ENDPOINT = os.getenv("WASABI_ENDPOINT", "s3.eu-west-2.wasabisys.com")
ACCESS_KEY = os.getenv("WASABI_ACCESS_KEY")
SECRET_KEY = os.getenv("WASABI_SECRET_KEY")

if not ACCESS_KEY or not SECRET_KEY:
    print("Missing WASABI_ACCESS_KEY or WASABI_SECRET_KEY", file=sys.stderr)
    sys.exit(1)

import boto3

session = boto3.session.Session(
    aws_access_key_id=ACCESS_KEY,
    aws_secret_access_key=SECRET_KEY,
    region_name=REGION,
)
s3 = session.client("s3", endpoint_url=f"https://{ENDPOINT}")

config = json.loads(CONFIG_FILE.read_text())
tenants_file = Path(__file__).with_name("wasabi_tenants.json")
tenant_config = json.loads(tenants_file.read_text()) if tenants_file.exists() else {}

def bucket_structure(service_prefix: str) -> list[str]:
    manifest = json.loads(Path('infra/scalingo-manifest.json').read_text())
    return [f"{service_prefix}{svc}/" for svc in sorted({svc['name'] for svc in manifest['services']})]


def ensure_bucket(bucket_name: str, prefixes: list[str]) -> None:
    try:
        s3.head_bucket(Bucket=bucket_name)
        print(f"Bucket {bucket_name} already exists")
    except s3.exceptions.ClientError:
        print(f"Creating bucket {bucket_name}")
        s3.create_bucket(
            Bucket=bucket_name,
            CreateBucketConfiguration={"LocationConstraint": REGION}
        )
    for prefix in prefixes:
        print(f"Ensuring {bucket_name}:{prefix}")
        s3.put_object(Bucket=bucket_name, Key=prefix)


# Base buckets for tenant 1 / shared staging
for entry in config.get("staging", []):
    ensure_bucket(entry["bucket"], entry.get("structure", []))
for entry in config.get("production", []):
    ensure_bucket(entry["bucket"], entry.get("structure", []))

# Tenant-specific buckets (production only unless staging flag true)
for tenant_id, tenant_data in tenant_config.items():
    prod_bucket = tenant_data.get("prod_bucket") or f"ewh-prod-tenant-{tenant_id}"
    prefixes = tenant_data.get("structure") or bucket_structure(f"production/tenant-{tenant_id}/")
    ensure_bucket(prod_bucket, prefixes)

    if tenant_data.get("staging", False):
        staging_bucket = tenant_data.get("staging_bucket") or f"ewh-staging-tenant-{tenant_id}"
        staging_prefixes = tenant_data.get("staging_structure") or bucket_structure(f"staging/tenant-{tenant_id}/")
        ensure_bucket(staging_bucket, staging_prefixes)

print("Buckets and structure provisioned")
