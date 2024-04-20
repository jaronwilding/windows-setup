<#
    .SYNOPSIS
        Installs NVM

    .DESCRIPTION
        Installs NVM to C:\Custom\Managers\nvm
        If already installed, will skip.
#>

function Get-TemporaryDownloadsFolder {
    <#
    .SYNOPSIS
        Creates and returns the temporary folder to download items too.
        
    .DESCRIPTION
        Makes a directory of "temp" in the users Downloads folder, and returns the path.

    .INPUTS
        Accepts the standard arguments, such as -Verbose
        
    .OUTPUTS
        Path to the temporary folder located in the Downloads directory.
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param()   
    process {
        $Parent = (New-Object -ComObject Shell.Application).NameSpace('shell:Downloads').Self.Path # Get the downloads folder
        $TemporaryPath = Join-Path $Parent "temp"

        if ( !(Test-Path -Path $TemporaryPath) ) {
            Write-Verbose "Creating custom path at: $TemporaryPath"
            New-Item -Path $TemporaryPath -ItemType Directory -ErrorAction SilentlyContinue | Out-Null
        }

        return $TemporaryPath
    }
}

function Get-Download {
    <#
    .SYNOPSIS
        Downloads the corresponding url to the given filename.
    
    .DESCRIPTION
        Downloads the file given to the temporary path. Relies on the Get-TemporaryDownloadsFolder cmdlet.
        It will use curl.exe to start, and fall back to Invoke-WebRequest I.E. wget if that fails.

    .PARAMETER Url
        The direct-link URL to download from.

    .PARAMETER FileName
        The name to call the downloaded file.

    .INPUTS
        Accepts the standard arguments, such as -Verbose

    .OUTPUTS
        Path to the temporary folder located in the Downloads directory.

    .EXAMPLE
        Get-Download -Url "https://nim-lang.org/download/nim-2.0.4_x64.zip" -FileName "nim.zip" -Verbose
        Get-Download "https://nim-lang.org/download/nim-2.0.4_x64.zip" "nim.zip" -Verbose
        
    #>
    [CmdletBinding()]
    [OutputType([string])]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Url,

        [Parameter(Mandatory = $true)]
        [string]$FileName
    )
    process {
        $DownloadPath = Get-TemporaryDownloadsFolder
        $DownloadFile = Join-Path $DownloadPath $FileName
        try {
            Write-Verbose "Downloading $FileName using Curl"
            Start-Process "curl.exe" -ArgumentList "--no-progress-meter -o $DownloadFile $Url" -Wait -NoNewWindow
        }
        catch {
            Write-Verbose "Downloading $FileName using standard Powershell cmdlets"
            Invoke-WebRequest -Uri $Url -OutFile $DownloadFile -Force
        }

        return $DownloadFile
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
