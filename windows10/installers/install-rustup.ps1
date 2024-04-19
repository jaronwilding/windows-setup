<#
    .SYNOPSIS
    Installs Rustup

    .DESCRIPTION
    Installs Rustup to C:\Custom\Managers\rust\cargo and C:\Custom\Managers\rust\rustup
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
        Write-Output "Installing Rustup"
    }
    process {
        $rust_dir = "C:\Custom\Managers\rust"
        $rustup = Get-Download "https://static.rust-lang.org/rustup/dist/x86_64-pc-windows-msvc/rustup-init.exe" "rustup-init.exe"
        [System.Environment]::SetEnvironmentVariable('CARGO_HOME', "$rust_dir\cargo\", [System.EnvironmentVariableTarget]::User)
        [System.Environment]::SetEnvironmentVariable('RUSTUP_HOME', "$rust_dir\rustup\", [System.EnvironmentVariableTarget]::User)
        $env:CARGO_HOME  = "$rust_dir\cargo\"
        $env:RUSTUP_HOME = "$rust_dir\rustup\"
        Write-Verbose "Installing Rustup"
        Start-Process $rustup -ArgumentList "-q -y" -Wait
    }
    end {
        Write-Output "Rustup Installed"
    }
}

Main

