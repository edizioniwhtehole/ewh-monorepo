import json
from pathlib import Path
from typing import Optional

# Base configuration
ORG = "edizioniwhitehole"
REPO_BASE = f"https://github.com/{ORG}"
STAGING_DOMAIN = "ewhsaas.it"
PRODUCTION_DOMAIN = "polosaas.it"
STAGING_BUCKET = "ewh-staging"
PRODUCTION_BUCKET = "ewh-prod"
STAGING_PROJECT = "prj-de643f68-d927-4229-9cc2-5e2a83f29957"
PRODUCTION_PROJECT = "prj-389a593b-f5c4-4ae1-aeef-a12ea5180516"

PUBLIC_DOMAINS = {
    "app-web-frontend": {
        "staging": f"app.{STAGING_DOMAIN}",
        "production": f"app.{PRODUCTION_DOMAIN}"
    },
    "svc-api-gateway": {
        "staging": f"api.{STAGING_DOMAIN}",
        "production": f"api.{PRODUCTION_DOMAIN}"
    },
    "app-admin-console": {
        "staging": f"admin.{STAGING_DOMAIN}",
        "production": f"admin.{PRODUCTION_DOMAIN}"
    }
}

DEFAULT_SCALE = {
    "web": {"staging": "1:S", "production": "1:M"},
    "worker": {"staging": "0", "production": "1:S"}
}

SERVICE_PORTS = {
    "svc-api-gateway": 4000,
    "svc-auth": 4001,
    "svc-plugins": 4002,
    "svc-media": 4003,
    "svc-billing": 4004,
    "svc-image-orchestrator": 4100,
    "svc-job-worker": 4101,
    "svc-writer": 4102,
    "svc-content": 4103,
    "svc-layout": 4104,
    "svc-prepress": 4105,
    "svc-vector-lab": 4106,
    "svc-mockup": 4107,
    "svc-video-orchestrator": 4108,
    "svc-video-runtime": 4109,
    "svc-raster-runtime": 4110,
    "svc-projects": 4200,
    "svc-search": 4201,
    "svc-site-builder": 4202,
    "svc-site-renderer": 4203,
    "svc-site-publisher": 4204,
    "svc-connectors-web": 4205,
    "svc-products": 4300,
    "svc-orders": 4301,
    "svc-inventory": 4302,
    "svc-channels": 4303,
    "svc-quotation": 4304,
    "svc-procurement": 4305,
    "svc-mrp": 4306,
    "svc-shipping": 4307,
    "svc-crm": 4308,
    "svc-pm": 4400,
    "svc-support": 4401,
    "svc-chat": 4402,
    "svc-boards": 4403,
    "svc-kb": 4404,
    "svc-collab": 4405,
    "svc-dms": 4406,
    "svc-timesheet": 4407,
    "svc-forms": 4408,
    "svc-forum": 4409,
    "svc-assistant": 4410,
    "svc-comm": 4500,
    "svc-enrichment": 4501,
    "svc-bi": 4502,
    "svc-n8n": 5678
}


def domain_root(env: str) -> str:
    return STAGING_DOMAIN if env == "staging" else PRODUCTION_DOMAIN


def host_for(subdomain: str, env: str) -> str:
    return f"{subdomain}.{domain_root(env)}"


