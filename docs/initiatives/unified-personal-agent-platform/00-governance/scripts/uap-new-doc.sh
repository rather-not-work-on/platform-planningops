#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
INITIATIVE="unified-personal-agent-platform"
TODAY="$(date +%Y-%m-%d)"

ALLOWED_POSTFIX=(
  brainstorm
  simulation
  strategy
  architecture
  execution-plan
  quality
  navigation
  meta
)

ALLOWED_DOMAIN=(
  governance
  discovery
  architecture
  planning
  quality
  navigation
)

ALLOWED_STATUS=(
  active
  reference
  deprecated
)

contains_value() {
  local needle="$1"
  shift
  local item
  for item in "$@"; do
    if [[ "$item" == "$needle" ]]; then
      return 0
    fi
  done
  return 1
}

expected_domain_for_target_dir() {
  local target_dir="$1"
  case "$target_dir" in
    00-governance) echo "governance" ;;
    10-brainstorm) echo "discovery" ;;
    20-architecture) echo "architecture" ;;
    20-repos/*/10-discovery) echo "discovery" ;;
    20-repos/*/20-architecture) echo "architecture" ;;
    20-repos/*/30-execution-plan) echo "planning" ;;
    20-repos/*/40-quality) echo "quality" ;;
    30-domains/planningops) echo "planning" ;;
    30-domains/contract-evolution) echo "architecture" ;;
    30-domains/observability) echo "quality" ;;
    30-execution-plan) echo "planning" ;;
    40-quality) echo "quality" ;;
    90-navigation) echo "navigation" ;;
    *) echo "" ;;
  esac
}

usage() {
  cat <<'EOF'
Usage:
  uap-new-doc.sh <target-dir> <subject-slug> <postfix> <domain> "<title>" "<summary>" [status]

Example:
  bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-new-doc.sh \
    30-execution-plan \
    planningops-sync-runbook \
    execution-plan \
    planning \
    "PlanningOps Sync Runbook" \
    "Defines operational runbook for planningops sync workflows." \
    reference
EOF
}

main() {
  if (( $# < 6 || $# > 7 )); then
    usage
    exit 1
  fi

  local target_dir="$1"
  local subject_slug="$2"
  local postfix="$3"
  local domain="$4"
  local title="$5"
  local summary="$6"
  local status="${7:-reference}"

  if [[ "$target_dir" == /* || "$target_dir" == *".."* ]]; then
    echo "[ERR] target-dir must be a safe relative path under initiative root"
    exit 1
  fi

  local expected_domain
  expected_domain="$(expected_domain_for_target_dir "$target_dir")"
  if [[ -z "$expected_domain" ]]; then
    echo "[ERR] unknown target-dir mapping '$target_dir'"
    echo "      allowed examples: 10-brainstorm, 20-architecture, 20-repos/<repo>/10-discovery, 30-execution-plan"
    exit 1
  fi

  if [[ ! "$subject_slug" =~ ^[a-z0-9][a-z0-9-]*$ ]]; then
    echo "[ERR] subject-slug must match ^[a-z0-9][a-z0-9-]*$"
    exit 1
  fi

  if ! contains_value "$postfix" "${ALLOWED_POSTFIX[@]}"; then
    echo "[ERR] invalid postfix '$postfix'"
    echo "      allowed: ${ALLOWED_POSTFIX[*]}"
    exit 1
  fi

  if ! contains_value "$domain" "${ALLOWED_DOMAIN[@]}"; then
    echo "[ERR] invalid domain '$domain'"
    echo "      allowed: ${ALLOWED_DOMAIN[*]}"
    exit 1
  fi

  if [[ "$domain" != "$expected_domain" ]]; then
    echo "[ERR] domain mismatch for target-dir '$target_dir': expected '$expected_domain', got '$domain'"
    exit 1
  fi

  if ! contains_value "$status" "${ALLOWED_STATUS[@]}"; then
    echo "[ERR] invalid status '$status'"
    echo "      allowed: ${ALLOWED_STATUS[*]}"
    exit 1
  fi

  local target_path="$ROOT_DIR/$target_dir"
  mkdir -p "$target_path"

  local file_name="$TODAY-uap-$subject_slug.$postfix.md"
  local out_path="$target_path/$file_name"
  if [[ -e "$out_path" ]]; then
    echo "[ERR] target already exists: $out_path"
    exit 1
  fi

  local base_doc_id="uap-$subject_slug"
  local doc_id="$base_doc_id"
  if rg -q "^doc_id:[[:space:]]+$doc_id$" "$ROOT_DIR"; then
    doc_id="${base_doc_id}-${postfix}"
  fi
  if rg -q "^doc_id:[[:space:]]+$doc_id$" "$ROOT_DIR"; then
    echo "[ERR] duplicate doc_id candidate '$doc_id'; choose another subject-slug"
    exit 1
  fi

  cat > "$out_path" <<EOF
---
doc_id: $doc_id
title: $title
doc_type: $postfix
domain: $domain
status: $status
date: $TODAY
updated: $TODAY
initiative: $INITIATIVE
summary: $summary
---

# $title

## Context
- TODO

## Decision
- TODO

## Next Step
- TODO
EOF

  echo "created: $out_path"
  echo "next: bash docs/initiatives/unified-personal-agent-platform/00-governance/scripts/uap-docs.sh check"
}

main "$@"
