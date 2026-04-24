output "private_key" {
  value     = tls_private_key.key-pair.private_key_pem
  sensitive = true
}
output "ec2_instance_id" {
  value = aws_instance.ec2_instance.id
}
# output "rds_instance_id" {
#   value = aws_db_instance.app_db.id
# }
# output "rds_endpoint" {
#   value = aws_db_instance.app_db.endpoint
# }
output "ec2_public_ip" {
  value = aws_instance.ec2_instance.public_ip
}