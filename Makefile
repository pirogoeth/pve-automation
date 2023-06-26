SHELL := /bin/bash
.DEFAULT_GOAL := all

.PHONY: help
help: #> Show this help
help:
	@printf "\033[1mUsage: \033[0mmake [target]\n\n"
	@printf "\033[1m\033[33mtargets:\033[0m\n"
	@grep -E '^\S+:.*?#> .*' $(MAKEFILE_LIST) \
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

manifests/packer-base.json: #> Build a packer image+manifest for the Ubuntu template.
manifests/packer-base.json: ansible/playbooks/base.yml ansible/roles/base/**/* ansible/vars/base/*.yml
manifests/packer-base.json: packer/base.pkr.hcl packer/vars/base.hcl
	mkdir -p manifests
	packer build \
		-var-file packer/vars/base.hcl \
		$(args) \
		packer/base.pkr.hcl

manifests/packer-docker.json: #> Build a packer image+manifest for the Docker template.
manifests/packer-docker.json: manifests/packer-base.json
manifests/packer-docker.json: ansible/playbooks/docker.yml ansible/roles/docker/**/* ansible/vars/docker/*.yml
manifests/packer-docker.json: packer/docker.pkr.hcl packer/vars/docker.hcl
	mkdir -p manifests
	packer build \
		-var-file packer/vars/docker.hcl \
		-var "source_vm_id=$(shell scripts/get-last-run.sh manifests/packer-base.json)" \
		$(args) \
		packer/docker.pkr.hcl \
	|| rm manifests/packer-docker.json

manifests/packer-k3s.json: #> Build a packer image+manifest for the K3s template.
manifests/packer-k3s.json: #> Parallelized builds are disabled here due to a race condition in the builder.
manifests/packer-k3s.json: manifests/packer-docker.json
manifests/packer-k3s.json: ansible/playbooks/k3s.yml ansible/roles/k3s/**/* ansible/vars/k3s/*.yml
manifests/packer-k3s.json: packer/k3s.pkr.hcl packer/vars/k3s.hcl
	mkdir -p manifests
	packer build \
	 	-parallel-builds 1 \
		-var-file packer/vars/k3s.hcl \
		-var "source_vm_id=$(shell scripts/get-last-run.sh manifests/packer-docker.json)" \
		$(args) \
		packer/k3s.pkr.hcl \
	|| rm manifests/packer-k3s.json

manifests/packer-buildkite.json: #> Build a packer image+manifest for the Buildkite template.
manifests/packer-buildkite.json: manifests/packer-docker.json
manifests/packer-buildkite.json: ansible/playbooks/buildkite.yml ansible/roles/buildkite/**/* ansible/vars/buildkite/*.yml
manifests/packer-buildkite.json: packer/buildkite.pkr.hcl packer/vars/buildkite.hcl
	mkdir -p manifests
	packer build \
		-var-file packer/vars/buildkite.hcl \
		-var "source_vm_id=$(shell scripts/get-last-run.sh manifests/packer-docker.json)" \
		$(args) \
		packer/buildkite.pkr.hcl \
	|| rm manifests/packer-buildkite.json

.PHONY: all
all: manifests/packer-k3s.json
all: manifests/packer-buildkite.json

.PHONY: clean
clean: #> Clean up build artifacts.
clean:
	rm -rf manifests