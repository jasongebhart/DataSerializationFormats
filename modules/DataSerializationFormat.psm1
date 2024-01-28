function New-VariableFromJSON {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [object]$JsonObject
    )
    foreach ($Property in $JsonObject.PSObject.Properties) {
        # Construct the variable name dynamically
        $VariableName = $Property.Name

        if (Test-Path Variable:\$VariableName) {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Variable $VariableName exists. Value: $($VariableName)"
        } else {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Variable $VariableName does not exist."
            # Assign the variable dynamically in the global scope
            Set-Variable -Name $VariableName -Value $Property.Value -Scope Global
        }
    }
}
function Get-MatchingNamingConvention {
    param (
        [string]$ComputerName,
        [array]$NamingConvention
    )

    $matchingConvention = $NamingConvention | Where-Object { $ComputerName -like "$($_.name)*" }

    if ($matchingConvention) {
        $matchingConvention
    } else {
        Write-Warning -Message "[$($MyInvocation.MyCommand)] - Test: Failed! Name like $ComputerName not found."
    }
}

function Set-TitleForMatchingNamingConvention {
    param (
        [object]$Object,
        [string]$NewTitle
    )

    # Create a new object with the same properties and the new title
    $newObject = $Object | Select-Object *
    $newObject.Title = $NewTitle
    $newObject
}

function New-VariablesFromPSObject {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [object]$inputObject
    )

    foreach ($property in $inputObject.PSObject.Properties) {
        $variableName = $property.Name

        # Check if the property value is not blank or null
        if ($null -ne $property.Value -and $property.Value -ne '') {
            if (Test-Path Variable:\$variableName) {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Variable $variableName already exists. Value: $(Get-Variable -Name $variableName -ValueOnly)"
            } 
            else {
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] Creating variable $variableName with value: $($property.Value)"
                Set-Variable -Name $variableName -Value $property.Value -Scope Global
            }
        } else {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Skipping variable $variableName as the value is blank or null."
        }
    }
}

