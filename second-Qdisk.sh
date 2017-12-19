
 tc qdisc add dev eth0 root handle 1:10000 cbq bandwidth 100Mbit         \
  avpkt 1000 cell 8
 

# tc class add dev eth0 parent 2:0 classid 2:1 cbq bandwidth 100Mbit  \
#  rate 6Mbit weight 0.6Mbit prio 8 allot 1514 cell 8 maxburst 20      \
#  avpkt 1000 boundedx