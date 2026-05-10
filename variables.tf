variable "pve1_endpoint" {
  description = "URL de l'API du node 1 (ex: https://10.20.10.1:8006)"
  type        = string
}

variable "pve1_api_token" {
  description = "Token API du node 1 au format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "pve1_node_name" {
  description = "Nom du node 1 (vérifier avec: pvesh get /nodes)"
  type        = string
  default     = "pve"
}

variable "pve2_endpoint" {
  description = "URL de l'API du node 2 (ex: https://10.20.10.2:8006)"
  type        = string
}

variable "pve2_api_token" {
  description = "Token API du node 2 au format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
}

variable "pve2_node_name" {
  description = "Nom du node 2 (vérifier avec: pvesh get /nodes)"
  type        = string
  default     = "pve"
}

variable "lxc_template" {
  description = "Chemin du template LXC sur le storage Proxmox"
  type        = string
  default     = "local:vztmpl/debian-12-standard_12.12-1_amd64.tar.zst"
}

variable "storage" {
  description = "Datastore Proxmox pour les disques containers"
  type        = string
  default     = "local-lvm"
}

variable "network_bridge" {
  description = "Bridge réseau Proxmox"
  type        = string
  default     = "vmbr0"
}

variable "network_gateway" {
  description = "Passerelle réseau du homelab"
  type        = string
  default     = "10.20.10.1"
}

variable "network_prefix" {
  description = "Préfixe réseau (ex: 10.20.10)"
  type        = string
  default     = "10.20.10"
}

variable "root_password" {
  description = "Mot de passe root des containers"
  type        = string
  sensitive   = true
}

variable "ssh_public_key" {
  description = "Clé SSH publique pour accès aux containers"
  type        = string
}
