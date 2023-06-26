# terraform

Usage instructions:
- Place your `authorized_keys` file in `./resources/`
- Copy `./vars/proxmox.tfvars.example` to `./vars/proxmox.tfvars` and update the values to be relevant to your environment.
- Change to `clusters` directory
- Run `terraform init` (only needs to be done the first time or if you update dependent modules)
- Run `terraform plan -var-file ../vars/proxmox.tfvars` to see what will be created
- Run `terraform apply plan` to create all the things
- Wait