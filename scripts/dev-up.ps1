#Requires -Version 5.1
# Bật hạ tầng dev FoodMap và đợi tới khi mọi service khoẻ.
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root
$ComposeFile = 'infra\docker-compose.yml'

function Info($m) { Write-Host "`n==> $m" -ForegroundColor Cyan }
function Warn($m) { Write-Host "!  $m" -ForegroundColor Yellow }
function Ok($m)   { Write-Host "OK $m" -ForegroundColor Green }

if (-not (Test-Path 'infra\.env')) {
    Warn 'Chưa có infra\.env — tạo từ .env.example'
    Copy-Item 'infra\.env.example' 'infra\.env'
    Warn 'Nhớ điền GOOGLE_MAPS_API_KEY, ANTHROPIC_API_KEY, JWT_SECRET'
}

Info 'Khởi động dịch vụ'
docker compose -f $ComposeFile up -d

Info 'Đợi healthcheck (tối đa 90 giây)'
$healthy = $false
for ($i = 0; $i -lt 45; $i++) {
    $states = docker compose -f $ComposeFile ps --format '{{.Health}}'
    if ($states -and -not ($states | Where-Object { $_ -ne 'healthy' })) {
        $healthy = $true
        break
    }
    Write-Host '.' -NoNewline
    Start-Sleep -Seconds 2
}
Write-Host ''

if (-not $healthy) {
    Warn 'Hết thời gian chờ. Trạng thái hiện tại:'
    docker compose -f $ComposeFile ps
    Warn "Xem log: docker compose -f $ComposeFile logs <service> --tail 50"
    exit 1
}
Ok 'Tất cả dịch vụ đã khoẻ'

Info 'Kiểm tra PostGIS'
docker exec foodmap-db psql -U foodmap -d foodmap -tAc 'SELECT PostGIS_Version();'

docker compose -f $ComposeFile ps

@'

Dịch vụ đang chạy:

  PostgreSQL + PostGIS  localhost:5433   db/user/pass: foodmap
  Redis                 localhost:6380
  MinIO API             localhost:9002
  MinIO Console         http://localhost:9003   (minioadmin / minioadmin)
  Mailpit SMTP          localhost:1025
  Mailpit UI            http://localhost:8025

Cổng lệch chuẩn là cố ý — tránh đụng Postgres/Redis/MinIO khác trên máy.
Đổi được trong infra\.env.

Tắt bằng: .\scripts\dev-down.ps1
'@ | Write-Host
