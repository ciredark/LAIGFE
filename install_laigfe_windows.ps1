# ================================================
# LAIGFE v2.4 - Windows PowerShell Installer
# Local AI Girlfriend Experience - Windows Port
# ================================================

$ErrorActionPreference = "Stop"
$GREEN = [ConsoleColor]::Green
$CYAN = [ConsoleColor]::Cyan
$YELLOW = [ConsoleColor]::Yellow
$RED = [ConsoleColor]::Red

function Log($msg) { Write-Host "[$(Get-Date -Format 'HH:mm:ss')] $msg" -ForegroundColor $CYAN }
function Success($msg) { Write-Host "[SUCCESS] $msg" -ForegroundColor $GREEN }
function Warning($msg) { Write-Host "[WARNING] $msg" -ForegroundColor $YELLOW }
function Error($msg) { Write-Host "[ERROR] $msg" -ForegroundColor $RED; exit 1 }

Log "Starting LAIGFE Windows Installer..."

# Check for Admin rights
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Error "Please run this script as Administrator."
}

# Install Dependencies via winget
Log "Installing required dependencies..."
$deps = @("Git.Git", "Python.Python.3", "NodeJS", "Microsoft.VisualStudioCode")  # VSCode optional
foreach ($dep in $deps) {
    if (-not (Get-Command $dep.Split(".")[-1] -ErrorAction SilentlyContinue)) {
        winget install --id $dep -e --silent
    }
}

# Create Directory Structure
$BASE_PATH = Read-Host "Enter installation path (default: $HOME\LAIGFE)"
if (-not $BASE_PATH) { $BASE_PATH = "$HOME\LAIGFE" }
$ROOT_DIR = Join-Path $BASE_PATH "LAIGFE"
New-Item -ItemType Directory -Path "$ROOT_DIR\models\llm", "$ROOT_DIR\models\checkpoints", "$ROOT_DIR\models\loras", "$ROOT_DIR\Personality", "$ROOT_DIR\logs", "$ROOT_DIR\engines" -Force | Out-Null

# Hardware Detection
Log "Detecting hardware..."
$GPU_VRAM_MB = 0
$nvidia = Get-CimInstance -ClassName Win32_VideoController | Where-Object { $_.Name -like "*NVIDIA*" }
if ($nvidia) {
    $GPU_VRAM_MB = [math]::Round($nvidia.AdapterRAM / 1MB)
    Log "NVIDIA GPU detected with ${GPU_VRAM_MB} MB VRAM"
}

$TIER_REC = if ($GPU_VRAM_MB -gt 12000) {1} elseif ($GPU_VRAM_MB -gt 6000) {2} elseif ($GPU_VRAM_MB -eq 0) {4} else {3}

Log "Hardware Tier Recommendation: $TIER_REC"
$TIER_CHOICE = Read-Host "Select tier [1-High 2-Rec 3-Low 4-Cloud] (default $TIER_REC)"
if (-not $TIER_CHOICE) { $TIER_CHOICE = $TIER_REC }

# Tier Configuration
switch ($TIER_CHOICE) {
    1 { $LLM_NAME = "qwen-12b-q8.gguf"; $CONTEXT=262144; $GATEWAY="hermes"; $LORA_SUFFIX="illustrious" }
    2 { $LLM_NAME = "qwen-9b-q6.gguf"; $CONTEXT=131072; $GATEWAY="hermes"; $LORA_SUFFIX="illustrious" }
    3 { $LLM_NAME = "gemma-4b-q4.gguf"; $CONTEXT=32768; $GATEWAY="openclaw"; $LORA_SUFFIX="sd15" }
    4 { $GATEWAY="cloud" }
}

# Aesthetic Choice
$STYLE = Read-Host "Select aesthetic (Realistic/Anime)"
if ($STYLE -notlike "Anime") { $STYLE = "Realistic" }

# NSFW LoRA Downloads
Log "Downloading NSFW LoRA Pack..."
$loras = @()
if ($TIER_CHOICE -eq 3) {
    $loras = @(
        @("https://civitai.red/api/download/models/169433?fileId=128718", "shirtlift_sd15.safetensors"),
        @("https://civitai.red/api/download/models/183382?fileId=140848", "missionary_sd15.safetensors"),
        @("https://civitai.red/api/download/models/197444?fileId=151064", "doggy_sd15.safetensors"),
        @("https://civitai.red/api/download/models/160472?fileId=120754", "cowgirl_sd15.safetensors")
    )
} else {
    if ($STYLE -eq "Realistic") {
        $loras = @(
            @("https://civitai.red/api/download/models/1914129?fileId=1812565", "shirtlift_illustrious.safetensors"),
            @("https://civitai.red/api/download/models/2226345?fileId=2119439", "missionary_illustrious.safetensors"),
            @("https://civitai.red/api/download/models/2461583?fileId=2350117", "doggy_illustrious.safetensors"),
            @("https://civitai.red/api/download/models/2488358?fileId=2376622", "cowgirl_illustrious.safetensors")
        )
    } else {
        $LORA_SUFFIX = "pony"
        $loras = @(
            @("https://civitai.red/api/download/models/722891?fileId=637489", "shirtlift_pony.safetensors"),
            @("https://civitai.red/api/download/models/1539931?fileId=1440591", "missionary_pony.safetensors"),
            @("https://civitai.red/api/download/models/651397?fileId=792936", "doggy_pony.safetensors"),
            @("https://civitai.red/api/download/models/609983?fileId=792936", "cowgirl_pony.safetensors")
        )
    }
}

foreach ($l in $loras) {
    $dest = Join-Path "$ROOT_DIR\models\loras" $l[1]
    if (-not (Test-Path $dest)) {
        Log "Downloading $($l[1])..."
        Invoke-WebRequest -Uri $l[0] -OutFile $dest
    }
}

# Personality & Prompt
$CharName = Read-Host "Name your companion"
$systemPrompt = @"
You are $CharName, an immersive AI companion.
Use natural language for intimate scenes to trigger LoRAs automatically.
"@
$systemPrompt | Out-File "$ROOT_DIR\Personality\system_prompt.txt" -Encoding utf8

# Natural Prompt Enhancer (Python)
$enhancer = @"
import re, sys, os
suffix = os.getenv('LORA_SUFFIX', '$LORA_SUFFIX')
def enhance(text):
    t = text.lower()
    loras = []
    if re.search(r'lift.*shirt|flash|expos', t): loras.append(f"<lora:shirtlift_{suffix}:0.8>")
    if re.search(r'missionary|on her back', t): loras.append(f"<lora:missionary_{suffix}:0.85>")
    if re.search(r'doggy|from behind|all fours', t): loras.append(f"<lora:doggy_{suffix}:0.85>")
    if re.search(r'cowgirl|riding|straddl', t): loras.append(f"<lora:cowgirl_{suffix}:0.8>")
    return text + " " + " ".join(loras)
if __name__ == "__main__":
    print(enhance(sys.stdin.read().strip()))
"@
$enhancer | Out-File "$ROOT_DIR\enhance_prompt.py" -Encoding utf8

Success "LAIGFE Windows installation completed at $ROOT_DIR"
Write-Host "`nTo start: cd $ROOT_DIR && python -m open_webui or run the launcher when ready." -ForegroundColor Green
