# VM with Primary UserDefinedNetwork

This directory contains Kubernetes manifests for deploying a VirtualMachine that uses a Primary UserDefinedNetwork (UDN) with Layer2 topology.

## Overview

This demo demonstrates how to:
- Create a UserDefinedNetwork with Layer2 topology and Primary role
- Configure a VirtualMachine to use the Primary UDN as its default network
- Set up a namespace-scoped network that becomes the default route for pods in that namespace

## Components

### UserDefinedNetwork

The `userdefinednetwork.yaml` defines a UDN named `primary-udn` with:
- **Topology**: Layer2
- **Role**: Primary (becomes the default route for pods in the namespace)
- **Subnet**: `10.1.1.0/24`
- **IPAM Lifecycle**: Persistent

**Note**: Only one Primary UDN per namespace is allowed.

### VirtualMachine

The `virtualmachine.yaml` defines a RHEL 9 VM that is patched by kustomization to:
- Use the `primary-udn` UDN via an l2bridge binding
- Start automatically with `runStrategy: RerunOnFailure`
- Connect to the network using the namespace-scoped UDN

### Namespace

The `namespace.yaml` creates the `demo-vm-primary-udn` namespace with:
- **Required Label**: `k8s.ovn.org/primary-user-defined-network: ""` (must be set at namespace creation when hosting a primary UDN)

### Kustomization

The `kustomization.yaml`:
- Sets the namespace to `demo-vm-primary-udn`
- Applies patches to convert the default pod network interface to use the primary UDN with l2bridge binding
- References all required resources

## Deployment

Apply the kustomization:

```bash
kubectl apply -k demo/vm-primary-udn
```

## Network Configuration

The VM will receive an IP address from the `10.1.1.0/24` subnet via the Primary UDN's IPAM. The Primary UDN serves as the default route for all pods in the namespace.

## Notes

- The namespace label `k8s.ovn.org/primary-user-defined-network: ""` must be present at namespace creation
- Only one Primary UDN is allowed per namespace
- The VM interface uses l2bridge binding for Layer2 connectivity
- IP addresses are managed with Persistent lifecycle, meaning they persist across pod restarts

