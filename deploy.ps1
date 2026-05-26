# ============================================================
#  MucoAcadémie – Script de déploiement PowerShell
#  Usage   : .\deploy.ps1
#  Prérequis: Git, PHP (XAMPP / WAMP / Laragon), MySQL
# ============================================================

param(
    [string]$RepoUrl    = "https://github.com/Bweso88/cours.git",
    [string]$Branch     = "claude/study-video-app-ph3I7",
    [string]$DeployDir  = "C:\xampp\htdocs\cours",
    [string]$DBHost     = "localhost",
    [string]$DBName     = "formation",
    [string]$DBUser     = "root",
    [string]$DBPass     = "",
    [switch]$Update
)

function Write-Ok    { param($m) Write-Host "  [OK] $m" -ForegroundColor Green  }
function Write-Warn  { param($m) Write-Host "  [!!] $m" -ForegroundColor Yellow }
function Write-Err   { param($m) Write-Host "  [KO] $m" -ForegroundColor Red    }
function Write-Step  { param($m) Write-Host "`n==> $m" -ForegroundColor Cyan    }

Clear-Host
Write-Host ""
Write-Host "  MucoAcadémie – Script de déploiement" -ForegroundColor Cyan
Write-Host "  $(if($Update){'Mode : MISE À JOUR'}else{'Mode : INSTALLATION INITIALE'})" -ForegroundColor Gray
Write-Host ""

Write-Step "Vérification des prérequis"
try { $gitV = git --version 2>&1; Write-Ok "Git : $gitV" } catch { Write-Err "Git non trouvé."; exit 1 }
try { $phpV = php -r "echo PHP_VERSION;" 2>&1; Write-Ok "PHP : $phpV" } catch { Write-Warn "PHP introuvable dans PATH." }

$mysqlExe = $null
@("C:\xampp\mysql\bin\mysql.exe","mysql") | ForEach-Object {
    if (!$mysqlExe -and (Test-Path $_ -ErrorAction SilentlyContinue)) { $mysqlExe = $_ }
}
if (!$mysqlExe) { try { mysql --version | Out-Null; $mysqlExe = "mysql" } catch {} }
if ($mysqlExe) { Write-Ok "MySQL trouvé : $mysqlExe" }
else { Write-Warn "mysql.exe introuvable – utilisez setup.php depuis le navigateur." }

Write-Step "Récupération du code source"
if (Test-Path "$DeployDir\.git") {
    Set-Location $DeployDir
    git fetch origin $Branch 2>&1 | Out-Null
    git checkout $Branch 2>&1 | Out-Null
    git pull origin $Branch 2>&1 | Out-Null
    Write-Ok "Code mis à jour (branche $Branch)"
} else {
    New-Item -ItemType Directory -Force -Path $DeployDir | Out-Null
    git clone --branch $Branch $RepoUrl $DeployDir 2>&1 | Out-Null
    Write-Ok "Dépôt cloné"
    Set-Location $DeployDir
}

Write-Step "Création des dossiers"
@("videos","views","images") | ForEach-Object {
    $path = Join-Path $DeployDir $_
    if (!(Test-Path $path)) { New-Item -ItemType Directory -Path $path | Out-Null; Write-Ok "Créé : $_" }
    else { Write-Ok "Existant : $_" }
}

Write-Step "Configuration de la base de données"
$dbContent = @"
<?php
`$host = "$DBHost";
`$db   = "$DBName";
`$user = "$DBUser";
`$pass = "$DBPass";
try {
    `$pdo = new PDO("mysql:host=`$host;dbname=`$db;charset=utf8mb4",`$user,`$pass,
        [PDO::ATTR_ERRMODE=>PDO::ERRMODE_EXCEPTION,PDO::ATTR_DEFAULT_FETCH_MODE=>PDO::FETCH_ASSOC]);
} catch (PDOException `$e) { die("Erreur de connexion à la base de données"); }
"@
Set-Content -Path (Join-Path $DeployDir "admin\db.php") -Value $dbContent -Encoding UTF8
Write-Ok "admin/db.php configuré"

if (!$Update -and $mysqlExe) {
    Write-Step "Import du schéma SQL"
    $sqlFile = Join-Path $DeployDir "schema.sql"
    if (Test-Path $sqlFile) {
        $args = @("-h",$DBHost,"-u",$DBUser)
        if ($DBPass -ne "") { $args += "-p$DBPass" }
        "CREATE DATABASE IF NOT EXISTS ``$DBName`` CHARACTER SET utf8mb4;" | & $mysqlExe @args 2>&1 | Out-Null
        & $mysqlExe @args $DBName -e "source $sqlFile" 2>&1 | Out-Null
        Write-Ok "Schéma SQL importé"
    } else { Write-Warn "schema.sql introuvable – utilisez setup.php" }
}

Write-Host ""
Write-Host "  Déploiement terminé !" -ForegroundColor Green
Write-Host "  Site        : http://localhost/cours/" -ForegroundColor White
Write-Host "  Admin       : http://localhost/cours/admin/" -ForegroundColor White
Write-Host "  Identifiant : admin  /  Mot de passe : Admin1234 (changez-le !)" -ForegroundColor Yellow
Write-Host ""
$open = Read-Host "  Ouvrir le site ? (O/n)"
if ($open -ne "n" -and $open -ne "N") { Start-Process "http://localhost/cours/" }
