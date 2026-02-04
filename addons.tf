# 1. AWS Load Balancer Controller
module "lb_controller_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "eks-lb-controller"
  attach_load_balancer_controller_policy = true
  oidc_providers = { main = { provider_arn = module.eks.oidc_provider_arn, namespace_service_accounts = ["kube-system:aws-load-balancer-controller"] } }
}

resource "helm_release" "lb_controller" {
  name       = "aws-load-balancer-controller"
  repository = "https://aws.github.io/eks-charts"
  chart      = "aws-load-balancer-controller"
  namespace  = "kube-system"
  set { name = "clusterName"; value = module.eks.cluster_name }
  set { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"; value = module.lb_controller_role.iam_role_arn }
}

# 2. ExternalDNS
module "external_dns_role" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"
  role_name = "external-dns"
  attach_external_dns_policy = true
  oidc_providers = { main = { provider_arn = module.eks.oidc_provider_arn, namespace_service_accounts = ["kube-system:external-dns"] } }
}

resource "helm_release" "external_dns" {
  name       = "external-dns"
  repository = "https://kubernetes-sigs.github.io/external-dns/"
  chart      = "external-dns"
  namespace  = "kube-system"
  set { name = "provider"; value = "aws" }
  set { name = "serviceAccount.annotations.eks\\.amazonaws\\.com/role-arn"; value = module.external_dns_role.iam_role_arn }
}

# 3. Cert-Manager
resource "helm_release" "cert_manager" {
  name       = "cert-manager"
  repository = "https://charts.jetstack.io"
  chart      = "cert-manager"
  namespace  = "cert-manager"
  create_namespace = true
  set { name = "installCRDs"; value = "true" }
}

# 4. Prometheus Stack
resource "helm_release" "prometheus" {
  name       = "kube-prometheus-stack"
  repository = "https://prometheus-community.github.io/helm-charts"
  chart      = "kube-prometheus-stack"
  namespace  = "monitoring"
  create_namespace = true
}
