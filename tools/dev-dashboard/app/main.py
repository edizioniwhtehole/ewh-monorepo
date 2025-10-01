import asyncio
import os
import json
import uuid
from datetime import datetime
from pathlib import Path
from typing import List, Literal, Optional
from urllib.parse import urlparse

import httpx
from fastapi import FastAPI, HTTPException, Request
from fastapi.middleware.cors import CORSMiddleware
from fastapi.responses import HTMLResponse
from fastapi.templating import Jinja2Templates
from pydantic import BaseModel, Field

app = FastAPI(title="EWH Dev Dashboard", version="1.0.0")

app.add_middleware(
    CORSMiddleware,
    allow_origins=["*"],
    allow_credentials=True,
    allow_methods=["*"],
    allow_headers=["*"],
)

APP_ROOT = Path(__file__).resolve().parent
SCRIPTS_ROOT = Path(os.environ.get("SCRIPTS_ROOT", APP_ROOT.parent.parent / "scripts")).resolve()
WORKSPACE_ROOT = SCRIPTS_ROOT.parent
TEMPLATES = Jinja2Templates(directory=str(APP_ROOT / "templates"))
KNOWLEDGE_FILE = APP_ROOT / "data" / "knowledge.json"


class ScriptInfo(BaseModel):
    name: str
    path: str
    description: str | None = None


class RunRequest(BaseModel):
    args: List[str] | None = None


class RunResult(BaseModel):
    script: str
    exit_code: int
    stdout: str
    stderr: str


class KnowledgeCreate(BaseModel):
    title: str = Field(..., max_length=200)
    description: str = Field(..., max_length=4000)
    tags: List[str] | None = None


class KnowledgeEntry(KnowledgeCreate):
    created_at: str
    id: str


class PromptContentRequest(BaseModel):
    path: str = Field(..., max_length=2000)
    content: str


class DockerActionRequest(BaseModel):
    action: Literal["start", "stop", "restart"]
    names: List[str] = Field(..., min_length=1)


class ScalingoActionRequest(BaseModel):
    action: Literal["restart"]
    names: List[str] = Field(..., min_length=1)


class GitActionRequest(BaseModel):
    action: Literal["status", "pull", "fetch"]
    repos: List[str] = Field(..., min_length=1)


def _discover_scripts() -> List[Path]:
    if not SCRIPTS_ROOT.exists():
        return []
    return sorted(SCRIPTS_ROOT.glob("*.sh"))


def _load_knowledge() -> List[dict]:
    if not KNOWLEDGE_FILE.exists():
        return []
    try:
        with KNOWLEDGE_FILE.open("r", encoding="utf-8") as handle:
            data = json.load(handle)
            if isinstance(data, list):
                return data
    except json.JSONDecodeError:
        return []
    return []


def _save_knowledge(entries: List[dict]) -> None:
    KNOWLEDGE_FILE.parent.mkdir(parents=True, exist_ok=True)
    with KNOWLEDGE_FILE.open("w", encoding="utf-8") as handle:
        json.dump(entries, handle, ensure_ascii=False, indent=2)


def _ensure_safe_script(script_name: str) -> Path:
    script_path = (SCRIPTS_ROOT / script_name).resolve()
    try:
        script_path.relative_to(SCRIPTS_ROOT)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Script fuori dalla directory consentita") from exc
    if not script_path.exists() or not script_path.is_file():
        raise HTTPException(status_code=404, detail="Script non trovato")
    if not os.access(script_path, os.X_OK):
        raise HTTPException(status_code=400, detail="Script non è eseguibile")
    return script_path


def _resolve_workspace_file(path_value: str) -> Path:
    if not path_value:
        raise HTTPException(status_code=400, detail="Percorso non valido")
    try:
        candidate = Path(path_value).expanduser()
    except (OSError, RuntimeError) as exc:
        raise HTTPException(status_code=400, detail="Percorso non valido") from exc
    if not candidate.is_absolute():
        candidate = (WORKSPACE_ROOT / candidate).resolve()
    try:
        candidate.relative_to(WORKSPACE_ROOT)
    except ValueError as exc:
        raise HTTPException(status_code=400, detail="Percorso fuori dal workspace") from exc
    return candidate


def _iter_local_repositories() -> List[Path]:
    repos: List[Path] = []
    for child in WORKSPACE_ROOT.iterdir():
        if not child.is_dir():
            continue
        name = child.name
        if name.startswith('.') or name in {'.git', '__pycache__', 'ewh-master', 'tools', 'scripts', 'infra', 'ops-infra'}:
            continue
        if (child / '.git').is_dir() or name.startswith(('app-', 'svc-', 'svc_', 'app_')):
            repos.append(child)
    return sorted(repos, key=lambda item: item.name.lower())


@app.get("/api/scripts", response_model=List[ScriptInfo])
async def list_scripts() -> List[ScriptInfo]:
    scripts = []
    for path in _discover_scripts():
        descr = None
        try:
            with path.open("r", encoding="utf-8") as handle:
                first_line = handle.readline().strip()
                if first_line.startswith("#"):
                    descr = first_line.lstrip("# ")
        except OSError:
            descr = None
        scripts.append(ScriptInfo(name=path.name, path=str(path), description=descr))
    return scripts


@app.post("/api/scripts/{script_name}/run", response_model=RunResult)
async def run_script(script_name: str, payload: RunRequest | None = None) -> RunResult:
    script_path = _ensure_safe_script(script_name)
    args = payload.args if payload and payload.args else []
    cmd = [str(script_path), *args]

    process = await asyncio.create_subprocess_exec(
        *cmd,
        stdout=asyncio.subprocess.PIPE,
        stderr=asyncio.subprocess.PIPE,
        cwd=str(SCRIPTS_ROOT),
    )
    stdout_bytes, stderr_bytes = await process.communicate()
    stdout = stdout_bytes.decode("utf-8", errors="replace")
    stderr = stderr_bytes.decode("utf-8", errors="replace")

    return RunResult(
        script=script_name,
        exit_code=process.returncode,
        stdout=stdout,
        stderr=stderr,
    )


