FROM hashicorp/packer:latest

USER root

# Install dependencies
RUN apt-get update && \
    apt-get upgrade -y && \
    apt-get install -y bash curl git jq openssh-client python3 python3-pip vim

# Install AWS CLI
RUN pip3 install --upgrade pip && \
    pip3 install awscli

# Create the Packer directories
RUN mkdir -p \
    /packer/http \
    /packer/scripts \
    /packer/templates \
    /packer/variables

# Create a non-root user for running Packer and set up ssh
RUN useradd -m -s /bin/bash sa-packer && \
    mkdir -p /home/sa-packer/.ssh && \
    chown -R sa-packer:sa-packer /home/sa-packer/.ssh && \
    chmod 700 /home/sa-packer/.ssh

# Use Docker secrets to handle SSH keys securely
RUN --mount=type=secret,id=ssh_private_key \
    echo "$(cat /run/secrets/ssh_private_key)" > .ssh/id_ed25519 && \
    chmod 600 .ssh/id_ed25519

RUN --mount=type=secret,id=ssh_public_key \
    echo "$(cat /run/secrets/ssh_public_key)" > .ssh/id_ed25519.pub && \
    chmod 644 .ssh/id_ed25519.pub

RUN echo "Host *\n\tStrictHostKeyChecking no\n" > .ssh/config && \
    chown -R sa-packer:sa-packer .ssh

# Copy in required files
COPY ./http /packer/http
COPY ./templates /packer/templates
COPY ./variables /packer/variables

# Change ownership of /packer to sa-packer user and set user
RUN chown -R sa-packer:sa-packer /packer
USER sa-packer
WORKDIR /packer

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "-c"]