def default_value(key: str, env: str, service: str) -> Optional[str]:
    if key == "DATABASE_URL":
        return "$SCALINGO_POSTGRESQL_URL"
    if key == "REDIS_URL":
        return "$SCALINGO_REDIS_URL"
    if key == "ALLOWED_ORIGINS":
        origins = [
            f"https://{PUBLIC_DOMAINS['app-web-frontend'][env]}",
            f"https://{PUBLIC_DOMAINS['app-admin-console'][env]}"
        ]
        return ",".join(origins)
    if key == "AUTH_ISSUER":
        return f"https://{PUBLIC_DOMAINS['svc-api-gateway'][env]}/auth"
    if key == "JWT_AUDIENCE":
        return f"https://{PUBLIC_DOMAINS['svc-api-gateway'][env]}"
    if key == "JWT_PRIVATE_KEY":
        return "<jwt-private-key>"
    if key == "JWT_PUBLIC_KEY":
        return "<jwt-public-key>"
    if key == "RATE_LIMIT_PER_TENANT":
        return "600" if env == "staging" else "2000"
    if key == "REFRESH_TTL":
        return "2592000"  # 30d in seconds
    if key == "TOKEN_TTL":
        return "900"  # 15m in seconds
    if key == "MEDIA_MAX_SIZE_MB":
        return "512" if env == "staging" else "2048"
    if key == "SIGNED_URL_TTL":
        return "900"
    if key == "WORKER_CONCURRENCY":
        return "2" if env == "staging" else "4"
    if key == "LLM_PROVIDER":
        return "openai"
    if key == "SEARCH_URL":
        return f"https://{PUBLIC_DOMAINS['svc-api-gateway'][env]}/search"
    if key == "SEARCH_KEY":
        return "<meili-search-key>"
    if key == "LAYOUT_ENGINE":
        return "layout-engine-v1"
    if key == "PREPRESS_MODE":
        return "preflight"
    if key == "VECTOR_PROVIDER":
        return "vector-lab-internal"
    if key == "MOCKUP_PROVIDER":
        return "mockup-lab"
    if key == "VIDEO_PROVIDER":
        return "ffmpeg"
    if key == "FFMPEG_ARGS":
        return "-preset fast -crf 20"
    if key == "PROJECTS_FEATURE_FLAGS":
        return "[]"
    if key == "MEILI_HOST":
        return f"https://{host_for('meili', env)}"
    if key == "SITE_BUILDER_FLAGS":
        return "[]"
    if key == "PUBLISHER_WEBHOOK_URL":
        return f"https://hooks.{host_for('svc-site-publisher', env)}"
    if key == "SHOPIFY_API_KEY":
        return "<shopify-api-key>"
    if key == "SHOPIFY_API_SECRET":
        return "<shopify-api-secret>"
    if key == "PRODUCTS_DEFAULT_CURRENCY":
        return "EUR"
    if key == "PAYMENTS_PROVIDER":
        return "stripe"
    if key == "PAYMENTS_API_KEY":
        return "<stripe-payments-api-key>"
    if key == "CHANNEL_SYNC_INTERVAL":
        return "300"
    if key == "QUOTE_PDF_TEMPLATE":
        return "default"
    if key == "MRP_PLANNING_HORIZON_DAYS":
        return "30"
    if key == "CARRIERS_API_KEY":
        return "<carriers-api-key>"
    if key == "CRM_ENRICHMENT_PROVIDER":
        return "enrichment-service"
    if key == "SUPPORT_INBOUND_EMAIL":
        local = "support" if env == "production" else "support-staging"
        domain = domain_root(env)
        return f"{local}@{domain}"
    if key == "SIGN_PROVIDER_API_KEY":
        return "<esign-api-key>"
    if key == "CHAT_WS_ORIGIN":
        return f"https://{host_for('chat', env)}"
    if key == "FORMS_SPAM_THRESHOLD":
        return "0.7"
    if key == "ASSISTANT_PROVIDER":
        return "assistant-service"
    if key == "ASSISTANT_API_KEY":
        return "<assistant-api-key>"
    if key == "SMTP_HOST":
        return "smtp.mailgun.org"
    if key == "SMTP_USER":
        return "<smtp-user>"
    if key == "SMTP_PASSWORD":
        return "<smtp-password>"
    if key == "ENRICHMENT_SOURCES":
        return "[]"
    if key == "STRIPE_API_KEY":
        return "<stripe-secret-key>"
    if key == "STRIPE_WEBHOOK_SECRET":
        return "<stripe-webhook-secret>"
    if key == "BI_DSN":
        return "postgresql://<bi-user>:<password>@host:5432/bi"
    if key == "PLUGINS_REGISTRY_URL":
        return f"https://{host_for('plugins', env)}"
    if key == "N8N_BASIC_AUTH_USER":
        return "admin"
    if key == "N8N_BASIC_AUTH_PASSWORD":
        return "<strong-password>"
    if key == "S3_ENDPOINT":
        return "https://s3.wasabisys.com"
    if key == "S3_ACCESS_KEY":
        return "<s3-access-key>"
    if key == "S3_SECRET_KEY":
        return "<s3-secret-key>"
    if key == "LLM_API_KEY":
        return "<llm-api-key>"
    if key == "MEILI_MASTER_KEY":
        return "<meili-master-key>"
    return None

