all: plan

plan: *.tf
ifndef target
	terraform plan -var-file ../../vars/proxmox.tfvars -out plan || rm plan
else
	terraform plan -var-file ../../vars/proxmox.tfvars -out plan -target "$(target)" || rm plan
endif

.PHONY: apply 
apply: plan
	terraform apply -parallelism=1 plan
	rm plan

.PHONY: reinit-modules
reinit-modules:
	terraform init -upgrade -var-file ../../vars/nomad.tfvars