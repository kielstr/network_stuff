#+---------+
#| root 1: |
#+---------+
#     |
#+---------------------------------------+
#| class 1:1                             |
#+---------------------------------------+
#  |      |      |      |      |      |      
#+----+ +----+ +----+ +----+ +----+ +----+
#|1:10| |1:11| |1:12| |1:13| |1:14| |1:15| 
#+----+ +----+ +----+ +----+ +----+ +----+ 

#classid 1:10 htb rate 80kbit ceil 80kbit prio 0
# This is the highest priority class. The packets in this class will have the lowest 
# delay and would get the excess of bandwith first so it's a good idea to limit the 
# ceil rate to this class. We will send through this class the following #packets 
# that benefit from low delay, such as interactive traffic: ssh, telnet, dns, 
# quake3, irc, and packets with the SYN flag.

# classid 1:11 htb rate 80kbit ceil ${CEIL}kbit prio 1
# Here we have the first class in which we can start to put bulk traffic. In my example 
# I have traffic from the local web #server and requests for web pages: source port 80,
# and destination port 80 respectively.

# classid 1:12 htb rate 20kbit ceil ${CEIL}kbit prio 2
# In this class I will put traffic with Maximize-Throughput TOS bit set and the rest of 
# the traffic that goes from local #processes on the router to the Internet. So the following 
# classes will only have traffic that is "routed through" the box.

# classid 1:13 htb rate 20kbit ceil ${CEIL}kbit prio 2
# This class is for the traffic of other NATed machines that need higher priority in their bulk traffic.

# classid 1:14 htb rate 10kbit ceil ${CEIL}kbit prio 3
# Here goes mail traffic (SMTP,pop3...) and packets with Minimize-Cost TOS bit set.

# classid 1:15 htb rate 30kbit ceil ${CEIL}kbit prio 3
# And finally here we have bulk traffic from the NATed machines behind the router. All kazaa,
# edonkey, and others will go #here, in order to not interfere with other services.



tc qdisc del dev eth0 root

CEIL=100
tc qdisc add dev eth0 root handle 1: htb default 16
tc class add dev eth0 parent 1: classid 1:1 htb rate ${CEIL}kbit ceil ${CEIL}kbit
tc class add dev eth0 parent 1:1 classid 1:10 htb rate 80kbit ceil 80kbit prio 0
tc class add dev eth0 parent 1:1 classid 1:11 htb rate 80kbit ceil ${CEIL}mbit prio 1
tc class add dev eth0 parent 1:1 classid 1:12 htb rate 20kbit ceil ${CEIL}mbit prio 2
tc class add dev eth0 parent 1:1 classid 1:13 htb rate 20kbit ceil ${CEIL}mbit prio 2
tc class add dev eth0 parent 1:1 classid 1:14 htb rate 10kbit ceil ${CEIL}mbit prio 3

tc class add dev eth0 parent 1:1 classid 1:15 htb rate 4mbit ceil ${CEIL}mbit prio 3

tc class add dev eth0 parent 1:1 classid 1:16 htb rate 10mbit ceil ${CEIL}mbit prio 3



tc qdisc add dev eth0 parent 1:12 handle 120: sfq perturb 10
tc qdisc add dev eth0 parent 1:13 handle 130: sfq perturb 10
tc qdisc add dev eth0 parent 1:14 handle 140: sfq perturb 10
tc qdisc add dev eth0 parent 1:15 handle 150: sfq perturb 10





# We have created the qdisc setup but no packet classification has been made, 
# so now all outgoing packets are going out in class 1:15 ( because we used: 
# tc qdisc add dev eth0 root handle 1: htb default 15 ). Now we need to tell 
# which packets go where. This is the most important part.

# Now we set the filters so we can classify the packets with iptables. I really prefer to do it with iptables,
# because they are very flexible and you have packet count for each rule. 
# Also with the RETURN target packets don't need to traverse all rules. We execute the following commands:

