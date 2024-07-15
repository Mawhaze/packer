packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

data "template_file" "user_data" {
  template = file("${var.http_directory}/cloud-init.yml.j2")
  vars = {
    ansible_ssh_username = var.ansible_ssh_username
    ansible_ssh_public_key = var.ansible_ssh_public_key
    packer_ssh_username = var.packer_ssh_username
    packer_ssh_public_key = var.packer_ssh_public_key
  }
}

source "proxmox-iso" "ubuntu-cloud" {
  # Proxmox settings
  node             = var.node_name
  proxmox_url      = var.proxmox_url
  username         = var.proxmox_username
  password         = var.proxmox_password
  # VM template core settings
  cores            = "2"
  cloud_init       = true
  cloud_init_storage_pool = "net-data"
  http_content     = {
    "/user-data"   = data.template_file.user_data.rendered
  }
  iso_file         = var.iso_file
  memory           = "2048"
  os               = "126"
  ssh_username     = var.packer_ssh_username
  ssh_public_key   = var.packer_ssh_public_key
  ssh_timeout      = "30m"
  tags             = var.proxmox_template_tags
  template_name    = var.proxmox_template_name
  template_description = "Ubuntu 24.04 lab image, built on ${timestamp()}"
  unmount_iso      = true
  qemu_agent       = true

  network_adapters = [
    {
      bridge = "vmbr0"
      model  = "virtio"
    }
  ]

  disks = [
    {
      disk_size       = "32G"
      storage_pool    = "net-data"
      type       = "scsi"
    }
  ]

  boot_command = [
    "<spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait><spacebar><wait>",
    "e<wait>",
    "<down><down><down><end>",
    " autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/",
    "<f10>"
  ]
  boot = "c"
  boot_wait = "5s"
}

build {
  sources = [
    "source.proxmox-iso.ubuntu-cloud"
  ]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
    ]
  }

  provisioner "file" {
    source      = "http/prox-ubuntu/99-pve.cfg"
    destination = "/etc/cloud/cloud.cfg.d/99-pve.cfg"
  }
}