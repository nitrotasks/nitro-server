#!/bin/bash
git pull

wget -q https://releases.hashicorp.com/terraform/0.11.3/terraform_0.11.3_linux_amd64.zip -o terraform.zip
unzip terraform.zip
chmod +x ./terraform

./terraform init
terraform apply -auto-approve