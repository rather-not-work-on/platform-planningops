#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
ROOT_DIR="$(cd -- "$SCRIPT_DIR/../.." && pwd)"
CATALOG_PATH="$ROOT_DIR/2026-02-27-uap-frontmatter-catalog.navigation.md"

REQUIRED_KEYS=(
  doc_id
  title
  doc_type
  domain
  status
  date
  updated
  initiative
  summary
)

ALLOWED_STATUS=(
  active
  draft
  archived
)

list_docs() {
  find "$ROOT_DIR" -type f -name "*.md" \
    ! -name "._*" \
    ! -path "*/00-governance/scripts/*" \
    | sort
}

cleanup_appledouble() {
  find "$ROOT_DIR" -type f -name "._*" -print0 \
    | while IFS= read -r -d '' file; do
        rm -f "$file"
      done
}

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

expected_doc_type() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"

  if [[ "$(basename "$rel")" == "README.md" ]]; then
    echo "hub"
    return 0
  fi

  if [[ "$rel" =~ \.brainstorm\.md$ ]]; then echo "brainstorm"; return 0; fi
  if [[ "$rel" =~ \.simulation\.md$ ]]; then echo "simulation"; return 0; fi
  if [[ "$rel" =~ \.strategy\.md$ ]]; then echo "strategy"; return 0; fi
  if [[ "$rel" =~ \.architecture\.md$ ]]; then echo "architecture"; return 0; fi
  if [[ "$rel" =~ \.execution-plan\.md$ ]]; then echo "execution-plan"; return 0; fi
  if [[ "$rel" =~ \.quality\.md$ ]]; then echo "quality"; return 0; fi
  if [[ "$rel" =~ \.navigation\.md$ ]]; then echo "navigation"; return 0; fi
  if [[ "$rel" =~ \.meta\.md$ ]]; then echo "meta"; return 0; fi

  echo ""
}

