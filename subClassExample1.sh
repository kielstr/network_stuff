
### IPTABLES ####
#

# Clear NAT
iptables -t nat -F

# Forward all httpd traffic to www
#iptables -t nat -A PREROUTING -p tcp -d 192.168.1.10 --dport 80 -j \
#	DNAT --to-destination 10.0.0.4:80

# Forward for server network
iptables -t nat -A POSTROUTING -s 10.0.0.0/24 -o eth0 -j MASQUERADE

# Users
iptables -t nat -A POSTROUTING -s 192.168.1.0/24 -o eth0 -j MASQUERADE

# second WiFi network
iptables -t nat -A POSTROUTING -s 192.168.2.0/24 -o eth0 -j MASQUERADE

# Clear marking rules
iptables -t mangle -F

# Clear chains
iptables -F

# if its LAN traffic do nothing 
iptables -A INPUT -d 192.168.1.10 -s 10.0.0.0/24 -j RETURN
iptables -A INPUT -d 192.168.1.10 -s 192.168.1.0/24 -j RETURN
iptables -A INPUT -d 192.168.1.10 -s 192.168.2.0/24 -j RETURN

#
## Packet shapping
#

# Clear out queues.
tc qdisc del dev eth0 root

# Create qdisc
tc qdisc add dev eth0 root handle 1: htb default 1

# Add root class
tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbit ceil 100mbit

###############################
# ALL INTERNET TRAFFIC TO KIEL 
#
# Q_ID: 1:10 Kiel (all devices) 

KS_RATE="11mbit"
KS_RATE_CEIL="11mbit"

tc class add dev eth0 parent 1:1 classid 1:10 htb rate 100mbit ceil 100mbit prio 1

# Q_ID: 1:11 Kiel (laptop)

tc class add dev eth0 parent 1:10 classid 1:11 htb rate $KS_RATE ceil $KS_RATE_CEIL prio 1
tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 11 fw classid 1:11

iptables -t mangle -A POSTROUTING -d kiels-laptop -j MARK --set-mark 11
iptables -t mangle -A POSTROUTING -d kiels-laptop -j RETURN

echo "Kiel(kiels-laptop) 1:12, has be rate limitted to $KS_RATE with a ceiling of $KS_RATE_CEIL";

# Q_ID: 1:12 Kiel (phone)

tc class add dev eth0 parent 1:10 classid 1:12 htb rate $KS_RATE ceil $KS_RATE_CEIL prio 1
tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 12 fw classid 1:12

iptables -t mangle -A POSTROUTING -d kiels-phone -j MARK --set-mark 12
iptables -t mangle -A POSTROUTING -d kiels-phone -j RETURN

echo "Kiel(kiels-phone) has be rate limitted to $KS_RATE with a ceiling of $KS_RATE_CEIL";

################################
# ALL INTERNET TRAFFIC TO SARAH 
#
# Q_ID: 1:20 Sarah (all devices) 
#
tc class add dev eth0 parent 1:1 classid 1:20 htb rate 6mbit ceil 7mbit prio 1

# Q_ID: 1:21 Sarah (phone) 

tc class add dev eth0 parent 1:20 classid 1:21 htb rate 6mbit ceil 7mbit prio 1
tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 21 fw classid 1:21

iptables -t mangle -A POSTROUTING -d 192.168.1.50 -j MARK --set-mark 21
iptables -t mangle -A POSTROUTING -d 192.168.1.50 -j RETURN

# Q_ID: 1:22 Sarah (laptop) 

tc class add dev eth0 parent 1:20 classid 1:22 htb rate 6mbit ceil 7mbit prio 1
tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 22 fw classid 1:22

iptables -t mangle -A POSTROUTING -d 192.168.1.51 -j MARK --set-mark 22
iptables -t mangle -A POSTROUTING -d 192.168.1.51 -j RETURN

################################
# ALL INTERNET TRAFFIC TO ISAC 
#
# Q_ID: 1:30 Isac (all devices) 
#
tc class add dev eth0 parent 1:1 classid 1:30 htb rate 2mbit ceil 6mbit prio 3

# # Q_ID: 1:31 Isac (laptop) 

tc class add dev eth0 parent 1:30 classid 1:31 htb rate 2mbit ceil 6mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 31 fw classid 1:31

iptables -t mangle -A POSTROUTING -d 192.168.1.7 -j MARK --set-mark 31
iptables -t mangle -A POSTROUTING -d 192.168.1.7 -j RETURN

