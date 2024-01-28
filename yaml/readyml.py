import yaml

# Specify the path to your YAML file
yaml_file_path = ".\inventory.yaml"

with open(yaml_file_path, 'r') as file:
    # Load YAML content
    data = yaml.safe_load(file)

# Accessing individual elements
for machine_info in data.get("inventory", []):
    machine_name = machine_info.get("machineName", "")
    os = machine_info.get("operatingSystem", "")
    memory = machine_info.get("memory", "")
    storage = machine_info.get("storage", "")
    status = machine_info.get("status", "")

    # Process or print the information as needed
    print(f"Machine Name: {machine_name}")
    print(f"Operating System: {os}")
    print(f"Memory: {memory}")
    print(f"Storage: {storage}")
    print(f"Status: {status}")
    print()
