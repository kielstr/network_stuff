#!/bin/bash

#          +------------+                +---------+               +-------------+
#  Packet -| PREROUTING |--- routing-----| FORWARD |-------+-------| POSTROUTING |- Packets
#  input   +------------+    decision    +---------+       |       +-------------+    out
#                               |                          |
#                          +-------+                    +--------+   
#                          | INPUT |---- Local process -| OUTPUT |
#                          +-------+                    +--------+

# Some docs on tc http://lartc.org/howto/lartc.qdisc.classful.html

# Devices to control

UPLOAD_BANDWITH=".7mbit"

LAN_DEVICE="eth0";
LAN_SUBNET="192.168.1.0/24";
LAN_TOTAL_BANDWITH="100mbit";

WIFI_DEVICE="wlan0";
WIFI_SUBNET="192.168.2.0/24";
WIFI_TOTAL_BANDWITH="50mbit";

ROUTER_ADDRESS="192.168.1.10";

DEFAULT_CLASS="1:1";

WIFI_LIMIT_ON_LAN="1mbit";

MEDIA_LIMIT="50mbit";
MEDIA_CLASS_ID="1:4";
declare -a MEDIA_ADDRESS=(
	"192.168.1.30" #
	"192.168.1.31" # 
	"192.168.1.32" # ubuntu-laptop
	"192.168.2.30"
	"192.168.2.31"
	"192.168.2.32"
);

ELIZA_LIMIT="2mbit";
ELIZA_CLASS_ID="1:5";
declare -a ELIZA_ADDRESS=(
	"192.168.1.40"
	"192.168.2.40"
);

SSH_BANDWITH="20mbit";

ISAC_LIMIT="2mbit";
ISAC_CLASS_ID="1:2";
declare -a ISAC_ADDRESS=(
	"192.168.1.7" 
	"192.168.1.8" 
	"192.168.1.9"
	"192.168.1.12"
	"192.168.1.13"
	"192.168.2.7" 
	"192.168.2.8" 
	"192.168.2.9"
	"192.168.2.12"
	"192.168.2.13"
);

EVIE_LIMIT="2mbit";
EVIE_CLASS_ID="1:3";
declare -a EVIE_ADDRESS=(
	"192.168.1.20" 
	"192.168.1.21" 
	"192.168.1.22"
	"192.168.1.23"
);

SARAH_LIMIT="5mbit";
SARAH_CLASS_ID="1:6";
declare -a SARAH_ADDRESS=(
	"192.168.1.50" 
	"192.168.2.50" 
);

KIEL_LIMIT="10mbit";
KIEL_CLASS_ID="1:9";
declare -a KIEL_ADDRESS=(
	"192.168.1.5" 
	"192.168.1.6" 
	"192.168.2.5" 
	"192.168.2.6" 
);

# Clear out NAT and Mangle rules
iptables -t raw -F
iptables -t nat -F 
iptables -t mangle -F 

# Allow trafic from wlan0 to be NAT's on eth0
iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#iptables -t nat -A POSTROUTING -s $WIFI_SUBNET -o $LAN_DEVICE -j SNAT --to-source $ROUTER_ADDRESS
#iptables -t nat -A POSTROUTING -s eth0:0 -o eth0 -j SNAT --to-source $ROUTER_ADDRESS

# Clear any defiend rules
tc qdisc del dev $LAN_DEVICE root
tc qdisc del dev $WIFI_DEVICE root

# Main Classes
# LAN
tc qdisc add dev $LAN_DEVICE root handle 1: cbq avpkt 1000 bandwidth $LAN_TOTAL_BANDWITH
# WiFi 
tc qdisc add dev $WIFI_DEVICE root handle 1: cbq avpkt 1000 bandwidth $WIFI_TOTAL_BANDWITH

# Undefined traffic goes here
tc class add dev $LAN_DEVICE parent 1: classid 1:1 cbq rate $LAN_TOTAL_BANDWITH allot 1500 prio 0 bounded isolated 

# Classes for Isac
# 	LAN
tc class add dev $LAN_DEVICE parent 1: classid $ISAC_CLASS_ID cbq rate $ISAC_LIMIT allot 1500 prio 4 bounded isolated 
# 	WiFi
tc class add dev $WIFI_DEVICE parent 1: classid $ISAC_CLASS_ID cbq rate $ISAC_LIMIT allot 1500 prio 4 bounded isolated 

