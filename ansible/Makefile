BIN := .venv/bin
PIP := $(BIN)/python -m pip
PY := $(BIN)/python

init:
	asdf install python 3.11.7
	asdf local python 3.11.7
	python -m venv .venv
	$(PY) -m ensurepip
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt
	ansible-galaxy collection install -r collections/requirements.yml
	ansible-galaxy role install -r roles/requirements.yml

.PHONY: run-play
run-play:
ifndef play
	echo "play=<path/to/play> argument is required"
	exit 1
endif
	$(BIN)/ansible-playbook -i inventory --diff -v $(args) $(play)