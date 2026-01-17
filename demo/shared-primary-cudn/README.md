# VM with Primary ClusterUserDefinedNetwork

This directory contains Kubernetes manifests for deploying VirtualMachines that share a Primary ClusterUserDefinedNetwork (CUDN) across multiple namespaces in the Engineering department.

This enables communication between teams within the department, but isolates them from any other workloads outside of their department's namespaces.

## Overview

This demo demonstrates how the Engineering department shares a single network among multiple teams (frontend and backend) using a ClusterUserDefinedNetwork with Layer2 topology and Primary role. The CUDN uses namespace label selectors to automatically include all namespaces belonging to the Engineering department.

This demo shows how to:
- Create a ClusterUserDefinedNetwork that spans multiple namespaces using label selectors
- Configure VirtualMachines in different namespaces to share the same network
- Use Kustomize overlays to deploy team-specific VMs while sharing the base network configuration
- Set up a department-wide network that becomes the default route for pods in all matching namespaces

## Architecture

The Engineering department uses a shared network (`engineering` CUDN) that is automatically available to all namespaces labeled with `bewley.net/dept: engineering`. This allows:

- **Frontend Team**: Deploys VMs in the `demo-engr-frontend` namespace
- **Backend Team**: Deploys VMs in the `demo-engr-backend` namespace
- **Shared Network**: Both teams share the same Layer2 network segment (`10.10.240.0/23`)

## Components

### ClusterUserDefinedNetwork

The `base/clusteruserdefinednetwork.yaml` defines a CUDN named `engineering` with:
- **Topology**: Layer2
- **Role**: Primary (becomes the default route for pods in matching namespaces)
- **Subnet**: `10.10.240.0/23`
- **IPAM Lifecycle**: Persistent
- **Namespace Selector**: Matches namespaces with label `bewley.net/dept: engineering`

**Note**: Only one _Primary_ CUDN per namespace is allowed. The namespace selector ensures all Engineering namespaces automatically use this network.

### Base Configuration

The `base/` directory contains:
- The `engineering` ClusterUserDefinedNetwork
- A VirtualMachine template that can be customized per team
- Kustomization patches that configure the VM to use the CUDN via l2bridge binding

### Team Overlays

The `overlays/` directory contains team-specific configurations:

#### Frontend Overlay (`overlays/frontend/`)
- Namespace: `demo-engr-frontend`
- Labels: `bewley.net/dept: engineering`, `bewley.net/team: frontend`
- VM Name: `frontend`

#### Backend Overlay (`overlays/backend/`)
- Namespace: `demo-engr-backend`
- Labels: `bewley.net/dept: engineering`, `bewley.net/team: backend`
- VM Name: `backend`

Both overlays:
- Reference the base configuration
- Create their respective namespaces with the required labels
- Patch the VM name to be team-specific
- Automatically inherit the `engineering` CUDN through the namespace selector

## Deployment

### Deploy Both Teams

Deploy the frontend and backend teams:

```bash
# Deploy Frontend team
oc apply -k demo/vm-primary-cudn/overlays/frontend

# Deploy Backend team
oc apply -k demo/vm-primary-cudn/overlays/backend
```

### Verify Deployment

Check that the CUDN is available and both teams are connected:

```bash
# Check the CUDN
oc describe clusteruserdefinednetwork engineering

# List the matched namespaces in Engineering dept
oc get namespaces -l bewley.net/dept=engineering

# Check Frontend team namespace and VM
oc get vmi -n demo-engr-frontend -o wide

# Check Backend team namespace and VM
oc describe namespace demo-engr-backend
oc get vmi -n demo-engr-backend -o wide
```

## Network Configuration

Both the frontend and backend VMs will receive IP addresses from the shared `10.10.240.0/23` subnet via the `engineering` CUDN's IPAM. The CUDN serves as the default route for all pods in both namespaces, enabling direct Layer2 communication between teams.

### Network Isolation

While both teams share the same network segment, they are isolated at the namespace level:
- Each team has its own namespace
- VMs can communicate at Layer2 within the shared subnet
- Kubernetes RBAC can be applied per namespace for additional resource isolation if needed

## Cleanup

> [!IMPORTANT]
> Namespace deletion will be blocked so long as the CUDN is selecting it.
> <https://issues.redhat.com/browse/OCPBUGS-61463>

Edit the CUDN and remove label selector

```bash
oc edit clusteruserdefinednetwork engineering
```

Remove the deployments:

```bash
# Remove frontend team
oc delete -k demo/vm-primary-cudn/overlays/frontend

# Remove backend team
oc delete -k demo/vm-primary-cudn/overlays/backend

# Remove the CUDN (if no other namespaces are using it)
oc delete -k demo/vm-primary-cudn/base
```

## Notes

- The namespace label `k8s.ovn.org/primary-user-defined-network: ""` must be present at namespace creation for namespaces hosting a primary CUDN
- The namespace label `bewley.net/dept: engineering` is required for the CUDN's namespace selector to match
- Only one Primary CUDN is allowed per namespace
- The VM interfaces use l2bridge binding for Layer2 connectivity
- IP addresses are managed with Persistent lifecycle, meaning they persist across pod restarts
- The CUDN automatically includes any namespace with the matching label, making it easy to add new teams to the shared network
