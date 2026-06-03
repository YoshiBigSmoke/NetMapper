#!/bin/bash
# discovery.sh — ARP ping host discovery

discovery_scan() {
  local subnet="$1"
  echo -e "\n  ${GRAY}Scanning ${BYELLOW}$subnet${GRAY} for live hosts...${NC}\n"

  # Hosts with visible MAC (remote devices)
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
  ' > /tmp/en_live_hosts.txt

  # Hosts without MAC (local machine or remote hops)
  sudo nmap -sn -PR --resolve-all "$subnet" 2>/dev/null | awk '
    /^Nmap scan report for/ {
      host=$5; ip=""
      if ($6 ~ /^\(/) { ip=$6; gsub(/[()]/,"",ip) } else { ip=$5; host="" }
      cur_ip=ip; cur_host=host
      if (cur_host=="" || cur_host==cur_ip) cur_host="unknown"
      has_mac=0
    }
    /^MAC Address:/ { has_mac=1 }
    /^Host is up/   { if (!has_mac) print cur_ip "|" cur_host "|" "(no MAC — local)" }
  ' >> /tmp/en_live_hosts.tmp 2>/dev/null

  cat /tmp/en_live_hosts.tmp >> /tmp/en_live_hosts.txt 2>/dev/null
  sort -t. -k1,1n -k2,2n -k3,3n -k4,4n /tmp/en_live_hosts.txt \
    | awk -F'|' '!seen[$1]++' > /tmp/en_live_sorted.txt
  mv /tmp/en_live_sorted.txt /tmp/en_live_hosts.txt
  rm -f /tmp/en_live_hosts.tmp

  if [[ ! -s /tmp/en_live_hosts.txt ]]; then
    echo -e "  ${BRED}✗${NC}  No hosts found on ${BYELLOW}$subnet${NC}\n"
    return 1
  fi

  local count
  count=$(wc -l < /tmp/en_live_hosts.txt)
  echo -e "  ${BGREEN}✓${NC}  ${BWHITE}$count host(s) found${NC}\n"
  printf "  ${GRAY}  %-5s %-20s %-34s %s${NC}\n" "#" "IP" "HOSTNAME" "VENDOR"
  echo -e "  ${GRAY}  ─────────────────────────────────────────────────────────────────${NC}"

  local i=1
  while IFS='|' read -r ip host vendor; do
    local vendor_color="$GRAY"
    [[ "$vendor" =~ [Aa]pple ]] && vendor_color="$BMAGENTA"
    printf "  ${BWHITE}  %-5s${NC} ${BYELLOW}%-20s${NC} ${CYAN}%-34s${NC} ${vendor_color}%s${NC}\n" \
      "$i." "$ip" "$host" "$vendor"
    ((i++))
  done < /tmp/en_live_hosts.txt
  echo ""
}
