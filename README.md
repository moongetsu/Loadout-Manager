<h1 align="center">
  <img src="https://images.gamebanana.com/img/ico/sprays/naruto.gif" width="64" alt="Loadout Manager"/>
  <br />
  Loadout Manager
</h1>
<p align="center">
  <b>Optimized weapon swapper for <span style="color:#19a974;">custom loadouts</span> in CS:GO servers.</b><br>
  <i>Personalize your arsenal with ease.</i>
</p>

<hr>

## 🔫 About

**Loadout Manager** is a lightweight and efficient SourceMod plugin that allows players to choose their preferred weapons for specific slots. If a player picks up or buys a weapon that they've disabled in their loadout (e.g., they prefer the USP-S over the P2000), the plugin automatically swaps it for their preferred version.

---

## ✨ Features

- **Pistol Start:** Swap between **P2000** and **USP-S**.
- **Sidearm Slot:** Choose between **Five-Seven / Tec-9** and **CZ75-Auto**.
- **Heavy Pistol:** Swap between **Desert Eagle** and **R8 Revolver**.
- **SMG Slot:** Choose between **MP7** and **MP5-SD**.
- **Primary Rifle (CT):** Swap between **M4A4** and **M4A1-S**.
- **Persistent Settings:** Preferences are saved using client cookies (database/file) and restored on rejoin.
- **Multilingual Support:** Fully translatable phrases.

---

## 🛠️ Requirements

- **[SourceMod 1.10+](https://www.sourcemod.net/downloads.php)**
- **[MultiColors](https://github.com/Bara/Multi-Colors)** (Include for compilation)

---

## 📦 Installation

1. Download the `loadout.sp` and `loadout.phrases.txt` files.
2. Compile `loadout.sp` using your local compiler or an online one.
3. Place `loadout.smx` in `addons/sourcemod/plugins/`.
4. Place `loadout.phrases.txt` in `addons/sourcemod/translations/`.
5. Restart your server or load the plugin manually (`sm plugins load loadout`).

---

## 🎮 Commands

| Command | Alias | Description |
|---------|-------|-------------|
| `sm_loadout` | `sm_lo` | Opens the Loadout Manager menu. |

*Note: You can use `!loadout` or `!lo` in chat.*

---

<p align="center">
  <img src="https://badgen.net/badge/Optimized%20for/CS:GO/green?icon=sourceengine" alt="Engine Optimized" />
  <img src="https://badgen.net/badge/Version/v1.2/blue" alt="Version" />
  <img src="https://badgen.net/badge/Language/SourcePawn/orange" alt="SourcePawn" />
</p>