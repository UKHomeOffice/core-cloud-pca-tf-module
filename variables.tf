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
  description = "For CA and end-entity certificates in a private PKI, the common name (CN) can be any string. For publicly trusted certificates,g Fully Qualified Domain Name (FQDN) associated with the certificate subject. Must be less than or equal to 64 characters in length"
}

variable "ca_subject_organization" {
  type        = string
  description = "The legal name of the organization with which the certificate subject is affiliated. Must be less than or equal to 64 characters in length"
}

variable "ca_subject_organization_unit" {
  type        = string
  description = "Optional - A subdivision or unit of the organization (such as sales or finance) with which the certificate subject is affiliated. Must be less than or equal to 64 characters in length"
  default     = null
}

variable "ca_subject_country" {
  type        = string
  description = "Two digit code that specifies the country in which the certificate subject located. Must be less than or equal to 2 characters in length"
}

variable "ca_subject_state" {
  type        = string
  description = "Optional - State in which the subject of the certificate is located. Must be less than or equal to 64 characters in length"
  default     = null
}

variable "ca_subject_locality" {
  type        = string
  description = "Optional - The locality (such as a city or town) in which the certificate subject is located. Must be less than or equal to 64 characters in length"
  default     = null
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

# AWS Resource Policy Settings
variable "pca_allowed_aws_organisation" {
  type        = string
  description = "Optional - Cross Account - The AWS OrgID that can request certificates from the PCA"
  default     = ""
}

variable "pca_allowed_aws_accounts" {
  type        = list(string)
  description = "Optional - Cross Account - The AWS Accounts that can request certificates from the PCA"
  default     = []
}

variable "pca_allowed_shared_templates" {
  type        = list(string)
  description = "Optional - The list of templates to assign to the CA Shared Resource Policy"
  default     = []
}

# AWS RAM Sharing
variable "pca_ram_enable" {
  type        = bool
  description = "Enable this switch if you want to share PCA via RAM"
  default     = false
}

variable "pca_ram_share_name" {
  type        = string
  description = "The name of the Resource Share - Required if RAM Share is enabled"
  default     = ""
}

variable "pca_ram_permission_arns" {
  type        = list(string)
  description = "The list of managed RAM Permission ARNs that are desired - Required if RAM Share is enabled"
  default     = []
}

variable "pca_ram_share_principals" {
  type        = list(string)
  description = "The list of principals to share PCA with, can be account IDs, org ARN, OU ARNs - Required if RAM Share is enabled"
  default     = []
}

variable "pca_ram_share_allow_external" {
  type        = bool
  description = "Enable this switch if PCA sharing is desired outside AWS Organisation"
  default     = false
}

variable "tags" {
  type    = map(string)
  default = {}
}
