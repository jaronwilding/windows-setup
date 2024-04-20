function Extract-Download {
    param (
        [string]$Folder,
        [string]$File
    )
    if (!(Test-Path -Path "$Folder" -PathType Container)) {
        Write-Error "$Folder does not exist!!!"
        Break
    }
    $Env:Path = $Env:Path + ";C:\Program Files\7-Zip"
    if (Test-Path -Path "$File" -PathType Leaf) {
        switch ($File.Split(".") | Select-Object -Last 1) {
            "rar" { Start-Process -FilePath "UnRar.exe" -ArgumentList "x","-op'$Folder'","-y","$File" -WorkingDirectory "$Env:ProgramFiles\WinRAR\" -Wait | Out-Null }
            "zip" { 7z x -o"$Folder" -y "$File" | Out-Null }
            "7z" { 7z x -o"$Folder" -y "$File" | Out-Null }
            "exe" { 7z x -o"$Folder" -y "$File" | Out-Null }
            Default { Write-Error "No way to Extract $File !!!"; Break }
        }
    }
}

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
    return $download_path
}

function Get-DownloadPath{
    param(
        [string]$fileName
    )
    $download_path = Get-TempDownloadsFolder
    $download_file = Join-Path $download_path $fileName
    return $download_file
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

function Get-DownloadW{
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
            # Invoke-WebRequest "$url" -OutFile $download_file
            Start-Process wget -ArgumentList "-O $download_file $url" -Wait
        }
    }
    end {
        return $download_file

    }
}

function Set-Privacy{
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Getting privacy settings."
    }
    process {
        # $download_path = Get-TempDownloadsFolder
        $shutup_10 = Get-DownloadPath "OOSU10.exe"
        $shutup_config = Get-DownloadPath "ooshutup10.cfg"

        If(!(Test-Path -Path $shutup_10)){
            Write-Verbose "Downloading Shutup10..."
            Invoke-WebRequest "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -OutFile $shutup_10
        }

        If(!(Test-Path -Path $shutup_config)){
            Write-Verbose "Downloading Shutup10 config file..."
            Invoke-WebRequest "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/ooshutup10.cfg" -OutFile $shutup_config
        }

        $shutup_10 = (Get-Download "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" "OOSU10.exe")
        $shutup_config = (Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/ooshutup10.cfg" "ooshutup10.cfg")

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
        $csvfile = Get-DownloadPath "defaultWindowsSettings.csv"

        If(!(Test-Path -Path $csvfile)){
            Write-Verbose "Downloading Default windows settings..."
            Invoke-WebRequest "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/defaultWindowsSettings.csv" -OutFile $csvfile
        }

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
        # Start-Process powershell -ArgumentList "$debloater" -Wait
        # powershell -command - < $debloater
        # powershell.exe "& $debloater"
        . $debloater

    }
    end {
        Write-Output "Debloated!"
    }
}

function Install-ApplicationsWinget {
    [CmdletBinding()]Param()
    begin {
        Write-Output "----------------------------"
        Write-Output "Installing via Winget..."
    }
    process {
        # Install winget
        $hasPackageManager = Get-AppPackage -name "Microsoft.DesktopAppInstaller"
        if(!$hasPackageManager){
            Add-AppxPackage -Path 'https://github.com/microsoft/winget-cli/releases/latest/download/Microsoft.DesktopAppInstaller_8wekyb3d8bbwe.msixbundle'
        }

        $WinGet = @(
            "Microsoft.DotNet.SDK.3_1",
            "Microsoft.DotNet.SDK.5",
            "Microsoft.DotNet.SDK.6",
            "Microsoft.DotNet.SDK.7",
            "Microsoft.DotNet.SDK.8",
            "Microsoft.WindowsTerminal",
            "Microsoft.PowerToys",
            "Microsoft.PowerShell",
            "Starship.Starship",
            "Docker.DockerDesktop",
            "chrisant996.Clink",
            "MediaArea.MediaInfo.GUI",
            "MediaArea.MediaInfo",
            "Git.Git",
            "GitHub.cli",
            "Piriform.Defraggler",
            "RARLab.WinRAR",
            "Mozilla.Firefox",
            "VideoLAN.VLC",
            "Discord.Discord",
            "Valve.Steam",
            "EpicGames.EpicGamesLauncher",
            "Ubisoft.Connect",
            "GOG.Galaxy",
            "ElectronicArts.EADesktop"

        )
        ForEach ($item in $WinGet) {
            Write-Verbose "Installing $item"
            Install-WinGetApp -PackageID "$item" | Out-Null
        }
    }
    end {
        Write-Output "Installed all Winget Applications"
    }
}

