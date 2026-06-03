#!/bin/bash
# profiles.sh — Port profiles per device type

PROFILE_TOTAL=10

get_profile_count() { echo "$PROFILE_TOTAL"; }

get_profile_name() {
  case "$1" in
    1)  echo "Mac / macOS"    ;;
    2)  echo "iPhone / iOS"   ;;
    3)  echo "iPad / iPadOS"  ;;
    4)  echo "PC Windows"     ;;
    5)  echo "PC Linux"       ;;
    6)  echo "Server"         ;;
    7)  echo "Android"        ;;
    8)  echo "IoT / Embedded" ;;
    9)  echo "Printer"        ;;
    10) echo "Generic"        ;;
  esac
}

get_profile_color() {
  case "$1" in
    1)  echo -n "${BMAGENTA}" ;;  # Mac     → bright magenta
    2)  echo -n "${BCYAN}"    ;;  # iPhone  → bright cyan
    3)  echo -n "${CYAN}"     ;;  # iPad    → cyan
    4)  echo -n "${BBLUE}"    ;;  # Windows → bright blue
    5)  echo -n "${BGREEN}"   ;;  # Linux   → bright green
    6)  echo -n "${BYELLOW}"  ;;  # Server  → yellow
    7)  echo -n "${GREEN}"    ;;  # Android → green
    8)  echo -n "${RED}"      ;;  # IoT     → red
    9)  echo -n "${BLUE}"     ;;  # Printer → blue
    10) echo -n "${GRAY}"     ;;  # Generic → gray
  esac
}

get_profile_desc() {
  case "$1" in
    1)  echo "AFP·548  Bonjour·5353  ARD·3283  AirPlay·7000  SSH·22"  ;;
    2)  echo "lockdownd·62078  AirPlay·7000  HTTP·80  iTunes·9"        ;;
    3)  echo "lockdownd·62078  AFP·548  Bonjour·5353  AirPlay·7000"    ;;
    4)  echo "RDP·3389  SMB·445  WinRM·5985  NetBIOS·139  HTTP·80"    ;;
    5)  echo "SSH·22  NFS·2049  VNC·5900  CUPS·631  HTTP·80"           ;;
    6)  echo "FTP·21  SMTP·25  DNS·53  HTTP·80  SQL·3306  Redis·6379"  ;;
    7)  echo "ADB·5555  debug bridge·5037  HTTP·8080"                  ;;
    8)  echo "Telnet·23  RTSP·554  MQTT·1883  UPnP·1900  SNMP·161"    ;;
    9)  echo "JetDirect·9100  LPD·515  IPP·631  HTTP·80  SNMP·161"    ;;
    10) echo "nmap default top 1000 ports"                              ;;
  esac
}

# Ports for Standard depth. Empty = --top-ports 1000
get_profile_ports() {
  case "$1" in
    1)  echo "22,88,389,445,548,3283,5009,5353,7000,8080,8443,9999,49152" ;;
    2)  echo "22,80,443,5000,7000,9,62078"                                 ;;
    3)  echo "22,80,443,548,5000,5009,5353,7000,9,62078"                  ;;
    4)  echo "80,135,139,445,1433,3389,5985,5986,8080,8443,49152"          ;;
    5)  echo "22,80,111,443,631,2049,3306,5432,5900,6379,8080,8443"        ;;
    6)  echo "21,22,25,53,80,110,143,443,465,587,993,995,3306,5432,6379,8080,8443,9200,27017,50070" ;;
    7)  echo "5555,5037,8080,8443"                                          ;;
    8)  echo "23,80,443,554,1883,1900,5683,8080,8883,37777,49152"          ;;
    9)  echo "80,443,515,631,9100,8080"                                     ;;
    10) echo ""                                                             ;;
  esac
}

# Verified NSE scripts per profile (only scripts confirmed in /usr/share/nmap/scripts/)
get_profile_scripts() {
  case "$1" in
    1)  echo "afp-serverinfo,smb-os-discovery,dns-service-discovery" ;;
    2)  echo "dns-service-discovery"                                  ;;
    3)  echo "afp-serverinfo,dns-service-discovery"                   ;;
    4)  echo "smb-os-discovery,smb-vuln-ms17-010"                    ;;
    5)  echo "ssh-hostkey,banner"                                     ;;
    6)  echo "banner,http-title,ssh-hostkey"                          ;;
    7)  echo "banner"                                                 ;;
    8)  echo "banner,snmp-sysdescr"                                   ;;
    9)  echo "pjl-ready-message,http-title"                           ;;
    10) echo ""                                                       ;;
  esac
}