async def _run_command(command: List[str], cwd: Path | None = None) -> RunResult:
    try:
        process = await asyncio.create_subprocess_exec(
            *command,
            stdout=asyncio.subprocess.PIPE,
            stderr=asyncio.subprocess.PIPE,
            cwd=str(cwd) if cwd else None,
        )
        stdout_bytes, stderr_bytes = await process.communicate()
        stdout = stdout_bytes.decode("utf-8", errors="replace")
        stderr = stderr_bytes.decode("utf-8", errors="replace")
        exit_code = process.returncode
    except FileNotFoundError:
        exit_code = -1
        stdout = ""
        stderr = f"Comando non trovato: {command[0]}"
    except Exception as exc:  # pragma: no cover - fallback
        exit_code = -1
        stdout = ""
        stderr = f"Errore esecuzione comando: {exc}"

    return RunResult(
        script=" ".join(command),
        exit_code=exit_code,
        stdout=stdout,
        stderr=stderr,
    )


def _read_config_list(env_var: str, file_env_var: str | None = None) -> List[str]:
    items: List[str] = []
    raw = os.environ.get(env_var, "")
    if raw:
        for line in raw.splitlines():
            for part in line.split():
                cleaned = part.strip()
                if cleaned and not cleaned.startswith("#"):
                    items.append(cleaned)
    if file_env_var:
        file_path = os.environ.get(file_env_var)
        if file_path:
            raw_path = Path(file_path).expanduser()
            candidate_paths = [raw_path]
            if not raw_path.is_absolute():
                candidate_paths.extend([
                    Path.cwd() / raw_path,
                    WORKSPACE_ROOT / raw_path,
                    (APP_ROOT.parent / raw_path),
                ])

            file_on_disk: Path | None = None
            for candidate in candidate_paths:
                try:
                    resolved = candidate.resolve()
                except FileNotFoundError:
                    continue
                if resolved.exists():
                    file_on_disk = resolved
                    break

            if file_on_disk and file_on_disk.exists():
                with file_on_disk.open("r", encoding="utf-8") as handle:
                    for line in handle:
                        part = line.strip()
                        if part and not part.startswith("#"):
                            items.append(part)
    if not items:
        return []
    deduped: dict[str, None] = {}
    for entry in items:
        deduped.setdefault(entry, None)
    return list(deduped.keys())


def _ensure_endpoint_url(value: str | None) -> str | None:
    if not value:
        return None
    value = value.strip()
    if not value:
        return None
    if not value.startswith("http://") and not value.startswith("https://"):
        return f"https://{value}"
    return value


def _status_entry(label: str, status: str, details: str, hint: str | None = None, **extra: object) -> dict:
    entry = {"label": label, "status": status, "details": details}
    if hint:
        entry["hint"] = hint
    if extra:
        entry.update(extra)
    return entry


def _overall_status(entries: List[dict], default: str = "info") -> str:
    if not entries:
        return default
    if any(e.get("status") == "error" for e in entries):
        return "error"
    if any(e.get("status") == "warn" for e in entries):
        return "warn"
    if any(e.get("status") == "ok" for e in entries):
        return "ok"
    return default


def _guess_environment_from_db_url(url: str) -> str:
    try:
        parsed = urlparse(url)
    except Exception:
        return "staging"
    host = (parsed.hostname or "").lower()
    if not host:
        return "staging"
    if host in {"localhost", "127.0.0.1"} or host.endswith(".local"):
        return "local"
    if any(token in host for token in ("staging", "sandbox", "dev", "test")):
        return "staging"
    if any(token in host for token in ("prod", "production", "live")):
        return "production"
    return "staging"


def _compute_environment_metrics(categories: List[dict]) -> tuple[dict, List[dict]]:
    metrics: dict[str, dict[str, int]] = {}
    critical: List[dict] = []
    for card in categories:
        environment = card.get("environment")
        if environment not in {"local", "staging", "production"}:
            continue
        env_metrics = metrics.setdefault(environment, {"total": 0, "ok": 0, "warn": 0, "error": 0})
        for entry in card.get("entries", []):
            status = (entry.get("status") or "").lower()
            if status not in {"ok", "warn", "error"}:
                continue
            env_metrics["total"] += 1
            env_metrics[status] += 1
            if status == "error":
                critical.append(
                    {
                        "category_id": card.get("id"),
                        "category_title": card.get("title"),
                        "entry": entry.get("label"),
                        "details": entry.get("details"),
                        "environment": environment,
                    }
                )
    for env_metrics in metrics.values():
        env_metrics["active"] = env_metrics.get("ok", 0)
        env_metrics["degraded"] = env_metrics.get("warn", 0)
        env_metrics["down"] = env_metrics.get("error", 0)
    return metrics, critical


def _status_counters(entries: List[dict]) -> dict[str, int]:
    counters = {"total": len(entries), "ok": 0, "warn": 0, "error": 0}
    for entry in entries:
        status = (entry.get("status") or "").lower()
        if status in {"ok", "warn", "error"}:
            counters[status] += 1
    return counters


