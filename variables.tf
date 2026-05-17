variable "proxmox_endpoint" {
  description = "URL de l'API Proxmox (ex: https://10.20.10.1:8006)"
  type        = string
}

variable "proxmox_api_token" {
  description = "Token API Proxmox au format user@realm!tokenid=secret"
  type        = string
  sensitive   = true
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
