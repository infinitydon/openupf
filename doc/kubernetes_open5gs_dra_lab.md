# Kubernetes Open5GS DRA Lab Notes

This branch contains the changes used to bring OpenUPF up with Open5GS core
NFs on Kubernetes using DRA networking.

## Tested Topology

Open5GS provided NRF, AUSF, UDM, UDR, PCF, NSSF, AMF, and SMF. The Open5GS UPF
was disabled and replaced by OpenUPF:

- SMU: PFCP/N4 endpoint toward Open5GS SMF and backend manager for FPUs
- LBU: DPDK packet I/O for N3/N6 and backend selection toward FPUs
- FPU: DPDK worker that performs session-aware UPF forwarding

The stable lab topology used kernel DRA macvlan on the virtio parent interface
for Open5GS core, gNB, data, and SMU N4. OpenUPF LBU/FPU DPDK ports used Intel
`iavf` VFs. Keeping kernel DRA and DPDK VFs on separate NIC paths avoided the
duplicate downlink replies seen when both paths shared the same Intel PF.

## Address Plan

| Interface | Subnet | Endpoint |
| --- | --- | --- |
| N3 | `10.60.0.16/28` | LBU `10.60.0.18`, gNB `10.60.0.26` |
| N4 | `10.60.0.32/28` | SMF `10.60.0.34`, SMU `10.60.0.35` |
| N6 | `10.60.0.48/28` | LBU `10.60.0.50`, data `10.60.0.60` |

## Validation Result

After adding a second FPU, SMU reported two active backend workers:

```text
backend: 255 2 Active: 2
```

The initial implementation still sent traffic only to the first FPU because
backend index `0` was used both as the invalid hash-table value and as the
first valid backend index. This branch reserves backend index `0` and starts
real FPU allocation at index `1`.

With that fix, a 10-UE UERANSIM run established 10 PDU sessions. Per-tunnel
ping succeeded apart from a first-tunnel warmup miss, 5 Mbit/s UDP iperf per
tunnel completed with 0% loss, and both FPUs showed non-zero `UP_RECV` and
`UP_FWD` counters.

## Companion Helm Chart

The companion chart work is in:

```text
https://github.com/infinitydon/telco-helm-charts/tree/main/open5gs-openupf-dra
```

Use the chart's `values.yaml` as the tested Open5GS plus OpenUPF profile and
adjust the node selector, service ClusterIPs, and DPDK VF PCI addresses for the
target lab.
