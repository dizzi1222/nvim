> # 💤 LazyVim - Configuración Universal

> **Setup compatible con Linux Hyprland, Windows y WSL** | LazyVim Starter Template

<div align="center">

![Nvim WSL Desktop](https://github.com/user-attachments/assets/9144215e-6156-43c3-beba-4cca7f431337)

![Nvim Desktop](https://github.com/user-attachments/assets/8adb6f60-bb35-4704-b4ab-12bd587f3992)


**Build optimizado para Linux Hyprland con soporte completo WSL/Windows**

</div>

---

## 📋 Tabla de Contenidos

- [Atajos Principales](#-atajos-principales)
- [Instalación Rápida](#-instalación-rápida)
- [Configuración por Plataforma](#️-configuración-por-plataforma)
- [IA · Compleción y Usage](#-ia--compleción-y-usage)
- [Sincronización Automática](#-sincronización-automática)
- [PowerToys Setup](#-powertoys-setup-windows)
- [Estructura del Proyecto](#-estructura-del-proyecto)
- [Recursos Adicionales](#-recursos-adicionales)

---

## ⚡ Atajos Principales

| Atajo | Acción | Descripción |
|-------|--------|-------------|
| `Shift + L` | Alt Tab → | Cambiar buffer siguiente |
| `Shift + H` | Alt Tab ← | Cambiar buffer anterior |

> 💡 **Estos atajos emulan Alt+Tab de tu sistema, pero dentro de Neovim**

---

## 🚀 Instalación Rápida

### Clonar el Repositorio

```bash
git clone https://github.com/dizzi1222/dotfiles-wsl-dizzi/
cd dotfiles-wsl-dizzi
```

---

## 🖥️ Configuración por Plataforma

<table>
<tr>
<th>🐧 Linux (Hyprland)</th>
<th>🪟 Windows</th>
<th>🔷 WSL (Arch/Debian)</th>
</tr>
<tr>
<td>

**Enlaces Simbólicos** (Optimizado)

```bash
ln -sf ~/dotfiles-wsl-dizzi/nvim \
  ~/.config/nvim
```

✅ Usa symlinks nativos  
✅ Sin lag  
✅ Actualización instantánea

</td>
<td>

**Sincronización Manual**

```powershell
# PowerShell
.\sync-nvim-pwshWindows.ps1
```

```bash
# Git Bash
./setup.sh
```

⚠️ NO uses symlinks  
⚠️ Windows tiene lag con `/mnt/c/`  
✅ Copia archivos nativos

</td>
<td>

**Sincronización WSL**

```bash
./sync-nvim.sh
```

⚠️ NO uses symlinks a `/mnt/c/`  
✅ Copia desde Windows a WSL  
✅ Sin lag en lectura

</td>
</tr>
</table>

---

## 🔄 Sincronización Automática

### Scripts Disponibles

| Script | Plataforma | Función |
|--------|-----------|---------|
| `setup.sh` | Windows (Git Bash) | Configura Neovim en `C:\Users\Diego\AppData\Local\nvim` |
| `sync-nvim.sh` | WSL (Linux) | Sincroniza Windows → WSL sin symlinks |
| `sync-nvim-pwshWindows.ps1` | Windows (PowerShell) | Alternativa PowerShell para usuarios Windows |

### Flujo de Sincronización

```
┌─────────────────────────────────────────────────────────────┐
│  C:\Users\Diego\AppData\Local\nvim                          │
│  (Config principal Windows)                                 │
└────────────────────┬────────────────────────────────────────┘
                     │
                     │ sync-nvim.sh
                     ↓
┌─────────────────────────────────────────────────────────────┐
│  \\wsl.localhost\archlinux\root\.config\nvim\lua\plugins    │
│  (Config sincronizada WSL)                                  │
└─────────────────────────────────────────────────────────────┘
```

### ⚠️ Por qué NO usar Symlinks en Windows/WSL

**Linux Nativo:**
```bash
# ✅ FUNCIONA - Optimizado y sin lag
ln -sf ~/.config/nvim ~/dotfiles
```

**Windows/WSL:**
```bash
# ❌ NO HACER - Lag extremo al leer desde /mnt/c/
ln -s /mnt/c/Users/Diego/AppData/Local/nvim ~/.config/nvim

# ✅ HACER - Copiar archivos nativos
./sync-nvim.sh  # Copia real, sin enlaces
```

**Razón técnica:** WSL tiene overhead masivo al acceder a `/mnt/c/` mediante symlinks. La sincronización manual copia archivos al sistema de archivos nativo de WSL, eliminando el lag.

---

## 🤖 IA · Compleción y Usage

Panorama de los motores de IA en esta config (Linux). Los ajustes finos viven
en `lua/plugins/*.lua`; acá está el mapa de quién alimenta cada cosa.

### Compleción (inline / tab)

| Motor | Archivo | Backend | Modo |
|---|---|---|---|
| **Copilot (NES)** | `lua/plugins/copilot.lua` | GitHub Copilot (`copilot.lua` + `copilot-lsp`) | Inline en INSERT + **líneas verdes predictivas en NORMAL** (NES) |
| **neocodeium** | `lua/plugins/neocodeium.lua` | Windsurf/Codeium (gratis, `:NeoCodeium auth`) | Inline, Alt en vez de `<Tab>` |
| **Supermaven** | `lua/plugins/supermaven.lua` | Supermaven (gratis) | Inline con `<Tab>` |
| **neocursor** | `lua/plugins/neocursor.lua` | `dizzi1222/neocursor.nvim` + `sidecar_antigravity.py` | Cursor Tab-Tab-Tab (ver nota abajo) |

> **neocursor (reciente):** usa el backend de completions de Antigravity/Google
> (`/v1internal:streamGenerateContent` con `tab_flash_lite_preview` y tu OAuth).
> El sidecar vive en el fork `dizzi1222/neocursor.nvim`: el ghost se extrae por
> match de prefix cercano al cursor + anchor de coherencia, y el "siguiente
> edit" se ubica con difflib en su posición real (jump Tab). El
> `capture_anty_token.sh` (token OAuth) es multi-OS (openssl del sistema,
> fallback Nix). La cuota del TAB es una **pool separada e invisible** — ver
> Usage.

**Soporte de lenguajes del sidecar** (`lang_for_path` en `sidecar_antigravity.py`):
el prompt del tab anuncia el lenguaje del archivo al modelo como cabecera
("This is a TypeScript file.") para orientarlo mejor que un rol genérico:

```python
return {
    ".ts": "TypeScript", ".tsx": "TypeScript/React",
    ".js": "JavaScript", ".jsx": "JavaScript/React",
    ".py": "Python", ".rs": "Rust", ".go": "Go",
    ".java": "Java", ".c": "C", ".h": "C", ".cpp": "C++",
    ".hpp": "C++", ".cs": "C#", ".rb": "Ruby", ".php": "PHP",
    ".swift": "Swift", ".kt": "Kotlin", ".lua": "Lua",
    ".sh": "Shell", ".bash": "Shell", ".zsh": "Shell",
    ".css": "CSS", ".scss": "SCSS", ".html": "HTML",
    ".json": "JSON", ".md": "Markdown",
}
```

> Extensión desconocida → no se anuncia lenguaje (cabecera vacía).

### Usage (`<leader>C` → `:AIUsage`)

| Motor | Fuente | Qué muestra |
|---|---|---|
| `antigravity_usage.py` | RPC `retrieveUserQuotaSummary` | Cuota del **agente** de agy por grupo (Gemini / Claude+GPT) |
| `cursor_usage.py` | RPC de Cursor | Plan de Cursor |
| `agy /usage` (TUI) | `anty_usage_float()` | `agy /usage` en float-terminal |

⚠️ **La cuota del TAB (neocursor/completions) no es consultable.** Los RPC de
quota (`retrieveUserQuotaSummary` / `retrieveUserQuota`) solo exponen modelos de
**chat**; el SSE del tab devuelve únicamente `usageMetadata` (tokens por request)
sin límite ni barra. Los % que ves en `agy /usage` son del agente, **no** del
tab — por eso el tab puede seguir respondiendo con la cuota del agente en 0%.

---

## 🎨 PowerToys Setup (Windows)

Para tener una experiencia similar a Linux en Windows, utiliza **PowerToys** con mi configuración personalizada.

### Instalación

```bash
# Clonar repositorio de PowerToys
git clone https://github.com/dizzi1222/GLAZE-WM-make-windows-pretty-main-dizzi
cd GLAZE-WM-make-windows-pretty-main-dizzi
```

### Restaurar Configuración

1. Abre **PowerToys**
2. Ve a **General → Backup & Restore**
3. Selecciona **Restaurar**
4. Carga el archivo: `settings_134107811922822208.ptb`

<div align="center">

**📂 Ubicación de Config:**

`[Config de Powertoys] = General, Restaurar\settings_134107811922822208.ptb`

</div>

---

## 📁 Estructura del Proyecto

```
dotfiles-wsl-dizzi/
├── nvim/                         # Configuración Neovim
│   ├── lua/
│   │   ├── config/              # Configuraciones base
│   │   └── plugins/             # Plugins LazyVim
│   │       └── disabled.lua     # ⚠️ IAs deshabilitadas
│   └── init.lua                 # Punto de entrada
│
├── setup.sh                     # Setup Windows (Git Bash)
├── sync-nvim.sh                 # Sincronización WSL
└── sync-nvim-pwshWindows.ps1    # Sincronización PowerShell
```

### ⚙️ Plugins y Configuración

Este proyecto usa [**LazyVim**](https://github.com/LazyVim/LazyVim) como base. 

**Plugins de IA deshabilitados por defecto:**
- Revisa: `nvim/lua/plugins/disabled.lua`
- Habilita los que necesites editando el archivo

---

## 📚 Recursos Adicionales

### Documentación Oficial

- [**LazyVim Documentation**](https://lazyvim.github.io/installation) - Guía de instalación completa
- [**LazyVim Starter**](https://github.com/LazyVim/LazyVim) - Template base

### Alternativa: Packer.nvim

Si prefieres usar **packer.nvim** en lugar de LazyVim:

```bash
# Revisa el directorio de versiones alternativas
cd nvim-wsl/~ [basura]/README
```

> 💡 Este proyecto mantiene compatibilidad con packer.nvim para usuarios que prefieran ese gestor de plugins.

### Repositorios del Proyecto

<table>
<tr>
<th>🐧 Linux/Hyprland</th>
<th>🪟 Windows/WSL</th>
</tr>
<tr>
<td>

**nvim** (Original)

```
https://github.com/dizzi1222/nvim
```

Para Linux nativo con Hyprland

</td>
<td>

**nvim-wsl** (Universal)

```
https://github.com/dizzi1222/nvim-wsl
```

Para Windows y WSL

</td>
</tr>
</table>

---

## 🎯 Casos de Uso

### Desarrollador Linux Nativo

```bash
# Setup rápido con symlinks
git clone https://github.com/dizzi1222/nvim
ln -sf ~/nvim ~/.config/nvim
```

### Usuario Windows

```powershell
# PowerShell
git clone https://github.com/dizzi1222/nvim-wsl
cd nvim-wsl
.\sync-nvim-pwshWindows.ps1
```

### Usuario WSL (Arch/Debian)

```bash
# Bash en WSL
git clone https://github.com/dizzi1222/dotfiles-wsl-dizzi
cd dotfiles-wsl-dizzi
./sync-nvim.sh
```

### Dual Boot (Windows + Linux)

```bash
# En Linux: usar symlinks
ln -sf ~/.config/nvim ~/dotfiles

# En Windows: sincronización manual
./setup.sh  # Primera vez
./sync-nvim-pwshWindows.ps1  # Actualizaciones
```

---

## 🔧 Solución de Problemas

### Neovim no encuentra plugins

```bash
# Reinstalar plugins
:Lazy sync
:Lazy restore
```

### Lag en Windows/WSL

```bash
# ❌ Si usaste symlinks a /mnt/c/
rm ~/.config/nvim  # Eliminar symlink

# ✅ Usar sincronización nativa
./sync-nvim.sh
```

### PowerToys no carga la config

1. Verifica que PowerToys esté actualizado
2. Asegúrate de usar la ruta correcta del `.ptb`
3. Reinicia PowerToys después de restaurar

---

<div align="center">

**💤 LazyVim - One Config, All Platforms**

*Linux · Windows · WSL*

[![Linux](https://img.shields.io/badge/Linux-Hyprland-blue?logo=linux)](https://github.com/dizzi1222/nvim)
[![Windows](https://img.shields.io/badge/Windows-10/11-blue?logo=windows)](https://github.com/dizzi1222/nvim-wsl)
[![WSL](https://img.shields.io/badge/WSL-Arch/Debian-purple?logo=linux)](https://github.com/dizzi1222/dotfiles-wsl-dizzi)

</div>
