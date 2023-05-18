SHELL := /bin/bash

.PHONY: help
help: #> Show this help
help:
	@printf "\033[1mUsage: \033[0mmake [target]\n\n"
	@printf "\033[1m\033[33mtargets:\033[0m\n"
	@grep -E '^[a-zA-Z_-]+:.*?#> .*' $(MAKEFILE_LIST) \
			| sort \
			| awk '\
					BEGIN {FS = ":.*?#> "}; \
					{printf "  \033[36m%-15s\033[0m %s\n", $$1, $$2} \
					'

.PHONY: upstream/ubuntu
upstream/ubuntu: #> Creates an Ubuntu template from a cloud-init-ready image
upstream/ubuntu:
	set -e ; \
	export \
		NODE=$(NODE) \
		VM_ID=$(VM_ID) \
		RELEASE=$(RELEASE) \
		SNAPSHOT=$(SNAPSHOT) \
		MACHINE_ARCH=$(MACHINE_ARCH) \
		TARGET_ISO_STORAGE=$(TARGET_ISO_STORAGE) \
		TARGET_VM_STORAGE=$(TARGET_VM_STORAGE) \
		CUSTOM_USER_CONFIG=$(CUSTOM_USER_CONFIG) \
		FORCE=$(FORCE) \
	&& { \
		set -e ; \
		[ -z "$${NODE}" ] && echo "need NODE=" && exit 127 ; \
		[ -z "$${VM_ID}" ] && echo "need VM_ID=" && exit 127 ; \
		[ -z "$${FORCE}" ] && export FORCE="-F" ; \
	} \
	&& ./scripts/create-ubuntu-template.sh \
		-i $${VM_ID} \
		-n $${NODE}
		-r $${RELEASE} \
		-s $${SNAPSHOT} \
		-m $${MACHINE_ARCH} \
		-t $${TARGET_ISO_STORAGE} \
		-T $${TARGET_VM_STORAGE} \
		-U $${CUSTOM_USER_CONFIG}
		$${FORCE}

.PHONY: template/ubuntu
template/ubuntu/base:
	packer build \
		-var-file vars/base.hcl \
		packer/base.pkr.hcl
