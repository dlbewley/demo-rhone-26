#!/usr/bin/env bash

# Prereq: demo-magic
# git clone https://github.com/paxtonhare/demo-magic.git ~/src/demos/demo-magic
source ~/src/demos/demo-magic/demo-magic.sh

TYPE_SPEED=100
PROMPT_TIMEOUT=2
DEMO_PROMPT="${CYAN}\W ${GREEN}$ ${COLOR_RESET}"
DEMO_COMMENT_COLOR=$GREEN

GIT_REPO=$(git remote get-url origin)
GIT_ROOT=$(git rev-parse --show-toplevel)
DEMO_ROOT=demo/vm-primary-udn
NAMESPACE=demo-vm-primary-udn
KUBECTL=${KUBECTL:-oc}

RUN_CLEANUP=false

function oc() {
  env KUBECTL_COMMAND=oc kubecolor $@
}

cleanup() {
  oc delete -k "$DEMO_PATH" --ignore-not-found
}

cd $GIT_ROOT

clear
figlet -w 100 'VM Primary UDN' | lolcat -p 1

DEMO_PROMPT='' p "# 🎬 Demo: VM with Primary UDN (Layer2)\n#  📦 Repo: $GIT_REPO\n#  📁 Path: $DEMO_ROOT\n"

p "# 📋 Show demo contents"
pei "tree -L 1 $DEMO_ROOT"
p

cd $GIT_ROOT/$DEMO_ROOT
p "# 🏷️  The Namespace must be labeled for a Primary UDN **at creation time**"
pei "bat -n -H 8 namespace.yaml"
p

p "# 🌐 Primary Layer2 UserDefinedNetwork definition"
pei "bat -n -H 8 -H 12 userdefinednetwork.yaml"
p

p "# 💻 VirtualMachine will use masquerade binding by default"
pei "yq '.spec.template.spec.domain.devices.interfaces' < virtualmachine.yaml | bat -l yaml -n -H 14"
p

p "# 🔍 The VirtualMachine will be patched to use l2bridge binding instead"
pei "oc kustomize . | kfilt -k VirtualMachine | yq '.spec.template.spec.domain.devices.interfaces' | bat -l yaml -n"
p

figlet -w 100 'Deploy' | lolcat -p 1
p "# ▶️ Apply the demo"
pei "oc apply -k ."
p

p "# ✔️ Verify namespace label"
pei "oc describe namespace $NAMESPACE"
p

p "# ✔️ Verify the UDN"
pei "oc describe userdefinednetwork -n $NAMESPACE"
p

p "# ⏳ Wait for the VirtualMachine to be ready"
pei "oc wait vm/vm-primary-udn --for=jsonpath='{.status.ready}'=true --timeout=180s"
p

POD_NAME=$(oc get pod -o name -l vm.kubevirt.io/name=vm-primary-udn -n $NAMESPACE)
p "# 👀 The Pod has an IP on the infrastructure locked network for health checks"
pei "oc get pods -n $NAMESPACE -o wide"
p
p "# 👀 Pod has an IP the primary UDN 10.1.1.0/24 which is 'down'"
pei "oc -n demo-vm-primary-udn rsh $POD_NAME ip -br -c -4 a"
p
p "# 🔗 the int is bound to k6t-ovn-udn1 bridge along with tap0"
pei "oc -n demo-vm-primary-udn rsh $POD_NAME ip -c link"

p "# which is passed to QEMU to become the VM eth0"
pei "oc -n $NAMESPACE rsh $POD_NAME virsh dumpxml 1 | grep -A 8 ethernet 2>/dev/null"
p
p "# 👀 The VirtualMachine has an IP on the UDN 10.1.1.0/24"
pei "oc get vmi -n $NAMESPACE -o wide"
p

NODE_NAME=$(oc get pod -o jsonpath='{.items[0].spec.nodeName}' -l vm.kubevirt.io/name=vm-primary-udn -n $NAMESPACE)

p "# 👀 Every node has the same IP on the layer2 UDN"
pei "oc debug node/$NODE_NAME -- ip -br -4 -c a 2>/dev/null"
p
p

clear
figlet -w 100 'OVN' | lolcat -p 1
DOTTED_NAMESPACE=$(echo $NAMESPACE | sed 's/-/./g')
p "# 🛜 OVN creates a layer2 switch named after the namespace and the UDN"
pei "ovncli $NODE_NAME ovn-nbctl ls-list | grep ${DOTTED_NAMESPACE}"
p "# 🛜 And a gateway router is created to exit the UDN"
pei "ovncli $NODE_NAME ovn-nbctl lr-list"
p "# 🛜 The UDN gateway router defines NAT to egress the UDN"
pei "ovncli $NODE_NAME ovn-nbctl show GR_${DOTTED_NAMESPACE}_primary.udn_${NODE_NAME}"
p
clear
#p "# 🛜 And the node gateway router defines the second NAT to egress the node"
#pei "ovncli $NODE_NAME ovn-nbctl show GR_${NODE_NAME}"


p "# 🧹 Cleanup"
if [[ "${RUN_CLEANUP:-false}" == "true" ]]; then
  pei "oc delete -k . --ignore-not-found"
fi
