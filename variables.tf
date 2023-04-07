variable "uniqueName" {
  type        = string
  description = "(optional) describe your variable"
}
variable "eks_cluster_name" {
  type        = string
  description = "(optional) describe your variable"
}
variable "eks_endpoint" {
  type        = string
  description = "(optional) describe your variable"
}
variable "eks_cluster_certificate_authority_data" {
  type        = string
  description = "(optional) describe your variable"
}

variable "eks_cluster_oidc_issuer_url" {
  type = string
  description = "(optional) describe your variable"
}
variable "eks_oidc_provider_arn" {
  type        = string
  description = "(optional) describe your variable"
}

variable "cluster_version" {
  type        = string
  description = "(optional) describe your variable"
}

variable "karpenter_queue_name" {
  type        = string
  description = "(optional) describe your variable"
}
variable "karpenter_instance_profile_name" {
  type        = string
  description = "(optional) describe your variable"
}
variable "karpenter_irsa_arn" {
  type        = string
  description = "(optional) describe your variable"
}
variable "vpc_id" {
  type        = string
  description = "(optional) describe your variable"
}
variable "region" {
  type        = string
  description = "(optional) describe your variable"
}

variable "zone_id" {
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
