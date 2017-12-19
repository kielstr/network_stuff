tc qdisc del dev eth0 root
tc qdisc add dev eth0 root handle 1: htb
tc class add dev eth0 parent 1: classid 1:1 htb rate 90mbit
tc class add dev eth0 parent 1:1 classid 1:10 htb rate 1kbit ceil 1mbit prio 2
tc filter add dev eth0 parent 1:0 prio 2 protocol ip handle 10 fw flowid 1:10

iptables -t nat -F 
iptables -t mangle -F 

iptables -t mangle -A POSTROUTING -d 192.168.1.6 -j MARK --set-mark 10
