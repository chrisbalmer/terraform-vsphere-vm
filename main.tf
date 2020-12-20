locals {
  vm = merge(var.default_vm, var.vm)
}

data "vsphere_datacenter" "dc" {
  name = var.cluster_settings.datacenter
}

data "vsphere_resource_pool" "pool" {
  name          = var.cluster_settings.pool
  datacenter_id = data.vsphere_datacenter.dc.id
}

data "vsphere_datastore" "datastore" {
  datacenter_id = data.vsphere_datacenter.dc.id
  name          = local.vm.datastore
}

data "vsphere_network" "networks" {
  count         = length(local.vm.networks)
  datacenter_id = data.vsphere_datacenter.dc.id
  name          = local.vm.networks[count.index].port_group
}

data "vsphere_virtual_machine" "template" {
  datacenter_id = data.vsphere_datacenter.dc.id
  name          = local.vm.template
}

resource "vsphere_virtual_machine" "vm" {
  name                       = local.vm.name
  datastore_id               = data.vsphere_datastore.datastore.id
  resource_pool_id           = data.vsphere_resource_pool.pool.id
  num_cpus                   = local.vm.cpus
  memory                     = local.vm.memory
  guest_id                   = data.vsphere_virtual_machine.template.guest_id
  scsi_type                  = data.vsphere_virtual_machine.template.scsi_type
  annotation                 = "Created: ${timestamp()}\nTemplate: ${local.vm.template}"
  wait_for_guest_net_timeout = local.vm.network_timeout

  dynamic "disk" {
    for_each = local.vm.disks

    content {
      label            = "${local.vm.name}.vmdk"
      size             = disk.value.size
      unit_number      = disk.key # This is the index of the disk in the list
      eagerly_scrub    = disk.value.template ? data.vsphere_virtual_machine.template.disks.0.eagerly_scrub : disk.value.eagerly_scrub
      thin_provisioned = disk.value.template ? data.vsphere_virtual_machine.template.disks.0.thin_provisioned : disk.value.thin

    }
  }

  dynamic "network_interface" {
    for_each = data.vsphere_network.networks

    content {
      network_id = network_interface.value.id
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.template.id
    #TODO: Complete this for non-cloud-init enabled templates like Windows
    dynamic "customize" {
      for_each = local.vm.customize ? [1] : []
      content {
        linux_options {
          host_name = local.vm.name
          domain    = local.vm.domain
        }

        dynamic "network_interface" {
          for_each = local.vm.networks
          content {
            ipv4_address = network_interface.value.ipv4_address
          }
        }

        ipv4_gateway = local.vm.gateway
      }
    }
  }

  # If using cloud-init and using a custom cloud-init setup then
  extra_config = local.vm.cloud_init ? (local.vm.cloud_init_custom ? {
    "guestinfo.${local.vm.cloud_config_guestinfo_path}"          = base64encode(data.template_file.userdata.rendered)
    "guestinfo.${local.vm.cloud_config_guestinfo_encoding_path}" = "base64"

    # Else if using cloud-init and not using a custom cloud-init setup then
    } : {
    "guestinfo.userdata"          = base64encode(data.template_file.userdata.rendered)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(data.template_file.metadata.rendered)
    "guestinfo.metadata.encoding" = "base64"

    # Else we aren't using cloud-init so don't supply anything
  }) : {}
}

data "template_file" "userdata" {
  template = file("${path.module}/files/${local.vm.cloud_config_template}")

  vars = {
    hostname          = local.vm.name
    ip_address        = local.vm.networks[0].ipv4_address
    gateway           = local.vm.gateway
    dns               = jsonencode(split(",", local.vm.networks[0].nameservers))
    network_interface = local.vm.networks[0].interface
    initial_key       = var.initial_key
    domain_name       = local.vm.domain
    cloud_user        = var.cloud_user
    cloud_pass        = var.cloud_pass
  }
}

data "template_file" "metadata" {
  template = file("${path.module}/files/${local.vm.metadata_template}")

  vars = {
    hostname       = local.vm.name
    network_config = base64encode(data.template_file.network_config.rendered)
  }
}

data "template_file" "network_config" {
  template = file("${path.module}/files/${local.vm.network_config_template}")

  vars = {
    ip_address        = local.vm.networks[0].ipv4_address
    gateway           = local.vm.gateway
    network_interface = local.vm.networks[0].interface
    dns               = jsonencode(split(",", local.vm.networks[0].nameservers))
    domain_name       = local.vm.domain
  }
}
