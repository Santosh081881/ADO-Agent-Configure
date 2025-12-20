output "agent_vm_public_ip" {
  value       = azurerm_public_ip.pip.ip_address
  description = "Public IP address of the Azure DevOps Agent VM"
}
