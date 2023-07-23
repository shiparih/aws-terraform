data "aws_security_groups" "default_security_group" {
  filter {
    name   = "vpc-id"
    values = ["vpc-37b2775c"]
  }
}
