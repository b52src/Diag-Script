#!/bin/bash
#
# Diagnostic Script
# Created by: Sean Crow
# Version: Alpha .031
## Use of this script is your sole responsibility and implies that you accept any risk and/or liability associated with executing this on your device.
## If you should come across an issue or would like to submit a feature request,
# please submit an issue: [https://github.com/b52src/Diag-Script/issues]
## Run script with: bash diag-script.sh
## For Vyatta run script with: su -c "diag-script.sh"
# To run without requiring interaction (example of use would be to trigger if monitoring detects an incident)
## bash diag-script.sh -option $argument -option $argument
## If you use this it is recommended that you have all of the programs listed under the "Current Diag Options:" section in this readme for best results, as running with parameters skips the program check.
## Available options: -o; -i
## -o is the Diag option, the argument following the option should be one of the below:
### 1 - Network Diag (Not available on Vyatta, use Vyatta Diag)
### 2 - Slow Diag (Not available on Vyatta)
### 3 - Raid Diag
### 4 - Vyatta Diag (Only works on Vyatta)
## -i is the destination IP for network and vyatta diags option (Only needed on Network or Vyatta diags, if you do not pass the IP it will stop and ask for it), Argument to follow should be the IP.
## Example: bash diag-script.sh -o 1 -i 8.8.8.8
## Vyatta Evample: su -c "bash diag-script.sh -o 4 -i 8.8.8.8"

# Run remotely and cat to local console(not officially supported at this time):
## ssh root@10.0.0.0 "bash -i" <  ./diag-script.sh
## ssh root@10.0.0.0 cat diag_2016-04-27-23 1816.log.txt

