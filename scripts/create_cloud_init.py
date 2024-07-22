import sys
import hcl2

from jinja2 import Environment, FileSystemLoader

# Load the variables from the variables file and render the cloud-init file
def render_cloud_init(variables_file, cloud_init_template):
    with open(variables_file, 'r') as var_file:
        variables = hcl2.load(var_file)

    env = Environment(loader=FileSystemLoader('.'), trim_blocks=True, lstrip_blocks=True)
    template = env.get_template(cloud_init_template)
    cloud_init = template.render(variables)

    # Write the rendered cloud-init file for use in the Packer template
    try:
      with open('/packer/http/cloud-init.yml', 'w') as cf_file:
          cf_file.write(cloud_init)
    except Exception as e:
        print(f'Error writing cloud-init file: {e}')
        exit(1)

if __name__ == "__main__":
    if len(sys.argv) != 3:
        print("Usage: python create_cloud_init.py <variables_file> <cloud_init_template>")
        sys.exit(1)
    render_cloud_init(sys.argv[1], sys.argv[2])