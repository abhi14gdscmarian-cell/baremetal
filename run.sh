#!/usr/bin/env bash

set -euo pipefail

# Resolve paths from this script so it can be launched from any working directory.
PROJECT_ROOT="$(cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd -P)"
BUILD_DIR="${1:-${PROJECT_ROOT}/build-tests}"
BUILD_DIR="$(cd -- "${BUILD_DIR}" && pwd -P)"
cd -- "${BUILD_DIR}"

to_unix_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -u "$1"
  elif command -v wslpath >/dev/null 2>&1; then
    wslpath -u "$1"
  elif [[ "$1" =~ ^([A-Za-z]):[/\\](.*)$ ]]; then
    local drive
    drive="$(printf '%s' "${BASH_REMATCH[1]}" | tr '[:upper:]' '[:lower:]')"
    printf '/mnt/%s/%s\n' "${drive}" "${BASH_REMATCH[2]//\\//}"
  else
    printf '%s\n' "$1"
  fi
}

to_mixed_path() {
  if command -v cygpath >/dev/null 2>&1; then
    cygpath -m "$1"
  else
    printf '%s\n' "${1//\\//}"
  fi
}

if ! command -v lcov >/dev/null 2>&1; then
  echo "Error: lcov is not installed or is not on PATH." >&2
  exit 1
fi
if ! command -v genhtml >/dev/null 2>&1; then
  echo "Error: genhtml is not installed or is not on PATH." >&2
  exit 1
fi

if [[ -z "${GCOV_TOOL:-}" ]]; then
  # Prefer gcov next to the compiler used to create this build's coverage data.
  COMPILER_PATH="$(
    sed -n 's/^CMAKE_C_COMPILER:FILEPATH=//p' \
      "${BUILD_DIR}/CMakeCache.txt" 2>/dev/null | head -n 1
  )"
  if [[ -n "${COMPILER_PATH}" ]]; then
    COMPILER_PATH="$(to_unix_path "${COMPILER_PATH}")"
    COMPILER_DIR="$(dirname -- "${COMPILER_PATH}")"
    for candidate in "${COMPILER_DIR}/gcov.exe" "${COMPILER_DIR}/gcov"; do
      if [[ -x "${candidate}" ]]; then
        GCOV_TOOL="${candidate}"
        break
      fi
    done
  fi

  if [[ -z "${GCOV_TOOL:-}" ]]; then
    GCOV_TOOL="$(command -v gcov.exe || command -v gcov || true)"
  fi
fi

if [[ -z "${GCOV_TOOL:-}" || ! -x "${GCOV_TOOL}" ]]; then
  echo "Error: gcov tool not found or not executable: ${GCOV_TOOL:-<not found>}" >&2
  echo "Set GCOV_TOOL to the gcov tool matching the compiler used for this build." >&2
  exit 1
fi

ROOT_FOR_TRACE="$(to_mixed_path "${PROJECT_ROOT}")"
ROOT_UNIX_FOR_TRACE="$(to_unix_path "${PROJECT_ROOT}")"
ROOT_RELATIVE="$(realpath --relative-to="${BUILD_DIR}" "${PROJECT_ROOT}")"
TRACE_RAW="${BUILD_DIR}/coverage.raw.info"
TRACE_NORMALIZED="${BUILD_DIR}/coverage.info"
TRACE_FILTERED="${BUILD_DIR}/coverage.filtered.info"
HTML_DIR="${BUILD_DIR}/coverage_html"

echo "Capturing coverage from: ${BUILD_DIR}"
lcov --capture \
  --directory "${BUILD_DIR}" \
  --base-directory "${PROJECT_ROOT}" \
  --output-file "${TRACE_RAW}" \
  --gcov-tool "${GCOV_TOOL}" \
  --rc lcov_branch_coverage=1 \
  --rc geninfo_auto_base=1

# gcov on Windows can emit paths shaped like:
#   /c/<project>/C:/<absolute project path>/<source>
# Keep only source paths whose embedded Windows path belongs to this checkout.
# Drop malformed/stale absolute paths (often from an older build directory).
awk -v root="${ROOT_UNIX_FOR_TRACE}/" \
    -v windows_root="${ROOT_FOR_TRACE}/" \
    -v relative="${ROOT_RELATIVE}/" '
  /^TN:/ { print; keep = 1; next }
  /^SF:/ {
    source = substr($0, 4)
    if (index(source, root) == 1) {
      source = substr(source, length(root) + 1)
        if (index(source, windows_root) == 1) {
          source = substr(source, length(windows_root) + 1)
        } else if (source ~ /^([A-Za-z]:\/|\/)/) {
          keep = 0
          next
        }
        if (source == "" || source ~ /^([A-Za-z]:\/|\/)/) {
        keep = 0
        next
      }
      print "SF:" relative source
      keep = 1
      next
    }
    # Already-relative source paths are valid. Never pass absolute host paths
    # through to genhtml, where they may resolve against the wrong checkout.
    if (source ~ /^([A-Za-z]:\/|\/)/) {
      keep = 0
      next
    }
    print
    keep = 1
    next
  }
  { if (keep) print }
' "${TRACE_RAW}" > "${TRACE_NORMALIZED}"

echo "Filtering GoogleTest, toolchain, and test sources..."
lcov --remove "${TRACE_NORMALIZED}" \
  '*googletest*' '*gtest_main*' '*msys64*' '*/_deps/*' \
  '*/tests/gtest_main.cpp' '*/tests/mock/*' '*/tests/driverstub/*' \
  '*/test/*' \
  --rc lcov_branch_coverage=1 \
  --output-file "${TRACE_FILTERED}"

echo "Generating HTML report..."
genhtml "${TRACE_FILTERED}" \
  --branch-coverage \
  --output-directory "${HTML_DIR}"

echo ""
echo "Per-file coverage:"
lcov --list "${TRACE_FILTERED}" --rc lcov_branch_coverage=1

echo "Coverage report: ${HTML_DIR}/index.html"
