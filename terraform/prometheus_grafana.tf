# Prometheus Helm Release
resource "helm_release" "prometheus" {
  provider = helm
  name       = "prometheus"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "prometheus"
  namespace  = "monitoring" # Use a single namespace for monitoring tools
  create_namespace = true    # Create the namespace if it doesn't exist

  set {
    name  = "server.service.type"
    value = "LoadBalancer" # Expose Prometheus via a LoadBalancer
  }

  set {
    name  = "server.persistentVolume.enabled"
    value = "true" # Enable persistent storage for Prometheus data
  }

  set {
    name  = "alertmanager.persistentVolume.enabled"
    value = "true" # Enable persistent storage for Alertmanager
  }

  set {
    name  = "nodeExporter.enabled"
    value = "true" # Enable Node Exporter for node-level metrics
  }

  set {
    name  = "pushgateway.enabled"
    value = "false" # Disable Pushgateway if not needed
  }

  # Add EKS monitoring configurations
  set {
    name  = "serviceAccounts.server.annotations.eks\\.amazonaws\\.com/role-arn"
    value = aws_iam_role.prometheus.arn  # IAM role for Prometheus to access EKS
  }

  set {
    name  = "server.remoteWrite[0].url"
    value = "http://prometheus-server.monitoring.svc.cluster.local/api/v1/write"
  }

  # Enable ServiceMonitor CRD
  set {
    name  = "prometheusOperator.createCustomResource"
    value = "true"
  }

  # Configure EKS service discovery
  set {
    name  = "server.service.serviceMonitor.enabled"
    value = "true"
  }

  # Add EKS scrape configs
  values = [
    <<-EOF
    extraScrapeConfigs: |
      - job_name: 'kubernetes-apiservers'
        kubernetes_sd_configs:
        - role: endpoints
        scheme: https
        tls_config:
          ca_file: /var/run/secrets/kubernetes.io/serviceaccount/ca.crt
        bearer_token_file: /var/run/secrets/kubernetes.io/serviceaccount/token
        relabel_configs:
        - source_labels: [__meta_kubernetes_namespace, __meta_kubernetes_service_name, __meta_kubernetes_endpoint_port_name]
          action: keep
          regex: default;kubernetes;https

      - job_name: 'kubernetes-nodes'
        kubernetes_sd_configs:
        - role: node
        relabel_configs:
        - action: labelmap
          regex: __meta_kubernetes_node_label_(.+)

      - job_name: 'kubernetes-pods'
        kubernetes_sd_configs:
        - role: pod
        relabel_configs:
        - source_labels: [__meta_kubernetes_pod_annotation_prometheus_io_scrape]
          action: keep
          regex: true
    EOF
  ]
}

# IAM role for Prometheus
resource "aws_iam_role" "prometheus" {
  name = "prometheus-role"

  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRole"
        Effect = "Allow"
        Principal = {
          Service = "monitoring.amazonaws.com"
        }
      }
    ]
  })
}

# IAM policy for Prometheus
resource "aws_iam_role_policy" "prometheus" {
  name = "prometheus-policy"
  role = aws_iam_role.prometheus.id

  policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Effect = "Allow"
        Action = [
          "eks:DescribeCluster",
          "eks:ListClusters",
          "ec2:DescribeInstances",
          "ec2:DescribeTags",
          "cloudwatch:GetMetricData",
          "cloudwatch:ListMetrics"
        ]
        Resource = "*"
      }
    ]
  })
}

# Grafana Helm Release
resource "helm_release" "grafana" {
  provider = helm
  name       = "grafana"
  repository = "https://grafana.github.io/helm-charts"
  chart      = "grafana"
  namespace  = "monitoring" # Use the same namespace as Prometheus
  create_namespace = true    # Create the namespace if it doesn't exist

  set {
    name  = "service.type"
    value = "LoadBalancer" # Expose Grafana via a LoadBalancer
  }

  set {
    name  = "adminPassword"
    value = "admin" # Set a secure password for Grafana admin user
  }

  set {
    name  = "persistence.enabled"
    value = "true" # Enable persistent storage for Grafana data
  }

  set {
    name  = "datasources.datasources\\.yaml.apiVersion"
    value = "1"
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].name"
    value = "Prometheus"  # Name shown in Grafana UI
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].type"
    value = "prometheus"  # Specifies Prometheus type datasource
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].url"
    value = "http://prometheus-server.monitoring.svc.cluster.local"  # Internal Kubernetes DNS name for Prometheus
  }

  set {
    name  = "datasources.datasources\\.yaml.datasources[0].access"
    value = "proxy"  # Grafana will proxy requests to Prometheus
  }
}
