variable "tenant_id" {}
variable "subscription_id" {}
variable "projects" {}
variable "sonarqube_url" {}
variable "sonarqube_token" {
  type      = string
  sensitive = true
}
