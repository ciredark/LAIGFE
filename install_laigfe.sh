#!/bin/bash
set -e

# ============================================================================
# LAIGFE v2.2 - Local AI Girlfriend Experience
# Hardened Bare-Metal Deployment with Natural NSFW LoRA Triggering
# ============================================================================

GREEN='\033[0;32m' CYAN='\033[0;36m' YELLOW='\033[1;33m' PURPLE='\033[0;35m' RED='\033[0;31m' NC='\033[0m'

log() { echo -e "${CYAN}[$(date +'%H:%M:%S')] $*${NC}" >&2; }
error() { echo -e "${RED}[ERROR] $*${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}[SUCCESS] $*${NC}" >&2; }
warning() { echo -e "${YELLOW}[WARNING] $*${NC}" >&2; }

if [[ $EUID -eq 0 ]]; then error "Do not run as root!"; fi

# Install dependencies
function install_deps() {
  log "Installing system dependencies..."
  if [ -f /etc/debian_version ]; then
    sudo apt update && sudo apt install -y build-essential cmake git curl python3-pip python3-venv python3-dev ffmpeg libvlc-dev feh net-tools lsof openssl netcat-traditional
    if ! command -v node &> /dev/null; then
      curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs
    fi
  elif [ -f /etc/arch-release ]; then
    sudo pacman -Syu --needed --noconfirm base-devel cmake git curl python python-pip python-venv ffmpeg nodejs npm vlc feh net-tools lsof openssl gnu-netcat
  elif [ -f /etc/fedora-release ]; then
    sudo dnf groupinstall -y "Development Tools" && sudo dnf install -y cmake git curl python3-pip python3-devel ffmpeg nodejs npm vlc feh net-tools lsof openssl nc
  else
    warning "Unsupported OS. Please install dependencies manually."
  fi
}

read -p "Install/verify dependencies? (y/N): " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] && install_deps

# Hardware detection and tier selection (condensed for GitHub)
log "Detecting hardware..."
CPU_CORES=$(nproc)
GPU_VRAM_MB=0
if command -v nvidia-smi > /dev/null; then GPU_VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1); fi

TIER_REC=3
if (( GPU_VRAM_MB > 12000 )); then TIER_REC=1; elif (( GPU_VRAM_MB > 6000 )); then TIER_REC=2; fi

echo "Select Tier: 1-High 2-Rec 3-Low 4-Cloud"
read -p "Choice (default $TIER_REC): " TIER_CHOICE
TIER_CHOICE=${TIER_CHOICE:-$TIER_REC}

BASE_PATH="${HOME}/LAIGFE"
ROOT_DIR="${BASE_PATH}/LAIGFE"
mkdir -p "$ROOT_DIR"/models/loras

# LoRA downloads using your links
log "Downloading NSFW LoRAs..."
download_lora() {
  curl -L --progress-bar -C - -o "$2" "$1" || true
}

if [[ "$TIER_CHOICE" != "4" ]]; then
  if [[ "$TIER_CHOICE" == "3" ]]; then
    download_lora "https://civitai.red/api/download/models/169433?fileId=128718" "$ROOT_DIR/models/loras/shirtlift_sd15.safetensors"
    download_lora "https://civitai.red/api/download/models/183382?fileId=140848" "$ROOT_DIR/models/loras/missionary_sd15.safetensors"
    download_lora "https://civitai.red/api/download/models/197444?fileId=151064" "$ROOT_DIR/models/loras/doggy_sd15.safetensors"
    download_lora "https://civitai.red/api/download/models/160472?fileId=120754" "$ROOT_DIR/models/loras/cowgirl_sd15.safetensors"
  else
    # Illustrious / Pony based on style choice (simplified)
    download_lora "https://civitai.red/api/download/models/1914129?fileId=1812565" "$ROOT_DIR/models/loras/shirtlift_illustrious.safetensors"
    download_lora "https://civitai.red/api/download/models/2226345?fileId=2119439" "$ROOT_DIR/models/loras/missionary_illustrious.safetensors"
    download_lora "https://civitai.red/api/download/models/2461583?fileId=2350117" "$ROOT_DIR/models/loras/doggy_illustrious.safetensors"
    download_lora "https://civitai.red/api/download/models/2488358?fileId=2376622" "$ROOT_DIR/models/loras/cowgirl_illustrious.safetensors"
  fi
fi

success "Current LAIGFE script saved to GitHub. Run the full installer for complete setup."
