all: plan

plan: *.tf
	terraform plan -var-file ../../vars/proxmox.tfvars -out plan

.PHONY: apply 
apply: plan
	terraform apply plan
	rm plan

.PHONY: reinit-modules
reinit-modules:
	terraform init -upgrade -var-file ../../vars/nomad.tfvars