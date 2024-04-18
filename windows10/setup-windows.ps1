# function Expand-Download {
#     param (
#         [string]$Folder,
#         [string]$File
#     )
#     if (!(Test-Path -Path "$Folder" -PathType Container)) {
#         Write-Error "$Folder does not exist!!!"
#         Break
#     }
#     if (Test-Path -Path "$File" -PathType Leaf) {
#         switch ($File.Split(".") | Select-Object -Last 1) {
#             "rar" { Start-Process -FilePath "UnRar.exe" -ArgumentList "x","-op'$Folder'","-y","$File" -WorkingDirectory "$Env:ProgramFiles\WinRAR\" -Wait | Out-Null }
#             "zip" { 7z x -o"$Folder" -y "$File" | Out-Null }
#             "7z" { 7z x -o"$Folder" -y "$File" | Out-Null }
#             "exe" { 7z x -o"$Folder" -y "$File" | Out-Null }
#             Default { Write-Error "No way to Extract $File !!!"; Break }
#         }
#     }
# }

# Invoke-WebRequest "https://win.rustup.rs/x86_64"

function Set-Backup{
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Creating a restore point..."
    }
    process {
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS" -WhatIf
    }
    end {
        Write-Output "Restore point created!"
    }
}

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
    Else
    {
        Write-Debug "Folder already exists!"
    }
    return $download_path
}

function Set-Privacy{
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Getting privacy settings."
    }
    process {
        $download_path = Get-TempDownloadsFolder
        $shutup_10 = Join-Path $download_path "OOSU10.exe"
        $shutup_config = Join-Path $download_path "ooshutup10.cfg"

        If(!(Test-Path -Path $shutup_10)){
            Write-Verbose "Downloading Shutup10..."
            Invoke-WebRequest "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $shutup_10
        }

        If(!(Test-Path -Path $shutup_config)){
            Write-Verbose "Downloading Shutup10 config file..."
            Invoke-WebRequest "https://github.com/jaronwilding/dotfiles/blob/main/windows10/ooshutup10.cfg?raw=true" -OutFile $shutup_config
        }

        Write-Verbose "Running Shutup10 with pre-configured settings..."
        Start-Process -FilePath $shutup_10 -Verb RunAs -Wait -ArgumentList "$shutup_config", "/quiet"
    }
    end {
        Write-Output "Privacy settings finished."
    }
}

function Optimize-Settings {
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Adjusting settings..."
    }
    process {
        $download_path = Get-TempDownloadsFolder
        $csvfile = Join-Path $download_path "defaultsettings.csv"

        If(!(Test-Path -Path $csvfile)){
            Write-Verbose "Downloading custom settings CSV..."
            Invoke-WebRequest "https://github.com/jaronwilding/dotfiles/blob/main/windows10/defaultsettings.csv?raw=true" -OutFile $csvfile
        }

        $settingValues = Import-Csv $csvfile | ForEach-Object {
            [PSCustomObject]@{
                "path"          = $_.Path
                "key"           = $_.Key
                'value'         = $_.Value
                "propertytype"  = $_.Type
                'description'   = $_.description
            }
        }
        foreach($setting in $settingValues){
            Write-Verbose $setting.description
            New-ItemProperty -Path $setting.path -Name $setting.key -Value $setting.value -PropertyType $setting.propertytype -Force
        }

        $service =  @(
            'DiagTrack'
        )
        foreach ($serviceName in $services) {
            if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
                Write-Verbose "Service $serviceName exists. Disabling service..."
                New-ItemProperty -Path "HKLM\SYSTEM\CurrentControlSet\Services\$serviceName" -Name Start -Value $4 -PropertyType DWORD -Force
                Stop-Service $serviceName -Force
                $process = Get-Process -Name $serviceName -ErrorAction SilentlyContinue
                if ($process) {
                    Write-Verbose "Process with PID $($process.Id) exists. Killing process..."
                    Stop-Process -Id $process.Id -Force
                }
                sc stop $serviceName
            } else {
                Write-Debug "Service $serviceName does not exist."
            }
        }

    }
    end {
        Write-Verbose "Settings have been adjusted."
    }
}

function Optimize-Windows {
    [CmdletBinding()]Param()
    begin {
        Write-Output "Initializing Windows 10..."
    }
    process {
        Set-Backup
        Optimize-Settings
        Set-Privacy
    }
    end {
        Write-Output "Windows 10 has finished setting up."
        Write-Output "Advised to restart the machine now! :)"
    }
}

Optimize-Windows
