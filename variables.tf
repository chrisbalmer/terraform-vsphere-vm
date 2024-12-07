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

      userdata_template                    = string
      metadata_template                    = string
      cpus                                 = number
      memory                               = number
      firmware                             = string
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

    userdata_template                    = "centos-cloud-config.tpl"
    metadata_template                    = "centos-metadata.tpl"

    cpus   = 2
    memory = 4096
    firmware = "efi"

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
  default = []
}

variable "cloud_user" {
  description = "Initial user for the node."
  default     = "ansible"
}

variable "cloud_pass" {
  description = "Initial user hashed password for the node."
  default = ""
}

variable "userdata_template" {
  default = ""
}

variable "userdata" {
  default = ""
}

variable "file_data" {
  type = list(object(
    {
      filename = string
      contents = string
    }
  ))
  default = []
}