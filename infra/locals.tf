# Locals shared by several files (the <name_prefix>-<env> name)
locals {
  # <name_prefix>-<env>, used by every file
  name = "${var.name_prefix}-${var.env}"
}
