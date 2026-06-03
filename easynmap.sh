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

LINE="${GRAY}  ──────────────────────────────────────────────────────────────────${NC}"

# ── Modules ───────────────────────────────────────────────────────────────────
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
source "$SCRIPT_DIR/modules/discovery.sh"
source "$SCRIPT_DIR/modules/profiles.sh"
source "$SCRIPT_DIR/modules/stealth.sh"

# ── Banner ────────────────────────────────────────────────────────────────────
banner() {
  clear
  echo ""
  echo -e "${BCYAN}  ██████╗  █████╗ ███████╗██╗   ██╗███╗   ██╗███╗   ███╗ █████╗ ██████╗${NC}"
  echo -e "${BCYAN}  ██╔════╝██╔══██╗██╔════╝╚██╗ ██╔╝████╗  ██║████╗ ████║██╔══██╗██╔══██╗${NC}"
  echo -e "${BCYAN}  █████╗  ███████║███████╗ ╚████╔╝ ██╔██╗ ██║██╔████╔██║███████║██████╔╝${NC}"
  echo -e "${BCYAN}  ██╔══╝  ██╔══██║╚════██║  ╚██╔╝  ██║╚██╗██║██║╚██╔╝██║██╔══██║██╔═══╝${NC}"
  echo -e "${BGREEN}  ███████╗██║  ██║███████║   ██║   ██║ ╚████║██║ ╚═╝ ██║██║  ██║██║${NC}"
  echo -e "${BGREEN}  ╚══════╝╚═╝  ╚═╝╚══════╝   ╚═╝   ╚═╝  ╚═══╝╚═╝     ╚═╝╚═╝  ╚═╝╚═╝${NC}"
  echo ""
  echo -e "  ${GRAY}Network Scanner with Profiles  ·  v2.0  ·  Authorized environments only${NC}"
  echo ""
  echo -e "$LINE"
  echo ""
}

# ── Section header ────────────────────────────────────────────────────────────
section() {
  local icon="$1" label="$2" color="${3:-$BCYAN}"
  echo -e "\n  ${color}${icon} ${label}${NC}  ${GRAY}──────────────────────────────────────────────────${NC}\n"
}

# ── Detect local IP ───────────────────────────────────────────────────────────
get_local_ip() {
  local iface ip
  iface=$(ip route 2>/dev/null | awk '/default/ {print $5; exit}')
  [[ -z "$iface" ]] && { echo -e "\n  ${BRED}✗${NC}  Could not detect network interface.\n"; exit 1; }
  ip=$(ip addr show "$iface" 2>/dev/null | awk '/inet / {split($2,a,"/"); print a[1]; exit}')
  [[ -z "$ip" ]] && { echo -e "\n  ${BRED}✗${NC}  Could not detect IP on $iface.\n"; exit 1; }
  IFACE="$iface"
  LOCAL_IP="$ip"
}

# ── Validate target ───────────────────────────────────────────────────────────
validate_target() {
  if [[ ! "$TARGET" =~ ^[a-zA-Z0-9._:/\-]+$ ]]; then
    echo -e "\n  ${BRED}✗${NC}  Invalid target: '${TARGET}'\n"
    exit 1
  fi
}

# ── Menu: Target ──────────────────────────────────────────────────────────────
menu_target() {
  section "◆" "TARGET" "$BCYAN"
  echo -e "  ${GRAY}Local IP${NC}  ${BYELLOW}$LOCAL_IP${NC}  ${GRAY}via ${BWHITE}$IFACE${NC}\n"
  echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Scan my network${NC}   ${GRAY}→  discover all hosts on ${LOCAL_IP%.*}.0/24${NC}"
  echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}Specific target${NC}   ${GRAY}→  enter IP or hostname manually${NC}\n"
  echo -ne "  ${BYELLOW}➤${NC}  Selection: "
  read -r opt

  case "$opt" in
    1)
      local subnet="${LOCAL_IP%.*}.0/24"
      section "◈" "NETWORK DISCOVERY" "$BCYAN"
      discovery_scan "$subnet" || exit 1
      echo -ne "  ${BYELLOW}➤${NC}  Select host number: "
      read -r sel
      TARGET=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f1)
      local thost tvendor
      thost=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f2)
      tvendor=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f3)
      [[ -z "$TARGET" ]] && { echo -e "\n  ${BRED}✗${NC}  Invalid selection.\n"; exit 1; }
      validate_target
      local vcolor="$GRAY"
      [[ "$tvendor" =~ [Aa]pple ]] && vcolor="$BMAGENTA"
      echo -e "\n  ${BGREEN}✓${NC}  ${BYELLOW}$TARGET${NC}  ${GRAY}$thost${NC}  ${vcolor}$tvendor${NC}\n"
      ;;
    2)
      echo -ne "\n  ${BYELLOW}➤${NC}  IP / hostname: "
      read -r TARGET
      [[ -z "$TARGET" ]] && { echo -e "\n  ${BRED}✗${NC}  Nothing entered.\n"; exit 1; }
      validate_target
      echo -e "\n  ${BGREEN}✓${NC}  Target set to ${BYELLOW}$TARGET${NC}\n"
      ;;
    *)
      echo -e "\n  ${BRED}✗${NC}  Invalid option.\n"; exit 1 ;;
  esac
}

