#!/bin/bash

	# to execute sript make it executable: chmod +x adblocl-script.sh
	# run with superuser right: devel-su ./setup_hosts.sh
	
	# The script basically automates the process developed and described at: https://dt.iki.fi/sailfish-os-adblock-hosts

# Function for user prompt
ask_user() {
    read -p "$1 (Y/n): " response
    case "$response" in
        [yY]|"") 
            return 0
            ;;
        [nN])
            return 1
            ;;
        *)
            echo "Invalid input. Please enter Y or n."
            ask_user "$1"
            ;;
    esac
}

# Default URL
default_url="https://notabug.org/ohnonot/sfos/raw/45a3f1132adc9cf6e0d1d13d5b82733f30795a9d/hosts/hostsupdate"

# User prompt for downloading the URL
if ask_user "Would you like to run the script? (Y or enter to proceed)" ; then
    read -p "On [Enter] Hostsupdate will be retrieved from URL [$default_url]. Otherwise enter URL: " custom_url
    custom_url=${custom_url:-$default_url} # Use default URL if custom_url is empty
    
    # Function for downloading URL
    download_url() {
        local url="$1"
        local destination="$2"
        curl -o "$destination" "$url"
    }
    
    # Change directory to /etc/systemd/system
    cd /etc/systemd/system
    
    # Create the hosts.timer file
    cat <<EOF | tee hosts.timer > /dev/null
[Unit]
Description=Update /etc/hosts

[Timer]
WakeSystem=false
OnCalendar=Sat *-*-* 16:00:00
RandomizedDelaySec=1h
AccuracySec=1h
Persistent=true

[Install]
WantedBy=timers.target
EOF
    
    # Create the hosts.service file
    cat <<EOF | tee hosts.service > /dev/null
[Unit]
Description=Update /etc/hosts

[Service]
ExecStart=/usr/local/bin/hostsupdate
EOF
    
    # Change directory to /usr/local/bin
    cd /usr/local/bin
    
    # Download the specified URL
    download_url "$custom_url" "hostsupdate"
    
    # Give hostsupdate execution permission
    chmod +x hostsupdate
    
    # Write specific content to hosts.head
    cat <<EOF | tee /etc/hosts.head > /dev/null
127.0.0.1       localhost.localdomain localhost
::1     localhost6.localdomain6 localhost6 ip6-localhost
EOF
    
    # Give hosts.head execution permission
    chmod +x /etc/hosts.head
    
    # Start and enable the timer
    systemctl start --now hosts.timer && systemctl enable hosts.timer
    
    # Execute the hostsupdate script
    cd /usr/local/bin/
    ./hostsupdate
    
    # Prompt for system reboot
    echo "Please note that you need to reboot the system to apply the changes."
else
    echo "Script execution aborted."
fi

