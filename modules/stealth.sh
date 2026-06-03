#!/bin/bash
# stealth.sh — Noise levels / nmap timing profiles

get_stealth_name() {
  case "$1" in
    1) echo "Silent"     ;;
    2) echo "Normal"     ;;
    3) echo "Aggressive" ;;
  esac
}

get_stealth_flags() {
  case "$1" in
    1) echo "-sS -T2 --max-retries 1 --scan-delay 200ms"                       ;;
    2) echo "-sS -T3 --min-rate 300"                                            ;;
    3) echo "-sS -sV --version-intensity 6 -O --osscan-guess -T4 --min-rate 1000" ;;
  esac
}

get_stealth_desc() {
  case "$1" in
    1) echo "SYN · T2 · 200ms delay · no fingerprinting"           ;;
    2) echo "SYN · T3 · 300 pkt/s · balanced"                      ;;
    3) echo "SYN · T4 · 1000 pkt/s · versions + OS + OS-guess"     ;;
  esac
}

stealth_color() {
  case "$1" in
    1) echo -n "${BGREEN}"  ;;
    2) echo -n "${BYELLOW}" ;;
    3) echo -n "${BRED}"    ;;
  esac
}
