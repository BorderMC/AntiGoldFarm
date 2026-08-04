$ErrorActionPreference = "Stop"

function Read-ProjectName {
    while ($true) {
        $name = Read-Host "Project name (one word, example: CraftLore)"
        if ($name -match "^[A-Za-z][A-Za-z0-9]*$") {
            return $name
        }

        Write-Host "Use exactly one word with only letters and numbers." -ForegroundColor Yellow
    }
}

function Read-GitRemote {
    while ($true) {
        $remote = Read-Host "Git remote URL (example: https://github.com/yourname/MyPlugin.git)"
        if (-not [string]::IsNullOrWhiteSpace($remote)) {
            return $remote.Trim()
        }

        Write-Host "Git remote URL is required." -ForegroundColor Yellow
    }
}

function Get-LowerCamelCase([string]$value) {
    if ($value.Length -eq 1) {
        return $value.ToLowerInvariant()
    }

    return $value.Substring(0, 1).ToLowerInvariant() + $value.Substring(1)
}

function Replace-InFile([string]$path, [string]$projectName, [string]$packageName, [string]$commandName) {
    $content = Get-Content -Raw -LiteralPath $path
    $updated = $content.Replace("AntiGoldFarm", $projectName).Replace("antiGoldFarm", $packageName).Replace("antigoldfarm", $commandName)

    if ($updated -ne $content) {
        [System.IO.File]::WriteAllText($path, $updated, [System.Text.UTF8Encoding]::new($false))
    }
}

function Invoke-GitSoft([string]$command, [string[]]$arguments) {
    Write-Host ("> git " + $command + ($(if ($arguments.Count -gt 0) { " " + ($arguments -join " ") } else { "" })))
    & git $command @arguments
    return $LASTEXITCODE -eq 0
}

function Rename-MatchingFiles([string]$root, [string]$projectName, [string]$packageName) {
    $targets = Get-ChildItem -LiteralPath $root -Recurse -File -Force |
        Where-Object { $_.FullName -notmatch "[\\/]\.git([\\/]|$)" } |
        Sort-Object { $_.FullName.Length } -Descending

    foreach ($file in $targets) {
        $newName = $file.Name.Replace("AntiGoldFarm", $projectName).Replace("antiGoldFarm", $packageName)
        if ($newName -ne $file.Name) {
            Rename-Item -LiteralPath $file.FullName -NewName $newName
        }
    }
}

function Rename-MatchingDirectories([string]$root, [string]$projectName, [string]$packageName) {
    $targets = Get-ChildItem -LiteralPath $root -Recurse -Directory -Force |
        Where-Object { $_.FullName -notmatch "[\\/]\.git([\\/]|$)" } |
        Sort-Object { $_.FullName.Length } -Descending

    foreach ($directory in $targets) {
        $newName = $directory.Name.Replace("AntiGoldFarm", $projectName).Replace("antiGoldFarm", $packageName)
        if ($newName -ne $directory.Name) {
            Rename-Item -LiteralPath $directory.FullName -NewName $newName
        }
    }
}

$scriptRoot = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $scriptRoot

$projectName = Read-ProjectName
$packageName = Get-LowerCamelCase $projectName
$commandName = $projectName.ToLowerInvariant()
$gitRemote = Read-GitRemote

if (Test-Path -LiteralPath "README.md") {
    Remove-Item -LiteralPath "README.md" -Force
}

if (Test-Path -LiteralPath "replacement-README.md") {
    Rename-Item -LiteralPath "replacement-README.md" -NewName "README.md"
}

if (Test-Path -LiteralPath ".git") {
    Remove-Item -LiteralPath ".git" -Recurse -Force
}

$textFiles = Get-ChildItem -LiteralPath $scriptRoot -Recurse -File -Force |
    Where-Object {
        $_.FullName -notmatch "[\\/]\.git([\\/]|$)" -and
        $_.FullName -notmatch "[\\/]build([\\/]|$)" -and
        $_.FullName -notmatch "[\\/]\.gradle([\\/]|$)" -and
        $_.FullName -notmatch "[\\/]\.idea([\\/]|$)"
    }

foreach ($file in $textFiles) {
    Replace-InFile -path $file.FullName -projectName $projectName -packageName $packageName -commandName $commandName
}

Rename-MatchingFiles -root $scriptRoot -projectName $projectName -packageName $packageName
Rename-MatchingDirectories -root $scriptRoot -projectName $projectName -packageName $packageName

$currentDirectory = Get-Item -LiteralPath $scriptRoot
if ($currentDirectory.Name -eq "AntiGoldFarm") {
    $parentDirectory = $currentDirectory.Parent.FullName
    $renamedRoot = Join-Path $parentDirectory $projectName

    Set-Location $parentDirectory
    Rename-Item -LiteralPath $currentDirectory.FullName -NewName $projectName
    Set-Location $renamedRoot
    $scriptRoot = $renamedRoot
}

$gitSteps = @(
    @{ Command = "init"; Arguments = @() },
    @{ Command = "remote"; Arguments = @("add", "origin", $gitRemote) },
    @{ Command = "add"; Arguments = @(".") },
    @{ Command = "commit"; Arguments = @("-m", "Initial commit") },
    @{ Command = "branch"; Arguments = @("-M", "main") },
    @{ Command = "push"; Arguments = @("-u", "origin", "main") }
)

$failedStep = $null

foreach ($step in $gitSteps) {
    if (-not (Invoke-GitSoft -command $step.Command -arguments $step.Arguments)) {
        $failedStep = $step
        break
    }
}

if ($failedStep -ne $null) {
    Write-Host ""
    Write-Host "Git setup was not completed automatically." -ForegroundColor Yellow
    Write-Host "Run these commands manually:" -ForegroundColor Yellow
    foreach ($step in $gitSteps) {
        Write-Host ("git " + $step.Command + ($(if ($step.Arguments.Count -gt 0) { " " + ($step.Arguments -join " ") } else { "" })))
    }
}

$scriptFiles = @(
    Join-Path $scriptRoot "setup-template.ps1",
    Join-Path $scriptRoot "setup-template.sh"
)

foreach ($scriptFile in $scriptFiles) {
    if (Test-Path -LiteralPath $scriptFile) {
        Remove-Item -LiteralPath $scriptFile -Force
    }
}
