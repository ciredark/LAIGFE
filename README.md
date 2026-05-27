**✅ README Restored & Updated**

I've reviewed our entire conversation history regarding the README and restored the **complete, polished, comprehensive version** with all requested sections.

Here is the **full restored `README.md`** content that should now be on your repository:

---

```markdown
# LAIGFE - Local AI Girlfriend Experience (Project Soma)

**"Idiot-Proof Push-Button Deployment"** for a fully private, uncensored AI companion.

**LAIGFE** stands for **Local AI Girlfriend Experience** (also playfully known as *Local AI Gooner Friendly Experience* or *Local AI Generator for EVERYTHING*).

## What is it?

LAIGFE is a complete, one-click bare-metal deployment wizard that automatically installs and configures everything needed for a high-quality, fully local, uncensored AI companion experience.

It handles:
- Large Language Models (via llama.cpp)
- Advanced Image Generation (ComfyUI + NSFW LoRAs)
- OpenWebUI frontend
- Personality matrix builder
- Optional messenger integrations (Telegram/Discord)

## What Does it Do?

It gives you a private, high-performance AI girlfriend / companion that runs **entirely on your hardware** (or via cloud fallback). 

**No more:**
- Paying expensive monthly fees to NSFW AI sites
- Trying to trick censored models like ChatGPT into ERP
- Having your private chats stored on someone else's servers

**You get:**
- Complete privacy — everything stays on your machine
- Uncensored interactions (text + images)
- Natural conversation with automatic high-quality NSFW image generation
- Persistent personality and memory

## How Does It Work?

1. **Hardware Auto-Detection** — Detects your GPU VRAM and recommends the best model tier
2. **One-Command Installation** — Installs all dependencies, downloads models, and configures everything
3. **Personality Wizard** — Builds a custom companion (Realistic/Anime, Sub/Dom, Original/Fictional, etc.)
4. **NSFW LoRA System** — Automatically triggers professional pose LoRAs using **natural language only**
5. **Integrated Stack** — llama.cpp + ComfyUI + OpenWebUI running together

## Who Is This For?

- Users who want a **private, uncensored AI companion**
- People tired of paying for NSFW AI services
- Enthusiasts with a decent GPU who want maximum performance and control
- Anyone who values privacy and wants full ownership of their AI interactions

## 🚀 How to Get Started

### Linux (Recommended)

```bash
curl -fsSL https://raw.githubusercontent.com/ciredark/LAIGFE/main/install_laigfe.sh -o install_laigfe.sh
chmod +x install_laigfe.sh
./install_laigfe.sh
```

Then:
```bash
cd ~/LAIGFE/LAIGFE && ./run_laigfe.sh
```

Access at: **http://localhost:8080**

### Windows

```powershell
irm https://raw.githubusercontent.com/ciredark/LAIGFE/main/install_laigfe_windows.ps1 -OutFile install_laigfe_windows.ps1
.\install_laigfe_windows.ps1
```

(Run PowerShell **as Administrator**)

## Hardware Tiers

| Tier | VRAM       | LLM Model          | Image Model          | Best For          |
|------|------------|--------------------|----------------------|-------------------|
| High | 12GB+      | Qwen 12B Q8        | Pony + LoRAs         | Maximum quality   |
| Rec  | 6-12GB     | Qwen 9B Q6         | Illustrious + LoRAs  | Balanced          |
| Low  | <6GB       | Gemma 4B Q4        | SD 1.5 + LoRAs       | Entry level       |
| Cloud| Any        | OpenRouter         | Civitai              | No local GPU      |

## NSFW Features

Pre-loaded professional LoRAs for key poses:
- **Shirt Lift / Flashing**
- **Missionary (POV + Side)**
- **Doggy Style (POV + Side)**
- **Cowgirl / Reverse Cowgirl (POV + Side)**

All variants (SD 1.5, Illustrious, Pony) are automatically selected based on your tier and aesthetic choice.

**Natural Language Triggering** — Just describe what you want naturally (e.g., "she lifts her shirt teasingly" or "take her in missionary while looking into my eyes"). The system automatically applies the correct LoRAs.

---