# ── Menu: Device type ─────────────────────────────────────────────────────────
menu_device() {
  section "◆" "DEVICE TYPE" "$BCYAN"
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
  echo -ne "  ${BYELLOW}➤${NC}  Selection: "
  read -r DEVICE_TYPE

  if ! [[ "$DEVICE_TYPE" =~ ^[0-9]+$ ]] || (( DEVICE_TYPE < 1 || DEVICE_TYPE > max )); then
    echo -e "\n  ${BRED}✗${NC}  Invalid option.\n"; exit 1
  fi
  DEVICE_NAME=$(get_profile_name "$DEVICE_TYPE")
  DEVICE_COLOR=$(get_profile_color "$DEVICE_TYPE")
  echo -e "\n  ${BGREEN}✓${NC}  Profile → ${DEVICE_COLOR}${DEVICE_NAME}${NC}\n"
}

# ── Menu: Noise level ─────────────────────────────────────────────────────────
menu_stealth() {
  section "◆" "NOISE LEVEL" "$BCYAN"
  printf "  ${BWHITE}[1]${NC}  ${BGREEN}%-14s${NC}  ${GRAY}%s${NC}\n" "Silent"     "$(get_stealth_desc 1)"
  printf "  ${BWHITE}[2]${NC}  ${BYELLOW}%-14s${NC}  ${GRAY}%s${NC}\n" "Normal"     "$(get_stealth_desc 2)"
  printf "  ${BWHITE}[3]${NC}  ${BRED}%-14s${NC}  ${GRAY}%s${NC}\n"   "Aggressive" "$(get_stealth_desc 3)"
  echo ""
  echo -ne "  ${BYELLOW}➤${NC}  Selection: "
  read -r STEALTH_LEVEL

  if ! [[ "$STEALTH_LEVEL" =~ ^[1-3]$ ]]; then
    echo -e "\n  ${BRED}✗${NC}  Invalid option.\n"; exit 1
  fi
  STEALTH_NAME=$(get_stealth_name "$STEALTH_LEVEL")
  STEALTH_FLAGS=$(get_stealth_flags "$STEALTH_LEVEL")
  echo -e "\n  ${BGREEN}✓${NC}  Mode → $(stealth_color "$STEALTH_LEVEL")${STEALTH_NAME}${NC}\n"
}

# ── Menu: Scan depth ──────────────────────────────────────────────────────────
menu_depth() {
  section "◆" "SCAN DEPTH" "$BCYAN"
  echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Fast${NC}       ${GRAY}top 100 ports · quickest${NC}"
  echo -e "  ${BWHITE}[2]${NC}  ${BYELLOW}Standard${NC}   ${GRAY}key ports for ${DEVICE_COLOR}${DEVICE_NAME}${NC}"
  echo -e "  ${BWHITE}[3]${NC}  ${BRED}Full${NC}       ${GRAY}all ports 1–65535 · slow but thorough${NC}\n"
  echo -ne "  ${BYELLOW}➤${NC}  Selection: "
  read -r DEPTH

  case "$DEPTH" in
    1) DEPTH_FLAGS="--top-ports 100" ; DEPTH_NAME="Fast" ;;
    2)
      local ports
      ports=$(get_profile_ports "$DEVICE_TYPE")
      DEPTH_FLAGS="${ports:+-p $ports}"
      DEPTH_FLAGS="${DEPTH_FLAGS:---top-ports 1000}"
      DEPTH_NAME="Standard"
      ;;
    3) DEPTH_FLAGS="-p-" ; DEPTH_NAME="Full" ;;
    *) echo -e "\n  ${BRED}✗${NC}  Invalid option.\n"; exit 1 ;;
  esac
  echo -e "\n  ${BGREEN}✓${NC}  Depth → ${BYELLOW}${DEPTH_NAME}${NC}\n"
}

