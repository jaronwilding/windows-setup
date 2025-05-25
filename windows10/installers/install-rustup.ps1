<#
    .SYNOPSIS
        Installs Rustup

    .DESCRIPTION
        Installs Rustup to C:\Custom\Managers\rust\cargo and C:\Custom\Managers\rust\rustup
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

function Set-PersistantEnvironmentVariable {
    <#
    .SYNOPSIS
        Sets a persistent environment variable for the user.
    
    .DESCRIPTION
        Sets a persistent environment variable for the user. This is done using setx, which is a built-in Windows command.
        It will set the variable to the given value, and will persist across sessions.

    .PARAMETER Name
        The name of the environment variable to set.

    .PARAMETER Value
        The value to set the environment variable to.

    .INPUTS
        Accepts the standard arguments, such as -Verbose

    .OUTPUTS
        None

    #>
    [CmdletBinding()]
    param (
        [Parameter(Mandatory = $true)]
        [string]$Name,

        [Parameter(Mandatory = $true)]
        [string]$Value,

        [Parameter(Mandatory = $false)]
        [switch]$MachineScope
    )
    process {
        Write-Verbose "Setting environment variable $Name to $Value"
        if ($MachineScope) {
            setx $Name $Value /M | Out-Null
        } else {
            setx $Name $Value | Out-Null
        }
    }
}

function Install-Rustup() {
    <#
    .SYNOPSIS
        Installs Rustup

    .DESCRIPTION
        Installs Rustup to C:\Custom\Managers\rust\cargo and C:\Custom\Managers\rust\rustup

    .EXAMPLE
        Install-Rustup -Verbose
    #>
    [CmdletBinding()]Param()
    begin {
        Write-Output "Installing Rustup"
    }
    process {
        # Sanity check to see if rustup is already installed
        # If it is, we will skip the installation and just update it.
        if (Get-Command rustup -ErrorAction SilentlyContinue) {
            Write-Warning "Rust is already installed, running rustup update..."
            rustup update
            return
        }

        $rust_dir = "C:\Custom\Managers\rust"
        $rustup_dir = "$rust_dir\rustup"
        $cargo_dir = "$rust_dir\cargo"

        $rustup = Get-Download "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" "rustup-init.exe"
        
        Set-PersistantEnvironmentVariable -Name "CARGO_HOME" -Value $cargo_dir -Verbose
        Set-PersistantEnvironmentVariable -Name "RUSTUP_HOME" -Value $rustup_dir -Verbose

        Write-Verbose "Installing Rustup to $rustup_dir using $rustup"
        Start-Process $rustup -ArgumentList "-q -y" -Wait
    }
    end {
        Write-Output "Rustup Installed"
    }
}