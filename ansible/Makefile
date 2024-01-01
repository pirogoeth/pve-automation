PIP := .venv/bin/pip
PY := .venv/bin/python

init:
	asdf install python 3.11.7
	asdf local python 3.11.7
	python -m venv .venv
	$(PY) -m ensurepip
	$(PIP) install --upgrade pip
	$(PIP) install -r requirements.txt