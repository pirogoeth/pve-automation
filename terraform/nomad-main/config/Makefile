TF := tofu

all: plan

plan: *.tf jobs/**
ifdef target
	$(TF) plan -var-file ../../vars/nomad.tfvars -out plan -target "$(target)" || rm plan
else
	$(TF) plan -var-file ../../vars/nomad.tfvars -out plan || rm plan
endif

.PHONY: apply
apply: plan
	$(TF) apply plan
	rm plan

.PHONY: reinit-modules
reinit-modules:
	$(TF) init -upgrade -var-file ../../vars/nomad.tfvars

.PHONY: clean
clean:
	rm plan

.PHONY: upgrade
upgrade:
	$(TF) init --upgrade -var-file ../../vars/nomad.tfvars

.PHONY: console
console:
	$(TF) console -var-file ../../vars/nomad.tfvars