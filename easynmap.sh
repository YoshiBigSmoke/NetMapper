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
  open_count=${open_count:-0}; host_down=${host_down:-0}; all_filtered=${all_filtered:-0}
  os_detected=${os_detected:-0}; os_unreliable=${os_unreliable:-0}

  # true if target is an Apple device (Mac=1, iPhone=2, iPad=3)
  local is_apple=0
  [[ "$DEVICE_TYPE" =~ ^[123]$ ]] && is_apple=1

  section "◈" "ANALYSIS" "$BYELLOW"

  # ── Host unreachable ──
  if (( host_down > 0 )); then
    echo -e "  ${BRED}✗${NC}  Target returned 0 hosts up — unreachable or all ports blocked\n"
    echo -e "  ${BYELLOW}Try these commands:${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Confirm it's online:"
    echo -e "    ${BGREEN}ping -c 3 $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Aggressive scan (${BCYAN}-A${NC} = versions + all NSE scripts + OS + traceroute):"
    echo -e "    ${BGREEN}sudo nmap -A -Pn $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Spoof source port to look like DNS traffic (bypasses some firewalls):"
    echo -e "    ${BGREEN}sudo nmap -sS -Pn --source-port 53 $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Fragment packets into smaller chunks:"
    echo -e "    ${BGREEN}sudo nmap -sS -Pn -f --mtu 24 $TARGET${NC}\n"
    if (( is_apple )); then
      echo -e "  ${BMAGENTA}  ›${NC} ${BMAGENTA}Apple device:${NC} screen may be off/locked — wake it and retry"
      echo -e "  ${BMAGENTA}  ›${NC} ${BMAGENTA}Apple + aggressive scripts:${NC}"
      echo -e "    ${BGREEN}sudo nmap -A -Pn --script afp-info,mdns-dns-sd,smb-os-discovery $TARGET${NC}\n"
    fi
    return
  fi

  # ── All ports filtered ──
  if (( all_filtered > 0 && open_count == 0 )); then
    echo -e "  ${BYELLOW}△${NC}  All ports filtered — firewall is dropping probe packets\n"
    echo -e "  ${BYELLOW}Try these commands:${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Aggressive scan (different probe types, finds more):"
    echo -e "    ${BGREEN}sudo nmap -A -Pn $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Fragment packets (evades some packet inspection):"
    echo -e "    ${BGREEN}sudo nmap -sS -Pn -f --mtu 24 $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} ACK scan to map which ports the firewall allows through:"
    echo -e "    ${BGREEN}sudo nmap -sA -Pn $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} UDP scan (separate protocol, may slip past TCP firewall):"
    echo -e "    ${BGREEN}sudo nmap -sU -Pn --top-ports 100 $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Full port range + aggressive:"
    echo -e "    ${BGREEN}sudo nmap -A -Pn -p- --min-rate 500 $TARGET${NC}\n"
    if (( is_apple )); then
      echo -e "  ${BMAGENTA}  ›${NC} ${BMAGENTA}Apple device:${NC}"
      echo -e "    ${BGREEN}sudo nmap -A -Pn --script afp-info,mdns-dns-sd,smb-os-discovery $TARGET${NC}\n"
    fi
    return
  fi

  # ── No open ports (not all filtered) ──
  if (( open_count == 0 )); then
    echo -e "  ${BYELLOW}△${NC}  No open ports found with this profile\n"
    echo -e "  ${BYELLOW}Try these commands:${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Scan all 65535 ports:"
    echo -e "    ${BGREEN}sudo nmap -sS -Pn -p- --min-rate 500 $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} Aggressive (finds services on non-standard ports):"
    echo -e "    ${BGREEN}sudo nmap -A -Pn $TARGET${NC}\n"
    echo -e "  ${GRAY}  ›${NC} UDP scan:"
    echo -e "    ${BGREEN}sudo nmap -sU -Pn --top-ports 100 $TARGET${NC}\n"
    return
  fi

  # ── Ports found ──
  echo -e "  ${BGREEN}✓${NC}  ${open_count} open port(s) found\n"

  if (( os_unreliable > 0 )); then
    echo -e "  ${BYELLOW}△${NC}  OS fingerprint unreliable — nmap needs more open/closed ports"
    echo -e "  ${GRAY}  ›${NC} ${BGREEN}sudo nmap -A -Pn -p- --min-rate 500 $TARGET${NC}"
  elif (( os_detected > 0 )); then
    echo -e "  ${BGREEN}✓${NC}  OS fingerprint captured"
  elif [[ "$STEALTH_FLAGS" != *"-O"* && "$EXTRA_FLAGS" != *"-O"* ]]; then
    echo -e "  ${GRAY}–${NC}  OS detection not enabled"
    echo -e "  ${GRAY}  ›${NC} ${BGREEN}sudo nmap -A -Pn $TARGET${NC}  ${GRAY}(-A includes OS detection)${NC}"
  fi

  if [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]]; then
    echo -e "  ${GRAY}–${NC}  Service versions not detected"
    echo -e "  ${GRAY}  ›${NC} ${BGREEN}sudo nmap -sV -Pn $TARGET${NC}  ${GRAY}(or use -A for everything at once)${NC}"
  fi

  echo ""
}

