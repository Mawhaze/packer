# Proxmox Variables
node_name = "node01"
proxmox_url = "https://10.10.10.10:8006/api2/json"
# VM template variables
http_directory = "/packer/http"
iso_file = "net-data:iso/ubuntu-24.04.1-live-server-amd64.iso"
proxmox_template_tags = "ubuntu;24.04;base_image"
proxmox_template_name = "ubuntu-24"
# User data variables
users = [
  {
    name = sa-ansible
    ssh_public_key = "{{env `ANSIBLE_SSH_PUBLIC_KEY`}}"
  },
  {
    name = sa-packer
    ssh_public_key = "{{env `PACKER_SSH_PUBLIC_KEY`}}"
  }
]