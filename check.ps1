param(
  [string]$ProjectPath = (Get-Location).Path
)

function Write-Title {
  param([string]$t)
  Write-Host ""
  Write-Host "=== $t ===" -ForegroundColor Cyan
}

function Test-Cmd {
  param([string]$name, [string]$args = "--version")
  try {
    $out = & $name $args 2>&1 | Select-Object -First 1
    if ($out) {
      Write-Host "$name : OK  $out" -ForegroundColor Green
    } else {
      Write-Host "$name : OK" -ForegroundColor Green
    }
  } catch {
    Write-Host "$name : FAIL (not in PATH)" -ForegroundColor Red
  }
}

Write-Title "TOOLS CHECK"
Test-Cmd "node"
Test-Cmd "npm"
Test-Cmd "docker" "--version"

# docker compose может быть подкомандой
try {
  $cv = (& docker compose version 2>&1 | Select-Object -First 1)
  if ($cv) { Write-Host "docker compose : OK  $cv" -ForegroundColor Green }
  else { Write-Host "docker compose : FAIL (no output)" -ForegroundColor Yellow }
} catch {
  Write-Host "docker compose : FAIL (not found)" -ForegroundColor Red
}

Test-Cmd "newman" "-v"
Test-Cmd "postman" "--version"   # Postman CLI; если не ставили  будет FAIL, это ок
Test-Cmd "git" "--version"

Write-Title "PROJECT PATH"
Write-Host $ProjectPath

if (-not (Test-Path $ProjectPath)) {
  Write-Host "Папка проекта не найдена. Создай её и структуру: api, db, verify-service, postman, scripts" -ForegroundColor Yellow
  exit 1
}

Set-Location $ProjectPath

Write-Title "STRUCTURE (expected top-level)"
$expected = @(
  "docker-compose.yml",
  "api",
  "db",
  "verify-service",
  "postman",
  "scripts"
)
foreach ($e in $expected) {
  if (Test-Path $e) {
    Write-Host "$e : OK" -ForegroundColor Green
  } else {
    Write-Host "$e : MISSING" -ForegroundColor Red
  }
}

Write-Title "FILES (expected key files)"
$files = @(
  "api\db.json",
  "db\init.sql",
  "verify-service\package.json",
  "verify-service\server.js",
  "postman\shop.postman_collection.json",
  "postman\dev.postman_environment.json",
  "scripts\run-newman.ps1"
)
foreach ($f in $files) {
  if (Test-Path $f) {
    $len = (Get-Item $f).Length
    if ($len -gt 0) {
      Write-Host "$f : OK ($len bytes)" -ForegroundColor Green
    } else {
      Write-Host "$f : EMPTY" -ForegroundColor Yellow
    }
  } else {
    Write-Host "$f : MISSING" -ForegroundColor Red
  }
}

Write-Title "EMPTY FILES (size=0)"
$empty = Get-ChildItem -Recurse -File | Where-Object { $_.Length -eq 0 }
if ($empty) {
  $empty | ForEach-Object { Write-Host $_.FullName -ForegroundColor Yellow }
} else {
  Write-Host "Нет пустых файлов" -ForegroundColor Green
}

Write-Title "TREE (2 levels)"
cmd /c "tree /F"

Write-Title "DOCKER STATUS (optional)"
try {
  $dp = docker ps --format "{{.Names}}" 2>$null
  if ($LASTEXITCODE -eq 0) {
    if ($dp) {
      Write-Host "Running containers:" -ForegroundColor Green
      $dp | ForEach-Object { Write-Host " - $_" }
    } else {
      Write-Host "Контейнеры не запущены. Для старта: docker compose up -d" -ForegroundColor Yellow
    }
  } else {
    Write-Host "Docker не отвечает. Проверь установку/запуск Docker Desktop." -ForegroundColor Yellow
  }
} catch {
  Write-Host "Docker не найден или не запущен." -ForegroundColor Yellow
}

Write-Host ""
Write-Host "Готово." -ForegroundColor Cyan
