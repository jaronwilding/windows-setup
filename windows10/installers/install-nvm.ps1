<#
    .SYNOPSIS
    Installs NVM

    .DESCRIPTION
    Installs NVM to C:\Custom\Managers\nvm
    If already installed, will skip.
#>
function Get-TempDownloadsFolder{
    #Variable
    $parent = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path # Get the downloads folder
    $download_path = Join-Path $parent "temp"
    #Check if Folder exists
    If(!(Test-Path -Path $download_path))
    {
        #powershell create directory
        New-Item -ItemType Directory -Path $download_path
        Write-Debug "New folder created successfully!"
    }
    return $download_path
}

function Get-Download{
    param(
        [string]$url,
        [string]$fileName
    )
    begin {
        Write-Host "URL: $url"
        Write-Host "Filename: $fileName"
        $download_path = Get-TempDownloadsFolder
        $download_file = Join-Path $download_path $fileName
    }
    process {
        If(!(Test-Path -Path $download_file)){
            Write-Verbose "Downloading $fileName"
            Invoke-WebRequest "$url" -OutFile $download_file
        }
    }
    end {
        return $download_file
    }
}

Function Main() {
    [CmdletBinding()]Param()
    begin {
        Write-Output "Installing NVM"
    }
    process {
        $nvm = Get-Download "https://github.com/coreybutler/nvm-windows/releases/latest/download/nvm-noinstall.zip" "nvm-noinstall.zip"
        Expand-Archive $nvm -DestinationPath "C:\Custom\Managers\nvm" -Force

        [System.Environment]::SetEnvironmentVariable('NVM_HOME', "C:\Custom\Managers\nvm\", [System.EnvironmentVariableTarget]::User)
        [System.Environment]::SetEnvironmentVariable('NVM_SYMLINK', "C:\Custom\Managers\nodejs\", [System.EnvironmentVariableTarget]::User)
        [Environment]::SetEnvironmentVariable(
            "Path",
            [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";%NVM_HOME%;%NVM_SYMLINK%",
            [EnvironmentVariableTarget]::User)

        $settings_file = "C:\Custom\Managers\nvm\settings.txt"
        New-Item "C:\Custom\Managers\nvm\settings.txt" -Force | Out-Null
        Add-Content -Path $settings_file -Value "root: C:\Custom\Managers\nvm"
        Add-Content -Path $settings_file -Value "path: C:\Custom\Managers\nodejs"
        Add-Content -Path $settings_file -Value "arch: 64"
        Add-Content -Path $settings_file -Value "proxy: none"

    }
    end {
        Write-Output "NVM Installed"
    }
}
Main
