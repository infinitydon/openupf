#!/usr/bin/env bash
set -euo pipefail

program="${1:?usage: entrypoint.sh <smu|fpu|lbu>}"

export PATH="/opt/upf/bin:${PATH}"
export LD_LIBRARY_PATH="/opt/upf/lib:${LD_LIBRARY_PATH:-}"

prepare_config() {
  local source_config="${1:?source config required}"
  local runtime_config="/tmp/openupf-${program}.ini"

  cp "${source_config}" "${runtime_config}"
  export UPF_RUNCONFIG="${runtime_config}"
}

case "${program}" in
  smu)
    prepare_config "${UPF_RUNCONFIG:-/opt/upf/config/smu/smu_docker.ini}"
    if [[ -n "${OPENUPF_LBU_SERVICE_HOST:-}" ]]; then
      sed -i "s/^lb_ips[[:space:]]*=.*/lb_ips = ${OPENUPF_LBU_SERVICE_HOST}/" "${UPF_RUNCONFIG}"
    fi
    ;;
  fpu)
    prepare_config "${UPF_RUNCONFIG:-/opt/upf/config/${program}/${program}_dpdk_docker.ini}"
    if [[ -n "${OPENUPF_SMU_SERVICE_HOST:-}" ]]; then
      sed -i "s/^mb_ips[[:space:]]*=.*/mb_ips = ${OPENUPF_SMU_SERVICE_HOST}/" "${UPF_RUNCONFIG}"
    fi

    mapfile -t pci_addrs < <(env | awk -F= '/^LINUX_NET_DRA_PCI_ADDRESS_PCI_/ {print $2}' | sort)
    if [[ "${#pci_addrs[@]}" -eq 0 ]]; then
      echo "No DRA PCI devices found in LINUX_NET_DRA_PCI_ADDRESS_PCI_* env vars" >&2
      exit 1
    fi

    export UPF_FPU_DEV="$(IFS=,; echo "${pci_addrs[*]}")"
    export DPDK_PCIDEVICE=UPF_FPU_DEV
    ;;
  lbu)
    prepare_config "${UPF_RUNCONFIG:-/opt/upf/config/lbu/lbu_docker.ini}"

    mapfile -t pci_addrs < <(env | awk -F= '/^LINUX_NET_DRA_PCI_ADDRESS_PCI_/ {print $2}' | sort)
    if [[ "${#pci_addrs[@]}" -lt 2 ]]; then
      echo "LBU requires at least two DPDK devices: external and internal" >&2
      exit 1
    fi

    export UPF_LBU_EXT_DEV="${pci_addrs[0]}"
    export UPF_LBU_INT_DEV="${pci_addrs[1]}"
    export DPDK_PCIDEVICE=UPF_LBU_EXT_DEV,UPF_LBU_INT_DEV
    ;;
  *)
    echo "Unknown OpenUPF program: ${program}" >&2
    exit 1
    ;;
esac

exec "/opt/upf/bin/${program}"