services = [
    {
        "name": "app-web-frontend",
        "repo": "app-web-frontend",
        "processes": {
            "web": {
                "type": "web",
                "addons": [],
                "env": {
                    "required": [
                        "NEXT_PUBLIC_API_BASE_URL",
                        "NEXT_PUBLIC_CDN_BASE_URL",
                        "NEXT_PUBLIC_APP_ENV"
                    ],
                    "staging": {
                        "NEXT_PUBLIC_API_BASE_URL": "https://api.staging.ewhsaas.it",
                        "NEXT_PUBLIC_CDN_BASE_URL": "https://cdn.staging.ewhsaas.it",
                        "NEXT_PUBLIC_APP_ENV": "staging"
                    },
                    "production": {
                        "NEXT_PUBLIC_API_BASE_URL": "https://api.polosaas.it",
                        "NEXT_PUBLIC_CDN_BASE_URL": "https://cdn.polosaas.it",
                        "NEXT_PUBLIC_APP_ENV": "production"
                    }
                },
                "scale": {"staging": "1:S", "production": "2:M"}
            }
        },
        "subdomains": {
            "staging": "app.staging.ewhsaas.it",
            "production": "app.polosaas.it"
        },
        "enabled": True
    },
    {
        "name": "app-admin-console",
        "repo": "app-admin-console",
        "processes": {
            "web": {
                "type": "web",
                "addons": [],
                "env": {
                    "required": [
                        "NEXT_PUBLIC_API_BASE_URL",
                        "NEXT_PUBLIC_CDN_BASE_URL",
                        "NEXT_PUBLIC_APP_ENV"
                    ],
                    "staging": {
                        "NEXT_PUBLIC_API_BASE_URL": "https://api.staging.ewhsaas.it",
                        "NEXT_PUBLIC_CDN_BASE_URL": "https://cdn.staging.ewhsaas.it",
                        "NEXT_PUBLIC_APP_ENV": "staging"
                    },
                    "production": {
                        "NEXT_PUBLIC_API_BASE_URL": "https://api.polosaas.it",
                        "NEXT_PUBLIC_CDN_BASE_URL": "https://cdn.polosaas.it",
                        "NEXT_PUBLIC_APP_ENV": "production"
                    }
                },
                "scale": {"staging": "1:S", "production": "1:M"}
            }
        },
        "subdomains": {
            "staging": "admin.staging.ewhsaas.it",
            "production": "admin.polosaas.it"
        },
        "enabled": True
    },
]

# Helper utilities

