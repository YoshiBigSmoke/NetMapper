
#!/bin/bash

#get router address

#hacer que se conecte al router
#hacer que pueda elegir entre su red o su pc 
#dar opciones 

#get self router ip address
Sip=$(ip add show $(ip route | grep default | awk '{print $5}') | grep 'inet ' | awk '{print $2}' | cut -f1 -d'/') 


# -- fist menu -- 
echo "select the target type:"
echo "1. Scan my network"
echo "2. Scan a specific IP address"
read target_type

if [ "$target_type" = "1" ]; then
    subnet="${Sip%.*}.0/24"

    # Descubrimiento: IP + hostname + vendor (si está en la LAN suele sacar MAC)
    sudo nmap -sn -PR --resolve-all "$subnet" | awk '
    /^Nmap scan report for/ {
        host=$5
        ip=""
        if ($6 ~ /^\(/) { ip=$6; gsub(/[()]/,"",ip) } else { ip=$5; host="" }
        cur_ip=ip
        cur_host=host
        if (cur_host=="" || cur_host==cur_ip) cur_host="unknown"
        next
    }
    /^MAC Address:/ {
        # Ej: MAC Address: 04:D6:0E:... (Funai Electric)
        vendor=$0
        sub(/^MAC Address: [0-9A-Fa-f:]+ \(/,"",vendor)
        sub(/\).*/,"",vendor)
        if (vendor=="") vendor="unknown"
        print cur_ip " - " cur_host " (" vendor ")"
        next
    }
    /^Nmap scan report for/ { next }
    ' > live_hosts.txt

    echo "Live hosts found:"
    nl -w2 -s'. ' live_hosts.txt

    echo "Select a host by number:"
    read selection

    Sip=$(sed -n "${selection}p" live_hosts.txt | awk '{print $1}')

    if [[ -z "$Sip" ]]; then
        echo "Invalid selection!"
        exit 1
    fi

elif [ "$target_type" = "2" ]; then
    echo "Enter the target IP address:"
    read Sip
fi


# -- second menu --
#prompt user for scan type
echo "select the scan type:"
echo "1. Quick Scan"
echo "2. Full Scan"

read scan_type

if [ "$scan_type" = "1" ]; then
    sudo nmap -sS -p- --min-rate 1000 -Pn $Sip
elif [ "$scan_type" = "2" ]; then
    sudo nmap -sS -sU -p- --min-rate 1000 -Pn $Sip
fi


