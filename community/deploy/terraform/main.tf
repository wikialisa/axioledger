# ─── Terraform: YOUR_INFRA Infrastructure as Code ──────────────────────────────────
# Provider versions
terraform {
  required_providers {
    aws = {
      source  = "hashicorp/aws"
      version = "~> 5.0"
    }
    cloudflare = {
      source  = "cloudflare/cloudflare"
      version = "~> 4.0"
    }
  }
  required_version = ">= 1.8"

  # Remote state — S3 backend (update bucket/key per environment)
  backend "s3" {
    bucket  = "YOUR_INFRA-terraform-state"
    key     = "infra/terraform.tfstate"
    region  = "ap-southeast-1"
    encrypt = true
  }
}

provider "aws" {
  region = var.aws_region
}

provider "cloudflare" {
  api_token  = var.cloudflare_api_token
  account_id = var.cloudflare_account_id
}

# ─── Variables ────────────────────────────────────────────────────────────────

variable "aws_region" {
  description = "AWS deployment region"
  type        = string
  default     = "ap-southeast-1"
}

variable "cloudflare_api_token" {
  description = "Cloudflare API token (set via TF_VAR_cloudflare_api_token or .tfvars)"
  type        = string
  sensitive   = true
}

variable "cloudflare_account_id" {
  description = "Cloudflare Account ID"
  type        = string
  sensitive   = true
  # default from .env.example: YOUR_CLOUDFLARE_ZONE_AND_ACCOUNT_ID
}

variable "cloudflare_zone_id" {
  description = "Cloudflare Zone ID for your-project.vn"
  type        = string
  # default from .env.example: YOUR_CLOUDFLARE_ZONE_AND_ACCOUNT_ID
}

variable "lb_origin" {
  description = "Load-balancer / origin CNAME for all subdomain records"
  type        = string
  default     = "lb.your-project.vn"
}

variable "environment" {
  description = "Deployment environment (dev | staging | prod)"
  type        = string
  default     = "prod"
}

variable "ecr_repository_prefix" {
  description = "ECR image repository prefix"
  type        = string
  default     = "YOUR_INFRA"
}

# ─── ECS Cluster ──────────────────────────────────────────────────────────────

resource "aws_ecs_cluster" "AXVN_main" {
  name = "YOUR_INFRA-main-cluster-${var.environment}"

  setting {
    name  = "containerInsights"
    value = "enabled"
  }

  tags = {
    Project     = "YOUR_INFRA-tech-holding"
    Environment = var.environment
  }
}

# ─── ECR Repositories for each microservice ───────────────────────────────────

locals {
  microservices = [
    "fiat-connector-api",
    "otc-liquidity-engine",
    "indexer-subgraph",
    "dune-alert-bots",
  ]
}

resource "aws_ecr_repository" "AXVN_services" {
  for_each             = toset(local.microservices)
  name                 = "${var.ecr_repository_prefix}/${each.key}"
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = true
  }

  tags = {
    Project     = "YOUR_INFRA-tech-holding"
    Environment = var.environment
  }
}

# ─── Cloudflare DNS — 10 subdomains ───────────────────────────────────────────

locals {
  dns_records = {
    # Your FinTech Division Name
    "id"  = { subdomain = "id",  comment = "P2P Escrow & Fiat Gateway" }
    "pay" = { subdomain = "pay", comment = "Payment Gateway & Merchant Dashboard" }

    # YOUR_INFRA Blockchain Infra
    "scan"                  = { subdomain = "scan",                  comment = "Block Explorer & Proof of Reserve" }
    "treasury-subgraph-api" = { subdomain = "treasury-subgraph-api", comment = "Subgraph Indexer API" }

    # YOUR_INFRA Global SG
    "swap" = { subdomain = "swap", comment = "AMM DEX & Liquidity Router" }

    # YOUR_INFRA Capital
    "dao" = { subdomain = "dao", comment = "Treasury & Governance Portal" }

    # Your MENA Division Name
    "otc" = { subdomain = "otc", comment = "Institutional OTC Liquidity Engine" }

    # YOUR_INFRA Holding
    "holding" = { subdomain = "holding", comment = "Admin Portal — IP Asset & Whitelist" }

    # YOUR_INFRA R&D
    "lab" = { subdomain = "lab", comment = "Digital Twin Engine & AI Lab" }

    # Developer API
    "dev-api" = { subdomain = "dev-api", comment = "Merchant SDK Gateway" }
  }
}

resource "cloudflare_record" "AXVN_subdomains" {
  for_each = local.dns_records

  zone_id = var.cloudflare_zone_id
  name    = each.value.subdomain
  value   = var.lb_origin
  type    = "CNAME"
  proxied = true
  ttl     = 1   # automatic when proxied = true

  comment = "YOUR_INFRA — ${each.value.comment}"
}

# ─── Cloudflare WAF — rate limiting for API endpoints ─────────────────────────

resource "cloudflare_ruleset" "AXVN_rate_limit" {
  zone_id     = var.cloudflare_zone_id
  name        = "YOUR_INFRA API Rate Limiting"
  description = "Protect dev-api and otc endpoints from abuse"
  kind        = "zone"
  phase       = "http_ratelimit"

  rules {
    action = "block"
    ratelimit {
      characteristics       = ["cf.colo.id", "ip.src"]
      period                = 60
      requests_per_period   = 100
      mitigation_timeout    = 600
    }
    expression  = "(http.host eq \"dev-api.your-project.vn\") or (http.host eq \"otc.your-project.vn\")"
    description = "Rate limit API surfaces to 100 req/min"
    enabled     = true
  }
}

# ─── Outputs ──────────────────────────────────────────────────────────────────

output "ecs_cluster_arn" {
  description = "ARN of the ECS cluster"
  value       = aws_ecs_cluster.AXVN_main.arn
}

output "ecr_repository_urls" {
  description = "ECR image URLs for each microservice"
  value       = { for k, v in aws_ecr_repository.AXVN_services : k => v.repository_url }
}

output "cloudflare_dns_records" {
  description = "Created Cloudflare DNS record names"
  value       = { for k, v in cloudflare_record.AXVN_subdomains : k => "${v.name}.your-project.vn" }
}
