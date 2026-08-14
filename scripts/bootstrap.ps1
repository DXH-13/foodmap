#Requires -Version 5.1
# Khởi tạo workspace FoodMap: submodule, file .env, dependency.
# Chạy được nhiều lần, an toàn.
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Info($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "!  $m" -ForegroundColor Yellow }
function Ok($m)   { Write-Host "OK $m" -ForegroundColor Green }

# --- Kiểm tra công cụ cần thiết ---------------------------------------------
Info 'Kiểm tra công cụ'
$missing = $false
foreach ($tool in @('git', 'docker', 'node', 'npm', 'java')) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Ok $tool }
    else { Warn "Thiếu: $tool"; $missing = $true }
}
if ($missing) {
    Warn 'Cài đủ công cụ trên rồi chạy lại. Cần: Git, Docker Desktop, Node 20+, JDK 21.'
    exit 1
}

$nodeMajor = [int](node -p 'process.versions.node.split(".")[0]')
if ($nodeMajor -lt 20) { Warn "Node $(node -v) cũ hơn khuyến nghị (20+)." }

# --- Submodule ---------------------------------------------------------------
Info 'Đồng bộ submodule'
git submodule update --init --recursive
git submodule status

# --- File .env ---------------------------------------------------------------
Info 'Chuẩn bị file môi trường'
if (Test-Path 'infra\.env') {
    Ok 'infra\.env đã có, giữ nguyên'
} else {
    Copy-Item 'infra\.env.example' 'infra\.env'
    Ok 'Đã tạo infra\.env từ .env.example'
    Warn 'Cần điền giá trị thật: GOOGLE_MAPS_API_KEY, ANTHROPIC_API_KEY, JWT_SECRET'
}

# --- Dependency --------------------------------------------------------------
if (Test-Path 'mobile\package.json') {
    Info 'Cài dependency cho mobile'
    Push-Location 'mobile'; npm install; Pop-Location
} else { Warn 'Bỏ qua mobile — chưa có package.json' }

if (Test-Path 'admin\package.json') {
    Info 'Cài dependency cho admin'
    Push-Location 'admin'; npm install; Pop-Location
} else { Warn 'Bỏ qua admin — chưa có package.json' }

if (Test-Path 'backend\gradlew.bat') {
    Info 'Tải dependency cho backend'
    Push-Location 'backend'; .\gradlew.bat --quiet dependencies | Out-Null; Pop-Location
    Ok 'Backend sẵn sàng'
} else { Warn 'Bỏ qua backend — chưa có gradlew.bat' }

Info 'Xong'
@'

Bước tiếp theo:

  .\scripts\dev-up.ps1                bật Postgres, Redis, MinIO, Mailpit
  cd backend; .\gradlew.bat bootRun   API tại http://localhost:8080
  cd mobile;  npx expo start          app mobile
  cd admin;   npm run dev             trang quản trị tại http://localhost:3000

Nhớ điền các key thật vào infra\.env trước khi chạy backend.
'@ | Write-Host
