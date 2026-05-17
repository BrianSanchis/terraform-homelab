#!/bin/bash

set -e

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

# Lister les containers dans main.tf
CONTAINERS=$(python3 -c "
import re
with open('main.tf') as f:
    content = f.read()
names = re.findall(r'resource \"proxmox_virtual_environment_container\" \"([^\"]+)\"', content)
print('\n'.join(names))
")

if [[ -z "$CONTAINERS" ]]; then
  echo "Aucun container trouvé dans main.tf."
  exit 1
fi

echo ""
echo "Containers disponibles :"
echo ""
i=1
declare -a LIST
while IFS= read -r name; do
  echo "  $i) $name"
  LIST+=("$name")
  ((i++))
done <<< "$CONTAINERS"

echo ""
read -p "Numéro du container à supprimer : " CHOIX

if ! [[ "$CHOIX" =~ ^[0-9]+$ ]]; then
  echo "Erreur : entrez un numéro, pas un nom."
  exit 1
fi

RESOURCE_NAME="${LIST[$((CHOIX-1))]}"

if [[ -z "$RESOURCE_NAME" ]]; then
  echo "Erreur : numéro hors limites (1-${#LIST[@]})."
  exit 1
fi

# Supprimer le bloc resource dans main.tf
python3 - <<EOF
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
EOF

echo ""
update_outputs
echo "Lance 'terraform apply' pour appliquer la suppression."
