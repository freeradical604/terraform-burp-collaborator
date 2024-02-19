provider "aws" {
  region = "${var.region}"
  profile = "${var.profile}"
}

data "aws_ami" "ubuntu" {
  most_recent = true

  filter {
    name   = "name"
    values = ["ubuntu/images/hvm-ssd/ubuntu-jammy-22.04-amd64-server-*"]
  }

  filter {
    name   = "virtualization-type"
    values = ["hvm"]
  }

  owners = ["099720109477"] # Canonical
}

resource "aws_ebs_encryption_by_default" "burp" {
  enabled = true
}

resource "aws_key_pair" "key" {
  key_name = "${var.key_name}"
  public_key = "${file("${var.key_name}.pub")}"
}

data "aws_eip" "collaborator" {
  public_ip = "54.212.9.21"
}

resource "aws_eip_association" "collaborator" {
  instance_id   = aws_instance.collaborator.id
  allocation_id = data.aws_eip.collaborator.id
}

resource "aws_instance" "collaborator" {
  ami = "${data.aws_ami.ubuntu.id}"
  instance_type = "${var.instance_type}"
  key_name = "${aws_key_pair.key.key_name}"

  security_groups = [
    "${aws_security_group.collaborator_sg.name}"
  ]

provisioner "file" {
    source      = "rules.v4"
    destination = "/tmp/rules.v4"
  }
provisioner "file" {
    source      = "10periodic"
    destination = "/tmp/10periodic"
  }
provisioner "file" {
    source      = "50unattended-upgrades"
    destination = "/tmp/50unattended-upgrades"
  }

#provisioner "file" {
#    source      = "install_splunk.sh"
#    destination = "/tmp/install_splunk.sh"
#  }

  provisioner "local-exec" {
    command = "sleep 45 && ansible-galaxy install -r requirements.yml && echo \"[collaborator]\n${aws_instance.collaborator.public_ip} ansible_connection=ssh ansible_ssh_user=ubuntu ansible_ssh_private_key_file=${var.key_name}\" > inventory && ANSIBLE_HOST_KEY_CHECKING=false ansible-playbook -i inventory playbook.yml --extra-vars \"server_hostname=${var.server_name} burp_server_domain=${var.burp_zone}.${var.zone} burp_local_address=${aws_instance.collaborator.private_ip} burp_public_address=${data.aws_eip.collaborator.public_ip}\""
  }


provisioner "file" {
    source      = "50unattended-upgrades"
    destination = "/tmp/50unattended-upgrades"
  }

provisioner "file" {
    source      = "burp.pk1-valid"
    destination = "/tmp/burp.pk1"
  }

provisioner "file" {
    source      = "burp.crt-valid"
    destination = "/tmp/burp.crt"
  }

provisioner "file" {
    source      = "burp_issuer.pem-valid"
    destination = "/tmp/burp_issuer.pem"
  }

 provisioner "remote-exec" {
    inline = [
      "sudo apt-get update -y",   # Update package lists (for Ubuntu/Debian)
      "echo iptables-persistent iptables-persistent/autosave_v4 boolean true | sudo debconf-set-selections",
      "echo iptables-persistent iptables-persistent/autosave_v6 boolean true | sudo debconf-set-selections",
      "sudo apt-get install -y iptables-persistent",   
      "sudo cp /tmp/rules.v4 /etc/iptables/rules.v4",
      "sudo systemctl restart iptables",
      "sudo openssl pkcs8 -topk8 -inform PEM -outform PEM -in /tmp/burp.pk1 -out /etc/burp/burp.pk8 -nocrypt",
      "sudo cp /tmp/burp.crt /etc/burp/burp.crt",
      "sudo cp /tmp/burp_issuer.pem /etc/burp/intermediate.crt",
      "sudo adduser --shell /bin/nologin --no-create-home --system collaborator",
      "sudo rm /tmp/burp*",
      "sudo chown -R collaborator /etc/burp",
      "sudo chown -R collaborator /usr/share/burp",
      "sudo systemctl stop burp",
      "sudo systemctl enable burp",
      "sudo systemctl start burp",
      "sudo apt-get install unattended-upgrades",
      "sudo cp /tmp/10periodic /etc/apt/apt.conf.d/10periodic",
      "sudo cp /tmp/50unattended-upgrades /etc/apt/apt.conf.d/50unattended-upgrades",
#      "sudo chmod +x /tmp/install_splunk.sh",
#      "sudo /tmp/install_splunk.sh",
    ]
  }

  connection {
    type        = "ssh"
    host        = "${aws_instance.collaborator.public_ip}"
    user        = "ubuntu"
    private_key = file("burpkeypair")  # Adjust the path to your private key
  }

}

resource "aws_security_group" "collaborator_sg" {
  name = "collaborator-sg"
  description = "Allow access to Burp Collaborator services"

  # SSH
  ingress {
    from_port = 22
    to_port = 22
    protocol = "tcp"
    cidr_blocks = ["${var.permitted_ssh_cidr_block}"]
  }

  # SMTP
  ingress {
    from_port = 25
    to_port = 25
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS
  ingress {
    from_port = 53
    to_port = 53
    protocol = "udp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # DNS
  ingress {
    from_port = 53
    to_port = 53
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTP
  ingress {
    from_port = 80
    to_port = 80
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # HTTPS
  ingress {
    from_port = 443
    to_port = 443
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SMTPS
  ingress {
    from_port = 465
    to_port = 465
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # SMTP
  ingress {
    from_port = 587
    to_port = 587
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Polling (HTTP)
  ingress {
    from_port = 9090
    to_port = 9090
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  # Polling (HTTPS)
  ingress {
    from_port = 9443
    to_port = 9443
    protocol = "tcp"
    cidr_blocks = ["54.70.141.160/32", "76.130.50.150/32"]
  }

  # splunk forwarder
  ingress {
    from_port = 8089
    to_port = 8089
    protocol = "tcp"
    cidr_blocks = ["0.0.0.0/0"]
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}

data "aws_route53_zone" "burp" {
  name = "${var.zone}"
}

resource "aws_route53_record" "a" {
  zone_id = "${data.aws_route53_zone.burp.zone_id}"
  name    = "${var.burp_zone}.${var.zone}"
  type    = "A"
  ttl     = "5"
  #records = ["${data.aws_eip.collaborator.public_ip}"]
  records = ["${aws_instance.collaborator.public_ip}"]
}

resource "aws_route53_record" "ns" {
 depends_on = [aws_route53_record.a] 
 zone_id = "${data.aws_route53_zone.burp.zone_id}"
 name    = "${var.burp_zone}.${var.zone}"
 type    = "NS"
 ttl     = "5"
  records = ["${var.burp_zone}.${var.zone}."]
}
