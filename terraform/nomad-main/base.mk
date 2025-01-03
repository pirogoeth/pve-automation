TF := tofu

ENVFILE := $(shell mu find-upwards .env)
include $(ENVFILE)
export

all: plan

plan: *.tf
ifdef target
	$(TF) plan -var-file ../../vars/$(VARS_NAME).tfvars -out plan -target "$(target)" || rm plan
else
	$(TF) plan -var-file ../../vars/$(VARS_NAME).tfvars -out plan || rm plan
endif

.PHONY: apply
apply: plan
	$(TF) apply plan
	rm plan

.PHONY: reinit-modules
reinit-modules:
	$(TF) init -upgrade -var-file ../../vars/$(VARS_NAME).tfvars

.PHONY: clean
clean:
	rm plan

.PHONY: upgrade
upgrade:
	$(TF) init --upgrade -var-file ../../vars/$(VARS_NAME).tfvars

.PHONY: console
console:
	$(TF) console -var-file ../../vars/$(VARS_NAME).tfvars

.PHONY: outputs
outputs:
	$(TF) output --json | jq .
