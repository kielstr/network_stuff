DEV="wlan0";

tc qdisc del dev $DEV root

tc qdisc add dev $DEV root handle 1: cbq avpkt 1000 bandwidth 100mbit 

# Isac
tc class add dev $DEV parent 1: classid 1:1 cbq rate 2mbit allot 1500 prio 5 bounded isolated 
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.7 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.8 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.9 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.12 flowid 1:1
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.13 flowid 1:1

# Evie
tc class add dev $DEV parent 1: classid 1:2 cbq rate 2mbit allot 1500 prio 5 bounded isolated 
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.20 flowid 1:2
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.21 flowid 1:2
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.22 flowid 1:2
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.23 flowid 1:2

#Eliza
tc class add dev $DEV parent 1: classid 1:5 cbq rate 2mbit allot 1500 prio 5 bounded isolated
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.122 flowid 1:5
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.40 flowid 1:5

# Sarah phone
tc filter add dev $DEV parent 1: protocol ip prio 16 u32 match ip dst 192.168.2.50 flowid 1:5

# Apple TV 
tc class add dev $DEV parent 1: classid 1:3 cbq rate 1mbit allot 1500 prio 2 bounded isolated 
tc filter add dev $DEV parent 1: protocol ip prio 2 u32 match ip dst 192.168.2.30 flowid 1:3
tc filter add dev $DEV parent 1: protocol ip prio 2 u32 match ip dst 192.168.2.31 flowid 1:3

#Lounge room laptopp
#tc class add dev $DEV parent 1: classid 1:4 cbq rate 5mbit allot 1500 prio 3 bounded isolated 
#tc filter add dev $DEV parent 1: protocol ip prio 1 u32 match ip dst 192.168.2.32 flowid 1:4

tc filter show dev eth0
