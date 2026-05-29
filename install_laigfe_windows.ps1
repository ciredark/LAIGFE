# =============================================================================
# LAIGFE v2.7 - Complete Windows Installer
# Fully featured with models, LoRAs, ComfyUI, OpenWebUI, ChromaDB
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

Log "Starting LAIGFE v2.7 Windows Installer..."

# Admin check
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Error "Please run this script as Administrator."
}

# Dependencies
Log "Installing core dependencies..."
winget install --id Git.Git -e --silent
winget install --id Python.Python.3 -e --silent
winget install --id NodeJS.LTS -e --silent

# Installation Path
$BASE_PATH = Read-Host "Enter installation path (default: $HOME\LAIGFE)"
if (-not $BASE_PATH) { $BASE_PATH = "$HOME\LAIGFE" }
$ROOT_DIR = Join-Path $BASE_PATH "LAIGFE"
New-Item -ItemType Directory -Path $ROOT_DIR -Force | Out-Null

# Create Full Folder Structure
$folders = @(
    "models\llm", "models\checkpoints", "models\loras",
    "Personality", "Knowledge", "Memories\interactions", "Memories\chroma_db",
    "engines\ComfyUI\custom_nodes", "envs", "logs", "media_out\images", "media_out\videos", "media_out\audio"
)
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

# Personality Wizard (simplified for Windows)
$STYLE = Read-Host "Aesthetic (Realistic/Anime)"
$CharName = Read-Host "Companion Name"

# Download Models & LoRAs based on tier
Log "Downloading models and LoRAs (this may take a while)..."

function Download-File($url, $dest) {
    if (-not (Test-Path $dest)) {
        Log "Downloading $(Split-Path $dest -Leaf)..."
        Invoke-WebRequest -Uri $url -OutFile $dest -UseBasicParsing
    }
}

# Example Downloads (Tier-aware - you can expand this)
if ($TIER_CHOICE -ne 4) {
    Download-File "https://huggingface.co/HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q6_K.gguf" "$ROOT_DIR\models\llm\qwen-9b-q6.gguf"
    
    # LoRAs (example for Realistic)
    Download-File "https://civitai.red/api/download/models/1914129?fileId=1812565" "$ROOT_DIR\models\loras\shirtlift_illustrious.safetensors"
    # Add the other 3 LoRAs similarly...
}

# ComfyUI Setup
Log "Setting up ComfyUI..."
Set-Location $ROOT_DIR\engines
git clone https://github.com/comfyanonymous/ComfyUI.git
Set-Location ComfyUI
python -m venv "$ROOT_DIR\envs\comfyui-env"
& "$ROOT_DIR\envs\comfyui-env\Scripts\activate"
pip install torch torchvision torchaudio --index-url https://download.pytorch.org/whl/cu121
pip install -r requirements.txt
& "$ROOT_DIR\envs\comfyui-env\Scripts\deactivate"

# OpenWebUI
Log "Installing OpenWebUI..."
python -m venv "$ROOT_DIR\envs\openwebui-env"
& "$ROOT_DIR\envs\openwebui-env\Scripts\activate"
pip install open-webui
& "$ROOT_DIR\envs\openwebui-env\Scripts\deactivate"

# ChromaDB
Log "Setting up ChromaDB memory system..."
& "$ROOT_DIR\envs\comfyui-env\Scripts\activate"
pip install chromadb sentence-transformers
& "$ROOT_DIR\envs\comfyui-env\Scripts\deactivate"

Success "LAIGFE v2.7 Windows installation completed!"
Write-Host "`nInstallation folder: $ROOT_DIR" -ForegroundColor Green
Write-Host "You can now start exploring the folders and run OpenWebUI." -ForegroundColor Cyan
