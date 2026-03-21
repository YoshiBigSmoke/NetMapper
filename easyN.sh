#!/bin/bash
# netmappel.sh — Network Discovery & Port Scanner

# ── Colors ──────────────────────────────────────────────────────────────────
RED='\033[0;31m'    BRED='\033[1;31m'
GREEN='\033[0;32m'  BGREEN='\033[1;32m'
YELLOW='\033[1;33m' CYAN='\033[0;36m'
BLUE='\033[0;34m'   MAGENTA='\033[0;35m'
WHITE='\033[1;37m'  GRAY='\033[0;90m'
NC='\033[0m'

SEP="${GRAY}  ─────────────────────────────────────────────────────────────────${NC}"

# ── Banner ───────────────────────────────────────────────────────────────────
banner() {
  clear
  echo -e "${BRED}"
  echo '  ███╗   ██╗███████╗████████╗███╗   ███╗ █████╗ ██████╗ ██████╗ ███████╗██╗'
  echo '  ████╗  ██║██╔════╝╚══██╔══╝████╗ ████║██╔══██╗██╔══██╗██╔══██╗██╔════╝██║'
  echo '  ██╔██╗ ██║█████╗     ██║   ██╔████╔██║███████║██████╔╝██████╔╝█████╗  ██║'
  echo '  ██║╚██╗██║██╔══╝     ██║   ██║╚██╔╝██║██╔══██║██╔═══╝ ██╔═══╝ ██╔══╝  ██║'
  echo '  ██║ ╚████║███████╗   ██║   ██║ ╚═╝ ██║██║  ██║██║     ██║     ███████╗███████╗'
  echo '  ╚═╝  ╚═══╝╚══════╝   ╚═╝   ╚═╝     ╚═╝╚═╝  ╚═╝╚═╝     ╚═╝     ╚══════╝╚══════╝'
  echo -e "${NC}"
  echo -e "$SEP"
  echo -e "${CYAN}               Network Discovery & Port Scanner  ${GRAY}│${YELLOW} v1.0${NC}"
  echo -e "$SEP"
}

#modulos del proyecto 

# ── Get local IP ─────────────────────────────────────────────────────────────
get_local_ip() {
  local iface
  iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')
  if [[ -z "$iface" ]]; then
    echo -e "\n  ${BRED}[!]${NC} Could not detect default network interface. Exiting.\n"
    exit 1
  fi
  local ip
  ip=$(ip addr show "$iface" 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]; exit}')
  if [[ -z "$ip" ]]; then
    echo -e "\n  ${BRED}[!]${NC} Could not detect local IP on interface ${YELLOW}$iface${NC}. Exiting.\n"
    exit 1
  fi
  IFACE="$iface"
  LOCAL_IP="$ip"
}

