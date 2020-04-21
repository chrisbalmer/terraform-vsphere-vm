#cloud-config

users:
  - name: ${cloud_user}
    groups: wheel
    lock_passwd: false
    passwd: ${cloud_pass}
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
      - ${initial_key}
