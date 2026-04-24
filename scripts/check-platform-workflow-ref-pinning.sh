#!/usr/bin/env bash
set -euo pipefail

repo_root="${1:-.}"
workflow_dir="${repo_root}/.github/workflows"

if [[ ! -d "${workflow_dir}" ]]; then
  echo "No .github/workflows directory found under ${repo_root}; skipping shared workflow ref pinning check."
  exit 0
fi

violations="$(
  rg -n --pcre2 \
    'uses:\s*zavestudios/platform-pipelines/\.github/workflows/[^@[:space:]]+@(?![0-9a-f]{40}\b)[^[:space:]]+' \
    "${workflow_dir}" || true
)"

if [[ -n "${violations}" ]]; then
  cat <<EOF
Found non-compliant shared workflow refs. Governed repositories must pin
zavestudios/platform-pipelines reusable workflow refs to immutable 40-character
commit SHAs.

Violations:
${violations}

Example fix:
  uses: zavestudios/platform-pipelines/.github/workflows/security-scan.yml@0123456789abcdef0123456789abcdef01234567
EOF
  exit 1
fi

echo "All zavestudios/platform-pipelines reusable workflow refs are pinned to immutable SHAs."
