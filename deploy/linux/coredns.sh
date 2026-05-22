#!/usr/bin/env bash
set -euo pipefail

COREDNS_BIN="${COREDNS_BIN:-/usr/local/bin/coredns}"
COREFILE="${COREFILE:-/etc/coredns/Corefile}"
COREDNS_WORKDIR="${COREDNS_WORKDIR:-/var/lib/coredns}"
COREDNS_ARGS="${COREDNS_ARGS:-}"

if [[ ! -x "${COREDNS_BIN}" ]]; then
    echo "coredns binary not executable: ${COREDNS_BIN}" >&2
    exit 1
fi

if [[ ! -f "${COREFILE}" ]]; then
    echo "Corefile not found: ${COREFILE}" >&2
    exit 1
fi

mkdir -p "${COREDNS_WORKDIR}"
cd "${COREDNS_WORKDIR}"

if [[ -n "${COREDNS_ARGS}" ]]; then
    # Intentional word splitting so system administrators can pass multiple flags.
    # shellcheck disable=SC2206
    extra_args=( ${COREDNS_ARGS} )
else
    extra_args=()
fi

exec "${COREDNS_BIN}" -conf "${COREFILE}" "${extra_args[@]}"
