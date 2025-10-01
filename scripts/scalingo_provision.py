#!/usr/bin/env python3
"""Provision Scalingo apps from infra/scalingo-manifest.json.

Usage:
  python scripts/scalingo_provision.py --env staging --dry-run
  python scripts/scalingo_provision.py --env both
"""
import argparse
import json
import shlex
import subprocess
import sys
from pathlib import Path
from typing import Any, Dict, Optional, Set

DEFAULT_MANIFEST = Path("infra/scalingo-manifest.json")
SUPPORTED_ENVS = {"staging", "production"}
ADDON_PLANS = {
    "postgres": {"addon": "postgresql", "plan": "postgresql-sandbox"},
    "redis": {"addon": "redis", "plan": "redis-sandbox"}
}
PLACEHOLDER_PREFIX = "<"
PLACEHOLDER_SUFFIX = ">"
ENABLE_INTEGRATION = False
STOP_ON_ERROR = False


def load_manifest(path: Path) -> dict:
    if not path.exists():
        raise SystemExit(f"Manifest not found: {path}")
    return json.loads(path.read_text())


def load_secrets(prefix: Optional[str], envs: Set[str]) -> Dict[str, Dict[str, Dict[str, str]]]:
    secrets: Dict[str, Dict[str, Dict[str, str]]] = {env: {} for env in envs}
    if not prefix:
        return secrets

    for env in envs:
        candidate_files = [
            Path(f"{prefix}.{env}.json"),
            Path(prefix) if prefix.endswith(f".{env}.json") else None
        ]
        for file in candidate_files:
            if file is None or not file.exists():
                continue
            data = json.loads(file.read_text())
            if env in data and isinstance(data[env], dict):
                env_map = data[env]
            else:
                env_map = data
            # normalise keys to strings -> dicts
            secrets[env] = {
                service: {str(k): v for k, v in (values or {}).items()}
                for service, values in env_map.items()
            }
            break
    return secrets


def is_placeholder(value: Any) -> bool:
    return (
        isinstance(value, str)
        and value.startswith(PLACEHOLDER_PREFIX)
        and value.endswith(PLACEHOLDER_SUFFIX)
    )


def placeholder_value(key: str, env_name: str) -> str:
    return f"TBD_{env_name.upper()}_{key}"


def run(cmd: str, *, dry_run: bool) -> None:
    print(cmd)
    if dry_run:
        return
    result = subprocess.run(shlex.split(cmd))
    if result.returncode != 0 and STOP_ON_ERROR:
        raise subprocess.CalledProcessError(result.returncode, cmd)


def app_exists(app_name: str) -> bool:
    result = subprocess.run(
        ["scalingo", "apps-info", "--app", app_name],
        stdout=subprocess.DEVNULL,
        stderr=subprocess.DEVNULL
    )
    return result.returncode == 0


def domain_exists(app_name: str, domain: str) -> bool:
    result = subprocess.run(
        ["scalingo", "domains", "--app", app_name],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True
    )
    if result.returncode != 0:
        return False
    return domain in result.stdout


def addon_exists(app_name: str, addon_type: str) -> bool:
    result = subprocess.run(
        ["scalingo", "addons", "--app", app_name],
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
        text=True
    )
    if result.returncode != 0:
        return False
    return addon_type in result.stdout


def format_env_set(env: dict) -> str:
    parts = []
    for key, value in sorted(env.items()):
        if value is None:
            continue
        parts.append(f"{key}={shlex.quote(str(value))}")
    return " ".join(parts)


def collect_env(
    process: dict,
    env_name: str,
    service_name: str,
    secrets: dict[str, dict[str, dict[str, str]]]
) -> tuple[dict, list[str]]:
    required = process["env"].get("required", [])
    target_values = dict(process["env"].get(env_name, {}))
    secret_values = secrets.get(env_name, {}).get(service_name, {})
    target_values.update(secret_values)
    missing: list[str] = []

    for key in required:
        value = target_values.get(key)
        if value is None or is_placeholder(value):
            if key == "DATABASE_URL":
                target_values[key] = "$SCALINGO_POSTGRESQL_URL"
                continue
            if key == "REDIS_URL":
                target_values[key] = "$SCALINGO_REDIS_URL"
                continue
            if key == "S3_BUCKET":
                # handled upstream by defaults, but treat missing placeholders as todo
                missing.append(key)
                target_values[key] = placeholder_value(key, env_name)
                continue
            missing.append(key)
            target_values[key] = placeholder_value(key, env_name)
            continue
    return target_values, missing


