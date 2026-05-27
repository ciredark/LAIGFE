# LAIGFE - Local AI Girlfriend Experience (Project Soma)

**"Idiot-Proof Push-Button Deployment" for a fully local, uncensored AI companion.**

## What is LAIGFE?

LAIGFE stands for **Local AI Girlfriend Experience** (also playfully known as *Local AI Gooner Friendly Experience* or *Local AI Generator for EVERYTHING*).

It is a complete, bare-metal deployment wizard that automatically installs and configures everything you need for a powerful, private, uncensored AI companion experience on your own hardware.

## What Does It Do?

- Automatically detects your hardware and scales LLM + Image Generation accordingly
- Installs llama.cpp, ComfyUI, OpenWebUI, and all dependencies
- Downloads high-quality models (Qwen, Gemma, Illustrious, Pony, etc.)
- Includes a full **NSFW LoRA Pose Pack** (Shirtlift, Missionary POV, Doggy, Cowgirl) with automatic natural language triggering
- Builds a personalized AI companion with custom personality, appearance, and relationship dynamics
- Supports local messengers (Telegram/Discord) and optional Cloud fallback

**STOP PAYING for NSFW AI sites. STOP trying to jailbreak censored models.** Everything runs 100% locally and privately on your machine. No more steamy chat logs left on someone else's server.

## How Does It Work?

1. **Hardware Assessment** → Detects GPU VRAM, CPU, storage and recommends the best tier
2. **One-Click Installation** → Downloads, builds, and configures all components (llama.cpp + ComfyUI + OpenWebUI)
3. **Personality Builder** → Interactive wizard creates a rich system prompt based on your preferences (Realistic/Anime, Submissive/Dominant, Original/Fictional, etc.)
4. **NSFW Engine** → ComfyUI with pre-loaded professional LoRAs that trigger automatically from natural descriptions
5. **Unified Interface** → Everything accessible via a clean OpenWebUI frontend at `http://localhost:8080`

## Who Is This For?

- Users tired of paying subscriptions for limited NSFW AI experiences
- Enthusiasts of deep, uncensored ERP / roleplay with high-quality visual generation
- Privacy-conscious individuals who want complete control and zero data logging
- Hardware owners (from modest laptops to high-end gaming rigs) who enjoy local AI
- Anyone who wants a truly personalized, always-available AI companion

## 🚀 How to Get Started

### 1. Run the Installer

```bash
curl -fsSL https://raw.githubusercontent.com/ciredark/LAIGFE/main/install_laigfe.sh -o install_laigfe.sh
chmod +x install_laigfe.sh
./install_laigfe.sh
```

### 2. Launch the Experience

```bash
cd ~/LAIGFE
./run_laigfe.sh
```

Open your browser and go to: **http://localhost:8080**

### 3. Configure Your Companion

During installation you'll be guided through:
- Hardware tier selection
- Aesthetic preference (Realistic vs Anime)
- Personality & relationship style
- Physical description

Start chatting naturally — the AI will handle both conversation and image generation seamlessly.

## Hardware Scaling Tiers

| Tier         | VRAM       | LLM                  | Image Generation              | Best For              |
|--------------|------------|----------------------|-------------------------------|-----------------------|
| **High**     | 12GB+      | Qwen 12B Q8         | Illustrious XL + LoRAs       | Maximum quality      |
| **Recommended** | 6-12GB  | Qwen 9B Q6          | Illustrious XL + LoRAs       | Balanced performance |
| **Low**      | <6GB       | Gemma 4B            | SD 1.5 + LoRAs               | Entry-level hardware |
| **Cloud**    | Any        | OpenRouter (free tier) | Civitai Orchestration     | No GPU required      |

## 🔥 NSFW Capabilities

Pre-loaded high-quality LoRAs for key poses:

- **Shirt Lift / Flashing**
- **Missionary (POV + Side)**
- **Doggy Style (POV + Side)**
- **Cowgirl / Reverse Cowgirl (POV + Side)**

**Natural Prompting System**: Simply describe scenes conversationally (e.g., "she slowly lifts her shirt while looking at me" or "I take her in missionary position"). The system automatically detects cues and applies the correct LoRAs.

## Important Notes

- **Bare Metal Only** — No containers, full performance
- Supports NVIDIA CUDA, AMD ROCm, and CPU fallback
- All data and generations stay on your local machine
- Fully customizable and open source
- Regularly updated with new features and model support

---

**Take back control. Build your perfect private AI companion today.**

Questions or issues? Open an Issue on this repo.
