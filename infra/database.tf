resource "aws_db_subnet_group" "rds" {
  name = "${var.project_prefix}-rds-subnet-group"
  subnet_ids = [
    aws_subnet.private["private_ap_northeast_1a_rds"].id,
    aws_subnet.private["private_ap_northeast_1c_rds"].id
  ]

  tags = {
    Name = "${var.project_prefix}-rds-subnet-group"
  }
}

resource "aws_db_instance" "rds" {
  identifier = "${var.project_prefix}-rds"
  engine = "mysql"
  engine_version = "8.0.42"
  instance_class = "db.t4g.micro"
  allocated_storage = 20
  storage_type = "gp2"
  db_name = var.rds_db_name
  username = "admin"
  manage_master_user_password = true
  multi_az = false
  publicly_accessible = false
  backup_retention_period = 0
  skip_final_snapshot = true
  db_subnet_group_name = aws_db_subnet_group.rds.name
  vpc_security_group_ids = [aws_security_group.rds.id]

  tags = {
    Name = "${var.project_prefix}-rds-instance"
  }
}