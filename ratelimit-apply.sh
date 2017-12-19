DEV="eth0";

tc qdisc del dev $DEV root

tc qdisc add dev $DEV root handle 1: cbq avpkt 1000 bandwidth 100mbit 

#tc class add dev external parent 1: classid 1:20 htb rate 905kbit ceil 2.15mbit

# Uploads
#tc class add dev $DEV parent 1: classid 1:20 cbq rate 1mbit allot 1500 prio 5 bounded isolated 
#tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.10 flowid 1:20

# Download www
tc class add dev $DEV parent 1: classid 1:21 cbq rate .6mbit allot 1500 prio 5 bounded isolated 
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip src 192.168.1.1 flowid 1:21

#iptables -A POSTROUTING -o eth0 -s 192.168.1.6 -j CLASSIFY --set-class 1:20

# Isac
tc class add dev $DEV parent 1: classid 1:1 cbq rate 2mbit allot 1500 prio 5 bounded isolated 
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.7 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.8 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.9 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.12 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.13 flowid 1:1

# Evie
tc class add dev $DEV parent 1: classid 1:2 cbq rate 2mbit allot 1500 prio 5 bounded isolated 
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.20 flowid 1:2
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.21 flowid 1:2
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.22 flowid 1:2
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.23 flowid 1:2

#Eliza
tc class add dev $DEV parent 1: classid 1:5 cbq rate 2mbit allot 1500 prio 5 bounded isolated
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.122 flowid 1:5
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.40 flowid 1:5

# Sarah phone
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.1.50 flowid 1:5

# Apple TV 
tc class add dev $DEV parent 1: classid 1:3 cbq rate 5mbit allot 1500 prio 2 bounded isolated 
tc filter add dev $DEV parent 1: protocol ip prio 2 u32 match ip dst 192.168.1.30 flowid 1:3
tc filter add dev $DEV parent 1: protocol ip prio 2 u32 match ip dst 192.168.1.31 flowid 1:3

#Lounge room laptopp
#tc class add dev $DEV parent 1: classid 1:4 cbq rate 5mbit allot 1500 prio 3 bounded isolated 
#tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 192.168.1.32 flowid 1:4

tc filter show dev eth0
