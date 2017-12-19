#!/bin/bash


#                     1:   root qdisc
#                      |
#                     1:1    child class
#                   /  |  \
#                  /   |   \
#                 /    |    \
#                 /    |    \
#              1:10  1:11  1:12   child classes
#               |      |     | 
#               |     11:    |    leaf class
#               |            | 
#               10:         12:   qdisc
#              /   \       /   \
#           10:1  10:2   12:1  12:2   leaf classes
#           

# qdiscs 
tc qdisc del dev eth0 root

# All local traffic goes
tc qdisc add dev eth0 root handle 1: cbq avpkt 1000 bandwidth 100MBit

#tc class add dev eth0 parent 1: classid 1:1 cbq rate 12669kBit allot 1500 prio 0 bounded isolated
tc class add dev eth0 parent 1: classid 1:1 cbq rate 5kBit allot 1500 prio 0 bounded isolated
tc filter add dev eth0 parent 1:0 protocol ip prio 0 handle 1 fw classid 1:1


# ALL TRAFFIC TO KIEL

iptables -t mangle -F

# if its LAN traffic do nothing 
iptables -t mangle -A POSTROUTING -d 192.168.1.10 -s 10.0.0.0/24 -j RETURN
iptables -t mangle -A POSTROUTING -d 192.168.1.10 -s 192.168.1.0/24 -j RETURN
iptables -t mangle -A POSTROUTING -d 192.168.1.10 -s 192.168.2.0/24 -j RETURN

# INTERNET TRAFFIC DOWNLOADS

# when the src addr is not one of out local networks and the dst prerouting is 
# the gateway then its internet downloads

iptables -t mangle -A PREROUTING ! -s 10.0.0.0/24 -d 192.168.1.10 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING ! -s 10.0.0.0/24 -d 192.168.1.10 -j RETURN

iptables -t mangle -A PREROUTING ! -s 192.168.1.0/24 -d 192.168.1.10 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING ! -s 192.168.1.0/24 -d 192.168.1.10 -j RETURN

iptables -t mangle -A PREROUTING ! -s 192.168.2.0/24 -d 192.168.1.10 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING ! -s 192.168.2.0/24 -d 192.168.1.10 -j RETURN


# 


iptables -t mangle -A POSTROUTING -d 192.168.1.6 -j MARK --set-mark 0x1
iptables -t mangle -A POSTROUTING -d 192.168.1.6 -j RETURN


# INTERNET TRAFFIC UPLOADS

# When the src address is the gateway and the dst addr is not one of our networks
#  then its an internet upload

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 10.0.0.0/24 -j MARK --set-mark 0x1
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 10.0.0.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.1.0/24 -j MARK --set-mark 0x1
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.1.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.2.0/24 -j MARK --set-mark 0x1
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.2.0/24 -j RETURN

