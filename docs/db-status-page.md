# Tomcat DB Status Page

This lab deploys a JSP page that attempts a real JDBC connection from the Tomcat VM to MySQL and displays database connection metadata.

## URL

After `10-vm` is deployed and Tomcat is running, open:

```text
http://<internal-load-balancer-ip>:8080/db-status.jsp
```

You can get the Internal Load Balancer IP with:

```bash
terraform -chdir=10-vm output internal_load_balancer_private_ip
```

For testing directly on the VM:

```bash
curl -I http://127.0.0.1:8080/db-status.jsp
curl http://127.0.0.1:8080/db-status.jsp
```

## Displayed values

The page displays:

| Field | Description |
| --- | --- |
| Connection Status | JDBC connection result: `SUCCESS` or `FAILED` |
| Configured DB Host | `mysql_host` Terraform variable |
| Resolved DB IP | DNS resolution result of `mysql_host` from the VM |
| Configured DB Region | `mysql_region` Terraform variable |
| Connected DB Hostname | `@@hostname` from MySQL |
| Current Database | `DATABASE()` from MySQL |
| DB Version | `@@version` from MySQL |
| DB Time | `NOW()` from MySQL |
| Web Server Time | Tomcat VM local JVM time |
| Error | JDBC or DNS error message if connection fails |

## Terraform variables

Set these values in `10-vm/sonmap.auto.tfvars`:

```hcl
mysql_host     = "<MYSQL_FQDN_OR_PRIVATE_IP>"
mysql_port     = 3306
mysql_database = "appdb"
mysql_username = "appuser"
mysql_password = "<PASSWORD>"
mysql_region   = "koreacentral"
```

For Azure Database for MySQL Flexible Server, confirm the login format required by your authentication mode. Some configurations require a user format such as `user` while others may require a server-qualified user.

## Implementation files

| File | Purpose |
| --- | --- |
| `10-vm/cloud-init-tomcat.yaml` | Installs Tomcat, MariaDB JDBC driver, and deploys `db-status.jsp` |
| `10-vm/variables.tf` | Defines MySQL connection variables |
| `10-vm/main.tf` | Renders cloud-init using `templatefile()` and passes DB values to JSP |
| `10-vm/terraform.tfvars.example` | Shows sample MySQL variable values |

## Security note

This is a lab implementation. It injects DB connection information into VM custom data so the JSP can connect to MySQL.

For production, use a safer pattern such as:

- Azure Key Vault
- Managed Identity
- Private Endpoint
- restricted NSG rules
- application configuration store
- no plaintext password in Terraform state

Terraform state can contain sensitive values. Treat the state file as sensitive data.