def _load_costs_breakdown() -> dict:
    raw = os.environ.get("STATUS_COSTS")
    file_path = os.environ.get("STATUS_COSTS_FILE")
    data = None
    source = None
    error = None

    if file_path:
        path_obj = Path(file_path).expanduser()
        candidates = [path_obj]
        if not path_obj.is_absolute():
            candidates.extend([
                Path.cwd() / path_obj,
                WORKSPACE_ROOT / path_obj,
                (APP_ROOT.parent / path_obj),
            ])
        resolved: Path | None = None
        for candidate in candidates:
            try:
                concrete = candidate.resolve()
            except FileNotFoundError:
                continue
            if concrete.exists():
                resolved = concrete
                break
        if resolved and resolved.exists():
            try:
                data = json.loads(resolved.read_text(encoding="utf-8"))
                source = str(resolved)
            except json.JSONDecodeError as exc:
                error = f"Impossibile leggere STATUS_COSTS_FILE ({exc})"
        else:
            error = "STATUS_COSTS_FILE indicato ma non trovato"

    if data is None and raw:
        try:
            data = json.loads(raw)
            source = "env:STATUS_COSTS"
            error = None
        except json.JSONDecodeError as exc:
            error = f"Impossibile leggere STATUS_COSTS ({exc})"

    return {"values": data or {}, "source": source, "error": error}


def _normalise_usage_entry(entry: dict) -> dict | None:
    if not isinstance(entry, dict):
        return None
    date = entry.get("date") or entry.get("day") or entry.get("timestamp")
    cpu = entry.get("cpu")
    if cpu is None:
        cpu = entry.get("cpu_percent") or entry.get("cpu_usage")
    disk = entry.get("disk_gb")
    if disk is None:
        disk = entry.get("disk") or entry.get("storage_gb") or entry.get("disk_usage")
    bucket = entry.get("bucket_gb") or entry.get("object_storage_gb")
    return {
        "date": date,
        "cpu": float(cpu) if cpu is not None else None,
        "disk_gb": float(disk) if disk is not None else None,
        "bucket_gb": float(bucket) if bucket is not None else None,
    }


def _normalise_usage_history(payload: dict | None) -> dict[str, List[dict]]:
    if not isinstance(payload, dict):
        return {}
    cleaned: dict[str, List[dict]] = {}
    for key, items in payload.items():
        if not isinstance(items, list):
            continue
        normalised: List[dict] = []
        for item in items:
            cleaned_item = _normalise_usage_entry(item)
            if not cleaned_item:
                continue
            normalised.append(cleaned_item)
        if normalised:
            cleaned[key] = normalised
    return cleaned


def _load_usage_history() -> dict:
    raw = os.environ.get("STATUS_USAGE_HISTORY")
    file_path = os.environ.get("STATUS_USAGE_HISTORY_FILE")
    data = None
    source = None
    error = None

    if file_path:
        candidate = Path(file_path).expanduser()
        candidates = [candidate]
        if not candidate.is_absolute():
            candidates.extend([
                Path.cwd() / candidate,
                WORKSPACE_ROOT / candidate,
                APP_ROOT.parent / candidate,
            ])
        resolved: Path | None = None
        for item in candidates:
            try:
                concrete = item.resolve()
            except FileNotFoundError:
                continue
            if concrete.exists():
                resolved = concrete
                break
        if resolved and resolved.exists():
            try:
                data = json.loads(resolved.read_text(encoding="utf-8"))
                source = str(resolved)
            except json.JSONDecodeError as exc:
                error = f"Impossibile leggere STATUS_USAGE_HISTORY_FILE ({exc})"
        else:
            error = "STATUS_USAGE_HISTORY_FILE indicato ma non trovato"

    if data is None and raw:
        try:
            data = json.loads(raw)
            source = "env:STATUS_USAGE_HISTORY"
            error = None
        except json.JSONDecodeError as exc:
            error = f"Impossibile leggere STATUS_USAGE_HISTORY ({exc})"

    values = _normalise_usage_history(data)
    return {"values": values, "source": source, "error": error}


def _is_placeholder_db_url(url: str) -> bool:
    if not url:
        return True
    lowered = url.lower()
    placeholders = [
        "postgres://user:pass@host:5432/dbname",
        "user:pass@host",
        "user:password@host",
        "postgres://username:password@hostname:5432/database",
    ]
    return any(token in lowered for token in placeholders)


async def _measure_bucket_usage(bucket: str, endpoint: str | None) -> dict:
    base_cmd = ["aws", "s3api", "list-objects-v2", "--bucket", bucket, "--output", "json", "--no-paginate"]
    if endpoint:
        base_cmd.extend(["--endpoint-url", endpoint.rstrip("/")])
    result = await _run_command(base_cmd)
    if result.exit_code != 0:
        detail = result.stderr or result.stdout or "Errore AWS CLI"
        return {"name": bucket, "status": "error", "error": detail.strip(), "type": "bucket", "environment": "global"}
    try:
        payload = json.loads(result.stdout or "{}")
    except json.JSONDecodeError as exc:
        return {"name": bucket, "status": "error", "error": f"JSON non valido: {exc}"}

    contents = payload.get("Contents") or []
    total_size = sum(int(item.get("Size") or 0) for item in contents)
    object_count = len(contents)
    truncated = bool(payload.get("IsTruncated")) or bool(payload.get("NextContinuationToken"))
    usage: dict = {
        "name": bucket,
        "size_bytes": None if truncated else total_size,
        "object_count": None if truncated else object_count,
        "partial": truncated,
        "status": "partial" if truncated else "ok",
        "type": "bucket",
        "environment": "global",
    }
    if truncated:
        usage["note"] = "Risultato parziale (listing troncato)"
    return usage


