provider "acme" {
  server_url = "https://acme-staging-v02.api.letsencrypt.org/directory"
#  server_url = "https://acme-v02.api.letsencrypt.org/directory"
}

data "aws_route53_zone" "base_domain" {
  name = "portsmine.com" # TODO put your own DNS in here!
}

resource "tls_private_key" "private_key" {
  algorithm = "RSA"
}

resource "acme_registration" "registration" {
  account_key_pem = tls_private_key.private_key.private_key_pem
  email_address   = "null@portsmine.com" # TODO put your own email in here!
}


resource "acme_certificate" "certificate" {
  account_key_pem           = acme_registration.registration.account_key_pem
  common_name               = "collab.${data.aws_route53_zone.base_domain.name}"
  subject_alternative_names = ["*.collab.${data.aws_route53_zone.base_domain.name}"]

  dns_challenge {
    provider = "route53"

    config = {
      AWS_HOSTED_ZONE_ID = data.aws_route53_zone.base_domain.zone_id
    }

  }

  depends_on = [acme_registration.registration]
}

resource "local_file" "private_key" {
    content  = nonsensitive(lookup(acme_certificate.certificate, "private_key_pem"))
    filename = "burp.pk1"
}

resource "local_file" "public_key" {
    content  = lookup(acme_certificate.certificate, "certificate_pem")
    filename = "burp.crt"
}

resource "local_file" "issuer_key" {
    content  = lookup(acme_certificate.certificate, "issuer_pem")
    filename = "burp_issuer.pem"
}