def service_entry(name, category, *, repo=None, db_schema=None, redis_queues=None,
                  redis_rate_limit=False, search_indexes=None, s3_paths=None,
                  process_type="web", enabled=True, scale=None, expose=True,
                  extra_env=None):
    repo_name = repo or name
    data = {
        "name": name,
        "category": category,
        "repo": repo_name,
        "processes": {},
        "enabled": enabled,
    }

    addons = []
    env_required = ["APP_ENV", "LOG_LEVEL"]
    env_staging = {"APP_ENV": "staging"}
    env_production = {"APP_ENV": "production"}

    if db_schema:
        addons.append("postgres")
        env_required.extend(["DATABASE_URL", "DB_SCHEMA"])
        env_staging["DB_SCHEMA"] = db_schema
        env_production["DB_SCHEMA"] = db_schema

    if redis_queues or redis_rate_limit:
        addons.append("redis")
        env_required.append("REDIS_URL")

    if s3_paths:
        env_required.extend(["S3_ENDPOINT", "S3_ACCESS_KEY", "S3_SECRET_KEY", "S3_BUCKET"])
        env_staging.setdefault("S3_BUCKET", STAGING_BUCKET)
        env_production.setdefault("S3_BUCKET", PRODUCTION_BUCKET)
    if extra_env:
        env_required.extend(extra_env.get("required", []))
        env_staging.update(extra_env.get("staging", {}))
        env_production.update(extra_env.get("production", {}))

    for key in list(env_required):
        if key not in env_staging:
            default = default_value(key, "staging", name)
            if default is not None:
                env_staging[key] = default
        if key not in env_production:
            default = default_value(key, "production", name)
            if default is not None:
                env_production[key] = default

    if process_type == "web":
        port = SERVICE_PORTS.get(name)
        if port is not None:
            env_required.append("PORT")
            env_staging.setdefault("PORT", str(port))
            env_production.setdefault("PORT", str(port))

    env_required = sorted(set(env_required))
    env_staging.setdefault("LOG_LEVEL", "info")
    env_production.setdefault("LOG_LEVEL", "info")

    proc = {
        "type": process_type,
        "addons": sorted(set(addons)),
        "env": {
            "required": env_required,
            "staging": env_staging,
            "production": env_production
        },
        "metadata": {
            "db_schema": db_schema,
            "redis": {
                "queues": redis_queues or [],
                "rate_limit": redis_rate_limit
            },
            "search_indexes": search_indexes or [],
            "s3_paths": s3_paths or []
        },
        "scale": scale or DEFAULT_SCALE.get(process_type, DEFAULT_SCALE["web"])
    }

    data["processes"]["web" if process_type == "web" else process_type] = proc

    data["subdomains"] = {
        "staging": None,
        "production": None
    }

    return data

