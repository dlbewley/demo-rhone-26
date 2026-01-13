# Repository Guidelines

## Project Structure & Module Organization
- `components/` holds reusable Kustomize building blocks (e.g., `components/physnet-mapping/`, `components/vm/`) with `kustomization.yaml` and related manifests.
- `demo/` contains end-to-end scenarios with per-demo `README.md` files and manifests (e.g., `demo/vm-vlan-cudn/`, `demo/bgp/`).
- `networking/` provides base and overlay Kustomize configuration (e.g., `networking/base/`, `networking/overlays/homelab/`).
- `README.md` documents the networking concepts and diagrams for the repository.

## Build, Test, and Development Commands
This repo is configuration-focused; there is no build system. Use Kustomize and kubectl/oc directly:
- `kustomize build components/physnet-mapping` renders manifests for a component.
- `kubectl apply -k demo/vm-vlan-cudn` applies a demo scenario to a cluster.
- `kubectl delete -k demo/vm-vlan-cudn` removes a demo scenario.

## Coding Style & Naming Conventions
- YAML is the primary format; keep indentation at 2 spaces.
- Prefer descriptive, kebab-case directory names matching the network or demo intent (e.g., `vm-primary-udn`, `localnet-1926-cudn`).
- Keep Kustomize files named `kustomization.yaml` and resource manifests named by kind or purpose (e.g., `clusteruserdefinednetwork.yaml`, `virtualmachine.yaml`).

## Testing Guidelines
- No automated test framework is present. Validate changes by rendering and applying manifests:
  - `kustomize build demo/vm-primary-udn` to spot YAML errors.
  - `kubectl apply -k demo/vm-primary-udn` in a non-production cluster.

## Commit & Pull Request Guidelines
- Commit messages in history are short, imperative, and sometimes prefixed (e.g., `fix:`). Follow that pattern (e.g., `Add VLAN 1926 CUDN manifests`).
- If you reference issues or PRs, use the existing style of including a suffix like `(#2)`.
- PRs should include a clear description, the scenario affected (path under `demo/` or `components/`), and how you validated changes (render/apply commands).

## Configuration Tips
- These manifests target OpenShift networking features (CUDN, UDN, and localnet mappings). Check cluster version compatibility before applying.
- Keep demo-specific namespaces in `demo/*/namespace.yaml` to avoid clashes.
