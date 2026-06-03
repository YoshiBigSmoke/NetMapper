#!/bin/bash
# easynmap.sh — Easy Nmap v2.0: Network Scanner with Profiles

# ── Colors ────────────────────────────────────────────────────────────────────
RED='\033[0;31m'      BRED='\033[1;31m'
GREEN='\033[0;32m'    BGREEN='\033[1;32m'
YELLOW='\033[0;33m'   BYELLOW='\033[1;33m'
CYAN='\033[0;36m'     BCYAN='\033[1;36m'
BLUE='\033[0;34m'     BBLUE='\033[1;34m'
MAGENTA='\033[0;35m'  BMAGENTA='\033[1;35m'
WHITE='\033[0;37m'    BWHITE='\033[1;37m'
GRAY='\033[0;90m'     NC='\033[0m'

SEP="${GRAY}  ──────────────────────────────────────────────────────────────────${NC}"

# ── Modules ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/modules/discovery.sh"
source "$SCRIPT_DIR/modules/profiles.sh"
source "$SCRIPT_DIR/modules/stealth.sh"

# ── Banner ────────────────────────────────────────────────────────────────────
banner() {
  clear
  echo -e ""
  echo -e "${BMAGENTA}  ╔══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BMAGENTA}  ║${NC}                                                                      ${BMAGENTA}║${NC}"
  echo -e "${BMAGENTA}  ║  ${BRED}▓${BGREEN}▓${BYELLOW}▓ ${BCYAN}E${BMAGENTA}A${BRED}S${BGREEN}Y${BYELLOW}N${BCYAN}M${BMAGENTA}A${BRED}P ${BGREEN}▓${BYELLOW}▓${BCYAN}▓${NC}   ${BWHITE}Network Scanner with Profiles${NC}         ${BMAGENTA}║${NC}"
  echo -e "${BMAGENTA}  ║${NC}                                                                      ${BMAGENTA}║${NC}"
  echo -e "${BMAGENTA}  ║  ${GRAY}v2.0  ·  github.com/YoshiBigSmoke  ·  Authorized environments only${NC}   ${BMAGENTA}║${NC}"
  echo -e "${BMAGENTA}  ║${NC}                                                                      ${BMAGENTA}║${NC}"
  echo -e "${BMAGENTA}  ╚══════════════════════════════════════════════════════════════════════╝${NC}\n"
}

# ── Section header ────────────────────────────────────────────────────────────
# Arg 1: ANSI bg+fg code   Arg 2: label
header() {
  echo -e "\n${1}  ◈  ${2}  ${NC}"
  echo -e "$SEP\n"
}

# ── Detect local IP ───────────────────────────────────────────────────────────
get_local_ip() {
  local iface ip
  iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')
  [[ -z "$iface" ]] && { echo -e "\n  ${BRED}[!]${NC} Could not detect network interface.\n"; exit 1; }
  ip=$(ip addr show "$iface" 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]; exit}')
  [[ -z "$ip" ]] && { echo -e "\n  ${BRED}[!]${NC} Could not detect IP on $iface.\n"; exit 1; }
  IFACE="$iface"
  LOCAL_IP="$ip"
}

# ── Validate target (IP / hostname / CIDR only) ───────────────────────────────
validate_target() {
  if [[ ! "$TARGET" =~ ^[a-zA-Z0-9._:/\-]+$ ]]; then
    echo -e "\n  ${BRED}[!]${NC} Invalid target: '${TARGET}'\n"
    exit 1
  fi
}

# ── Menu: Target ──────────────────────────────────────────────────────────────
menu_target() {
  header '\033[1;37;44m' 'TARGET'
  echo -e "  ${BCYAN}◆${NC} Local IP : ${BYELLOW}$LOCAL_IP${NC}   ${GRAY}[$IFACE]${NC}\n"
  echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Scan my network${NC}    ${GRAY}→  ${LOCAL_IP%.*}.0/24${NC}"
  echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}IP / hostname${NC}      ${GRAY}→  enter manually${NC}\n"
  echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
  read -r opt

  case "$opt" in
    1)
      local subnet="${LOCAL_IP%.*}.0/24"
      echo -e "\n$SEP"
      echo -e "  ${BCYAN}DISCOVERY  ${GRAY}→  ${BYELLOW}$subnet${NC}\n"
      discovery_scan "$subnet" || exit 1

      echo -ne "  ${BMAGENTA}➤  Host number:${NC} "
      read -r sel
      TARGET=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f1)
      local thost tvendor
      thost=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f2)
      tvendor=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f3)
      [[ -z "$TARGET" ]] && { echo -e "\n  ${BRED}[!]${NC} Invalid selection.\n"; exit 1; }
      validate_target

      local vcolor="$GRAY"
      [[ "$tvendor" =~ [Aa]pple ]] && vcolor="$BMAGENTA"
      echo -e "\n  ${BGREEN}[✓]${NC} Target : ${BYELLOW}$TARGET${NC}  ${GRAY}$thost${NC}  ${vcolor}$tvendor${NC}\n"
      ;;
    2)
      echo -ne "\n  ${BMAGENTA}➤  IP / hostname:${NC} "
      read -r TARGET
      [[ -z "$TARGET" ]] && { echo -e "\n  ${BRED}[!]${NC} Nothing entered.\n"; exit 1; }
      validate_target
      echo -e "\n  ${BGREEN}[✓]${NC} Target : ${BYELLOW}$TARGET${NC}\n"
      ;;
    *)
      echo -e "\n  ${BRED}[!]${NC} Invalid option.\n"; exit 1 ;;
  esac
}

