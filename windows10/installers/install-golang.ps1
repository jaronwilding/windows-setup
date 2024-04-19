<#
    .SYNOPSIS
    Installs Golang

    .DESCRIPTION
    Installs Golang to C:\Custom\Managers\rust\cargo and C:\Custom\Managers\rust\rustup
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
        Write-Output "Installing Golang"
    }
    process {
        $releases_url = "https://go.dev/dl/?mode=json"
        $releases = Invoke-WebRequest -uri $releases_url | ConvertFrom-Json | Select-Object -First 1
        $latestRelease = $releases.files | Where-Object { $_.filename.EndsWith(".windows-amd64.msi")} | Select-Object -First 1
        $golang_url = $latestRelease.filename
        $golang = Get-Download "https://go.dev/dl/$golang_url" "$golang_url"
        Write-Verbose "Installing Golang"
        Start-Process 'msiexec.exe' -ArgumentList "/I $golang INSTALLDIR=C:\Custom\Managers\Golang /qn" -Wait
    }
    end {
        Write-Output "Golang Installed"
    }
}

Main

