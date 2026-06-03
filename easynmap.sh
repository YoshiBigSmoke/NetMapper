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
    echo -e "  ${BRED}✗${NC}  Invalid target: '${TARGET}'\n"
    return 1
  fi
  return 0
}

# ── Menu: Target ──────────────────────────────────────────────────────────────
# Returns: 0 = target set, 1 = back (exit program)
menu_target() {
  while true; do
    section "◆" "TARGET" "$BCYAN"
    echo -e "  ${GRAY}Local IP${NC}  ${BYELLOW}$LOCAL_IP${NC}  ${GRAY}via ${BWHITE}$IFACE${NC}\n"
    echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Scan my network${NC}   ${GRAY}→  discover all hosts on ${LOCAL_IP%.*}.0/24${NC}"
    echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}Specific target${NC}   ${GRAY}→  enter IP or hostname manually${NC}"
    echo -e "  ${BWHITE}[0]${NC}  ${GRAY}Exit${NC}\n"
    echo -ne "  ${BYELLOW}➤${NC}  Selection: "
    read -r opt

    case "$opt" in
      0) return 1 ;;
      1)
        local subnet="${LOCAL_IP%.*}.0/24"
        section "◈" "NETWORK DISCOVERY" "$BCYAN"
        if ! discovery_scan "$subnet"; then
          echo -e "  ${BRED}✗${NC}  Discovery failed. Try again.\n"
          continue
        fi
        while true; do
          echo -ne "  ${BYELLOW}➤${NC}  Select host number (b = back): "
          read -r sel
          [[ "$sel" == "b" || "$sel" == "B" ]] && break
          TARGET=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f1)
          if [[ -z "$TARGET" ]]; then
            echo -e "  ${BRED}✗${NC}  Invalid number — try again\n"
            continue
          fi
          local thost tvendor
          thost=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f2)
          tvendor=$(sed -n "${sel}p" /tmp/en_live_hosts.txt | cut -d'|' -f3)
          validate_target || continue
          local vcolor="$GRAY"
          [[ "$tvendor" =~ [Aa]pple ]] && vcolor="$BMAGENTA"
          echo -e "\n  ${BGREEN}✓${NC}  ${BYELLOW}$TARGET${NC}  ${GRAY}$thost${NC}  ${vcolor}$tvendor${NC}\n"
          return 0
        done
        ;;
      2)
        while true; do
          echo -ne "\n  ${BYELLOW}➤${NC}  IP / hostname (b = back): "
          read -r TARGET
          [[ "$TARGET" == "b" || "$TARGET" == "B" ]] && break
          [[ -z "$TARGET" ]] && { echo -e "  ${BRED}✗${NC}  Nothing entered\n"; continue; }
          validate_target || continue
          echo -e "\n  ${BGREEN}✓${NC}  Target set to ${BYELLOW}$TARGET${NC}\n"
          return 0
        done
        ;;
      *)
        echo -e "  ${BRED}✗${NC}  Enter 1, 2 or 0\n"
        ;;
    esac
  done
}

# ── Menu: Device type ─────────────────────────────────────────────────────────
# Returns: 0 = selected, 1 = back
menu_device() {
  local max
  max=$(get_profile_count)
  while true; do
    section "◆" "DEVICE TYPE" "$BCYAN"
    local i
    for i in $(seq 1 "$max"); do
      printf "  ${BWHITE}[%2s]${NC}  $(get_profile_color "$i")%-16s${NC}  ${GRAY}%s${NC}\n" \
        "$i" "$(get_profile_name "$i")" "$(get_profile_desc "$i")"
    done
    echo -e "\n  ${BWHITE}[ b]${NC}  ${GRAY}Back${NC}\n"
    echo -ne "  ${BYELLOW}➤${NC}  Selection: "
    read -r DEVICE_TYPE

    [[ "$DEVICE_TYPE" == "b" || "$DEVICE_TYPE" == "B" ]] && return 1
    if [[ "$DEVICE_TYPE" =~ ^[0-9]+$ ]] && (( DEVICE_TYPE >= 1 && DEVICE_TYPE <= max )); then
      DEVICE_NAME=$(get_profile_name "$DEVICE_TYPE")
      DEVICE_COLOR=$(get_profile_color "$DEVICE_TYPE")
      echo -e "\n  ${BGREEN}✓${NC}  Profile → ${DEVICE_COLOR}${DEVICE_NAME}${NC}\n"
      return 0
    fi
    echo -e "  ${BRED}✗${NC}  Enter 1–$max or b\n"
  done
}

