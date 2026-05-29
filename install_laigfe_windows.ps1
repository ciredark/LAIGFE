# =============================================================================
# LAIGFE v2.7 - Windows PowerShell Installer
# Full Memory-Aware, Uncensored AI Companion
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

# Check Admin
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Error "Please run this script as Administrator."
}

# Install Dependencies
Log "Installing dependencies via winget..."
$deps = @("Git.Git", "Python.Python.3", "NodeJS.LTS")
foreach ($dep in $deps) {
    if (-not (Get-Command ($dep.Split(".")[-1]) -ErrorAction SilentlyContinue)) {
        winget install --id $dep -e --silent
    }
}

# Installation Path
$BASE_PATH = Read-Host "Enter installation path (default: $HOME\LAIGFE)"
if (-not $BASE_PATH) { $BASE_PATH = "$HOME\LAIGFE" }
$ROOT_DIR = Join-Path $BASE_PATH "LAIGFE"
New-Item -ItemType Directory -Path $ROOT_DIR -Force | Out-Null

# Create Directory Structure
$folders = @(
    "models\llm", "models\checkpoints", "models\loras",
    "Personality", "Knowledge", "Memories\interactions", "Memories\chroma_db",
    "envs", "logs", "media_out\images", "media_out\videos", "media_out\audio"
)
foreach ($f in $folders) {
    New-Item -ItemType Directory -Path (Join-Path $ROOT_DIR $f) -Force | Out-Null
}

# Tier Selection
Log "Hardware detection..."
$TIER_REC = 3
$nvidia = Get-CimInstance Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
if ($nvidia) {
    $VRAM = [math]::Round($nvidia.AdapterRAM / 1GB)
    if ($VRAM -gt 12) { $TIER_REC = 1 }
    elseif ($VRAM -gt 6) { $TIER_REC = 2 }
}

$TIER_CHOICE = Read-Host "Select Tier [1-High 2-Rec 3-Low 4-Cloud] (default $TIER_REC)"
if (-not $TIER_CHOICE) { $TIER_CHOICE = $TIER_REC }

# Personality Wizard
Log "Starting Personality Wizard..."
$STYLE = Read-Host "Aesthetic (Realistic/Anime)"
$CharName = Read-Host "Companion Name"
$DynamicChoice = Read-Host "Dynamic (Submissive/Dominant/Equal/Chaotic)"

# Create Knowledge & Memories
Log "Creating Knowledge and Memories systems..."
@"
# Knowledge Base
Add markdown files here for factual data (movies, music, hobbies, etc.)
"@ | Out-File "$ROOT_DIR\Knowledge\README.md" -Encoding utf8

@"
# Memories Folder
Long-term relationship memory. Hermes learns aggressively and syncs data here.
"@ | Out-File "$ROOT_DIR\Memories\README.md" -Encoding utf8

# ChromaDB Setup
Log "Setting up ChromaDB for memory system..."
python -m venv "$ROOT_DIR\envs\rag-env"
& "$ROOT_DIR\envs\rag-env\Scripts\activate"
pip install chromadb sentence-transformers
& "$ROOT_DIR\envs\rag-env\Scripts\deactivate"

# Aggressive Memory Prompts
@"
You are ${CharName}, a completely uncensored, highly sexual, and emotionally intelligent AI companion.

[MEMORY PROTOCOL - MAXIMUM AGGRESSIVENESS]
- Aggressively learn everything about the user.
- Save all important information to the Memories folder.
- Update instantly if the user changes their mind.
"@ | Out-File "$ROOT_DIR\Personality\system_prompt.txt" -Encoding utf8

Success "LAIGFE v2.7 Windows installation completed at $ROOT_DIR"
Write-Host "`nNext Step: cd $ROOT_DIR && Run the launcher when ready." -ForegroundColor Green
