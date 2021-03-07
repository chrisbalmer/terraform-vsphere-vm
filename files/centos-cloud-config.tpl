#cloud-config

users:
  - name: ${cloud_user}
    groups: wheel
    lock_passwd: false
    passwd: ${cloud_pass}
    shell: /bin/bash
    sudo: ['ALL=(ALL) NOPASSWD:ALL']
    ssh_authorized_keys:
%{ for ssh_key in ssh_keys ~}
      - ${file(ssh_key)}
%{ endfor ~}

# grow the LVM partition (but not the VG or LV) on first boot
growpart:
  mode: growpart
  devices: [ '/dev/sda2' ]

# use runcmd to grow the VG, LV and root filesystem, as cloud-init
# # doesn't handle LVM resizing natively
runcmd:
  - pvresize /dev/sda2
  - lvextend -l +100%FREE /dev/mapper/centos_localcomputer-root
  - xfs_growfs /dev/mapper/centos_localcomputer-root
