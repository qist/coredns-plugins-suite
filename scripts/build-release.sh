#!/usr/bin/env bash
set -euo pipefail

if [[ $# -ne 2 ]]; then
    echo "usage: $0 <coredns-tag> <output-dir>" >&2
    exit 1
fi

COREDNS_TAG="$1"
OUTPUT_DIR="$2"
WORKDIR="$(mktemp -d)"

cleanup() {
    rm -rf "${WORKDIR}"
}
trap cleanup EXIT

log() {
    printf '[build-release] %s\n' "$*"
}

ensure_line_after() {
    local file_path="$1"
    local anchor="$2"
    local new_line="$3"

    python3 - "$file_path" "$anchor" "$new_line" <<'PY'
from pathlib import Path
import sys

file_path = Path(sys.argv[1])
anchor = sys.argv[2]
new_line = sys.argv[3]

lines = file_path.read_text().splitlines()
if new_line not in lines:
    index = lines.index(anchor) + 1
    lines.insert(index, new_line)
    file_path.write_text("\n".join(lines) + "\n")
PY
}

log "cloning CoreDNS ${COREDNS_TAG}"
git clone --depth 1 --branch "${COREDNS_TAG}" https://github.com/coredns/coredns.git "${WORKDIR}/coredns"

log "cloning extra plugins"
git clone --depth 1 https://github.com/qist/hostlist.git "${WORKDIR}/coredns/plugin/hostlist"
git clone --depth 1 https://github.com/qist/speedcheck.git "${WORKDIR}/coredns/plugin/speedcheck"
git clone --depth 1 https://github.com/qist/resolve.git "${WORKDIR}/coredns/plugin/resolve"

cd "${WORKDIR}/coredns"

log "applying resolve patch"
git apply --3way plugin/resolve/server_https.patch

log "injecting hostlist and speedcheck into plugin.cfg"
ensure_line_after "plugin.cfg" "tsig:tsig" "hostlist:hostlist"
ensure_line_after "plugin.cfg" "cache:cache" "speedcheck:speedcheck"

log "plugin order summary"
grep -nE 'edns0:resolve|resolve:resolve|hostlist:hostlist|speedcheck:speedcheck' plugin.cfg

log "running go generate coredns.go"
go generate coredns.go

log "building release assets with CoreDNS Makefile.release"
make -f Makefile.release release

mkdir -p "${OUTPUT_DIR}"
cp -f release/* "${OUTPUT_DIR}/"

log "release assets copied to ${OUTPUT_DIR}"