# Q_ID: 1:32 Isac (playstation) 

tc class add dev eth0 parent 1:30 classid 1:32 htb rate 2mbit ceil 6mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 32 fw classid 1:32

iptables -t mangle -A POSTROUTING -d 192.168.1.8 -j MARK --set-mark 32
iptables -t mangle -A POSTROUTING -d 192.168.1.8 -j RETURN

# Q_ID: 1:33 Isac (phone) 

tc class add dev eth0 parent 1:30 classid 1:33 htb rate 2mbit ceil 6mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 33 fw classid 1:33

iptables -t mangle -A POSTROUTING -d 192.168.1.12 -j MARK --set-mark 33
iptables -t mangle -A POSTROUTING -d 192.168.1.12 -j RETURN

# Q_ID: 1:34 Isac (ipad) 

tc class add dev eth0 parent 1:30 classid 1:34 htb rate 2mbit ceil 6mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 34 fw classid 1:34

iptables -t mangle -A POSTROUTING -d 192.168.1.13 -j MARK --set-mark 34
iptables -t mangle -A POSTROUTING -d 192.168.1.13 -j RETURN

#######################
# ALL TRAFFIC TO EVIE 
#

# Q_ID: 1:40 Evie (all devices) 

tc class add dev eth0 parent 1:1 classid 1:40 htb rate 2mbit ceil 7mbit prio 3

# Q_ID: 1:41 Evie (laptops) 

tc class add dev eth0 parent 1:40 classid 1:41 htb rate 2mbit ceil 7mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 41 fw classid 1:41

iptables -t mangle -A POSTROUTING -d 192.168.1.20 -j MARK --set-mark 41
iptables -t mangle -A POSTROUTING -d 192.168.1.20 -j RETURN

iptables -t mangle -A POSTROUTING -d 192.168.1.22 -j MARK --set-mark 41
iptables -t mangle -A POSTROUTING -d 192.168.1.22 -j RETURN

# Q_ID: 1:42 Evie (tablet) 

tc class add dev eth0 parent 1:40 classid 1:42 htb rate 2mbit ceil 7mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 42 fw classid 1:42

iptables -t mangle -A POSTROUTING -d 192.168.1.21 -j MARK --set-mark 42
iptables -t mangle -A POSTROUTING -d 192.168.1.21 -j RETURN

# Q_ID: 1:43 Evie (ipad)

tc class add dev eth0 parent 1:40 classid 1:43 htb rate 2mbit ceil 7mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 43 fw classid 1:43

iptables -t mangle -A POSTROUTING -d 192.168.1.23 -j MARK --set-mark 43
iptables -t mangle -A POSTROUTING -d 192.168.1.23 -j RETURN

########################
# ALL TRAFFIC TO ELISA 
#

# Q_ID: 1:50 Eliza (all devices)

tc class add dev eth0 parent 1:1 classid 1:50 htb rate 2mbit ceil 5mbit prio 3

# Q_ID: 1:50 Eliza (tablet)

tc class add dev eth0 parent 1:50 classid 1:51 htb rate 2mbit ceil 5mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 51 fw classid 1:51

iptables -t mangle -A POSTROUTING -d 192.168.1.40 -j MARK --set-mark 51
iptables -t mangle -A POSTROUTING -d 192.168.1.40 -j RETURN


################################
# ALL TRAFFIC TO MEDIA DEVICES 
#

# Q_ID: 1:60 Media (all devices)

tc class add dev eth0 parent 1:1 classid 1:60 htb rate 7mbit ceil 7mbit prio 2

# Q_ID: 1:61 Media (lounge apple tv)

tc class add dev eth0 parent 1:60 classid 1:61 htb rate 7mbit ceil 7mbit prio 2
tc filter add dev eth0 parent 1:0 protocol ip prio 2 handle 61 fw classid 1:61

iptables -t mangle -A POSTROUTING -d 192.168.1.30 -j MARK --set-mark 61
iptables -t mangle -A POSTROUTING -d 192.168.1.30 -j RETURN

# Q_ID: 1:62 Media (bedroom apple tv)

tc class add dev eth0 parent 1:60 classid 1:62 htb rate 7mbit ceil 7mbit prio 2
tc filter add dev eth0 parent 1:0 protocol ip prio 2 handle 62 fw classid 1:62