# ── Menu: Noise level ─────────────────────────────────────────────────────────
# Returns: 0 = selected, 1 = back
menu_stealth() {
  while true; do
    section "◆" "NOISE LEVEL" "$BCYAN"
    printf "  ${BWHITE}[1]${NC}  ${BGREEN}%-14s${NC}  ${GRAY}%s${NC}\n" "Silent"     "$(get_stealth_desc 1)"
    printf "  ${BWHITE}[2]${NC}  ${BYELLOW}%-14s${NC}  ${GRAY}%s${NC}\n" "Normal"     "$(get_stealth_desc 2)"
    printf "  ${BWHITE}[3]${NC}  ${BRED}%-14s${NC}  ${GRAY}%s${NC}\n"   "Aggressive" "$(get_stealth_desc 3)"
    echo -e "\n  ${BWHITE}[b]${NC}  ${GRAY}Back${NC}\n"
    echo -ne "  ${BYELLOW}➤${NC}  Selection: "
    read -r STEALTH_LEVEL

    [[ "$STEALTH_LEVEL" == "b" || "$STEALTH_LEVEL" == "B" ]] && return 1
    if [[ "$STEALTH_LEVEL" =~ ^[1-3]$ ]]; then
      STEALTH_NAME=$(get_stealth_name "$STEALTH_LEVEL")
      STEALTH_FLAGS=$(get_stealth_flags "$STEALTH_LEVEL")
      echo -e "\n  ${BGREEN}✓${NC}  Mode → $(stealth_color "$STEALTH_LEVEL")${STEALTH_NAME}${NC}\n"
      return 0
    fi
    echo -e "  ${BRED}✗${NC}  Enter 1, 2, 3 or b\n"
  done
}

# ── Menu: Scan depth ──────────────────────────────────────────────────────────
# Returns: 0 = selected, 1 = back
menu_depth() {
  while true; do
    section "◆" "SCAN DEPTH" "$BCYAN"
    echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Fast${NC}       ${GRAY}top 100 ports · quickest${NC}"
    echo -e "  ${BWHITE}[2]${NC}  ${BYELLOW}Standard${NC}   ${GRAY}key ports for ${DEVICE_COLOR}${DEVICE_NAME}${NC}"
    echo -e "  ${BWHITE}[3]${NC}  ${BRED}Full${NC}       ${GRAY}all ports 1–65535 · slow but thorough${NC}"
    echo -e "\n  ${BWHITE}[b]${NC}  ${GRAY}Back${NC}\n"
    echo -ne "  ${BYELLOW}➤${NC}  Selection: "
    read -r DEPTH

    [[ "$DEPTH" == "b" || "$DEPTH" == "B" ]] && return 1
    case "$DEPTH" in
      1) DEPTH_FLAGS="--top-ports 100" ; DEPTH_NAME="Fast"     ;;
      2)
        local ports
        ports=$(get_profile_ports "$DEVICE_TYPE")
        DEPTH_FLAGS="${ports:+-p $ports}"
        DEPTH_FLAGS="${DEPTH_FLAGS:---top-ports 1000}"
        DEPTH_NAME="Standard"
        ;;
      3) DEPTH_FLAGS="-p-" ; DEPTH_NAME="Full" ;;
      *) echo -e "  ${BRED}✗${NC}  Enter 1, 2, 3 or b\n"; continue ;;
    esac
    echo -e "\n  ${BGREEN}✓${NC}  Depth → ${BYELLOW}${DEPTH_NAME}${NC}\n"
    return 0
  done
}

