# OpenUPF Kubernetes Bring-up

This directory captures the cluster-native shape for OpenUPF while preserving
the upstream split architecture:

- SMU runs as a normal control-plane pod.
- FPU runs with one DPDK VF allocated by Kubernetes DRA.
- LBU runs with two DPDK VFs allocated by Kubernetes DRA.

The manifests target the DRA driver already present on the lab cluster:
`linux-net.dra.infinitydon.com`.

## Runtime Contract

OpenUPF expects DPDK PCI addresses indirectly:

- `DPDK_PCIDEVICE` contains a comma-separated list of environment variable names.
- Each named environment variable contains one or more PCI addresses.

The `entrypoint.sh` script converts the DRA-injected
`LINUX_NET_DRA_PCI_ADDRESS_PCI_*` variables into OpenUPF's expected
`UPF_FPU_DEV`, `UPF_LBU_EXT_DEV`, and `UPF_LBU_INT_DEV` variables.

SMU uses `hostNetwork: true` for the N4 interface. FPU and LBU keep normal pod
networking because the DRA/NRI device preparation expects a pod network
namespace. Kubernetes Services expose the SMU and LBU management ports, and the
entrypoint rewrites the upstream `127.0.0.1` management defaults from Service
environment variables at startup.

## Apply Config

From the repository root:

```sh
NAMESPACE=openupf ./deploy/kubernetes/apply-config.sh
kubectl -n openupf create secret docker-registry ghcr-openupf \
  --docker-server=ghcr.io \
  --docker-username=<github-user> \
  --docker-password=<github-token>
kubectl apply -f deploy/kubernetes/openupf-dra.yaml
```

## Current Status

This is a bring-up scaffold. Before using it for traffic, update the source
configs under `config/` so they match the Open5GS SMF, N3, N4, N6, and N9
networks in the target cluster, then re-run `apply-config.sh`.
