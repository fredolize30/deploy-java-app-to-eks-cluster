# Create a KMS key for backup encryption
resource "aws_kms_key" "backup_key" {
  description = "KMS key for EKS backup encryption"
  tags = {
    Name = "${var.eks_cluster_name}-backup-key"
  }
}

# AWS Backup vault with KMS encryption
resource "aws_backup_vault" "eks_vault" {
  name          = "${var.eks_cluster_name}-backup-vault"
  kms_key_arn = aws_kms_key.backup_key.arn
  tags = {
    Environment = "production"
  }
}

# Simple backup plan with daily backups
resource "aws_backup_plan" "eks_backup" {
  name = "${var.eks_cluster_name}-backup-plan"

  rule {
    rule_name         = "daily_backup"
    target_vault_name = aws_backup_vault.eks_vault.name
    schedule          = "cron(0 1 * * ? *)" # Daily at 1 AM UTC

    lifecycle {
      delete_after = 14 # Keep backups for 14 days
    }
  }
}

# Basic IAM role for AWS Backup
resource "aws_iam_role" "backup_role" {
  name = "${var.eks_cluster_name}-backup-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "backup.amazonaws.com"
        }
      }
    ]
  })
}

# Attach basic backup policy
resource "aws_iam_role_policy_attachment" "backup_policy" {
  policy_arn = "arn:aws:iam::aws:policy/service-role/AWSBackupServiceRolePolicyForBackup"
  role       = aws_iam_role.backup_role.name
}

# Basic backup selection
resource "aws_backup_selection" "eks_backup" {
  name         = "${var.eks_cluster_name}-backup-selection"
  plan_id      = aws_backup_plan.eks_backup.id
  iam_role_arn = aws_iam_role.backup_role.arn

  selection_tag {
    type  = "STRINGEQUALS"
    key   = "backup"
    value = "true"
  }

  # Use the EKS cluster ARN directly
  resources = [module.eks.cluster_arn]
}
