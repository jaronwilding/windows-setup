# Basically just install two programs: Git, and Chezmoi
winget install --silent --id "Git.Git" --accept-source-agreements --accept-package-agreements
winget install --silent --id "twpayne.chezmoi" --accept-source-agreements --accept-package-agreements

$env:Path = [System.Environment]::GetEnvironmentVariable("Path","Machine")
$env:Path += ";" + [System.Environment]::GetEnvironmentVariable("Path","User")  

chezmoi init --apply jaronwilding
