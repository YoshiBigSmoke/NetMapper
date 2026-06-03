#!/bin/bash
# demo.sh — Simulates easynmap.sh UI for recording demos (no real nmap)

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

t() { sleep "${1:-0.04}"; }   # typing delay
nl() { echo ""; }

type_out() {
  local text="$1" delay="${2:-0.04}"
  local i char
  for (( i=0; i<${#text}; i++ )); do
    char="${text:$i:1}"
    printf "%s" "$char"
    sleep "$delay"
  done
  echo ""
}

header() {
  echo -e "\n${1}  ◈  ${2}  ${NC}"
  echo -e "$SEP\n"
}

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
  sleep 1
}

demo_discovery() {
  echo -e "\n  ${BCYAN}[+]${NC} Scanning ${BYELLOW}192.168.1.0/24${NC} ...\n"
  sleep 1.5
  echo -e "  ${BGREEN}[✓]${NC} ${BWHITE}5 host(s) found${NC}\n"
  echo -e "  ${GRAY}  #    IP                  HOSTNAME                        VENDOR${NC}"
  echo -e "$SEP"
  sleep 0.2
  printf "  ${BWHITE}%-5s${NC} ${BYELLOW}%-20s${NC} ${CYAN}%-32s${NC} ${GRAY}%s${NC}\n" "1." "192.168.1.1"   "router.local"        "TP-Link Technologies"
  sleep 0.15
  printf "  ${BWHITE}%-5s${NC} ${BYELLOW}%-20s${NC} ${CYAN}%-32s${NC} ${BMAGENTA}%s${NC}\n" "2." "192.168.1.4"   "macbook-pro.local"   "Apple, Inc."
  sleep 0.15
  printf "  ${BWHITE}%-5s${NC} ${BYELLOW}%-20s${NC} ${CYAN}%-32s${NC} ${BMAGENTA}%s${NC}\n" "3." "192.168.1.7"   "iphone.local"        "Apple, Inc."
  sleep 0.15
  printf "  ${BWHITE}%-5s${NC} ${BYELLOW}%-20s${NC} ${CYAN}%-32s${NC} ${GRAY}%s${NC}\n"    "4." "192.168.1.10"  "desktop-win.local"   "ASRock Incorporation"
  sleep 0.15
  printf "  ${BWHITE}%-5s${NC} ${BYELLOW}%-20s${NC} ${CYAN}%-32s${NC} ${GRAY}%s${NC}\n"    "5." "192.168.1.15"  "raspberrypi.local"   "Raspberry Pi Foundation"
  echo ""
}

demo_nmap_output() {
  echo -e "${GRAY}Starting Nmap 7.94 ( https://nmap.org )${NC}"
  sleep 0.5
  echo -e "${GRAY}Nmap scan report for macbook-pro.local (192.168.1.4)${NC}"
  sleep 0.3
  echo -e "${GRAY}Host is up (0.0023s latency).${NC}"
  sleep 0.2
  echo ""
  printf "${GRAY}%-10s %-10s %-10s %s${NC}\n" "PORT" "STATE" "SERVICE" "VERSION"
  sleep 0.15
  printf "${BGREEN}%-10s${NC} ${GREEN}%-10s${NC} ${CYAN}%-10s${NC} ${WHITE}%s${NC}\n" \
    "22/tcp"   "open" "ssh"    "OpenSSH 9.4 (protocol 2.0)"
  sleep 0.1
  printf "${BGREEN}%-10s${NC} ${GREEN}%-10s${NC} ${CYAN}%-10s${NC} ${WHITE}%s${NC}\n" \
    "88/tcp"   "open" "kerberos-sec" "Heimdal Kerberos"
  sleep 0.1
  printf "${BGREEN}%-10s${NC} ${GREEN}%-10s${NC} ${CYAN}%-10s${NC} ${WHITE}%s${NC}\n" \
    "445/tcp"  "open" "microsoft-ds" "Samba smbd 4.x"
  sleep 0.1
  printf "${BGREEN}%-10s${NC} ${GREEN}%-10s${NC} ${CYAN}%-10s${NC} ${BMAGENTA}%s${NC}\n" \
    "548/tcp"  "open" "afp"    "Apple Filing Protocol"
  sleep 0.1
  printf "${BGREEN}%-10s${NC} ${GREEN}%-10s${NC} ${CYAN}%-10s${NC} ${BMAGENTA}%s${NC}\n" \
    "5353/tcp" "open" "mdns"   "Bonjour / mDNS"
  sleep 0.1
  printf "${BGREEN}%-10s${NC} ${GREEN}%-10s${NC} ${CYAN}%-10s${NC} ${BMAGENTA}%s${NC}\n" \
    "7000/tcp" "open" "afs3"   "AirPlay (Apple)"
  sleep 0.3
  echo ""
  echo -e "${BMAGENTA}OS details: macOS Sonoma 14.x${NC}"
  sleep 0.2
  echo -e "${GRAY}Network Distance: 1 hop${NC}"
  sleep 0.2
  echo -e "${GRAY}Service Info: Host: macbook-pro; OS: macOS${NC}"
}

# ── Demo flow ─────────────────────────────────────────────────────────────────
banner

# TARGET
header '\033[1;37;44m' 'TARGET'
echo -e "  ${BCYAN}◆${NC} Local IP : ${BYELLOW}192.168.1.5${NC}   ${GRAY}[wlan0]${NC}\n"
echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Scan my network${NC}    ${GRAY}→  192.168.1.0/24${NC}"
echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}IP / hostname${NC}      ${GRAY}→  enter manually${NC}\n"
echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
sleep 0.8; type_out "1" 0.1

echo -e "\n$SEP"
echo -e "  ${BCYAN}DISCOVERY  ${GRAY}→  ${BYELLOW}192.168.1.0/24${NC}\n"
demo_discovery

echo -ne "  ${BMAGENTA}➤  Host number:${NC} "
sleep 0.8; type_out "2" 0.1
echo -e "\n  ${BGREEN}[✓]${NC} Target : ${BYELLOW}192.168.1.4${NC}  ${GRAY}macbook-pro.local${NC}  ${BMAGENTA}Apple, Inc.${NC}\n"
sleep 0.5

# DEVICE TYPE
header '\033[1;37;45m' 'DEVICE TYPE'
printf "  ${BWHITE}[%s]${NC}  ${BMAGENTA}%-16s${NC}  ${GRAY}%s${NC}\n" "1" "Mac / macOS"    "AFP·548  Bonjour·5353  ARD·3283  AirPlay·7000  SSH·22"
printf "  ${BWHITE}[%s]${NC}  ${BCYAN}%-16s${NC}  ${GRAY}%s${NC}\n"    "2" "iPhone / iOS"   "lockdownd·62078  AirPlay·7000  HTTP·80  iTunes·9"
printf "  ${BWHITE}[%s]${NC}  ${BBLUE}%-16s${NC}  ${GRAY}%s${NC}\n"    "3" "PC Windows"     "RDP·3389  SMB·445  WinRM·5985  NetBIOS·139"
printf "  ${BWHITE}[%s]${NC}  ${BGREEN}%-16s${NC}  ${GRAY}%s${NC}\n"   "4" "PC Linux"       "SSH·22  NFS·2049  VNC·5900  CUPS·631  HTTP·80"
printf "  ${BWHITE}[%s]${NC}  ${BYELLOW}%-16s${NC}  ${GRAY}%s${NC}\n"  "5" "Server"         "FTP·21  SMTP·25  DNS·53  HTTP·80  SQL·3306  Redis·6379"
printf "  ${BWHITE}[%s]${NC}  ${GREEN}%-16s${NC}  ${GRAY}%s${NC}\n"    "6" "Android"        "ADB·5555  debug bridge·5037  HTTP·8080"
printf "  ${BWHITE}[%s]${NC}  ${RED}%-16s${NC}  ${GRAY}%s${NC}\n"      "7" "IoT / Embedded" "Telnet·23  RTSP·554  MQTT·1883  UPnP·1900  CoAP·5683"
printf "  ${BWHITE}[%s]${NC}  ${GRAY}%-16s${NC}  ${GRAY}%s${NC}\n"     "8" "Generic"        "nmap default top 1000 ports"
echo ""
echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
sleep 0.8; type_out "1" 0.1
echo -e "\n  ${BGREEN}[✓]${NC} Profile : ${BMAGENTA}Mac / macOS${NC}\n"
sleep 0.5

# NOISE LEVEL
header '\033[0;30;46m' 'NOISE LEVEL'
printf "  ${BWHITE}[1]${NC}  ${BGREEN}%-14s${NC}  ${GRAY}%s${NC}\n" "Silent"     "SYN · T2 · 200ms delay · no fingerprinting"
printf "  ${BWHITE}[2]${NC}  ${BYELLOW}%-14s${NC}  ${GRAY}%s${NC}\n" "Normal"     "SYN · T3 · 300 pkt/s · balanced"
printf "  ${BWHITE}[3]${NC}  ${BRED}%-14s${NC}  ${GRAY}%s${NC}\n"   "Aggressive" "SYN · T4 · 1000 pkt/s · versions + OS + OS-guess"
echo ""
echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
sleep 0.8; type_out "3" 0.1
echo -e "\n  ${BGREEN}[✓]${NC} Mode : ${BRED}Aggressive${NC}\n"
sleep 0.5

# SCAN DEPTH
header '\033[0;30;42m' 'SCAN DEPTH'
echo -e "  ${BWHITE}[1]${NC}  ${BGREEN}Fast${NC}       ${GRAY}top 100 ports · fastest${NC}"
echo -e "  ${BWHITE}[2]${NC}  ${BYELLOW}Standard${NC}   ${GRAY}key ports for ${BMAGENTA}Mac / macOS${NC}"
echo -e "  ${BWHITE}[3]${NC}  ${BRED}Full${NC}       ${GRAY}all ports 1–65535 · slow${NC}\n"
echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
sleep 0.8; type_out "2" 0.1
echo -e "\n  ${BGREEN}[✓]${NC} Depth : ${BYELLOW}Standard${NC}\n"
sleep 0.5

# EXTRAS
header '\033[1;37;41m' 'OPTIONAL EXTRAS'
echo -e "  ${GRAY}Enter numbers separated by spaces  ·  0 = none${NC}\n"
echo -e "  ${BWHITE}[1]${NC}  ${BCYAN}-sV${NC}                          Service version detection"
echo -e "  ${BWHITE}[2]${NC}  ${BCYAN}-sC${NC}                          Default NSE scripts"
echo -e "  ${BWHITE}[3]${NC}  ${BCYAN}-O --osscan-guess${NC}            OS detection with aggressive guessing"
echo -e "  ${BWHITE}[4]${NC}  ${BCYAN}--script vuln${NC}                Known vulnerability scan"
echo -e "  ${BWHITE}[5]${NC}  ${BMAGENTA}--script afp,mdns,smb-os${NC}     Apple / Mac fingerprint${NC}"
echo -e "  ${BWHITE}[6]${NC}  ${BYELLOW}Recommended scripts for ${BMAGENTA}Mac / macOS${BYELLOW}:${NC} ${GRAY}afp-info,smb-os-discovery,mdns-dns-sd${NC}"
echo ""
echo -ne "  ${BMAGENTA}➤  Selection:${NC} "
sleep 0.8; type_out "5 6" 0.1
echo ""
sleep 0.5

# SUMMARY
CMD="sudo nmap -sS -sV --version-intensity 6 -O --osscan-guess -T4 --min-rate 1000 -p 22,88,389,445,548,3283,5009,5353,7000,8080,8443,9999,49152 -Pn --script afp-info,mdns-dns-sd,smb-os-discovery,afp-info,smb-os-discovery,mdns-dns-sd 192.168.1.4"

echo -e "\n${BWHITE}  ╔══════════════════════════════════════════════════════════════════════╗${NC}"
echo -e "${BWHITE}  ║${NC}  ${BYELLOW}◈  SCAN SUMMARY${NC}                                                    ${BWHITE}║${NC}"
echo -e "${BWHITE}  ╠══════════════════════════════════════════════════════════════════════╣${NC}"
printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  ${BYELLOW}%-54s${BWHITE}║${NC}\n" "Target:"    "192.168.1.4"
printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  ${BMAGENTA}%-54s${BWHITE}║${NC}\n" "Device:"    "Mac / macOS"
printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  ${BRED}%-54s${BWHITE}║${NC}\n"    "Noise:"     "Aggressive"
printf "${BWHITE}  ║${NC}  ${GRAY}%-13s${NC}  ${WHITE}%-54s${BWHITE}║${NC}\n"   "Depth:"     "Standard"
echo -e "${BWHITE}  ╠══════════════════════════════════════════════════════════════════════╣${NC}"
echo -e "${BWHITE}  ║${NC}  ${BCYAN}Command:${NC}                                                              ${BWHITE}║${NC}"
echo -e "${BWHITE}  ║${NC}  ${BGREEN}$CMD${NC}"
echo -e "${BWHITE}  ╚══════════════════════════════════════════════════════════════════════╝${NC}\n"

echo -ne "  ${BMAGENTA}➤  Execute? ${GRAY}[y/N]${NC}: "
sleep 0.8; type_out "y" 0.1

echo -e "\n$SEP"
echo -e "  ${BCYAN}SCANNING  ${GRAY}→  ${BYELLOW}192.168.1.4${NC}"
echo -e "$SEP\n"
sleep 1
demo_nmap_output
echo -e "\n$SEP"
echo -e "  ${BGREEN}[✓] Scan complete.${NC}"
echo -e "$SEP\n"
