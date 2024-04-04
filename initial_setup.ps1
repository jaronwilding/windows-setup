# Basically just install two programs: Git, and Chezmoi
winget install --silent --id "Git.Git" --accept-source-agreements --accept-package-agreements
winget install --silent --id "twpayne.chezmoi" --accept-source-agreements --accept-package-agreements


Invoke-Command { & "chezmoi init --apply jaronwilding" } -NoNewScope
