resource "random_pet" "master_username" {
  keepers = {
    name = var.name
  }

  length = 1
}
