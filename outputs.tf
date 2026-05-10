output "lb_ip" {
  description = "IP du load balancer"
  value       = local.lb_ip
}

output "web_server_ips" {
  description = "IPs des serveurs web"
  value = {
    web-1 = local.web1_ip
    web-2 = local.web2_ip
  }
}

output "container_ids" {
  description = "IDs Proxmox de tous les containers créés"
  value = {
    lb    = proxmox_virtual_environment_container.lb.vm_id
    web-1 = proxmox_virtual_environment_container.web1.vm_id
    web-2 = proxmox_virtual_environment_container.web2.vm_id
  }
}

output "infrastructure_summary" {
  description = "Résumé de l'infrastructure déployée"
  value = {
    load_balancer = "${local.lb_ip} (node: ${var.pve1_node_name})"
    web_servers = {
      web-1 = "${local.web1_ip} (node: ${var.pve1_node_name})"
      web-2 = "${local.web2_ip} (node: ${var.pve2_node_name})"
    }
  }
}