# ── Menu: Extras ──────────────────────────────────────────────────────────────
# Returns: 0 = done, 1 = back
menu_extras() {
  while true; do
    section "◆" "OPTIONAL EXTRAS" "$BCYAN"
    echo -e "  ${GRAY}Numbers separated by spaces  ·  0 or Enter = none${NC}\n"
    echo -e "  ${BWHITE}[1]${NC}  ${BCYAN}-sV${NC}                        Service version detection"
    echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}-sC${NC}                        Default NSE scripts"
    echo -e "  ${BWHITE}[3]${NC}  ${BCYAN}-O --osscan-guess${NC}          OS detection + aggressive guess"
    echo -e "  ${BWHITE}[4]${NC}  ${BCYAN}--script vuln${NC}              Known vulnerability scan"
    echo -e "  ${BWHITE}[5]${NC}  ${BMAGENTA}--script afp,mdns,smb-os${NC}   Apple / Mac fingerprint${NC}"

    local profile_scripts
    profile_scripts=$(get_profile_scripts "$DEVICE_TYPE")
    [[ -n "$profile_scripts" ]] && \
      echo -e "  ${BWHITE}[6]${NC}  ${BYELLOW}Profile scripts for ${DEVICE_COLOR}${DEVICE_NAME}${BYELLOW}:${NC}  ${GRAY}$profile_scripts${NC}"

    echo -e "\n  ${BWHITE}[b]${NC}  ${GRAY}Back${NC}\n"
    [[ "$STEALTH_LEVEL" == "1" ]] && \
      echo -e "  ${BYELLOW}△${NC}  Silent mode active — extras will increase noise\n"

    echo -ne "  ${BYELLOW}➤${NC}  Selection: "
    read -r raw_extras

    [[ "$raw_extras" == "b" || "$raw_extras" == "B" ]] && return 1

    EXTRA_FLAGS=""
    [[ "$raw_extras" == "0" || -z "$raw_extras" ]] && return 0

    local e
    for e in $raw_extras; do
      case "$e" in
        1) [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]] && EXTRA_FLAGS+=" -sV" ;;
        2) EXTRA_FLAGS+=" -sC" ;;
        3) [[ "$STEALTH_FLAGS" != *"-O"* && "$EXTRA_FLAGS" != *"-O"* ]] && EXTRA_FLAGS+=" -O --osscan-guess" ;;
        4)
          EXTRA_FLAGS+=" --script vuln"
          [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]] && EXTRA_FLAGS+=" -sV"
          ;;
        5) EXTRA_FLAGS+=" --script afp-serverinfo,dns-service-discovery,smb-os-discovery" ;;
        6) [[ -n "$profile_scripts" ]] && EXTRA_FLAGS+=" --script $profile_scripts" ;;
      esac
    done
    return 0
  done
}

