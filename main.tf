data "vsphere_datacenter" "node_dc" {
  name = "${var.vsphere_datacenter}"
}

data "vsphere_compute_cluster" "node_cluster" {
  name          = "${var.vsphere_cluster}"
  datacenter_id = "${data.vsphere_datacenter.node_dc.id}"
}

data "vsphere_resource_pool" "node_pool" {
  name          = "${var.vsphere_resource_pool}"
  datacenter_id = "${data.vsphere_datacenter.node_dc.id}"
}

data "vsphere_datastore" "node_datastore" {
  datacenter_id = "${data.vsphere_datacenter.node_dc.id}"
  name          = "${var.vsphere_datastore}"
}

data "vsphere_network" "node_network" {
  count         = length(var.vsphere_network)
  datacenter_id = "${data.vsphere_datacenter.node_dc.id}"
  name          = "${var.vsphere_network[count.index]}"
}

data "vsphere_virtual_machine" "node_template" {
  datacenter_id = "${data.vsphere_datacenter.node_dc.id}"
  name          = "${var.vsphere_template}"
}

resource "vsphere_virtual_machine" "nodes" {
  count                      = var.node_count
  name                       = "${var.node_prefix}${var.node_name}${count.index + 1}"
  datastore_id               = data.vsphere_datastore.node_datastore.id
  resource_pool_id           = data.vsphere_resource_pool.node_pool.id
  num_cpus                   = var.node_cpus
  memory                     = var.node_memory
  guest_id                   = data.vsphere_virtual_machine.node_template.guest_id
  scsi_type                  = data.vsphere_virtual_machine.node_template.scsi_type
  annotation                 = "Created on blah" #TODO: Add info here, date and source template
  wait_for_guest_net_timeout = var.wait_for_guest_net_timeout

  disk {
    label            = "${var.node_prefix}${var.node_name}${count.index + 1}$.vmd"
    size             = var.node_disk_size
    eagerly_scrub    = data.vsphere_virtual_machine.node_template.disks.0.eagerly_scrub
    thin_provisioned = data.vsphere_virtual_machine.node_template.disks.0.thin_provisioned
  }

  dynamic "network_interface" {
    for_each = data.vsphere_network.node_network

    content {
      network_id = network_interface.value.id
    }
  }

  clone {
    template_uuid = data.vsphere_virtual_machine.node_template.id
    #TODO: Complete this for non-cloud-init enabled templates like Windows
    dynamic "customize" {
      for_each = var.customize_vm ? [1] : []
      content {
        linux_options {
          host_name = "${var.node_prefix}${var.node_name}${count.index + 1}"
          domain    = var.node_domain_name
        }

        network_interface {
          ipv4_address = var.node_ips[count.index]
          #ipv4_netmask = 24
        }

        ipv4_gateway = var.node_gateway
      }
    }
  }

  # If using cloud-init and using a custom cloud-init setup then
  extra_config = var.cloud_init ? (var.cloud_init_custom ? {
    "guestinfo.${var.cloud_config_guestinfo_path}"          = "${base64encode("${data.template_file.userdata.*.rendered[count.index]}")}"
    "guestinfo.${var.cloud_config_guestinfo_encoding_path}" = "base64"

    # Else if using cloud-init and not using a custom cloud-init setup then
    } : {
    "guestinfo.userdata"          = "${base64encode("${data.template_file.userdata.*.rendered[count.index]}")}"
    "guestinfo.userdata.encoding" = "base64"
    "guestinfo.metadata"          = "${base64encode("${data.template_file.metadata.*.rendered[count.index]}")}"
    "guestinfo.metadata.encoding" = "base64"

    # Else we aren't using cloud-init so don't supply anything
  }) : {}
}

data "template_file" "userdata" {
  count    = "${var.node_count}"
  template = "${file("${path.module}/files/${var.cloud_config_template}")}"

  vars = {
    hostname          = "${var.node_prefix}${var.node_name}${count.index + 1}"
    ip_address        = "${var.node_ips[count.index]}"
    gateway           = "${var.node_gateway}"
    dns               = "${jsonencode(split(",", var.node_dns))}"
    network_interface = "${var.node_network_interface}"
    initial_key       = "${var.node_initial_key}"
    domain_name       = "${var.node_domain_name}"
    cloud_user        = "${var.cloud_user}"
    cloud_pass        = "${var.cloud_pass}"
  }
}

data "template_file" "metadata" {
  count    = "${var.node_count}"
  template = "${file("${path.module}/files/${var.metadata_template}")}"

  vars = {
    hostname       = "${var.node_prefix}${var.node_name}${count.index + 1}"
    network_config = "${base64encode("${data.template_file.network_config.*.rendered[count.index]}")}"
  }
}

data "template_file" "network_config" {
  count    = "${var.node_count}"
  template = "${file("${path.module}/files/${var.network_config_template}")}"

  vars = {
    ip_address        = "${var.node_ips[count.index]}"
    gateway           = "${var.node_gateway}"
    network_interface = "${var.node_network_interface}"
    dns               = "${jsonencode(split(",", var.node_dns))}"
    domain_name       = "${var.node_domain_name}"
  }
}

resource "vsphere_compute_cluster_vm_anti_affinity_rule" "node_anti_affinity" {
  count               = var.anti_affinity_enabled ? 1 : 0
  name                = "${var.node_prefix}${var.node_name}-anti-affinity"
  compute_cluster_id  = data.vsphere_compute_cluster.node_cluster.id
  virtual_machine_ids = vsphere_virtual_machine.nodes.*.id
}

resource "dns_a_record_set" "a_record" {
  count     = var.add_dns_record ? var.node_count : 0
  zone      = "${var.node_domain_name}."
  name      = "${var.node_prefix}${var.node_name}${count.index + 1}"
  addresses = ["${split("/", var.node_ips[count.index])[0]}"]
  ttl       = 3600
}
