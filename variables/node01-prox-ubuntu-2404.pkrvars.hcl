# Proxmox Variables
node_name = "node01"
proxmox_url = "https://10.10.10.10:8006/api2/json"
proxmox_username = ${PROXMOX_USERNAME}
proxmox_password = ${PROXMOX_PASSWORD}
# VM template variables
http_directory = "http/prox-ubuntu"
iso_file = "net-data:iso/ubuntu-24.04.1-live-server-amd64.iso"
proxmox_template_tags = ["ubuntu", "24.04", "base_image"]
proxmox_template_name = "ubuntu-24"
# User data variables
users = [
  {
    name = sa-ansible
    ssh_authorized_keys = ${ANSIBLE_SSH_PUBLIC_KEY}
  },
  {
    name = sa-packer
    ssh_authorized_keys = ${PACKER_SSH_PUBLIC_KEY}
  }
]