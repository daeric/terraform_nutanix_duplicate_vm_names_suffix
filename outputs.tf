
output "vm_name" {
  description = "Final VM name created in Nutanix"
  value       = nutanix_virtual_machine_v2.test.name
}
output "vm_name_note" {
  description = "Explanation when the final VM name differs from the requested name"
  value = local.vm_name_note
}