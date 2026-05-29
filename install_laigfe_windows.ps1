# =============================================================================
# LAIGFE v2.8 - Complete Windows Production Installer
# Full Memory System, Uncensored, Multi-Modal, ChromaDB, Hermes
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

# Path & Folders
$BASE_PATH = Read-Host "Installation path (default: $HOME\LAIGFE)"
if (-not $BASE_PATH) { $BASE_PATH = "$HOME\LAIGFE" }
$ROOT_DIR = Join-Path $BASE_PATH "LAIGFE"
New-Item -ItemType Directory -Path $ROOT_DIR -Force | Out-Null

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

$HairDesc = Read-Host "Hair description"
$EyeDesc = Read-Host "Eyes description"
$BuildDesc = Read-Host "Build/Figure description"
$PHYSICAL = "Hair: $HairDesc, Eyes: $EyeDesc, Build: $BuildDesc"

# Download Function (CURL)
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
    # LLM
    switch ($TIER_CHOICE) {
        "1" { $LLM_URL = "https://huggingface.co/KevinJK51/Qwen3.6-12B-IQ-Ultra-Heretic-Uncensored-Thinking-V2-Hightop-GGUF/resolve/main/Qwen3.6-12B-IQ-Q8_0.gguf"; $LLM_NAME = "qwen-12b-q8.gguf" }
        "2" { $LL
