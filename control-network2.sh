#!/bin/bash

#          +------------+                +---------+               +-------------+
#  Packet -| PREROUTING |--- routing-----| FORWARD |-------+-------| POSTROUTING |- Packets <-- dest 192.168.1.10
#  input   +------------+    decision    +---------+       |       +-------------+    out
#                               |                          |
#                          +-------+                    +--------+   
#                          | INPUT |---- Local process -| OUTPUT |
#                          +-------+                    +--------+

# TC 

# qdiscs 
tc qdisc del dev eth0 root
tc qdisc add dev eth0 root handle 1: cbq avpkt 1000 bandwidth 90mbit

iptables -F
iptables -t nat -F
iptables -t mangle -F

# classes

# INTERNET UPLOADS
tc class add dev eth0 parent 1: classid 1:1 cbq rate 1mbit allot 1500 prio 0 bounded isolated

# ALL Local traffic
tc class add dev eth0 parent 1: classid 1:2 cbq rate 100mbit allot 1500 prio 0 bounded isolated

# 192.168.1.0/24
tc class add dev eth0 parent 1: classid 1:3 cbq rate 3mbit allot 1500 prio 0 bounded isolated

# 192.168.2.0/24
tc class add dev eth0 parent 1: classid 1:4 cbq rate 10mbit allot 1500 prio 0 bounded isolated

# 10.0.0.0/24
tc class add dev eth0 parent 1: classid 1:5 cbq rate 100mbit allot 1500 prio 0 bounded isolated

# filters
tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 1 fw classid 1:1
tc filter add dev eth0 parent 1:0 protocol ip prio 2 handle 2 fw classid 1:2
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 3 fw classid 1:3
tc filter add dev eth0 parent 1:0 protocol ip prio 4 handle 4 fw classid 1:4
tc filter add dev eth0 parent 1:0 protocol ip prio 4 handle 5 fw classid 1:5

# IPTABLES

# NAT
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE
iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o eth0 -j MASQUERADE

# MANGLE

# LAN 192.168.1.0/24 most hosts on this network are users
#

# Downloads packets 

# local traffic
iptables -t mangle -A PREROUTING -d 192.168.1.0/24 -j MARK --set-mark 0x2
iptables -t mangle -A PREROUTING -d 192.168.1.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.1.0/24 -j MARK --set-mark 0x3
iptables -t mangle -A POSTROUTING -d 192.168.1.0/24 -j RETURN

# Uploads packets
iptables -t mangle -A PREROUTING -s 192.168.1.0/24 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING -s 192.168.1.0/24 -j RETURN

# LAN 192.168.2.0/24 is the wifi network SGW-Media
#

# Download packets

# local traffic
iptables -t mangle -A PREROUTING -d 192.168.2.0/24 -j MARK --set-mark 0x2
iptables -t mangle -A PREROUTING -d 192.168.2.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.2.0/24 -j MARK --set-mark 0x4
iptables -t mangle -A POSTROUTING -d 192.168.2.0/24 -j RETURN

# Upload packets
iptables -t mangle -A PREROUTING -s 192.168.2.0/24 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING -s 192.168.2.0/24 -j RETURN

# LAN 10.0.0.0/24
#   All host are servers 
#

# Downloads

# local traffic
iptables -t mangle -A PREROUTING -d 10.0.0.0/24 -j MARK --set-mark 0x2
iptables -t mangle -A PREROUTING -d 10.0.0.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -d 10.0.0.0/24 -j MARK --set-mark 0x5
iptables -t mangle -A POSTROUTING -d 10.0.0.0/24 -j RETURN

# Uploads
iptables -t mangle -A PREROUTING -s 10.0.0.0/24 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING -s 10.0.0.0/24 -j RETURN


# All Internet downloads
#iptables -t mangle -A POSTROUTING ! -s 192.168.1.0/24 -j MARK --set-mark 0x2
#iptables -t mangle -A POSTROUTING ! -s 192.168.2.0/24 -j MARK --set-mark 0x2
#iptables -t mangle -A POSTROUTING ! -s 10.0.0.0/24 -j MARK --set-mark 0x2



# INPUT chain
iptables -A INPUT -j ACCEPT

# FORWARD chain
iptables -A FORWARD -j ACCEPT

#iptables -A FORWARD -i eth0 -o wlan0 -m state --state RELATED,ESTABLISHED -j ACCEPT
#iptables -A FORWARD -i wlan0 -o eth0 -j ACCEPT

# OUTPUT chain
iptables -A OUTPUT -j ACCEPT
