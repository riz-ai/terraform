# Deploy ArgoCD using Helm
resource "helm_release" "argocd" {
  name       = "argocd"
  namespace  = var.namespace
  chart      = "argo-cd"
  repository = "https://argoproj.github.io/argo-helm"
  version    = "7.2.0"  

  values = [file("${var.git_repo_clone_directory}/argocd/values.yaml")]

  # Override global.domain in the values.yaml
  set {
    name  = "global.domain"
    value = var.argocd_host  
  }

  # Ingress setup for ArgoCD
  set {
    name  = "server.ingress.enabled"
    value = "true"
  }

  set {
    name  = "server.ingress.annotations.\"kubernetes.io/ingress.class\""
    value = "alb"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/scheme\""
    value = "internet-facing"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/certificate-arn\""
    value = var.acm_certificate_arn
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/group.name\""
    value = "staging-elb-ingress-group"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/target-type\""
    value = "ip"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/subnets\""
    value = join(",", var.alb_subnets)
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/backend-protocol\""
    value = "HTTP"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/listen-ports\""
    value = "[{\"HTTPS\":443}]"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/ssl-redirect\""
    value = "443"
  }

  set {
    name  = "server.ingress.annotations.\"alb.ingress.kubernetes.io/success-codes\""
    value = "200"
  }
}