function Install-ApplicationsCustom {
    [CmdletBinding()]Param()
    begin {
        Write-Output "----------------------------"
        Write-Output "Installing via Custom..."
    }
    process {
        $tools_path = "C:\Custom\Tools\"
        $tweak_path = "C:\Custom\Tweaks\"
        $temp_path = Get-TempDownloadsFolder
        if (!(Test-Path -Path $tools_path)) {
            New-Item $tools_path -ItemType Directory | Out-Null
        }
        if (!(Test-Path -Path $tweak_path)) {
            New-Item $tweak_path -ItemType Directory | Out-Null
        }

        # -----------------------
        $zip7 = Get-Download "https://www.7-zip.org/a/7z2404-x64.msi" "7z2404-x64.msi"
        Write-Verbose "Installing 7zip"
        Start-Process 'msiexec.exe' -ArgumentList "/I $zip7 /qn" -Wait

        # -----------------------
        Write-Verbose "Installing FFMPEG"
        $ffmpeg = Get-Download "https://github.com/BtbN/FFmpeg-Builds/releases/download/latest/ffmpeg-master-latest-win64-gpl.zip" "ffmpeg-master-latest-win64-gpl.zip"
        Expand-Archive $ffmpeg -DestinationPath "$temp_path" -Force
        Copy-Item -Path "$temp_path\ffmpeg-master-latest-win64-gpl\bin\*.exe" -Destination "$tools_path"

        # -----------------------
        Write-Verbose "Installing Aria2C"
        $aria = Get-Download "https://github.com/aria2/aria2/releases/download/release-1.37.0/aria2-1.37.0-win-64bit-build1.zip" "aria.zip"
        Expand-Archive $aria -DestinationPath "$temp_path" -Force
        Copy-Item -Path "$temp_path\aria2-1.37.0-win-64bit-build1\*.exe" -Destination "$tools_path"

        # -----------------------
        Write-Verbose "Installing MKVToolNix"
        $mkvtoolnix = Get-Download "https://mkvtoolnix.download//windows/releases/83.0/mkvtoolnix-64-bit-83.0.7z" "mkvtoolnix-64-bit-83.0.7z"
        # Extract-Download $ffmpeg -DestinationPath "$temp_path" -Force
        Extract-Download -Folder "$temp_path" -File "$mkvtoolnix"
        $mkvtoolnix_items = @(
            "mkvextract.exe",
            "mkvinfo.exe",
            "mkvmerge.exe",
            "mkvpropedit.exe",
            "mkvtoolnix-gui.exe"
        )
        ForEach($item in $mkvtoolnix_items){
            Copy-Item -Path "$temp_path\mkvtoolnix\$item" -Destination "$tools_path" -Force
        }
        Copy-Item -Path "$temp_path\mkvtoolnix\tools" -Destination "$tools_path" -Force -Recurse

        # -----------------------
        Write-Verbose "Installing SharkCodecs"
        $shark_codecs = Get-Download "https://files1.majorgeeks.com/10afebdbffcd4742c81a3cb0f6ce4092156b4375/multimedia/Shark007Codecs.7z" "Shark007Codecs.7z"
        # Extract-Download $ffmpeg -DestinationPath "$temp_path" -Force
        Extract-Download -Folder "$tweak_path" -File "$shark_codecs"

    }
    end {
        Write-Output "Installed all Custom Applications"
    }
}

function Install-Managers {
    [CmdletBinding()]Param()
    begin {
        Write-Output "----------------------------"
        Write-Output "Installing Managers..."
    }
    process {
        $manager_path = "C:\Custom\Managers"
        If(!(Test-Path -Path $manager_path))
        {
            New-Item -ItemType Directory -Path $manager_path
        }

        $pyenv = Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/installers/install-pythonz.ps1" "install-pythonz.ps1"
        . "$pyenv"
        
        $golang = Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/installers/install-golang.ps1" "install-golang.ps1"
        . "$golang"

        $rustup = Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/installers/install-nim.ps1" "install-rustup.ps1"
        . "$rustup"

        $nim = Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/installers/install-nim.ps1" "install-nim.ps1"
        . "$nim"

        $nvm = Get-Download "https://github.com/jaronwilding/dotfiles/raw/main/windows10/installers/install-nvm.ps1" "install-nvm.ps1"
        . "$nvm"

    }
    end {
        Write-Output "Installed all Managers"
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
        # Install-ApplicationsWinget
        Install-ApplicationsCustom
        Install-Managers
        # Optimize-Settings
        # Set-Privacy
        # Enable-WinFeatures
    }
    end {
        Write-Output "Windows 10 has finished setting up."
        Write-Output "Advised to restart the machine now! :)"
    }
}

Optimize-Windows -Verbose