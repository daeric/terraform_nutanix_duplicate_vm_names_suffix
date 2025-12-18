# Terraform Nutanix VM (example)

This repository contains a small Terraform configuration that demonstrates creating a Nutanix AHV virtual machine using the `nutanix` provider (v2.x). It includes a guest-customization (cloud-init) payload, a guard that detects duplicate VM names, and logic to append a short randomized suffix when a name collision is detected.

Use this repo as a testing/demo workspace — do not commit secrets or credentials.

## What this repo does

- Creates a VM from an image found via `data "nutanix_images_v2"`.
- Attaches a NIC using a subnet discovered via `data "nutanix_subnets_v2"`.
- Applies cloud-init user data from `files/config.yaml` (rendered with the final VM name).
- If a VM with the requested name already exists in Prism Central, the config appends a short hex suffix (3 bytes -> 6 hex chars) to avoid collision and still create the VM.
- Outputs the final VM name plus a short human-readable note explaining any name change.

## Files

- `main.tf` - primary Terraform configuration (data sources, VM resource, random id logic, locals).
- `providers.tf` - provider configuration and required providers.
- `variables.tf` / `terraform.tfvars` - variable definitions and example values.
- `files/config.yaml` - cloud-init template used for guest customization. The template expects a `vm_name` variable.
- `outputs.tf` - Terraform outputs (final VM name and explanatory note).

## Requirements

- Terraform 1.0+ (this repository was tested with Terraform 1.12.1 in this workspace).
- Nutanix Prism Central accessible from where you run Terraform.
- The `nutanix` provider is used (v2.x). The `null` and `random` providers are also used for helper logic.

## How duplicate names are handled

This configuration uses a `data "nutanix_virtual_machines_v2" "existing"` lookup to check for an existing VM with the requested name. If a match is found, Terraform generates a short randomized suffix using `random_id` and appends it to the requested name. The VM is then created with that final name.

Rationale: It avoids mid-create failures caused by collisions and avoids renaming the VM after creation. The cloud-init `hostname` is rendered from the final name so the guest matches the Prism name.

## Outputs

- `vm_name` — the actual name of the VM created in Prism Central.
- `vm_name_note` — a small human-readable message explaining why the final name may differ from the requested `vm_name`.
