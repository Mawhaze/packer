// Set up packer folders
folder('packer/containers') {
  description('Packer jobs for Jenkins')
}

folder('packer/iso') {
  description('Packer jobs for Jenkins')
}

// Define the packer build jobs within the packer/containers folder
// Keep this alphabetical for easier maintenance
// Define the packer build jobs within the packer/iso folder
pipelineJob('packer/iso/proxmox_ubuntu_24.04_template') {
  logRotator {
    numToKeep(10) //Only keep the last 10
  }
  definition {
    cps {
      // Inline Groovy script for pipeline definition
      script("""
pipeline {
  agent any
  stages {
      stage('Sign into DockerHub and Pull Docker Image') {
          steps {
              script {
                  docker.withRegistry('https://index.docker.io/v1/', 'dockerhub_credentials') {
                      // Pull the Docker image from DockerHub before running it
                      sh "docker pull mawhaze/packer:latest"
                  }
              }
          }
      }
      stage('Run Packer Build') {
          steps {
              withCredentials([
                  usernamePassword(credentialsId: 'sa_packer_proxmox_creds', usernameVariable: 'PROXMOX_USERNAME', passwordVariable: 'PROXMOX_PASSWORD'),
                  string(credentialsId: 'ansible_public_ssh_key', variable: 'ANSIBLE_SSH_PUBLIC_KEY'),
                  string(credentialsId: 'packer_public_ssh_key', variable: 'PACKER_SSH_PUBLIC_KEY'),
              ]) {
                  sh(
                      'docker run -e PROXMOX_USERNAME=\$PROXMOX_USERNAME -e PROXMOX_PASSWORD=\$PROXMOX_PASSWORD \
                      -e ANSIBLE_SSH_PUBLIC_KEY="\$ANSIBLE_SSH_PUBLIC_KEY" -e PACKER_SSH_PUBLIC_KEY="\$PACKER_SSH_PUBLIC_KEY" \
                      mawhaze/packer:latest 
                      python create_cloud_init.py variables/node01-prox-ubuntu-2404.pkrvars.hcl http/prox-ubuntu/cloud-init.yml.j2 && \
                      packer build -var-file=variables/node01-prox-ubuntu-2404.pkrvars.hcl templates/prox-ubuntu.pkr.hcl'
                  )
              }
          }
      }
  }
}
      """)
    }
  }
}

// Docker build job for Packer
pipelineJob('docker/build/packer_docker') {
  description('Build the Packer Docker image from a Jenkinsfile')
  logRotator {
    numToKeep(10) //Only keep the last 10
  }
  definition {
    cpsScm {
      scm {
        git {
          remote {
            url('https://github.com/Mawhaze/packer.git')
            credentials('github_access_token')
          }
          branches('*/main')
          scriptPath('Jenkinsfile')
        }
      }
    }
  }
  triggers {
    scm('H/15 * * * *') // Poll SCM every 15 minutes.
  }
}