iptables -t mangle -A POSTROUTING -d 192.168.1.31 -j MARK --set-mark 62
iptables -t mangle -A POSTROUTING -d 192.168.1.31 -j RETURN

# Q_ID: 1:63 Media (ubuntu laptop)

tc class add dev eth0 parent 1:60 classid 1:63 htb rate 10mbit ceil 10mbit prio 2
tc filter add dev eth0 parent 1:0 protocol ip prio 2 handle 63 fw classid 1:63

iptables -t mangle -A POSTROUTING -d 192.168.1.32 -j MARK --set-mark 63
iptables -t mangle -A POSTROUTING -d 192.168.1.32 -j RETURN

#####################################################
# ALL DYNAMIC HOSTS (192.168.1.100 - 192.168.1.200)
#

# Q_ID: 1:70 DHCP unassigned (visitors)

tc class add dev eth0 parent 1:1 classid 1:70 htb rate 2mbit ceil 4mbit prio 3
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 70 fw classid 1:70

iptables -t mangle -A POSTROUTING -d 192.168.1.0/24 -j MARK --set-mark 70
iptables -t mangle -A POSTROUTING -d 192.168.1.0/24 -j RETURN

##########################################################################################
# Rest of the traffic from the internet. Host on 10.0.0.0/24 and 192.168.2.0/24 hit this
# queue.

# Q_ID: 1:80 10.0.0.0/24 and 192.168.2.0/24 (servers and wifi #2)

tc class add dev eth0 parent 1:1 classid 1:80 htb rate 12mbit ceil 12mbit prio 1
tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 80 fw classid 1:80

iptables -t mangle -A PREROUTING ! -s 10.0.0.0/24 -d 192.168.1.10 -j MARK --set-mark 80
iptables -t mangle -A PREROUTING ! -s 10.0.0.0/24 -d 192.168.1.10 -j RETURN

iptables -t mangle -A PREROUTING ! -s 192.168.1.0/24 -d 192.168.1.10 -j MARK --set-mark 80
iptables -t mangle -A PREROUTING ! -s 192.168.1.0/24 -d 192.168.1.10 -j RETURN

iptables -t mangle -A PREROUTING ! -s 192.168.2.0/24 -d 192.168.1.10 -j MARK --set-mark 80
iptables -t mangle -A PREROUTING ! -s 192.168.2.0/24 -d 192.168.1.10 -j RETURN

############################
# INTERNET TRAFFIC UPLOADS

# When the src address is the gateway and the dst addr is not one of our networks
#  then its an internet upload

# Q_ID: 1:90 -- all internet uploads (all ips)

tc class add dev eth0 parent 1:1 classid 1:90 htb rate 500kbit ceil 1mbit prio 4
tc filter add dev eth0 parent 1:0 protocol ip prio 4 handle 90 fw classid 1:90

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 10.0.0.0/24 -j MARK --set-mark 90
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 10.0.0.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.1.0/24 -j MARK --set-mark 90
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.1.0/24 -j RETURN

iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.2.0/24 -j MARK --set-mark 90
iptables -t mangle -A POSTROUTING -s 192.168.1.10 ! -d 192.168.2.0/24 -j RETURN

# isac-laptop 192.168.1.7 
# isac-playstation 192.168.1.8
# isac-oldphone 192.168.1.9
# isac-ipad 192.168.1.12
# isac-newphone 192.168.1.13

# Bad kid rule.

#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.7 --dport 80 -j REDIRECT --to-port 8080
#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.7 --dport 80 -j RETURN
#iptables -A FORWARD -s 192.168.1.7 -j DROP

#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.8 --dport 80 -j REDIRECT --to-port 8080
#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.8 --dport 80 -j RETURN
#iptables -A FORWARD -s 192.168.1.8 -j DROP

#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.9 --dport 80 -j REDIRECT --to-port 8080
#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.9 --dport 80 -j RETURN
#iptables -A FORWARD -s 192.168.1.9 -j DROP

#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.12 --dport 80 -j REDIRECT --to-port 8080
#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.12 --dport 80 -j RETURN
#iptables -A FORWARD -s 192.168.1.12 -j DROP

#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.13 --dport 80 -j REDIRECT --to-port 8080
#iptables -t nat -A PREROUTING -i eth0 -p tcp -s 192.168.1.13 --dport 80 -j RETURN
#iptables -A FORWARD -s 192.168.1.13 -j DROP

