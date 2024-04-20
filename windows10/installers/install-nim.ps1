<#
    .SYNOPSIS
    Installs Nim

    .DESCRIPTION
    Installs Nim to C:\Custom\Managers\nim
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
        Write-Output "Installing NIM"
    }
    process {
        $temp_path = Get-TempDownloadsFolder
        # I don't like this, but it's the best I've got for now. Maybe later I'll fix it to get proper
        $nim_releases = "https://api.github.com/repos/nim-lang/Nim/releases"
        $nim_dir = "C:\Custom\Managers\nim"
        $nim = Get-Download "https://nim-lang.org/download/nim-2.0.4_x64.zip" "nim.zip"
        
        Expand-Archive $nim -DestinationPath $temp_path -Force
        Copy-Item -Path "$temp_path\nim*" -Destination "$nim_dir" -Recurse
        [Environment]::SetEnvironmentVariable(
            "Path",
            [Environment]::GetEnvironmentVariable("Path", [EnvironmentVariableTarget]::User) + ";$nim_dir\bin",
            [EnvironmentVariableTarget]::User)

    }
    end {
        Write-Output "NIM Installed"
    }
}

Main

