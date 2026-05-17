#!/bin/bash
# Fonctions partagées entre tous les scripts

# Se placer à la racine du projet (proxmox-infra/)
cd "$(dirname "$0")/.."

ANSIBLE_INVENTORY="../../ansible/inventory/hosts.yml"

# ── Ajouter un bloc resource dans main.tf ────────────────────────────────────
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

# ── Supprimer un bloc resource de main.tf ────────────────────────────────────
remove_container() {
  local RESOURCE_NAME="$1"

python3 - <<PYEOF
name = "$RESOURCE_NAME"

with open('main.tf', 'r') as f:
    lines = f.readlines()

start = -1
for i, line in enumerate(lines):
    if f'"proxmox_virtual_environment_container" "{name}"' in line:
        start = i - 1 if i > 0 and lines[i-1].strip().startswith('#') else i
        break

if start == -1:
    print(f"Erreur : '{name}' non trouvé dans main.tf")
    exit(1)

depth = 0
end = start
for i in range(start, len(lines)):
    depth += lines[i].count('{') - lines[i].count('}')
    if depth == 0 and i > start:
        end = i
        break

del lines[start:end+1]

with open('main.tf', 'w') as f:
    f.writelines(lines)

print(f"Container '{name}' supprimé de main.tf.")
PYEOF
}

# ── Régénérer outputs.tf ─────────────────────────────────────────────────────
update_outputs() {
python3 - <<'PYEOF'
import re

with open('main.tf') as f:
    content = f.read()

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

# ── Ajouter un host dans l'inventaire Ansible ────────────────────────────────
add_to_ansible() {
  local NAME="$1"
  local IP="$2"
  local GROUP="$3"

python3 - <<PYEOF
import yaml

name  = "$NAME"
ip    = "$IP"
group = "$GROUP"
path  = "$ANSIBLE_INVENTORY"

with open(path) as f:
    inv = yaml.safe_load(f)

inv['all']['children'].setdefault(group, {}).setdefault('hosts', {})[name] = {'ansible_host': ip}

with open(path, 'w') as f:
    yaml.dump(inv, f, default_flow_style=False, allow_unicode=True)

print(f"  -> {name} ajouté au groupe '{group}' dans hosts.yml")
PYEOF
}

# ── Supprimer un host de l'inventaire Ansible ─────────────────────────────────
remove_from_ansible() {
  local NAME="$1"

python3 - <<PYEOF
import yaml

name = "$NAME"
path = "$ANSIBLE_INVENTORY"

with open(path) as f:
    inv = yaml.safe_load(f)

for group in inv['all'].get('children', {}).values():
    if name in group.get('hosts', {}):
        del group['hosts'][name]
        break

with open(path, 'w') as f:
    yaml.dump(inv, f, default_flow_style=False, allow_unicode=True)

print(f"  -> {name} supprimé de hosts.yml")
PYEOF
}

# ── Prochaine IP disponible ───────────────────────────────────────────────────
next_ip() {
  local OFFSET="${1:-1}"
  python3 -c "
import re
with open('main.tf') as f:
    content = f.read()
vmids = [int(x) for x in re.findall(r'vm_id\s*=\s*(\d+)', content)]
print(f'10.20.10.{max(vmids) + $OFFSET}' if vmids else '10.20.10.200')
"
}

# ── Lister les containers dans main.tf ───────────────────────────────────────
list_containers() {
  python3 -c "
import re
with open('main.tf') as f:
    content = f.read()
names = re.findall(r'resource \"proxmox_virtual_environment_container\" \"([^\"]+)\"', content)
print('\n'.join(names))
"
}

# ── Validation node ──────────────────────────────────────────────────────────
validate_node() {
  local NODE="$1"
  if [[ "$NODE" != "pve1" && "$NODE" != "pve2" ]]; then
    echo "Erreur : le node doit être pve1 ou pve2."
    exit 1
  fi
}
