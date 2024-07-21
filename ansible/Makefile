BIN := .venv/bin
PATH := $(BIN):$(PATH)
PIP := $(BIN)/python -m pip
PY := $(BIN)/python
export PATH := $(PATH)

init:
	asdf install python 3.11.7
	asdf local python 3.11.7
	python -m venv .venv
	$(PY) -m ensurepip
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	make refresh-galaxy

.PHONY: refresh-galaxy
refresh-galaxy:
	ansible-galaxy collection install -r collections/requirements.yml $(args)
	ansible-galaxy role install -r roles/requirements.yml $(args)

.PHONY: run-play
run-play:
ifndef play
	echo "play=<path/to/play> argument is required"
	exit 1
endif
	$(BIN)/ansible-playbook -i inventory --diff -v $(args) $(play)