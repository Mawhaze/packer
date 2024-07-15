source "docker" "ubuntu" {
  image  = "ubuntu:24.04"
  commit = true
}

build {
  sources = [
    "source.docker.ubuntu"
  ]

  provisioner "shell" {
    inline = [
      "apt-get update",
      "apt-get install -y nginx",
      "systemctl enable nginx"
    ]
  }
}