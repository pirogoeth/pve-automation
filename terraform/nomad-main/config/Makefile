plan: *.tf jobs/**
ifneq ($(target),)
	terraform plan -var-file ../../vars/nomad.tfvars -out plan -target "$(target)"
endif
	terraform plan -var-file ../../vars/nomad.tfvars -out plan

.PHONY: apply
apply: plan
	terraform apply plan
	rm plan

.PHONY: reinit-modules
reinit-modules:
	terraform init -upgrade -var-file ../../vars/nomad.tfvars

.PHONY: clean
clean:
	rm plan