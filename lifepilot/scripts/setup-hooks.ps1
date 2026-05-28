<#
PowerShell helper to enable repository hooks and optionally set the required git user identity.

Usage:
  # Configure the repo to use the included hooks
  .\scripts\setup-hooks.ps1

  # Configure hooks and set user.name and user.email (run only if you want to change your local config)
  .\scripts\setup-hooks.ps1 -SetUser -UserName "Your Name"

This script will set git config core.hooksPath to .githooks for the current repository.
If -SetUser is supplied it will also set user.name and user.email in the local repo configuration.
#>

param(
    [switch]$SetUser,
    [string]$UserName = "",
    [string]$RequiredEmail = "it25100142@my.sliit.lk"
)

Write-Host "Configuring repository hooks..."

$repoRoot = (git rev-parse --show-toplevel) 2>$null
if (-not $repoRoot) {
    Write-Error "This script must be run inside a git repository."
    exit 1
}

Push-Location $repoRoot
try {
    git config core.hooksPath .githooks
    Write-Host "Set core.hooksPath to '.githooks' in repository at: $repoRoot"

    $currentEmail = git config user.email || $null
    if ($currentEmail) { Write-Host "Current git user.email: $currentEmail" }
    else { Write-Host "No git user.email is configured for this repository." }

    if ($SetUser) {
        if (-not $UserName) {
            Write-Host "Setting user.email to $RequiredEmail"
            git config user.email $RequiredEmail
            Write-Host "Please run the command again later to set user.name if desired: git config user.name 'Your Name'"
        }
        else {
            Write-Host "Setting user.name to '$UserName' and user.email to $RequiredEmail"
            git config user.name "$UserName"
            git config user.email $RequiredEmail
        }
    }
    else {
        Write-Host "Note: To change your local repo identity you can run:`n  git config user.email $RequiredEmail`" -ForegroundColor Yellow
    }

    Write-Host "Setup complete. Try making a commit; the pre-commit hook will block commits from other emails." -ForegroundColor Green
}
finally {
    Pop-Location
}

