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
    template        = "centos8-2020-06-10"

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

variable "initial_key" {
  description = "The initial SSH key to allow access to the node."
}

variable "cloud_user" {
  description = "Initial user for the node."
  default     = "ansible"
}

variable "cloud_pass" {
  description = "Initial user hashed password for the node."
}