# ── Device-specific tips ──────────────────────────────────────────────────────
get_device_tips() {
  case "$1" in
    1)
      echo -e "  ${BMAGENTA}  ›${NC} Mac: check ${BWHITE}System Settings → Sharing → File Sharing${NC} (opens AFP 548)"
      echo -e "  ${BMAGENTA}  ›${NC} Mac: Bonjour runs on UDP 5353 — try: ${BGREEN}sudo nmap -sU -Pn -p 5353 $TARGET${NC}"
      echo -e "  ${BMAGENTA}  ›${NC} Mac: enable ${BWHITE}Remote Login${NC} to open SSH (port 22)"
      ;;
    2|3)
      echo -e "  ${BCYAN}  ›${NC} iOS/iPadOS: ${BYELLOW}wake the screen${NC} — iOS closes ports when locked"
      echo -e "  ${BCYAN}  ›${NC} iOS/iPadOS: only lockdownd (62078) may stay open when screen is off"
      echo -e "  ${BCYAN}  ›${NC} iOS/iPadOS: tap ${BWHITE}'Trust This Computer'${NC} if a prompt appears"
      echo -e "  ${BCYAN}  ›${NC} Confirm reachable: ${BGREEN}sudo arping -c 3 $TARGET${NC}"
      ;;
    4)
      echo -e "  ${BBLUE}  ›${NC} Windows: Defender blocks ICMP — already using -Pn to skip ping"
      echo -e "  ${BBLUE}  ›${NC} Windows: SMB (445) may be blocked — try NetBIOS (139) instead"
      echo -e "  ${BBLUE}  ›${NC} Windows: check ${BWHITE}Settings → Network → Network discovery${NC} is ON"
      ;;
    5)
      echo -e "  ${BGREEN}  ›${NC} Linux: SSH (22) is almost always open — try: ${BGREEN}sudo nmap -sS -Pn -p 22 $TARGET${NC}"
      echo -e "  ${BGREEN}  ›${NC} Linux: iptables/ufw may block — try: ${BGREEN}--source-port 53${NC}"
      ;;
    6)
      echo -e "  ${BYELLOW}  ›${NC} Server: cloud providers (AWS/GCP/Azure) have security groups — check inbound rules"
      echo -e "  ${BYELLOW}  ›${NC} Server: try spoofed source port: ${BGREEN}sudo nmap -sS -Pn --source-port 53 $TARGET${NC}"
      ;;
    7)
      echo -e "  ${GREEN}  ›${NC} Android: enable ${BWHITE}Developer Options → USB Debugging${NC} for ADB (port 5555)"
      echo -e "  ${GREEN}  ›${NC} Android: ADB over Wi-Fi must be enabled explicitly in device settings"
      echo -e "  ${GREEN}  ›${NC} Test ADB: ${BGREEN}adb connect $TARGET:5555${NC}"
      ;;
    8)
      echo -e "  ${RED}  ›${NC} IoT/Router: ${BYELLOW}-sS (SYN) is often blocked${NC} — use TCP connect instead:"
      echo -e "  ${RED}    ${BGREEN}sudo nmap -sT -Pn -p 80,443,22,23,8080 $TARGET${NC}"
      echo -e "  ${RED}  ›${NC} IoT: check if AP isolation is blocking device-to-device traffic"
      echo -e "  ${RED}  ›${NC} SNMP: ${BGREEN}sudo nmap -sU -Pn -p 161 --script snmp-sysdescr $TARGET${NC}"
      ;;
    9)
      echo -e "  ${BLUE}  ›${NC} Printer: main ports are 9100 (JetDirect), 515 (LPD), 631 (IPP)"
      echo -e "  ${BLUE}  ›${NC} Routers/printers block SYN — use TCP connect: ${BGREEN}sudo nmap -sT -Pn -p 80,443,9100 $TARGET${NC}"
      echo -e "  ${BLUE}  ›${NC} SNMP: ${BGREEN}sudo nmap -sU -Pn -p 161 --script snmp-sysdescr $TARGET${NC}"
      echo -e "  ${BLUE}  ›${NC} Check web interface: ${BGREEN}curl -s http://$TARGET | head -5${NC}"
      ;;
  esac
}

# ── Device-specific rescue command ────────────────────────────────────────────
get_device_rescue_cmd() {
  case "$1" in
    1)  echo "sudo nmap -A -Pn -p 22,445,548,5353 --script afp-serverinfo,smb-os-discovery,dns-service-discovery $TARGET" ;;
    2)  echo "sudo nmap -sS -Pn -p 62078,7000 --source-port 5353 $TARGET" ;;
    3)  echo "sudo nmap -sS -Pn -p 62078,548,5353,7000 --source-port 5353 $TARGET" ;;
    4)  echo "sudo nmap -sS -Pn -p 135,139,445,3389 --script smb-os-discovery $TARGET" ;;
    5)  echo "sudo nmap -sS -Pn -p 22,80,443,8080 --script ssh-hostkey,banner $TARGET" ;;
    6)  echo "sudo nmap -A -Pn --source-port 53 $TARGET" ;;
    7)  echo "sudo nmap -sS -Pn -p 5555,5037,8080 --script banner $TARGET" ;;
    8)  echo "sudo nmap -sT -sU -Pn -p T:23,80,8080,U:161 --script snmp-sysdescr,banner $TARGET" ;;
    9)  echo "sudo nmap -sT -sU -Pn -p T:80,515,631,9100,U:161 --script pjl-ready-message,http-title $TARGET" ;;
    *)  echo "sudo nmap -A -Pn $TARGET" ;;
  esac
}

