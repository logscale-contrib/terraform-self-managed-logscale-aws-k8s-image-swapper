data "aws_caller_identity" "current" {
}

resource "helm_release" "k8s_image_swapper" {
  depends_on = [
    aws_iam_role_policy.k8s_image_swapper
  ]
  name       = var.k8s_image_swapper_name
  namespace  = "kube-system"
  repository = "https://estahn.github.io/charts/"
  chart      = "k8s-image-swapper"
  keyring    = ""
  version    = "1.5.0"
  values = [
    <<YAML
config:
  dryRun: ${var.dry_run}
  logLevel: info
  logFormat: json

  imageCopyPolicy: immediate
  source:
    # Filters provide control over what pods will be processed.
    # By default all pods will be processed. If a condition matches, the pod will NOT be processed.
    # For query language details see https://jmespath.org/
    filters:
      - jmespath: "obj.metadata.namespace == 'kube-system'"
      - jmespath: "contains(container.image, '.dkr.ecr.') && contains(container.image, '.amazonaws.com')"
  target:
    type: aws
    aws:
      accountId: "${data.aws_caller_identity.current.account_id}"
      region: ${var.region}

secretReader:
    enabled: true  
# awsSecretName: k8s-image-swapper-aws
serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Specifies annotations for this service account
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${module.irsa_ks.iam_role_name}"
# certmanager:
#   enabled: true
YAML
    ,
  ]
}

#iam policy for k8s-image-swapper service account
resource "aws_iam_role_policy" "k8s_image_swapper" {
  name = "${var.eks_cluster_name}-${var.k8s_image_swapper_name}"
  role = module.irsa_ks.iam_role_name

  policy = <<-EOF
{
    "Version": "2012-10-17",
    "Statement": [
        {
            "Effect": "Allow",
            "Action": [
                "ecr:CreateRepository",
                "ecr:GetAuthorizationToken"
            ],
            "Resource": "*"
        },
        {
            "Effect": "Allow",
            "Action": [
                "ecr:BatchCheckLayerAvailability",
                "ecr:BatchGetImage",
                "ecr:CompleteLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:InitiateLayerUpload",
                "ecr:ListImages",
                "ecr:PutImage",
                "ecr:TagResource",
                "ecr:UploadLayerPart"
            ],
            "Resource": "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/*"
        }
    ]
}
EOF
}
module "irsa_ks" {
  source = "terraform-aws-modules/iam/aws//modules/iam-role-for-service-accounts-eks"

  role_name = "${var.uniqueName}-${var.k8s_image_swapper_name}"

  oidc_providers = {
    main = {
      provider_arn               = var.eks_oidc_provider_arn
      namespace_service_accounts = ["kube-system:k8s-image-swapper"]
    }
  }

}

