#!/bin/bash

# qdiscs 
tc qdisc del dev eth0 root

# All local traffic goes
tc qdisc add dev eth0 root handle 1: cbq bandwidth 100Mbit cell 8 avpkt 1000 mpu 64 allot 1514


iptables -F
iptables -t nat -F
iptables -t mangle -F

# classes

# DOWNLOAD TRAFFIC. There are rules in place for most known heavy users. So this queue is mostly
# servers. It also contains the second wifi network 192.168.2.0/24.

tc class add dev eth0 parent 1: classid 1:1 cbq rate 13mbit allot 1500 prio 0 bounded sharing
tc filter add dev eth0 parent 1:0 protocol ip prio 0 handle 1 fw classid 1:1

# UPLOAD TRAFFIC sets a max upload on all traffic sent out the wire.

tc class add dev eth0 parent 1: classid 1:2 cbq rate 800Kbit allot 1500 prio 8 borrow isolated
tc filter add dev eth0 parent 1:0 protocol ip prio 8 handle 2 fw classid 1:2

# TRAFFIC to Evie

#tc class add dev eth0 parent 1: classid 1:3 cbq rate 4Mbit allot 1500 prio 3 bounded sharing

tc class add dev eth0 parent 1: classid 1:3 cbq rate 6Mbit bandwidth 100Mbit \
	maxburst 20 avpkt 1000 allot 1500 prio 3 bounded sharing

tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 3 fw classid 1:3

# TRAFFIC to Isac
tc class add dev eth0 parent 1: classid 1:4 cbq rate 6Mbit bandwidth 100Mbit \
	maxburst 20 avpkt 1000 allot 1500 prio 3 bounded sharing

tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 4 fw classid 1:4

# TRAFFIC to Eliza
#tc class add dev eth0 parent 1: classid 1:5 cbq rate 3Mbit allot 1500 prio 3 bounded sharing

tc class add dev eth0 parent 1: classid 1:5 cbq rate 6Mbit bandwidth 100Mbit \
	maxburst 20 avpkt 1000 allot 1500 prio 3 bounded sharing

tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 5 fw classid 1:5

# TRAFFIC to Sarah
#tc class add dev eth0 parent 1: classid 1:6 cbq rate 4Mbit allot 1500 prio 1 bounded sharing

tc class add dev eth0 parent 1: classid 1:6 cbq rate 13Mbit bandwidth 100Mbit \
	maxburst 20 avpkt 1000 allot 1500 prio 1 bounded sharing

tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 6 fw classid 1:6

# TRAFFIC to Kiel
tc class add dev eth0 parent 1: classid 1:7 cbq rate 13Mbit bandwidth 100Mbit \
	maxburst 20 avpkt 1000 allot 1500 prio 1 borrow isolated

tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 7 fw classid 1:7

# TRAFFIC to streaming devices
tc class add dev eth0 parent 1: classid 1:8 cbq rate 6Mbit allot 1500 prio 6 bounded sharing
tc filter add dev eth0 parent 1:0 protocol ip prio 2 handle 8 fw classid 1:8

# TRAFFIC to DHCP assigned devices
tc class add dev eth0 parent 1: classid 1:9 cbq rate 4Mbit allot 1500 prio 3 bounded sharing
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 9 fw classid 1:9

# IPTABLES

# NAT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o eth0 -j MASQUERADE

# forward all httpd traffic to www
iptables -t nat -A PREROUTING -p tcp -d 192.168.1.10 --dport 80 -j \
	DNAT --to-destination 10.0.0.4:80

# MANGLE

# if its LAN traffic do nothing 
iptables -t mangle -A POSTROUTING -d 192.168.1.10 -s 10.0.0.0/24 -j RETURN
iptables -t mangle -A POSTROUTING -d 192.168.1.10 -s 192.168.1.0/24 -j RETURN
iptables -t mangle -A POSTROUTING -d 192.168.1.10 -s 192.168.2.0/24 -j RETURN

# INTERNET TRAFFIC DOWNLOADS

# when the src addr is not one of out local networks and the dst prerouting is 
# the gateway then its internet downloads

# Media streaming devices ratelimits

# LOUNGE ROOM APPLE TV
iptables -t mangle -A POSTROUTING -d 192.168.1.30 -j MARK --set-mark 0x8
iptables -t mangle -A POSTROUTING -d 192.168.1.30 -j RETURN

