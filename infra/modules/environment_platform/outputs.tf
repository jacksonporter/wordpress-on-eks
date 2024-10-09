output "endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "kubeconfig-certificate-authority-data" {
  value = aws_eks_cluster.this.certificate_authority[0].data
}

output "_cluster_auth_token" {
  value     = data.aws_eks_cluster_auth.current.token
  sensitive = true
}

output "cluster_endpoint" {
  value = aws_eks_cluster.this.endpoint
}

output "base64_decoded_cluster_ca_certificate" {
  value = base64decode(aws_eks_cluster.this.certificate_authority[0].data)
}
