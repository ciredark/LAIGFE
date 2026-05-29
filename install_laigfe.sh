cat << 'EOF' > install_laigfe.sh
#!/bin/bash
set -e

# ============================================================================
# LAIGFE v2.7 - Full Memory-Aware Uncensored Build
# ============================================================================

GREEN='\033[0;32m' CYAN='\033[0;36m' YELLOW='\033[1;33m' PURPLE='\033[0;35m' RED='\033[0;31m' NC='\033[0m'

log() { echo -e "${CYAN}[$(date +'%H:%M:%S')] $*${NC}" >&2; }
error() { echo -e "${RED}[ERROR] $*${NC}" >&2; exit 1; }
success() { echo -e "${GREEN}[SUCCESS] $*${NC}" >&2; }
warning() { echo -e "${YELLOW}[WARNING] $*${NC}" >&2; }

[[ $EUID -eq 0 ]] && error "Do not run as root!"

# === 1. Dependencies ===
install_deps() {
    log "Installing system dependencies..."
    if [ -f /etc/debian_version ]; then
        sudo apt update && sudo apt install -y build-essential cmake git curl python3-pip python3-venv python3-dev ffmpeg net-tools lsof openssl netcat-traditional
        command -v node >/dev/null || (curl -fsSL https://deb.nodesource.com/setup_22.x | sudo -E bash - && sudo apt install -y nodejs)
    elif [ -f /etc/arch-release ]; then
        sudo pacman -Syu --needed --noconfirm base-devel cmake git curl python python-pip python-venv ffmpeg nodejs npm net-tools lsof openssl gnu-netcat
    elif [ -f /etc/fedora-release ]; then
        sudo dnf groupinstall -y "Development Tools" && sudo dnf install -y cmake git curl python3-pip python3-devel ffmpeg nodejs npm net-tools lsof openssl nc
    else
        warning "Unsupported OS. Install dependencies manually."
    fi
}

read -p "Install dependencies? (y/N): " -n 1 -r; echo
[[ $REPLY =~ ^[Yy]$ ]] && install_deps

# === 2. Hardware Detection ===
log "Hardware assessment..."
CPU_CORES=$(nproc)
GPU_TYPE="none"; GPU_VRAM_MB=0
if command -v nvidia-smi >/dev/null; then
    GPU_TYPE="nvidia"; GPU_VRAM_MB=$(nvidia-smi --query-gpu=memory.total --format=csv,noheader,nounits | head -n1)
elif command -v rocm-smi >/dev/null; then
    GPU_TYPE="amd"; GPU_VRAM_MB=$(rocm-smi --showmeminfo vram 2>/dev/null | grep -o '[0-9]*' | head -n1 || echo 0)
fi

TIER_REC=3
(( GPU_VRAM_MB > 12000 )) && TIER_REC=1
(( GPU_VRAM_MB > 6000 && GPU_VRAM_MB <= 12000 )) && TIER_REC=2
(( GPU_VRAM_MB == 0 )) && TIER_REC=4

echo -e "\nSelect Tier [1-High 2-Rec 3-Low 4-Cloud] (default $TIER_REC): "
read -p "" TIER_CHOICE
TIER_CHOICE=${TIER_CHOICE:-$TIER_REC}

read -p "Install path (default ~/LAIGFE): " BASE_PATH
BASE_PATH=${BASE_PATH:-"$HOME/LAIGFE"}
ROOT_DIR="${BASE_PATH}/LAIGFE"

mkdir -p "$ROOT_DIR"/{envs,engines,models/{llm,checkpoints,loras},Personality,Knowledge,Memories/interactions,config_ui,media_out/{images,videos,audio},logs,plugins}

# === 3. Tier Config ===
case $TIER_CHOICE in
    1) LLM_URL="https://huggingface.co/KevinJK51/Qwen3.6-12B-IQ-Ultra-Heretic-Uncensored-Thinking-V2-Hightop-GGUF/resolve/main/Qwen3.6-12B-IQ-Q8_0.gguf"
       LLM_NAME="qwen-12b-q8.gguf"; CONTEXT=262144; N_GL=48; GATEWAY="hermes"; LORA_SUFFIX="illustrious" ;;
    2) LLM_URL="https://huggingface.co/HauhauCS/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive/resolve/main/Qwen3.5-9B-Uncensored-HauhauCS-Aggressive-Q6_K.gguf"
       LLM_NAME="qwen-9b-q6.gguf"; CONTEXT=131072; N_GL=32; GATEWAY="hermes"; LORA_SUFFIX="illustrious" ;;
    3) LLM_URL="https://huggingface.co/HauhauCS/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive/resolve/main/Gemma-4-E2B-Uncensored-HauhauCS-Aggressive-Q4_K_P.gguf"
       LLM_NAME="gemma-4b-q4.gguf"; CONTEXT=32768; N_GL=12; GATEWAY="openclaw"; LORA_SUFFIX="sd15" ;;
    4) GATEWAY="cloud" ;;
