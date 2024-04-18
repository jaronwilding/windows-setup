# Setup for all my workstations

## Windows 10 guide

It's advised that when you first install Windows 10, to run all the updates first, then enable Restore Points before running this file.
Annoyingly I cannot get a good solution to uninstalling a ton of the bloatware applications that are there, so we'll have to settle with uninstalling by hand.

Setup command file here.

```
powershell -Command "irm 'https://github.com/jaronwilding/dotfiles/raw/main/windows10/setup-windows.ps1' | iex"
```
