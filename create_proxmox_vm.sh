#!/bin/bash
# ============ Create Proxmox VM after Terraform apply ============
# Usage: ./create_proxmox_vm.sh
# Requirements: curl, jq, SSH key to Proxmox host

set -e

# ===== Configuration =====
PROXMOX_HOST="${PROXMOX_HOST:-172.199.10.165}"
PROXMOX_API_TOKEN="${PROXMOX_API_TOKEN:?Error: PROXMOX_API_TOKEN not set}"
PROXMOX_NODE="${PROXMOX_NODE:-proxmox02}"
TEMPLATE_VM_ID=9999
NEW_VM_ID=1100
NEW_VM_NAME="project-automation-db"
NEW_VM_IP="172.199.10.180"
NEW_VM_CIDR="24"
NEW_VM_GW="172.199.10.1"

# ===== Functions =====
log() {
  echo "[$(date +'%Y-%m-%d %H:%M:%S')] $1"
}

api_call() {
  local method=$1
  local endpoint=$2
  local data=$3

  local cmd="curl -sk -X $method \
    -H 'Authorization: PVEAPIToken=$PROXMOX_API_TOKEN' \
    -H 'Content-Type: application/json' \
    https://$PROXMOX_HOST:8006$endpoint"

  if [ -n "$data" ]; then
    cmd="$cmd -d '$data'"
  fi

  eval "$cmd"
}

# ===== Main =====
log "Starting Proxmox VM creation..."

# Step 1: Clone VM
log "Step 1/4: Cloning VM $TEMPLATE_VM_ID → $NEW_VM_ID"
clone_response=$(api_call POST "/api2/json/nodes/$PROXMOX_NODE/qemu/$TEMPLATE_VM_ID/clone" \
  "{\"newid\":$NEW_VM_ID,\"name\":\"$NEW_VM_NAME\",\"full\":1}")
log "Clone response: $clone_response"

# Wait for clone to complete
log "Waiting for clone to complete..."
for i in {1..30}; do
  status=$(api_call GET "/api2/json/nodes/$PROXMOX_NODE/qemu/$NEW_VM_ID/status/current" | jq -r '.data.status // "unknown"')
  if [ "$status" != "unknown" ]; then
    log "VM status: $status"
    break
  fi
  log "Attempt $i/30... waiting for VM to appear"
  sleep 2
done

# Step 2: Configure cloud-init
log "Step 2/4: Configuring cloud-init"
api_call PUT "/api2/json/nodes/$PROXMOX_NODE/qemu/$NEW_VM_ID/config" \
  "{\"cicustom\":\"local:snippets/project-automation-ci.yml\"}" > /dev/null
log "Cloud-init configured"

# Step 3: Set IP configuration
log "Step 3/4: Setting IP configuration"
api_call PUT "/api2/json/nodes/$PROXMOX_NODE/qemu/$NEW_VM_ID/config" \
  "{\"ipconfig0\":\"ip=$NEW_VM_IP/$NEW_VM_CIDR,gw=$NEW_VM_GW\"}" > /dev/null
log "IP configuration set to $NEW_VM_IP/$NEW_VM_CIDR"

# Step 4: Start VM
log "Step 4/4: Starting VM"
api_call POST "/api2/json/nodes/$PROXMOX_NODE/qemu/$NEW_VM_ID/status/start" "" > /dev/null
log "VM started!"

log "✅ Proxmox VM creation complete!"
log "   VM ID: $NEW_VM_ID"
log "   VM Name: $NEW_VM_NAME"
log "   VM IP: $NEW_VM_IP"
log ""
log "Waiting 30 seconds for VM to fully boot..."
sleep 30

log "VM is ready! You can now run Ansible playbooks:"
log "   ansible-playbook -i inventory.yml ansible/site.yml"