# Classes for Evie
# 	LAN
tc class add dev $LAN_DEVICE parent 1: classid $EVIE_CLASS_ID cbq rate $EVIE_LIMIT allot 1500 prio 8 bounded isolated 
# 	WiF
tc class add dev $WIFI_DEVICE parent 1: classid $EVIE_CLASS_ID cbq rate $EVIE_LIMIT allot 1500 prio 8 bounded isolated 

# Classes for Eliza
# 	LAN
tc class add dev $LAN_DEVICE parent 1: classid $ELIZA_CLASS_ID cbq rate $ELIZA_LIMIT allot 1500 prio 4 bounded isolated
# 	WiFi
tc class add dev $WIFI_DEVICE parent 1: classid $ELIZA_CLASS_ID cbq rate $ELIZA_LIMIT allot 1500 prio 2 bounded isolated

# Media 
#	LAN
tc class add dev $LAN_DEVICE parent 1: classid $MEDIA_CLASS_ID cbq rate $MEDIA_LIMIT allot 1500 prio 1 bounded isolated 
#	Wifi
tc class add dev $WIFI_DEVICE parent 1: classid $MEDIA_CLASS_ID cbq rate $MEDIA_LIMIT allot 1500 prio 1 bounded isolated 

# Classes for Sarah
#	LAN
tc class add dev $LAN_DEVICE parent 1: classid $SARAH_CLASS_ID cbq rate $ELIZA_LIMIT allot 1500 prio 2 bounded isolated
#	WiFi
tc class add dev $WIFI_DEVICE parent 1: classid $SARAH_CLASS_ID cbq rate $ELIZA_LIMIT allot 1500 prio 2 bounded isolated

# Classes for Kiel
#	LAN
tc class add dev $LAN_DEVICE parent 1: classid $KIEL_CLASS_ID cbq rate $KIEL_LIMIT allot 1500 prio 0 bounded isolated
#	WiFi
tc class add dev $WIFI_DEVICE parent 1: classid $KIEL_CLASS_ID cbq rate $KIEL_LIMIT allot 1500 prio 0 bounded isolated

# Class for Wifi traffic on LAN
tc class add dev $LAN_DEVICE parent 1: classid 1:7 cbq rate $WIFI_LIMIT_ON_LAN allot 1500 prio 3 bounded isolated 

# Class for SSH
tc class add dev $LAN_DEVICE parent 1: classid 1:8 cbq rate $SSH_BANDWITH allot 1500 prio 1 bounded isolated 

# Class for Internet uploads
tc class add dev $LAN_DEVICE parent 1: classid 1:10 cbq rate $UPLOAD_BANDWITH allot 1500 prio 1 bounded isolated 

# Filters to handle iptable marked packets

# WiFi network
tc filter add dev $LAN_DEVICE parent 1:0 protocol ip prio 1 handle 3 fw classid 1:7

# SSH
tc filter add dev $LAN_DEVICE parent 1:0 protocol ip prio 0 handle 2 fw classid 1:8

# uploads
tc filter add dev $LAN_DEVICE parent 1:0 protocol ip prio 0 handle 1 fw classid 1:10


# useful cmds 
# watch tc -s class show dev eth0
# iptables -nL -v --line-numbers -t mangle
# iptables -I OUTPUT -p tcp -m tcp --dport 22 -m state --state NEW,ESTABLISHED -j LOG --log-prefix "Outgoing SSH connection"
# while :; do iptables -L OUTPUT -v -n --line-n; sleep 2; done
# Debug 
#	iptables -t raw -A PREROUTING ! -d $LAN_SUBNET -j TRACE

# Traffic from wlan0 goes to queue 7
iptables -t mangle -A PREROUTING -p tcp -m tcp -s $WIFI_SUBNET -j MARK --set-mark 0x3
iptables -t mangle -A PREROUTING -p tcp -m tcp -s $WIFI_SUBNET -j RETURN

# Mark SSH packets to go to queue 8
#iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 22 -j MARK --set-mark 0x2
#iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 22 -j RETURN

# Mark all WAN uploads with 1 to route it into class 1:10
iptables -t mangle -A PREROUTING ! -d $LAN_SUBNET -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING ! -d $LAN_SUBNET -j RETURN

