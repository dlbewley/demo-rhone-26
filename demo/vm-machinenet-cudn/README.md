# VM with MachineNet ClusterUserDefinedNetwork

This directory contains Kubernetes manifests for deploying a VirtualMachine that uses a ClusterUserDefinedNetwork (CUDN) with Localnet topology.

## Overview

This demo demonstrates how to:
- Create a ClusterUserDefinedNetwork with Localnet topology
- Configure a VirtualMachine to use the CUDN instead of the default pod network
- Connect the VM to a physical network via OVN localnet

## Components

### ClusterUserDefinedNetwork

The `clusteruserdefinednetwork.yaml` defines a CUDN named `machinenet` with:
- **Topology**: Localnet
- **Role**: Secondary
- **Physical Network**: `physnet` (`br-ex`)
- **MTU**: 1500
- **IPAM**: Disabled (uses DHCP from the datacenter)
- **Namespace Selector**: Creates a NetworkAttachmentDefinition in the `default` namespace

### VirtualMachine

The `virtualmachine.yaml` defines a RHEL 9 VM that is patched by kustomization to:
- Use the `machinenet` CUDN via a bridge interface
- Start automatically with `runStrategy: RerunOnFailure`
- Connect to the network using the NetworkAttachmentDefinition created by the CUDN

### Kustomization

The `kustomization.yaml`:
- Sets the namespace to `demo-vm-machinenet`
- Applies patches to convert the default pod network interface to use the machinenet CUDN
- References all required resources

## Deployment

Apply the kustomization:

```bash
kubectl apply -k demo/vm-machinenet-cudn
```

## Network Configuration

The VM will receive its IP address via DHCP from the datacenter network. The physical network name (`physnet`) and MTU should be configured to match your infrastructure.

## Notes

- The CUDN creates a NetworkAttachmentDefinition in the `default` namespace
- The VM interface uses a bridge model for localnet connectivity
- Ensure the physical network configuration matches your datacenter setup

