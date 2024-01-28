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
$DataPathType = 'xml'
try {
    $TranscriptName = "GetObjects$DataPathType" + ".log"
    $TranscriptLog = Join-Path -Path $Path -ChildPath $TranscriptName
    Start-Transcript -Path $TranscriptLog -ErrorAction Stop | Out-Null
} catch [System.InvalidOperationException] {
    Write-Warning -Message "Transcribe already running"
}
$manifestPath = "$parentDirectory\ExecutionConfig\Manifests"
$reportManifestPath = Join-Path $manifestPath "report.manifest.xml"
$threadsManifestPath = Join-Path $manifestPath "threads.manifest.xml"

# Define an array of file paths and their associated parameters
$fileParams = @(
    @{
        Title = 'Map'
        DataPath = "$parentDirectory\Setup\map.xml"
        DataPathType = $DataPathType
        QueryPath = "//Framework/Configuration"
        ExpectedCount = 12
        ExpectedKeyValue = @{Weave = '\\deploy.vivika.com\weave'}
    },
    @{
        Title = 'Environment'
        DataPath = "$parentDirectory\Setup\environment.xml"
        DataPathType = $DataPathType
        QueryPath = "//Framework/Configuration"
        ExpectedCount = 21
        ExpectedKeyValue = @{WeaveEnvironmentName = 'Weave 10'}
    },
    @{
        Title = 'Device Profiles'
        DataPath = "$parentDirectory\ExecutionConfig\Nodes\device.profiles.xml"
        DataPathType = $DataPathType
        QueryPath = "//MainDevices/Device"
        ExpectedCount = 3
        ExpectedArrayKeyValue = @{name = 'ws11-main'}
    },
    @{
        Title = 'Naming Convention'
        DataPath = "$parentDirectory\ExecutionConfig\Nodes\naming.convention.xml"
        DataPathType = $DataPathType
        QueryPath = "//NamingConventions/Convention"
        ExpectedCount = 3
    },
    @{
        Title = 'Nodes'
        DataPath = "$parentDirectory\ExecutionConfig\Nodes\nodes.xml"
        DataPathType = $DataPathType
        QueryPath = "//Nodes/Node"
        ExpectedCount = 2
        ExpectedArrayKeyValue = @{name = 'ws11-001'}
    },
    @{
        Title = 'Resources'
        DataPath = "$parentDirectory\ExecutionConfig\Resources\map.resources.xml"
        DataPathType = $DataPathType
        QueryPath = "//Resources/ResourcesList/Resource"
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
        $param.Verbose = $VerbosePreference
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
    QueryPath = "//Weave/Threads/Thread"
    ExpectedCount = 5
    ModulesQueryPath = "report.manifest.xml"
    Verbose = $VerbosePreference
}
$manifestReports = Test-Manifest @splatParams

$splatParams = @{
    ManifestPath = $threadsManifestPath
    DataPathType = $DataPathType
    QueryPath = "//Weave/Threads/Thread"
    ExpectedCount = 16
    ModulesQueryPath = "threads.manifest.xml"
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