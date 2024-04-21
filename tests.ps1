
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
            Invoke-WebRequest -Uri $Url -OutFile $DownloadFile -Force -Resume
        }

        return $DownloadFile
    }
}


function Install-ApplicationsWinget {
    <#
    .SYNOPSIS
        Installs the Winget application, and then all corresponding applications.

    .DESCRIPTION
        Makes use of the hard-coded URL to a json list object. Alternatively a path to a json file can be passed as the first input,
        and it will utilize the id's in there to install.

    .PARAMETER WingetConfig
        The path to a standalone json object to run the installer against.

    .INPUTS
        Accepts the standard arguments, such as -Verbose

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $false, Position = 0)]
        [string]
        $WingetConfig
    )
    begin {
        Write-Output "----------------------------"
        Write-Output "Installing via Winget..."
    }
    process {
        # Install winget
        # Assume that Winget is installed if over version 5, as I cannot get around this stupid issue.
        # Issue: https://github.com/PowerShell/PowerShell/issues/19031
        if ($PSVersionTable.PSVersion.Major -le 5) {
            Import-Module Appx
            $hasPackageManager = Get-AppPackage -name "Microsoft.DesktopAppInstaller"
            if(!$hasPackageManager) {
                Add-AppxPackage -Path 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
            }
        }

        if (!$WingetConfig) {
            $Packages = Invoke-WebRequest -Uri "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/winget/config-winget.json" | ConvertFrom-Json
        } else {
            $Packages = Get-Content -Path $WingetConfig -Raw | ConvertFrom-Json
        }
        
        foreach ($Package in $Packages) {
            Write-Verbose "Installing $Package"
            Start-Process "winget" -ArgumentList "install --silent --id $Package --accept-source-agreements --accept-package-agreements" -Wait -NoNewWindow -WhatIf
        }
    }
    end {
        Write-Output "Installed all Winget Applications"
    }
}

Install-ApplicationsWinget