# ── Auto-retry with rescue command ────────────────────────────────────────────
auto_retry() {
  local rescue_cmd
  rescue_cmd=$(get_device_rescue_cmd "$DEVICE_TYPE")
  echo ""
  echo -e "  ${GRAY}  ┌────────────────────────────────────────────────────────────────${NC}"
  echo -e "  ${GRAY}  │${NC}  ${BGREEN}$rescue_cmd${NC}"
  echo -e "  ${GRAY}  └────────────────────────────────────────────────────────────────${NC}\n"
  echo -ne "  ${BYELLOW}➤${NC}  Auto-retry with this command? ${GRAY}[y/N]${NC}: "
  read -r confirm
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && { echo ""; return; }

  local retry_tmp
  retry_tmp=$(mktemp /tmp/en_scan_XXXXXX.txt)
  echo ""
  echo -e "$LINE"
  echo -e "  ${BCYAN}AUTO-RETRY${NC}  ${GRAY}→${NC}  ${BYELLOW}$TARGET${NC}"
  echo -e "$LINE\n"
  eval "$rescue_cmd" | tee "$retry_tmp"
  echo ""
  echo -e "$LINE"
  echo -e "  ${BGREEN}✓${NC}  Retry complete."
  echo -e "$LINE"
  analyze_scan "$retry_tmp" 0
  rm -f "$retry_tmp"
}

