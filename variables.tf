variable "vm" {}

variable "default_vm" {
  type = object(
    {
      name = string

      network_timeout = number
      domain          = string
      gateway         = string
      networks = list(object(
        {
          interface    = string
          port_group   = string
          ipv4_address = string
          nameservers  = string
        }
      ))
      disks = list(object(
        {
          size          = number
          template      = bool
          eagerly_scrub = bool
          thin          = bool
        }
      ))
      datastore = string
      template  = string

      customize                            = bool
      cloud_init                           = bool
      cloud_init_custom                    = bool
      cloud_config_template                = string
      metadata_template                    = string
      network_config_template              = string
      cloud_config_guestinfo_path          = string
      cloud_config_guestinfo_encoding_path = string
      cpus                                 = number
      memory                               = number
      tags                                 = map(list(string))
    }
  )

  default = {
    name            = "worker"
    network_timeout = 5
    domain          = "ad.balmerfamilyfarm.com"
    gateway         = null
    networks        = []
    disks           = []
    datastore       = "vsanDatastore"
    template        = "centos7-2020-12-19"

    customize                            = false
    cloud_init                           = true
    cloud_init_custom                    = false
    cloud_config_template                = "centos-cloud-config.tpl"
    metadata_template                    = "centos-metadata.tpl"
    network_config_template              = "centos-network-config.tpl"
    cloud_config_guestinfo_path          = "cloud-init.config.data"
    cloud_config_guestinfo_encoding_path = "cloud-init.data.encoding"

    cpus   = 2
    memory = 4096

    tags = {}
  }
}

variable "cluster_settings" {
  type = object(
    {
      datacenter = string
      cluster    = string
      pool       = string
    }
  )
}

variable "ssh_keys" {
  description = "SSH keys to add to the node."
  type        = list(string)
}

variable "cloud_user" {
  description = "Initial user for the node."
  default     = "ansible"
}

variable "cloud_pass" {
  description = "Initial user hashed password for the node."
}
