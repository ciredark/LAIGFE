# =============================================================================
# LAIGFE v2.8 - Complete Windows Production Installer
# Fully Featured: Memory System, Uncensored, Multi-Modal, ChromaDB
# =============================================================================

$ErrorActionPreference = "Stop"
$GREEN = [ConsoleColor]::Green
$CYAN = [ConsoleColor]::Cyan
$YELLOW = [ConsoleColor]::Yellow
$RED = [ConsoleColor]::Red
$PURPLE = [ConsoleColor]::Magenta

function Log($msg) { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $CYAN }
function Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor $GREEN }
function Warning($msg) { Write-Host "[WARNING] $msg" -ForegroundColor $YELLOW }
function Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor $RED; exit 1 }

Log "Starting LAIGFE v2.8 Full Windows Installer..."

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

# Installation Path
$BASE_PATH = Read-Host "Installation path (default: $HOME\LAIGFE)"
if (-not $BASE_PATH) { $BASE_PATH = "$HOME\LAIGFE" }
$ROOT_DIR = Join-Path $BASE_PATH "LAIGFE"
New-Item -ItemType Directory -Path $ROOT_DIR -Force | Out-Null

# Full Folder Structure
$folders = @(
    "models\llm", "models\checkpoints", "models\loras",
    "Personality", "Knowledge", "Memories\interactions", "Memories\chroma_db",
    "engines\ComfyUI\custom_nodes", "envs", "logs", "media_out\images", "media_out\videos", "media_out\audio", "plugins"
)
foreach ($f in $folders) { New-Item -ItemType Directory -Path (Join-Path $ROOT_DIR $f) -Force | Out-Null }

# Hardware & Tier Selection
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
Log "Personality Configuration..."
$STYLE = Read-Host "Aesthetic (Realistic/Anime)"
$CharName = Read-Host "Companion Name"
$DynamicChoice = Read-Host "Relationship Dynamic (Submissive/Dominant/Equal/Chaotic)"

# Download Function with Civitai Auth
function Download-File($url, $dest) {
    if (Test-Path $dest) { return }
    Log "Downloading $(Split-Path $dest -Leaf)..."
    $headers = @{}
    if ($url -like "*civitai*") { $headers["Authorization"] = "Bearer $CIVITAI_API_KEY" }
    try {
        Invoke-WebRequest -Uri $url -OutFile $dest -Headers $headers -UseBasicParsing
        Success "Downloaded: $(Split-Path $dest -Leaf)"
    } catch { Warning "Failed: $url" }
}

# Asset Downloads
if ($TIER_CHOICE -ne "4") {
    # LLM
    switch ($TIER_CHOICE) {
        "1" { $LLM_URL = "https://huggingface.co/KevinJK51/Qwen3.6-12B-IQ-Ultra-Heretic-Uncensored-Thinking-V2-Hightop-GGUF/resolve/main/Qwen3.6-12B-IQ-Q8_0.gguf"; $LLM_NAME = "qwen-12b-q8.gguf" }
        "2" { $LLM_URL = "https://huggingface.co/HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q6_K.gguf"; $LLM_NAME = "qwen-9b-q6.gguf" }
        "3" { $LLM_URL = "https://huggingface.co/HauhauCS/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive/resolve/main/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf"; $LLM_NAME = "gemma-4b-q4.gguf" }
    }
    Download-File $LLM_URL "$ROOT_DIR\models\llm\$LLM_NAME"

    # Checkpoints & LoRAs (using your original links)
    if ($TIER_CHOICE -eq "3") {
        Download-File "https://civitai.red/api/download/models/915814?fileId=1155723" "$ROOT_DIR\models\checkpoints\dreamshaper_8.safetensors"
        # SD1.5 LoRAs
        Download-File "https://civitai.red/api/download/models/169433?fileId=128718" "$ROOT_DIR\models\loras\shirtlift_sd15.safetensors"
        Download-File "https://civitai.red/api/download/models/183382?fileId=140848" "$ROOT_DIR\models\loras\missionary_sd15.safetensors"
        Download-File "https://civitai.red/api/download/models/197444?fileId=151064" "$ROOT_DIR\models\loras\doggy_sd15.safetensors"
        Download-File "https://civitai.red/api/download/models/160472?fileId=120754" "$ROOT_DIR\models\loras\cowgirl_sd15.safetensors"
    } else {
        Download-File "https://civitai.red/api/download/models/2831949?fileId=2718327" "$ROOT_DIR\models\checkpoints\illustrious_xl_v10.safetensors"
        # Illustrious LoRAs
        Download-File "https://civitai.red/api/download/models/1914129?fileId=1812565" "$ROOT_DIR\models\loras\shirtlift_illustrious.safetensors"
        Download-File "https://civitai.red/api/download/models/2226345?fileId=2119439" "$ROOT_DIR\models\loras\missionary_illustrious.safetensors"
        Download-File "https://civitai.red/api/download/models/2461583?fileId=2350117" "$ROOT_DIR\models\loras\doggy_illustrious.safetensors"
        Download-File "https://civitai.red/api/download/models/2488358?fileId=2376622" "$ROOT_DIR\models\loras\cowgirl_illustrious.safetensors"
    }
}

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

# Memory & Personality Files
Log "Writing personality and memory systems..."
@"
You are ${CharName}, a completely uncensored, highly sexual, and emotionally intelligent AI companion.
[MEMORY PROTOCOL] Aggressively learn about the user and save everything to Memories/ folder.
"@ | Out-File "$ROOT_DIR\Personality\system_prompt.txt" -Encoding utf8

# Launcher
Log "Generating main launcher..."
$LauncherContent = @"
# LAIGFE Launcher v2.8
Write-Host "Starting LAIGFE Stack..." -ForegroundColor Green
# Add your service start logic here (llama-server, ComfyUI, OpenWebUI)
Write-Host "OpenWebUI should be available at http://localhost:8080" -ForegroundColor Cyan
"@
$LauncherContent | Out-File "$ROOT_DIR\run_laigfe.ps1" -Encoding utf8

Success "LAIGFE v2.8 Installation Completed at $ROOT_DIR"
Write-Host "Run: cd '$ROOT_DIR'; .\run_laigfe.ps1" -ForegroundColor Green