# ── Menu: Device type ─────────────────────────────────────────────────────────
menu_device() {
  header '\033[1;37;45m' 'DEVICE TYPE'
  local i max
  max=$(get_profile_count)
  for i in $(seq 1 "$max"); do
    local color name desc
    color=$(get_profile_color "$i")
    name=$(get_profile_name "$i")
    desc=$(get_profile_desc "$i")
    printf "  ${BWHITE}[%s]${NC}  ${color}%-16s${NC}  ${GRAY}%s${NC}\n" "$i" "$name" "$desc"
  done
  echo ""
  echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
  read -r DEVICE_TYPE

  if ! [[ "$DEVICE_TYPE" =~ ^[0-9]+$ ]] || (( DEVICE_TYPE < 1 || DEVICE_TYPE > max )); then
    echo -e "\n  ${BRED}[!]${NC} Invalid option.\n"; exit 1
  fi
  DEVICE_NAME=$(get_profile_name "$DEVICE_TYPE")
  DEVICE_COLOR=$(get_profile_color "$DEVICE_TYPE")
  echo -e "\n  ${BGREEN}[✓]${NC} Profile : ${DEVICE_COLOR}${DEVICE_NAME}${NC}\n"
}

# ── Menu: Noise level ─────────────────────────────────────────────────────────
menu_stealth() {
  header '\033[0;30;46m' 'NOISE LEVEL'
  printf "  ${BWHITE}[1]${NC}  ${BGREEN}%-14s${NC}  ${GRAY}%s${NC}\n" "Silent"     "$(get_stealth_desc 1)"
  printf "  ${BWHITE}[2]${NC}  ${BYELLOW}%-14s${NC}  ${GRAY}%s${NC}\n" "Normal"     "$(get_stealth_desc 2)"
  printf "  ${BWHITE}[3]${NC}  ${BRED}%-14s${NC}  ${GRAY}%s${NC}\n"   "Aggressive" "$(get_stealth_desc 3)"
  echo ""
  echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
  read -r STEALTH_LEVEL

  if ! [[ "$STEALTH_LEVEL" =~ ^[1-3]$ ]]; then
    echo -e "\n  ${BRED}[!]${NC} Invalid option.\n"; exit 1
  fi
  STEALTH_NAME=$(get_stealth_name "$STEALTH_LEVEL")
  STEALTH_FLAGS=$(get_stealth_flags "$STEALTH_LEVEL")
  echo -e "\n  ${BGREEN}[✓]${NC} Mode : $(stealth_color "$STEALTH_LEVEL")${STEALTH_NAME}${NC}\n"
}

# ── Menu: Scan depth ──────────────────────────────────────────────────────────
menu_depth() {
  header '\033[0;30;42m' 'SCAN DEPTH'
  echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Fast${NC}       ${GRAY}top 100 ports · fastest${NC}"
  echo -e "  ${BWHITE}[2]${NC}  ${BYELLOW}Standard${NC}   ${GRAY}key ports for ${DEVICE_COLOR}${DEVICE_NAME}${NC}"
  echo -e "  ${BWHITE}[3]${NC}  ${BRED}Full${NC}       ${GRAY}all ports 1–65535 · slow${NC}\n"
  echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
  read -r DEPTH

  case "$DEPTH" in
    1)
      DEPTH_FLAGS="--top-ports 100"
      DEPTH_NAME="Fast"
      ;;
    2)
      local ports
      ports=$(get_profile_ports "$DEVICE_TYPE")
      if [[ -n "$ports" ]]; then
        DEPTH_FLAGS="-p $ports"
      else
        DEPTH_FLAGS="--top-ports 1000"
      fi
      DEPTH_NAME="Standard"
      ;;
    3)
      DEPTH_FLAGS="-p-"
      DEPTH_NAME="Full"
      ;;
    *)
      echo -e "\n  ${BRED}[!]${NC} Invalid option.\n"; exit 1 ;;
  esac
  echo -e "\n  ${BGREEN}[✓]${NC} Depth : ${BYELLOW}${DEPTH_NAME}${NC}\n"
}

