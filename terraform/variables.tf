variable "ami" {
    description = "AMI ID"
    default = "ami-0c55b159cbfafe1f0"
}

variable "instance_type" {
    description = "Instance Type"
    default = "t2.micro"
}

variable "security_group_id" {
    description = "Security Group ID"
    default = "sg-0c7b6f6f7b6f7b6f0"
}

variable "eks_cluster_name" {
    description = "EKS Cluster Name"
    default = "devsecops-cluster"
    }

variable "eks_cluster_version" {
    description = "EKS Cluster Version"
    default = "1.27"
}