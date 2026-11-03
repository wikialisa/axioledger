#!/usr/bin/env node
/**
 * apply-brand.js — Community fork brand substitution script
 *
 * Two-pass operation:
 *   Pass 1 — Convert hardcoded legacy literals → ${VAR} placeholders
 *   Pass 2 — Substitute all ${VAR} placeholders with brand.config.json values
 *
 * Usage:
 *   node scripts/apply-brand.js
 *   node scripts/apply-brand.js --dry-run      # preview only, no writes
 *   node scripts/apply-brand.js --pass1-only   # only literalise (debug)
 *   node scripts/apply-brand.js --pass2-only   # only substitute (if already literalised)
 */

'use strict';

const fs   = require('fs');
const path = require('path');

const ROOT    = path.resolve(__dirname, '..');
const CONFIG  = JSON.parse(fs.readFileSync(path.join(ROOT, 'brand.config.json'), 'utf8'));
const DRY_RUN     = process.argv.includes('--dry-run');
const PASS1_ONLY  = process.argv.includes('--pass1-only');
const PASS2_ONLY  = process.argv.includes('--pass2-only');

const SKIP_DIRS = new Set(['node_modules', '.git', '.changeset', 'out', '.next', 'dist', 'target']);
const APPLY_EXT = new Set([
  '.ts', '.tsx', '.js', '.mjs', '.cjs', '.json', '.md', '.toml',
  '.yml', '.yaml', '.html', '.sh', '.tf', '.sql', '.conf',
  '.example', '.env', '.txt', '.rs', '.sol',
  // nginx http-only variants
  '.http-only',
  // Helm template helpers
  '.tpl',
  // HTML prototypes
  '.html',
]);
// Files matched by name prefix (e.g. Dockerfile.*)
const APPLY_NAME_PREFIX = ['Dockerfile'];

