<#
    .SYNOPSIS
        A bootstrapper for windows 10 installs.

    .DESCRIPTION
        Creates a restore point, then will download configuration files from the repo and run them.
        This includes registry tweaks, program uninstalls, program installs, power options, debloating,
        and version managers for specific programs.
#>

class RegisterOptions 
{
    [string] $BaseUrl
    [System.Collections.Generic.List[string]] $Files
}

# TODO: Fix this
function Expand-CustomArchive {
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
            "rar" { 
                Start-Process -FilePath "UnRar.exe" -ArgumentList "x","-op'$Folder'","-y","$File" -WorkingDirectory "$Env:ProgramFiles\WinRAR\" -Wait | Out-Null 
            }
            "zip" { 
                7z x -o"$Folder" -y "$File" | Out-Null 
            }
            "7z" { 
                7z x -o"$Folder" -y "$File" | Out-Null 
            }
            "exe" { 
                7z x -o"$Folder" -y "$File" | Out-Null 
            }
            Default { Write-Error "No way to Extract $File !!!"; Break }
        }
    }
}

function Backup-Computer{
    <#
    .SYNOPSIS
        Wrapper for two function calls to creating a restore point.

    .DESCRIPTION
       Makes use of Enable-ComputerRestore to make sure that creation of a restore point won't error out.
       Then makes use of Checkpoint-Computer and creates a custom restore point called "RestorePoint1".

    .INPUTS
        Accepts the standard arguments, such as -Verbose

    #>
    [CmdletBinding()]
    param()
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

    .PARAMETER UseCurl
        Whether to use Curl or not by default. Defaults to true

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
        [string]$FileName,

        [Parameter(Mandatory = $false)]
        [string]$UseCurl = $true
    )
    process {
        $DownloadPath = Get-TemporaryDownloadsFolder
        $DownloadFile = Join-Path $DownloadPath $FileName
        
        if($UseCurl -eq $false) {
            Write-Verbose "Downloading $FileName using standard Powershell cmdlets"
            Invoke-WebRequest -Uri $Url -OutFile $DownloadFile -Resume

            return $DownloadFile
        }

        try {
            Write-Verbose "Downloading $FileName using Curl"
            Start-Process "curl.exe" -ArgumentList "--no-progress-meter -o $DownloadFile $Url" -Wait -NoNewWindow
        }
        catch {
            Write-Verbose "Downloading $FileName using standard Powershell cmdlets"
            Invoke-WebRequest -Uri $Url -OutFile $DownloadFile -Resume
        }

        return $DownloadFile
    }
}

# TODO: Fix this
function Set-Privacy{
    [CmdletBinding()]Param()
    begin {
        Write-Output "--------------------------------------------------------"
        Write-Output "Getting privacy settings."
    }
    process {
        $ShutUp10 = Get-Download -Url "https://dl5.oo-software.com/files/ooshutup10/OOSU10.exe" -FileName "OOSU10.exe"
        $ShutUpConfig = Get-Download -Url "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/ooshutup10.cfg" -FileName "ooshutup10.cfg"

        Write-Verbose "Running Shutup10 with pre-configured settings..."
        Start-Process -FilePath $ShutUp10 -ArgumentList "$ShutUpConfig /quiet" -Verb RunAs -Wait
    }
    end {
        Write-Output "Privacy settings finished."
    }
}

# TODO: Fix this
function Set-RegistryOptions {
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
        Write-Output "Installing registry tweaks..."
    }
    process {
        $RegistryOptions = [RegisterOptions](Invoke-WebRequest -Uri "https://github.com/jaronwilding/dotfiles/raw/main/windows10/config/registry/config-registry.json" | ConvertFrom-Json)
        $Url = $RegistryOptions.BaseUrl
        
        $progress = 1
        # $progress_percent = ($progress / ($RegistryOptions.Files.Count)) * 100
        Write-Progress -Activity "Installing Registry Tweaks" -Status "Initalizing" -Id 1 -PercentComplete (($progress / ($RegistryOptions.Files.Count)) * 100)
        foreach ($File in $RegistryOptions.Files) {
            $Url = (@($RegistryOptions.BaseUrl, $File) | ForEach-Object {$_.trim('/')}) -join '/'
            $DownloadedFile = Get-Download -Url $Url -FileName $File -UseCurl $false
            Write-Verbose "$File downloaded, loading..."
            Invoke-Command {reg import $DownloadedFile *>&1 | Out-Null}
        }
    }
    end {
        Write-Output "Installed all Registry tweaks"
    }
}

# TODO: Fix this
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

# TODO: Fix this
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

# TODO: Fix this
function Install-ApplicationsCustom {
    [CmdletBinding()]Param()
    begin {
        Write-Output "----------------------------"
        Write-Output "Installing via Custom..."
    }
    process {
        $tools_path = "C:\Custom\Tools\"
        $tweak_path = "C:\Custom\Tweaks\"
        $temp_path = Get-TemporaryDownloadsFolder
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
        $mkvtoolnix = Get-Download "https://mkvtoolnix.download/windows/releases/83.0/mkvtoolnix-64-bit-83.0.7z" "mkvtoolnix-64-bit-83.0.7z"
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

# TODO: Fix this
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
        Set-RegistryOptions
        Set-Privacy
        Remove-PreinstalledApplications
        Enable-WinFeatures
        Install-ApplicationsWinget
        Install-ApplicationsCustom
        # Install-Managers
    }
    end {
        Write-Output "Windows 10 has finished setting up."
        Write-Output "Advised to restart the machine now! :)"
    }
}

Optimize-Windows -Verbose