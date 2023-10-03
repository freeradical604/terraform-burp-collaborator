terraform {
  required_version = "~> 1.5.5"

  required_providers {
    acme = {
      source  = "vancluever/acme"
      version = "~> 2.5.3"
    }
  }
}
