#!/usr/bin/env python3
"""Generate 20-asr/data/protected_vms.csv from shared inventory and Terraform outputs.

Run after the 10-vm stack has been applied:

    python3 scripts/generate_protected_vms.py

The script reads:
- inventory/vm_inventory.csv
- terraform -chdir=10-vm output -json vm_ids
- terraform -chdir=10-vm output -json vm_os_disk_ids
- terraform -chdir=10-vm output -json vm_nic_ids

It writes:
- 20-asr/data/protected_vms.csv
"""

import csv
import json
import subprocess
import sys
from pathlib import Path

ROOT = Path(__file__).resolve().parents[1]
INVENTORY = ROOT / "inventory" / "vm_inventory.csv"
OUTPUT = ROOT / "20-asr" / "data" / "protected_vms.csv"


def terraform_output(name: str) -> dict:
    command = ["terraform", "-chdir=10-vm", "output", "-json", name]
    try:
        result = subprocess.run(
            command,
            cwd=ROOT,
            check=True,
            capture_output=True,
            text=True,
        )
    except subprocess.CalledProcessError as exc:
        print(f"ERROR: failed to read Terraform output '{name}'.", file=sys.stderr)
        print(exc.stderr, file=sys.stderr)
        raise

    return json.loads(result.stdout)


def main() -> None:
    if not INVENTORY.exists():
        raise FileNotFoundError(f"Inventory file not found: {INVENTORY}")

    vm_ids = terraform_output("vm_ids")
    os_disk_ids = terraform_output("vm_os_disk_ids")
    nic_ids = terraform_output("vm_nic_ids")

    rows = []

    with INVENTORY.open(newline="", encoding="utf-8") as inventory_file:
        reader = csv.DictReader(inventory_file)

        for vm in reader:
            if vm.get("asr_enabled", "").strip().lower() != "true":
                continue

            vm_name = vm["vm_name"]

            missing_outputs = [
                output_name
                for output_name, output_value in {
                    "vm_ids": vm_ids,
                    "vm_os_disk_ids": os_disk_ids,
                    "vm_nic_ids": nic_ids,
                }.items()
                if vm_name not in output_value
            ]

            if missing_outputs:
                raise KeyError(
                    f"VM '{vm_name}' is enabled for ASR but is missing from Terraform outputs: "
                    f"{', '.join(missing_outputs)}"
                )

            rows.append(
                {
                    "replication_name": vm["replication_name"],
                    "source_vm_name": vm_name,
                    "source_vm_id": vm_ids[vm_name],
                    "os_disk_id": os_disk_ids[vm_name],
                    "source_nic_id": nic_ids[vm_name],
                    "target_resource_group_name": vm["target_resource_group_name"],
                    "target_subnet_name": vm["target_subnet_name"],
                    "failover_test_subnet_name": vm["failover_test_subnet_name"],
                    "target_disk_type": vm["target_disk_type"],
                    "target_replica_disk_type": vm["target_replica_disk_type"],
                }
            )

    OUTPUT.parent.mkdir(parents=True, exist_ok=True)

    fieldnames = [
        "replication_name",
        "source_vm_name",
        "source_vm_id",
        "os_disk_id",
        "source_nic_id",
        "target_resource_group_name",
        "target_subnet_name",
        "failover_test_subnet_name",
        "target_disk_type",
        "target_replica_disk_type",
    ]

    with OUTPUT.open("w", newline="", encoding="utf-8") as output_file:
        writer = csv.DictWriter(output_file, fieldnames=fieldnames)
        writer.writeheader()
        writer.writerows(rows)

    print(f"Generated {len(rows)} ASR protected VM row(s): {OUTPUT}")


if __name__ == "__main__":
    main()
