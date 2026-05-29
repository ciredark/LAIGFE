# =============================================================================
# LAIGFE v2.8 - Complete Windows Installer (Fixed Launcher with String Replacement)
# =============================================================================

$ErrorActionPreference = "Stop"
$GREEN = [ConsoleColor]::Green
$CYAN = [ConsoleColor]::Cyan
$YELLOW = [ConsoleColor]::Yellow
$RED = [ConsoleColor]::Red

function Log($msg) { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $CYAN }
function Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor $GREEN }
function Warning($msg) { Write-Host "[WARNING] $msg" -ForegroundColor $YELLOW }
function Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor $RED; exit 1 }

Log "Starting LAIGFE v2.8 Windows Installer..."

# Admin Check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Error "Please run this script as Administrator."
}

$CIVITAI_API_KEY = "ba9841ada4c58920a94446dbdb929b31"

# Dependencies
Log "Installing dependencies..."
winget install --id Git.Git -e --silent
winget install --id Python.Python.3 -e --silent
winget install --id NodeJS.LTS -e --silent

# Path Setup
$BASE_PATH = Read-Host "Installation path (default: $HOME\LAIGFE)"
if (-not $BASE_PATH) { $BASE_PATH = "$HOME\LAIGFE" }
$ROOT_DIR = Join-Path $BASE_PATH "LAIGFE"
New-Item -ItemType Directory -Path $ROOT_DIR -Force | Out-Null

# Folder Structure
$folders = @("models\llm", "models\checkpoints", "models\loras", "Personality", "Knowledge", "Memories\interactions", "Memories\chroma_db", "engines", "envs", "logs", "media_out")
foreach ($f in $folders) { New-Item -ItemType Directory -Path (Join-Path $ROOT_DIR $f) -Force | Out-Null }

# Tier & Personality (simplified)
$TIER_CHOICE = Read-Host "Select Tier [1-4] (default 2)"
if (-not $TIER_CHOICE) { $TIER_CHOICE = 2 }
$STYLE = Read-Host "Aesthetic (Realistic/Anime)"
$CharName = Read-Host "Companion Name"

# LLM Selection
switch ($TIER_CHOICE) {
    "1" { $LLM_NAME = "qwen-12b-q8.gguf" }
    "2" { $LLM_NAME = "qwen-9b-q6.gguf" }
    "3" { $LLM_NAME = "gemma-4b-q4.gguf" }
    default { $LLM_NAME = "qwen-9b-q6.gguf" }
}

# Download Function (CURL)
function Download-File($url, $dest) {
    if (Test-Path $dest) { return }
    Log "Downloading $(Split-Path $dest -Leaf)..."
    $headers = if ($url -like "*civitai*") { "-H `"Authorization: Bearer $CIVITAI_API_KEY`"" } else { "" }
    $cmd = "curl.exe -L -# $headers -o `"$dest`" `"$url`""
    Invoke-Expression $cmd
}

# ... Add your model and LoRA downloads here as needed ...

# Launcher Generation with String Replacement (Fixed)
Log "Generating launcher script..."

$LauncherTemplate = @"
`$ROOT_DIR = "`$PSScriptRoot"
Write-Host "=== LAIGFE v2.8 Starting Services ===" -ForegroundColor Green

# 1. llama.cpp
Write-Host "Starting llama.cpp on port 6118..." -ForegroundColor Cyan
Start-Job -ScriptBlock { & "`$ROOT_DIR\engines\llama.cpp\build\bin\Release\llama-server.exe" -m "`$ROOT_DIR\models\llm\$LLM_NAME" --port 6118 --host 127.0.0.1 -ngl 40 -c 8192 } | Out-Null
Start-Sleep -Seconds 8

# 2. ComfyUI
Write-Host "Starting ComfyUI on port 8188..." -ForegroundColor Cyan
Start-Job -ScriptBlock { & "`$ROOT_DIR\envs\comfyui-env\Scripts\activate.ps1"; python "`$ROOT_DIR\engines\ComfyUI\main.py" --port 8188 --listen 127.0.0.1 } | Out-Null
Start-Sleep -Seconds 6

# 3. Hermes Gateway
Write-Host "Starting Hermes on port 8010..." -ForegroundColor Cyan
Start-Job -ScriptBlock { hermes start --port 8010 --llm-base-url "http://127.0.0.1:6118/v1" --system-prompt-file "`$ROOT_DIR\Personality\system_prompt.txt" } | Out-Null
Start-Sleep -Seconds 5

# 4. OpenWebUI
Write-Host "Starting OpenWebUI on port 8080..." -ForegroundColor Cyan
Start-Job -ScriptBlock { 
    `$env:OPENAI_API_BASE_URL = "http://127.0.0.1:8010/v1"
    `$env:OPENAI_API_KEY = "sk-laigfe"
    `$env:ENABLE_IMAGE_GENERATION = "True"
    `$env:IMAGE_GENERATION_ENGINE = "comfyui"
    `$env:COMFYUI_BASE_URL = "http://127.0.0.1:8188"
    & "`$ROOT_DIR\envs\openwebui-env\Scripts\activate.ps1"
    open-webui serve --host 0.0.0.0 --port 8080 
} | Out-Null

Write-Host "`nAll services started! Open http://localhost:8080" -ForegroundColor Green
"@
$LauncherTemplate = $LauncherTemplate.Replace('$LLM_NAME', $LLM_NAME).Replace('$ROOT_DIR', $ROOT_DIR)
$LauncherTemplate | Out-File "$ROOT_DIR\run_laigfe.ps1" -Encoding utf8

Success "LAIGFE v2.8 Installation Complete at $ROOT_DIR"
Write-Host "Launch with: cd '$ROOT_DIR'; .\run_laigfe.ps1" -ForegroundColor Green
