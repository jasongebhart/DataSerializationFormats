# YAML Configuration

<a name="top-of-file"></a>

## YAML Configuration File Directory Structure
<a name="executionconfig"></a>
### ExecutionConfig
- **Manifests**
  - report.manifest.yaml
  - threads.manifest.yaml
- **Nodes**
  - device.profiles.yaml
  - namming.convention.yaml
  - nodes.yaml
- **Resources**
  - resources.yaml
  - resources-defs/
    - win11.personal.yaml
    - win11.standard.yaml

### Setup
- environment.yaml
- map.yaml

### tests
- Get-ObjectFromYaml.ps1

## Execution Configuration Files

### Manifests:

The Manifests directory contains the configuration files for the Framework.

#### Threads (threads.manifest.yaml)

The **Threads Manifest** contains elements known as 'threads', each representing a PowerShell script or command with specific purposes, such as modifying registry items or deleting scheduled tasks. These sections are evaluated during the Weave build process to determine their execution on the target computer.

- threads.manifest.yaml: This file defines 'threads,' each representing a script or command for the target computer.

### Nodes:

The Nodes directory contains configuration files for specific nodes in your environment.

- device.profiles.yaml: This file defines parent devices and determines the threads to run for each parent device. Naming conventions are used for non-parent computers to identify the scripts to run.

The **device profiles** file defines parent devices and their associated threads. Naming conventions guide script execution for non-parent computers.

### Resources:

The Resources directory contains resource definition files.

#### Resource Definition Files 

These files (e.g., Win11.Personal.yaml, Win11.Standard.yaml) contain hypervisor, Active Directory, and specific information for scripted updates of machine catalogs. They form the foundation for infrastructure automation.

- map.resources.yaml: This file maps to individual Resource Definition Files.
- Resource Definition Files: Contain information for scripted updates and form the basis for infrastructure automation.


<a name="the-map-file"></a>

## Setup Files

### Map (map.yaml)

The **map** serves as a reference to crucial locations, including the application repository, environment settings, PowerShell modules, scripts, and reporting information.

<a name="environment"></a>

### Environment (environment.yaml)

The environment file contains essential information describing the environment—server names, Active Directory details, tenant ID, hypervisor name, and database information. Entries are automatically converted into variables for reference in Weave. Different environment files (e.g., prod.environment.yaml, test.environment.yaml) allow maintaining multiple infrastructures with one resource mapping. The config file references this file in the **WeaveEnvironment** element.

___
[Back to Top](#top-of-file)