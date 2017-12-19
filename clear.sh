tc qdisc del dev eth0 root
tc qdisc del dev wlan0 root

iptables -F
#iptables -t nat -F
iptables -t mangle -F