async def _measure_database_usage(db_url: str) -> dict:
    stats_query = (
        "SELECT pg_database_size(current_database()), "
        "SUM(CASE WHEN relkind = 'r' THEN reltuples ELSE 0 END)::bigint "
        "FROM pg_class;"
    )
    result = await _run_command(["psql", db_url, "-At", "-c", stats_query], cwd=None)
    environment = _guess_environment_from_db_url(db_url)
    if result.exit_code != 0:
        detail = result.stderr or result.stdout or "Errore interrogazione"
        return {"url": db_url, "status": "error", "environment": environment, "error": detail.strip(), "type": "manual"}
    line = (result.stdout or "").strip().splitlines()
    if not line:
        return {"url": db_url, "status": "error", "environment": environment, "error": "Risposta vuota"}
    first = line[0]
    size_str, _, rows_str = first.partition("|")
    try:
        size = int(float(size_str)) if size_str else 0
    except ValueError:
        size = 0
    try:
        rows = int(float(rows_str)) if rows_str else 0
    except ValueError:
        rows = 0
    return {
        "url": db_url,
        "status": "ok",
        "environment": environment,
        "size_bytes": size,
        "row_estimate": rows,
        "type": "manual",
    }


def _parse_scalingo_apps(output: str) -> List[dict]:
    entries: List[dict] = []
    for line in output.splitlines():
        line = line.strip()
        if not line.startswith("│"):
            continue
        cols = [col.strip() for col in line.strip("│").split("│")]
        if not cols or cols[0].lower() == "name":
            continue
        if len(cols) < 3:
            continue
        name = cols[0]
        role = cols[1] if len(cols) > 1 else ""
        status_txt = cols[2]
        status_lower = status_txt.lower()
        if "running" in status_lower:
            status = "ok"
        elif any(token in status_lower for token in ["starting", "initializing", "pending"]):
            status = "warn"
        else:
            status = "error"
        details = f"Role: {role} · Status: {status_txt}"
        entries.append(
            _status_entry(
                name,
                status,
                details,
                meta=status_txt,
                target={"type": "scalingo_app", "id": name},
                actions=["restart"],
            )
        )
    return entries


def _extract_scalingo_app_names(output: str) -> List[str]:
    return [entry["label"] for entry in _parse_scalingo_apps(output)]


def _parse_scalingo_addons_cli(app_name: str, output: str) -> List[dict]:
    entries: List[dict] = []
    for line in output.splitlines():
        line = line.strip()
        if not line.startswith("│"):
            continue
        cols = [col.strip() for col in line.strip("│").split("│")]
        if not cols or cols[0].lower() in {"addon", "add-on"}:
            continue
        addon_name = cols[0]
        if "postgres" not in addon_name.lower():
            continue
        addon_id = cols[1] if len(cols) > 1 else ""
        plan = cols[2] if len(cols) > 2 else ""
        status_txt = cols[3] if len(cols) > 3 else ""
        status_lower = status_txt.lower()
        if status_lower in ("running", "available", "provisioned"):
            status = "ok"
        elif any(token in status_lower for token in ["provision", "start", "build", "pending", "creating"]):
            status = "warn"
        else:
            status = "error"
        label = f"{app_name} · {addon_name}" if addon_name else app_name
        details = f"ID: {addon_id or '?'} · Plan: {plan or '?'} · Status: {status_txt or '?'}"
        entries.append(_status_entry(label, status, details, meta=status_txt or status))
    return entries


def _load_scalingo_credentials() -> tuple[str | None, str]:
    token = os.environ.get("SCALINGO_API_TOKEN")
    region = os.environ.get("SCALINGO_REGION", "osc-fr1")
    base_url = os.environ.get("SCALINGO_API_URL")

    config_file = Path(os.environ.get("SCALINGO_CONFIG_FILE", Path.home() / ".config" / "scalingo" / "config.json"))
    if not token and config_file.exists():
        try:
            data = json.loads(config_file.read_text(encoding="utf-8"))
            token = data.get("auth_token") or data.get("api_token") or data.get("token")
            region = data.get("region", region)
            base_url = data.get("api_url") or data.get("base_url") or base_url
        except json.JSONDecodeError:
            pass

    if not base_url:
        base_url = f"https://api.{region}.scalingo.com" if region else "https://api.osc-fr1.scalingo.com"

    return token, base_url.rstrip("/")


async def _fetch_scalingo_via_api() -> tuple[List[dict], str | None]:
    token, base_url = _load_scalingo_credentials()
    if not token:
        return [], "Imposta SCALINGO_API_TOKEN o la config locale"

    url = f"{base_url}/v1/apps"
    headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
    try:
        async with httpx.AsyncClient(timeout=10.0) as client:
            resp = await client.get(url, headers=headers)
        if resp.status_code != 200:
            return [], f"API Scalingo ha risposto {resp.status_code}: {resp.text[:200]}"
        data = resp.json()
        apps = data.get("apps", [])
        entries: List[dict] = []
        for app in apps:
            name = app.get("name", "(sconosciuto)")
            status_txt = app.get("status", "?")
            description = app.get("description")
            if not status_txt:
                last_deployment = app.get("last_deployment", {})
                status_txt = last_deployment.get("status", "?")
            status_lower = str(status_txt).lower()
            if status_lower in ("running", "started", "ok"):
                status = "ok"
            elif any(token in status_lower for token in ["starting", "initial", "build", "pending"]):
                status = "warn"
            else:
                status = "error"
            details = f"Status: {status_txt}"
            region = app.get("region") or app.get("provider", {}).get("region")
            if region:
                details += f" · Region: {region}"
            if description:
                details += f" · {description}"
            entries.append(_status_entry(name, status, details))
        return entries, None
    except httpx.HTTPError as exc:
        return [], f"Errore HTTP Scalingo API: {exc}"


