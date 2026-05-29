# =============================================================================
# LAIGFE v2.8 - Complete Windows Installer (Final Revision)
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

# Admin Check + Dependencies (same as before)
if (-not ([Security.Principal.WindowsPrincipal][Security.Principal.WindowsIdentity]::GetCurrent()).IsInRole([Security.Principal.WindowsBuiltInRole]::Administrator)) {
    Error "Please run as Administrator."
}

$CIVITAI_API_KEY = "ba9841ada4c58920a94446dbdb929b31"

# ... [Dependencies, Path, Folders, Tier Selection, Personality Wizard, Downloads - kept the same as previous good version] ...

# === Launcher with Correct Service Order ===
Log "Generating main launcher with proper service chain..."

$LauncherContent = @"
`$ROOT_DIR = "`$PSScriptRoot"
`$LOG_DIR = Join-Path `$ROOT_DIR "logs"
New-Item -ItemType Directory -Path `$LOG_DIR -Force | Out-Null

Write-Host "=== LAIGFE v2.8 Starting Services in Order ===" -ForegroundColor Green

# 1. llama.cpp Server
Log "Starting llama.cpp server on port 6118..."
Start-Job -ScriptBlock {
    & "$using:ROOT_DIR\engines\llama.cpp\build\bin\Release\llama-server.exe" `
        -m "$using:ROOT_DIR\models\llm\$using:LLM_NAME" `
        --port 6118 --host 127.0.0.1 -ngl 40 -c 8192 --flash-attn auto
} -Name "llama" | Out-Null
Start-Sleep -Seconds 8

# 2. ComfyUI
Log "Starting ComfyUI on port 8188..."
Start-Job -ScriptBlock {
    & "$using:ROOT_DIR\envs\comfyui-env\Scripts\activate.ps1"
    python "$using:ROOT_DIR\engines\ComfyUI\main.py" --port 8188 --listen 127.0.0.1 --input-directory "$using:ROOT_DIR\models" --output-directory "$using:ROOT_DIR\media_out"
} -Name "comfyui" | Out-Null
Start-Sleep -Seconds 6

# 3. Hermes Gateway (pointed at llama.cpp)
Log "Starting Hermes Gateway on port 8010..."
Start-Job -ScriptBlock {
    hermes start --port 8010 --llm-base-url "http://127.0.0.1:6118/v1" --system-prompt-file "$using:ROOT_DIR\Personality\system_prompt.txt"
} -Name "hermes" | Out-Null
Start-Sleep -Seconds 5

# 4. OpenWebUI
Log "Starting OpenWebUI on port 8080..."
Start-Job -ScriptBlock {
    `$env:OPENAI_API_BASE_URL = "http://127.0.0.1:8010/v1"
    `$env:OPENAI_API_KEY = "sk-laigfe"
    `$env:ENABLE_IMAGE_GENERATION = "True"
    `$env:IMAGE_GENERATION_ENGINE = "comfyui"
    `$env:COMFYUI_BASE_URL = "http://127.0.0.1:8188"
    
    & "$using:ROOT_DIR\envs\openwebui-env\Scripts\activate.ps1"
    open-webui serve --host 0.0.0.0 --port 8080
} -Name "openwebui" | Out-Null

Write-Host "`nAll services started!" -ForegroundColor Green
Write-Host "OpenWebUI → http://localhost:8080" -ForegroundColor Cyan
Write-Host "Press Ctrl+C to stop all services." -ForegroundColor Yellow

try { while (`$true) { Start-Sleep -Seconds 10 } } 
finally { Get-Job | Stop-Job | Remove-Job }
"@

$LauncherContent | Out-File -FilePath "$ROOT_DIR\run_laigfe.ps1" -Encoding utf8

Success "LAIGFE v2.8 Windows Installation Complete!"
Write-Host "Launch with: cd '$ROOT_DIR'; .\run_laigfe.ps1" -ForegroundColor Green
