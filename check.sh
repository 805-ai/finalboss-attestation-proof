#!/usr/bin/env bash
# One command: re-check every FinalBoss attestation bundle in this repository yourself.
#   bash check.sh             fetches Intel's and NVIDIA's current signing material, as VoltageGPU did
#   bash check.sh --offline   uses only the Intel and NVIDIA material stored inside each bundle (no network after install)
# Needs: bash, Python 3.10 or newer, and internet once to install voltage-verify from PyPI.
# Writes only inside this folder: .venv/ (the tool) and my_outputs/ (what it printed for each bundle).
set -u
cd "$(dirname "$0")"
MODE=""; [ "${1:-}" = "--offline" ] && MODE="--offline"
VV_VERSION="${VV_VERSION:-0.2.3}"   # the release VoltageGPU used; set VV_VERSION=<newer> to try a later one
SETS="bundles bundles_box4_20261028"   # October 27 runs (29 bundles), October 28 box 4 (4 bundles)
EXPECT=33

if command -v sha256sum >/dev/null 2>&1; then SUM="sha256sum"; else SUM="shasum -a 256"; fi

echo "1/3 fingerprints: every bundle against its folder's SHA256SUMS.txt"
ok_sums=0
for s in $SETS; do
  n=$(cd "$s" && $SUM -c SHA256SUMS.txt 2>/dev/null | grep -c ': OK$')
  t=$(grep -c . "$s/SHA256SUMS.txt")
  echo "    $s: $n of $t match"
  [ "$n" = "$t" ] || { (cd "$s" && $SUM -c SHA256SUMS.txt 2>&1 | grep -v ': OK$'); echo "FINGERPRINTS=FAIL"; echo "CHECK=FAIL"; exit 1; }
  ok_sums=$((ok_sums+n))
done
[ "$ok_sums" = "$EXPECT" ] || { echo "FINGERPRINTS=FAIL ($ok_sums of $EXPECT)"; echo "CHECK=FAIL"; exit 1; }
echo "FINGERPRINTS=$EXPECT/$EXPECT OK"

echo "2/3 tool: voltage-verify $VV_VERSION from PyPI (open source, MIT, github.com/VoltageGPU/voltage-verify)"
PY=$(command -v python3 || command -v python) || { echo "CHECK=FAIL (no python3 found)"; exit 1; }
[ -x .venv/bin/voltage-verify ] || { "$PY" -m venv .venv && .venv/bin/pip install -q "voltage-verify==$VV_VERSION"; } || { echo "CHECK=FAIL (could not install voltage-verify $VV_VERSION)"; exit 1; }
echo "    $(.venv/bin/voltage-verify --version 2>&1)"

echo "3/3 verify: voltage-verify verify $MODE <bundle> for each of the $EXPECT"
rm -rf my_outputs && mkdir -p my_outputs
verified=0; failed=""
for s in $SETS; do
  while read -r _ f; do
    name=$(echo "$s/$f" | tr '/' '_' | sed 's/\.json$//')
    .venv/bin/voltage-verify verify $MODE "$s/$f" > "my_outputs/$name.txt" 2>&1
    if tail -1 "my_outputs/$name.txt" | grep -q '^RESULT: VERIFIED$'; then verified=$((verified+1)); else failed="$failed $s/$f"; fi
  done < "$s/SHA256SUMS.txt"
done
echo "VERIFIED=$verified/$EXPECT (each tool output is in my_outputs/)"
if [ "$verified" = "$EXPECT" ]; then echo "CHECK=PASS"; else echo "not verified:$failed"; echo "CHECK=FAIL"; exit 1; fi