function New-ObjectFromJson {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [string]$Json,
        [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$JsonPath = ''
    )

    Write-Verbose -Message "[$($MyInvocation.MyCommand)] - New PSCustomObject from JSON ($Json) .............................."

    $JsonObject = Get-Content -Raw -Path $Json | ConvertFrom-Json

    if ($JsonPath) {
        try {
            $Result = Invoke-Expression ('$JsonObject.' + $JsonPath)
        } catch {
            Write-Error "Failed to get value from JSON path: $JsonPath"
            return
        }
    } else {
        $Result = $JsonObject
    }

    $Result
}
Function New-ObjectFromXML {
    [Cmdletbinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        [ValidateScript( {
            if (Test-Path -Path $_ -PathType Leaf) {
                $true
            }
            else {
                throw "The Path argument must be a file. Folder paths are not allowed."
            }
        })]
        [string]$XML,
        [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
        [string]$XPathQuery = '//*' # Select all nodes regardless of name
    )

    Write-Verbose -Message "[$($MyInvocation.MyCommand)] - XML: $XML"
    $XMLDoc = [xml](Get-Content -path $XML)
    $selectedNodes = $XMLDoc.SelectNodes($XPathQuery)

    # Convert XML nodes to PowerShell objects dynamically
    $outputObjects = foreach ($node in $selectedNodes) {
        $properties = @{}
        
        # Capture attributes
        foreach ($attribute in $node.Attributes) {
            $properties[$attribute.Name] = $attribute.Value
        }
        
        # Capture child nodes
        foreach ($childNode in $node.ChildNodes) {
            $childNodeName = $childNode.Name
            $childNodeValue = $childNode.InnerText

            # Check if the key already exists before adding
            $index = 0
            while ($properties.ContainsKey($childNodeName)) {
                $childNodeName = "${childNode.Name}_${index}"
                $index++
            }

            $properties[$childNodeName] = $childNodeValue
        }

        [PSCustomObject]$properties
    }

    $outputObjects
}
function New-ObjectFromYAML {
    [CmdletBinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        $yaml,
        [Parameter(Position = 1, Mandatory = $false, ValueFromPipeline = $true)]
        $yamlPath
    )

    try {
        $yamlObject = Get-Content -Raw -Path $yaml | ConvertFrom-Yaml
    }
    catch {
        Write-Error "Failed to convert YAML to object. $_"
        return
    }

    if ($yamlPath) {
        $result = Invoke-Expression ('$yamlObject.' + $yamlPath)

        try {
            $result = Invoke-Expression ('$yamlObject.' + $yamlPath)
        }
        catch {
            Write-Error "Failed to get value from YAML path: $yamlPath"
            return
        }

        if ($result -is [System.Collections.IEnumerable] -and $result -isnot [System.String]) {
            $resultObjects = @()
            foreach ($item in $result) {
                $resultObjects += [PSCustomObject]$item
            }
            $resultObjects
        }
        else {
            [PSCustomObject]@{ $yamlPath = $result }
        }
    }
    else {
        [PSCustomObject]$yamlObject
    }
}
Function Test-IsDeviceProfile {
    [Cmdletbinding()]
    param (
        [Parameter(Position = 0, Mandatory = $true, ValueFromPipeline = $true)]
        $ComputerName,
        [Parameter(Position = 1, Mandatory = $true, ValueFromPipeline = $true)]
        $DeviceProfile
    )
    $Device = $DeviceProfile | Where-Object -Property Name -eq $ComputerName
    If ($Device) {
        [pscustomobject]@{
            Name               = $Device.name
            Description        = $Device.description
            OS                 = $Device.OS
            Type               = $Device.Type
            Version            = $Device.Version
            DeliveryController = $Device.DeliveryController
            DDrive             = $Device.DDrive
            IsProfile          = $true
        }
    }
    else {
        Write-Warning -Message "[$($MyInvocation.MyCommand)] -  $ComputerName is not a build parent...scripts may not run"
        [pscustomobject]@{
            Name               = $ComputerName
            Description        = "Not Defined"
            OS                 = "Not Defined"
            Type               = "Not Defined"
            Version            = "Not Defined"
            DeliveryController = "Not Defined"
            DDrive             = $true
            IsProfile          = $false
        }
    }
}
Function Expand-VariablesInData {
    param (
        [object]$Data,
        [string[]]$PropertiesToExpand
    )

    if ($Data -is [System.Xml.XmlElement] -or $Data -is [System.Xml.XmlNodeList]) {
        foreach ($node in $Data) {
            Expand-VariablesInData -Data $node -PropertiesToExpand $PropertiesToExpand
        }
    }
    elseif ($Data -is [System.Management.Automation.PSCustomObject]) {
        foreach ($property in $Data.psobject.properties) {
            if ($property.Value -is [string] -and $property.Name -in $PropertiesToExpand) {
                $property.Value = Expand-String $property.Value
            }
            else {
                Expand-VariablesInData -Data $property.Value -PropertiesToExpand $PropertiesToExpand
            }
        }
    }
}
Function Expand-String {
    param (
        [string]$String
    )
    $ExecutionContext.InvokeCommand.ExpandString($String)
}
function Test-PropertyCount {
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory = $true)]
        [object]$Object,
        [Parameter(Mandatory = $true)]
        [int]$ExpectedCount
    )

    $NoteProperty = $Object | Get-Member -MemberType NoteProperty | Measure-Object | Select-Object -Property Count

    if ($NoteProperty.Count -ge $ExpectedCount) {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] Property Count Test: Success!"
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] Property Count: $($NoteProperty.Count)"
    } else {
        Write-Warning -Message "[$($MyInvocation.MyCommand)] - Test: Fail!"
        Write-Warning -Message "[$($MyInvocation.MyCommand)] - Property Count not correct: $($NoteProperty.Count)"
    }
}
function Test-ValueEquality {
    param (
        [Parameter(Mandatory = $true)]
        [string]$TestName,
        [Parameter(Mandatory = $true)]
        [object]$ActualValue,
        [Parameter(Mandatory = $true)]
        [object]$ExpectedValue
    )

    if ($ActualValue -eq $ExpectedValue) {
        $true
    } else {
        $false
    }
}
function Test-FileObject {
    [Cmdletbinding()]
    param (
        [Parameter(Mandatory = $true, Position = 0)]
        [string]$DataPath,
        [Parameter(Mandatory = $true)]
        [string]$DataPathType,
        [Parameter(Mandatory = $false)]
        [string]$QueryPath,
        [Parameter(Mandatory = $false)]
        [int]$ExpectedCount = 11, 
        [Parameter(Mandatory = $false)]
        [hashtable]$ExpectedKeyValue = $null,
        [Parameter(Mandatory = $false)]
        [hashtable]$ExpectedArrayKeyValue = $null,
        [Parameter(Mandatory = $false)]
        [string]$Title = $null  
    )
    if($PSCmdlet.MyInvocation.BoundParameters['Verbose'].IsPresent){
        $splatParams = @{
            DataPath = $DataPath
            DataPathType = $DataPathType
            QueryPath = $QueryPath
            ExpectedCount = $ExpectedCount
            ExpectedKeyValue = $ExpectedKeyValue
            ExpectedArrayKeyValue = $ExpectedArrayKeyValue
        }  
        Write-VerboseInfo @splatParams -Verbose
    }
    $ObjectName = (Get-Item $DataPath).BaseName

    try {
         # Determine the file format based on the extension
         $fileExtension = (Get-Item $DataPath).Extension.TrimStart('.')
         $Object = switch ($fileExtension) {
             'json' { New-ObjectFromJson -json $DataPath -jsonPath $QueryPath }
             'yaml' { New-ObjectFromYAML -yaml $DataPath -yamlPath $QueryPath}
             'xml'  { New-ObjectFromXML -XMl $DataPath -XPathQuery $QueryPath}
             default { throw "Unsupported file format: $fileExtension" }
         }
         
        Write-VerboseObjectInfo -ObjectName $ObjectName -Object $Object
        Test-PropertyCount -Object $Object -ExpectedCount $ExpectedCount
        If ($Title -eq 'Map' -or $Title -eq 'Environment') {
            New-VariablesFromPSObject -inputObject $Object
        }
        
        if (-not($ExpectedKeyValue -or $ExpectedArrayKeyValue)){
            # Do nothing here
        }
        
        if ($ExpectedKeyValue){
            Test-KeyValuePairs -Object $Object -ExpectedKeyValue $ExpectedKeyValue
        }
        if ($ExpectedArrayKeyValue) {
            $Object = Test-ArrayKeyValuePairs -Object $Object -ExpectedArrayKeyValue $ExpectedArrayKeyValue
        }

        # Create a new object with the original properties and the updated "Title"
        $newObject = $Object | Select-Object * -ExcludeProperty Title
        $newObject | Add-Member -MemberType NoteProperty -Name "Title" -Value $Title

        $newObject

    } catch {
        Write-Error "Failed to get value from path: $QueryPath"
        Write-Error "Error details: $_"
        return $null
    }
}
function Write-VerboseInfo {
    [Cmdletbinding()]
    param (
        [string]$DataPath,
        [Parameter(Mandatory = $true)]
        [string]$DataPathType,
        [string]$QueryPath,
        [int]$ExpectedCount,
        [hashtable]$ExpectedKeyValue,
        [hashtable]$ExpectedArrayKeyValue
    )

    Write-Verbose -Message "[$($MyInvocation.MyCommand)] DataPath: $DataPath"
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] DataPathType: $DataPathType"
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] QueryPath: $QueryPath"
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] ExpectedCount: $ExpectedCount"
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] ExpectedKeyValue: $($ExpectedKeyValue.Keys -join ', ')"
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] ExpectedArrayKeyValue: $($ExpectedArrayKeyValue.Keys -join ', ')"
}
function Write-VerboseObjectInfo {
    [Cmdletbinding()]
    param (
        [string]$ObjectName,
        [object]$Object
    )

    Write-Verbose -Message "[$($MyInvocation.MyCommand)] File: $ObjectName"
    Write-Verbose -Message "[$($MyInvocation.MyCommand)] Type: $($Object.GetType().name)"
}