# ── Scan analysis ─────────────────────────────────────────────────────────────
# $1 = result file   $2 = 0 to suppress auto-retry
analyze_scan() {
  local f="$1" allow_retry="${2:-1}"
  [[ ! -f "$f" ]] && return

  local open_count host_down all_filtered os_detected os_unreliable
  open_count=$(grep -cE "/(tcp|udp)[[:space:]]+open" "$f" 2>/dev/null)
  host_down=$(grep -c "Host seems down\|0 hosts up" "$f" 2>/dev/null)
  all_filtered=$(grep -cE "All [0-9]+ scanned ports.*filtered|Not shown: [0-9]+ filtered" "$f" 2>/dev/null)
  os_detected=$(grep -c "OS details:\|Running:" "$f" 2>/dev/null)
  os_unreliable=$(grep -c "OSScan results may be unreliable" "$f" 2>/dev/null)
  open_count=${open_count:-0}; host_down=${host_down:-0}; all_filtered=${all_filtered:-0}
  os_detected=${os_detected:-0}; os_unreliable=${os_unreliable:-0}

  section "◈" "ANALYSIS" "$BYELLOW"

  if (( host_down > 0 )); then
    echo -e "  ${BRED}✗${NC}  Target returned 0 hosts up — unreachable or ports blocked\n"
    get_device_tips "$DEVICE_TYPE"
    echo ""
    echo -e "  ${BYELLOW}General fixes:${NC}"
    echo -e "  ${GRAY}  ›${NC} Confirm online: ${BGREEN}ping -c 3 $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} Spoof DNS port:  ${BGREEN}sudo nmap -sS -Pn --source-port 53 $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} Fragment:        ${BGREEN}sudo nmap -sS -Pn -f --mtu 24 $TARGET${NC}"
    echo ""
    if (( allow_retry )); then
      echo -e "  ${BYELLOW}Best rescue scan for ${DEVICE_COLOR}${DEVICE_NAME}${BYELLOW}:${NC}"
      auto_retry
    fi
    return
  fi

  if (( all_filtered > 0 && open_count == 0 )); then
    echo -e "  ${BYELLOW}△${NC}  All ports filtered — firewall dropping probe packets\n"
    get_device_tips "$DEVICE_TYPE"
    echo ""
    echo -e "  ${BYELLOW}General fixes:${NC}"
    echo -e "  ${GRAY}  ›${NC} Fragment:   ${BGREEN}sudo nmap -sS -Pn -f --mtu 24 $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} ACK scan:   ${BGREEN}sudo nmap -sA -Pn $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} UDP:        ${BGREEN}sudo nmap -sU -Pn --top-ports 100 $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} Full + -A:  ${BGREEN}sudo nmap -A -Pn -p- --min-rate 500 $TARGET${NC}"
    echo ""
    if (( allow_retry )); then
      echo -e "  ${BYELLOW}Best rescue scan for ${DEVICE_COLOR}${DEVICE_NAME}${BYELLOW}:${NC}"
      auto_retry
    fi
    return
  fi

  if (( open_count == 0 )); then
    echo -e "  ${BYELLOW}△${NC}  No open ports found with this profile\n"
    get_device_tips "$DEVICE_TYPE"
    echo ""
    echo -e "  ${BYELLOW}Try:${NC}"
    echo -e "  ${GRAY}  ›${NC} Full range: ${BGREEN}sudo nmap -sS -Pn -p- --min-rate 500 $TARGET${NC}"
    echo -e "  ${GRAY}  ›${NC} UDP:        ${BGREEN}sudo nmap -sU -Pn --top-ports 100 $TARGET${NC}"
    echo ""
    if (( allow_retry )); then
      echo -e "  ${BYELLOW}Best rescue scan for ${DEVICE_COLOR}${DEVICE_NAME}${BYELLOW}:${NC}"
      auto_retry
    fi
    return
  fi

  echo -e "  ${BGREEN}✓${NC}  ${open_count} open port(s) found\n"

  if (( os_unreliable > 0 )); then
    echo -e "  ${BYELLOW}△${NC}  OS fingerprint unreliable — try: ${BGREEN}sudo nmap -A -Pn -p- $TARGET${NC}"
  elif (( os_detected > 0 )); then
    echo -e "  ${BGREEN}✓${NC}  OS fingerprint captured"
  elif [[ "$STEALTH_FLAGS" != *"-O"* && "$EXTRA_FLAGS" != *"-O"* ]]; then
    echo -e "  ${GRAY}–${NC}  No OS detection — add: ${BGREEN}sudo nmap -A -Pn $TARGET${NC}"
  fi

  if [[ "$STEALTH_FLAGS" != *"-sV"* && "$EXTRA_FLAGS" != *"-sV"* ]]; then
    echo -e "  ${GRAY}–${NC}  No version detection — add: ${BGREEN}sudo nmap -sV -Pn $TARGET${NC}"
  fi

  echo ""
}

