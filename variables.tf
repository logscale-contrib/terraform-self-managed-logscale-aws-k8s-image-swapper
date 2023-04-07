variable "uniqueName" {
  type        = string
  description = "(optional) describe your variable"
}
variable "eks_cluster_name" {
  type        = string
  description = "(optional) describe your variable"
}

variable "eks_oidc_provider_arn" {
  type        = string
  description = "(optional) describe your variable"
}


variable "region" {
  type        = string
  description = "(optional) describe your variable"
}


variable "k8s_image_swapper_namespace" {
  default     = "kube-system"
  description = "namespace to install k8s-image-swapper"
}

variable "k8s_image_swapper_name" {
  default     = "k8s-image-swapper"
  description = "name for k8s-image-swapper release and service account"
}

variable "dry_run" {
  type        = string
  default     = "false"
  description = "(optional) describe your variable"
}
