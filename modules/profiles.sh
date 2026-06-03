#!/bin/bash
# profiles.sh — Port profiles per device type

PROFILE_TOTAL=8

get_profile_count() { echo "$PROFILE_TOTAL"; }

get_profile_name() {
  case "$1" in
    1) echo "Mac / macOS"    ;;
    2) echo "iPhone / iOS"   ;;
    3) echo "PC Windows"     ;;
    4) echo "PC Linux"       ;;
    5) echo "Server"         ;;
    6) echo "Android"        ;;
    7) echo "IoT / Embedded" ;;
    8) echo "Generic"        ;;
  esac
}

get_profile_color() {
  case "$1" in
    1) echo -n "${BMAGENTA}" ;;  # Mac   → magenta / Apple
    2) echo -n "${BCYAN}"    ;;  # iOS   → cyan
    3) echo -n "${BBLUE}"    ;;  # Win   → blue
    4) echo -n "${BGREEN}"   ;;  # Linux → green
    5) echo -n "${BYELLOW}"  ;;  # Srv   → yellow
    6) echo -n "${GREEN}"    ;;  # Droid → light green
    7) echo -n "${RED}"      ;;  # IoT   → red
    8) echo -n "${GRAY}"     ;;  # Gen   → gray
  esac
}

get_profile_desc() {
  case "$1" in
    1) echo "AFP·548  Bonjour·5353  ARD·3283  AirPlay·7000  SSH·22" ;;
    2) echo "lockdownd·62078  AirPlay·7000  HTTP·80  iTunes·9"       ;;
    3) echo "RDP·3389  SMB·445  WinRM·5985  NetBIOS·139"             ;;
    4) echo "SSH·22  NFS·2049  VNC·5900  CUPS·631  HTTP·80"          ;;
    5) echo "FTP·21  SMTP·25  DNS·53  HTTP·80  SQL·3306  Redis·6379" ;;
    6) echo "ADB·5555  debug bridge·5037  HTTP·8080"                  ;;
    7) echo "Telnet·23  RTSP·554  MQTT·1883  UPnP·1900  CoAP·5683"  ;;
    8) echo "nmap default top 1000 ports"                             ;;
  esac
}

# Ports for "Standard" depth. Empty = --top-ports 1000
get_profile_ports() {
  case "$1" in
    1) echo "22,88,389,445,548,3283,5009,5353,7000,8080,8443,9999,49152" ;;
    2) echo "22,80,443,5000,7000,9,62078"                                 ;;
    3) echo "80,135,139,445,1433,3389,5985,5986,8080,8443,49152"          ;;
    4) echo "22,80,111,443,631,2049,3306,5432,5900,6379,8080,8443"        ;;
    5) echo "21,22,25,53,80,110,143,443,465,587,993,995,3306,5432,6379,8080,8443,9200,27017,50070" ;;
    6) echo "5555,5037,8080,8443"                                          ;;
    7) echo "23,80,443,554,1883,1900,5683,8080,8883,37777,49152"          ;;
    8) echo ""                                                             ;;
  esac
}

# Recommended NSE scripts per profile
get_profile_scripts() {
  case "$1" in
    1) echo "afp-info,smb-os-discovery,mdns-dns-sd" ;;
    2) echo "mdns-dns-sd"                            ;;
    3) echo "smb-os-discovery,smb-vuln-ms17-010"    ;;
    4) echo "ssh-hostkey,banner"                     ;;
    5) echo "banner,http-title,ssh-hostkey"          ;;
    6) echo "banner"                                 ;;
    7) echo "banner"                                 ;;
    8) echo ""                                       ;;
  esac
}
