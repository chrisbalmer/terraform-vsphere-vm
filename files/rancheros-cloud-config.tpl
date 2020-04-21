#cloud-config
hostname: ${hostname}
ssh_authorized_keys:
  - ${initial_key}

rancher:
  network:
    interfaces:
      ${network_interface}:
        address: ${ip_address}
        gateway: ${gateway}
        mtu: 1500
        dhcp: false
    dns:
      search:
        - ${domain_name}
      nameservers: ${dns}
  resize_device: /dev/sda
  repositories:
    cb-nfs-service-test:
      url: https://raw.githubusercontent.com/chrisbalmer/cb-nfs-service-test/master
  services_include:
    nfs: true