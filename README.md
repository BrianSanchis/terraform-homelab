# proxmox-infra

Infrastructure web HA sur Proxmox via Terraform.

## Architecture

```
[lb - 10.20.10.200]  ← nginx load balancer (pve1)
   ├── [web-1 - 10.20.10.201]  (pve1)
   └── [web-2 - 10.20.10.202]  (pve2)
```

## Prérequis

### 1. Token API Proxmox

Sur l'interface Proxmox : **Datacenter → API Tokens → Add**

- User : `root@pam`
- Token ID : `terraform`
- Décocher "Privilege Separation"

### 2. Template LXC (à faire une seule fois sur chaque node)

```bash
pveam update
pveam download local debian-12-standard_12.7-1_amd64.tar.zst
```

### 3. Noms des nœuds

```bash
pvesh get /nodes --output-format=json | jq '.[].node'
```

## Utilisation

```bash
cp terraform.tfvars.example terraform.tfvars
# Éditer terraform.tfvars avec vos valeurs

terraform init
terraform plan
terraform apply
```

## Détruire l'infra

```bash
terraform destroy
```
