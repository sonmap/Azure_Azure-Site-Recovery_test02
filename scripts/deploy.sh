#!/usr/bin/env bash
set -euo pipefail

ROOT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"

for stage in 00-network 10-vm 20-asr; do
  echo "============================================================"
  echo "Terraform stage: ${stage}"
  echo "============================================================"
  cd "${ROOT_DIR}/${stage}"
  terraform init
  terraform fmt -recursive
  terraform validate
  terraform plan -out=tfplan
  echo "Apply ${stage}? Type yes to continue:"
  read -r answer
  if [[ "${answer}" == "yes" ]]; then
    terraform apply tfplan
  else
    echo "Skipped apply for ${stage}."
    exit 1
  fi

done
