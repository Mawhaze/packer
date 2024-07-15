FROM hashicorp/packer:latest

USER root

# Install dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache openssh-client python3 py3-pip vim

# Not needed until AWS builds are configured    
# # Install AWS CLI
# RUN pip3 install --upgrade pip && \
#     pip3 install awscli

# Create the Packer directories
RUN mkdir -p \
    /packer/http \
    /packer/scripts \
    /packer/templates \
    /packer/variables

# Create a non-root user for running Packer and set up ssh
RUN adduser -D sa-packer && \
    mkdir -p /home/sa-packer/.ssh && \
    chown -R sa-packer:sa-packer /home/sa-packer/.ssh && \
    chmod 700 /home/sa-packer/.ssh

# Use Docker secrets to handle SSH keys securely
RUN --mount=type=secret,id=ssh_private_key \
    echo "$(cat /run/secrets/ssh_private_key)" > /home/sa-packer/.ssh/id_ed25519 && \
    chmod 600 /home/sa-packer/.ssh/id_ed25519

RUN --mount=type=secret,id=ssh_public_key \
    echo "$(cat /run/secrets/ssh_public_key)" > /home/sa-packer/.ssh/id_ed25519.pub && \
    chmod 644 /home/sa-packer/.ssh/id_ed25519.pub

RUN echo "Host *\n\tStrictHostKeyChecking no\n" > /home/sa-packer/.ssh/config && \
    chown -R sa-packer:sa-packer /home/sa-packer/.ssh

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