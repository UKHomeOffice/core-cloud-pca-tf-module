# Core Cloud PCA TF Module

This is a TF module to create and manage PCA (Private Certificate Authority) on AWS Accounts

<!-- BEGIN_TF_DOCS -->
## Requirements

No requirements.

## Providers

| Name | Version |
|------|---------|
| <a name="provider_aws"></a> [aws](#provider\_aws) | n/a |

## Modules

No modules.

## Resources

| Name | Type |
|------|------|
| [aws_acmpca_certificate.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate) | resource |
| [aws_acmpca_certificate.subordinate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate) | resource |
| [aws_acmpca_certificate_authority.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate_authority) | resource |
| [aws_acmpca_certificate_authority_certificate.root](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate_authority_certificate) | resource |
| [aws_acmpca_certificate_authority_certificate.subordinate](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_certificate_authority_certificate) | resource |
| [aws_acmpca_permission.this](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/acmpca_permission) | resource |
| [aws_s3_bucket.pca_crl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket) | resource |
| [aws_s3_bucket_policy.pca_crl](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/resources/s3_bucket_policy) | resource |
| [aws_caller_identity.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/caller_identity) | data source |
| [aws_iam_policy_document.pca_crl_bucket_access](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/iam_policy_document) | data source |
| [aws_partition.current](https://registry.terraform.io/providers/hashicorp/aws/latest/docs/data-sources/partition) | data source |

## Inputs

| Name | Description | Type | Default | Required |
|------|-------------|------|---------|:--------:|
| <a name="input_ca_crl_bucket_name"></a> [ca\_crl\_bucket\_name](#input\_ca\_crl\_bucket\_name) | Optional - custom S3 bucket name to store CRL | `string` | `null` | no |
| <a name="input_ca_crl_enabled"></a> [ca\_crl\_enabled](#input\_ca\_crl\_enabled) | Switch to enable Certificate Revocation List | `bool` | `false` | no |
| <a name="input_ca_crl_expiration_time_in_days"></a> [ca\_crl\_expiration\_time\_in\_days](#input\_ca\_crl\_expiration\_time\_in\_days) | Number of days until a certificate expires | `number` | `7` | no |
| <a name="input_ca_key_algorithm"></a> [ca\_key\_algorithm](#input\_ca\_key\_algorithm) | Type of the public key algorithm and size, in bits, of the key pair that your key pair creates when it issues a certificate | `string` | `"EC_prime256v1"` | no |
| <a name="input_ca_ocsp_enabled"></a> [ca\_ocsp\_enabled](#input\_ca\_ocsp\_enabled) | Switch to enable Online Certificate Status Protocol for CA | `bool` | `false` | no |
| <a name="input_ca_signing_algorithm"></a> [ca\_signing\_algorithm](#input\_ca\_signing\_algorithm) | Name of the algorithm your private CA uses to sign certificate requests | `string` | `"SHA512WITHECDSA"` | no |
| <a name="input_ca_subject_common_name"></a> [ca\_subject\_common\_name](#input\_ca\_subject\_common\_name) | For CA and end-entity certificates in a private PKI, the common name (CN) can be any string. For publicly trusted certificates, Fully Qualified Domain Name (FQDN) associated with the certificate subject. Must be less than or equal to 64 characters in length | `string` | n/a | yes |
| <a name="input_ca_subject_country"></a> [ca\_subject\_country](#input\_ca\_subject\_country) | Two digit code that specifies the country in which the certificate subject located. Must be less than or equal to 2 characters in length | `string` | n/a | yes |
| <a name="input_ca_subject_locality"></a> [ca\_subject\_locality](#input\_ca\_subject\_locality) | Optional - The locality (such as a city or town) in which the certificate subject is located. Must be less than or equal to 64 characters in length | `string` | `null` | no |
| <a name="input_ca_subject_organization"></a> [ca\_subject\_organization](#input\_ca\_subject\_organization) | The legal name of the organization with which the certificate subject is affiliated. Must be less than or equal to 64 characters in length | `string` | n/a | yes |
| <a name="input_ca_subject_organization_unit"></a> [ca\_subject\_organization\_unit](#input\_ca\_subject\_organization\_unit) | Optional - A subdivision or unit of the organization (such as sales or finance) with which the certificate subject is affiliated. Must be less than or equal to 64 characters in length | `string` | `null` | no |
| <a name="input_ca_subject_state"></a> [ca\_subject\_state](#input\_ca\_subject\_state) | Optional - State in which the subject of the certificate is located. Must be less than or equal to 64 characters in length | `string` | `null` | no |
| <a name="input_enabled"></a> [enabled](#input\_enabled) | Wether or not PCA is enabled or not - PCA must be in an active state first if disabling | `bool` | `true` | no |
| <a name="input_key_storage_security_standard"></a> [key\_storage\_security\_standard](#input\_key\_storage\_security\_standard) | Cryptographic key management compliance standard used for handling CA keys. Defaults to FIPS\_140\_2\_LEVEL\_3\_OR\_HIGHER in code | `string` | `null` | no |
| <a name="input_pca_acm_access"></a> [pca\_acm\_access](#input\_pca\_acm\_access) | Whether or not to allow ACM to access the PCA to request/renew certs | `bool` | `false` | no |
| <a name="input_pca_certificate_validity_in_years"></a> [pca\_certificate\_validity\_in\_years](#input\_pca\_certificate\_validity\_in\_years) | The number of years that the CA certificate remains valid for | `number` | `null` | no |
| <a name="input_pca_type"></a> [pca\_type](#input\_pca\_type) | The type of CA (Certificate Authority): ROOT \| SUBORDINATE | `string` | n/a | yes |
| <a name="input_permanent_deletion_time_in_days"></a> [permanent\_deletion\_time\_in\_days](#input\_permanent\_deletion\_time\_in\_days) | Number of days to make a CA restorable after it has been deleted, must be between 7 to 30 days | `number` | `30` | no |
| <a name="input_sub_pca_root_pca_arn"></a> [sub\_pca\_root\_pca\_arn](#input\_sub\_pca\_root\_pca\_arn) | The ARN of the Root CA for the Subordinate CA to issue a Certificate Signing Request to - must be specified if pca\_type is SUBORDINATE | `string` | `null` | no |
| <a name="input_tags"></a> [tags](#input\_tags) | n/a | `map(string)` | `{}` | no |
| <a name="input_usage_mode"></a> [usage\_mode](#input\_usage\_mode) | Specifies wether to use PCA in short-lived mode or general purpose (normal) mode - Defaults to short lived | `string` | `"SHORT_LIVED_CERTIFICATE"` | no |

## Outputs

No outputs.
<!-- END_TF_DOCS -->