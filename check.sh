#!/usr/bin/env bash
# One command: re-check the 29 FinalBoss attestation bundles yourself.
#   bash check.sh             fetches Intel's and NVIDIA's current signing material, as VoltageGPU did on 2026-10-28
#   bash check.sh --offline   uses only the Intel and NVIDIA material stored inside each bundle (no network after install)
# Needs: bash, Python 3.10 or newer, and internet once to install voltage-verify from PyPI.
# Writes only inside this folder: .venv/ (the tool) and my_outputs/ (what it printed for each bundle).
set -u
cd "$(dirname "$0")"
MODE=""; [ "${1:-}" = "--offline" ] && MODE="--offline"
VV_VERSION="${VV_VERSION:-0.2.3}"   # the release VoltageGPU used; set VV_VERSION=<newer> to try a later one

if command -v sha256sum >/dev/null 2>&1; then SUM="sha256sum"; else SUM="shasum -a 256"; fi

echo "1/3 fingerprints: every bundle against bundles/SHA256SUMS.txt"
ok_sums=$(cd bundles && $SUM -c SHA256SUMS.txt 2>/dev/null | grep -c ': OK$')
if [ "$ok_sums" != "29" ]; then
  echo "FINGERPRINTS=FAIL ($ok_sums of 29 match)"; (cd bundles && $SUM -c SHA256SUMS.txt 2>&1 | grep -v ': OK$'); echo "CHECK=FAIL"; exit 1
fi
echo "FINGERPRINTS=29/29 OK"

echo "2/3 tool: voltage-verify $VV_VERSION from PyPI (open source, MIT, github.com/VoltageGPU/voltage-verify)"
PY=$(command -v python3 || command -v python) || { echo "CHECK=FAIL (no python3 found)"; exit 1; }
[ -x .venv/bin/voltage-verify ] || { "$PY" -m venv .venv && .venv/bin/pip install -q "voltage-verify==$VV_VERSION"; } || { echo "CHECK=FAIL (could not install voltage-verify $VV_VERSION)"; exit 1; }
echo "    $(.venv/bin/voltage-verify --version 2>&1)"

echo "3/3 verify: voltage-verify verify $MODE <bundle> for each of the 29"
rm -rf my_outputs && mkdir -p my_outputs
verified=0; failed=""
while read -r _ f; do
  name=$(echo "$f" | tr '/' '_' | sed 's/\.json$//')
  .venv/bin/voltage-verify verify $MODE "bundles/$f" > "my_outputs/$name.txt" 2>&1
  if tail -1 "my_outputs/$name.txt" | grep -q '^RESULT: VERIFIED$'; then verified=$((verified+1)); else failed="$failed $f"; fi
done < bundles/SHA256SUMS.txt
echo "VERIFIED=$verified/29 (each tool output is in my_outputs/)"
if [ "$verified" = "29" ]; then echo "CHECK=PASS"; else echo "not verified:$failed"; echo "CHECK=FAIL"; exit 1; fi