async def _scalingo_status() -> tuple[List[dict], str | None]:
    entries, error = await _fetch_scalingo_via_api()
    if entries:
        return entries, error
    if error:
        # API fallback to CLI only if CLI available
        cli_res = await _run_command(["scalingo", "apps"])
        if cli_res.exit_code == 0 and cli_res.stdout.strip():
            return _parse_scalingo_apps(cli_res.stdout), None
        cli_error = cli_res.stderr or cli_res.stdout or "CLI Scalingo non disponibile"
        hint = "Configura SCALINGO_API_TOKEN (o la config locale) o installa la CLI nel container"
        return [_status_entry("scalingo", "error", cli_error, meta="Errore", hint=hint)], error
    return entries, None


async def _fetch_scalingo_postgres_addons_cli(region: str) -> tuple[List[dict], str | None]:
    apps_res = await _run_command(["scalingo", "--region", region, "apps"])
    if apps_res.exit_code != 0 or not apps_res.stdout.strip():
        error = apps_res.stderr or apps_res.stdout or "CLI Scalingo non disponibile"
        return [], error

    app_names = _extract_scalingo_app_names(apps_res.stdout)
    if not app_names:
        return [], "Nessuna app trovata via CLI"

    semaphore = asyncio.Semaphore(4)

    async def fetch_for_app(app_name: str) -> List[dict]:
        async with semaphore:
            addons_res = await _run_command(["scalingo", "--region", region, "-a", app_name, "addons"])
        if addons_res.exit_code != 0:
            details = addons_res.stderr or addons_res.stdout or "Errore CLI addons"
            return [_status_entry(app_name, "error", details)]
        return _parse_scalingo_addons_cli(app_name, addons_res.stdout)

    tasks = [asyncio.create_task(fetch_for_app(name)) for name in app_names]
    results = await asyncio.gather(*tasks)
    entries: List[dict] = [entry for bucket in results for entry in bucket]

    if not entries:
        return [], "Nessun addon Postgres trovato via CLI"
    return entries, None


async def _fetch_scalingo_postgres_addons() -> tuple[List[dict], str | None]:
    token, base_url = _load_scalingo_credentials()
    region = os.environ.get("SCALINGO_REGION", "osc-fr1")

    api_error_msg: str | None = None

    if token:
        headers = {"Authorization": f"Bearer {token}", "Accept": "application/json"}
        entries: List[dict] = []
        async with httpx.AsyncClient(timeout=10.0) as client:
            try:
                apps_resp = await client.get(f"{base_url}/v1/apps", headers=headers)
                apps_resp.raise_for_status()
                apps = apps_resp.json().get("apps", [])
            except httpx.HTTPError as exc:
                api_error_msg = f"Errore HTTP Scalingo API (apps): {exc}"
            else:
                for app in apps:
                    app_name = app.get("name")
                    if not app_name:
                        continue
                    try:
                        addons_resp = await client.get(f"{base_url}/v1/apps/{app_name}/addons", headers=headers)
                        addons_resp.raise_for_status()
                        addons = addons_resp.json().get("addons", [])
                    except httpx.HTTPError as exc:
                        entries.append(_status_entry(app_name, "error", f"Errore addons: {exc}"))
                        continue

                    for addon in addons:
                        provider = addon.get("addon_provider", {}).get("name", "")
                        if "postgres" not in provider.lower():
                            continue
                        status_txt = addon.get("state") or addon.get("status") or "sconosciuto"
                        status_lower = str(status_txt).lower()
                        if status_lower in ("running", "available", "provisioned"):
                            status = "ok"
                        elif any(token in status_lower for token in ["provision", "start", "build", "pending"]):
                            status = "warn"
                        else:
                            status = "error"
                        plan = addon.get("plan", {}).get("name")
                        addon_region = addon.get("region") or app.get("region") or addon.get("provider_region")
                        addon_name = addon.get("name") or addon.get("id") or provider
                        details = f"App: {app_name} · Plan: {plan or '?'} · Status: {status_txt}"
                        if addon_region:
                            details += f" · Region: {addon_region}"
                        entries.append(
                            _status_entry(
                                addon_name,
                                status,
                                details,
                                meta=status_txt,
                            )
                        )

        if entries:
            return entries, None
        if not api_error_msg:
            api_error_msg = "Nessun addon Postgres trovato via API"
    else:
        api_error_msg = "Configura SCALINGO_API_TOKEN o la config locale"

    cli_entries, cli_error = await _fetch_scalingo_postgres_addons_cli(region)
    if cli_entries:
        return cli_entries, api_error_msg
    return cli_entries, cli_error or api_error_msg


@app.get("/", response_class=HTMLResponse)
async def root(request: Request) -> HTMLResponse:
    return TEMPLATES.TemplateResponse(
        "index.html",
        {"request": request, "scripts_root": str(SCRIPTS_ROOT)},
    )


@app.get("/api/knowledge", response_model=List[KnowledgeEntry])
async def get_knowledge() -> List[KnowledgeEntry]:
    entries = _load_knowledge()
    return [KnowledgeEntry(**entry) for entry in entries]


@app.post("/api/knowledge", response_model=KnowledgeEntry)
async def add_knowledge(entry: KnowledgeCreate) -> KnowledgeEntry:
    entries = _load_knowledge()
    new_entry = KnowledgeEntry(
        id=str(uuid.uuid4()),
        title=entry.title,
        description=entry.description,
        tags=entry.tags or [],
        created_at=datetime.utcnow().isoformat() + "Z",
    )
    entries.append(new_entry.model_dump())
    _save_knowledge(entries)
    return new_entry


