version: 1
config:
- type: physical
  name: ${network_interface}
  subnets:
    - type: static
      address: ${ip_address}
      gateway: ${gateway}
      dns_nameservers: ${dns}
      dns_search:
        - ${domain_name}