# Not Yet Constructed
# Lacks native tool for reading toml
# Example using TomlNet:
Add-Type -Path "TomlNet.dll"
$tomlContent = Get-Content 'path/to/your/file.toml' -Raw
$toml = [TomlNet.TomlParser]::Parse($tomlContent)

$ComputerName = 'ws11-main'
$WeaveEnvironmentTest = 'Weave 10'
$WeaveTest = '\\deploy.vivika.com\weave'
If ($PSScriptRoot) {$path = $PSScriptRoot }else {$path = ".\"}
import-module powershell-yaml
Import-Module $path\..\..\modules\DataSerializationFormat.psm1

$MapObject = New-ObjectFromYAML -yaml "$path\..\Setup\map.yaml"
Write-Output -InputObject "`nFile: map"
Write-Output -InputObject "Type: $($MapObject.GetType().name)"
$NoteProperty = $MapObject  | Get-Member -MemberType NoteProperty | Measure-Object | Select-Object -Property Count
If ($NoteProperty.Count -gt 11){
    Write-Output -InputObject "Property Count Test: Success!"
    Write-Output -InputObject "Property Count: $($NoteProperty.Count)"
} else {
    Write-Warning -Message "Test: Fail!"
    Write-Warning -Message "Property Count not correct: $($NoteProperty.Count)"
}
New-VariablesFromPSObject -inputObject $MapObject
If ($WeaveTest -eq $MapObject.Weave){
    Write-Output -InputObject "Value Test(Weave): Success!"
    Write-Output -InputObject "Value Test(Weave): $WeaveTest"
}else {
    Write-Warning -Message "Value Test(Weave): Failed!"
    Write-Warning -Message "Value Test(Weave): $WeaveTest"
}

$EnvironmentObject = New-ObjectFromYAML -yaml "$path\..\Setup\environment.yaml" -yamlPath "configuration"
Write-Output -InputObject "`nFile: environment"
Write-Output -InputObject "Type: $($EnvironmentObject.GetType().name)"
$NoteProperty = $EnvironmentObject  | Get-Member -MemberType NoteProperty | Measure-Object | Select-Object -Property Count
If ($NoteProperty.Count -gt 20){
    Write-Output -InputObject "Property Count Test: Success!"
    Write-Output -InputObject "Property Count: $($NoteProperty.Count)"
} else {
    Write-Warning -Message "Test: Fail!"
    Write-Warning -Message "Property Count not correct: $($NoteProperty.Count)"
}
New-VariablesFromPSObject -inputObject $EnvironmentObject
If ($WeaveEnvironmentTest -eq $EnvironmentObject.WeaveEnvironmentName){
    Write-Output -InputObject "Value Test (WeaveEnvironment): Success!"
    Write-Output -InputObject "Value Test (WeaveEnvironment): $WeaveEnvironmentTest"
}else {
    Write-Warning -Message "Value Test(WeaveEnvironment): Failed!"
    Write-Warning -Message "Value Test(WeaveEnvironment): $WeaveEnvironmentTest"
}

$DeviceProfile = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Nodes\device.profiles.yaml" -yamlPath "main_devices"
Write-Output -InputObject "`nFile: device.profiles"
Write-Output -InputObject "Type: $($DeviceProfile.GetType().name)"
Write-Output -InputObject "Count: $($DeviceProfile.Count)"
If ((Test-IsDeviceProfile -ComputerName $ComputerName -DeviceProfile $DeviceProfile).IsProfile){
    Write-Output -InputObject "Test: Success!"
    Write-Output -InputObject "$ComputerName is Profiled: $((Test-IsDeviceProfile -ComputerName $ComputerName -DeviceProfile $DeviceProfile).IsProfile)"
}else {
    Write-Warning -Message "Test: Failed!"
    Write-Warning -Message "$ComputerName is not Profiled: $((Test-IsDeviceProfile -ComputerName $ComputerName -DeviceProfile $DeviceProfile).IsProfile)"
}

$namingConvention = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Nodes\naming.convention.yaml" -yamlPath "naming_convention"
Write-Output -InputObject "`nFile: naming.convention"
Write-Output -InputObject "Type: $($NamingConvention.GetType().name)"
Write-Output -InputObject "Count: $($NamingConvention.Count)"
$matchingConvention = $NamingConvention | Where-Object { $ComputerName -like "$($_.name)*" }
if ($matchingConvention ) {
    Write-Output -InputObject "Test if $ComputerName matches a naming convention: Success!"
    Write-Output -InputObject  "Name Matches $($matchingConvention.name)"
} else {
    Write-Warning -Message "Test: Failed!"
    Write-Warning -Message "Name like $ComputerName not found"
}
# Test for a non-matching instance
$nonMatchingConvention = $NamingConvention | Where-Object { 'notmatch' -like "$($_.name)*" }
if ($nonMatchingConvention) {
    Write-Warning -Message "Test for a non-matching instance: Failed! Unexpected matching instance found."
    Write-Warning -Message "Unexpected matching name: $($nonMatchingConvention.name)"
} else {
    Write-Output -InputObject "Test for a 'notmatch' instance: Success!"
    Write-Output -InputObject "No naming convention found that matches 'notmatch'."
}

$Nodes = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Nodes\nodes.yaml" -yamlPath "nodes"
Write-Output -InputObject "`nFile: nodes"
Write-Output -InputObject "Type: $($Nodes.GetType().name)"
Write-Output -InputObject "Count: $($Nodes.Count)"
$InNode = $Nodes | Where-Object {'ws11-001' -eq "$($_.name)"}
if ($InNode) {
    Write-Output -InputObject "Test if 'ws11-001' is a node: Success!"
    Write-Output -InputObject  "Name is in Nodes $($Nodes.name)"
} else {
    Write-Warning -Message "Test: Failed!"
    Write-Warning -Message "Name is not in Nodes $($Nodes.name)"
}

$ResourcesObject = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Resources\map.resources.yaml" -yamlPath "Resources.ResourcesList"
Write-Output -InputObject "`nFile: map.resources"
Write-Output -InputObject "Type: $($ResourcesObject.GetType())"
Write-Output -InputObject "Count: $($ResourcesObject.Count)"
$InResourceMap = $ResourcesObject | Where-Object {'Windows 10 Standard' -eq "$($_.name)"}
if ($InResourceMap) {
    Write-Output -InputObject "Test if 'Windows 10 Standard' is in file map.resources: Success!"
    Write-Output -InputObject  "'Windows 10 Standard' is in map.resources"
} else {
    Write-Warning -Message "Test: Failed!"
    Write-Warning -Message "Name is not in Nodes $($ResourcesObject.name)"
}

$reports = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Manifests\report.manifest.yaml" -yamlPath "Weave.threads.thread"
$reportmodules = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Manifests\report.manifest.yaml" -yamlPath "Weave.Modules"
Write-Output -InputObject "`nFile: report.manifest"
Write-Output -InputObject "Type: $($reports.GetType().name)"
Write-Output -InputObject "Count: $($reports.Count)"
Write-Output "Modules: $reportmodules"
$propertiesToExpand = @('description', 'descriptionpath', 'Path', 'Run', 'Arguments', 'PassparentSettings')
foreach ($report in $reports){
    Write-Output "`n-- $($report.title) --"
    Write-Output "Path(original): $($report.path)"
    Expand-VariablesInData -Data $report -PropertiesToExpand $propertiesToExpand
    Write-Output "Path(expanded): $($report.path)"
}

$threads = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Manifests\threads.manifest.yaml" -yamlPath "Weave.threads.thread"
$modules = New-ObjectFromYAML -yaml "$path\..\ExecutionConfig\Manifests\threads.manifest.yaml" -yamlPath "Weave.Modules"
Write-Output -InputObject "`nFile: threads.manifest"
Write-Output -InputObject "Type: $($threads.GetType().name)"
Write-Output -InputObject "Count: $($threads.Count)"
Write-Output "Modules: $($modules.'#text')"
Write-Output -InputObject "`n................................Threads ............................................"
$propertiesToExpand = @('description', 'descriptionpath', 'Path', 'Run', 'Arguments', 'PassparentSettings')
foreach ($thread in $threads) {
    Write-Output "`n-- $($thread.title) --"
    Write-Output "Path(original): $($thread.path)"
    Write-Output "Arguments(original): $($thread.Arguments)"
    Expand-VariablesInData -Data $thread -PropertiesToExpand $propertiesToExpand
    Write-Output "Path(expanded): $($thread.path)"
    Write-Output "Arguments(expanded): $($thread.Arguments)"
}

Write-Output -InputObject "`nFor More Detail run these commands"
Write-Output -InputObject '$Reports | Out-GridView'
Write-Output -InputObject '$Threads | Out-GridView'
Write-Output -InputObject '$Nodes | Out-GridView'
Write-Output -InputObject '$ResourcesObject | Out-GridView'
Write-Output -InputObject '$namingConventions | Out-GridView'
Write-Output -InputObject '$DeviceProfile | Out-GridView'
Write-Output -InputObject '$EnvironmentObject | Format-list'
Write-Output -InputObject '$MapObject | Format-list'

