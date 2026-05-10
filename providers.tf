provider "proxmox" {
  alias     = "pve1"
  endpoint  = var.pve1_endpoint
  api_token = var.pve1_api_token
  insecure  = true # self-signed cert homelab
}

provider "proxmox" {
  alias     = "pve2"
  endpoint  = var.pve2_endpoint
  api_token = var.pve2_api_token
  insecure  = true
}