tc filter add dev eth0 parent 1:0 protocol ip prio 1 handle 1 fw classid 1:10
tc filter add dev eth0 parent 1:0 protocol ip prio 2 handle 2 fw classid 1:11
tc filter add dev eth0 parent 1:0 protocol ip prio 3 handle 3 fw classid 1:12
tc filter add dev eth0 parent 1:0 protocol ip prio 4 handle 4 fw classid 1:13
tc filter add dev eth0 parent 1:0 protocol ip prio 5 handle 5 fw classid 1:14
tc filter add dev eth0 parent 1:0 protocol ip prio 6 handle 6 fw classid 1:15
tc filter add dev eth0 parent 1:0 protocol ip prio 7 handle 7 fw classid 1:16


#tc filter add dev eth0 parent 2:0 protocol ip prio 7 handle 7 fw classid 2:1

# We have just told the kernel that packets that have a specific FWMARK value ( handle x fw ) go in the 
# specified class ( classid x:x). Next you will see how to mark packets with iptables.

#First you have to understand how packet traverse the filters with iptables:
#
#        +------------+                +---------+               +-------------+
#Packet -| PREROUTING |--- routing-----| FORWARD |-------+-------| POSTROUTING |- Packets
#input   +------------+    decision    +---------+       |       +-------------+    out
#                             |                          |
#                        +-------+                    +--------+   
#                        | INPUT |---- Local process -| OUTPUT |
#                        +-------+                    +--------+


#Next we instruct the kernel to actually do NAT, so clients in the private network can start talking to the outside.

echo 1 > /proc/sys/net/ipv4/ip_forward

iptables -F 
iptables -t nat -F 
iptables -t mangle -F 

iptables -t nat -A POSTROUTING -o eth0 -j MASQUERADE

#iptables -t nat -A POSTROUTING -s 192.168.1.0/255.255.0.0 -o eth0 -j SNAT --to-source 192.168.1.10
#iptables -t nat -A POSTROUTING -s 192.168.2.0/255.255.0.0 -o eth0 -j SNAT --to-source 192.168.1.10

# Now check that packets are flowing through 1:15:
# tc -s class show dev eth0

# You can start marking packets adding rules to the PREROUTING chain in the mangle table.
iptables -t mangle -A PREROUTING -p icmp -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING -p icmp -j RETURN

# Now you should be able to see packet count increasing when pinging from machines 
# within the private network to some site on the Internet. Check packet count increasing in 1:10

# tc -s class show dev eth0

# We have done a -j RETURN so packets don't traverse all rules. Icmp packets won't match other rules 
# below RETURN. Keep that in mind. Now we can start adding more rules, lets do proper TOS handling:

iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING -m tos --tos Minimize-Delay -j RETURN
iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j MARK --set-mark 0x5
iptables -t mangle -A PREROUTING -m tos --tos Minimize-Cost -j RETURN
iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j MARK --set-mark 0x6
iptables -t mangle -A PREROUTING -m tos --tos Maximize-Throughput -j RETURN

# Now prioritize ssh packets:


iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 22 -j MARK --set-mark 0x1
iptables -t mangle -A PREROUTING -p tcp -m tcp --sport 22 -j RETURN


iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.6 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.6 -j RETURN


# Isac 
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.7 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.7 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.8 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.8 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.9 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.9 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.12 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.12 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.13 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.13 -j RETURN

# Isac on Media
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.7 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.7 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.8 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.8 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.9 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.9 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.12 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.12 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.13 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.13 -j RETURN


# Evie
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.20 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.20 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.21 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.21 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.22 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.22 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.23 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.1.23 -j RETURN


# Evie on media
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.20 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.20 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.21 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.21 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.22 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.22 -j RETURN

iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.23 -j MARK --set-mark 0x7
iptables -t mangle -A PREROUTING -p tcp -m tcp -d 192.168.2.23 -j RETURN


	
# A good idea is to prioritize packets to begin tcp connections, those with SYN flag set:
iptables -t mangle -I PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j MARK --set-mark 0x1
iptables -t mangle -I PREROUTING -p tcp -m tcp --tcp-flags SYN,RST,ACK SYN -j RETURN


iptables -t mangle -A PREROUTING -j MARK --set-mark 0x7

