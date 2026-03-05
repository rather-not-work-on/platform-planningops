#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/../.." && pwd)"

REQUIRED_DIRS=(
  "planningops/adr"
  "planningops/artifacts"
  "planningops/config"
  "planningops/contracts"
  "planningops/fixtures"
  "planningops/quality"
  "planningops/schemas"
  "planningops/scripts"
  "planningops/templates"
)

REQUIRED_HEADERS=(
  "## Purpose"
  "## Contents"
  "## Change Rules"
)

if command -v rg >/dev/null 2>&1; then
  SEARCH_TOOL="rg"
else
  SEARCH_TOOL="grep"
fi

violations=0
for dir in "${REQUIRED_DIRS[@]}"; do
  readme="${ROOT_DIR}/${dir}/README.md"
  if [[ ! -f "${readme}" ]]; then
    echo "missing README: ${dir}/README.md"
    violations=$((violations + 1))
    continue
  fi

  for header in "${REQUIRED_HEADERS[@]}"; do
    if [[ "${SEARCH_TOOL}" == "rg" ]]; then
      if ! rg -q "^${header}$" "${readme}"; then
        echo "missing header '${header}' in ${dir}/README.md"
        violations=$((violations + 1))
      fi
    elif ! grep -qE "^${header}$" "${readme}"; then
      echo "missing header '${header}' in ${dir}/README.md"
      violations=$((violations + 1))
    fi
  done
done

if [[ "${violations}" -gt 0 ]]; then
  echo "module README contract failed: ${violations} violation(s)"
  exit 1
fi

echo "module README contract ok"
