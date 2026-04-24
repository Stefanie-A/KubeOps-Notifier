# resource "aws_db_subnet_group" "db_subnet" {
#   name       = "app-database"
#   subnet_ids = [aws_subnet.private_subnet[0].id, aws_subnet.private_subnet[1].id]

#   tags = {
#     Name = "My DB subnet group"
#   }
# }

# resource "aws_db_instance" "app_db" {
#   identifier             = "app-database"
#   db_name                = "appdb"
#   instance_class         = "db.t3.micro"
#   allocated_storage      = 10
#   engine                 = "postgres"
#   username               = var.db_username
#   password               = var.db_password
#   db_subnet_group_name   = aws_db_subnet_group.db_subnet.name
#   vpc_security_group_ids = [aws_security_group.rds_sg.id]
#   publicly_accessible    = false
#   skip_final_snapshot    = true
#   # final_snapshot_identifier = "db-snap-${t}"
#   backup_retention_period = 7
# }

# # Security group for the RDS instance
# resource "aws_security_group" "rds_sg" {
#   vpc_id = aws_vpc.main.id

#   ingress {
#     from_port       = 5432
#     to_port         = 5432
#     protocol        = "tcp"
#     security_groups = [aws_security_group.ec2_sg.id] # Allow access from EC2 security group
#   }
#   egress {
#     from_port   = 0
#     to_port     = 0
#     protocol    = -1
#     cidr_blocks = ["0.0.0.0/0"]
#   }
#   tags = {
#     Name = "rds-security-group"
#   }
# }