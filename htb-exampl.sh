iptables -F
iptables -t nat -F
iptables -t mangle -F

tc qdisc del dev eth0 root

tc qdisc add dev eth0 root handle 1: htb default 10

tc class add dev eth0 parent 1: classid 1:1 htb rate 100mbit ceil 100mbit

# ALL TRAFFIC TO SERVERS (10.0.0.0/24)
tc class add dev eth0 parent 1:1 classid 1:10 htb rate 12mbit ceil 12mbit prio 0

# www
tc class add dev eth0 parent 1:10 classid 1:11 htb rate 100mbit ceil 12mbit prio 0

iptables -t mangle -A POSTROUTING -d 10.0.0.4 -j MARK --set-mark 11
iptables -t mangle -A POSTROUTING -d 10.0.0.4 -j RETURN

# db
tc class add dev eth0 parent 1:10 classid 1:12 htb rate 100mbit ceil 12mbit prio 1

iptables -t mangle -A POSTROUTING -d 10.0.0.3 -j MARK --set-mark 12
iptables -t mangle -A POSTROUTING -d 10.0.0.3 -j RETURN

#
# ALL TRAFFIC TO KIEL 
#
tc class add dev eth0 parent 1:1 classid 1:20 htb rate 6mbit ceil 12mbit prio 1

# laptop
tc class add dev eth0 parent 1:10 classid 1:21 htb rate 12mbit ceil 12mbit prio 0

tc filter add dev eth0 parent 1:10 protocol ip prio 3 handle 21 fw classid 1:21

iptables -t mangle -A POSTROUTING -d 192.168.1.6 -j MARK --set-mark 21
iptables -t mangle -A POSTROUTING -d 192.168.1.6 -j RETURN

# phone
tc class add dev eth0 parent 1:10 classid 1:22 htb rate 12mbit ceil 12mbit prio 1

iptables -t mangle -A POSTROUTING -d 192.168.1.5 -j MARK --set-mark 22
iptables -t mangle -A POSTROUTING -d 192.168.1.5 -j RETURN

#
# Streaming media
#
tc class add dev eth0 parent 1:1 classid 1:30 htb rate 6mbit ceil 8mbit prio 2
	# loungeroom apple tv
	tc class add dev eth0 parent 1:30 classid 1:31 htb rate 6mbit ceil 8mbit prio 0
	# bedroom apple tv 
	tc class add dev eth0 parent 1:30 classid 1:32 htb rate 6mbit ceil 8mbit prio 0
	# ubuntu laptop
	tc class add dev eth0 parent 1:30 classid 1:33 htb rate 6mbit ceil 8mbit prio 0

# Isac
tc class add dev eth0 parent 1:1 classid 1:40 htb rate 6mbit ceil 8mbit prio 3
	# playstation 
	tc class add dev eth0 parent 1:40 classid 1:41 htb rate 1mbit ceil 2mbit prio 0
	# laptop
	tc class add dev eth0 parent 1:40 classid 1:42 htb rate 3mbit ceil 8mbit prio 1
	# phone
	tc class add dev eth0 parent 1:40 classid 1:43 htb rate 2mbit ceil 8mbit prio 2
	# ipad
	tc class add dev eth0 parent 1:40 classid 1:44 htb rate 3mbit ceil 8mbit prio 3

# 
# ALL TRAFFIC TO EVIE
#

tc class add dev eth0 parent 1:1 classid 1:50 htb rate 6mbit ceil 8mbit prio 3

# laptop
tc class add dev eth0 parent 1:50 classid 1:51 htb rate 6mbit ceil 8mbit prio 0

iptables -t mangle -A POSTROUTING -d 192.168.1.20 -j MARK --set-mark 51
iptables -t mangle -A POSTROUTING -d 192.168.1.20 -j RETURN

# ipad
tc class add dev eth0 parent 1:50 classid 1:52 htb rate 6mbit ceil 8mbit prio 1
iptables -t mangle -A POSTROUTING -d 192.168.1.23 -j MARK --set-mark 52
iptables -t mangle -A POSTROUTING -d 192.168.1.23 -j RETURN

# tablet
tc class add dev eth0 parent 1:50 classid 1:53 htb rate 6mbit ceil 8mbit prio 2

iptables -t mangle -A POSTROUTING -d 192.168.1.21 -j MARK --set-mark 53
iptables -t mangle -A POSTROUTING -d 192.168.1.21 -j RETURN


# Sarah
tc class add dev eth0 parent 1:1 classid 1:60 htb rate 6mbit ceil 8mbit prio 3
	# 
	tc class add dev eth0 parent 1:60 classid 1:61 htb rate 6mbit ceil 8mbit prio 0
	tc class add dev eth0 parent 1:60 classid 1:62 htb rate 6mbit ceil 8mbit prio 1

# Eliza
tc class add dev eth0 parent 1:1 classid 1:70 htb rate 6mbit ceil 8mbit prio 3
	tc class add dev eth0 parent 1:70 classid 1:71 htb rate 6mbit ceil 8mbit prio 0




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