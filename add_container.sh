#!/bin/bash

set -e

update_outputs() {
python3 - <<'PYEOF'
import re

with open('main.tf') as f:
    content = f.read()

# Extraire les locals pour résoudre les références d'IP
local_ips = {}
locals_m = re.search(r'locals\s*\{([^}]+)\}', content)
if locals_m:
    for m in re.finditer(r'(\w+)\s*=\s*"\$\{var\.network_prefix\}\.(\d+)"', locals_m.group(1)):
        local_ips[m.group(1)] = m.group(2)

containers = []
for match in re.finditer(r'resource "proxmox_virtual_environment_container" "(\w+)" \{', content):
    name = match.group(1)
    pos  = match.start()
    depth, block_end = 0, pos
    for i, c in enumerate(content[pos:]):
        if c == '{': depth += 1
        elif c == '}':
            depth -= 1
            if depth == 0:
                block_end = pos + i
                break
    block = content[pos:block_end + 1]

    node_m = re.search(r'node_name\s*=\s*"([^"]+)"', block)
    vmid_m = re.search(r'vm_id\s*=\s*(\d+)', block)
    ip_m   = re.search(r'address\s*=\s*"([^"]+)"', block)

    node = node_m.group(1) if node_m else 'unknown'
    vmid = vmid_m.group(1) if vmid_m else '0'
    ip   = f'10.20.10.{vmid}'
    if ip_m:
        raw = ip_m.group(1).replace('/24', '')
        local_ref = re.search(r'\$\{local\.(\w+)\}', raw)
        if local_ref:
            octet = local_ips.get(local_ref.group(1), vmid)
            ip = f'10.20.10.{octet}'
        elif re.match(r'\d+\.\d+\.\d+\.\d+', raw):
            ip = raw

    containers.append({'resource': name, 'label': name.replace('_', '-'), 'node': node, 'vmid': vmid, 'ip': ip})

out = []
out.append('output "container_ids" {')
out.append('  description = "IDs Proxmox de tous les containers créés"')
out.append('  value = {')
for c in containers:
    out.append(f'    "{c["label"]}" = proxmox_virtual_environment_container.{c["resource"]}.vm_id')
out.append('  }')
out.append('}')
out.append('')
out.append('output "infrastructure_summary" {')
out.append('  description = "Résumé de l\'infrastructure déployée"')
out.append('  value = {')
for c in containers:
    out.append(f'    "{c["label"]}" = "{c["ip"]} (node: {c["node"]}, vmid: {c["vmid"]})"')
out.append('  }')
out.append('}')
out.append('')

with open('outputs.tf', 'w') as f:
    f.write('\n'.join(out))

print(f"outputs.tf mis à jour — {len(containers)} container(s) : {', '.join(c['label'] for c in containers)}")
PYEOF
}

add_container() {
  local NAME="$1"
  local IP="$2"
  local NODE="$3"
  local TAGS="$4"

  local VMID
  VMID=$(echo "$IP" | cut -d'.' -f4)
  local RESOURCE_NAME
  RESOURCE_NAME=$(echo "$NAME" | tr '-' '_')

  if grep -q "vm_id.*=.*$VMID" main.tf; then
    echo "Erreur : vm_id $VMID (issu de l'IP $IP) est déjà utilisé dans main.tf."
    exit 1
  fi

  if grep -q "\"$RESOURCE_NAME\"" main.tf; then
    echo "Erreur : un container nommé '$NAME' existe déjà dans main.tf."
    exit 1
  fi

  cat >> main.tf <<EOF

# $NAME sur $NODE
resource "proxmox_virtual_environment_container" "$RESOURCE_NAME" {
  description   = "$NAME"
  node_name     = "$NODE"
  vm_id         = $VMID
  tags          = [$TAGS]
  start_on_boot = true

  initialization {
    hostname = "$NAME"

    ip_config {
      ipv4 {
        address = "$IP/24"
        gateway = var.network_gateway
      }
    }

    user_account {
      keys     = [var.ssh_public_key]
      password = var.root_password
    }
  }

  network_interface {
    name   = "eth0"
    bridge = var.network_bridge
  }

  operating_system {
    template_file_id = var.lxc_template
    type             = "debian"
  }

  cpu {
    cores = 1
  }

  memory {
    dedicated = 512
  }

  disk {
    datastore_id = var.storage
    size         = 8
  }
}
EOF

  echo "  -> $NAME | IP: $IP | node: $NODE | vmid: $VMID"
}

# ─── Menu principal ───────────────────────────────────────────────────────────
echo ""
echo "1) Ajouter un seul container"
echo "2) Ajouter deux containers en load balancing"
echo ""
read -p "Choix (1 ou 2) : " CHOIX

if [[ "$CHOIX" == "1" ]]; then

  read -p "Nom du container (ex: db-1)  : " NAME
  read -p "IP (ex: 10.20.10.203)        : " IP
  read -p "Node (pve1 ou pve2)          : " NODE

  if [[ -z "$NAME" || -z "$IP" || -z "$NODE" ]]; then
    echo "Erreur : tous les champs sont requis."
    exit 1
  fi
  if [[ "$NODE" != "pve1" && "$NODE" != "pve2" ]]; then
    echo "Erreur : le node doit être pve1 ou pve2."
    exit 1
  fi

  echo ""
  add_container "$NAME" "$IP" "$NODE" '"terraform"'

elif [[ "$CHOIX" == "2" ]]; then

  read -p "Nom web-1 (ex: nginx-1)      : " NAME1
  read -p "IP web-1 (ex: 10.20.10.203) : " IP1
  read -p "Node web-1 (pve1 ou pve2)   : " NODE1
  read -p "Nom web-2 (ex: nginx-2)      : " NAME2
  read -p "IP web-2 (ex: 10.20.10.204) : " IP2
  read -p "Node web-2 (pve1 ou pve2)   : " NODE2

  if [[ -z "$NAME1" || -z "$IP1" || -z "$NODE1" || -z "$NAME2" || -z "$IP2" || -z "$NODE2" ]]; then
    echo "Erreur : tous les champs sont requis."
    exit 1
  fi
  for NODE in "$NODE1" "$NODE2"; do
    if [[ "$NODE" != "pve1" && "$NODE" != "pve2" ]]; then
      echo "Erreur : le node doit être pve1 ou pve2."
      exit 1
    fi
  done

  echo ""
  add_container "$NAME1" "$IP1" "$NODE1" '"web", "terraform"'
  add_container "$NAME2" "$IP2" "$NODE2" '"web", "terraform"'

else
  echo "Erreur : choix invalide."
  exit 1
fi

echo ""
update_outputs
echo "Lance 'terraform apply' pour déployer."
