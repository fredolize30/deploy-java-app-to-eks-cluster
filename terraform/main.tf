# VPC
resource "aws_vpc" "main" {
    cidr_block = "10.0.0.0/16"
    tags = {
        Name = "devsecops-vpc"
    }
  
}

# Subnets
resource "aws_subnet" "public" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.1.0/24"
    availability_zone = "us-east-1a"
    tags = {
        Name = "devsecops-public-subnet"
    }
  
}

resource "aws_subnet" "private" {
    vpc_id = aws_vpc.main.id
    cidr_block = "10.0.2.0/24"
    availability_zone = "us-east-1b"
    tags = {
        Name = "devsecops-private-subnet"
    }
  
}

# Elastic ip for nat gateway
resource "aws_eip" "nat" {
    associate_with_private_ip = true
    tags = {
        Name = "devsecops-nat-eip" 
    }
}

# NAT Gateway for private subnet
resource "aws_nat_gateway" "nat" {
    allocation_id = aws_eip.nat.id
    subnet_id     = aws_subnet.public.id # Nat gateway should be in public subnet
    tags = {
        Name = "devsecops-nat-gateway" 
    }
}

# Route table for private subnet
resource "aws_route_table" "private" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0" # Route all outbound traffic to the NAT gateway
        nat_gateway_id = aws_nat_gateway.nat.id
    }

    tags = {
        Name = "devsecops-private-rt"
    }

}

# Associate private subnet with private route table
resource "aws_route_table_association" "private" {
    subnet_id = aws_subnet.private.id
    route_table_id = aws_route_table.private.id
  
}

# Internet Gateway for public subnet 
resource "aws_internet_gateway" "igw" {
    vpc_id = aws_vpc.main.id
    tags = {
        Name = "devsecops-igw"
    }
  
}

# Route table for public table
resource "aws_route_table" "public" {
    vpc_id = aws_vpc.main.id
    route {
        cidr_block = "0.0.0.0/0"
        gateway_id = aws_internet_gateway.igw.id
    }

    tags = {
        Name = "devsecops-public-rt"
    }    
  
}

# Associate public subnet with public route table
resource "aws_route_table_association" "public" {
    subnet_id = aws_subnet.public.id
    route_table_id = aws_route_table.public.id
  
}

# This creates an ec2 instance for sonarqube
resource "aws_instance" "sonarqube" {
    ami = var.ami
    instance_type = var.instance_type
    subnet_id = aws_subnet.public.id
    vpc_security_group_ids = [ var.security_group_id ]
    tags = {
        Name = "sonarqube"
    }
  
}

# Security Group for sonarqube
resource "aws_security_group" "sonarqube" {
    name = "sonarqube-sg"
    description = "Allow port 9000 and SSH inbound traffic"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 9000
        to_port = 9000
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }
  
}

# EKS cluster
module "eks" {
    source = "terraform-aws-modules/eks/aws"
    version = "~> 19.0"

    cluster_name = var.eks_cluster_name
    cluster_version = var.eks_cluster_version

    vpc_id = aws_vpc.main.id
    subnet_ids = [aws_subnet.private.id]

    # Update IAM role configuration
    iam_role_use_name_prefix = false
    create_iam_role = true
    iam_role_name = "${var.eks_cluster_name}-cluster-role"
    
    # Use separate policy attachments instead of inline policies
    attach_cluster_encryption_policy = true
    cluster_encryption_policy_name = "${var.eks_cluster_name}-encryption"

    eks_managed_node_groups = {
        workers = {
            instance_type = "t2.medium"
            min_size      = 1
            max_size      = 3
            vpc_security_group_ids = [aws_security_group.eks_worker_nodes.id]
        }
    }

    tags = {
        Environment = "devsecops"
        backup      = "true"
    }
}

# Security Group for EKS Worker Nodes
resource "aws_security_group" "eks_worker_nodes" {
    name = "eks-worker-nodes-sg"
    description = "Allow traffic to EKS worker nodes"
    vpc_id = aws_vpc.main.id

    ingress {
        from_port = 443
        to_port = 443
        protocol = "tcp"
        security_groups = [module.eks.cluster_security_group_id]  # Reference the auto-created EKS cluster security group
    }

    ingress {
        from_port = 0
        to_port = 65535
        protocol = "tcp"
        self = true
    }

    ingress {
        from_port = 22
        to_port = 22
        protocol = "tcp"
        cidr_blocks = ["0.0.0.0/0"]
    }   

    egress {
        from_port = 0
        to_port = 0
        protocol = "-1"
        cidr_blocks = ["0.0.0.0/0"]
    }

    tags = {
        Name = "eks-worker-nodes-sg"
    } 
}


