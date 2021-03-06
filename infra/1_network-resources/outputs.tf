output "public_route_table_association_id" {
    value = aws_vpc.main
    description = "vpc details"
}

output "sub_a_web" {
    value = aws_subnet.sub_a_web
    description = "subnet for web in az a, to deploy frontend"
}

output "sub_b_web" {
    value = aws_subnet.sub_b_web
    description = "subnet for web in az b, to deploy frontend"
}

output "sub_a_app" {
    value = aws_subnet.sub_a_app
    description = "subnet for web in az a, to deploy backend"
}

output "sub_b_app" {
    value = aws_subnet.sub_b_app
    description = "subnet for web in az b, to deploy backend"
}

output "sub_a_db" {
    value = aws_subnet.sub_a_db
    description = "subnet for web in az a, to deploy db"
}

output "sub_b_db" {
    value = aws_subnet.sub_b_db
    description = "subnet for web in az b, to deploy db"
}

output "sub_a_public" {
    value = aws_subnet.sub_a_public
    description = "public subnet in az a, to host loadbalancer"
}

output "sub_b_public" {
    value = aws_subnet.sub_b_public
    description = "public subnet in az b, to host loadbalancer"
}

output "vpc" {
    value = aws_vpc.main
    description = "vpc details"
}