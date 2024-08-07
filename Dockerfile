FROM hashicorp/packer:latest

USER root

# Install dependencies
RUN apk update && \
    apk upgrade && \
    apk add --no-cache openssh-client python3 py3-pip vim

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
COPY ./scripts /packer/scripts
COPY ./templates /packer/templates
COPY ./variables /packer/variables

# Change ownership of /packer to sa-packer user and set user
RUN chown -R sa-packer:sa-packer /packer
USER sa-packer

# Create and activate a virtual environment for Packers pip requirements
RUN python3 -m venv /home/sa-packer/packer-venv
RUN . home/sa-packer/packer-venv/bin/activate && \
    pip install --upgrade pip && \
    pip install boto3 python-hcl2 jinja2

# Set the working directory
WORKDIR /packer

# Initialize Packer
RUN packer init ./templates

# Set the entrypoint
ENTRYPOINT ["/bin/bash", "-c", "source /home/sa-packer/packer-venv/bin/activate && exec \"$@\"", "--"]
CMD ["packer", "--version"]