resource "aws_security_group" "endpoint_ec2" {
  name   = "endpoint-ec2"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "endpoint_ec2_443" {
  security_group_id = aws_security_group.endpoint_ec2.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [for s in data.aws_subnet.total : s.cidr_block]
}

resource "aws_vpc_endpoint" "ec2" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-southeast-1.ec2"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.aws_subnet_ids.web.ids

  security_group_ids = [aws_security_group.endpoint_ec2.id]
}


resource "aws_security_group" "endpoint_ecr" {
  name   = "endpoint-ecr"
  vpc_id = var.vpc_id
}

resource "aws_security_group_rule" "endpoint_ecr_443" {
  security_group_id = aws_security_group.endpoint_ecr.id
  type              = "ingress"
  from_port         = 443
  to_port           = 443
  protocol          = "tcp"
  cidr_blocks       = [for s in data.aws_subnet.total : s.cidr_block]
}

resource "aws_vpc_endpoint" "ecr_api" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-southeast-1.ecr.api"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.aws_subnet_ids.web.ids

  security_group_ids = [
    aws_security_group.endpoint_ecr.id,
  ]
}

resource "aws_vpc_endpoint" "ecr_dkr" {
  vpc_id              = var.vpc_id
  service_name        = "com.amazonaws.ap-southeast-1.ecr.dkr"
  vpc_endpoint_type   = "Interface"
  private_dns_enabled = true
  subnet_ids          = data.aws_subnet_ids.web.ids

  security_group_ids = [
    aws_security_group.endpoint_ecr.id,
  ]
}

resource "aws_vpc_endpoint" "s3" {
  count             = var.create_s3_vpce ? 1 : 0
  vpc_id            = var.vpc_id
  service_name      = "com.amazonaws.ap-southeast-1.s3"
  vpc_endpoint_type = "Gateway"
  route_table_ids   = [aws_route_table.private.id]
}

resource "aws_route_table" "private" {
  # no need for_each, which creates 1 route table per subnet
  #   for_each = data.aws_subnet_ids.total.ids
  vpc_id = var.vpc_id
}

resource "aws_route_table_association" "private" {
  count = var.create_s3_vpce ? length(data.aws_subnet_ids.total.ids) : 0
  #   for_each       = data.aws_subnet_ids.total.ids
  subnet_id      = tolist(data.aws_subnet_ids.total.ids)[count.index]
  route_table_id = aws_route_table.private.id
}
