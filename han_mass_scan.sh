#!/bin/bash
now=$(date);
echo -e "$now\n">>Auth_problem.txt;
echo -e "$now\n">>Successful_proxies.txt;
for ip in {1..15}; do
	echo "hantenks-scan started on target machine 172.16.114.${ip} ::";
	#echo -e "\n";
	port_list=$(sudo nmap -sS -n -p 1-65535 172.16.114.$ip | grep open | cut -d '/' -f1)
	for my_port in $port_list; do
		echo -e "\tTesting :: 172.16.114.$ip:$my_port"
		echo -en "\t";
		http_proxy=http://172.16.114.$ip:$my_port/ 
		my_message=$(curl -4 -s -m 2 http://nyc2.mirrors.digitalocean.com/tools/open_proxy_check.txt | grep "digitalocean")
		if [[ $my_message == *"ERR_ACCESS_DENIED"* ]]
		then
		  echo "Output :: Authentication Problem";
		  echo "172.16.114.$ip:$my_port">>Auth_problem.txt;
		elif [[ $my_message == *"digitalocean"* ]]
		then
		  echo "Output :: Success (No Auth needed)";
		  echo "172.16.114.$ip:$my_port">>Successful_proxies.txt;
		else
		  echo "Output :: Not HTTP Proxy";
		fi
		echo -e "\n";
	done
	echo -e "\n";
done
echo -e "\n\n">>Auth_problem.txt;
echo -e "\n\n">>Successful_proxies.txt;