// ─────────────────────────────────────────────────────────────────────────────
// PASS 1 — Literal substitution rules
//
// Each rule maps a hardcoded string literal to a ${VAR} placeholder.
// Rules are applied in ORDER — more specific rules must come before generic ones.
// Only applies to files that already exist in the repo (not generated files).
//
// Convention: "literal" → "${VAR_NAME}"
// ─────────────────────────────────────────────────────────────────────────────
const LITERAL_RULES = [
  // ── Solidity contract names ────────────────────────────────────────────────
  // Must come before generic AXVN substitutions
  { from: 'AXVNSwiftBridgeV2',   to: '${BRAND_SWIFT_BRIDGE_CONTRACT}V2'  },
  { from: 'AXVNSwiftBridge',     to: '${BRAND_SWIFT_BRIDGE_CONTRACT}'    },

  // ── Token symbols in Solidity/TS (sAXVN, gAXVN before AXVN) ──────────────
  { from: 'sAXVNToken',          to: '${BRAND_STOKEN_SYMBOL}Token'        },
  { from: 'gAXVNToken',          to: '${BRAND_GTOKEN_SYMBOL}Token'        },
  { from: 'AXVNToken',           to: '${BRAND_TOKEN_SYMBOL_UPPER}Token'   },
  { from: 'SAXVNToken',          to: '${BRAND_STOKEN_SYMBOL}Token'        },
  { from: 'GAXVNToken',          to: '${BRAND_GTOKEN_SYMBOL}Token'        },

  // ── Solidity variable names (net.sAXVN_TOKEN etc.) ────────────────────────
  { from: 'net.SAXVN_TOKEN',     to: 'net.S${BRAND_TOKEN_SYMBOL_UPPER}_TOKEN' },
  { from: 'net.GAXVN_TOKEN',     to: 'net.G${BRAND_TOKEN_SYMBOL_UPPER}_TOKEN' },
  { from: 'net.AXVN_TOKEN',      to: 'net.${BRAND_TOKEN_SYMBOL_UPPER}_TOKEN'  },

  // ── EVM env var keys in docker-compose (AXVN_EVM_RPC etc.) ───────────────
  { from: 'AXVN_SWIFT_BRIDGE',        to: '${BRAND_INFRA_PREFIX}_SWIFT_BRIDGE'        },
  { from: 'AXVN_EVM_RPC',             to: '${BRAND_INFRA_PREFIX}_EVM_RPC'             },
  { from: 'AXVN_INTERNAL_WEBHOOK_SECRET', to: '${BRAND_INFRA_PREFIX}_INTERNAL_WEBHOOK_SECRET' },
  { from: 'AXVN_SWIFT_LAU_SECRET_KEY_2026!!', to: '${BRAND_INFRA_PREFIX}_SWIFT_LAU_SECRET_KEY!!' },

  // ── DB user names (AXVN_fiat_connector etc.) ──────────────────────────────
  { from: 'AXVN_fiat_connector', to: '${BRAND_INFRA_PREFIX_LOWER}_fiat_connector' },
  { from: 'AXVN_indexer',        to: '${BRAND_INFRA_PREFIX_LOWER}_indexer'        },
  { from: 'AXVN_otc',            to: '${BRAND_INFRA_PREFIX_LOWER}_otc'            },

  // ── npm scope @AXVN/ ──────────────────────────────────────────────────────
  { from: '@AXVN/',              to: '@${BRAND_NPM_SCOPE_UPPER}/'         },

  // ── Docker image registry prefix AXVN/ ────────────────────────────────────
  { from: 'image: AXVN/',        to: 'image: ${BRAND_DOCKER_REGISTRY}/'  },
  // Dockerfile RUN pnpm --filter @AXVN/ already handled by @AXVN/ rule above

  // ── Container names / network names / DB names (standalone AXVN) ─────────
  // These are context-specific: only replace when AXVN is used as infra prefix
  // Patterns: "container_name: AXVN-", "AXVN-network", "POSTGRES_DB: AXVN",
  //           "AXVN/mock-mgw-daemon", "# ── AXVN Infra"
  { from: 'container_name: AXVN-',    to: 'container_name: ${BRAND_INFRA_PREFIX}-' },
  { from: 'name: AXVN-network',       to: 'name: ${BRAND_INFRA_PREFIX}-network'    },
  { from: 'POSTGRES_DB:       AXVN',  to: 'POSTGRES_DB:       ${BRAND_INFRA_PREFIX}' },
  { from: 'POSTGRESQL_DATABASE:       AXVN', to: 'POSTGRESQL_DATABASE:       ${BRAND_INFRA_PREFIX}' },
  { from: 'PGBOUNCER_DATABASE:        AXVN',  to: 'PGBOUNCER_DATABASE:        ${BRAND_INFRA_PREFIX}' },
  { from: 'DATABASE:        AXVN',    to: 'DATABASE:        ${BRAND_INFRA_PREFIX}' },
  { from: ':5432/AXVN',               to: ':5432/${BRAND_INFRA_PREFIX}'             },
  { from: 'REDIS_URL: redis://AXVN-redis', to: 'REDIS_URL: redis://${BRAND_INFRA_PREFIX}-redis' },
  { from: '# ── AXVN Infra',          to: '# ── ${BRAND_INFRA_PREFIX} Infra'        },
  { from: '# ── AXVN R&D',            to: '# ── ${BRAND_INFRA_PREFIX} R&D'          },
  { from: '  # INBOUND:  swift-gateway webhook → settleInboundSwift() → Mint AXVN',
    to:   '  # INBOUND:  swift-gateway webhook → settleInboundSwift() → Mint ${BRAND_TOKEN_SYMBOL_UPPER}' },
  { from: 'image: AXVN/mock-mgw-daemon',   to: 'image: ${BRAND_DOCKER_REGISTRY}/mock-mgw-daemon' },
  { from: 'AXVN TECH HOLDING',             to: '${BRAND_ORG_FULL}'                  },

  // ── SQL GRANT statements ───────────────────────────────────────────────────
  { from: 'GRANT CONNECT ON DATABASE AXVN TO AXVN_', to: 'GRANT CONNECT ON DATABASE ${BRAND_INFRA_PREFIX} TO ${BRAND_INFRA_PREFIX_LOWER}_' },
  { from: 'ON DATABASE AXVN',             to: 'ON DATABASE ${BRAND_INFRA_PREFIX}'   },

  // ── Comment references to token 1 AXVN = 1 VND ───────────────────────────
  { from: '1 AXVN = 1 VND',    to: '1 ${BRAND_TOKEN_SYMBOL_UPPER} = 1 VND' },
  { from: 'Mint AXVN',         to: 'Mint ${BRAND_TOKEN_SYMBOL_UPPER}'       },
  { from: '── FX Oracle (AXVNSwiftBridgeV2', to: '── FX Oracle (${BRAND_SWIFT_BRIDGE_CONTRACT}V2' },

  // ── AXVNIcon component ────────────────────────────────────────────────────
  { from: 'AXVNIcon',          to: '${BRAND_TOKEN_SYMBOL_UPPER}Icon'        },

  // ── explorer-AXVNscan app name ─────────────────────────────────────────────
  { from: 'explorer-AXVNscan', to: 'explorer-${BRAND_INFRA_PREFIX}scan'    },

  // ── @wikialisa/swift-core → ${BRAND_NPM_SCOPE}/${BRAND_SDK_SWIFT_CORE} ────
  { from: '@wikialisa/swift-core', to: '@${BRAND_NPM_SCOPE}/${BRAND_SDK_SWIFT_CORE}' },
  { from: '@wikialisa/config',     to: '@${BRAND_NPM_SCOPE}/config'         },

  // ── deploy.sh container name references ────────────────────────────────────
  { from: 'wait_healthy "AXVN-postgres"',   to: 'wait_healthy "${BRAND_INFRA_PREFIX}-postgres"'  },
  { from: 'wait_healthy "AXVN-redis"',      to: 'wait_healthy "${BRAND_INFRA_PREFIX}-redis"'     },
  { from: 'docker exec -i AXVN-postgres',   to: 'docker exec -i ${BRAND_INFRA_PREFIX}-postgres'  },
  { from: 'psql -U postgres -d AXVN',       to: 'psql -U postgres -d ${BRAND_INFRA_PREFIX}'      },
  { from: '(AXVN-postgres)',                to: '(${BRAND_INFRA_PREFIX}-postgres)'               },
  { from: '(AXVN-pgbouncer)',               to: '(${BRAND_INFRA_PREFIX}-pgbouncer)'              },
  { from: '(AXVN-redis)',                   to: '(${BRAND_INFRA_PREFIX}-redis)'                  },

  // ── docker-compose inline comments ─────────────────────────────────────────
  { from: '# Redis Event Bus — AXVN ↔',    to: '# Redis Event Bus — ${BRAND_INFRA_PREFIX} ↔'   },
  { from: '# AXVN App-Chain EVM RPC',      to: '# ${BRAND_INFRA_PREFIX} App-Chain EVM RPC'      },
  { from: '"pg_isready -U postgres -d AXVN"', to: '"pg_isready -U postgres -d ${BRAND_INFRA_PREFIX}"' },

  // ── Nginx comment header lines ──────────────────────────────────────────────
  { from: '#  AXVN — Nginx',               to: '#  ${BRAND_INFRA_PREFIX} — Nginx'               },

  // ── deploy.sh status output lines ──────────────────────────────────────────
  { from: 'PostgreSQL  → localhost:5432 (AXVN-postgres)',  to: 'PostgreSQL  → localhost:5432 (${BRAND_INFRA_PREFIX}-postgres)'  },
  { from: 'PgBouncer   → localhost:5433 (AXVN-pgbouncer)', to: 'PgBouncer   → localhost:5433 (${BRAND_INFRA_PREFIX}-pgbouncer)' },
  { from: 'Redis       → localhost:6379 (AXVN-redis)',     to: 'Redis       → localhost:6379 (${BRAND_INFRA_PREFIX}-redis)'     },

  // ── PSQL_CMD variable definition ────────────────────────────────────────────
  { from: 'PSQL_CMD="docker exec -i AXVN-postgres psql -U postgres -d AXVN"',
    to:   'PSQL_CMD="docker exec -i ${BRAND_INFRA_PREFIX}-postgres psql -U postgres -d ${BRAND_INFRA_PREFIX}"' },

  // ── Nginx http-only comment header ──────────────────────────────────────────
  { from: '#  AXVN — Nginx Config (HTTP-only',  to: '#  ${BRAND_INFRA_PREFIX} — Nginx Config (HTTP-only' },
  { from: '║   AXVN — Nginx + Let\'s Encrypt', to: '║   ${BRAND_INFRA_PREFIX} — Nginx + Let\'s Encrypt' },

  // ── Terraform ────────────────────────────────────────────────────────────────
  { from: '# ─── Terraform: AXVN Infrastructure',     to: '# ─── Terraform: ${BRAND_INFRA_PREFIX} Infrastructure' },
  { from: 'bucket  = "AXVN-terraform-state"',          to: 'bucket  = "${BRAND_INFRA_PREFIX}-terraform-state"'    },
  { from: 'default     = "AXVN"',                      to: 'default     = "${BRAND_INFRA_PREFIX}"'                },
  { from: 'name = "AXVN-main-cluster-',                to: 'name = "${BRAND_INFRA_PREFIX}-main-cluster-'          },
  { from: 'Project     = "AXVN-tech-holding"',          to: 'Project     = "${BRAND_INFRA_PREFIX}-tech-holding"'  },
  { from: '# AXVN Blockchain Infra',                    to: '# ${BRAND_INFRA_PREFIX} Blockchain Infra'            },
  { from: '# AXVN Global SG',                           to: '# ${BRAND_INFRA_PREFIX} Global SG'                   },
  { from: '# AXVN Capital',                             to: '# ${BRAND_INFRA_PREFIX} Capital'                     },
  { from: '# AXVN Holding',                             to: '# ${BRAND_INFRA_PREFIX} Holding'                     },
  { from: '# AXVN R&D',                                 to: '# ${BRAND_INFRA_PREFIX} R&D'                         },
  { from: 'comment = "AXVN — ${each.value.comment}"',  to: 'comment = "${BRAND_INFRA_PREFIX} — ${each.value.comment}"' },
  { from: 'name        = "AXVN API Rate Limiting"',     to: 'name        = "${BRAND_INFRA_PREFIX} API Rate Limiting"' },

  // ── SQL comment headers & seed data ──────────────────────────────────────────
  { from: '-- AXVN — Database Views',   to: '-- ${BRAND_INFRA_PREFIX} — Database Views'  },
  { from: '-- AXVN — Database Users',   to: '-- ${BRAND_INFRA_PREFIX} — Database Users'  },
  { from: '-- AXVN — Seed Data',        to: '-- ${BRAND_INFRA_PREFIX} — Seed Data'       },
  { from: '\'AXVN Admin\'',             to: '\'${BRAND_INFRA_PREFIX} Admin\''            },
  { from: '/callback/AXVN\'',           to: '/callback/${BRAND_INFRA_PREFIX}\''           },
  { from: '500 AXVN (9 decimals)',       to: '500 ${BRAND_TOKEN_SYMBOL_UPPER} (9 decimals)' },

  // ── SQL misc ──────────────────────────────────────────────────────────────────
  { from: '-- ── Sandbox participant (AXVN itself',  to: '-- ── Sandbox participant (${BRAND_INFRA_PREFIX} itself' },
  { from: '=== AXVN Database Seed Complete ===',     to: '=== ${BRAND_INFRA_PREFIX} Database Seed Complete ===' },

  // ── Kubernetes Helm chart ─────────────────────────────────────────────────────
  { from: '# ─── Helm Chart: AXVN-services',        to: '# ─── Helm Chart: ${BRAND_INFRA_PREFIX}-services'       },
  { from: 'name: AXVN-services',                     to: 'name: ${BRAND_INFRA_PREFIX}-services'                   },
  { from: '# ─── Default values for AXVN-services', to: '# ─── Default values for ${BRAND_INFRA_PREFIX}-services' },
  { from: '  - name: AXVN-registry-secret',          to: '  - name: ${BRAND_INFRA_PREFIX}-registry-secret'       },
  { from: '    - secretName: AXVN-tls',              to: '    - secretName: ${BRAND_INFRA_PREFIX}-tls'            },
  { from: '  AXVN Services — Generic Service',       to: '  ${BRAND_INFRA_PREFIX} Services — Generic Service'    },
  { from: '  AXVN Services — Generic Deployment',    to: '  ${BRAND_INFRA_PREFIX} Services — Generic Deployment' },
  { from: '  AXVN Services — Ingress template',      to: '  ${BRAND_INFRA_PREFIX} Services — Ingress template'   },
  { from: '  AXVN Services Helm Chart — Template',   to: '  ${BRAND_INFRA_PREFIX} Services Helm Chart — Template' },
  { from: '"AXVN-services.name"',                    to: '"${BRAND_INFRA_PREFIX}-services.name"'                  },
  { from: '"AXVN-services.fullname"',                to: '"${BRAND_INFRA_PREFIX}-services.fullname"'              },
  { from: '"AXVN-services.labels"',                  to: '"${BRAND_INFRA_PREFIX}-services.labels"'                },
  { from: '"AXVN-services.selectorLabels"',          to: '"${BRAND_INFRA_PREFIX}-services.selectorLabels"'        },
  { from: '{{ include "AXVN-services.name"',         to: '{{ include "${BRAND_INFRA_PREFIX}-services.name"'       },
  { from: '{{ include "AXVN-services.selectorLabels"', to: '{{ include "${BRAND_INFRA_PREFIX}-services.selectorLabels"' },
  { from: 'name: AXVN-secrets',                      to: 'name: ${BRAND_INFRA_PREFIX}-secrets'                   },

  // ── Helm _helpers.tpl (define blocks) ────────────────────────────────────────
  { from: '{{- define "AXVN-services.name"',          to: '{{- define "${BRAND_INFRA_PREFIX}-services.name"'      },
  { from: '{{- define "AXVN-services.fullname"',      to: '{{- define "${BRAND_INFRA_PREFIX}-services.fullname"'  },
  { from: '{{- define "AXVN-services.labels"',        to: '{{- define "${BRAND_INFRA_PREFIX}-services.labels"'    },
  { from: '{{- define "AXVN-services.selectorLabels"',to: '{{- define "${BRAND_INFRA_PREFIX}-services.selectorLabels"' },

  // ── npm deploy tooling ────────────────────────────────────────────────────────
  { from: '# NPM Registry — AXVN Package',            to: '# NPM Registry — ${BRAND_INFRA_PREFIX} Package'       },
  { from: '"📦  AXVN NPM Publisher"',                 to: '"📦  ${BRAND_INFRA_PREFIX} NPM Publisher"'            },
  { from: '"description": "NPM publish tooling for AXVN', to: '"description": "NPM publish tooling for ${BRAND_INFRA_PREFIX}' },

  // ── PM2 ecosystem ─────────────────────────────────────────────────────────────
  { from: '// PM2 Ecosystem — AXVN Tech Holding',     to: '// PM2 Ecosystem — ${BRAND_ORG_FULL}'                 },

  // ── Docs / INFRASTRUCTURE_STANDARDS.md ───────────────────────────────────────
  { from: 'github.com/AXVNvietnam/AXVN-tech-holding', to: 'github.com/${BRAND_ORG_GITHUB}/${BRAND_INFRA_PREFIX}-tech-holding' },
  { from: 'AXVN-tech-holding/',                        to: '${BRAND_INFRA_PREFIX}-tech-holding/'                 },
  { from: '@your-npm-org/AXVN-types',                  to: '@${BRAND_NPM_SCOPE}/${BRAND_INFRA_PREFIX_LOWER}-types' },
  { from: '"name": "AXVN-tech-holding-monorepo"',      to: '"name": "${BRAND_INFRA_PREFIX_LOWER}-tech-holding-monorepo"' },
  { from: '"url":  "https://github.com/AXVNvietnam/AXVN-packages.git"', to: '"url": "https://github.com/${BRAND_ORG_GITHUB}/${BRAND_INFRA_PREFIX_LOWER}-packages.git"' },

  // ── HTML prototype ────────────────────────────────────────────────────────────
  { from: 'AXVN Fintech – 42-Screen Interactive Prototype', to: '${BRAND_INFRA_PREFIX} Fintech – 42-Screen Interactive Prototype' },
  { from: '>AXVN<',                                    to: '>${BRAND_INFRA_PREFIX}<'                              },

  // ── gen-env-secrets.sh ────────────────────────────────────────────────────────
  { from: 'AXVN — Auto-generate',                     to: '${BRAND_INFRA_PREFIX} — Auto-generate'               },
  { from: 'grep AXVN)',                                to: 'grep ${BRAND_INFRA_PREFIX})'                         },

  // ── setup-mgw-keystore.sh ─────────────────────────────────────────────────────
  { from: 'AXVN SWIFT MGW — Keystore',                to: '${BRAND_INFRA_PREFIX} SWIFT MGW — Keystore'          },

  // ── test-swift-gateway.sh ─────────────────────────────────────────────────────
  { from: '  AXVN SWIFT GATEWAY INTEGRATION TEST SUITE', to: '  ${BRAND_INFRA_PREFIX} SWIFT GATEWAY INTEGRATION TEST SUITE' },
  { from: '"msgId": "AXVN/',                           to: '"msgId": "${BRAND_INFRA_PREFIX}/'                    },
  { from: '"endToEndId": "E2E-AXVN-',                  to: '"endToEndId": "E2E-${BRAND_INFRA_PREFIX}-'           },

  // ── run-swift-setup.sh ────────────────────────────────────────────────────────
  { from: 'AXVN SWIFT Setup hoàn tất',                 to: '${BRAND_INFRA_PREFIX} SWIFT Setup hoàn tất'         },

  // ── publish-all.mjs (with chalk formatting) ───────────────────────────────────
  { from: '"\n📦  AXVN NPM Publisher"',                to: '"\n📦  ${BRAND_INFRA_PREFIX} NPM Publisher"'        },

  // ── vnkr-infra-setup.sh ───────────────────────────────────────────────────────
  { from: 'Tác giả:    AXVN Platform',                 to: 'Tác giả:    ${BRAND_INFRA_PREFIX} Platform'        },
  { from: 'AXVN-tech-holding-monorepo (GitHub)',        to: '${BRAND_INFRA_PREFIX}-tech-holding-monorepo (GitHub)' },
  { from: '(AXVN design system)',                       to: '(${BRAND_INFRA_PREFIX} design system)'             },
  { from: '# AXVN scope → GitHub Packages',            to: '# ${BRAND_INFRA_PREFIX} scope → GitHub Packages'   },
  { from: '(added by AXVN-infra-setup.sh)',             to: '(added by ${BRAND_INFRA_PREFIX}-infra-setup.sh)'  },
  { from: 'AXVN Infra Setup — Chuẩn Hóa',              to: '${BRAND_INFRA_PREFIX} Infra Setup — Chuẩn Hóa'    },
  { from: 'bash scripts/AXVN-infra-setup.sh',          to: 'bash scripts/${BRAND_INFRA_PREFIX}-infra-setup.sh' },

  // ── installer.sh ──────────────────────────────────────────────────────────────
  { from: 'môi trường trên VPS cho monorepo AXVN.',    to: 'môi trường trên VPS cho monorepo ${BRAND_INFRA_PREFIX}.' },
  { from: '"/var/log/AXVN-installer.log"',             to: '"/var/log/${BRAND_INFRA_PREFIX}-installer.log"'    },
  { from: "WHERE datname='AXVN';",                     to: "WHERE datname='${BRAND_INFRA_PREFIX}';"            },
  { from: '# Set password cho superuser postgres & tạo database AXVN', to: '# Set password cho superuser postgres & tạo database ${BRAND_INFRA_PREFIX}' },
  { from: "'CREATE DATABASE AXVN ENCODING",                  to: "'CREATE DATABASE ${BRAND_INFRA_PREFIX} ENCODING"  },
  { from: 'psql -U postgres -h 127.0.0.1 -d AXVN',          to: 'psql -U postgres -h 127.0.0.1 -d ${BRAND_INFRA_PREFIX}' },
  { from: '"AXVN < "$sql_file"',                             to: '"${BRAND_INFRA_PREFIX} < "$sql_file"'             },
  { from: 'sites-available/AXVN"',                           to: 'sites-available/${BRAND_INFRA_PREFIX}"'           },
  { from: 'sites-enabled/AXVN"',                             to: 'sites-enabled/${BRAND_INFRA_PREFIX}"'             },
  { from: 'conf.d/AXVN.conf"',                               to: 'conf.d/${BRAND_INFRA_PREFIX}.conf"'               },
  { from: '# AXVN — Generated by scripts/installer.sh',      to: '# ${BRAND_INFRA_PREFIX} — Generated by scripts/installer.sh' },
  { from: 'sites-available/AXVN.conf"',                      to: 'sites-available/${BRAND_INFRA_PREFIX}.conf"'      },

  // ── publish-all.mjs exact match ───────────────────────────────────────────────
  { from: 'chalk.bold.cyan("\\n📦  AXVN NPM Publisher")',    to: 'chalk.bold.cyan("\\n📦  ${BRAND_INFRA_PREFIX} NPM Publisher")' },
];

