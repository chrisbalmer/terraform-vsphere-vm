variable "vsphere_datacenter" {
  description = "The datacenter in vCenter to deploy the node(s) to."
  default     = "the farm"
}

variable "vsphere_cluster" {
  description = "The cluster in the datacenter to deploy the node(s) to."
  default     = "operations"
}

variable "vsphere_resource_pool" {
  description = "The resouce pool to deploy the node(s) to."
  default     = "Resources"
}

variable "vsphere_datastore" {
  description = "The datastore to deploy the node(s) to."
  default     = "vsanDatastore"
}

variable "vsphere_network" {
  description = "The network to connect the node(s) to."
  default     = "vlan14-servers"
}

variable "vsphere_template" {
  description = "The template to use for creating the node(s)."
  default     = "centos7-2019-06-13"
}

variable "node_count" {
  description = "How many nodes of this type to create."
  default     = "1"
}

variable "node_prefix" {
  description = "The prefix for the full node name, i.e. dev, prod, etc"
  default     = "dev-"
}

variable "node_name" {
  description = "The name of the node, i.e. worker, master, etc"
  default     = "worker"
}

variable "node_disk_size" {
  description = "The size of the node disk drive in GB."
  default     = "30"
}
variable "node_ips" {
  description = "IP addresses to assign to the nodes."
  default = [
    "172.21.19.21/24",
    "172.21.19.22/24",
    "172.21.19.23/24"
  ]
}
variable "node_gateway" {
  description = "Gateway for the node."
  default     = "172.21.19.1"
}
variable "node_dns" {
  description = "DNS servers for the node."
  default     = "172.21.14.2,172.21.14.4"
}
variable "node_network_interface" {
  description = "Network interface used by the node."
  default     = "ens160"
}
variable "node_initial_key" {
  description = "The initial SSH key to allow access to the node."
}
variable "node_domain_name" {
  description = "The domain name to assign to the node."
  default     = "farm.oakops.io"
}

variable "node_cpus" {
  description = "How many CPUs to assign to the node."
  default     = 2
}

variable "node_memory" {
  description = "How much memory in MB to assign to the node."
  default     = 4096
}

variable "cloud_init" {
  description = "Whether or not to use the cloud-init system."
  default     = true
}

variable "cloud_init_custom" {
  description = "Whether or not to use a custom cloud-init setup like CoreOS and RancherOS use."
  default     = false
}

variable "cloud_config_template" {
  description = "The cloud config template to use."
  default     = "centos-cloud-config.tpl"
}

variable "metadata_template" {
  description = "The metadata template to use."
  default     = "centos-metadata.tpl"
}
variable "network_config_template" {
  description = "The network config template to use."
  default     = "centos-network-config.tpl"
}

variable "cloud_config_guestinfo_path" {
  description = "Custom guestinfo path for the cloud config data."
  default     = "cloud-init.config.data"
}

variable "cloud_config_guestinfo_encoding_path" {
  description = "Custom guestinfo path for the cloud config encoding type."
  default     = "cloud-init.data.encoding"
}

variable "cloud_user" {
  description = "Initial user for the node."
  default     = "ansible"
}

variable "cloud_pass" {
  description = "Initial user hashed password for the node."
  default     = ""
}

variable "anti_affinity_enabled" {
  description = "Whether or not to enable the anti affinity rule for these nodes."
  default     = false
}
