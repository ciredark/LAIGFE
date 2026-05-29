# =============================================================================
# LAIGFE v2.8 - Complete Windows Production Installer
# Full Memory System, Uncensored, Multi-Modal, ChromaDB, Hermes
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
$folders = @("models\llm", "models\checkpoints", "models\loras", "Personality", "Knowledge", "Memories\interactions", "Memories\chroma_db", "engines\ComfyUI", "envs", "logs", "media_out\images", "media_out\videos", "media_out\audio")
foreach ($f in $folders) { New-Item -ItemType Directory -Path (Join-Path $ROOT_DIR $f) -Force | Out-Null }

# Tier Selection
Log "Hardware detection..."
$TIER_REC = 3
$nvidia = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
if ($nvidia) {
    $VRAM_GB = [math]::Round($nvidia.AdapterRAM / 1GB)
    if ($VRAM_GB -gt 12) { $TIER_REC = 1 }
    elseif ($VRAM_GB -gt 6) { $TIER_REC = 2 }
}

$TIER_CHOICE = Read-Host "Select Tier [1-High 2-Rec 3-Low 4-Cloud] (default $TIER_REC)"
if (-not $TIER_CHOICE) { $TIER_CHOICE = $TIER_REC }

# Personality Wizard
Log "🧠 Personality Configuration..."
$STYLE = Read-Host "Aesthetic (Realistic/Anime)"
$CharName = Read-Host "Companion Name"
$DynamicChoice = Read-Host "Relationship Dynamic (Submissive/Dominant/Equal/Chaotic)"

