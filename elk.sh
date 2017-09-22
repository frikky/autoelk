#/bin/sh

ip=$(ip a | grep -E "eth0|ens160" | grep inet | grep -Po "\d+\.\d+\.\d+\.\d+" | head -1)
git clone https://github.com/deviantony/docker-elk
cd docker-elk
docker-compose up -d
echo "\n[!] ELK setup finished. Kibana is up at $ip:5601 in 2~ minutes."
