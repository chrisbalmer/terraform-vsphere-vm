---
instance-id: ${hostname}
local-hostname: ${hostname}
network:
  version: 2
  ethernets:
    ${network_interface}:
      dhcp4: false
      addresses:
        - ${ip_address}
      gateway4: ${gateway}
      nameservers:
        addresses: ${dns}
wait-on-network:
  ipv4: true