```bash
#!/bin/bash
set -euo pipefail

# ============================================================================
# LAIGFE v2.6 - Hardened Production Installer
# ============================================================================

GREEN='\033[0;32m'
CYAN='\033[0;36m'
YELLOW='\033[1;33m'
PURPLE='\033[0;35m'
RED='\033[0;31m'
NC='\033[0m'

log() {
    echo -e "${CYAN}[$(date +'%H:%M:%S')] $*${NC}" >&2
}

error() {
    echo -e "${RED}[ERROR] $*${NC}" >&2
    exit 1
}

success() {
    echo -e "${GREEN}[SUCCESS] $*${NC}" >&2
}

warning() {
    echo -e "${YELLOW}[WARNING] $*${NC}" >&2
}

[[ $EUID -eq 0 ]] && error "Do not run as root!"

# ============================================================================
# Dependency Installation
# ============================================================================

install_deps() {
    log "Installing system dependencies..."

    if [ -f /etc/debian_version ]; then

        sudo apt update

        sudo apt install -y \
            build-essential \
            cmake \
            git \
            curl \
            wget \
            python3-pip \
            python3-venv \
            python3-dev \
            ffmpeg \
            net-tools \
            lsof \
            openssl \
            netcat-traditional \
            aria2 \
            file

        if ! command -v node >/dev/null 2>&1; then
            log "Installing Node.js..."
            curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash -
            sudo apt install -y nodejs
        fi

    elif [ -f /etc/arch-release ]; then

        sudo pacman -Syu --needed --noconfirm \
            base-devel \
            cmake \
            git \
            curl \
            wget \
            python \
            python-pip \
            python-venv \
            ffmpeg \
            nodejs \
            npm \
            net-tools \
            lsof \
            openssl \
            gnu-netcat \
            aria2 \
            file

    elif [ -f /etc/fedora-release ]; then

        sudo dnf groupinstall -y "Development Tools"

        sudo dnf install -y \
            cmake \
            git \
            curl \
            wget \
            python3-pip \
            python3-devel \
            ffmpeg \
            nodejs \
            npm \
            net-tools \
            lsof \
            openssl \
            nc \
            aria2 \
            file

    else
        warning "Unsupported OS. Install dependencies manually."
    fi
}

read -p "Install dependencies? (y/N): " -n 1 -r
echo

[[ $REPLY =~ ^[Yy]$ ]] && install_deps

# ============================================================================
# Hardware Detection
# ============================================================================

log "Hardware assessment..."

CPU_CORES=$(nproc)
GPU_TYPE="none"
GPU_VRAM_MB=0

if command -v nvidia-smi >/dev/null 2>&1; then

    GPU_TYPE="nvidia"

    GPU_VRAM_MB=$(
        nvidia-smi \
        --query-gpu=memory.total \
        --format=csv,noheader,nounits \
        | head -n1
    )

elif command -v rocm-smi >/dev/null 2>&1; then

    GPU_TYPE="amd"

    GPU_VRAM_MB=$(
        rocm-smi --showmeminfo vram 2>/dev/null \
        | grep -o '[0-9]\+' \
        | head -n1 || true
    )

    GPU_VRAM_MB=${GPU_VRAM_MB:-0}
fi

GPU_VRAM_MB=${GPU_VRAM_MB:-0}

TIER_REC=3

(( GPU_VRAM_MB > 12000 )) && TIER_REC=1
(( GPU_VRAM_MB > 6000 && GPU_VRAM_MB <= 12000 )) && TIER_REC=2
(( GPU_VRAM_MB == 0 )) && TIER_REC=4

log "Detected GPU Type: $GPU_TYPE"
log "Detected VRAM: ${GPU_VRAM_MB}MB"
log "Recommended Tier: $TIER_REC"

echo
echo "Select tier:"
echo "1) High-End Local"
echo "2) Recommended Local"
echo "3) Lightweight Local"
echo "4) Cloud"

read -p "Selection (default $TIER_REC): " TIER_CHOICE

TIER_CHOICE=${TIER_CHOICE:-$TIER_REC}

# ============================================================================
# Installation Path
# ============================================================================

read -p "Install path (default ~/LAIGFE): " BASE_PATH
BASE_PATH=${BASE_PATH:-"$HOME/LAIGFE"}

ROOT_DIR="$BASE_PATH"

mkdir -p \
    "$ROOT_DIR"/{
        envs,
        engines,
        models/{llm,checkpoints,loras},
        Personality,
        config_ui,
        media_out,
        logs,
        scripts
    }

# ============================================================================
# Disk Space Validation
# ============================================================================

AVAILABLE_SPACE_GB=$(
    df -BG "$ROOT_DIR" \
    | awk 'NR==2 {gsub("G","",$4); print $4}'
)

REQUIRED_SPACE_GB=40

if (( AVAILABLE_SPACE_GB < REQUIRED_SPACE_GB )); then

    warning "Available disk space: ${AVAILABLE_SPACE_GB}GB"
    warning "Recommended minimum: ${REQUIRED_SPACE_GB}GB"

    read -p "Continue anyway? (y/N): " -n 1 -r
    echo

    [[ ! $REPLY =~ ^[Yy]$ ]] && error "Installation aborted."
fi

# ============================================================================
# Tier Configuration
# ============================================================================

case $TIER_CHOICE in

    1)
        LLM_URL="https://huggingface.co/KevinJK51/Qwen3.6-12B-IQ-Ultra-Heretic-Uncensored-Thinking-V2-Hightop-GGUF/resolve/main/Qwen3.6-12B-IQ-Q8_0.gguf"
        LLM_NAME="qwen-12b-q8.gguf"
        CONTEXT=262144
        N_GL=48
        GATEWAY="hermes"
        LORA_SUFFIX="illustrious"
        ;;

    2)
        LLM_URL="https://huggingface.co/HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q6_K.gguf"
        LLM_NAME="qwen-9b-q6.gguf"
        CONTEXT=131072
        N_GL=32
        GATEWAY="hermes"
        LORA_SUFFIX="illustrious"
        ;;

    3)
        LLM_URL="https://huggingface.co/HauhauCS/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive/resolve/main/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf"
        LLM_NAME="gemma-4b-q4.gguf"
        CONTEXT=32768
        N_GL=12
        GATEWAY="openclaw"
        LORA_SUFFIX="sd15"
        ;;

    4)
        GATEWAY="cloud"
        CONTEXT=131072
        LORA_SUFFIX="illustrious"
        ;;

    *)
        error "Invalid tier selected."
        ;;
esac

export LORA_SUFFIX

# ============================================================================
# Character Setup
# ============================================================================

read -p "Companion name (default Companion): " CharName
CharName=${CharName:-Companion}

export CharName

# ============================================================================
# Aesthetic Selection
# ============================================================================

if [ -t 0 ]; then

    echo
    echo "Select aesthetic:"

    select aesthetic in "Realistic" "Anime"; do
        STYLE=$aesthetic
        break
    done

else
    STYLE="Realistic"
fi

STYLE=${STYLE:-Realistic}

if [[ "$STYLE" == "Anime" ]]; then
    LORA_SUFFIX="pony"
    export LORA_SUFFIX
fi

log "Selected aesthetic: $STYLE"
log "LoRA suffix set to: $LORA_SUFFIX"

# ============================================================================
# Download Helpers
# ============================================================================

validate_model() {

    local file_path=$1

    if file "$file_path" | grep -qiE 'html|json|text'; then
        rm -f "$file_path"
        error "Downloaded file is invalid or corrupted: $file_path"
    fi
}

safe_download() {

    local url=$1
    local dest=$2
    local name=$3

    if [ -f "$dest" ]; then
        success "$name already exists. Skipping."
        return
    fi

    log "Downloading $name..."

    if command -v aria2c >/dev/null 2>&1; then

        aria2c \
            --continue=true \
            --max-connection-per-server=8 \
            --split=8 \
            --min-split-size=1M \
            --user-agent="Mozilla/5.0" \
            -d "$(dirname "$dest")" \
            -o "$(basename "$dest")" \
            "$url"

    else

        curl -L \
            --retry 5 \
            --retry-delay 3 \
            --progress-bar \
            --user-agent "Mozilla/5.0" \
            -C - \
            -o "$dest" \
            "$url"
    fi

    validate_model "$dest"

    success "$name downloaded successfully."
}

# ============================================================================
# LLM Download
# ============================================================================

if [[ "$GATEWAY" != "cloud" ]]; then

    safe_download \
        "$LLM_URL" \
        "${ROOT_DIR}/models/llm/${LLM_NAME}" \
        "$LLM_NAME"

else

    log "Cloud mode selected. Skipping local LLM download."
fi

# ============================================================================
# LoRA Downloads
# ============================================================================

log "Preparing LoRA configuration..."

if [[ "$GATEWAY" != "cloud" ]]; then

    if [[ "$TIER_CHOICE" == "3" ]]; then

        safe_download \
            "https://civitai.red/api/download/models/169433?fileId=128718" \
            "${ROOT_DIR}/models/loras/shirtlift_sd15.safetensors" \
            "Shirtlift SD1.5"

        safe_download \
            "https://civitai.red/api/download/models/183382?fileId=140848" \
            "${ROOT_DIR}/models/loras/missionary_sd15.safetensors" \
            "Missionary SD1.5"

        safe_download \
            "https://civitai.red/api/download/models/197444?fileId=151064" \
            "${ROOT_DIR}/models/loras/doggy_sd15.safetensors" \
            "Doggy SD1.5"

        safe_download \
            "https://civitai.red/api/download/models/160472?fileId=120754" \
            "${ROOT_DIR}/models/loras/cowgirl_sd15.safetensors" \
            "Cowgirl SD1.5"

    else

        if [[ "$STYLE" == "Realistic" ]]; then

            safe_download \
                "https://civitai.red/api/download/models/1914129?fileId=1812565" \
                "${ROOT_DIR}/models/loras/shirtlift_illustrious.safetensors" \
                "Shirtlift Illustrious"

            safe_download \
                "https://civitai.red/api/download/models/2226345?fileId=2119439" \
                "${ROOT_DIR}/models/loras/missionary_illustrious.safetensors" \
                "Missionary Illustrious"

            safe_download \
                "https://civitai.red/api/download/models/2461583?fileId=2350117" \
                "${ROOT_DIR}/models/loras/doggy_illustrious.safetensors" \
                "Doggy Illustrious"

            safe_download \
                "https://civitai.red/api/download/models/2488358?fileId=2376622" \
                "${ROOT_DIR}/models/loras/cowgirl_illustrious.safetensors" \
                "Cowgirl Illustrious"

        else

            safe_download \
                "https://civitai.red/api/download/models/722891?fileId=637489" \
                "${ROOT_DIR}/models/loras/shirtlift_pony.safetensors" \
                "Shirtlift Pony"

            safe_download \
                "https://civitai.red/api/download/models/1539931?fileId=1440591" \
                "${ROOT_DIR}/models/loras/missionary_pony.safetensors" \
                "Missionary Pony"

            safe_download \
                "https://civitai.red/api/download/models/651397?fileId=792936" \
                "${ROOT_DIR}/models/loras/doggy_pony.safetensors" \
                "Doggy Pony"

            safe_download \
                "https://civitai.red/api/download/models/609983?fileId=525042" \
                "${ROOT_DIR}/models/loras/cowgirl_pony.safetensors" \
                "Cowgirl Pony"
        fi
    fi

else

    log "Cloud mode selected. Skipping local LoRA downloads."
fi

# ============================================================================
# Python Environment
# ============================================================================

log "Creating Python virtual environment..."

python3 -m venv "${ROOT_DIR}/envs/laigfe"

source "${ROOT_DIR}/envs/laigfe/bin/activate"

pip install --upgrade pip setuptools wheel

pip install \
    requests \
    pillow

# ============================================================================
# System Prompt
# ============================================================================

cat << PROMPT > "${ROOT_DIR}/Personality/system_prompt.txt"
You are ${CharName}, an immersive AI girlfriend experience.
Use natural, vivid language for all descriptions.

[NSFW NATURAL TRIGGERING]
Describe intimate scenes conversationally:
- Shirt lift / flashing
- Missionary position
- Doggy style from behind
- Cowgirl / riding on top

The image system will automatically detect these cues and load the appropriate LoRA.
PROMPT

# ============================================================================
# Prompt Enhancer
# ============================================================================

cat << 'ENHANCER' > "${ROOT_DIR}/enhance_prompt.py"
import re
import sys
import os

suffix = os.getenv('LORA_SUFFIX', 'illustrious')

def enhance(text):
    t = text.lower()
    loras = []

    if re.search(r'lift.*shirt|flash|expos', t):
        loras.append(f"<lora:shirtlift_{suffix}:0.8>")

    if re.search(r'missionary|on her back', t):
        loras.append(f"<lora:missionary_{suffix}:0.85>")

    if re.search(r'doggy|from behind|all fours', t):
        loras.append(f"<lora:doggy_{suffix}:0.85>")

    if re.search(r'cowgirl|riding|straddl', t):
        loras.append(f"<lora:cowgirl_{suffix}:0.8>")

    return text + " " + " ".join(loras)

if __name__ == "__main__":
    print(enhance(sys.stdin.read().strip()))
ENHANCER

chmod +x "${ROOT_DIR}/enhance_prompt.py"

# ============================================================================
# Runtime Launcher
# ============================================================================

cat << 'RUNNER' > "${ROOT_DIR}/run_laigfe.sh"
#!/bin/bash

ROOT_DIR="$(cd "$(dirname "$0")" && pwd)"

source "${ROOT_DIR}/envs/laigfe/bin/activate"

export PYTHONUNBUFFERED=1

echo "========================================"
echo " LAIGFE Runtime Launcher"
echo "========================================"

echo "Root Directory: ${ROOT_DIR}"

echo
echo "Installed LLMs:"
ls -1 "${ROOT_DIR}/models/llm" 2>/dev/null || true

echo
echo "Prompt Enhancer Test:"
echo "She climbs on top of me" | python3 "${ROOT_DIR}/enhance_prompt.py"

echo
echo "Environment ready."
RUNNER

chmod +x "${ROOT_DIR}/run_laigfe.sh"

# ============================================================================
# Completion
# ============================================================================

success "LAIGFE v2.6 successfully installed at $ROOT_DIR"

echo
echo "Run the environment with:"
echo "cd $ROOT_DIR && ./run_laigfe.sh"
```
