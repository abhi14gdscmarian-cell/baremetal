
# scripts/setup-git.ps1
# Prepare an existing MPFS RISC-V64 project for GitHub.
# Run this script from the project root or pass -ProjectRoot.

param(
    [string]$ProjectRoot = (Get-Location).Path
)

$ErrorActionPreference = "Stop"

# Resolve and validate the project root.
$ProjectRoot = (Resolve-Path $ProjectRoot).Path

Write-Host "`n=== MPFS Git Setup ===" -ForegroundColor Cyan
Write-Host "Project root: $ProjectRoot"

# Verify Git is installed.
if (-not (Get-Command git -ErrorAction SilentlyContinue)) {
    throw "Git was not found. Install Git for Windows and reopen PowerShell."
}

git --version
if ($LASTEXITCODE -ne 0) {
    throw "Git is not working correctly."
}

Push-Location $ProjectRoot

try {
    # Initialize Git only if this directory is not already a repository.
    git rev-parse --is-inside-work-tree *> $null
    $isRepository = ($LASTEXITCODE -eq 0)

    if (-not $isRepository) {
        git init
        if ($LASTEXITCODE -ne 0) {
            throw "Git initialization failed."
        }

        Write-Host "Git repository initialized." -ForegroundColor Green
    }
    else {
        Write-Host "Existing Git repository detected; preserving it." `
            -ForegroundColor Yellow
    }

    # Create a conservative .gitignore only when one doesn't exist.
    $gitIgnore = Join-Path $ProjectRoot ".gitignore"

    if (-not (Test-Path $gitIgnore)) {
        $ignoreRules = @'
# CMake build output
/build/
/build-*/
/cmake-build-*/

# Compiled firmware and intermediate files
*.o
*.obj
*.a
*.lib
*.elf
*.hex
*.bin
*.map
*.lst
*.d
*.gcda
*.gcno
*.gcov
*.info

# Test and coverage output
/coverage/
/coverage_html/
Testing/

# IDE and local machine files
.vscode/
.idea/
*.user
*.suo
.DS_Store
Thumbs.db

# Local environment and credentials
.env
.env.*
!.env.example
*.pem
*.key

# Python cache
__pycache__/
*.py[cod]
'@

        Set-Content -Path $gitIgnore -Value $ignoreRules -Encoding utf8
        Write-Host ".gitignore created." -ForegroundColor Green
    }
    else {
        Write-Host ".gitignore already exists; it was not modified." `
            -ForegroundColor Yellow
    }

    Write-Host "`n=== Repository Status ===" -ForegroundColor Cyan
    git status --short --branch

    if ($LASTEXITCODE -ne 0) {
        throw "Unable to read Git status."
    }

    Write-Host "`nSetup completed. No commit or push was performed." `
        -ForegroundColor Green
    Write-Host "Review files and .gitignore before staging anything."
}
finally {
    Pop-Location
}