function Test-KeyValuePairs {
    [Cmdletbinding()]
    param (
        [object]$Object,
        [hashtable]$ExpectedKeyValue
    )

    foreach ($key in $ExpectedKeyValue.Keys) {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] -key: $key"
        $property = $Object.PSObject.Properties | Where-Object { $_.Name -eq $key }

        if ($property) {
            $actualValue = $property.Value
            If (Test-ValueEquality -TestName $key -ActualValue $actualValue -ExpectedValue $ExpectedKeyValue[$key]){
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Value Test($key): Success!"
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Value Test($key): $($ActualValue)"
            } else {
                Write-Warning -Message "[$($MyInvocation.MyCommand)] -Value Test($TestName): Failed!"
                Write-Warning -Message "[$($MyInvocation.MyCommand)] -Value Test($TestName): $($ActualValue)"
            }
        } else {
            Write-Warning -Message "[$($MyInvocation.MyCommand)] -Key '$key' not found in the PowerShell object."
        }
    }
}
function Test-ArrayKeyValuePairs {
    [Cmdletbinding()]
    param (
        [object]$Object,
        [hashtable]$ExpectedArrayKeyValue
    )

    foreach ($key in $ExpectedArrayKeyValue.Keys) {
        Write-Verbose -Message "[$($MyInvocation.MyCommand)] -Array key: $key"
        $foundMatch = $false

        foreach ($arrayObject in $Object) {
            $null = $property 
            $property = $arrayObject | Where-Object { $_.Name -eq $ExpectedArrayKeyValue[$key]}

            if ($property) {
                $actualValue = $property.Value
                $foundMatch = $true
                Write-Verbose -Message "[$($MyInvocation.MyCommand)] - Match Found: $actualValue"
                $arrayObject
            }
        }

        if (-not $foundMatch) {
            Write-Warning -Message "[$($MyInvocation.MyCommand)] - Key '$key' not found in any object of the PowerShell object array."
        }
    }
}
function Test-Manifest {
    [Cmdletbinding()]
    param (
        [string]$ManifestPath,
        [string]$DataPathType,
        [string]$QueryPath,
        [int]$ExpectedCount,
        [string]$ModulesQueryPath
    )

    try {
        # Test the main manifest file
        $manifests = Test-FileObject -DataPath $ManifestPath -DataPathType $DataPathType -QueryPath $QueryPath -ExpectedCount $ExpectedCount
        $propertiesToExpand = @('description', 'descriptionpath', 'Path', 'Run', 'Arguments', 'PassparentSettings')

        foreach ($manifest in $manifests) {
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] `n-- $($manifest.title) --"
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Path(original): $($manifest.path)"
            # Expand variables in the manifest
            Expand-VariablesInData -Data $manifest -PropertiesToExpand $propertiesToExpand
            Write-Verbose -Message "[$($MyInvocation.MyCommand)] Path(expanded): $($manifest.path)"
        }
        # Return manifest objects
        return $manifests
    } catch {
        Write-Error "Failed to test manifest: $ManifestPath"
        Write-Error "Error details: $_"
        return @()  # Return an empty array if an error occurs
    }
}
function Get-Reports {
    param (
        [array]$ManifestReports = $global:manifestReports
    )

    $ManifestReports | Out-GridView -Title 'Manifest Reports'
}

function Get-Threads {
    param (
        [array]$ManifestThreads = $global:manifestThreads
    )

    $ManifestThreads | Out-GridView -Title 'Manifest Threads'
}

function Get-ResultTitles {
    param (
        [object[]]$Results = $global:resultsArray,
        [switch]$UseOutGridView
    )

    Write-Host "Result Titles:"
    $index = 1
    foreach ($result in $Results) {
        Write-Host "$index. $($result.title)"
        $index++
    }

    $choice = Read-Host -Prompt "Enter the number of the result to view (Press Enter to exit)"
    if ($choice -match '\d+' -and $choice -ge 1 -and $choice -le $Results.Count) {
        $selectedResult = $Results[$choice - 1]

        if ($UseOutGridView) {
            # Open the selected object in Out-GridView
            $selectedResult | Out-GridView
        } else {
            # Display the selected object in the console
            $selectedResult
        }
    }
}