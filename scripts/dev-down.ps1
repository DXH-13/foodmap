#Requires -Version 5.1
# Tắt hạ tầng dev FoodMap. Dữ liệu trong volume được GIỮ LẠI.
$ErrorActionPreference = 'Stop'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

docker compose -f 'infra\docker-compose.yml' down

@'

Đã tắt. Dữ liệu trong volume vẫn còn.

Muốn xoá sạch dữ liệu (KHÔNG HOÀN TÁC ĐƯỢC):
  docker compose -f infra\docker-compose.yml down -v
'@ | Write-Host
