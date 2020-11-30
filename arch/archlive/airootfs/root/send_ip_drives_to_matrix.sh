#!/bin/bash

# Gets all IP addresses (ip address show) and drives (fdisk -l) and sends it to a Matrix room
# Designed for my custom Arch ISO with SSH enabled
# Script will hang forever if not run as root or with root permissions
# Specifically, fdisk -l usually need root. Script does not handle sudo

# Config
#
# How many times to test for network connection. Waits 10 seconds in between each
# 1 minute = 6
# 10 minutes = 60
max_connection_attempts=30
#
# Matrix config
# The user the access token belongs to must already be in the room
delegated_homeserver_url="matrix.example.com"
# Replace ! with %21
room_id="%21mqwPzQRvfmMOUxqYPM:example.com"
access_token="superS3cr3t"


# Exit if not root
if [[ $EUID -ne 0 ]]; then
	exit 1
fi


# Check if internet is available, return 0 of true and 1 if false
function is_connected {
    wget -q --spider https://archlinux.org

    if [ $? -eq 0 ]; then
        return 0
    else
        return 1
    fi
}


# Test network connection and exit if no dice after max allowed attempts
connection_attempts=0
connection_status=is_connected
(( max_connection_attempts += 1 ))
while [ $connection_status == 1 ]
do
    sleep 10s
    (( connection_attempts += 1 ))
    if [ "$connection_attempts" == "$max_connection_attempts" ]
    then
        exit 1
    fi
done


# Get system information
current_user=$(whoami)
current_hostname=$(hostname)
current_date=$(date)
ips=$(ip address show)
resolve=$(resolvectl)
disks=$(fdisk -l)
lsblk=$(lsblk)


# Create mesage body

body="Hi, I have now booted up and have an internet connection. My details are
\`\`\`$current_user@$current_hostname ~ # date
$current_date

$current_user@$current_hostname ~ # ip address show
$ips\n\n$current_user@$current_hostname ~ # resolvectl
$resolve\n\n$current_user@$current_hostname ~ # fdisk -l
$lsblk\n\n$current_user@$current_hostname ~ # lsblk
$disks
\`\`\`"

formatted_body="Hi, I have now booted up and have an internet connection. My details are
<pre><code>$current_user@$current_hostname ~ # date
$current_date

$current_user@$current_hostname ~ # ip address show
$ips

$current_user@$current_hostname ~ # resolvectl
$resolve

$current_user@$current_hostname ~ # fdisk -l
$disks

$current_user@$current_hostname ~ # lsblk
$lsblk</pre></code>"


# Save multiline variables to temp files
echo "$body" > body.txt
echo "$formatted_body" > formatted_body.txt

# Replace newlines with literral \n and save the one line strings to variables
body=$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' body.txt)
formatted_body=$(sed -E ':a;N;$!ba;s/\r{0,1}\n/\\n/g' formatted_body.txt)

# Remove the temp files
rm body.txt
rm formatted_body.txt

# Create JSON header data
generate_post_data()
{
cat <<EOF
{
    "msgtype":"m.text",
    "body":"$body",
    "format":"org.matrix.custom.html",
    "formatted_body":"$formatted_body"
}
EOF
}


# Send Matrix message
curl \
    -XPOST "https://$delegated_homeserver_url/_matrix/client/r0/rooms/$room_id/send/m.room.message" \
    --header "Content-Type: application/json" \
    --header "Authorization: Bearer $access_token" \
    --data "$(generate_post_data)" \
    --silent > /dev/null


# Delete .zshrc to not send the Matrix message every time someone logs in
# Only if hostname is archiso, to not delete the file when testing on other computers
if [ "$current_hostname" == "archiso" ]
then
    rm /root/.zshrc
fi
