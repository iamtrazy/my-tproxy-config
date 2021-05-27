#!/bin/bash

ip rule add fwmark 1 table 100
ip route add local 0.0.0.0/0 dev lo table 100

# Proxy LAN devices
iptables -t mangle -N XRAY
# "ipv4 segment where the gateway is located" is obtained by running the command "ip address | grep -w inet | awk '{print $2}'", usually there are multiple
iptables -t mangle -A XRAY -d 127.0.0.1/8 -j RETURN
iptables -t mangle -A XRAY -d 192.168.43.76/24 -j RETURN

# Mark 1 for TCP and forward to port 12345
# mark can only be set to 1 for the traffic to be accepted by the Xray dokodemo-door
iptables -t mangle -A XRAY -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1
iptables -t mangle -A XRAY -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
# Apply rules
iptables -t mangle -A PREROUTING -j XRAY

# Proxy gateway itself
iptables -t mangle -N XRAY_MASK
iptables -t mangle -A XRAY_MASK -d 127.0.0.1/8 -j RETURN
iptables -t mangle -A XRAY_MASK -d 192.168.43.76/24 -j RETURN

iptables -t mangle -A XRAY_MASK -j MARK --set-mark 1
iptables -t mangle -A OUTPUT -m owner ! --gid-owner 23333 ! -p icmp -j XRAY_MASK

ip -6 rule add fwmark 1 table 106
ip -6 route add local ::/0 dev lo table 106

# Proxy LAN devices
ip6tables -t mangle -N XRAY6
# The "ipv6 segment where the gateway is located" is obtained by running the command "ip address | grep -w inet6 | awk '{print $2}'".
ip6tables -t mangle -A XRAY6 -d 2407:c00:5007:5805:48ca:2353:f312:d411/64 -j RETURN
ip6tables -t mangle -A XRAY6 -d fe80::2ab:5235:9146:d3e/64 -j RETURN

ip6tables -t mangle -A XRAY6 -p udp -j TPROXY --on-port 12345 --tproxy-mark 1
ip6tables -t mangle -A XRAY6 -p tcp -j TPROXY --on-port 12345 --tproxy-mark 1
ip6tables -t mangle -A PREROUTING -j XRAY6

# Proxy gateway itself
ip6tables -t mangle -N XRAY6_MASK
ip6tables -t mangle -A XRAY6_MASK -d 2407:c00:5007:5805:48ca:2353:f312:d411/64 -j RETURN
ip6tables -t mangle -A XRAY6_MASK -d fe80::2ab:5235:9146:d3e/64 -j RETURN

ip6tables -t mangle -A XRAY6_MASK -j MARK --set-mark 1
ip6tables -t mangle -A OUTPUT -m owner ! --gid-owner 23333 ! -p icmp -j XRAY6_MASK