TITLE="Diagnostic Script "
INSTRUCTIONS="Use of this script is your sole responsibility and implies that you accept any risk and/or liability associated with executing this on your device.  This script will pull general and common information for troubleshooting issues. Please note that additional information may be needed, and this script is supplemental, and not a substitute for your own diagnostics and troubleshooting. The script will check for some common diagnostic tools and ask if you wish to install them if they are missing. You can proceed without these tools, however the best support data will come from running the script using the suggested tools. This script should be run as root or sudo for optimal results, for Vyatta run with: su -c \"bash diag-script.sh\". Please select a diagnostic action you would like to perform:"
COL_WIDTH=$(tput cols)
TITLE_WIDTH=$((($COL_WIDTH/2)-(${#TITLE})/2))
TextDIV="==============================="
TextDIV2="-------------------------------"
NET_INSTRUCTIONS="Please Input a Destination IP for Traceroute, MTR, and PING test:"
OS_TYPE=""

ADAPTEC=/usr/StorMan/arcconf
ADAPTEC_EVENT=/usr/Adaptec_Event_Monitor/arcconf
AVAGO=/opt/MegaRAID/storcli/storcli64
VYATTASH=/opt/vyatta/bin/vyatta-op-cmd-wrapper

# checks for MTR version and if IPV6 is disabled in the kernal
MTRVER=$(command mtr -v >/dev/null 2>&1 | sed -n 's/mtr 0.//p')
IPV6=$(if cat /proc/cmdline | grep -oq "ipv6.disable=1"; then echo "Disabled"; else echo "Enabled"; fi)

DIG=$(if command -v dig >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
IFCON=$(if command -v ifconfig >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
NETSTAT=$(if command -v netstat >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
SS=$(if command -v ss >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
LSOF=$(if command -v lsof >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
TRACE=$(if command -v traceroute >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
MTR=$(if command -v mtr >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
# checks for MTR 0.85(and lower) IPV6 disabled BUG
MTRBUG=$(if [ "$MTRVER" \< 86 ] && [ "$IPV6" = "Disabled" ] && [ "$OS_TYPE" = "UBUNTU" ]; then echo "Present"; else echo "NOBUG"; fi)
TOP=$(if command -v top >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
FREE=$(if command -v free >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
PS=$(if command -v ps >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
IOSTAT=$(if command -v iostat >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)
VMSTAT=$(if command -v vmstat >/dev/null 2>&1; then echo "Yes"; else echo "No"; fi)




##Required Paramaters to run without aditional interaction:
CUST_SELECTION=""
DEST_IP=""

#Get options
while getopts o:i: option
do
 case "${option}"
 in
 o) CUST_SELECTION=${OPTARG}; CUST_OPT=${OPTARG};;
 i) DEST_IP=${OPTARG}; IP_OPT=${OPTARG};;
 esac
done

function Diag_Complete
{
 echo "Diag Complete." | echo "Please attach $FILENAME to your ticket"
}

function NetComChk
# check for Net Diag Programs
{
	if [ "$DIG" == Yes ]  && [ "$IFCON" == Yes ] && [ "$NETSTAT" == Yes ] && [ "$SS" == Yes ] && [ "$LSOF" == Yes ] && [ "$TRACE" == Yes ] && [ "$MTR" == Yes ]
	then
		echo "all suggested programs found"
	else
		echo -e "\nThe following programs are suggested for optimal results: \n dig:\t\t$DIG\n ifconfig:\t$IFCON\n netstat:\t$NETSTAT\n ss:\t\t$SS\n lsof:\t\t$LSOF\n traceroute:\t$TRACE\n mtr:\t\t$MTR\n\nIt Is recommended to have the above programs installed for optimal Results.\n"
		read -r -p "Would you like to Continue without these installed? <y/N> " Y_N
		if [[ $Y_N == "y" || $Y_N == "Y" || $Y_N == "yes" || $Y_N == "Yes" ]]
		then
			echo "Continuing..."
		else
			echo "Exiting, please rerun when you are ready"
			exit 0
		fi
	fi
}

 function NetDiag01
{
	echo -e "\n$TextDIV\n\t/etc/resolv.conf\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	cat /etc/resolv.conf >>./$FILENAME
	Resolv=$(grep -oPm 1  '(?<=^nameserver ).*' /etc/resolv.conf)
	echo -e "\n$TextDIV\ndig  reddit.com @$Resolv\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command dig  reddit.com @$Resolv 2>/dev/null |grep -i reddit.com >> ./$FILENAME && command dig  google.com @$Resolv |grep -i google.com >> ./$FILENAME && command dig  ibm.com @$Resolv |grep -i ibm.com >> ./$FILENAME || { echo "dig not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tifconfig\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command ifconfig 1>>./$FILENAME 2>/dev/null || { echo "ifconfig not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tnetstat\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command netstat -s 1>>./$FILENAME 2>/dev/null || { echo "netstat not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tss -s\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command ss -s 1>>./$FILENAME 2>/dev/null || { echo "ss not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tlsof -i\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command lsof -i 1>>./$FILENAME 2>/dev/null || { echo "lsof not installed">>./$FILENAME;}
	[ -z "$IP_OPT" ] && echo "$NET_INSTRUCTIONS"
	[ -z "$IP_OPT" ] && read DEST_IP
	[ -z "$IP_OPT" ] && echo "Starting Ping, Taceroute, and MTR. Tests may take some time to complete, please stand by."
	echo -e "\n$TextDIV\n\ttraceroute\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	if [ "$MTRBUG" == Present ] || [ "$MTR" == No ];
	then
		command traceroute $DEST_IP 1>>./$FILENAME 2>/dev/null || { echo "Traceroute not installed">>./$FILENAME;}
	else
	    	echo "MTR installed, skipping Traceroute">>./$FILENAME
	fi
	echo -e "\n$TextDIV\n\t100 count ping\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	if [ "$MTRBUG" == Present ] || [ "$MTR" == No ];
  	then
		ping -c 100 -q  $DEST_IP >>./$FILENAME
  	else
    		echo "MTR installed, skipping Ping">>./$FILENAME
  	fi
	[ -z "$IP_OPT" ] && echo "Ping Complete, Starting MTR"
	echo -e "\n$TextDIV\n\t100 count mtr\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	if [ "$MTRBUG" == Present ];
	then
		echo -e "Known Bug Present: MTR 0.85 and older will not work if IPv6 is dissabled in the Kernel" >> ./$FILENAME
	else
		echo -e "$TextDIV2\n\tICMP:\n$TextDIV2" >> ./$FILENAME
		command mtr -c 100 -r $DEST_IP 1>>./$FILENAME 2>/dev/null || { echo "mtr not installed">>./$FILENAME;}
		echo -e "\n$TextDIV2\n\tUDP:\n$TextDIV2" >> ./$FILENAME
		command mtr -u -c 100 -r $DEST_IP 1>>./$FILENAME 2>/dev/null || { echo "mtr not installed">>./$FILENAME;}
	fi
}

function SlowComChk
# check for Slow System Diag Programs
{
	if [ "$TOP" == Yes ]  && [ "$FREE" == Yes ] && [ "$PS" == Yes ] && [ "$SS" == Yes ] && [ "$IOSTAT" == Yes ] && [ "$VMSTAT" == Yes ]
	then
		echo "all suggested programs found"
	else
		echo -e "\nThe following programs are suggested for optimal results: \n top:\t\t$TOP\n free:\t\t$FREE\n ps:\t\t$PS\n ss:\t\t$SS\n iostat:\t$IOSTAT\n vmstat:\t$VMSTAT\n\nIt Is recommended to have the above programs installed for optimal Results.\n"
		read -r -p "Would you like to Continue without these installed? <y/N> " Y_N
		if [[ $Y_N == "y" || $Y_N == "Y" || $Y_N == "yes" || $Y_N == "Yes" ]]
		then
			echo "Continuing..."
		else
			echo "Exiting, please rerun when you are ready"
			exit 0
		fi
	fi
}

function SlowDiag01
{
	echo -e "\n$TextDIV\n\tnice top\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command nice top -n1 -b 1>>./$FILENAME 2>/dev/null || { echo "top not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tfree -m\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command free -m 1>>./$FILENAME 2>/dev/null || { echo "free not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tps aux\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command ps aux 1>>./$FILENAME 2>/dev/null || { echo "ps not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tss -s\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command ss -s 1>>./$FILENAME 2>/dev/null || { echo "ss not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tiostat\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command iostat 1>>./$FILENAME 2>/dev/null || { echo "iostat not installed">>./$FILENAME;}
	echo -e "\n$TextDIV\n\tvmstat\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	command vmstat 1>>./$FILENAME 2>/dev/null || { echo "vmstat not installed">>./$FILENAME;}
	RAID01
}

function RAIDComChk
# check for RAID card and SW installed
# lspci not installed in Cent7 and RHEL7 by default, using lsscsi
{
	if [ $OS_TYPE = "CENT7" ]
	then
		if lsscsi | grep -i AVAGO 1>/dev/null 2>/dev/null
		then
			if [ -e $AVAGO ]
			then
				echo "LSI RAID card detected and Software installed"
			else
				echo -e "LSI RAID card detected but software is not installed\nWe reccomend installing the LSI RAID software so the RAID card can be checked"
			fi
		elif lsscsi | grep -i adaptec 1>/dev/null 2>/dev/null
		then
			if [ -e $ADAPTEC ] | [ -e $ADAPTEC_EVENT ]
			then
				echo "Adaptec RAID card detected and Software installed"
			else
				echo -e "Adaptec RAID card detected but software is not installed\nWe recommend installing the Adaptec RAID software so the RAID card can be checked"
			fi
		else
			echo "No RAID card detected quitting"
		fi
	else
		if lspci | grep -i raid | grep -i lsi 1>/dev/null 2>/dev/null
		then
			if [ -e $AVAGO ]
			then
				echo "LSI RAID card detected and Software installed"
			else
				echo -e "LSI RAID card detected but Software is Not installed\nWe reccomend installing the LSI RAID software so the RAID card can be checked"
			fi
		elif lspci | grep -i raid | grep -i adaptec 1>/dev/null 2>/dev/null
		then
			if [ -e $ADAPTEC ] | [ -e $ADAPTEC_EVENT ]
			then
				echo "Adaptec RAID card detected and Software installed"
			else
				echo -e "Adaptec RAID card detected but Software is Not installed\nWe recommend installing the Adaptec RAID software so the RAID card can be checked"
			fi
		else
			echo "No RAID card detected quitting"
		fi
	fi
}

function RAID01
{
	if [ -e $ADAPTEC ]
	then
		echo -e "\n$TextDIV\n\tAdaptec Logs Summary\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC getconfig 1 | grep -i "Logical devices/Failed/Degraded" >>./$FILENAME && $ADAPTEC getconfig 1 | grep -i "Overall Backup Unit Status" >>./$FILENAME && $ADAPTEC getconfig 1 | awk '/Logical device number/{nr[NR];nr[NR+1];nr[NR+2];nr[NR+3];nr[NR+5];nr[NR+15]}; NR in nr' >>./$FILENAME && $ADAPTEC getconfig 1 | awk '/Device #/{nr[NR];nr[NR+2];nr[NR+21]}; NR in nr' >>./$FILENAME
		echo -e "\n$TextDIV\n\tAdaptec Logs\n$TextDIV\n" >> ./$FILENAME
		echo -e "\n$TextDIV\n\tGet Status 1\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC getstatus 1 >> ./$FILENAME
		echo -e "\n$TextDIV\n\tGet Config 1\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC getconfig 1 >> ./$FILENAME
		echo -e "\n$TextDIV\n\tDevice Logs\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC getlogs 1 device tabular >> ./$FILENAME
		echo -e "\n$TextDIV\n\tDead Logs\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC getlogs 1 dead tabular >> ./$FILENAME
	elif [ -e $ADAPTEC_EVENT ]
	then
		echo -e "\n$TextDIV\n\tAdaptec Logs Summary\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC_EVENT getconfig 1 | grep -i "Logical devices/Failed/Degraded" >>./$FILENAME && $ADAPTEC_EVENT getconfig 1 | grep -i "Overall Backup Unit Status" >>./$FILENAME && $ADAPTEC_EVENT getconfig 1 | awk '/Device #/{nr[NR];nr[NR+1];nr[NR+2];nr[NR+21]}; NR in nr' >>./$FILENAME && $ADAPTEC_EVENT getconfig 1 | awk '/Logical device number/{nr[NR];nr[NR+1];nr[NR+3];nr[NR+5];nr[NR+15]}; NR in nr' >>./$FILENAME
		echo -e "\n$TextDIV\n\tAdaptec Logs\n$TextDIV\n" >> ./$FILENAME
		echo -e "\n$TextDIV\n\tGet Status 1\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC_EVENT getstatus 1 >> ./$FILENAME
		echo -e "\n$TextDIV\n\tGet Config 1\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC_EVENT getconfig 1 >> ./$FILENAME
		echo -e "\n$TextDIV\n\tDevice Logs\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC_EVENT getlogs 1 device tabular >> ./$FILENAME
		echo -e "\n$TextDIV\n\tDead Logs\n$TextDIV\n" >> ./$FILENAME
		$ADAPTEC_EVENT getlogs 1 dead tabular >> ./$FILENAME
	elif [ -e $AVAGO ]
	then
		echo -e "\n$TextDIV\n\tLSI Logs Summary\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
		$AVAGO /c0 show all | grep -i "Controller Status" >>./$FILENAME && $AVAGO -adpbbucmd -aAll | grep -i "Battery State" >>./$FILENAME && $AVAGO /c0/vall show all | awk '/TYPE  State/{nr[NR];nr[NR+1];nr[NR+2];nr[NR+3]}; NR in nr' >>./$FILENAME && $AVAGO /c0/eall/sall show all | awk '/EID:Slt/{nr[NR];nr[NR+1];nr[NR+2];nr[NR+3];nr[NR+20];nr[NR+21];nr[NR+23];nr[NR+24]}; NR in nr' >>./$FILENAME
		echo -e "\n$TextDIV\n\tLSI Logs\n$TextDIV\n" >> ./$FILENAME
		echo -e "\n$TextDIV\n   /c0/eall/sall show rebuild\n$TextDIV\n" >> ./$FILENAME
		$AVAGO /c0/eall/sall show rebuild >> ./$FILENAME
		echo -e "\n$TextDIV\n   /c0/eall/sall show copyback\n$TextDIV\n" >> ./$FILENAME
		$AVAGO /c0/eall/sall show copyback >> ./$FILENAME
		echo -e "\n$TextDIV\n\t/c0 show all\n$TextDIV\n" >> ./$FILENAME
		$AVAGO /c0 show all >> ./$FILENAME
		echo -e "\n$TextDIV\n   /c0/eall/sall show all\n$TextDIV\n" >> ./$FILENAME
		$AVAGO /c0/eall/sall show all >> ./$FILENAME
		echo -e "\n$TextDIV\n\t/c0/vall show all\n$TextDIV\n" >> ./$FILENAME
		$AVAGO /c0/vall show all >> ./$FILENAME
		echo -e "\n$TextDIV\n\tBBU Info\n$TextDIV\n" >> ./$FILENAME
		$AVAGO -adpbbucmd -aAll >> ./$FILENAME
	else
		echo "No RAID Utility found." >>./$FILENAME
	fi
}

function Vyatta01
{
	# Get current Vyatta version
	echo -e "\n$TextDIV\n\tshow version\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show version >> ./$FILENAME
	# show recent commit changes
	echo -e "\n$TextDIV\n   show system commit\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show system commit >> ./$FILENAME
	# show interfaces
	echo -e "\n$TextDIV\n\tshow interfaces\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show interfaces >> ./$FILENAME
	# show vrrp sync-group to determine whether master/backup
	echo -e "\n$TextDIV\n   show vrrp sync-group\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show vrrp sync-group >> ./$FILENAME
	# show config-sync status
	echo -e "\n$TextDIV\n   show config-sync status\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show config-sync status >> ./$FILENAME
	# Compare running Vyatta conf with underlying OS
	echo -e "\n$TextDIV\n\tshow ip route\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show ip route >> ./$FILENAME
	echo -e "\n$TextDIV\n\tip route show\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	sudo ip route show >> ./$FILENAME
	# IPSec Tunnels
	echo -e "\n$TextDIV\n\tshow vpn ike sa\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show vpn ike sa >> ./$FILENAME
	echo -e "\n$TextDIV\n    show vpn ipsec sa\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	$VYATTASH show vpn ipsec sa >> ./$FILENAME
	# Ping and MTR
	[ -z "$IP_OPT" ] && echo $NET_INSTRUCTIONS
	[ -z "$IP_OPT" ] && read DEST_IP
	[ -z "$IP_OPT" ] && echo "Starting MTR. Tests may take some time to complete, please stand by."
	echo -e "\n$TextDIV\n\t100 count mtr\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	echo -e "$TextDIV2\n\tICMP:\n$TextDIV2" >> ./$FILENAME
	/usr/bin/mtr -c 100 -r $DEST_IP >>./$FILENAME
	echo -e "$TextDIV2\n\tUDP:\n$TextDIV2" >> ./$FILENAME
	/usr/bin/mtr -u -c 100 -r $DEST_IP >>./$FILENAME
	echo -e "\n$TextDIV\n   show configuration commands\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
	cp ./$FILENAME ./$FILENAME_Raw
	$VYATTASH show configuration commands >> ./$FILENAME_Raw
	echo -e "$TextDIV2\n   show configuration commands\n\tfirewall\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set firewall' >> ./$FILENAME || $VYATTASH show configuration commands | grep -i 'set security firewall' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tinterfaces\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set interfaces' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tload-balancing\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set load-balancing' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tnat\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set nat' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tpolicy\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set policy' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tprotocols\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set protocols' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tresources\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set resources' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tservice\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set service' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tsystem\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set system' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\ttraffic-policy\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set traffic-policy' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tvpn\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set vpn' >> ./$FILENAME
	echo -e "$TextDIV2\n   show configuration commands\n\tzone-policy\n$TextDIV2" >> ./$FILENAME
	$VYATTASH show configuration commands | grep -i 'set zone-policy' >> ./$FILENAME
	#check for 10.0.0.0/8 route
	if  grep -q '10.0.0.0/8' <($VYATTASH show ip route)
	then
		echo "10.0.0.0/8 route is present"
	else
		echo "There is currently no route for 10.0.0.0/8, it is recomended that this route be present."
	fi
}

#Check to see if Script was run as Root
if [ "$(id -u)" != "0" ]; then
  echo "This script must be run as sudo or root, For Vyatta it is recommended to use: su -c \"bash bmi-diag.sh\" " 1>&2
   exit 1
fi

# Logic to determine OS type and patch level
## CentOS & RHEL
if [ -e /etc/redhat-release ]
then
	OS_TYPE=CENT
	OS_INFO=`cat /etc/redhat-release`
	if grep -1 'e 7.' /etc/redhat-release 1>/dev/null 2>/dev/null
	then
		OS_TYPE=CENT7
		OS_INFO=`cat /etc/redhat-release`
	fi
## Vyatta
elif [ -e "$VYATTASH" ]
then
	OS_TYPE=VYATTA
	OS_INFO=`$VYATTASH show version 2>/dev/null | grep -i Description | cut -f2- -d:`
## Ubuntu, Debian, & Quantastor
elif [ -e /etc/os-release ]
then
	if [ "ubuntu" = $(grep -i ID= /etc/os-release | head -n 1 | cut -d '=' -f 2) ]
	then
		OS_TYPE=UBUNTU
		OS_INFO=`cat /etc/ec2_version 2>/dev/null || qs 2>/dev/null | sed -n '2p' | grep -i PRETTY_NAME= /etc/os-release | head -n 1 | cut -d '=' -f 2`
	## Debian detection specifically for 7 (Wheezy) or greater
	elif [ "debian" = $(grep -i ID= /etc/os-release | grep debian | cut -d '=' -f 2) ]
	then
		OS_TYPE=DEBIAN7
		OS_INFO="Debian "
		OS_INFO+=`cat /etc/debian_version`
	fi
## Debian detection before version 7
elif [ "debian" = $(lsb_release -a 2>/dev/null | grep -i debian | head -n 1 | cut -d ':' -f 2 | xargs | tr '[:upper:]' '[:lower:]' ) ]
then
	OS_TYPE=DEBIAN
	OS_INFO="Debian "
	OS_INFO+=`cat /etc/debian_version`
fi

function C_SELECT
{
# Logic for input to perform actions
case $CUST_SELECTION in
	1)
		#For Best Results the following should be installed:
		## dig, ifconfig, netstat, ss, lsof, traceroute, ping, MTR
		[ -z "$CUST_OPT" ] && NetComChk
		FILENAME="netdiag_`date +"%Y-%m-%d-%H%M%S"`.log.txt"
		touch $FILENAME
		echo -e "\n$TextDIV\nHostname: `hostname -A`\nIPs: `hostname -I`\nOS: $OS_INFO\nNetwork Diag Log\n`date`\n$TextDIV\n$TextDIV\nUptime: `uptime`\n$TextDIV\n" >> ./$FILENAME
		if [ $OS_TYPE = "CENT" ]
		then
			NetDiag01
			Diag_Complete
		elif [ $OS_TYPE = "CENT7" ]
		then
			echo -e "\n$TextDIV\n\tip addr show\n`date '+%X %Z %z'`\n$TextDIV\n" >> ./$FILENAME
			command ip addr show 1>>./$FILENAME 2>/dev/null || { echo "ip not installed">>./$FILENAME;}
			NetDiag01
			Diag_Complete
		elif [ $OS_TYPE = "UBUNTU" ]
		then
			NetDiag01
			Diag_Complete
		elif [ $OS_TYPE = "DEBIAN7" ]
		then
			NetDiag01
			Diag_Complete
		elif [ $OS_TYPE = "DEBIAN" ]
		then
			NetDiag01
			Diag_Complete
		##added not compattable with Vyatta prompt
    		elif [ $OS_TYPE = "VYATTA" ]
    		then
      			printf "This selection does not currently support Vyatta. Quitting...\n"
      			exit
		else
			printf "Unable to determine OS. Quitting...\n"
		fi
		;;
	2)
		##For Best Results the following should be installed:
		## top, free, iostat, ps aux, 'ss -s', vmstat
		[ -z "$CUST_OPT" ] && SlowComChk
		FILENAME="slowdiag_`date +"%Y-%m-%d-%H%M%S"`.log.txt"
		touch $FILENAME
		echo -e "\n$TextDIV\nHostname: `hostname -A`\nIPs: `hostname -I`\nOS: $OS_INFO\nSlow System Diag Log\n`date`\n$TextDIV\n$TextDIV\nUptime: `uptime`\n$TextDIV\n" >> ./$FILENAME
		if [ $OS_TYPE = "CENT" ]
		then
			SlowDiag01
			Diag_Complete
		elif [ $OS_TYPE = "CENT7" ]
		then
			SlowDiag01
			Diag_Complete
		elif [ $OS_TYPE = "UBUNTU" ]
		then
			SlowDiag01
			Diag_Complete
		elif [ $OS_TYPE = "DEBIAN7" ]
		then
			SlowDiag01
			Diag_Complete
		elif [ $OS_TYPE = "DEBIAN" ]
		then
			SlowDiag01
			Diag_Complete
		##added not compattable with Vyatta prompt
    		elif [ $OS_TYPE = "VYATTA" ]
    		then
			printf "This selection does not currently support Vyatta. Quitting...\n"
      			exit
		else
			printf "Unable to determine OS. Quitting...\n"
		fi
		;;
	3)
		#Checks for RAID issues
		[ -z "$CUST_OPT" ] && RAIDComChk
		FILENAME="RAIDdiag_`date +"%Y-%m-%d-%H%M%S"`.log.txt"
		touch $FILENAME
		if [ $OS_TYPE = "VYATTA" ]
		then
			TEMP0="`hostname`.`hostname -d`"
		else
			TEMP0=`hostname -A`
		fi
		echo -e "\n$TextDIV\nHostname: $TEMP0\nIPs: `hostname -I`\nOS: $OS_INFO\nRAID Diag Log\n`date`\n$TextDIV\n$TextDIV\nUptime: `uptime`\n$TextDIV\n" >> ./$FILENAME
		if [ -e $ADAPTEC ] || [ -e $ADAPTEC_EVENT ] || [ -e $AVAGO ]
		then
			RAID01
			Diag_Complete
		else
			printf "No RAID Utility found. Quitting...\n"
		fi
		;;
	4)
		# Vyatta doesn't like shell scripting
		# Unsupported and undocumented private API
		# Requires using the Vyatta shell wrapper command
		# /opt/vyatta/bin/vyatta-op-cmd-wrapper
		# https://help.ubnt.com/hc/en-us/articles/204976164-EdgeMAX-How-to-run-operational-mode-command-from-scripts-
		FILENAME_Raw="vyattadiag_raw_`date +"%Y-%m-%d-%H%M%S"`.log.txt"
		FILENAME="vyattadiag_formatted_`date +"%Y-%m-%d-%H%M%S"`.log.txt"
		touch $FILENAME_Raw
		touch $FILENAME
		TEMP0="`hostname`.`hostname -d`"
		echo -e "\n$TextDIV\nHostname: $TEMP0\nIPs: `hostname -I`\nOS: $OS_INFO\nBrocade vRouter Diag Log\n`date`\n$TextDIV\n$TextDIV\nUptime: `uptime`\n$TextDIV\n" >> ./$FILENAME
		if [ ! -e "$VYATTASH" ]
		then
			printf "Not a Vyatta or unable to run Vyatta shell commands. Quitting...\n"
		else
			Vyatta01
			echo -e "Diag Complete.\nPlease attach $FILENAME and $FILENAME_Raw to your ticket"
		fi
		;;
	5)
		printf "Quiting...\n"
		;;
	*)
		printf "Invalid Entry. Quiting...\n"
esac
}


#check to see if script was run with arguments  passed
if [ -z "$CUST_OPT" ]; then
	# Logic to print pretty TITLE and INSTRUCTIONS
	for (( c=1; c<=$TITLE_WIDTH; c++ ))
	do
		printf "*"
	done
	printf "$TITLE"
	for (( c=1; c<$TITLE_WIDTH; c++ ))
	do
		printf "*"
	done
	printf "\n"
	echo $INSTRUCTIONS | fold -s -w $COL_WIDTH
	printf "\n"
	printf "1. Network Diagnostics (Trouble connecting to other devices) [Not Compatible with Vyatta]\n"
	printf "2. Slow System (Trouble with current device) [Not Compatible with Vyatta]\n"
	printf "3. RAID Diagnostics (Avago/LSI or Adaptec)\n"
	printf "4. Vyatta Diagnostics (Vyatta devices only)\n"
	printf "5. Exit\n"
	printf "\nInput: "
	read CUST_SELECTION
	C_SELECT
else
	C_SELECT
fi

exit 0