# Add remaining services using helper
services.extend([
    service_entry(
        "app-layout-editor",
        "client",
        extra_env={
            "required": [
                "NEXT_PUBLIC_API_BASE_URL",
                "NEXT_PUBLIC_CDN_BASE_URL",
                "NEXT_PUBLIC_APP_ENV"
            ],
            "staging": {
                "NEXT_PUBLIC_API_BASE_URL": "https://api.staging.ewhsaas.it",
                "NEXT_PUBLIC_CDN_BASE_URL": "https://cdn.staging.ewhsaas.it",
                "NEXT_PUBLIC_APP_ENV": "staging"
            },
            "production": {
                "NEXT_PUBLIC_API_BASE_URL": "https://api.polosaas.it",
                "NEXT_PUBLIC_CDN_BASE_URL": "https://cdn.polosaas.it",
                "NEXT_PUBLIC_APP_ENV": "production"
            }
        }
    ),
    service_entry(
        "app-raster-editor",
        "client",
        extra_env={
            "required": [
                "NEXT_PUBLIC_API_BASE_URL",
                "NEXT_PUBLIC_APP_ENV"
            ],
            "staging": {
                "NEXT_PUBLIC_API_BASE_URL": "https://api.staging.ewhsaas.it",
                "NEXT_PUBLIC_APP_ENV": "staging"
            },
            "production": {
                "NEXT_PUBLIC_API_BASE_URL": "https://api.polosaas.it",
                "NEXT_PUBLIC_APP_ENV": "production"
            }
        }
    ),
    service_entry(
        "app-video-editor",
        "client",
        extra_env={
            "required": [
                "NEXT_PUBLIC_API_BASE_URL",
                "NEXT_PUBLIC_APP_ENV"
            ],
            "staging": {
                "NEXT_PUBLIC_API_BASE_URL": "https://api.staging.ewhsaas.it",
                "NEXT_PUBLIC_APP_ENV": "staging"
            },
            "production": {
                "NEXT_PUBLIC_API_BASE_URL": "https://api.polosaas.it",
                "NEXT_PUBLIC_APP_ENV": "production"
            }
        }
    ),
    service_entry(
        "svc-api-gateway",
        "edge",
        db_schema=None,
        redis_rate_limit=True,
        redis_queues=["rate"],
        s3_paths=[],
        extra_env={
            "required": [
                "AUTH_ISSUER",
                "JWT_AUDIENCE",
                "RATE_LIMIT_PER_TENANT",
                "ALLOWED_ORIGINS"
            ]
        }
    ),
    service_entry(
        "svc-auth",
        "edge",
        db_schema="auth",
        redis_rate_limit=False,
        s3_paths=[],
        extra_env={
            "required": [
                "JWT_PRIVATE_KEY",
                "JWT_PUBLIC_KEY",
                "TOKEN_TTL",
                "REFRESH_TTL"
            ]
        }
    ),
    service_entry(
        "svc-media",
        "creative",
        db_schema="media",
        redis_queues=["q:thumbs"],
        s3_paths=["/assets", "/public"],
        search_indexes=["assets"],
        extra_env={
            "required": [
                "SIGNED_URL_TTL",
                "MEDIA_MAX_SIZE_MB"
            ]
        }
    ),
    service_entry(
        "svc-image-orchestrator",
        "creative",
        db_schema="image_orchestrator",
        redis_queues=["q:img"],
        s3_paths=["/assets"],
        search_indexes=[],
        extra_env={
            "required": [
                "WORKER_CONCURRENCY"
            ]
        }
    ),
    service_entry(
        "svc-job-worker",
        "creative",
        process_type="worker",
        db_schema=None,
        redis_queues=["q:img", "q:layout", "q:prepress"],
        s3_paths=["/public", "/exports"],
        expose=False,
        extra_env={
            "required": [
                "WORKER_CONCURRENCY"
            ]
        }
    ),
    service_entry(
        "svc-writer",
        "creative",
        db_schema="writer",
        redis_queues=[],
        s3_paths=["/documents"],
        search_indexes=["documents"],
        extra_env={
            "required": [
                "LLM_PROVIDER",
                "LLM_API_KEY"
            ]
        }
    ),
    service_entry(
        "svc-content",
        "creative",
        db_schema="content",
        redis_queues=[],
        search_indexes=["pages"],
        extra_env={
            "required": [
                "SEARCH_URL",
                "SEARCH_KEY"
            ]
        }
    ),
    service_entry(
        "svc-raster-runtime",
        "creative",
        process_type="worker",
        db_schema=None,
        redis_queues=["q:raster"],
        s3_paths=["/public", "/exports"],
        expose=False,
        extra_env={
            "required": [
                "WORKER_CONCURRENCY"
            ]
        }
    ),
    service_entry(
        "svc-layout",
        "creative",
        db_schema="layout",
        redis_queues=["q:layout"],
        s3_paths=["/exports/layout"],
        search_indexes=[],
        extra_env={
            "required": [
                "LAYOUT_ENGINE"
            ]
        }
    ),
    service_entry(
        "svc-prepress",
        "creative",
        db_schema="prepress",
        redis_queues=["q:prepress"],
        s3_paths=["/print"],
        extra_env={
            "required": [
                "PREPRESS_MODE"
            ]
        }
    ),
    service_entry(
        "svc-vector-lab",
        "creative",
        db_schema="vector_lab",
        redis_queues=["q:vector"],
        s3_paths=["/exports/vector"],
        extra_env={
            "required": [
                "VECTOR_PROVIDER"
            ]
        }
    ),
    service_entry(
        "svc-mockup",
        "creative",
        db_schema="mockup",
        redis_queues=["q:mockup"],
        s3_paths=["/mockups"],
        extra_env={
            "required": [
                "MOCKUP_PROVIDER"
            ]
        }
    ),
    service_entry(
        "svc-video-orchestrator",
        "creative",
        db_schema="video_orchestrator",
        redis_queues=["q:video"],
        s3_paths=["/video"],
        extra_env={
            "required": [
                "VIDEO_PROVIDER"
            ]
        }
    ),
    service_entry(
        "svc-video-runtime",
        "creative",
        process_type="worker",
        db_schema=None,
        redis_queues=["q:video"],
        s3_paths=["/video"],
        expose=False,
        extra_env={
            "required": [
                "FFMPEG_ARGS"
            ]
        }
    ),
    service_entry(
        "svc-projects",
        "publishing",
        db_schema="projects",
        search_indexes=["projects"],
        extra_env={
            "required": [
                "PROJECTS_FEATURE_FLAGS"
            ]
        }
    ),
    service_entry(
        "svc-search",
        "publishing",
        db_schema=None,
        redis_queues=[],
        search_indexes=["assets", "projects", "products", "forum", "kb"],
        extra_env={
            "required": [
                "MEILI_MASTER_KEY",
                "MEILI_HOST"
            ]
        }
    ),
    service_entry(
        "svc-site-builder",
        "publishing",
        db_schema="site_builder",
        search_indexes=["pages"],
        extra_env={
            "required": [
                "SITE_BUILDER_FLAGS"
            ]
        }
    ),
    service_entry(
        "svc-site-renderer",
        "publishing",
        process_type="worker",
        db_schema=None,
        redis_queues=["q:site-render"],
        s3_paths=["/static-builds"],
        expose=False
    ),
    service_entry(
        "svc-site-publisher",
        "publishing",
        db_schema="site_publisher",
        redis_queues=["q:publish"],
        extra_env={
            "required": [
                "PUBLISHER_WEBHOOK_URL"
            ]
        }
    ),
    service_entry(
        "svc-connectors-web",
        "publishing",
        db_schema="connectors_web",
        extra_env={
            "required": [
                "SHOPIFY_API_KEY",
                "SHOPIFY_API_SECRET"
            ]
        }
    ),
    service_entry(
        "svc-products",
        "erp",
        db_schema="products",
        redis_queues=[],
        search_indexes=["products"],
        extra_env={
            "required": [
                "PRODUCTS_DEFAULT_CURRENCY"
            ]
        }
    ),
    service_entry(
        "svc-orders",
        "erp",
        db_schema="orders",
        redis_queues=["q:orders"],
        search_indexes=["orders"],
        s3_paths=["/orders"],
        extra_env={
            "required": [
                "PAYMENTS_PROVIDER",
                "PAYMENTS_API_KEY"
            ]
        }
    ),
    service_entry(
        "svc-inventory",
        "erp",
        db_schema="inventory"
    ),
    service_entry(
        "svc-channels",
        "erp",
        db_schema="channels",
        redis_queues=["q:channel-sync"],
        extra_env={
            "required": [
                "CHANNEL_SYNC_INTERVAL"
            ]
        }
    ),
    service_entry(
        "svc-quotation",
        "erp",
        db_schema="quotation",
        s3_paths=["/quotes"],
        extra_env={
            "required": [
                "QUOTE_PDF_TEMPLATE"
            ]
        }
    ),
    service_entry(
        "svc-procurement",
        "erp",
        db_schema="procurement"
    ),
    service_entry(
        "svc-mrp",
        "erp",
        db_schema="mrp",
        redis_queues=["q:mrp"],
        extra_env={
            "required": [
                "MRP_PLANNING_HORIZON_DAYS"
            ]
        }
    ),
    service_entry(
        "svc-shipping",
        "erp",
        db_schema="shipping",
        redis_queues=["q:shipping"],
        s3_paths=["/labels"],
        extra_env={
            "required": [
                "CARRIERS_API_KEY"
            ]
        }
    ),
    service_entry(
        "svc-crm",
        "erp",
        db_schema="crm",
        search_indexes=["crm"],
        extra_env={
            "required": [
                "CRM_ENRICHMENT_PROVIDER"
            ]
        }
    ),
    service_entry(
        "svc-pm",
        "collaboration",
        db_schema="pm"
    ),
    service_entry(
        "svc-support",
        "collaboration",
        db_schema="support",
        redis_queues=["q:support"],
        s3_paths=["/support"],
        search_indexes=["tickets"],
        extra_env={
            "required": [
                "SUPPORT_INBOUND_EMAIL"
            ]
        }
    ),
    service_entry(
        "svc-kb",
        "collaboration",
        db_schema="kb",
        search_indexes=["kb"]
    ),
    service_entry(
        "svc-collab",
        "collaboration",
        db_schema="collab",
        s3_paths=["/shares"]
    ),
    service_entry(
        "svc-dms",
        "collaboration",
        db_schema="dms",
        s3_paths=["/dms"],
        extra_env={
            "required": [
                "SIGN_PROVIDER_API_KEY"
            ]
        }
    ),
    service_entry(
        "svc-timesheet",
        "collaboration",
        db_schema="timesheet"
    ),
    service_entry(
        "svc-boards",
        "collaboration",
        db_schema="boards"
    ),
    service_entry(
        "svc-chat",
        "collaboration",
        db_schema="chat",
        redis_queues=["ws:rooms"],
        extra_env={
            "required": [
                "CHAT_WS_ORIGIN"
            ]
        }
    ),
    service_entry(
        "svc-forms",
        "collaboration",
        db_schema="forms",
        redis_queues=["q:forms"],
        extra_env={
            "required": [
                "FORMS_SPAM_THRESHOLD"
            ]
        }
    ),
    service_entry(
        "svc-forum",
        "collaboration",
        db_schema="forum",
        search_indexes=["forum"]
    ),
    service_entry(
        "svc-assistant",
        "collaboration",
        db_schema="assistant",
        redis_queues=["q:assistant"],
        extra_env={
            "required": [
                "ASSISTANT_PROVIDER",
                "ASSISTANT_API_KEY"
            ]
        }
    ),
    service_entry(
        "svc-comm",
        "platform",
        db_schema="comm",
        redis_queues=["q:comm"],
        s3_paths=["/templates"],
        extra_env={
            "required": [
                "SMTP_HOST",
                "SMTP_USER",
                "SMTP_PASSWORD"
            ]
        }
    ),
    service_entry(
        "svc-enrichment",
        "platform",
        db_schema="enrichment",
        redis_queues=["q:enrichment"],
        extra_env={
            "required": [
                "ENRICHMENT_SOURCES"
            ]
        }
    ),
    service_entry(
        "svc-billing",
        "platform",
        db_schema="billing",
        redis_queues=["q:billing"],
        s3_paths=["/invoices"],
        extra_env={
            "required": [
                "STRIPE_API_KEY",
                "STRIPE_WEBHOOK_SECRET"
            ]
        }
    ),
    service_entry(
        "svc-bi",
        "platform",
        db_schema="bi",
        redis_queues=["q:etl"],
        extra_env={
            "required": [
                "BI_DSN"
            ]
        }
    ),
    service_entry(
        "svc-plugins",
        "platform",
        db_schema="plugins",
        s3_paths=["/plugins"],
        extra_env={
            "required": [
                "PLUGINS_REGISTRY_URL"
            ]
        }
    ),
    service_entry(
        "svc-n8n",
        "platform",
        process_type="web",
        db_schema=None,
        redis_queues=["q:n8n"],
        s3_paths=[],
        extra_env={
            "required": [
                "N8N_BASIC_AUTH_USER",
                "N8N_BASIC_AUTH_PASSWORD"
            ]
        },
        scale={"staging": "1:S", "production": "1:S"}
    )
])

