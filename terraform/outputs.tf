output "sonarqube_public_ip" {
    description = "Public ip for sonarqube ec2 instance"
    value = aws_instance.sonarqube.public_ip
}

output "eks_cluster_name" {
    description = "Name of eks Cluster"
    value = module.eks.cluster_name
}

output "eks_cluster_endpoint" {
    description = "EKS Cluster Endpoint"
    value = module.eks.cluster_endpoint
}