# ── Quick retry menu ───────────────────────────────────────────────────────────
offer_retry() {
  section "◈" "QUICK RETRY" "$BCYAN"
  echo -e "  ${GRAY}Run a follow-up scan without going through all menus again${NC}\n"

  local is_apple=0
  [[ "$DEVICE_TYPE" =~ ^[123]$ ]] && is_apple=1

  echo -e "  ${BWHITE}[1]${NC}  ${BCYAN}-A${NC}                     Aggressive  ${GRAY}(-sV -sC -O --traceroute bundled)${NC}"
  if (( is_apple )); then
    echo -e "  ${BWHITE}[2]${NC}  ${BMAGENTA}-A + Apple scripts${NC}     ${GRAY}afp-info, mdns-dns-sd, smb-os-discovery${NC}"
  else
    echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}-A -sU${NC}                 Aggressive + UDP"
  fi
  echo -e "  ${BWHITE}[3]${NC}  ${BYELLOW}-f --mtu 24${NC}            Fragment packets  ${GRAY}(evades some firewalls)${NC}"
  echo -e "  ${BWHITE}[4]${NC}  ${BYELLOW}-sU --top-ports 100${NC}    UDP top 100"
  echo -e "  ${BWHITE}[5]${NC}  ${BYELLOW}-p- --min-rate 500${NC}     Full port range  ${GRAY}(all 65535 ports, fast)${NC}"
  echo -e "  ${BWHITE}[6]${NC}  ${WHITE}Custom${NC}                 add your own nmap flags"
  echo -e "  ${BWHITE}[0]${NC}  ${GRAY}Exit${NC}\n"

  echo -ne "  ${BYELLOW}➤${NC}  Selection: "
  read -r retry_opt

  [[ "$retry_opt" == "0" || -z "$retry_opt" ]] && { echo ""; return; }

  local extra_retry=""
  case "$retry_opt" in
    1) extra_retry="-A" ;;
    2) (( is_apple )) \
         && extra_retry="-A --script afp-info,mdns-dns-sd,smb-os-discovery" \
         || extra_retry="-A -sU" ;;
    3) extra_retry="-f --mtu 24" ;;
    4) extra_retry="-sU --top-ports 100" ;;
    5) extra_retry="-p- --min-rate 500" ;;
    6)
      echo -ne "\n  ${BYELLOW}➤${NC}  Extra nmap flags: "
      read -r extra_retry
      [[ -z "$extra_retry" ]] && { echo ""; return; }
      ;;
    *) echo -e "  ${BRED}✗${NC}  Invalid option\n"; return ;;
  esac

  local retry_cmd="sudo nmap $STEALTH_FLAGS $DEPTH_FLAGS -Pn $extra_retry $TARGET"

  echo -e "\n  ${GRAY}Command${NC}"
  echo -e "  ${GRAY}  ┌────────────────────────────────────────────────────────────────${NC}"
  echo -e "  ${GRAY}  │${NC}  ${BGREEN}$retry_cmd${NC}"
  echo -e "  ${GRAY}  └────────────────────────────────────────────────────────────────${NC}\n"
  echo -ne "  ${BYELLOW}➤${NC}  Execute? ${GRAY}[y/N]${NC}: "
  read -r confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo -e "\n  ${GRAY}Cancelled.${NC}\n"; return; }

  local retry_tmp
  retry_tmp=$(mktemp /tmp/en_scan_XXXXXX.txt)

  echo ""
  echo -e "$LINE"
  echo -e "  ${BCYAN}SCANNING${NC}  ${GRAY}→${NC}  ${BYELLOW}$TARGET${NC}  ${GRAY}[$extra_retry]${NC}"
  echo -e "$LINE\n"
  eval "$retry_cmd" | tee "$retry_tmp"
  echo ""
  echo -e "$LINE"
  echo -e "  ${BGREEN}✓${NC}  Scan complete."
  echo -e "$LINE"

  analyze_scan "$retry_tmp"
  rm -f "$retry_tmp"
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

  offer_retry
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
