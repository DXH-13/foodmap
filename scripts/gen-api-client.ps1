#Requires -Version 5.1
# Sinh TypeScript client cho mobile và admin từ docs/03-api/openapi.yaml.
#
# ĐỪNG SỬA TAY file trong các thư mục generated\ — chúng bị ghi đè mỗi lần chạy script này.
# Muốn đổi kiểu dữ liệu API thì sửa openapi.yaml rồi chạy lại.
#
# ⚠️ File phải lưu dạng UTF-8 KÈM BOM (PowerShell 5.1 đọc .ps1 theo ANSI khi thiếu BOM).
# ⚠️ KHÔNG đặt $ErrorActionPreference = 'Stop': npx ghi tiến trình ra stderr.

$ErrorActionPreference = 'Continue'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
$Spec = 'docs/03-api/openapi.yaml'

function Info($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "!  $m" -ForegroundColor Yellow }
function Ok($m)   { Write-Host "OK $m" -ForegroundColor Green }

if (-not (Test-Path $Spec)) {
    Warn "Không tìm thấy $Spec"
    Warn "Chạy 'git submodule update --init' để lấy submodule docs."
    exit 1
}

$readme = @'
# Thư mục sinh tự động — KHÔNG SỬA TAY

Toàn bộ nội dung ở đây được sinh từ `docs/03-api/openapi.yaml` bằng
`scripts/gen-api-client.ps1` (hoặc bản `.sh`). Mọi thay đổi sửa tay sẽ mất khi
chạy lại script.

Cần đổi kiểu dữ liệu của API? Sửa `docs/03-api/openapi.yaml`, rồi:

    .\scripts\gen-api-client.ps1

Chi tiết quy trình: skill `api-contract` trong `.claude/skills/`.
'@

foreach ($target in @('mobile', 'admin')) {
    if (-not (Test-Path "$target\package.json")) {
        Warn "Bỏ qua $target — chưa có package.json"
        continue
    }

    Info "Sinh client cho $target"
    $outDir = "$target\src\api\generated"
    New-Item -ItemType Directory -Force -Path $outDir | Out-Null

    npx --yes openapi-typescript $Spec --output "$outDir\schema.ts"
    if ($LASTEXITCODE -ne 0) { Warn "Sinh client cho $target thất bại"; exit 1 }

    $readme | Out-File -FilePath "$outDir\README.md" -Encoding utf8
    Ok "$outDir\schema.ts"
}

Info 'Kiểm tra kiểu'
$typecheckFailed = $false
foreach ($target in @('mobile', 'admin')) {
    if (Test-Path "$target\tsconfig.json") {
        Write-Host "    $target : " -NoNewline
        Push-Location $target
        npx --yes tsc --noEmit 2>&1 | Out-Null
        $failed = $LASTEXITCODE -ne 0
        Pop-Location
        if ($failed) {
            Write-Host 'có lỗi' -ForegroundColor Yellow
            $typecheckFailed = $true
        } else {
            Write-Host 'OK' -ForegroundColor Green
        }
    }
}

if ($typecheckFailed) {
    @'

Có lỗi TypeScript. Đây thường là điều TỐT: nó chỉ đúng những chỗ code đang dùng
API cũ sau khi hợp đồng thay đổi. Xem chi tiết bằng:

  cd mobile; npx tsc --noEmit
  cd admin;  npx tsc --noEmit

Đừng sửa file trong generated\ để làm hết lỗi — hãy sửa chỗ gọi.
'@ | Write-Host
    exit 1
}

Ok 'Xong'
