variable "tenant_id" {
  description = "Microsoft Entra ID tenant ID."
  type        = string
}

variable "subscription_id" {
  description = "Azure subscription ID."
  type        = string
}

variable "admin_ssh_public_key" {
  description = "SSH public key used for the lab Linux VM. Do not use the example value in production."
  type        = string
}