# BEDROOM APPLE TV
iptables -t mangle -A POSTROUTING -d 192.168.1.31 -j MARK --set-mark 0x8
iptables -t mangle -A POSTROUTING -d 192.168.1.31 -j RETURN

# LOUNGE ROOM LAPTOP
iptables -t mangle -A POSTROUTING -d 192.168.1.32 -j MARK --set-mark 0x8
iptables -t mangle -A POSTROUTING -d 192.168.1.32 -j RETURN


# User ratelimits to control internet sharing.

# ALL TRAFFIC TO EVIE
iptables -t mangle -A POSTROUTING -d 192.168.1.20 -j MARK --set-mark 0x3
iptables -t mangle -A POSTROUTING -d 192.168.1.20 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.1.21 -j MARK --set-mark 0x3
iptables -t mangle -A POSTROUTING -d 192.168.1.21 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.1.22 -j MARK --set-mark 0x3
iptables -t mangle -A POSTROUTING -d 192.168.1.22 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.1.23 -j MARK --set-mark 0x3
iptables -t mangle -A POSTROUTING -d 192.168.1.23 -j RETURN

# ALL TRAFFIC TO ISAC
# laptop
iptables -t mangle -A POSTROUTING -d 192.168.1.7 -j MARK --set-mark 41
iptables -t mangle -A POSTROUTING -d 192.168.1.7 -j RETURN
# play station
iptables -t mangle -A POSTROUTING -d 192.168.1.8 -j MARK --set-mark 40
iptables -t mangle -A POSTROUTING -d 192.168.1.8 -j RETURN
# old phone
iptables -t mangle -A POSTROUTING -d 192.168.1.9 -j MARK --set-mark 43
iptables -t mangle -A POSTROUTING -d 192.168.1.9 -j RETURN
# ipad
iptables -t mangle -A POSTROUTING -d 192.168.1.12 -j MARK --set-mark 43
iptables -t mangle -A POSTROUTING -d 192.168.1.12 -j RETURN
#  phone
iptables -t mangle -A POSTROUTING -d 192.168.1.13 -j MARK --set-mark 42
iptables -t mangle -A POSTROUTING -d 192.168.1.13 -j RETURN

# ALL TRAFFIC TO ELIZA
iptables -t mangle -A POSTROUTING -d 192.168.1.40 -j MARK --set-mark 0x5
iptables -t mangle -A POSTROUTING -d 192.168.1.40 -j RETURN

# ALL TRAFFIC TO SARAH
iptables -t mangle -A POSTROUTING -d 192.168.1.50 -j MARK --set-mark 0x6
iptables -t mangle -A POSTROUTING -d 192.168.1.50 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.1.51 -j MARK --set-mark 0x6
iptables -t mangle -A POSTROUTING -d 192.168.1.51 -j RETURN

# ALL TRAFFIC TO KIEL

iptables -t mangle -A POSTROUTING -d 192.168.1.5 -j MARK --set-mark 0x7
iptables -t mangle -A POSTROUTING -d 192.168.1.5 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.1.6 -j MARK --set-mark 0x7
iptables -t mangle -A POSTROUTING -d 192.168.1.6 -j RETURN

# ALL DYNAMIC HOST
iptables -t mangle -A POSTROUTING -d 192.168.1.0/24 -j MARK --set-mark 0x9
iptables -t mangle -A POSTROUTING -d 192.168.1.0/24 -j RETURN

# Rest of the traffic from the internet. Host on 10.0.0.0/24 and 192.168.2.0/24 hit this
# queue.

iptables -t mangle -A PREROUTING ! -s 10.0.0.0/24 -d 192.168.1.10 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING ! -s 10.0.0.0/24 -d 192.168.1.10 -j RETURN

iptables -t mangle -A PREROUTING ! -s 192.168.1.0/24 -d 192.168.1.10 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING ! -s 192.168.1.0/24 -d 192.168.1.10 -j RETURN

iptables -t mangle -A PREROUTING ! -s 192.168.2.0/24 -d 192.168.1.10 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING ! -s 192.168.2.0/24 -d 192.168.1.10 -j RETURN


# INTERNET TRAFFIC UPLOADS

# When the src address is the gateway and the dst addr is not one of our networks
#  then its an internet upload

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 10.0.0.0/24 -j MARK --set-mark 0x2
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 10.0.0.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.1.0/24 -j MARK --set-mark 0x2
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.1.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.2.0/24 -j MARK --set-mark 0x2
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.2.0/24 -j RETURN
