# Node addresses for the Ansible inventory, and the load balancer name.

output "searchhead_fqdn" {
  description = "Private FQDN of each search head."
  value = {
    for index, instance in module.searchhead :
    index => instance.dns_priv_fqdn
  }
}

output "searchhead_private_ip" {
  description = "Private IP of each search head."
  value = {
    for index, instance in module.searchhead :
    index => instance.private_ip
  }
}

output "indexer_fqdn" {
  description = "Private FQDN of each indexer."
  value = {
    for index, instance in module.indexer :
    index => instance.dns_priv_fqdn
  }
}

output "indexer_private_ip" {
  description = "Private IP of each indexer."
  value = {
    for index, instance in module.indexer :
    index => instance.private_ip
  }
}

output "heavyforwarder_fqdn" {
  description = "Private FQDN of each heavy forwarder."
  value = {
    for index, instance in module.heavyforwarder :
    index => instance.dns_priv_fqdn
  }
}

output "heavyforwarder_private_ip" {
  description = "Private IP of each heavy forwarder."
  value = {
    for index, instance in module.heavyforwarder :
    index => instance.private_ip
  }
}

output "manager_fqdn" {
  description = "Private FQDN of each manager."
  value = {
    for index, instance in module.manager :
    index => instance.dns_priv_fqdn
  }
}

output "manager_private_ip" {
  description = "Private IP of each manager."
  value = {
    for index, instance in module.manager :
    index => instance.private_ip
  }
}

output "load_balancer_fqdn" {
  description = "Public DNS name of the front-end load balancer."
  value       = aws_route53_record.frontend.name
}
