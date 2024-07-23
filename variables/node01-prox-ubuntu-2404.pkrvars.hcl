# Proxmox Variables
node_name = "node01"
proxmox_url = "https://storage.mawhaze.dev:8006/api2/json"
# VM template variables
iso_file = "net-data:iso/ubuntu-24.04-live-server-amd64.iso"
proxmox_template_tags = "ubuntu;24.04;base_image"
proxmox_template_name = "ubuntu-24"
# User data variables
users = [
  {name = "sa-ansible"},
  {name = "sa-packer"}
]