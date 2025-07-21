variable "enabled" {
  type        = bool
  description = "Wether or not PCA is enabled or not - PCA must be in an active state first if disabling"
  default     = true
}

variable "usage_mode" {
  type        = string
  description = "Specifies wether to use PCA in short-lived mode or general purpose (normal) mode - Defaults to short lived"
  default     = "SHORT_LIVED_CERTIFICATE"
}

variable "pca_type" {
  type        = string
  description = "The type of CA (Certificate Authority): ROOT | SUBORDINATE"
}

variable "key_storage_security_standard" {
  type        = string
  description = "Cryptographic key management compliance standard used for handling CA keys. Defaults to FIPS_140_2_LEVEL_3_OR_HIGHER in code"
  default     = null
}

variable "permanent_deletion_time_in_days" {
  type        = number
  description = "Number of days to make a CA restorable after it has been deleted, must be between 7 to 30 days"
  default     = 30
}

variable "ca_key_algorithm" {
  type        = string
  description = "Type of the public key algorithm and size, in bits, of the key pair that your key pair creates when it issues a certificate"
  default     = "EC_prime256v1" #ECDSA P256
}

variable "ca_signing_algorithm" {
  type        = string
  description = "Name of the algorithm your private CA uses to sign certificate requests"
  default     = "SHA512WITHECDSA"
}

variable "ca_subject_common_name" {
  type        = string
  description = "Fully qualified domain name (FQDN) associated with the certificate subject. Must be less than or equal to 64 characters in length"
}

variable "ca_subject_country" {
  type        = string
  description = "Two digit code that specifies the country in which the certificate subject located. Must be less than or equal to 2 characters in length"
}

variable "ca_subject_organization" {
  type        = string
  description = " Legal name of the organization with which the certificate subject is affiliated. Must be less than or equal to 64 characters in length"
}

variable "ca_crl_enabled" {
  type        = bool
  description = "Switch to enable Certificate Revocation List"
  default     = false
}

variable "ca_crl_bucket_name" {
  type        = string
  description = "Optional - custom S3 bucket name to store CRL"
  default     = null
}

variable "ca_ocsp_enabled" {
  type        = bool
  description = "Switch to enable Online Certificate Status Protocol for CA"
  default     = false
}

variable "ca_crl_expiration_time_in_days" {
  type        = number
  description = "Number of days until a certificate expires"
  default     = 7
}

variable "sub_pca_root_pca_arn" {
  type        = string
  description = "The ARN of the Root CA for the Subordinate CA to issue a Certificate Signing Request to - must be specified if pca_type is SUBORDINATE"
  default     = null
}

variable "pca_certificate_validity_in_years" {
  type        = number
  description = "The number of years that the CA certificate remains valid for"
  default     = null
}

variable "pca_acm_access" {
  type        = bool
  description = "Whether or not to allow ACM to access the PCA to request/renew certs"
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
