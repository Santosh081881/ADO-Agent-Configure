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
