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
  parameters {
    choiceParam('HOST_NODE', ['node01', 'storage'], 'Select the destination node')
  }
  definition {
    cps {
      // Inline Groovy script for pipeline definition
      script("""
pipeline {
  agent {
      label 'net-host'
  }
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
      stage('Verify Template File') {
          steps {
              sh 'docker run --rm mawhaze/packer:latest /bin/bash -c "ls -l /packer/http/prox-ubuntu"'
          }
      }
      stage('Run Packer Build') {
          steps {
              withCredentials([
                  usernamePassword(credentialsId: 'sa_packer_proxmox_creds', usernameVariable: 'PROXMOX_USERNAME', passwordVariable: 'PROXMOX_PASSWORD'),
                  string(credentialsId: 'sa_packer_aws_access_key_id', variable: 'AWS_ACCESS_KEY_ID'),
                  string(credentialsId: 'sa_packer_aws_secret_access_key', variable: 'AWS_SECRET_ACCESS_KEY')

              ]) {
                  sh(
                      'docker run --network host -e AWS_DEFAULT_REGION=us-west-2 \
                      -e AWS_ACCESS_KEY_ID=\$AWS_ACCESS_KEY_ID -e AWS_SECRET_ACCESS_KEY=\$AWS_SECRET_ACCESS_KEY \
                      -e PROXMOX_USERNAME=\$PROXMOX_USERNAME -e PROXMOX_PASSWORD=\$PROXMOX_PASSWORD \
                      mawhaze/packer:latest \
                      /bin/bash -c "source /home/sa-packer/packer-venv/bin/activate && cd /packer && ls -la && \
                      python scripts/create_cloud_init.py variables/\$HOST_NODE-prox-ubuntu-2404.pkrvars.hcl http/prox-ubuntu/cloud-config.yml.j2 && \
                      packer build -var-file=variables/node01-prox-ubuntu-2404.pkrvars.hcl templates/prox-ubuntu.pkr.hcl"'
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