# ── Menu: Extras ──────────────────────────────────────────────────────────────
menu_extras() {
  section "◆" "OPTIONAL EXTRAS" "$BCYAN"
  echo -e "  ${GRAY}Enter numbers separated by spaces  ·  0 or Enter = none${NC}\n"
  echo -e "  ${BWHITE}[1]${NC}  ${BCYAN}-sV${NC}                        Service version detection"
  echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}-sC${NC}                        Default NSE scripts"
  echo -e "  ${BWHITE}[3]${NC}  ${BCYAN}-O --osscan-guess${NC}          OS detection with aggressive guessing"
  echo -e "  ${BWHITE}[4]${NC}  ${BCYAN}--script vuln${NC}              Known vulnerability scan"
  echo -e "  ${BWHITE}[5]${NC}  ${BMAGENTA}--script afp,mdns,smb-os${NC}   Apple / Mac fingerprint${NC}"

  local profile_scripts
  profile_scripts=$(get_profile_scripts "$DEVICE_TYPE")
  [[ -n "$profile_scripts" ]] && \
    echo -e "  ${BWHITE}[6]${NC}  ${BYELLOW}Profile scripts for ${DEVICE_COLOR}${DEVICE_NAME}${NC}${BYELLOW}:${NC}  ${GRAY}$profile_scripts${NC}"

  echo ""
  [[ "$STEALTH_LEVEL" == "1" ]] && \
    echo -e "  ${BYELLOW}△${NC}  Silent mode active — extras will add noise\n"

  echo -ne "  ${BYELLOW}➤${NC}  Selection: "
  read -r raw_extras

  EXTRA_FLAGS=""
  [[ "$raw_extras" == "0" || -z "$raw_extras" ]] && { echo ""; return; }

  local e
  for e in $raw_extras; do
    case "$e" in
      1)
        [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]] && EXTRA_FLAGS+=" -sV"
        ;;
      2) EXTRA_FLAGS+=" -sC" ;;
      3)
        [[ "$STEALTH_FLAGS" != *"-O"* && "$EXTRA_FLAGS" != *"-O"* ]] && \
          EXTRA_FLAGS+=" -O --osscan-guess"
        ;;
      4)
        EXTRA_FLAGS+=" --script vuln"
        [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]] && EXTRA_FLAGS+=" -sV"
        ;;
      5) EXTRA_FLAGS+=" --script afp-info,mdns-dns-sd,smb-os-discovery" ;;
      6) [[ -n "$profile_scripts" ]] && EXTRA_FLAGS+=" --script $profile_scripts" ;;
    esac
  done
  echo ""
}

