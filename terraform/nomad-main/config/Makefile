all: plan

plan: *.tf jobs/**
ifdef target
	terraform plan -var-file ../../vars/nomad.tfvars -out plan -target "$(target)" || rm plan
else
	terraform plan -var-file ../../vars/nomad.tfvars -out plan || rm plan
endif

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
