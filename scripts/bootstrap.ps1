#Requires -Version 5.1
# Khởi tạo workspace FoodMap: submodule, file .env, dependency.
# Chạy được nhiều lần, an toàn.
#
# ⚠️ Hai điều cần biết khi sửa file này:
#  1. File phải lưu dạng UTF-8 KÈM BOM. PowerShell 5.1 đọc .ps1 theo bảng mã ANSI khi
#     thiếu BOM, làm hỏng ký tự tiếng Việt và gây lỗi cú pháp.
#  2. KHÔNG đặt $ErrorActionPreference = 'Stop'. Với lệnh native như npm hay gradle,
#     PowerShell 5.1 coi mọi dòng ghi ra stderr là lỗi dừng — mà npm ghi cảnh báo
#     deprecated ra stderr ở gần như mọi lần cài. Thay vào đó kiểm tra $LASTEXITCODE.

$ErrorActionPreference = 'Continue'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

function Info($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "!  $m" -ForegroundColor Yellow }
function Ok($m)   { Write-Host "OK $m" -ForegroundColor Green }

function Fail($m) {
    Write-Host "LOI: $m" -ForegroundColor Red
    exit 1
}

# --- Kiểm tra công cụ cần thiết ---------------------------------------------
Info 'Kiểm tra công cụ'
$missing = $false
foreach ($tool in @('git', 'docker', 'node', 'npm', 'java')) {
    if (Get-Command $tool -ErrorAction SilentlyContinue) { Ok $tool }
    else { Warn "Thiếu: $tool"; $missing = $true }
}
if ($missing) {
    Fail 'Cài đủ công cụ trên rồi chạy lại. Cần: Git, Docker Desktop, Node 20+, JDK 21.'
}

# Tự tách phiên bản trong PowerShell thay vì truyền biểu thức có dấu nháy vào `node -p`:
# PowerShell nuốt mất dấu nháy kép khi chuyển tham số cho lệnh native trên Windows.
$nodeVersion = (node -v).TrimStart('v')
$nodeMajor = [int]($nodeVersion.Split('.')[0])
if ($nodeMajor -lt 20) { Warn "Node v$nodeVersion cũ hơn khuyến nghị (20+)." }

# --- Submodule ---------------------------------------------------------------
Info 'Đồng bộ submodule'
git submodule update --init --recursive
if ($LASTEXITCODE -ne 0) { Fail 'Không đồng bộ được submodule.' }
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

foreach ($client in @('mobile', 'admin')) {
    if ((Test-Path "$client\.env.example") -and -not (Test-Path "$client\.env")) {
        Copy-Item "$client\.env.example" "$client\.env"
        Ok "Đã tạo $client\.env từ .env.example"
    }
}

# --- Dependency --------------------------------------------------------------
foreach ($client in @('mobile', 'admin')) {
    if (Test-Path "$client\package.json") {
        Info "Cài dependency cho $client"
        Push-Location $client

        # Có lockfile thì dùng `npm ci`, KHÔNG dùng `npm install`.
        # Lý do không phải lý thuyết: `npm install` trên cây sạch đã từng cài thiếu —
        # gói có mặt nhưng thiếu toàn bộ file .d.ts, khiến `tsc --noEmit` báo
        # "Cannot find module" cho những gói rõ ràng đang nằm trong node_modules.
        # `npm ci` xoá sạch node_modules và cài đúng theo lockfile.
        if (Test-Path 'package-lock.json') {
            npm ci --no-audit --no-fund
        } else {
            npm install --no-audit --no-fund
        }

        $code = $LASTEXITCODE
        Pop-Location
        if ($code -ne 0) { Fail "Cài dependency cho $client thất bại (mã $code)." }
        Ok "$client sẵn sàng"
    } else {
        Warn "Bỏ qua $client — chưa có package.json"
    }
}

if (Test-Path 'backend\gradlew.bat') {
    Info 'Tải dependency cho backend'
    Push-Location 'backend'
    .\gradlew.bat --quiet dependencies | Out-Null
    $code = $LASTEXITCODE
    Pop-Location
    if ($code -ne 0) { Fail "Gradle thất bại (mã $code)." }
    Ok 'Backend sẵn sàng'
} else {
    Warn 'Bỏ qua backend — chưa có gradlew.bat'
}

Info 'Xong'
@'

Bước tiếp theo:

  .\scripts\dev-up.ps1                bật Postgres, Redis, MinIO, Mailpit
  cd backend; .\gradlew.bat bootRun   API tại http://localhost:8080
  cd mobile;  npx expo start          app mobile
  cd admin;   npm run dev             trang quản trị tại http://localhost:3000

Nhớ điền các key thật vào infra\.env trước khi chạy backend.
Nhớ đổi EXPO_PUBLIC_API_BASE_URL trong mobile\.env thành IP LAN của máy bạn.
'@ | Write-Host
