# ELK stack

# Server (Tested on Ubuntu 1604)
> $ ./docker.sh<br>
> $ ./elk.sh

ELK configurations can be done for each of the 

# Clients (Windows)
Run the following command in a root cmd/powershell prompt:<br>
> \> powershell -ExecutionPolicy ByPass -File scripts/runner.ps1

# Issue(s)
* Winpcap is necessary for packetbeat service to start. Winpcap needs Chocolatey or GUI install so far. This is a hassle if it's supposed to be pushed by e.g. 

# TODO
* Replace all IP's with ELK IPs based on runner.ps1 param (PS params). (Config files)