# ── Discovery scan ────────────────────────────────────────────────────────────
discovery_scan() {
  local subnet="$1"
  echo -e "\n  ${GREEN}[+]${NC} Scanning ${YELLOW}$subnet${NC}... please wait\n"

  sudo nmap -sn -PR --resolve-all "$subnet" 2>/dev/null | awk '
    /^Nmap scan report for/ {
      host=$5; ip=""
      if ($6 ~ /^\(/) { ip=$6; gsub(/[()]/,"",ip) } else { ip=$5; host="" }
      cur_ip=ip; cur_host=host
      if (cur_host=="" || cur_host==cur_ip) cur_host="unknown"
      has_mac=0
    }
    /^MAC Address:/ {
      has_mac=1
      vendor=$0
      sub(/^MAC Address: [0-9A-Fa-f:]+ \(/,"",vendor)
      sub(/\).*/,"",vendor)
      if (vendor=="") vendor="unknown"
      print cur_ip "|" cur_host "|" vendor
    }
    END {}
  ' > /tmp/nm_live_hosts.txt

  # Also catch hosts without MAC (e.g. local machine or remote hops)
  sudo nmap -sn -PR --resolve-all "$subnet" 2>/dev/null | awk '
    /^Nmap scan report for/ {
      host=$5; ip=""
      if ($6 ~ /^\(/) { ip=$6; gsub(/[()]/,"",ip) } else { ip=$5; host="" }
      cur_ip=ip; cur_host=host
      if (cur_host=="" || cur_host==cur_ip) cur_host="unknown"
      has_mac=0
    }
    /^MAC Address:/ { has_mac=1 }
    /^Nmap done/ || /^$/ {}
    /^Host is up/ { if (!has_mac) print cur_ip "|" cur_host "|" "(no MAC — local or remote)" }
  ' >> /tmp/nm_live_hosts.tmp 2>/dev/null

  # Merge and deduplicate
  cat /tmp/nm_live_hosts.tmp >> /tmp/nm_live_hosts.txt 2>/dev/null
  sort -t. -k1,1n -k2,2n -k3,3n -k4,4n /tmp/nm_live_hosts.txt | \
    awk -F'|' '!seen[$1]++' > /tmp/nm_live_sorted.txt
  mv /tmp/nm_live_sorted.txt /tmp/nm_live_hosts.txt
  rm -f /tmp/nm_live_hosts.tmp

  if [[ ! -s /tmp/nm_live_hosts.txt ]]; then
    echo -e "  ${BRED}[!]${NC} No live hosts found on $subnet\n"
    exit 0
  fi

  printf "  ${GRAY}%-4s %-18s %-26s %s${NC}\n" "#" "IP" "HOSTNAME" "VENDOR"
  echo -e "$SEP"
  local i=1
  while IFS='|' read -r ip host vendor; do
    printf "  ${WHITE}%-4s${NC} ${YELLOW}%-18s${NC} ${CYAN}%-26s${NC} ${GRAY}%s${NC}\n" \
      "$i." "$ip" "$host" "$vendor"
    ((i++))
  done < /tmp/nm_live_hosts.txt
  echo ""
}

# ── Scan type menu ────────────────────────────────────────────────────────────
scan_menu() {
  local target="$1"
  echo -e "$SEP"
  echo -e "${CYAN}   SCAN TYPE${NC}"
  echo -e "$SEP\n"
  echo -e "    ${WHITE}[1]${NC} ${GREEN}Quick Scan${NC}    ${GRAY}TCP SYN · all ports · fast rate${NC}"
  echo -e "    ${WHITE}[2]${NC} ${YELLOW}Full Scan${NC}     ${GRAY}TCP + UDP · all ports · slower${NC}\n"
  echo -ne "${MAGENTA}  ➤  Select scan type:${NC} "
  read -r scan_type

  echo -e "\n$SEP"
  case "$scan_type" in
    1)
      echo -e "${CYAN}   QUICK SCAN${NC} ${GRAY}→ ${YELLOW}$target${NC}"
      echo -e "$SEP\n"
      sudo nmap -sS -p- --min-rate 1000 -Pn "$target"
      ;;
    2)
      echo -e "${CYAN}   FULL SCAN${NC} ${GRAY}→ ${YELLOW}$target${NC}"
      echo -e "$SEP\n"
      sudo nmap -sS -sU -p- --min-rate 1000 -Pn "$target"
      ;;
    *)
      echo -e "\n  ${BRED}[!]${NC} Invalid option.\n"
      exit 1
      ;;
  esac
  echo -e "\n$SEP"
  echo -e "${GREEN}  [✓] Scan complete.${NC}"
  echo -e "$SEP\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────
banner
get_local_ip

echo -e "  ${GREEN}[*]${NC} Local IP detected: ${YELLOW}$LOCAL_IP${NC}"
echo -e "  ${GREEN}[*]${NC} Interface:         ${YELLOW}$IFACE${NC}\n"

echo -e "$SEP"
echo -e "${CYAN}   TARGET SELECTION${NC}"
echo -e "$SEP\n"
echo -e "    ${WHITE}[1]${NC} ${GREEN}Scan my network${NC}      ${GRAY}→  ${LOCAL_IP%.*}.0/24${NC}"
echo -e "    ${WHITE}[2]${NC} ${BLUE}Scan a specific IP${NC}   ${GRAY}→  enter manually${NC}\n"
echo -ne "${MAGENTA}  ➤  Select option:${NC} "
read -r target_type

case "$target_type" in
  1)
    subnet="${LOCAL_IP%.*}.0/24"
    echo -e "\n$SEP"
    echo -e "${CYAN}   DISCOVERY SCAN  ${GRAY}─  $subnet${NC}"
    echo -e "$SEP"
    discovery_scan "$subnet"

    echo -ne "${MAGENTA}  ➤  Select host number:${NC} "
    read -r selection
    TARGET_IP=$(sed -n "${selection}p" /tmp/nm_live_hosts.txt | cut -d'|' -f1)

    if [[ -z "$TARGET_IP" ]]; then
      echo -e "\n  ${BRED}[!]${NC} Invalid selection.\n"
      exit 1
    fi

    TARGET_HOST=$(sed -n "${selection}p" /tmp/nm_live_hosts.txt | cut -d'|' -f2)
    echo -e "\n  ${GREEN}[✓] Target set:${NC} ${YELLOW}$TARGET_IP${NC}  ${GRAY}($TARGET_HOST)${NC}\n"
    ;;
  2)
    echo -ne "\n${MAGENTA}  ➤  Enter target IP:${NC} "
    read -r TARGET_IP
    if [[ -z "$TARGET_IP" ]]; then
      echo -e "\n  ${BRED}[!]${NC} No IP entered.\n"
      exit 1
    fi
    echo -e "\n  ${GREEN}[✓] Target set:${NC} ${YELLOW}$TARGET_IP${NC}\n"
    ;;
  *)
    echo -e "\n  ${BRED}[!]${NC} Invalid option.\n"
    exit 1
    ;;
esac

scan_menu "$TARGET_IP"
