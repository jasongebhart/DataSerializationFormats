<#
.Synopsis
.Description
.Parameter
.Example
.Notes
#>
[cmdletbinding()]
param ()
If ($PSScriptRoot) { $path = $PSScriptRoot } else { $path = ".\" }
$parentDirectory = Split-Path -Path $path -Parent
Import-Module $parentDirectory\..\modules\DataSerializationFormat.psm1
$global:computername = 'ws11-001'
$DataPathType = 'yaml'
try {
    $TranscriptName = "GetObjects$DataPathType" + ".log"
    $TranscriptLog = Join-Path -Path $Path -ChildPath $TranscriptName
    Start-Transcript -Path $TranscriptLog -ErrorAction Stop | Out-Null
} catch [System.InvalidOperationException] {
    Write-Warning -Message "Transcribe already running"
}
$manifestPath = "$parentDirectory\ExecutionConfig\Manifests"
$reportManifestPath = Join-Path $manifestPath "report.manifest.yaml"
$threadsManifestPath = Join-Path $manifestPath "threads.manifest.yaml"

# Define an array of file paths and their associated parameters
$fileParams = @(
    @{
        Title = 'Map'
        DataPath = "$parentDirectory\Setup\map.yaml"
        DataPathType = $DataPathType
        QueryPath = $null
        ExpectedCount = 12
        ExpectedKeyValue = @{Weave = '\\deploy.vivika.com\weave'}
    },
    @{
        Title = 'Environment'
        DataPath = "$parentDirectory\Setup\environment.yaml"
        DataPathType = $DataPathType
        QueryPath = "configuration"
        ExpectedCount = 21
        ExpectedKeyValue = @{WeaveEnvironmentName = 'Weave 10'}
    },
    @{
        Title = 'Device Profiles'
        DataPath = "$parentDirectory\ExecutionConfig\Nodes\device.profiles.yaml"
        DataPathType = $DataPathType
        QueryPath = "main_devices"
        ExpectedCount = 3
        ExpectedArrayKeyValue = @{name = 'ws11-main'}
    },
    @{
        Title = 'Naming Convention'
        DataPath = "$parentDirectory\ExecutionConfig\Nodes\naming.convention.yaml"
        DataPathType = $DataPathType
        QueryPath = "naming_convention"
        ExpectedCount = 3
    },
    @{
        Title = 'Nodes'
        DataPath = "$parentDirectory\ExecutionConfig\Nodes\nodes.yaml"
        DataPathType = $DataPathType
        QueryPath = "nodes"
        ExpectedCount = 2
        ExpectedArrayKeyValue = @{name = 'ws11-001'}
    },
    @{
        Title = 'Resources'
        DataPath = "$parentDirectory\ExecutionConfig\Resources\map.resources.yaml"
        DataPathType = $DataPathType
        QueryPath = "Resources.ResourcesList"
        ExpectedCount = 3
        ExpectedArrayKeyValue = @{name = 'Windows 10 Standard'}
    }
)
# Array to store results for each iteration
$resultsArray = @()

# Loop through the file parameters and call Test-FileObject
foreach ($param in $fileParams) {
    $param.DataPathType = $DataPathType
    # Add Verbose parameter to $param if script was called with -Verbose
    if ($VerbosePreference) {
        $param.Verbose = $true  # Or use a switch parameter: $param.Verbose = $VerbosePreference
    }
    $result = Test-FileObject @param
    $resultsArray += $result
}
$NamingConvention = $resultsArray | Where-Object { $_.Title -eq "Naming Convention" }
$MatchedNamingConvention = Get-MatchingNamingConvention -ComputerName 'ws11-main' -NamingConvention $NamingConvention
if ($MatchedNamingConvention) {
    $resultsArray += Set-TitleForMatchingNamingConvention -Object $MatchedNamingConvention -NewTitle "Matched Naming Convention"
}
$splatParams = @{
    ManifestPath = $reportManifestPath
    DataPathType = $DataPathType
    QueryPath = "Weave.threads.thread"
    ExpectedCount = 5
    ModulesQueryPath = "report.manifest.yaml"
    Verbose = $VerbosePreference
}
$manifestReports = Test-Manifest @splatParams

$splatParams = @{
    ManifestPath = $threadsManifestPath
    DataPathType = $DataPathType
    QueryPath = "Weave.threads.thread"
    ExpectedCount = 16
    ModulesQueryPath = "threads.manifest.yaml"
    Verbose = $VerbosePreference
}
$manifestThreads = Test-Manifest @splatParams
# Display information for each result
foreach ($result in $resultsArray) {
    $result.title
    $result
}

Stop-Transcript
Write-Output "To view manifests in a grid view, type 'get-reports' or 'get-threads'."
Write-Output "To view other results in the console, type 'get-ResultTitles'."