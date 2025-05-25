#Requires -RunAsAdministrator
<#
    .SYNOPSIS
        Installs Golang

    .DESCRIPTION
        Installs Golang to C:\Custom\Managers\rust\cargo and C:\Custom\Managers\rust\rustup
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
            # Start-Process "curl.exe" -ArgumentList "--no-progress-meter -o $DownloadFile $Url" -Wait -NoNewWindow
            & curl.exe --fail --location -o $DownloadFile $Url
            if ($LASTEXITCODE -ne 0) {
                throw "Curl failed with exit code $LASTEXITCODE"
            }
            if ((Get-Item $DownloadFile).Length -lt 200) {
                throw "Downloaded file appears too small. Something went wrong."
            }
        }
        catch {
            Write-Verbose "Downloading $FileName using standard Powershell cmdlets"
            Invoke-WebRequest -Uri $Url -OutFile $DownloadFile -Force
        }

        return $DownloadFile
    }
}

function Install-Golang() {
    [CmdletBinding()]
    param()
    begin {
        Write-Output "Installing Golang"
    }
    process {
        $releases_url = "https://go.dev/dl/?mode=json"
        $releases = Invoke-WebRequest -uri $releases_url | ConvertFrom-Json | Select-Object -First 1
        $latestRelease = $releases.files | Where-Object { $_.filename.EndsWith(".windows-amd64.msi")} | Select-Object -First 1
        $golang_url = $latestRelease.filename
        $golang = Get-Download "https://go.dev/dl/$golang_url" "$golang_url"
        Write-Debug "Golang URL: https://go.dev/dl/$golang_url"
        Write-Debug "Golang Downloaded: $golang"
        Write-Verbose "Installing Golang"
        Start-Process 'msiexec.exe' -ArgumentList "/I $golang INSTALLDIR=C:\Custom\Managers\Golang /qn" -Wait
    }
    end {
        Write-Output "Golang Installed"
    }
}