def provision_service(
    service: dict,
    env_name: str,
    *,
    dry_run: bool,
    deploy_defaults: dict,
    project_defaults: dict,
    secrets: dict[str, dict[str, dict[str, str]]]
) -> None:
    app_name = service["applications"][env_name]
    repo = service["repo"]["url"]
    repo_name = service["repo"]["name"]
    project = service.get("projects", {}).get(env_name) or project_defaults.get(env_name)

    print(f"\n### {service['name']} ({env_name})")
    if not dry_run and app_exists(app_name):
        print(f"# App {app_name} already exists, skipping creation")
    else:
        create_cmd = f"scalingo create {app_name}"
        if project:
            create_cmd = f"scalingo create --project-id {project} {app_name}"
        run(create_cmd, dry_run=dry_run)

    for proc_name, proc in service["processes"].items():
        for addon in proc.get("addons", []):
            plan_info = ADDON_PLANS.get(addon)
            if not plan_info:
                continue
            addon_name = f"{service['name']}-{env_name}-{addon}"
            if not dry_run and addon_exists(app_name, plan_info["addon"]):
                print(f"# Addon {plan_info['addon']} already present on {app_name}")
            else:
                run(
                    f"scalingo addons-add {plan_info['addon']} {plan_info['plan']} -a {app_name}",
                    dry_run=dry_run
                )

        env_values, missing = collect_env(proc, env_name, service["name"], secrets)
        for key, value in sorted(env_values.items()):
            cmd = f"scalingo env-set {shlex.quote(key + '=' + str(value))} -a {app_name}"
            run(cmd, dry_run=dry_run)
        if missing:
            print(f"# TODO provide values for {', '.join(sorted(set(missing)))}")

        scale_value = proc.get("scale", {}).get(env_name)
        if scale_value is not None:
            run(f"scalingo scale {proc_name}:{scale_value} -a {app_name}", dry_run=dry_run)

    domain = service.get("subdomains", {}).get(env_name)
    if domain:
        if not dry_run and domain_exists(app_name, domain):
            print(f"# Domain {domain} already present on {app_name}")
        else:
            run(f"scalingo domains-add {domain} -a {app_name}", dry_run=dry_run)

    repo_slug = repo.replace("https://github.com/", "").removesuffix(".git")
    service_deploy = service.get("deploy", {})
    branch = service_deploy.get(env_name) or deploy_defaults.get(f"{env_name}_branch")
    if ENABLE_INTEGRATION and branch:
        repo_url = f"https://github.com/{repo_slug}"
        cmd = (
            "scalingo integration-link-create"
            f" --app {app_name}"
            f" --branch {branch} --auto-deploy"
            f" {repo_url}"
        )
        run(cmd, dry_run=dry_run)

    print(f"# Link git remote from repo {repo_name}: git remote add scalingo git@scalingo.com:{app_name}.git")


def main() -> None:
    parser = argparse.ArgumentParser(description="Provision Scalingo apps from manifest")
    parser.add_argument("--manifest", type=Path, default=DEFAULT_MANIFEST)
    parser.add_argument("--env", choices=["staging", "production", "both"], default="both")
    parser.add_argument("--dry-run", action="store_true", help="Print commands without executing")
    parser.add_argument(
        "--secrets-prefix",
        default="infra/scalingo-secrets",
        help="Base path (without .<env>.json) for secrets overrides"
    )
    args = parser.parse_args()

    manifest = load_manifest(args.manifest)
    services = manifest.get("services", [])
    globals_section = manifest.get("globals", {})
    deploy_defaults = globals_section.get("deploy", {})
    project_defaults = globals_section.get("projects", {})

    target_envs = list(SUPPORTED_ENVS) if args.env == "both" else [args.env]
    secrets = load_secrets(args.secrets_prefix, set(target_envs))

    for service in services:
        if not service.get("enabled", True):
            continue
        service.setdefault("deploy", {})
        for env_name in target_envs:
            provision_service(
                service,
                env_name,
                dry_run=args.dry_run,
                deploy_defaults=deploy_defaults,
                project_defaults=project_defaults,
                secrets=secrets
            )


if __name__ == "__main__":
    try:
        main()
    except subprocess.CalledProcessError as exc:
        sys.exit(exc.returncode)