# ── Post-scan menu — stays alive until user decides ───────────────────────────
# Returns: 0=exit  1=new scan  2=same target  3=re-run  4=custom retry
post_scan_menu() {
  local is_apple=0
  [[ "$DEVICE_TYPE" =~ ^[123]$ ]] && is_apple=1

  local opt2_label
  case "$DEVICE_TYPE" in
    1)   opt2_label="${BMAGENTA}-A + Apple scripts${NC}    " ;;
    2|3) opt2_label="${BCYAN}lockdownd only  ·62078${NC} " ;;
    4)   opt2_label="${BBLUE}SMB + WinRM${NC}             " ;;
    5)   opt2_label="${BGREEN}SSH + banner${NC}            " ;;
    8)   opt2_label="${RED}SNMP + Telnet${NC}           " ;;
    9)   opt2_label="${BLUE}JetDirect + SNMP${NC}        " ;;
    *)   opt2_label="${BCYAN}-A + UDP${NC}                " ;;
  esac

  while true; do
    section "◈" "WHAT'S NEXT?" "$BCYAN"
    echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}New scan${NC}                new target, start over"
    echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}Same target${NC}             keep ${BYELLOW}$TARGET${NC}, change device/depth/noise"
    echo -e "  ${BWHITE}[3]${NC}  ${BYELLOW}Re-run${NC}                 exact same command again"
    echo -e "  ${GRAY}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${BWHITE}[4]${NC}  ${BCYAN}-A${NC}                       Aggressive  ${GRAY}(-sV -sC -O --traceroute)${NC}"
    echo -e "  ${BWHITE}[5]${NC}  ${opt2_label}  ${GRAY}best for ${DEVICE_COLOR}${DEVICE_NAME}${NC}"
    echo -e "  ${BWHITE}[6]${NC}  ${BYELLOW}-f --mtu 24${NC}             Fragment packets"
    echo -e "  ${BWHITE}[7]${NC}  ${BYELLOW}-sU --top-ports 100${NC}     UDP top 100"
    echo -e "  ${BWHITE}[8]${NC}  ${BYELLOW}-p- --min-rate 500${NC}      All 65535 ports"
    echo -e "  ${BWHITE}[9]${NC}  ${BYELLOW}-sT${NC}                      TCP connect  ${GRAY}(use when SYN is blocked — routers, IoT)${NC}"
    echo -e "  ${BWHITE}[c]${NC}  ${WHITE}Custom flags${NC}            type your own nmap parameters"
    echo -e "  ${GRAY}  ─────────────────────────────────────────────────────────────${NC}"
    echo -e "  ${BWHITE}[0]${NC}  ${GRAY}Exit${NC}\n"
    echo -ne "  ${BYELLOW}➤${NC}  Selection: "
    read -r choice

    case "$choice" in
      0) return 0 ;;   # exit
      1) return 1 ;;   # new scan
      2) return 2 ;;   # same target
      3) return 3 ;;   # re-run
      4|5|6|7|8|9|c|C)
        # Each option builds a complete, clean command — no flag conflicts
        local retry_cmd="" retry_label=""
        case "$choice" in
          4) retry_cmd="sudo nmap -A -Pn $TARGET"
             retry_label="-A" ;;
          5) # Device-specific standalone — its own ports, no DEPTH_FLAGS conflict
             case "$DEVICE_TYPE" in
               1)   retry_cmd="sudo nmap -A -Pn -p 22,445,548 --script afp-serverinfo,smb-os-discovery,dns-service-discovery $TARGET" ;;
               2|3) retry_cmd="sudo nmap -sS -Pn -p 62078 --source-port 5353 $TARGET" ;;
               4)   retry_cmd="sudo nmap -sS -Pn -p 135,139,445,5985 --script smb-os-discovery $TARGET" ;;
               5)   retry_cmd="sudo nmap -sS -Pn -p 22,80 --script ssh-hostkey,banner $TARGET" ;;
               8)   retry_cmd="sudo nmap -sT -sU -Pn -p T:23,80,U:161 --script snmp-sysdescr $TARGET" ;;
               9)   retry_cmd="sudo nmap -sT -sU -Pn -p T:9100,515,631,U:161 --script pjl-ready-message $TARGET" ;;
               *)   retry_cmd="sudo nmap -A -sU -Pn $TARGET" ;;
             esac
             retry_label="device-specific" ;;
          6) retry_cmd="sudo nmap $STEALTH_FLAGS $DEPTH_FLAGS -Pn -f --mtu 24 $TARGET"
             retry_label="-f --mtu 24" ;;
          7) retry_cmd="sudo nmap -sU -Pn --top-ports 100 $TARGET"
             retry_label="-sU top 100" ;;
          8) retry_cmd="sudo nmap $STEALTH_FLAGS -Pn -p- --min-rate 500 $TARGET"
             retry_label="-p- full range" ;;
          9) retry_cmd="sudo nmap -sT -Pn -p 80,443,22,23,8080,8443 $TARGET"
             retry_label="-sT TCP connect" ;;
          c|C)
            echo -ne "\n  ${BYELLOW}➤${NC}  Full flags (after 'sudo nmap'): "
            read -r custom_flags
            [[ -z "$custom_flags" ]] && continue
            retry_cmd="sudo nmap -Pn $custom_flags $TARGET"
            retry_label="custom"
            ;;
        esac
        echo -e "\n  ${GRAY}  │${NC}  ${BGREEN}$retry_cmd${NC}\n"
        echo -ne "  ${BYELLOW}➤${NC}  Execute? ${GRAY}[y/N]${NC}: "
        read -r confirm
        [[ "$confirm" != "y" && "$confirm" != "Y" ]] && continue
        local retry_tmp
        retry_tmp=$(mktemp /tmp/en_scan_XXXXXX.txt)
        echo ""
        echo -e "$LINE"
        echo -e "  ${BCYAN}SCANNING${NC}  ${GRAY}→${NC}  ${BYELLOW}$TARGET${NC}  ${GRAY}[$retry_label]${NC}"
        echo -e "$LINE\n"
        eval "$retry_cmd" | tee "$retry_tmp"
        echo ""
        echo -e "$LINE"
        echo -e "  ${BGREEN}✓${NC}  Scan complete."
        echo -e "$LINE"
        analyze_scan "$retry_tmp" 0
        rm -f "$retry_tmp"
        ;;
      *) echo -e "  ${BRED}✗${NC}  Enter 0–9\n" ;;
    esac
  done
}

