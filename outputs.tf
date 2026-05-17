output "container_ids" {
  description = "IDs Proxmox de tous les containers créés"
  value = {
    "lb" = proxmox_virtual_environment_container.lb.vm_id
    "web1" = proxmox_virtual_environment_container.web1.vm_id
    "web2" = proxmox_virtual_environment_container.web2.vm_id
    "test1" = proxmox_virtual_environment_container.test1.vm_id
    "test2" = proxmox_virtual_environment_container.test2.vm_id
  }
}

output "infrastructure_summary" {
  description = "Résumé de l'infrastructure déployée"
  value = {
    "lb" = "10.20.10.200 (node: pve1, vmid: 200)"
    "web1" = "10.20.10.201 (node: pve1, vmid: 201)"
    "web2" = "10.20.10.202 (node: pve2, vmid: 202)"
    "test1" = "10.20.10.203 (node: pve1, vmid: 203)"
    "test2" = "10.20.10.204 (node: pve2, vmid: 204)"
  }
}
