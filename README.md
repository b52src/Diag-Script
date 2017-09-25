# Diagnostic Script  
Created by: Sean Crow  

This is a diagnostics script to help gather pertinent information for common issues. Use of this script will be your sole responsibility and implies that you accept any risk and/or liability associated with executing this on your device. If you should come across an issue or would like to submit a feature request for it, please submit an issue: [https://github.com/b52src/Diag-Script/issues](https://github.com/b52src/Diag-Script/issues).

This script will pull general and common information for troubleshooting common issues. The goal of this script is to assist in providing pertinent information for the most common types of issues that are seen and reduce time of gathering that pertinent information. Additional information may be required to fully diagnose your issue, and this script is not a substitute for your troubleshooting.

## **Tested Operating Systems:**
This is a standard bash script and should work on most Linux based operating systems, but has been tested on the following:

- Vyatta 5400 6.7R10+
- vRouter 5600 5.2R2+
- Ubuntu 14.04+
- Cent 6+
- Red Hat 6+
- Debian 7+
- CloudLinux 6+
- Quantastor 4+

## **To download the current script:**  
Download the diag-script.sh file from [here](https://github.com/b52src/Diag-Script) to your desktop.  
Then either use [SCP](https://linux.die.net/man/1/scp) to copy the file over to the desired server or create a new file on the server and copy and paste the plain text from the file downloaded.

Or You can grab it with: `curl -O https://raw.githubusercontent.com/b52src/Diag-Script/master/bmi-diag.sh`

## Running The Script:
**To run the script with a standard Linux OS, you should use the following command (It should be run as root or sudo for all commands to work correctly):**  
`bash diag-script.sh`  
**To run the script with Vyatta:**   
`su -c "bash diag-script.sh"`  

**To run without requiring interaction(example of use would be to trigger if monitoring detects an incident)**  
`bash diag-script.sh -option $argument -option $argument`  
If you use this it is recommended that you have all of the programs listed under the "Current Diag Options:" section in this readme for best results, as running with parameters skips the program check.  
Available options: -o; -i  
-o is the Diag option, the argument following the option should be one of the below:  
1 - Network Diag (Not available on Vyatta, use Vyatta Diag)  
2 - Slow Diag (Not available on Vyatta)  
3 - Raid Diag  
4 - Vyatta Diag (Only works on Vyatta)  
-i is the destination IP for network and vyatta diags option(Only needed on Network or Vyatta diags, if you do not pass the IP it will stop and ask for it), argument to follow should be the IP.  
Example: `bash diag-script.sh -o 1 -i 8.8.8.8`  `bash diag-script.sh -o 2`   
Vyatta Example: `su -c "bash diag-script.sh -o 4 -i 8.8.8.8"`  

**To run the script remotely and cat to local console you may use the below commands:**  
`ssh root@10.0.0.0 "bash -i" <  ./diag-script.sh`  
`ssh root@10.0.0.0 cat vyattadiag_raw_2017-04-25-133635.log.txt`  

**Current Diag Options:**

1. Network Diagnostic Commands Used:
	1. [dig](https://linux.die.net/man/1/dig)  
	2. [ifconfig](https://linux.die.net/man/8/ifconfig)  
	3. [netstat](https://linux.die.net/man/8/netstat) -s  
	4. [ss](https://linux.die.net/man/8/ss) -s  
	5. [lsof](https://linux.die.net/man/8/lsof) -i  
	6. [traceroute](https://linux.die.net/man/8/traceroute)  
	7. [ping](https://linux.die.net/man/8/ping) –c 100 -q  
	8. [mtr](https://linux.die.net/man/8/mtr) –c 100 –r  
2. Slow Diag
	1. nice [top](https://linux.die.net/man/1/top) –n1 –b
	2. [free](https://linux.die.net/man/1/free) –m
	3. [ps](https://linux.die.net/man/1/ps) aux
	4. [ss](https://linux.die.net/man/8/ss) -s
	5. [iostat](https://linux.die.net/man/1/iostat)
	6. [vmstat](https://linux.die.net/man/8/vmstat)
	7. RAID card info
3. RAID info (Works with LSI cards and Adaptech)
	1. Pulls RAID card info if installed
		1. Adaptech Event Monitor
		2. LSI storcli
4. Vyatta/vRouter info
	1. Show version
	2. Show system commit
	3. Show interfaces
	4. Show vrrp sync-group
	5. Show config-sync status
	6. Show ip route
	7. ip route show
	8. show vpn ike sa
	9. show vpn ipsec sa
	10. [ping](https://linux.die.net/man/8/ping) –c 100 -q
	11. [mtr](https://linux.die.net/man/8/mtr) –c 100 –r
	12. show configuration commands

## Contributing
Contributing to this project is welcome and encouraged - See the [CONTRIBUTING.md](CONTRIBUTING.md) file for details 

## Credits
Thanks to those who have contributed to this project - see the [CREDIT](CREDIT) file for details

## License
This project is licensed under the MIT license - see the [LICENSE.md](LICENSE.md) file for details