# ── Execute scan ──────────────────────────────────────────────────────────────
# Returns: 0 = scan executed, 1 = user went back to extras
execute_scan() {
  local cmd="sudo nmap $STEALTH_FLAGS $DEPTH_FLAGS -Pn${EXTRA_FLAGS} $TARGET"

  section "◈" "SCAN SUMMARY" "$BWHITE"
  printf "  ${GRAY}%-14s${NC}  ${BYELLOW}%s${NC}\n"                          "Target"  "$TARGET"
  printf "  ${GRAY}%-14s${NC}  ${DEVICE_COLOR}%s${NC}\n"                     "Device"  "$DEVICE_NAME"
  printf "  ${GRAY}%-14s${NC}  $(stealth_color "$STEALTH_LEVEL")%s${NC}\n"   "Noise"   "$STEALTH_NAME"
  printf "  ${GRAY}%-14s${NC}  ${WHITE}%s${NC}\n"                            "Depth"   "$DEPTH_NAME"
  echo ""
  echo -e "  ${GRAY}Command${NC}"
  echo -e "  ${GRAY}  ┌────────────────────────────────────────────────────────────────${NC}"
  echo -e "  ${GRAY}  │${NC}  ${BGREEN}$cmd${NC}"
  echo -e "  ${GRAY}  └────────────────────────────────────────────────────────────────${NC}\n"
  echo -ne "  ${BYELLOW}➤${NC}  Execute? ${GRAY}[y/N/b=back]${NC}: "
  read -r confirm

  [[ "$confirm" == "b" || "$confirm" == "B" ]] && return 1
  [[ "$confirm" != "y" && "$confirm" != "Y" ]] && {
    echo -e "\n  ${GRAY}Cancelled — returning to menu.${NC}\n"
    return 1
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
  return 0
}

# ── Main wizard — state machine ───────────────────────────────────────────────
# States: 1=target  2=device  3=stealth  4=depth  5=extras  6=execute  7=post-scan
run_wizard() {
  local step=1

  while true; do
    case $step in
      1)  menu_target  && (( step++ )) || return 0 ;;
      2)  menu_device  && (( step++ )) || (( step-- )) ;;
      3)  menu_stealth && (( step++ )) || (( step-- )) ;;
      4)  menu_depth   && (( step++ )) || (( step-- )) ;;
      5)  menu_extras  && (( step++ )) || (( step-- )) ;;
      6)
        execute_scan
        local ret=$?
        if [[ $ret -eq 1 ]]; then
          (( step-- ))  # back to extras
        else
          step=7
        fi
        ;;
      7)
        post_scan_menu
        case $? in
          0) return 0 ;;     # exit
          1) step=1 ;;       # new scan
          2) step=2 ;;       # same target, pick device
          3) step=6 ;;       # re-run same command
        esac
        ;;
    esac
  done
}

# ── Main ──────────────────────────────────────────────────────────────────────
banner
get_local_ip
run_wizard
echo -e "  ${GRAY}Goodbye.${NC}\n"
