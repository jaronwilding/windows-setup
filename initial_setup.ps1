# Basically just install two programs: Git, and Chezmoi
winget install --silent --id "Git.Git" --accept-source-agreements --accept-package-agreements
winget install --silent --id "twpayne.chezmoi" --accept-source-agreements --accept-package-agreements

$waitTimeMilliseconds = 1 * 60 * 1000 # Just wait one minute.

$process = Start-Process "powershell.exe" -NoNewWindow -ArgumentList ("-ExecutionPolicy Bypass -noninteractive -noprofile chezmoi init --apply jaronwilding") -PassThru
$process.WaitForExit($waitTimeMilliseconds)
