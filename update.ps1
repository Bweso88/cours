# ============================================================
#  MucoAcadémie – Script de mise à jour
#  Usage : clic droit > "Exécuter avec PowerShell"
# ============================================================

param(
    [string]$Branch  = "claude/study-video-app-ph3I7",
    [string]$RepoUrl = "https://github.com/Bweso88/cours.git"
)

function Write-Ok   { param($m) Write-Host "  [OK] $m" -ForegroundColor Green }
function Write-Err  { param($m) Write-Host "  [KO] $m" -ForegroundColor Red   }
function Write-Step { param($m) Write-Host "`n>>> $m" -ForegroundColor Cyan   }

Clear-Host
Write-Host ""
Write-Host "  MucoAcadémie – Mise à jour" -ForegroundColor Cyan
Write-Host "  ─────────────────────────────────────────" -ForegroundColor DarkGray
Write-Host ""

$ScriptDir = Split-Path -Parent $MyInvocation.MyCommand.Path
Set-Location $ScriptDir
Write-Ok "Dossier : $ScriptDir"

Write-Step "Vérification de Git"
try { git --version | Out-Null; Write-Ok "Git détecté" }
catch { Write-Err "Git non trouvé."; pause; exit 1 }

Write-Step "Vérification du dépôt"
if (!(Test-Path ".git")) {
    git init; git remote add origin $RepoUrl
    Write-Ok "Dépôt initialisé"
} else { Write-Ok "Dépôt Git existant" }

Write-Step "Sauvegarde de la configuration"
$dbFile = "admin\db.php"; $dbBackup = "admin\db.php.bak"
if (Test-Path $dbFile) { Copy-Item $dbFile $dbBackup -Force; Write-Ok "admin/db.php sauvegardé" }

Write-Step "Téléchargement des mises à jour"
git fetch origin $Branch 2>&1 | Out-Null
git checkout $Branch 2>&1 | Out-Null
git pull origin $Branch 2>&1 | Out-Null
if ($LASTEXITCODE -eq 0) { Write-Ok "Code mis à jour (branche $Branch)" }
else { Write-Err "Échec du pull."; pause; exit 1 }

Write-Step "Restauration de la configuration"
if (Test-Path $dbBackup) { Copy-Item $dbBackup $dbFile -Force; Remove-Item $dbBackup -Force; Write-Ok "admin/db.php restauré" }

Write-Step "Vérification des dossiers"
@("videos","views","images") | ForEach-Object {
    if (!(Test-Path $_)) { New-Item -ItemType Directory -Path $_ | Out-Null; Write-Ok "Créé : $_" }
    else { Write-Ok "OK : $_" }
}

Write-Host ""
Write-Host "  Mise à jour terminée !" -ForegroundColor Green
Write-Host ""
pause
