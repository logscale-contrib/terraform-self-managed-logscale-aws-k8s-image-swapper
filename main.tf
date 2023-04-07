data "aws_caller_identity" "current" {
}

resource "helm_release" "k8s_image_swapper" {
  depends_on = [
    aws_iam_role_policy.k8s_image_swapper
    , kubernetes_secret.kis
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
  logLevel: debug
  logFormat: console

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
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ecr:GetAuthorizationToken",
                "ecr:DescribeRepositories",
                "ecr:DescribeRegistry"
            ],
            "Resource": "*"
        },
        {
            "Sid": "",
            "Effect": "Allow",
            "Action": [
                "ecr:UploadLayerPart",
                "ecr:PutImage",
                "ecr:ListImages",
                "ecr:InitiateLayerUpload",
                "ecr:GetDownloadUrlForLayer",
                "ecr:CreateRepository",
                "ecr:CompleteLayerUpload",
                "ecr:BatchGetImage",
                "ecr:BatchCheckLayerAvailability"
            ],
            "Resource": [
              "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/docker.io/*",
              "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/quay.io/*"
        ]
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

# resource "kubernetes_secret" "kis" {
#   metadata {
#     name      = "k8s-image-swapper-aws"
#     namespace = "kube-system"
#   }

#   data = {
#     aws_access_key_id     = aws_iam_access_key.kis.id
#     aws_secret_access_key = aws_iam_access_key.kis.secret
#   }

#   type = "kubernetes.io/generic"
# }
# resource "aws_iam_access_key" "kis" {
#   user = aws_iam_user.kis.name

# }
# resource "aws_iam_user" "kis" {
#   name = "${var.eks_cluster_name}-${var.k8s_image_swapper_name}"
#   path = "/"
# }

# #iam policy for k8s-image-swapper service account
# resource "aws_iam_user_policy" "k8s_image_swapper" {
#   name = "${var.eks_cluster_name}-${var.k8s_image_swapper_name}-user"
#   user = aws_iam_user.kis.name

#   policy = <<-EOF
# {
#     "Version": "2012-10-17",
#     "Statement": [
#         {
#             "Sid": "",
#             "Effect": "Allow",
#             "Action": [
#                 "ecr:GetAuthorizationToken",
#                 "ecr:DescribeRepositories",
#                 "ecr:DescribeRegistry"
#             ],
#             "Resource": "*"
#         },
#         {
#             "Sid": "",
#             "Effect": "Allow",
#             "Action": [
#                 "ecr:UploadLayerPart",
#                 "ecr:PutImage",
#                 "ecr:ListImages",
#                 "ecr:InitiateLayerUpload",
#                 "ecr:GetDownloadUrlForLayer",
#                 "ecr:CreateRepository",
#                 "ecr:CompleteLayerUpload",
#                 "ecr:BatchGetImage",
#                 "ecr:BatchCheckLayerAvailability"
#             ],
#             "Resource": [
#               "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/docker.io/*",
#               "arn:aws:ecr:*:${data.aws_caller_identity.current.account_id}:repository/quay.io/*"
#         ]
#         }
#     ]
# }
# EOF
# }
