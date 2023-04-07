data "aws_caller_identity" "current" {
}


resource "aws_ecr_repository" "main" {
  name                 = var.eks_cluster_name
  image_tag_mutability = "MUTABLE"

  image_scanning_configuration {
    scan_on_push = false
  }
  force_delete = true
}
#k8s-image-swapper helm chart
resource "helm_release" "k8s_image_swapper" {
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

serviceAccount:
  # Specifies whether a service account should be created
  create: true
  # Specifies annotations for this service account
  annotations:
    eks.amazonaws.com/role-arn: "arn:aws:iam::${data.aws_caller_identity.current.account_id}:role/${aws_iam_role.k8s_image_swapper.name}"
YAML
    ,
  ]
}

#iam policy for k8s-image-swapper service account
resource "aws_iam_role_policy" "k8s_image_swapper" {
  name = "${var.eks_cluster_name}-${var.k8s_image_swapper_name}"
  role = aws_iam_role.k8s_image_swapper.id

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

#role for k8s-image-swapper service account
resource "aws_iam_role" "k8s_image_swapper" {
  name               = "${var.eks_cluster_name}-${var.k8s_image_swapper_name}"
  assume_role_policy = <<-EOF
{
  "Version": "2012-10-17",
  "Statement": [
    {
      "Effect": "Allow",
      "Principal": {
        "Federated": "arn:aws:iam::${data.aws_caller_identity.current.account_id}:oidc-provider/${replace(var.eks_cluster_oidc_issuer_url, "/https:///", "")}"
      },
      "Action": "sts:AssumeRoleWithWebIdentity",
      "Condition": {
        "StringEquals": {
          "${replace(var.eks_cluster_oidc_issuer_url, "/https:///", "")}:sub": "system:serviceaccount:${var.k8s_image_swapper_namespace}:${var.k8s_image_swapper_name}"
        }
      }
    }
  ]
}
EOF
}