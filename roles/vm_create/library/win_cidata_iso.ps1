#!powershell
#AnsibleRequires -CSharpUtil Ansible.Basic

$spec = @{
    options = @{
        path = @{ type = "path"; required = $true }
        meta_data = @{ type = "str"; required = $false }
        network_config = @{ type = "str"; required = $false }
        user_data = @{ type = "str"; required = $false }
    }
    # TODO supports_check_mode = $true
}

$module = [Ansible.Basic.AnsibleModule]::Create($args, $spec)

Set-StrictMode -Version Latest
$ErrorActionPreference = 'Stop'
$ProgressPreference = 'SilentlyContinue'

[System.Reflection.Assembly]::LoadWithPartialName('Microsoft.InternationalSettings.Commands') | Out-Null

$path = $module.Params.path
$metaData = $module.Params.meta_data
$networkConfig = $module.Params.network_config
$userData = $module.Params.user_data

$module.Result.path = $path

# TODO when the iso already exists, verify if it needs to be recreated.
if (Test-Path $path) {
    # TODO if the file is being used (e.g. vm is running), this will fail.
    $module.ExitJson()
    Exit 0
    Remove-Item -Force $path
}
$tmpPath = "$path.tmp"
if (Test-Path $tmpPath) {
    Remove-Item -Recurse -Force $tmpPath
}
mkdir "$tmpPath\cidata" | Out-Null
New-Item -Path "$tmpPath\cidata\meta-data" -Value $metaData | Out-Null
New-Item -Path "$tmpPath\cidata\network-config" -Value $networkConfig | Out-Null
New-Item -Path "$tmpPath\cidata\user-data" -Value $userData | Out-Null
$wasmtimePath = (Get-Command wasmtime.exe).Path
$hadrisIsoCliWasmPath = "$(Split-Path -Parent $wasmtimePath)\hadris-iso-cli.wasm"
$output = &$wasmtimePath `
    run `
    --dir "$tmpPath::/cidata" `
    $hadrisIsoCliWasmPath `
    create `
    --joliet `
    --rock-ridge `
    --volume-name cidata `
    --volume-set-id "TODO" `
    --output /cidata/cidata.iso `
    /cidata/cidata
if ($LASTEXITCODE) {
    $module.FailJson("failed to create iso with exit code $($exitCode): $output")
    Exit 1
}
Move-Item "$tmpPath\cidata.iso" $path
Remove-Item -Recurse -Force $tmpPath

$module.Result.changed = $true
$module.ExitJson()