# ── Scan analysis & recommendations ──────────────────────────────────────────
analyze_scan() {
  local f="$1"
  [[ ! -f "$f" ]] && return

  local open_count host_down all_filtered os_detected os_unreliable
  open_count=$(grep -cE "/(tcp|udp)[[:space:]]+open" "$f" 2>/dev/null)
  host_down=$(grep -c "Host seems down\|0 hosts up" "$f" 2>/dev/null)
  all_filtered=$(grep -cE "All [0-9]+ scanned ports.*filtered|Not shown: [0-9]+ filtered" "$f" 2>/dev/null)
  os_detected=$(grep -c "OS details:\|Running:" "$f" 2>/dev/null)
  os_unreliable=$(grep -c "OSScan results may be unreliable" "$f" 2>/dev/null)
  # grep -c always prints "0" on no match (exit 1); default handles file-error edge case
  open_count=${open_count:-0}; host_down=${host_down:-0}; all_filtered=${all_filtered:-0}
  os_detected=${os_detected:-0}; os_unreliable=${os_unreliable:-0}

  section "◈" "ANALYSIS" "$BYELLOW"

  # ── Host down ──
  if (( host_down > 0 )); then
    echo -e "  ${BRED}✗${NC}  Host appears to be blocking ping probes\n"
    echo -e "  ${BYELLOW}Recommendations:${NC}"
    echo -e "  ${GRAY}  ›${NC} The host may be up but ignoring ICMP — try ${BCYAN}Aggressive${NC} mode (forces -Pn)"
    echo -e "  ${GRAY}  ›${NC} Verify the target is actually online with: ${BGREEN}ping $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} Force scan regardless of ping: ${BGREEN}sudo nmap -sS -Pn -p 80,443,22 $TARGET${NC}"
    echo ""; return
  fi

  # ── All ports filtered ──
  if (( all_filtered > 0 && open_count == 0 )); then
    echo -e "  ${BYELLOW}△${NC}  All ports are filtered — a firewall is likely blocking probes\n"
    echo -e "  ${BYELLOW}Recommendations:${NC}"
    echo -e "  ${GRAY}  ›${NC} Switch to ${BYELLOW}Full${NC} depth + ${BRED}Aggressive${NC} noise and re-run"
    echo -e "  ${GRAY}  ›${NC} Try packet fragmentation: ${BGREEN}sudo nmap -sS -Pn -f --mtu 24 $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} Try ACK scan to map firewall rules: ${BGREEN}sudo nmap -sA -Pn $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} Try UDP (bypasses some firewalls): ${BGREEN}sudo nmap -sU -Pn --top-ports 100 $TARGET${NC}"
    echo ""; return
  fi

  # ── No open ports (but not all filtered) ──
  if (( open_count == 0 )); then
    echo -e "  ${BYELLOW}△${NC}  No open ports found with this profile\n"
    echo -e "  ${BYELLOW}Recommendations:${NC}"
    echo -e "  ${GRAY}  ›${NC} Try ${BRED}Full${NC} depth to scan all 65535 ports"
    echo -e "  ${GRAY}  ›${NC} Try a different device profile — the target may not match ${DEVICE_COLOR}${DEVICE_NAME}${NC}"
    echo -e "  ${GRAY}  ›${NC} Add UDP scan: ${BGREEN}sudo nmap -sU -Pn --top-ports 50 $TARGET${NC}"
    echo ""; return
  fi

  # ── Ports found ──
  echo -e "  ${BGREEN}✓${NC}  ${open_count} open port(s) found\n"

  # OS
  if (( os_unreliable > 0 )); then
    echo -e "  ${BYELLOW}△${NC}  OS fingerprint unreliable — nmap needs more open/closed ports"
    echo -e "  ${GRAY}  ›${NC} Re-run with ${BRED}Full${NC} depth for a more accurate OS guess"
  elif (( os_detected > 0 )); then
    echo -e "  ${BGREEN}✓${NC}  OS fingerprint captured"
  elif [[ "$STEALTH_FLAGS" != *"-O"* && "$EXTRA_FLAGS" != *"-O"* ]]; then
    echo -e "  ${GRAY}–${NC}  OS detection was not enabled"
    echo -e "  ${GRAY}  ›${NC} Re-run and add extra ${BCYAN}[3] -O --osscan-guess${NC}"
  fi

  # Versions
  if [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]]; then
    echo -e "  ${GRAY}–${NC}  Service versions were not detected"
    echo -e "  ${GRAY}  ›${NC} Re-run and add extra ${BCYAN}[1] -sV${NC} to fingerprint running software"
  fi

  echo ""
}

# ── Summary and execution ─────────────────────────────────────────────────────
compose_and_run() {
  local cmd="sudo nmap $STEALTH_FLAGS $DEPTH_FLAGS -Pn${EXTRA_FLAGS} $TARGET"

  section "◈" "SCAN SUMMARY" "$BWHITE"

  printf "  ${GRAY}%-14s${NC}  ${BYELLOW}%s${NC}\n"                          "Target"      "$TARGET"
  printf "  ${GRAY}%-14s${NC}  ${DEVICE_COLOR}%s${NC}\n"                     "Device"      "$DEVICE_NAME"
  printf "  ${GRAY}%-14s${NC}  $(stealth_color "$STEALTH_LEVEL")%s${NC}\n"   "Noise"       "$STEALTH_NAME"
  printf "  ${GRAY}%-14s${NC}  ${WHITE}%s${NC}\n"                            "Depth"       "$DEPTH_NAME"
  echo ""
  echo -e "  ${GRAY}Command${NC}"
  echo -e "  ${GRAY}  ┌────────────────────────────────────────────────────────────────${NC}"
  echo -e "  ${GRAY}  │${NC}  ${BGREEN}$cmd${NC}"
  echo -e "  ${GRAY}  └────────────────────────────────────────────────────────────────${NC}"
  echo ""
  echo -ne "  ${BYELLOW}➤${NC}  Execute? ${GRAY}[y/N]${NC}: "
  read -r confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && {
    echo -e "\n  ${GRAY}Cancelled.${NC}\n"; exit 0
  }

  echo ""
  echo -e "$LINE"
  echo -e "  ${BCYAN}SCANNING${NC}  ${GRAY}→${NC}  ${BYELLOW}$TARGET${NC}"
  echo -e "$LINE\n"

  local tmp_out
  tmp_out=$(mktemp /tmp/en_scan_XXXXXX.txt)

  eval "$cmd" | tee "$tmp_out"
  echo ""
  echo -e "$LINE"
  echo -e "  ${BGREEN}✓${NC}  Scan complete."
  echo -e "$LINE"

  analyze_scan "$tmp_out"
  rm -f "$tmp_out"
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
