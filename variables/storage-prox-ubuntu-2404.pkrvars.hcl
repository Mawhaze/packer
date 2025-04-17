# Proxmox Variables
node_name = "storage"
proxmox_url = "https://storage.mawhaze.dev:8006/api2/json"
# VM template variables
iso_file = "net-data:iso/ubuntu-24.04-live-server-amd64.iso"
ssh_private_key_file = "/home/sa-packer/.ssh/id_ed25519"
proxmox_template_tags = "ubuntu,24.04,base_image"
proxmox_template_name = "storage-ubuntu-2404-template"
destination_storage_pool = "nvme01"
# User data variables
users = [
  {name = "sa-ansible"},
  {name = "sa-packer"}
]