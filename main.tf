data "nutanix_clusters_v2" "Test" {
  filter = "name eq 'Test'"
}

data "nutanix_images_v2" "rocky" {
  filter = "startswith(name,'rocky')"
  page   = 0
  limit  = 10
}

data "nutanix_subnets_v2" "default" {
  filter = "name eq 'default'"
}

data "nutanix_virtual_machines_v2" "existing" {
  filter = "name eq '${var.vm_name}'"
  page   = 0
  limit  = 1
}

# Generate a short randomized suffix when we need to disambiguate names
resource "random_id" "suffix" {
  # only create a random id when a duplicate exists
  count       = length(data.nutanix_virtual_machines_v2.existing.vms) > 0 ? 1 : 0
  byte_length = 3
}

# Final VM name: if an existing VM with the same name is found, append the random
# suffix so the resource can be created without duplicate.
locals {
  vm_name_final = length(data.nutanix_virtual_machines_v2.existing.vms) > 0 ? "${var.vm_name}-${random_id.suffix[0].hex}" : var.vm_name
  vm_name_note  = length(data.nutanix_virtual_machines_v2.existing.vms) > 0 ? "Requested name '${var.vm_name}' already existed; created VM as '${var.vm_name}-${random_id.suffix[0].hex}'." : "Requested name '${var.vm_name}' was available and used as-is."
}

resource "nutanix_virtual_machine_v2" "test" {
  name                 = local.vm_name_final
  num_sockets          = 1
  num_cores_per_socket = 4
  memory_size_bytes    = 8 * 1024 * 1024 * 1024 # 8 GiB

  cluster {
    ext_id = data.nutanix_clusters_v2.Test.cluster_entities[0].ext_id
  }

  guest_customization {
    config {
      cloud_init {
        cloud_init_script {
          user_data {
            value = base64encode(templatefile("${path.module}/files/config.yaml", { vm_name = local.vm_name_final }))
          }
        }
      }
    }
  }

  disks {
    disk_address {
      bus_type = "SCSI"
      index    = 0
    }
    backing_info {
      vm_disk {
        data_source {
          reference {
            image_reference {
              image_ext_id = data.nutanix_images_v2.rocky.images[0].ext_id
            }
          }
        }
      }
    }
  }

  nics {
    network_info {
      nic_type = "NORMAL_NIC"
      subnet {
        ext_id = data.nutanix_subnets_v2.default.subnets[0].ext_id
      }
      vlan_mode = "ACCESS"
    }
  }

    power_state = "OFF"
  }
