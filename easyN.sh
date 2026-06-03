#!/bin/bash
# easyN.sh — Acceso legado; redirige a easynmap.sh
exec "$(dirname "${BASH_SOURCE[0]}")/easynmap.sh" "$@"
