# Repository for Testing, Reading, and Writing XML, YAML, and JSON Data Formats

**Purpose:**

- Experiment with reading and writing XML, YAML, and JSON data formats using PowerShell and potentially Python.
- Explore different approaches for handling these data formats in script-based automation.

**Directory Structure:**
- json
- modules
- toml
- xml
- yaml

**ExecutionConfig**

- **Manifests**
  - report.manifest.[yaml|json|xml]
  - threads.manifest.[yaml]
- **Nodes**
  - device.profiles.[yaml|json|xml]
  - naming.convention.[yaml|json|xml]
  - nodes.[yaml|json|xml]
- **Resources**
  - resources.[yaml|json|xml]
  - resources-defs/
    - win11.personal.[yaml|json|xml]
    - win11.standard.[yaml|json|xml]

**Setup**

- environment.[yaml|json|xml]
- map.[yaml|json|xml]

**Tests**

- Get-ObjectFromYaml.ps1
- Get-ObjectFromXML.ps1
- Get-ObjectFromJSON.ps1

**Key Files and Functionalities**

*** Modules ***
- DataSerializationFormat

**Execution Configuration Files**
  - **Manifests** Define configuration settings for the framework.
    - **Threads Manifest (threads.manifest.[yaml|json|xml]):** Contains 'threads,' representing PowerShell scripts or commands executed on target computers.
  - **Nodes** Specify configuration for specific nodes in the environment.
    - **device profiles (device.profiles.[yaml|json|xml]):** Define parent devices and associated threads. Naming conventions guide script execution for non-parent computers.
  - **Resources**
    - **Resource Definition Files (e.g., Win11.Personal.[yaml|json|xml], Win11.Standard.[yaml|json|xml]):** Contain information for scripted updates of machine catalogs, forming the basis for infrastructure automation.
    - **map.resources.[yaml|json|xml]:** Maps to individual Resource Definition Files.

- **Setup Files**
  - **Map (map.[yaml|json|xml]):** References crucial locations (application repository, environment settings, PowerShell modules, scripts, reporting information).
  - **Environment (environment.[yaml|json|xml]):** Contains environment details (server names, Active Directory information, tenant ID, hypervisor name, database information). Entries become variables for reference in Weave. Multiple environment files (e.g., prod.environment.[yaml|json|xml], test.environment.[yaml|json|xml]) allow managing different infrastructures with one resource mapping.

**Additional Information:**

- The repository primarily utilizes PowerShell scripts for testing and automation.
- Python scripts may be added in the future to explore data format handling in different languages.

**Back to Top: #top-of-file**
