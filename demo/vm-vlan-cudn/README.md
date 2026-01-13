# VM with VLAN 1926 ClusterUserDefinedNetwork

This directory contains Kubernetes manifests for deploying a VirtualMachine that uses a ClusterUserDefinedNetwork (CUDN) with Localnet topology and VLAN tagging.

## Overview

This demo demonstrates how to:
- Create a ClusterUserDefinedNetwork with Localnet topology and VLAN access mode
- Use DHCP for IP address assignment (IPAM disabled)
- Connect a VirtualMachine to a VLAN-tagged physical network

## Components

### ClusterUserDefinedNetwork

The `clusteruserdefinednetwork.yaml` defines a CUDN named `localnet-1926` with:
- **Topology**: Localnet
- **Role**: Secondary
- **Physical Network**: `physnet-vmdata`
- **VLAN**:
  - Mode: Access
  - ID: 1926
- **IPAM**: Disabled (uses DHCP from the datacenter)
  - See https://issues.redhat.com/browse/CNV-64523
- **Namespace Selector**: Creates a NetworkAttachmentDefinition in the `default` namespace

**Note**: This CUDN can only be created by cluster-admin.

### VirtualMachine

The `virtualmachine.yaml` defines a RHEL 9 VM that is patched by kustomization to:
- Use the `localnet-1926` CUDN via a bridge interface
- Start automatically with `runStrategy: RerunOnFailure`
- Connect to the network using the NetworkAttachmentDefinition created by the CUDN
- Receive an IP address via DHCP from the datacenter

### Kustomization

The `kustomization.yaml`:
- Sets the namespace to `demo-vm-vlan`
- Applies patches to convert the default pod network interface to use the localnet-1926 CUDN
- References all required resources

## Deployment

Apply the kustomization:

```bash
kubectl apply -k demo/vm-vlan-cudn
```

## Network Configuration

The VM will receive its IP address via DHCP from the datacenter network. The VM will be connected to VLAN 1926 on the physical network `physnet-vmdata`.

## Notes

- The CUDN creates a NetworkAttachmentDefinition in the `default` namespace
- The VM interface uses a bridge model for localnet connectivity
- Ensure the physical network configuration (`physnet-vmdata`) and VLAN 1926 match your infrastructure
- Only cluster-admin can create ClusterUserDefinedNetwork resources
- IP addresses are assigned via DHCP from the datacenter (IPAM is disabled)