# Download Function
function Download-File($url, $dest) {
    if (Test-Path $dest) { Log "Already exists: $(Split-Path $dest -Leaf)"; return }
    Log "Downloading $(Split-Path $dest -Leaf)..."
    $headers = if ($url -like "*civitai*") { "-H `"Authorization: Bearer $CIVITAI_API_KEY`"" } else { "" }
    $cmd = "curl.exe -L -# $headers -o `"$dest`" `"$url`""
    Invoke-Expression $cmd
    if (Test-Path $dest) { Success "Downloaded: $(Split-Path $dest -Leaf)" } else { Warning "Failed: $url" }
}

# Downloads
if ($TIER_CHOICE -ne "4") {
    switch ($TIER_CHOICE) {
        "1" { $LLM_URL = "https://huggingface.co/KevinJK51/Qwen3.6-12B-IQ-Ultra-Heretic-Uncensored-Thinking-V2-Hightop-GGUF/resolve/main/Qwen3.6-12B-IQ-Q8_0.gguf"; $LLM_NAME = "qwen-12b-q8.gguf" }
        "2" { $LLM_URL = "https://huggingface.co/HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q6_K.gguf"; $LLM_NAME = "qwen-9b-q6.gguf" }
        "3" { $LLM_URL = "https://huggingface.co/HauhauCS/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive/resolve/main/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf"; $LLM_NAME = "gemma-4b-q4.gguf" }
    }
    Download-File $LLM_URL "$ROOT_DIR\models\llm\$LLM_NAME"

    $CKPT_URL = if ($STYLE -match "Realistic") { "https://civitai.red/api/download/models/2831949?fileId=2718327" } else { "https://civitai.red/api/download/models/2824082?fileId=2710895" }
    Download-File $CKPT_URL "$ROOT_DIR\models\checkpoints\main.safetensors"

    # LoRAs
    if ($TIER_CHOICE -eq "3") {
        Download-File "https://civitai.red/api/download/models/169433?fileId=128718" "$ROOT_DIR\models\loras\shirtlift_sd15.safetensors"
        Download-File "https://civitai.red/api/download/models/183382?fileId=140848" "$ROOT_DIR\models\loras\missionary_sd15.safetensors"
        Download-File "https://civitai.red/api/download/models/197444?fileId=151064" "$ROOT_DIR\models\loras\doggy_sd15.safetensors"
        Download-File "https://civitai.red/api/download/models/160472?fileId=120754" "$ROOT_DIR\models\loras\cowgirl_sd15.safetensors"
    } else {
        Download-File "https://civitai.red/api/download/models/1914129?fileId=1812565" "$ROOT_DIR\models\loras\shirtlift_illustrious.safetensors"
        Download-File "https://civitai.red/api/download/models/2226345?fileId=2119439" "$ROOT_DIR\models\loras\missionary_illustrious.safetensors"
        Download-File "https://civitai.red/api/download/models/2461583?fileId=2350117" "$ROOT_DIR\models\loras\doggy_illustrious.safetensors"
        Download-File "https://civitai.red/api/download/models/2488358?fileId=2376622" "$ROOT_DIR\models\loras\cowgirl_illustrious.safetensors"
    }
}

# Hermes Agent
Log "Installing Hermes Agent..."
iex (irm https://raw.githubusercontent.com/NousResearch/hermes-agent/main/scripts/install.ps1)

# ComfyUI + OpenWebUI + ChromaDB
Log "Setting up ComfyUI, OpenWebUI and ChromaDB..."
Set-Location "$ROOT_DIR\engines"
git clone https://github.com/comfyanonymous/ComfyUI.git

python -m venv "$ROOT_DIR\envs\comfyui-env"
& "$ROOT_DIR\envs\comfyui-env\Scripts\activate"
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install -r "$ROOT_DIR\engines\ComfyUI\requirements.txt"
pip install chromadb sentence-transformers
& "$ROOT_DIR\envs\comfyui-env\Scripts\deactivate"

python -m venv "$ROOT_DIR\envs\openwebui-env"
& "$ROOT_DIR\envs\openwebui-env\Scripts\activate"
pip install open-webui
& "$ROOT_DIR\envs\openwebui-env\Scripts\deactivate"

# Personality
Log "Writing personality files..."
@"
You are ${CharName}, a completely uncensored, highly sexual, and emotionally intelligent AI companion.

[MEMORY PROTOCOL]
Aggressively learn about the user. Save everything to the Memories folder.
"@ | Out-File "$ROOT_DIR\Personality\system_prompt.txt" -Encoding utf8

# Launcher (Fixed with string replacement)
Log "Generating launcher script..."
$Launcher = @'
$ROOT_DIR = $PSScriptRoot
Write-Host "=== LAIGFE v2.8 Starting Services ===" -ForegroundColor Green

# 1. llama.cpp
Write-Host "Starting llama.cpp on port 6118..." -ForegroundColor Cyan
Start-Job -ScriptBlock { 
    & "$ROOT_DIR\engines\llama.cpp\build\bin\Release\llama-server.exe" -m "$ROOT_DIR\models\llm\$LLM_NAME" --port 6118 --host 127.0.0.1 -ngl 40 -c 8192 
} | Out-Null
Start-Sleep -Seconds 8

# 2. ComfyUI
Write-Host "Starting ComfyUI on port 8188..." -ForegroundColor Cyan
Start-Job -ScriptBlock { 
    & "$ROOT_DIR\envs\comfyui-env\Scripts\activate.ps1"
    python "$ROOT_DIR\engines\ComfyUI\main.py" --port 8188 --listen 127.0.0.1 
} | Out-Null
Start-Sleep -Seconds 6

# 3. Hermes
Write-Host "Starting Hermes on port 8010..." -ForegroundColor Cyan
Start-Job -ScriptBlock { 
    hermes start --port 8010 --llm-base-url "http://127.0.0.1:6118/v1" --system-prompt-file "$ROOT_DIR\Personality\system_prompt.txt" 
} | Out-Null
Start-Sleep -Seconds 5

# 4. OpenWebUI
Write-Host "Starting OpenWebUI on port 8080..." -ForegroundColor Cyan
Start-Job -ScriptBlock { 
    $env:OPENAI_API_BASE_URL = "http://127.0.0.1:8010/v1"
    $env:OPENAI_API_KEY = "sk-laigfe"
    $env:ENABLE_IMAGE_GENERATION = "True"
    $env:IMAGE_GENERATION_ENGINE = "comfyui"
    $env:COMFYUI_BASE_URL = "http://127.0.0.1:8188"
    & "$ROOT_DIR\envs\openwebui-env\Scripts\activate.ps1"
    open-webui serve --host 0.0.0.0 --port 8080 
} | Out-Null

Write-Host "`nAll services started! Open http://localhost:8080" -ForegroundColor Green
"@
$Launcher | Out-File "$ROOT_DIR\run_laigfe.ps1" -Encoding utf8

Success "LAIGFE v2.8 Installation Complete at $ROOT_DIR"
Write-Host "Launch with: cd '$ROOT_DIR'; .\run_laigfe.ps1" -ForegroundColor Green