manifest = {
    "version": "1.0",
    "globals": {
        "organisation": ORG,
        "repo_base": REPO_BASE,
        "domains": {
            "staging": STAGING_DOMAIN,
            "production": PRODUCTION_DOMAIN
        },
        "buckets": {
            "staging": STAGING_BUCKET,
            "production": PRODUCTION_BUCKET
        },
        "projects": {
            "staging": STAGING_PROJECT,
            "production": PRODUCTION_PROJECT
        },
        "deploy": {
            "staging_branch": "develop",
            "production_branch": "main"
        }
    },
    "services": []
}

for svc in services:
    svc_copy = dict(svc)
    repo_name = svc_copy["repo"]
    svc_copy["repo"] = {
        "name": repo_name,
        "url": f"{REPO_BASE}/{repo_name}.git"
    }
    svc_copy["applications"] = {
        "staging": f"ewh-stg-{svc_copy['name']}",
        "production": f"ewh-prod-{svc_copy['name']}"
    }
    svc_copy["projects"] = {
        "staging": STAGING_PROJECT,
        "production": PRODUCTION_PROJECT
    }
    subdomains = svc_copy.get("subdomains", {"staging": None, "production": None})
    mapping = PUBLIC_DOMAINS.get(svc_copy["name"], {})
    subdomains["staging"] = mapping.get("staging")
    subdomains["production"] = mapping.get("production")
    svc_copy["subdomains"] = subdomains
    manifest["services"].append(svc_copy)

Path("infra/scalingo-manifest.json").write_text(json.dumps(manifest, indent=2))
print("✅ Wrote infra/scalingo-manifest.json with", len(services), "services")
