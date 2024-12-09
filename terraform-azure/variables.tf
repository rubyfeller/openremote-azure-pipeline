variable "subscription_id" {
  description = "Azure Subscription ID"
  type        = string
}

variable "ssh_source_ip" {
  description = "IP address allowed for SSH access"
  type        = string
}

variable "ssh_public_key" {
  description = "Public SSH key for VM access"
  type        = string
}

variable "alert_email_address" {
  description = "Email address to receive alerts"
  type        = string
}

variable "enable_backups" {
  description = "Enable backups"
  type        = bool
  default     = false
}

variable "enable_monitoring" {
  description = "Enable monitoring"
  type        = bool
  default     = false
}

variable "region" {
  description = "Azure region"
  type        = string
  default     = "Central India"
}