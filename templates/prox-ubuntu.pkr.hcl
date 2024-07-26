packer {
  required_plugins {
    proxmox = {
      version = ">= 1.1.8"
      source  = "github.com/hashicorp/proxmox"
    }
  }
}

variable "node_name" {
  description = "Proxmox node name"
}

variable "ssh_private_key_file" {
  description = "SSH private key file"
}

variable "proxmox_url" {
  description = "Proxmox API URL"
}

variable "proxmox_username" {
  description = "Proxmox username"
  type        = string
  default     = "${env("PROXMOX_USERNAME")}"
}

variable "proxmox_password" {
  description = "Proxmox password"
  type        = string
  default     = "${env("PROXMOX_PASSWORD")}"
}

variable "iso_file" {
  description = "ISO file to use for installation"
}

variable "proxmox_template_tags" {
  description = "Tags to apply to the Proxmox template"
}

variable "proxmox_template_name" {
  description = "Name of the Proxmox template"
}

source "proxmox-iso" "ubuntu-server-noble-numbat" {
  # Proxmox settings
  node             = var.node_name
  proxmox_url      = var.proxmox_url
  username         = var.proxmox_username
  password         = var.proxmox_password
  # VM template core settings
  cores            = "2"
  cloud_init       = true
  cloud_init_storage_pool = "net-data"
  http_port_min    = "8800"
  http_port_max    = "8800"
  http_directory   = "/packer/http/"
  iso_file         = var.iso_file
  memory           = "4096"
  os               = "l26"
  scsi_controller  = "virtio-scsi-pci"
  ssh_timeout      = "30m"
  ssh_username     = "ubuntu"
  ssh_password     = "ubuntu"
  # ssh_private_key_file  = var.ssh_private_key_file
  tags             = var.proxmox_template_tags
  template_name    = var.proxmox_template_name
  template_description = "Ubuntu 24.04 lab image, built on ${timestamp()}"
  unmount_iso      = true
  qemu_agent       = true

  network_adapters {
    bridge = "vmbr0"
    model  = "virtio"
  }

  disks {
    disk_size       = "32G"
    storage_pool    = "net-data"
    type            = "scsi"
  }

  boot_command = [
    "<esc><wait>",
    "e<wait>",
    "<down><down><down><end>",
    "<bs><bs><bs><bs><wait>",
    "ip=::::::dhcp<wait>::: ",
    "autoinstall ds=nocloud-net\\;s=http://{{ .HTTPIP }}:{{ .HTTPPort }}/ ---<wait>",
    "<f10><wait>"
  ]
  boot = "c"
  boot_wait = "5s"
}

build {
  sources = [
    "source.proxmox-iso.ubuntu-server-noble-numbat"
  ]

  provisioner "shell" {
    inline = [
      "while [ ! -f /var/lib/cloud/instance/boot-finished ]; do echo 'Waiting for cloud-init...'; sleep 1; done",
    ]
  }
  provisioner "file" {
      source = "/packer/http/prox-ubuntu/99-pve.cfg"
      destination = "/tmp/99-pve.cfg"
  }

  provisioner "shell" {
      inline = [ "sudo cp /tmp/99-pve.cfg /etc/cloud/cloud.cfg.d/99-pve.cfg" ]
  }
}