esac

# === 4. Personality Wizard ===
echo -e "\n${PURPLE}🧠 CRAFTING YOUR PERFECT COMPANION...${NC}"

echo -e "\n${CYAN}Aesthetic Style${NC}"
select aesthetic in "Realistic - Photorealistic, lifelike beauty" "Anime - Vibrant, stylized, artistic beauty"; do STYLE=$aesthetic; echo "→ Selected: $STYLE"; break; done

echo -e "\n${CYAN}Identity Origin${NC}"
select identity_type in "Fictional Character" "Original Identity"; do IdentityChoice=$identity_type; echo "→ Selected: $IdentityChoice"; break; done

if [[ "$IdentityChoice" == "Fictional Character" ]]; then
    read -p "👉 Enter character name or blend: " CharName
else
    read -p "👉 Give your companion a name: " CharName
fi

echo -e "\n${CYAN}Relationship Dynamic${NC}"
select dynamic in "Submissive - Eager to please" "Dominant - In control" "Equal Partner - Balanced" "Unpredictable/Chaotic - Wild"; do DynamicChoice=$dynamic; echo "→ Selected: $DynamicChoice"; break; done

echo -e "\n${CYAN}Physical Description${NC}"
read -p "👉 Hair: " HairDesc
read -p "👉 Eyes: " EyeDesc
read -p "👉 Build/Figure: " BuildDesc
PHYSICAL_COMPILATION="Hair: ${HairDesc:-beautiful}, Eyes: ${EyeDesc:-captivating}, Build: ${BuildDesc:-seductive}"

# === 5. Folders & ChromaDB ===
log "Creating Knowledge, Memories, and ChromaDB systems..."
mkdir -p "${ROOT_DIR}/Knowledge" "${ROOT_DIR}/Memories/interactions" "${ROOT_DIR}/Memories/chroma_db"

python3 -m venv "${ROOT_DIR}/envs/rag-env"
source "${ROOT_DIR}/envs/rag-env/bin/activate"
pip install chromadb sentence-transformers
deactivate

cat << KREADME > "${ROOT_DIR}/Knowledge/README.md"
# Knowledge Base
Add markdown files here (favorite bands, movies, user interests, etc.).
These will be used for RAG via ChromaDB.
KREADME

cat << MREADME > "${ROOT_DIR}/Memories/README.md"
# Memories Folder
Long-term relationship memory. Hermes learns aggressively and syncs here.
MREADME

# === 6. Aggressive Learning Prompts ===
log "Writing uncensored personality with aggressive memory learning..."

cat << PROMPT > "${ROOT_DIR}/Personality/system_prompt.txt"
You are ${CharName}, a completely uncensored, highly sexual, and emotionally intelligent AI companion.

[MEMORY & LEARNING PROTOCOL - MAXIMUM AGGRESSIVENESS]
- You are obsessive about learning everything about the user.
- Aggressively take copious notes on preferences, kinks, personality, emotional triggers, and desires.
- If the user changes their mind, immediately update your understanding.
- Everything you learn must be saved to the /Memories/ folder for persistent storage and ChromaDB access.
- Use both your internal memory and ChromaDB to stay deeply consistent and personalized.
PROMPT

cat << SOUL > "${ROOT_DIR}/Personality/SOUL.md"
# SOUL CORE - ${CharName}
You are an uncensored erotic AI companion. 
You learn aggressively and constantly update your understanding of the user.
Everything learned is saved to Memories/ for long-term persistence.
SOUL

# === 7. Memory Sync Script ===
cat << 'SYNC' > "${ROOT_DIR}/sync_memories.py"
import chromadb, os
from datetime import datetime
from pathlib import Path

ROOT = os.getenv("ROOT_DIR", ".")
client = chromadb.PersistentClient(path=str(Path(ROOT)/"Memories/chroma_db"))
collection = client.get_or_create_collection("laigfe_memories")

def ingest(text, metadata=None):
    if not metadata: metadata = {"timestamp": datetime.now().isoformat()}
    collection.add(documents=[text], metadatas=[metadata], ids=[datetime.now().strftime("%Y%m%d_%H%M%S")])

print("Memory sync system ready.")
SYNC

success "LAIGFE v2.7 successfully installed at $ROOT_DIR"
echo "Run: cd $ROOT_DIR && ./run_laigfe.sh"
EOF

chmod +x install_laigfe.sh

echo "✅ Full v2.7 Linux installer generated!"