@app.get("/api/prompt-files")
async def list_prompt_files() -> dict:
    master_path = (WORKSPACE_ROOT / "ewh-master" / "MASTER_PROMPT.md").resolve()
    try:
        master_path.relative_to(WORKSPACE_ROOT)
    except ValueError:
        master_path = WORKSPACE_ROOT / "ewh-master" / "MASTER_PROMPT.md"

    master_info = {
        "path": str(master_path),
        "exists": master_path.exists(),
    }

    repos_info = []
    for repo in _iter_local_repositories():
        prompt_path = (repo / "prompt.md").resolve()
        readme_path = (repo / "README.md").resolve()
        repos_info.append(
            {
                "name": repo.name,
                "prompt": {"path": str(prompt_path), "exists": prompt_path.exists()},
                "readme": {"path": str(readme_path), "exists": readme_path.exists()},
            }
        )

    return {"master": master_info, "repos": repos_info}


@app.get("/api/prompt-files/content")
async def get_prompt_file_content(path: str) -> dict:
    file_path = _resolve_workspace_file(path)
    if not file_path.exists():
        return {"path": str(file_path), "content": "", "exists": False}
    try:
        content = file_path.read_text(encoding="utf-8")
    except OSError as exc:  # pragma: no cover - filesystem errors
        raise HTTPException(status_code=500, detail=f"Errore lettura file: {exc}") from exc
    return {"path": str(file_path), "content": content, "exists": True}


@app.post("/api/prompt-files/content")
async def save_prompt_file_content(payload: PromptContentRequest) -> dict:
    file_path = _resolve_workspace_file(payload.path)
    try:
        file_path.parent.mkdir(parents=True, exist_ok=True)
        file_path.write_text(payload.content or "", encoding="utf-8")
    except OSError as exc:  # pragma: no cover - filesystem errors
        raise HTTPException(status_code=500, detail=f"Errore salvataggio file: {exc}") from exc
    return {"path": str(file_path), "saved": True}


def _docker_command_for_action(action: str, name: str) -> List[str]:
    if action == "start":
        return ["docker", "start", name]
    if action == "stop":
        return ["docker", "stop", name]
    if action == "restart":
        return ["docker", "restart", name]
    raise ValueError(f"Azione docker non supportata: {action}")


@app.post("/api/docker/containers/actions")
async def docker_containers_actions(payload: DockerActionRequest) -> dict:
    unique_names = sorted({name for name in payload.names if name})
    if not unique_names:
        raise HTTPException(status_code=400, detail="Nessun container selezionato")

    results: List[dict] = []
    for name in unique_names:
        try:
            command = _docker_command_for_action(payload.action, name)
        except ValueError as exc:  # pragma: no cover - guard for literals
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        run_result = await _run_command(command)
        results.append(
            {
                "name": name,
                "action": payload.action,
                "exit_code": run_result.exit_code,
                "stdout": run_result.stdout,
                "stderr": run_result.stderr,
            }
        )
    return {"action": payload.action, "results": results}


@app.post("/api/scalingo/apps/actions")
async def scalingo_apps_actions(payload: ScalingoActionRequest) -> dict:
    unique_names = sorted({name for name in payload.names if name})
    if not unique_names:
        raise HTTPException(status_code=400, detail="Nessuna app selezionata")

    region = os.environ.get("SCALINGO_REGION", "osc-fr1")
    results: List[dict] = []
    for name in unique_names:
        command = ["scalingo", "--region", region, "-a", name, "restart"]
        run_result = await _run_command(command)
        results.append(
            {
                "name": name,
                "action": payload.action,
                "exit_code": run_result.exit_code,
                "stdout": run_result.stdout,
                "stderr": run_result.stderr,
            }
        )
    return {"action": payload.action, "results": results}


def _validate_repo_path(repo_path: Path) -> Path:
    try:
        resolved = repo_path.resolve()
    except FileNotFoundError as exc:
        raise HTTPException(status_code=400, detail=f"Repository non trovato: {repo_path}") from exc
    try:
        resolved.relative_to(WORKSPACE_ROOT)
    except ValueError as exc:  # pragma: no cover - safety guard
        raise HTTPException(status_code=400, detail="Repository fuori dal workspace") from exc
    if not resolved.exists() or not resolved.is_dir():
        raise HTTPException(status_code=400, detail=f"Percorso non valido: {resolved}")
    return resolved


def _git_command_for_action(action: str) -> List[str]:
    if action == "status":
        return ["git", "status", "-sb"]
    if action == "fetch":
        return ["git", "fetch"]
    if action == "pull":
        return ["git", "pull", "--ff-only"]
    raise ValueError(f"Azione git non supportata: {action}")


@app.post("/api/git/repos/actions")
async def git_repos_actions(payload: GitActionRequest) -> dict:
    repo_paths = sorted({repo for repo in payload.repos if repo})
    if not repo_paths:
        raise HTTPException(status_code=400, detail="Nessun repository selezionato")

    results: List[dict] = []
    for repo in repo_paths:
        resolved = _validate_repo_path(Path(repo))
        try:
            command = _git_command_for_action(payload.action)
        except ValueError as exc:  # pragma: no cover - guard for literals
            raise HTTPException(status_code=400, detail=str(exc)) from exc
        run_result = await _run_command(command, cwd=resolved)
        results.append(
            {
                "repo": str(resolved),
                "action": payload.action,
                "exit_code": run_result.exit_code,
                "stdout": run_result.stdout,
                "stderr": run_result.stderr,
            }
        )
    return {"action": payload.action, "results": results}


