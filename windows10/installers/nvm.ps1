Write-Verbose "Installing NVM"
$nvm = Get-Download "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-noinstall.zip" "nvm-noinstall.zip"
Expand-Archive $nvm -DestinationPath "C:\Custom\Managers\nvm" -Force

[System.Environment]::SetEnvironmentVariable('NVM_HOME', "C:\Custom\Managers\nvm\", [System.EnvironmentVariableTarget]::User)
[System.Environment]::SetEnvironmentVariable('NVM_SYMLINK', "C:\Custom\Managers\nodejs\", [System.EnvironmentVariableTarget]::User)
[Environment]::SetEnvironmentVariable(
    "Path",
    [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";%NVM_HOME%;%NVM_SYMLINK%",
    [EnvironmentVariableTarget]::User)
        
$settings_file = "C:\Custom\Managers\nvm\settings.txt"
New-Item "C:\Custom\Managers\nvm\settings.txt" | Out-Null
Add-Content -Path $settings_file -Value "root: C:\Custom\Managers\nvm"
Add-Content -Path $settings_file -Value "path: C:\Custom\Managers\nodejs"
Add-Content -Path $settings_file -Value "arch: 64"
Add-Content -Path $settings_file -Value "proxy: none"
