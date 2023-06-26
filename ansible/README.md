# ansible

Provisioning things for fun and profit

## Usage

- Get a Python environment set up, install latest Ansible (or, 2.14.0 as of this writing)
- `ansible-galaxy install -r requirements.yml`
- `ansible-playbook --diff playbooks/k3s.yml`