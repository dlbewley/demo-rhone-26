# VM with VLAN 1924 ClusterUserDefinedNetwork (IPAM Enabled)

This directory contains Kubernetes manifests for deploying a VirtualMachine that uses a ClusterUserDefinedNetwork (CUDN) with Localnet topology, VLAN tagging, and IPAM enabled.

## Overview

This demo demonstrates how to:
- Create a ClusterUserDefinedNetwork with Localnet topology and VLAN access mode
- Enable IPAM (IP Address Management) for automatic IP assignment
    - See https://issues.redhat.com/browse/CNV-64523
- Configure subnet exclusions to reserve IP ranges
- Connect a VirtualMachine to a VLAN-tagged physical network with managed IP addresses

## Components

### ClusterUserDefinedNetwork

The `clusteruserdefinednetwork.yaml` defines a CUDN named `vlan-1924-ipam` with:
- **Topology**: Localnet
- **Role**: Secondary
- **Physical Network**: `physnet-vmdata`
- **VLAN**:
  - Mode: Access
  - ID: 1924
- **IPAM**: Enabled (automatic IP assignment)
- **Subnet**: `192.168.4.0/24`
- **Excluded Subnets** (reserved IP ranges):
  - `192.168.4.0/25` (128 addresses)
  - `192.168.4.128/26` (64 addresses)
  - `192.168.4.240/28` (16 addresses)
- **Namespace Selector**: Creates a NetworkAttachmentDefinition in the `default` namespace

**Note**: This CUDN can only be created by cluster-admin.

### VirtualMachine

The `virtualmachine.yaml` defines a RHEL 9 VM that is patched by kustomization to:
- Use the `vlan-1924-ipam` CUDN via a bridge interface
- Start automatically with `runStrategy: RerunOnFailure`
- Connect to the network using the NetworkAttachmentDefinition created by the CUDN
- Receive an IP address automatically from the available IP pool (excluding the reserved ranges)

### Kustomization

The `kustomization.yaml`:
- Sets the namespace to `demo-vm-machinenet`
- Applies patches to convert the default pod network interface to use the vlan-1924-ipam CUDN
- References all required resources

## Deployment

Apply the kustomization:

```bash
kubectl apply -k demo/vm-1924-cudn-ipam
```

## Network Configuration

The VM will receive an IP address automatically from the `192.168.4.0/24` subnet via IPAM, excluding the reserved ranges:
- Available IP pool: `192.168.4.192/26` through `192.168.4.239` (48 addresses)
- The VM will be connected to VLAN 1924 on the physical network `physnet-vmdata`

## IP Address Management

With IPAM enabled, the CUDN automatically assigns IP addresses from the available pool. The excluded subnets ensure that certain IP ranges are not assigned to pods/VMs, which is useful for:
- Reserving IPs for static assignments
- Avoiding conflicts with existing network infrastructure
- Maintaining IP ranges for specific purposes

## Notes

- The CUDN creates a NetworkAttachmentDefinition in the `default` namespace
- The VM interface uses a bridge model for localnet connectivity
- Ensure the physical network configuration (`physnet-vmdata`) and VLAN 1924 match your infrastructure
- Only cluster-admin can create ClusterUserDefinedNetwork resources
- IP addresses are assigned automatically from the available pool (excluding reserved ranges)

