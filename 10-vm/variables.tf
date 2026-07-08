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

variable "mysql_host" {
  description = "MySQL endpoint FQDN or private IP used by the Tomcat DB status page."
  type        = string
  default     = "mysql-placeholder.mysql.database.azure.com"
}

variable "mysql_port" {
  description = "MySQL TCP port."
  type        = number
  default     = 3306
}

variable "mysql_database" {
  description = "MySQL database name used by the Tomcat DB status page."
  type        = string
  default     = "appdb"
}

variable "mysql_username" {
  description = "MySQL login user used by the Tomcat DB status page. For Azure MySQL, this might be user@server-name depending on authentication mode."
  type        = string
  default     = "appuser"
}

variable "mysql_password" {
  description = "MySQL login password used by the Tomcat DB status page. Use Key Vault or a secure variable mechanism for production."
  type        = string
  sensitive   = true
  default     = "ChangeMe-DoNotUse"
}

variable "mysql_region" {
  description = "Logical Azure region label displayed on the Tomcat DB status page."
  type        = string
  default     = "koreacentral"
}
