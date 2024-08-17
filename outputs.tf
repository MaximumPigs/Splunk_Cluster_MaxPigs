output "searchhead_fqdn" {
  value = {
    for index, instance in module.searchhead :
    index => instance.dns_priv_fqdn
  }
}

output "searchhead_private_ip" {
  value = {
    for index, instance in module.searchhead :
    index => instance.private_ip
  }
}

output "indexer_fqdn" {
  value = {
    for index, instance in module.indexer :
    index => instance.dns_priv_fqdn
  }
}

output "indexer_private_ip" {
  value = {
    for index, instance in module.indexer :
    index => instance.private_ip
  }
}

output "heavyforwarder_fqdn" {
  value = {
    for index, instance in module.heavyforwarder :
    index => instance.dns_priv_fqdn
  }
}

output "heavyforwarder_private_ip" {
  value = {
    for index, instance in module.heavyforwarder :
    index => instance.private_ip
  }
}

output "manager_fqdn" {
  value = {
    for index, instance in module.manager :
    index => instance.dns_priv_fqdn
  }
}

output "manager_private_ip" {
  value = {
    for index, instance in module.manager :
    index => instance.private_ip
  }
}