for addr in "${ISAC_ADDRESS[@]}"
do
	case $(echo $addr | awk -F. '{print $3}') in 
		1 )
			echo "rate limiting Isac on ip $addr device $LAN_DEVICE to $ISAC_LIMIT class id $ISAC_CLASS_ID";
   			tc filter add dev $LAN_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $ISAC_CLASS_ID
   			;;

   		2)
			echo "rate limiting Isac on ip $addr device $WIFI_DEVICE to $ISAC_LIMIT class id $ISAC_CLASS_ID";
   			tc filter add dev $WIFI_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $ISAC_CLASS_ID
			;;
	esac
done

for addr in "${EVIE_ADDRESS[@]}"
do
	case $(echo $addr | awk -F. '{print $3}') in 
		1 )
			echo "rate limiting Evie on ip $addr device $LAN_DEVICE to $EVIE_LIMIT class id $EVIE_CLASS_ID";
   			tc filter add dev $LAN_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $EVIE_CLASS_ID
   			;;

   		2)
			echo "rate limiting Evie on ip $addr device $WIFI_DEVICE to $EVIE_LIMIT class id $EVIE_CLASS_ID";
   			tc filter add dev $WIFI_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $EVIE_CLASS_ID
			;;
	esac
done

for addr in "${MEDIA_ADDRESS[@]}"
do
	case $(echo $addr | awk -F. '{print $3}') in 
		1 )
			echo "rate limiting media on ip $addr device $LAN_DEVICE to $MEDIA_LIMIT class id $MEDIA_CLASS_ID";
   			tc filter add dev $LAN_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $MEDIA_CLASS_ID
   			;;

   		2)
			echo "rate limiting media on ip $addr device $WIFI_DEVICE to $MEDIA_LIMIT class id $MEDIA_CLASS_ID";
   			tc filter add dev $WIFI_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $MEDIA_CLASS_ID
			;;
	esac
done

for addr in "${ELIZA_ADDRESS[@]}"
do
	case $(echo $addr | awk -F. '{print $3}') in 
		1 )
			echo "rate limiting Eliza on ip $addr device $LAN_DEVICE to $ELIZA_LIMIT class id $ELIZA_CLASS_ID";
   			tc filter add dev $LAN_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $ELIZA_CLASS_ID
   			;;

   		2)
			echo "rate limiting Eliza on ip $addr device $WIFI_DEVICE to $ELIZA_LIMIT class id $ELIZA_CLASS_ID";
   			tc filter add dev $WIFI_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $ELIZA_CLASS_ID
			;;
	esac
done

for addr in "${SARAH_ADDRESS[@]}"
do
	case $(echo $addr | awk -F. '{print $3}') in 
		1 )
			echo "rate limiting Sarah on ip $addr device $LAN_DEVICE to $SARAH_LIMIT class id $SARAH_CLASS_ID";
   			tc filter add dev $LAN_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $SARAH_CLASS_ID
   			;;

   		2)
			echo "rate limiting Sarah on ip $addr device $WIFI_DEVICE to $SARAH_LIMIT class id $SARAH_CLASS_ID";
   			tc filter add dev $WIFI_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $SARAH_CLASS_ID
			;;
	esac
done

for addr in "${KIEL_ADDRESS[@]}"
do
	case $(echo $addr | awk -F. '{print $3}') in 
		1 )
			echo "rate limiting Kiel on ip $addr device $LAN_DEVICE to $KIEL_LIMIT class id $KIEL_CLASS_ID";
   			tc filter add dev $LAN_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $KIEL_CLASS_ID
   			;;

   		2)
			echo "rate limiting Kiel on ip $addr device $WIFI_DEVICE to $KIEL_LIMIT class id $KIEL_CLASS_ID";
   			tc filter add dev $WIFI_DEVICE parent 1: protocol ip prio 2 u32 match ip dst $addr flowid $KIEL_CLASS_ID
			;;
	esac
done

# Kiels mac testing

#tc filter add dev $LAN_DEVICE parent 1:0 protocol ip prio 0 handle 4 fw classid 1:9

#iptables -t mangle -A PREROUTING -d 192.168.1.6 -j MARK --set-mark 0x4

# Everything else
tc filter add dev $LAN_DEVICE parent 1: protocol ip prio 0 u32 match ip dst $LAN_SUBNET flowid $DEFAULT_CLASS