// ─────────────────────────────────────────────────────────────────────────────
// PASS 2 — ${VAR} → brand.config.json value substitution
// ─────────────────────────────────────────────────────────────────────────────
function applyPass2(content) {
  let changed = false;
  for (const [key, val] of Object.entries(CONFIG)) {
    if (key.startsWith('_')) continue;
    if (typeof val !== 'string') continue;
    const placeholder = '${' + key + '}';
    if (content.includes(placeholder)) {
      content = content.replaceAll(placeholder, val);
      changed = true;
    }
  }
  return { content, changed };
}

// ─────────────────────────────────────────────────────────────────────────────
// File walker
// ─────────────────────────────────────────────────────────────────────────────
let pass1Count = 0;
let pass2Count = 0;

function processFile(fpath) {
  const ext    = path.extname(fpath);
  const bname  = path.basename(fpath);
  const isEnv  = bname.startsWith('.env');
  const isNameMatch = APPLY_NAME_PREFIX.some(p => bname.startsWith(p));

  if (!APPLY_EXT.has(ext) && !isEnv && !isNameMatch) return;
  if (bname === 'brand.config.json') return;
  if (bname === 'apply-brand.js') return;

  let content = fs.readFileSync(fpath, 'utf8');
  let p1Changed = false;
  let p2Changed = false;

  // Pass 1 — literal → placeholder
  if (!PASS2_ONLY) {
    for (const rule of LITERAL_RULES) {
      if (content.includes(rule.from)) {
        content = content.replaceAll(rule.from, rule.to);
        p1Changed = true;
      }
    }
    if (p1Changed) pass1Count++;
  }

  // Pass 2 — placeholder → value
  if (!PASS1_ONLY) {
    const r = applyPass2(content);
    content  = r.content;
    p2Changed = r.changed;
    if (p2Changed) pass2Count++;
  }

  if (p1Changed || p2Changed) {
    const rel = path.relative(ROOT, fpath);
    const tag = [p1Changed && 'literal→var', p2Changed && 'var→value'].filter(Boolean).join(', ');
    if (DRY_RUN) {
      console.log(`  [dry-run] ${tag}: ${rel}`);
    } else {
      fs.writeFileSync(fpath, content, 'utf8');
      console.log(`  ✓ [${tag}] ${rel}`);
    }
  }
}

function walk(dir) {
  for (const entry of fs.readdirSync(dir, { withFileTypes: true })) {
    const full = path.join(dir, entry.name);
    if (entry.isDirectory()) {
      if (!SKIP_DIRS.has(entry.name)) walk(full);
    } else {
      processFile(full);
    }
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Main
// ─────────────────────────────────────────────────────────────────────────────
console.log(`\napply-brand.js — ${DRY_RUN ? 'DRY RUN' : 'APPLYING'}`);
if (PASS1_ONLY) console.log('Mode: pass1 only (literal → placeholder)');
if (PASS2_ONLY) console.log('Mode: pass2 only (placeholder → value)');
console.log(`Config keys: ${Object.keys(CONFIG).filter(k => !k.startsWith('_')).join(', ')}\n`);

walk(ROOT);

console.log('');
if (!PASS2_ONLY) console.log(`Pass 1 (literal→var)   : ${pass1Count} files ${DRY_RUN ? 'would be ' : ''}updated`);
if (!PASS1_ONLY) console.log(`Pass 2 (var→value)     : ${pass2Count} files ${DRY_RUN ? 'would be ' : ''}updated`);
console.log('');
