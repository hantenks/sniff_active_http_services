#!/bin/bash
#Usage :: default parameters are given below; else input 3 parameters network_id = X.X.X ; host_id_start = first pc ip id(last 8bits-in binary). 
#Example :: How to run -> ./han_proxy.sh 172.16.83 190 205
#Example :: How to run -> ./han_proxy.sh 172.16.83 190 190 d   //for debugging i.e prints my_message; by default no debugging message is printed
network_id="172.16.114";
host_id_start="1";
host_id_end="254";
my_debug="n";
if [ "$#" -ge 1 ]
then
	network_id=$1;
	if [ "$#" -ge 2 ]
	then
		host_id_start=$2;
		if [ "$#" -ge 3 ]
		then
			host_id_end=$3;
			if [ "$#" -ge 4 ]
			then
				my_debug=$4;
			fi
		fi
	fi
fi
now=$(date);
echo -e "$now\nChecking $network_id.$host_id_start to $network_id.$host_id_end">>Auth_problem.txt;
echo -e "$now\nChecking $network_id.$host_id_start to $network_id.$host_id_end">>Successful_proxies.txt;

#wanting to use .. nmap  -T5 --max-parallelism 30 -p1-65535 -n 172.16.114.205-250

#Variant 1
#for ((i=host_id_start;i<=host_id_end;i++)); do                    //should also work fine. Note no "$" and "(())", double brackets here treat it as an arithmetic expression.

#Variant 2      Good for unknown lab host networks, when you need to scan a lot. It filters before hand by checking pingable hosts
#eg. what it does is :: nmap  -n -sP 172.16.116.0/24 | grep report | awk '{print $5}'
host_id_list=$(nmap  -n -sP $network_id.$host_id_start-$host_id_end | grep report | awk '{print $5}' | cut -d '.' -f4)
for ip in $host_id_list; do

#Variant 3;		Good When you are sure which lab has high probability
#for ip in $(seq $host_id_start $host_id_end); do
	#if [[ "$network_id.$ip" == $(nmap  -n -sP $network_id.$ip | grep report | awk '{print $5}') ]]   //of you want to check if host is actually up proceed else don't.. maybe faster. I haven't checked
	echo "hantenks-scan started on target machine $network_id.$ip ::";

	#Variant 1
	#port_list=$(sudo nmap -sS -n --host-timeout 15s -p 1-65535 $network_id.$ip | grep open | cut -d '/' -f1)  #if firewalled it takes ove minutes. Avg is like 13 I guess
	# or simply don't use sudo..(remove -sS too then); special case 114.113 pingable but firewalled so takes 5 min or so

	#use either
	#Variant 2
	port_list=$(nmap -n -p 1-65535 $network_id.$ip | grep open | cut -d '/' -f1)

	#Variant 3
	#Adding host timeout is advised
	#port_list=$(sudo nmap -sS -n -p 1-65535 $network_id.$ip | grep open | cut -d '/' -f1)

	#Variant 4;
	#sudo by default does a stealth scan; don't use sudo if you don't want to bypass basic firewall even; example 172.16.114.113
	#port_list=$(sudo nmap -sS -Pn -n -p 1-65535 $network_id.$ip | grep open | cut -d '/' -f1)
	#use -Pn to get hosts who have firewalls to drop ping requests
	#use -r to scan sequentially; not random(by default ports are randomly scanned)
	for my_port in $port_list; do
		echo -e "\tTesting :: $network_id.$ip:$my_port"
		echo -en "\t";
		http_proxy=http://$network_id.$ip:$my_port/ 
		my_message=$(curl -4 -s -m 2 http://www.google.com)
		if [[ $my_debug == "d" ]]
		then
			echo $my_message;
			echo -en "\t";
		fi
		# -s is to silent error logs, -m is to specify 2 secs as max timeout, note :: ssh port 22 is generated as well;
		#	once, my_message <- cvs [pserver aborted]: bad auth protocol start .. contributes to "bad" ; Although this should be in the success check if then anded with href gogle tag as 	[[ $my_message != *"bad"* ]]
		#if [[ $my_message == *"ERR_ACCESS_DENIED"* ]]
		#if [[ $my_message == *"ERR_ACCESS_DENIED"* ]] || [[ $my_message == *"ERR_CACHE_ACCESS_DENIED"* ]]
		if [[ $my_message == *"ERR"* ]] || [[ $my_message == *"bad"* ]]
		#Keep searching for more tags here
		then
		  #It is a valid http_proxy but error is due to either ACL non-membership or passwd is needed
		  echo "Output  :: Authentication Problem";
		  echo "$network_id.$ip:$my_port">>Auth_problem.txt;
		#elif [[ $my_message == *"google"* ]]
		elif [[ $my_message == *"<A HREF=\"http://www.google.co"* ]]
		#this is by far one of the unique tags. When Apache httpd at 114.80 was running "google" was a output	
		then
		  echo "Output :: SUCCESS (No Auth needed)";
		  echo "$network_id.$ip:$my_port">>Successful_proxies.txt;
		else
		  echo "Output :: Not HTTP Proxy";
		fi
		echo -en "\n";
	done
	echo -e "\n";
done
echo -e "\n\n">>Auth_problem.txt;
echo -e "\n\n">>Successful_proxies.txt;