async def _gather_status_data() -> dict:
    categories: List[dict] = []
    git_dirty: List[dict] = []
    bucket_usage: List[dict] = []
    database_usage: List[dict] = []

    # Repository status
    repo_entries: List[dict] = []
    repo_actions: set[str] = {"status", "fetch", "pull"}
    repo_paths = sorted(path.parent for path in WORKSPACE_ROOT.glob("*/.git"))
    if not repo_paths:
        repo_entries.append(_status_entry("Workspace", "info", "Nessun repository trovato", meta="Nessun repository trovato"))
    else:
        for repo_path in repo_paths:
            res = await _run_command(["git", "status", "--porcelain"], cwd=repo_path)
            if res.exit_code != 0:
                details = res.stderr or res.stdout or "Errore git"
                entry_status = "error"
                repo_entries.append(
                    _status_entry(
                        repo_path.name,
                        entry_status,
                        details,
                        meta="Errore",
                        target={"type": "git_repo", "id": str(repo_path)},
                        actions=list(repo_actions),
                    )
                )
                git_dirty.append(
                    {
                        "name": repo_path.name,
                        "path": str(repo_path),
                        "status": entry_status,
                        "details": details,
                    }
                )
            elif res.stdout.strip():
                summary = res.stdout.strip()
                entry_status = "warn"
                repo_entries.append(
                    _status_entry(
                        repo_path.name,
                        entry_status,
                        summary,
                        meta="Modifiche locali",
                        target={"type": "git_repo", "id": str(repo_path)},
                        actions=list(repo_actions),
                    )
                )
                git_dirty.append(
                    {
                        "name": repo_path.name,
                        "path": str(repo_path),
                        "status": entry_status,
                        "details": summary,
                    }
                )
            else:
                repo_entries.append(
                    _status_entry(
                        repo_path.name,
                        "ok",
                        "Pulito",
                        meta="Pulito",
                        target={"type": "git_repo", "id": str(repo_path)},
                        actions=list(repo_actions),
                    )
                )
    categories.append(
        {
            "id": "local_repos",
            "title": "Repository locali",
            "status": _overall_status(repo_entries, default="info"),
            "entries": repo_entries,
            "actions": sorted(repo_actions),
            "environment": "local",
            "category_type": "git",
        }
    )

    # Local docker containers
    docker_entries: List[dict] = []
    docker_hint = None
    docker_actions: set[str] = set()
    docker_cmd = await _run_command(["docker", "ps", "-a", "--format", "{{.Names}}::{{.Status}}"])
    if docker_cmd.exit_code == 0:
        lines = [line.strip() for line in docker_cmd.stdout.splitlines() if line.strip()]
        if not lines:
            docker_entries.append(_status_entry("Docker", "info", "Nessun container trovato"))
        else:
            for line in lines:
                name, _, state = line.partition("::")
                container_name = name.strip()
                if not container_name:
                    continue
                status_text = state.strip()
                status_lower = status_text.lower()
                if status_lower.startswith("up") and "restart" not in status_lower:
                    entry_status = "ok"
                    available_actions = ["stop", "restart"]
                elif any(token in status_lower for token in ["exited", "dead", "created"]):
                    entry_status = "error"
                    available_actions = ["start"]
                elif "paused" in status_lower:
                    entry_status = "warn"
                    available_actions = ["start", "restart", "stop"]
                else:
                    entry_status = "warn"
                    available_actions = ["start", "restart", "stop"]
                docker_actions.update(available_actions)
                docker_entries.append(
                    _status_entry(
                        container_name,
                        entry_status,
                        status_text,
                        meta=status_text,
                        target={"type": "docker_container", "id": container_name},
                        actions=available_actions,
                    )
                )
    else:
        error = docker_cmd.stderr or docker_cmd.stdout or "Comando docker non disponibile"
        docker_hint = "Installa docker CLI nel container o monta il socket del demone host"
        docker_entries.append(_status_entry("docker", "error", error, meta="Errore", hint=docker_hint))

    docker_card: dict = {
        "id": "local_docker",
        "title": "Container locali",
        "status": _overall_status(docker_entries, default="info"),
        "entries": docker_entries,
        "hint": docker_hint,
        "environment": "local",
        "category_type": "services",
    }
    if docker_actions:
        docker_card["actions"] = sorted(docker_actions)
    categories.append(docker_card)

    # Manual database checks
    manual_db_entries_by_env: dict[str, List[dict]] = {"local": [], "staging": [], "production": []}
    db_urls = [url for url in _read_config_list("STATUS_DB_URLS", "STATUS_DB_URLS_FILE") if not _is_placeholder_db_url(url)]
    for url in db_urls:
        env = _guess_environment_from_db_url(url)
        res = await _run_command(["psql", url, "-At", "-c", "SELECT 1;"], cwd=None)
        if res.exit_code == 0:
            entry = _status_entry(url, "ok", "Connessione OK", meta="Connessione OK")
            manual_db_entries_by_env.setdefault(env, []).append(entry)
            usage = await _measure_database_usage(url)
            database_usage.append(usage)
        else:
            error_msg = res.stderr or res.stdout or "Errore connessione"
            entry = _status_entry(url, "error", error_msg, meta="Errore")
            manual_db_entries_by_env.setdefault(env, []).append(entry)
            database_usage.append(
                {
                    "url": url,
                    "status": "error",
                    "environment": env,
                    "error": error_msg.strip(),
                    "type": "manual",
                }
            )

    local_db_entries = manual_db_entries_by_env.get("local") or []
    if local_db_entries:
        categories.append(
            {
                "id": "databases_local",
                "title": "Database locali",
                "status": _overall_status(local_db_entries, default="info"),
                "entries": local_db_entries,
                "environment": "local",
                "category_type": "databases",
            }
        )

    # Scalingo staging apps
    staging_entries, scalingo_hint = await _scalingo_status()
    if not staging_entries:
        staging_entries.append(_status_entry("Scalingo", "info", "Nessuna app trovata", meta="Nessuna app"))
    scalingo_actions = sorted({action for entry in staging_entries for action in entry.get("actions", [])})
    staging_card: dict = {
        "id": "staging",
        "title": "Scalingo staging",
        "status": _overall_status(staging_entries, default="info"),
        "entries": staging_entries,
        "hint": scalingo_hint,
        "environment": "staging",
        "category_type": "services",
    }
    if scalingo_actions:
        staging_card["actions"] = scalingo_actions
    categories.append(staging_card)

    # Database staging
    scalingo_db_entries, scalingo_db_hint = await _fetch_scalingo_postgres_addons()
    staging_db_entries = list(scalingo_db_entries)
    for entry in scalingo_db_entries:
        database_usage.append(
            {
                "type": "scalingo",
                "environment": "staging",
                "label": entry.get("label"),
                "status": entry.get("status"),
                "details": entry.get("details"),
            }
        )
    manual_staging_entries = manual_db_entries_by_env.get("staging") or []
    staging_db_entries.extend(manual_staging_entries)
    if not staging_db_entries:
        if scalingo_db_hint:
            staging_db_entries.append(_status_entry("Scalingo", "error", scalingo_db_hint, meta="Errore"))
        else:
            staging_db_entries.append(_status_entry("Database", "info", "Nessun database configurato", meta="Nessun database"))
    elif scalingo_db_hint:
        staging_db_entries.append(_status_entry("Scalingo", "warn", scalingo_db_hint, meta="Avviso"))
    categories.append(
        {
            "id": "databases_staging",
            "title": "Database staging",
            "status": _overall_status(staging_db_entries, default="info"),
            "entries": staging_db_entries,
            "environment": "staging",
            "category_type": "databases",
        }
    )

    # Production placeholder
    prod_entries = [_status_entry("Produzione", "info", "Ancora non configurato")]
    categories.append(
        {
            "id": "production",
            "title": "Produzione",
            "status": "info",
            "entries": prod_entries,
            "environment": "production",
            "category_type": "services",
        }
    )

    production_db_entries = manual_db_entries_by_env.get("production") or []
    if not production_db_entries:
        production_db_entries.append(
            _status_entry("Database produzione", "info", "Ancora non configurato", meta="Configurazione mancante")
        )
    categories.append(
        {
            "id": "databases_production",
            "title": "Database produzione",
            "status": _overall_status(production_db_entries, default="info"),
            "entries": production_db_entries,
            "environment": "production",
            "category_type": "databases",
        }
    )

    # Buckets
    bucket_entries: List[dict] = []
    bucket_names = _read_config_list("STATUS_BUCKETS", "STATUS_BUCKETS_FILE")
    bucket_endpoint = _ensure_endpoint_url(
        os.environ.get("STATUS_BUCKETS_ENDPOINT")
        or os.environ.get("AWS_S3_ENDPOINT")
        or os.environ.get("WASABI_ENDPOINT")
    )
    if not bucket_names:
        bucket_entries.append(_status_entry("Bucket", "info", "Configura STATUS_BUCKETS o STATUS_BUCKETS_FILE", meta="Configurazione mancante"))
    else:
        for bucket in bucket_names:
            cmd = ["aws", "s3", "ls", f"s3://{bucket}"]
            if bucket_endpoint:
                cmd.extend(["--endpoint-url", bucket_endpoint.rstrip("/")])
            res = await _run_command(cmd)
            if res.exit_code == 0:
                bucket_entries.append(_status_entry(bucket, "ok", "Accessibile", meta="Accessibile"))
                usage = await _measure_bucket_usage(bucket, bucket_endpoint)
            else:
                error_msg = res.stderr or res.stdout or "Errore S3"
                bucket_entries.append(_status_entry(bucket, "error", error_msg, meta="Errore"))
                usage = {
                    "name": bucket,
                    "status": "error",
                    "error": (error_msg or "Errore S3").strip(),
                    "type": "bucket",
                    "environment": "global",
                }
            bucket_usage.append(usage)
    categories.append(
        {
            "id": "buckets",
            "title": "Bucket S3",
            "status": _overall_status(bucket_entries, default="info"),
            "entries": bucket_entries,
            "environment": "global",
            "category_type": "storage",
        }
    )

    environment_summary, critical_entries = _compute_environment_metrics(categories)
    for env in ("local", "staging", "production"):
        environment_summary.setdefault(
            env,
            {"total": 0, "ok": 0, "warn": 0, "error": 0, "active": 0, "degraded": 0, "down": 0},
        )

    database_summary = {
        "local": _status_counters(local_db_entries),
        "staging": _status_counters(staging_db_entries),
        "production": _status_counters(production_db_entries),
    }
    bucket_summary = _status_counters(bucket_entries)

    usage_history = _load_usage_history()

    return {
        "categories": categories,
        "environment_summary": environment_summary,
        "critical": critical_entries,
        "git_dirty": git_dirty,
        "bucket_usage": bucket_usage,
        "database_usage": database_usage,
        "costs": _load_costs_breakdown(),
        "database_summary": database_summary,
        "bucket_summary": bucket_summary,
        "usage_history": usage_history,
        "generated_at": datetime.utcnow().isoformat() + "Z",
    }


@app.get("/api/status")
async def get_status() -> dict:
    data = await _gather_status_data()
    return {"categories": data["categories"]}


@app.get("/api/overview")
async def get_overview() -> dict:
    data = await _gather_status_data()
    return {
        "generated_at": data["generated_at"],
        "environment_summary": data["environment_summary"],
        "critical": data["critical"],
        "git_dirty": data["git_dirty"],
        "bucket_usage": data["bucket_usage"],
        "database_usage": data["database_usage"],
        "costs": data["costs"],
        "database_summary": data["database_summary"],
        "bucket_summary": data["bucket_summary"],
        "usage_history": data["usage_history"],
    }