# ── Menu: Extras ──────────────────────────────────────────────────────────────
menu_extras() {
  header '\033[1;37;41m' 'OPTIONAL EXTRAS'
  echo -e "  ${GRAY}Enter numbers separated by spaces  ·  0 = none${NC}\n"

  echo -e "  ${BWHITE}[1]${NC}  ${BCYAN}-sV${NC}                          Service version detection"
  echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}-sC${NC}                          Default NSE scripts"
  echo -e "  ${BWHITE}[3]${NC}  ${BCYAN}-O --osscan-guess${NC}            OS detection with aggressive guessing"
  echo -e "  ${BWHITE}[4]${NC}  ${BCYAN}--script vuln${NC}                Known vulnerability scan"
  echo -e "  ${BWHITE}[5]${NC}  ${BMAGENTA}--script afp,mdns,smb-os${NC}     Apple / Mac fingerprint${NC}"

  local profile_scripts
  profile_scripts=$(get_profile_scripts "$DEVICE_TYPE")
  [[ -n "$profile_scripts" ]] && \
    echo -e "  ${BWHITE}[6]${NC}  ${BYELLOW}Recommended scripts for ${DEVICE_COLOR}${DEVICE_NAME}${NC}${BYELLOW}:${NC} ${GRAY}$profile_scripts${NC}"

  echo ""
  [[ "$STEALTH_LEVEL" == "1" ]] && \
    echo -e "  ${BYELLOW}[!]${NC} Silent mode active — extras will increase noise\n"

  echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
  read -r raw_extras

  EXTRA_FLAGS=""
  [[ "$raw_extras" == "0" || -z "$raw_extras" ]] && { echo ""; return; }

  local e
  for e in $raw_extras; do
    case "$e" in
      1)
        [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]] && \
          EXTRA_FLAGS+=" -sV"
        ;;
      2) EXTRA_FLAGS+=" -sC" ;;
      3)
        [[ "$STEALTH_FLAGS" != *"-O"* && "$EXTRA_FLAGS" != *"-O"* ]] && \
          EXTRA_FLAGS+=" -O --osscan-guess"
        ;;
      4)
        EXTRA_FLAGS+=" --script vuln"
        [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]] && \
          EXTRA_FLAGS+=" -sV"
        ;;
      5) EXTRA_FLAGS+=" --script afp-info,mdns-dns-sd,smb-os-discovery" ;;
      6)
        [[ -n "$profile_scripts" ]] && EXTRA_FLAGS+=" --script $profile_scripts"
        ;;
    esac
  done
  echo ""
}

# ── Summary and execution ─────────────────────────────────────────────────────
compose_and_run() {
  local cmd="sudo nmap $STEALTH_FLAGS $DEPTH_FLAGS -Pn${EXTRA_FLAGS} $TARGET"

  echo -e "\n${BWHITE}  ╔══════════════════════════════════════════════════════════════════════╗${NC}"
  echo -e "${BWHITE}  ║${NC}  ${BYELLOW}◈  SCAN SUMMARY${NC}                                                    ${BWHITE}║${NC}"
  echo -e "${BWHITE}  ╠══════════════════════════════════════════════════════════════════════╣${NC}"
  printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  ${BYELLOW}%-54s${BWHITE}║${NC}\n" "Target:"    "$TARGET"
  printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  ${DEVICE_COLOR}%-54s${BWHITE}║${NC}\n" "Device:"     "$DEVICE_NAME"
  printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  $(stealth_color "$STEALTH_LEVEL")%-54s${BWHITE}║${NC}\n" "Noise:"  "$STEALTH_NAME"
  printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  ${WHITE}%-54s${BWHITE}║${NC}\n" "Depth:"      "$DEPTH_NAME"
  echo -e "${BWHITE}  ╠══════════════════════════════════════════════════════════════════════╣${NC}"
  echo -e "${BWHITE}  ║${NC}  ${BCYAN}Command:${NC}                                                              ${BWHITE}║${NC}"
  echo -e "${BWHITE}  ║${NC}  ${BGREEN}$cmd${NC}"
  echo -e "${BWHITE}  ╚══════════════════════════════════════════════════════════════════════╝${NC}\n"

  echo -ne "  ${BMAGENTA}➤  Execute? ${GRAY}[y/N]${NC}: "
  read -r confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && {
    echo -e "\n  ${BYELLOW}[~]${NC} Cancelled.\n"; exit 0
  }

  echo -e "\n$SEP"
  echo -e "  ${BCYAN}SCANNING  ${GRAY}→  ${BYELLOW}$TARGET${NC}"
  echo -e "$SEP\n"
  eval "$cmd"
  echo -e "\n$SEP"
  echo -e "  ${BGREEN}[✓] Scan complete.${NC}"
  echo -e "$SEP\n"
}

# ── Main ──────────────────────────────────────────────────────────────────────
banner
get_local_ip
menu_target
menu_device
menu_stealth
menu_depth
menu_extras
compose_and_run
