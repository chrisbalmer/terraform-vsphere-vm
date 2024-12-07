locals {
  vm = merge(var.default_vm, var.vm)
  userdata_template = "${var.userdata_template != "" ? var.userdata_template : "${path.module}/files/${local.vm.userdata_template}"}"
  userdata = var.userdata != "" ? var.userdata : templatefile(local.userdata_template,
    {
      hostname          = local.vm.name,
      ip_address        = local.vm.networks[0].ipv4_address,
      gateway           = local.vm.gateway,
      dns               = jsonencode(split(",", local.vm.networks[0].nameservers)),
      network_interface = local.vm.networks[0].interface,
      ssh_keys          = var.ssh_keys,
      domain_name       = local.vm.domain,
      cloud_user        = var.cloud_user,
      cloud_pass        = var.cloud_pass,
      file_data         = var.file_data,
    }
  )
  metadata = templatefile("${path.module}/files/${local.vm.metadata_template}",
    {
      hostname          = local.vm.name,
      ip_address        = local.vm.networks[0].ipv4_address,
      gateway           = local.vm.gateway,
      network_interface = local.vm.networks[0].interface,
      dns               = jsonencode(split(",", local.vm.networks[0].nameservers)),
      domain_name       = local.vm.domain,
    }
  )
  tags = flatten([
    for group in keys(local.vm.tags) : [
      for tag in local.vm.tags[group] : {
        group = group
        tag   = tag
      }
    ]
  ])
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
  annotation                 = "Last apply: ${timestamp()}\nTemplate: ${local.vm.template}"
  tags                       = data.vsphere_tag.tag.*.id
  wait_for_guest_net_timeout = local.vm.network_timeout
  firmware                   = local.vm.firmware
  dynamic "disk" {
    for_each = local.vm.disks

    content {
      label            = contains(keys(disk.value), "name") ? "${local.vm.name}-${disk.value.name}.vmdk" : "${local.vm.name}-${disk.key}.vmdk"
      size             = contains(keys(disk.value), "size") ? disk.value.size : data.vsphere_virtual_machine.template.disks.0.size
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
  }

  lifecycle {
    ignore_changes = [
      clone[0].template_uuid,
      extra_config,
    ]
  }

  extra_config = {
    "guestinfo.userdata"          = base64encode(local.userdata)
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = base64encode(local.metadata)
    "guestinfo.metadata.encoding" = "base64"
  }
}

data "vsphere_tag_category" "category" {
  for_each = local.vm.tags
  name     = each.key
}

data "vsphere_tag" "tag" {
  count       = length(local.tags)
  name        = local.tags[count.index]["tag"]
  category_id = data.vsphere_tag_category.category[local.tags[count.index]["group"]].id
}