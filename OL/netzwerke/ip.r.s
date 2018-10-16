user@KONN-66:~$ ip r s
default via 192.168.49.1 dev eth4  proto static  metric 100 
default dev eth2  scope link  metric 1004 
10.10.8.0/24 dev eth0  proto kernel  scope link  src 10.10.8.6 linkdown 
10.217.9.0/24 dev eth3  proto kernel  scope link  src 10.217.9.1 
10.250.0.0/16 dev docker0  proto kernel  scope link  src 10.250.0.1 linkdown 
169.254.0.0/16 dev eth2  proto kernel  scope link  src 169.254.4.189 
169.254.0.0/16 dev eth1  scope link  metric 1000 linkdown 
192.168.2.0/24 dev eth0  proto kernel  scope link  src 192.168.2.1 linkdown 
192.168.3.0/24 dev eth1  proto kernel  scope link  src 192.168.3.100 linkdown 
192.168.49.0/24 dev eth4  proto kernel  scope link  src 192.168.49.223  metric 100 