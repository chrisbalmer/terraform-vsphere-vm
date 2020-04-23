output "vm_name" {
  value = "${vsphere_virtual_machine.nodes.*.name}"
}
