iptables -F

iptables -I FORWARD -s www -j MARK --set-mark 6
iptables -I FORWARD -d www -j MARK --set-mark 6

tc qdisc del dev eth0 root
tc qdisc add dev eth0 root handle 1: htb
tc class add dev eth0 parent 1:1 classid 1:10 htb rate .5mbit ceil 1mbit
tc qdisc add dev eth0 parent 1:10 sfq perturb 10
tc filter add dev eth0 protocol ip parent 1: prio 1 handle 6 fw flowid 1:10
