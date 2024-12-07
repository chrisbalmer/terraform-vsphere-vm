#cloud-config
users:
  - name: ${cloud_user}
    groups: sudo, wheel
    lock_passwd: false
    passwd: ${cloud_pass}
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
%{ for ssh_key in ssh_keys ~}
      - ${ssh_key}
%{ endfor ~}

growpart:
  mode: growpart
  devices: [ '/dev/sda3' ]

runcmd:
  - pvresize /dev/sda3
  - lvextend -r -l +100%FREE /dev/mapper/ubuntu--vg-ubuntu--lv
