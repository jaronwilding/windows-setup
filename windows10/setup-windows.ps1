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
        Enable-ComputerRestore -Drive "C:\"
        Checkpoint-Computer -Description "RestorePoint1" -RestorePointType "MODIFY_SETTINGS"
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

function Get-Download{
    param(
        [string]$url,
        [string]$fileName
    )
    $download_path = Get-TempDownloadsFolder
    $download_file = Join-Path $download_path $fileName
    If(!(Test-Path -Path $download_file)){
        Write-Verbose "Downloading $fileName..."
        Invoke-WebRequest "$url" -OutFile $download_file -Wait
    }
    return $download_file
}

function Set-Privacy{
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Getting privacy settings."
    }
    process {
        # $download_path = Get-TempDownloadsFolder
        # $shutup_10 = Join-Path $download_path "OOSU10.exe"
        # $shutup_config = Join-Path $download_path "ooshutup10.cfg"

        # If(!(Test-Path -Path $shutup_10)){
        #     Write-Verbose "Downloading Shutup10..."
        #     Invoke-WebRequest "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $shutup_10
        # }

        # If(!(Test-Path -Path $shutup_config)){
        #     Write-Verbose "Downloading Shutup10 config file..."
        #     Invoke-WebRequest "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/ooshutup10.cfg" -OutFile $shutup_config
        # }

        $shutup_10 = Get-Download "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" "OOSU10.exe"
        $shutup_config= Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/ooshutup10.cfg" "ooshutup10.cfg"

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
        $csvfile = Join-Path $download_path "defaultWindowsSettings.csv"

        If(!(Test-Path -Path $csvfile)){
            Write-Verbose "Downloading custom settings CSV..."
            
            Invoke-WebRequest 'https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/defaultWindowsSettings.csv' -OutFile $csvfile
        }

        $csvfile = Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/defaultWindowsSettings.csv" "defaultWindowsSettings.csv"

        $settingValues = Import-Csv $csvfile | ForEach-Object {
            [PSCustomObject]@{
                "path"          = $_.Path
                "key"           = $_.Key
                'value'         = $_.Value
                "propertytype"  = $_.PropertyType
                'description'   = $_.description
            }
        }
        ForEach($setting in $settingValues){
            Write-Verbose $setting.description
            If(!(Test-Path -Path $setting.path)) {
                New-Item -Path $setting.path | Out-Null
            }
            New-ItemProperty -Path $setting.path -Name $setting.key -Value $setting.value -PropertyType $setting.propertytype -Force | Out-Null
        }

        $services =  @(
            'DiagTrack'
        )
        ForEach ($serviceName in $services) {
            if (Get-Service -Name $serviceName -ErrorAction SilentlyContinue) {
                Write-Verbose "Service $serviceName exists. Disabling service..."
                New-ItemProperty -Path "HKLM:\SYSTEM\CurrentControlSet\Services\$serviceName" -Name Start -Value $4 -PropertyType DWORD -Force | Out-Null
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

function Enable-WinFeatures{
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Enabling specific windows features"
    }
    process {
        $features = @(
                "NetFx3",
                "WCF-Services45",
                "WCF-TCP-PortSharing45",
                "MediaPlayback",
                "WindowsMediaPlayer",
                "SmbDirect",
                "Printing-PrintToPDFServices-Features",
                "Printing-XPSServices-Features",
                "SearchEngine-Client-Package",
                "MSRDC-Infrastructure",
                "Microsoft-SnippingTool",
                "Microsoft-RemoteDesktopConnection",
                "WorkFolders-Client",
                "Printing-Foundation-Features",
                "Printing-Foundation-InternetPrinting-Client",
                "MicrosoftWindowsPowerShellV2Root",
                "MicrosoftWindowsPowerShellV2",
                "NetFx4-AdvSrvs",
                "Internet-Explorer-Optional-amd64",
                "Microsoft-Windows-Subsystem-Linux",
                "HypervisorPlatform",
                "VirtualMachinePlatform",
                "Containers-DisposableClientVM",
                "Microsoft-Hyper-V-All",
                "Microsoft-Hyper-V",
                "Microsoft-Hyper-V-Tools-All",
                "Microsoft-Hyper-V-Management-PowerShell",
                "Microsoft-Hyper-V-Hypervisor",
                "Microsoft-Hyper-V-Services",
                "Microsoft-Hyper-V-Management-Clients"
            )
        ForEach($feature in $features)
        {
            Write-Verbose "Enabling feature: $feature"
            Enable-WindowsOptionalFeature -Online -FeatureName $feature -NoRestart | Out-Null
        }
    }
    end {
        
        Write-Output "Windows features have been enabled"
    }
}

function Install-WinGetApp {
    param (
        [string]$PackageID
    )
    begin {
        Write-Verbose -Message "Preparing to install $PackageID"
    }
    process {
        Write-Verbose -Message "Installing $Package"
        winget install --silent --id "$PackageID" --accept-source-agreements --accept-package-agreements
    }
    end {
        Write-Verbose -Message "Installing $Package"
    }
}

function Remove-PreinstalledApplications{
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Uninstalling bloatware applications..."
    }
    process {
        Write-Verbose "Downloading and using the script from Scynex!"
        $debloater = Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/Windows10SysPrepDebloater.ps1" "Windows10SysPrepDebloater.ps1"
        . $debloater
        Write-Host "$debloater Sourced"
    }
    end {
        Write-Output "Debloated!"
    }
}

function Install-Applications {
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Installing 3rd-Party tools..."
    }
    process {
        $WinGet = @(
            "Microsoft.DotNet.SDK.3_1",
            "Microsoft.DotNet.SDK.5",
            "Microsoft.DotNet.SDK.6",
            "Microsoft.DotNet.SDK.7",
            "Microsoft.DotNet.SDK.8",
            "Microsoft.WindowsTerminal",
            "Microsoft.PowerToys",
            "Microsoft.PowerShell",
            "VideoLAN.VLC",
            "Discord.Discord",
            "Valve.Steam",
            "Starship.Starship",
            "chrisant996.Clink",
            "Mozilla.Firefox",
            "Piriform.Defraggler"
        )
        ForEach ($item in $WinGet) {
            Install-WinGetApp -PackageID "$item"
        }
    }
    end {
        Write-Output "Windows 10 has finished setting up."
        Write-Output "Advised to restart the machine now! :)"
    }
}


function Optimize-Windows {
    [CmdletBinding()]Param()
    begin {
        Write-Output "Initializing Windows 10..."
    }
    process {
        # Set-Backup
        Remove-PreinstalledApplications
        # Install-Application
        Optimize-Settings
        # Set-Privacy
        # Enable-WinFeatures
    }
    end {
        Write-Output "Windows 10 has finished setting up."
        Write-Output "Advised to restart the machine now! :)"
    }
}

Optimize-Windows
