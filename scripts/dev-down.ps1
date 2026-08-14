#Requires -Version 5.1
# Tắt hạ tầng dev FoodMap. Dữ liệu trong volume được GIỮ LẠI.
#
# ⚠️ File phải lưu dạng UTF-8 KÈM BOM (PowerShell 5.1 đọc .ps1 theo ANSI khi thiếu BOM).

$ErrorActionPreference = 'Continue'

$Root = Split-Path -Parent $PSScriptRoot
Set-Location $Root

docker compose -f 'infra\docker-compose.yml' down

@'

Đã tắt. Dữ liệu trong volume vẫn còn.

Muốn xoá sạch dữ liệu (KHÔNG HOÀN TÁC ĐƯỢC):
  docker compose -f infra\docker-compose.yml down -v
'@ | Write-Host