expected_domain() {
  local file="$1"
  local rel="${file#$ROOT_DIR/}"

  if [[ "$(basename "$rel")" == "README.md" ]]; then
    echo "navigation"
    return 0
  fi
  if [[ "$rel" == "AGENT.md" ]]; then
    echo "governance"
    return 0
  fi
  if [[ "$rel" == "AGENT-START.md" ]]; then
    echo "navigation"
    return 0
  fi
  if [[ "$rel" =~ \.navigation\.md$ ]]; then
    echo "navigation"
    return 0
  fi

  case "$rel" in
    00-governance/*) echo "governance" ;;
    10-brainstorm/*) echo "discovery" ;;
    20-architecture/*) echo "architecture" ;;
    20-repos/*/10-discovery/*) echo "discovery" ;;
    20-repos/*/20-architecture/*) echo "architecture" ;;
    20-repos/*/30-execution-plan/*) echo "planning" ;;
    20-repos/*/40-quality/*) echo "quality" ;;
    30-domains/planningops/*) echo "planning" ;;
    30-domains/contract-evolution/*) echo "architecture" ;;
    30-domains/observability/*) echo "quality" ;;
    30-execution-plan/*) echo "planning" ;;
    40-quality/*) echo "quality" ;;
    90-navigation/*) echo "navigation" ;;
    *) echo "" ;;
  esac
}

extract_scalar() {
  local file="$1"
  local key="$2"
  awk -v k="$key" '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && $0 ~ ("^" k ":") {
      sub("^" k ":[[:space:]]*", "", $0)
      print $0
      exit
    }
  ' "$file"
}

extract_related_docs() {
  local file="$1"
  awk '
    NR == 1 && $0 == "---" { in_fm=1; next }
    in_fm && $0 == "---" { exit }
    in_fm && /^related_docs:[[:space:]]*$/ { in_rel=1; next }
    in_rel && /^  - / {
      sub(/^  - /, "", $0)
      print $0
      next
    }
    in_rel && /^[^[:space:]-]/ { in_rel=0 }
  ' "$file"
}

extract_markdown_links() {
  local file="$1"
  rg -o '\[[^]]+\]\([^)]+\)' "$file" \
    | sed -E 's/.*\(([^)]+)\)$/\1/' \
    | sort -u
}

check_docs() {
  local errors=0
  local seen_doc_ids_file
  seen_doc_ids_file="$(mktemp)"

  while IFS= read -r file; do
    if [[ "$(head -n 1 "$file")" != "---" ]]; then
      echo "[ERR] frontmatter missing: $file"
      errors=$((errors + 1))
      continue
    fi

    for key in "${REQUIRED_KEYS[@]}"; do
      local value
      value="$(extract_scalar "$file" "$key" || true)"
      if [[ -z "$value" ]]; then
        echo "[ERR] missing key '$key': $file"
        errors=$((errors + 1))
      fi
    done

    local doc_id
    doc_id="$(extract_scalar "$file" "doc_id" || true)"
    if [[ -n "$doc_id" ]]; then
      local prev_file
      prev_file="$(awk -F'\t' -v id="$doc_id" '$1 == id { print $2; exit }' "$seen_doc_ids_file")"
      if [[ -n "$prev_file" ]]; then
        echo "[ERR] duplicate doc_id '$doc_id':"
        echo "      - $prev_file"
        echo "      - $file"
        errors=$((errors + 1))
      else
        printf "%s\t%s\n" "$doc_id" "$file" >> "$seen_doc_ids_file"
      fi
    fi

    local doc_type
    doc_type="$(extract_scalar "$file" "doc_type" || true)"
    local expected_type
    expected_type="$(expected_doc_type "$file")"
    if [[ -n "$expected_type" && "$doc_type" != "$expected_type" ]]; then
      echo "[ERR] doc_type mismatch: $file (expected '$expected_type', got '$doc_type')"
      errors=$((errors + 1))
    fi

    local domain
    domain="$(extract_scalar "$file" "domain" || true)"
    local expected_dom
    expected_dom="$(expected_domain "$file")"
    if [[ -z "$expected_dom" ]]; then
      echo "[ERR] unknown directory mapping for domain check: $file"
      errors=$((errors + 1))
    elif [[ "$domain" != "$expected_dom" ]]; then
      echo "[ERR] domain mismatch: $file (expected '$expected_dom', got '$domain')"
      errors=$((errors + 1))
    fi

    local status
    status="$(extract_scalar "$file" "status" || true)"
    if ! contains_value "$status" "${ALLOWED_STATUS[@]}"; then
      echo "[ERR] invalid status '$status': $file (allowed: active,draft,archived)"
      errors=$((errors + 1))
    fi

    while IFS= read -r rel; do
      [[ -z "$rel" ]] && continue
      if [[ "$rel" == http://* || "$rel" == https://* ]]; then
        continue
      fi
      if [[ "$rel" == /* ]]; then
        echo "[ERR] related_docs must be relative path: $file -> $rel"
        errors=$((errors + 1))
        continue
      fi
      local base_dir target_path
      base_dir="$(dirname "$file")"
      target_path="$base_dir/$rel"
      if [[ ! -f "$target_path" ]]; then
        echo "[ERR] related_docs target not found: $file -> $rel"
        errors=$((errors + 1))
      fi
    done < <(extract_related_docs "$file")

    while IFS= read -r link; do
      [[ -z "$link" ]] && continue
      if [[ "$link" == http://* || "$link" == https://* || "$link" == mailto:* || "$link" == \#* ]]; then
        continue
      fi
      local normalized
      normalized="${link%%#*}"
      [[ -z "$normalized" ]] && continue
      local link_target
      link_target="$base_dir/$normalized"
      if [[ ! -e "$link_target" ]]; then
        echo "[ERR] markdown link target not found: $file -> $link"
        errors=$((errors + 1))
      fi
    done < <(extract_markdown_links "$file")
  done < <(list_docs)

  rm -f "$seen_doc_ids_file"

  if (( errors > 0 )); then
    echo "check failed: $errors error(s)"
    return 1
  fi

  echo "check passed: frontmatter and related_docs are valid"
}

generate_catalog() {
  local tmp_file tmp_rows today
  tmp_file="$(mktemp)"
  tmp_rows="$(mktemp)"
  today="$(date +%Y-%m-%d)"

  while IFS= read -r file; do
    local rel doc_id title doc_type domain status summary
    rel="${file#$ROOT_DIR/}"
    doc_id="$(extract_scalar "$file" "doc_id" || true)"
    title="$(extract_scalar "$file" "title" || true)"
    doc_type="$(extract_scalar "$file" "doc_type" || true)"
    domain="$(extract_scalar "$file" "domain" || true)"
    status="$(extract_scalar "$file" "status" || true)"
    summary="$(extract_scalar "$file" "summary" || true)"
    summary="${summary//|/\\|}"
    title="${title//|/\\|}"
    printf "%s\t%s\t%s\t%s\t%s\t%s\t%s\n" \
      "$domain" "$doc_type" "$doc_id" "$status" "$rel" "$title" "$summary" \
      >> "$tmp_rows"
  done < <(list_docs)

  sort -t$'\t' -k1,1 -k2,2 -k5,5 "$tmp_rows" > "${tmp_rows}.sorted"

  cat > "$tmp_file" <<EOF
---
doc_id: uap-frontmatter-catalog
title: UAP Frontmatter Catalog
doc_type: navigation
domain: navigation
status: active
date: 2026-02-27
updated: $today
initiative: unified-personal-agent-platform
tags:
  - uap
  - catalog
  - frontmatter
  - navigation
summary: Auto-generated catalog for quick navigation across UAP documents.
related_docs:
  - ./README.md
  - ./90-navigation/2026-02-27-uap-document-map.navigation.md
  - ./00-governance/2026-02-27-uap-doc-governance.meta.md
---

# UAP Frontmatter Catalog

이 문서는 frontmatter 기반으로 자동 생성된다.

- 생성 스크립트: \`00-governance/scripts/uap-docs.sh\`
- 생성 명령: \`bash ./00-governance/scripts/uap-docs.sh catalog\`

## Table

| domain | type | doc_id | status | path | title | summary |
|---|---|---|---|---|---|---|
EOF

  while IFS=$'\t' read -r domain doc_type doc_id status rel title summary; do
    printf "| %s | %s | %s | %s | [%s](%s) | %s | %s |\n" \
      "$domain" "$doc_type" "$doc_id" "$status" "$rel" "$rel" "$title" "$summary" \
      >> "$tmp_file"
  done < "${tmp_rows}.sorted"

  mv "$tmp_file" "$CATALOG_PATH"
  rm -f "$tmp_rows" "${tmp_rows}.sorted"
  echo "catalog generated: $CATALOG_PATH"
}

usage() {
  cat <<'EOF'
Usage:
  uap-docs.sh clean     # Remove macOS AppleDouble artifacts (._*)
  uap-docs.sh check     # Validate frontmatter and related_docs links
  uap-docs.sh catalog   # Generate frontmatter catalog
  uap-docs.sh sync      # Run catalog -> check
EOF
}

main() {
  local cmd="${1:-sync}"
  case "$cmd" in
    clean)
      cleanup_appledouble
      echo "cleaned: AppleDouble artifacts removed"
      ;;
    check)
      cleanup_appledouble
      check_docs
      cleanup_appledouble
      ;;
    catalog)
      cleanup_appledouble
      generate_catalog
      cleanup_appledouble
      ;;
    sync)
      cleanup_appledouble
      generate_catalog
      check_docs
      cleanup_appledouble
      ;;
    *)
      usage
      exit 1
      ;;
  esac
}

main "$@"
