variable "ado_org_url" {
  description = "Azure DevOps Org URL"
  type        = string
}

variable "ado_pat" {
  description = "ADO PAT Token"
  type        = string
  sensitive   = true
}

variable "agent_pool" {
  description = "Agent pool name"
  type        = string
}

# variable "agent_user" {
#   description = "Linux user for Azure DevOps agent"
#   type        = string
#   default     = "santosh"
# }
