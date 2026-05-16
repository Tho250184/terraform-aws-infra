# 1. Cấu hình nhà cung cấp dữ liệu AWS
provider "aws" {
  region     = "ap-southeast-1"
  access_key = "mock_access_key"
  secret_key = "mock_secret_key"

# 3 dòng cốt lõi ép Terraform chạy chế độ Ngoại tuyến (Offline/Mock)
  skip_metadata_api_check     = true
  skip_requesting_account_id  = true
  skip_credentials_validation = true

# Chỉ định tất cả các dịch vụ liên quan phải gọi vào Docker LocalStack (Cổng 4566)
  endpoints {
    ec2 = "http://localhost:4566"
    sts = "http://localhost:4566"
  }
}

# 2. Khởi tạo mạng chính (VPC)
resource "aws_vpc" "lab_vpc" {
  cidr_block           = "10.0.0.0/16"
  enable_dns_hostnames = true
  
  tags = {
    Name        = "Gia-Lap-VPC-Company"
    Environment = "Lab-Test"
  }
}

# 3. Tạo phân vùng mạng nội bộ (Subnet)
resource "aws_subnet" "lab_subnet" {
  vpc_id            = aws_vpc.lab_vpc.id
  cidr_block        = "10.0.1.0/24"
  availability_zone = "ap-southeast-1a"

  tags = {
    Name = "Lab-Subnet-Internal"
  }
}

# 4. Tạo Luật tường lửa (Security Group)
resource "aws_security_group" "lab_firewall" {
  name        = "lab-allow-ansible"
  description = "Chan/Mo cong bao mat thu nghiem"
  vpc_id      = aws_vpc.lab_vpc.id

  # Chỉ cho phép máy Ansible (giả lập là IP máy WSL của bạn) kết nối cổng WinRM 5985
  ingress {
    from_port   = 5985
    to_port     = 5985
    protocol    = "tcp"
    cidr_blocks = ["10.0.1.50/32"] 
  }

  egress {
    from_port   = 0
    to_port     = 0
    protocol    = "-1"
    cidr_blocks = ["0.0.0.0/0"]
  }
}
