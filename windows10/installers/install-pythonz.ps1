<#
    .SYNOPSIS
    Installs Python versions

    .DESCRIPTION
    Installs Python versions to C:\Custom\Managers\Pythonz
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
        Write-Output "Installing Python versions"
    }
    process {
        $root_path = "C:\Custom\Managers\Pythonz"
        $pythonz = @(
            @{
                Url = "https://www.python.org/ftp/python/3.7.9/python-3.7.9-amd64.exe"
                Name = "python-3.7.9-amd64.exe"
                Destination = "$root_path\Python37"
            },
            @{
                Url = "https://www.python.org/ftp/python/3.9.13/python-3.9.13-amd64.exe"
                Name = "python-3.9.13-amd64.exe"
                Destination = "$root_path\Python39"
            },
            @{
                Url = "https://www.python.org/ftp/python/3.12.3/python-3.12.3-amd64.exe"
                Name = "python-3.12.3-amd64.exe"
                Destination = "$root_path\Python312"
            },
            @{
                Url = "https://www.python.org/ftp/python/3.11.9/python-3.11.9-amd64.exe"
                Name = "python-3.11.9-amd64.exe"
                Destination = "$root_path\Python311"
            }
        )
        
        foreach($py in $pythonz){
            $py_app = Get-Download $py.Url $py.Name
            $dest = $py.Destination
            if (!(Test-Path -Path "$dest" -PathType Container)) {
                Start-Process $py_app -ArgumentList "/passive InstallAllUsers=1 TargetDir=$dest Include_launcher=0" -Wait
            }
        }
    }
    end {
        Write-Output "All Python versions Installed"
    }
}

Main

