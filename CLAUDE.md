# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Running

```bash
sudo bash easynmap.sh   # entry point principal
sudo bash easyN.sh      # alias legado — redirige a easynmap.sh
```

Requires `sudo` — nmap needs root for SYN scans and ARP discovery (`-sS`, `-PR`).

## Architecture

`easynmap.sh` sources three modules and runs a cascading menu:

```
easynmap.sh
├── modules/discovery.sh   — ARP ping discovery, tabla de hosts con fabricante
├── modules/profiles.sh    — 8 perfiles de dispositivo con puertos y scripts NSE
└── modules/stealth.sh     — 3 niveles de ruido (timing + técnica nmap)
```

**Flujo de menús:**
1. `get_local_ip()` — detecta interfaz/IP via `ip route`
2. `menu_target()` — red local (discovery scan → pick host) o IP manual
3. `menu_device()` — 8 perfiles: Mac/macOS, iPhone, Windows, Linux, Servidor, Android, IoT, Genérico
4. `menu_stealth()` — Silencioso (`T2 + delay`), Normal (`T3`), Agresivo (`T4 + -sV -O --osscan-guess`)
5. `menu_depth()` — Rápido (top 100), Estándar (puertos del perfil), Completo (`-p-`)
6. `menu_extras()` — `-sV`, `-sC`, `-O --osscan-guess`, `--script vuln`, Apple fingerprint, scripts del perfil
7. `compose_and_run()` — muestra el comando nmap exacto, confirma, ejecuta con `eval`

**Temp files:** `/tmp/en_live_hosts.txt`, `.tmp`, sorted — creados y limpiados por ejecución.

## Conventions

- Bash only; colores con par regular/bold (`RED`/`BRED`, `GREEN`/`BGREEN`, etc.)
- Cabeceras de sección con fondo ANSI via `cabecera '<bg-code>' 'LABEL'`
- Perfiles de dispositivo: Mac es el perfil 1 (prioritario), con puertos AFP·548, Bonjour·5353, ARD·3283
- Scripts NSE por perfil en `get_profile_scripts()` — se activan como extra opción 6
- Output y comentarios en español
- `modules/arp-scn.sh` — stub vacío, ignorar
