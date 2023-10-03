variable "region" {
  description = "The AWS region."
}

variable "profile" {
  description = "The AWS credentials profile to use."
  default     = "default"
}

variable "availability_zone" {
  description = "The AWS availability zone to use."
}

variable "instance_type" {
  description = "The AWS instance type to use."
}

variable "key_name" {
  description = "The AWS SSH keypair to use."
}

variable "server_name" {
  description = "The name of the server (will be used in the Name tag on AWS)."
}

variable "zone" {
  description = "Primary DNS zone."
}

variable "burp_zone" {
  description = "Collaborator zone to create collaborator server in."
}

variable "permitted_ssh_cidr_block" {
  description = "IP addresses from which SSH connections will be allowed. Default is all, which will be noisy."
  default = "0.0.0.0/0"
}

variable "domain_registered_with_other" {
  description = "Is the domain is registered with someone other than AWS set this to true as we will need to create the hosted zone"
  default = "false"

}
variable "name" {
  description = "Name used for Terraform resources."
  type        = string
}

variable "domains" {
  description = "Domain names to apply. The first domain provided will be the subject CN of the certificate, and all domains will be Subject Alternative Names on the certificate."
  type        = list(string)
  default     = ["collab.portsmine.com", "*.collab.portsmine.com"]
}

variable "email_address" {
  description = "Email used for Let's Encrypt registration and recovery contact."
  type        = string
}

variable "hosted_zone_id" {
  description = "Route53 Hosted Zone ID for the domains."
  type        = string
}

variable "staging" {
  description = "Use Let's Encrypt staging environment (use this while testing)."
  type        = string
  default     = true
}
