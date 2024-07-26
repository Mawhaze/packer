import sys
import boto3
import hcl2

from jinja2 import Environment, FileSystemLoader

# Load the variables from the variables file and render the cloud-init file
def render_cloud_init(variables_file, cloud_init_template):
    with open(variables_file, 'r') as var_file:
        variables = hcl2.load(var_file)

    # Create a list of Users from the variables file
    required_users = [user['name'] for user in variables['users']]

    # Pull public ssh keys from AWS SSM and create a user dictionary
    ssm = boto3.client('ssm')
    users = []

    for user in required_users:
        try:
            response = ssm.get_parameter(Name=f'/{user[3:]}/{user}/ssh-pub', WithDecryption=True)
            users.append({'name': user, 'ssh_public_key': response['Parameter']['Value']})
        except Exception as e:
            print(f'Error retrieving user {user} public key: {e}')
            exit(1)

    # Rendered the cloud-init file for use in the Packer template
    env = Environment(loader=FileSystemLoader('/packer'), trim_blocks=True, lstrip_blocks=True)
    template = env.get_template(cloud_init_template)
    cloud_init = template.render({'users': users})
    
    try:
      with open('/packer/http/user-data', 'w') as cf_file:
          cf_file.write(cloud_init)
    except Exception as e:
        print(f'Error writing cloud-init file: {e}')
        exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python scripts/create_cloud_init.py <variables_file> <cloud_init_template>")
        sys.exit(1)
    render_cloud_init(sys.argv[1], sys.argv[2])