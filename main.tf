data "aws_partition" "current" {}
data "aws_caller_identity" "current" {}

resource "aws_s3_bucket" "pca_crl" {
  count = var.ca_crl_enabled ? 1 : 0

  bucket        = lower(coalesce("${var.ca_crl_bucket_name}", "cc-pca-${data.aws_caller_identity.current.account_id}-${substr(replace(var.ca_subject_common_name, " ", "-"), 0, 35)}-crl"))
  force_destroy = true

  tags = var.tags
}

data "aws_iam_policy_document" "pca_crl_bucket_access" {
  statement {
    sid    = "PCAS3Access"
    effect = "Allow"
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      aws_s3_bucket.pca_crl[0].arn,
      "${aws_s3_bucket.pca_crl[0].arn}/*",
    ]

    principals {
      identifiers = ["acm-pca.amazonaws.com"]
      type        = "Service"
    }
  }

  statement {
    sid    = "AllowSSLRequestsOnly"
    effect = "Deny"
    actions = [
      "s3:*"
    ]

    resources = [
      aws_s3_bucket.pca_crl[0].arn,
      "${aws_s3_bucket.pca_crl[0].arn}/*",
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "Bool"
      variable = "aws:SecureTransport"
      values   = ["false"]
    }
  }
}

resource "aws_s3_bucket_policy" "pca_crl" {
  bucket = aws_s3_bucket.pca_crl[0].id
  policy = data.aws_iam_policy_document.pca_crl_bucket_access.json
}

resource "aws_acmpca_certificate_authority" "this" {
  enabled    = var.enabled                      # Default to true - switch to disable if desired
  usage_mode = upper(trimspace(var.usage_mode)) #"SHORT_LIVED_CERTIFICATE" # Default to Short Lived Certificate
  type       = upper(trimspace(var.pca_type))

  key_storage_security_standard = var.key_storage_security_standard

  certificate_authority_configuration {
    key_algorithm     = trimspace(var.ca_key_algorithm)
    signing_algorithm = trimspace(var.ca_signing_algorithm)

    subject {
      common_name         = var.ca_subject_common_name
      organization        = var.ca_subject_organization
      organizational_unit = var.ca_subject_organization_unit
      country             = upper(var.ca_subject_country)
      state               = var.ca_subject_state
      locality            = var.ca_subject_locality
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled            = var.ca_crl_enabled
      expiration_in_days = var.ca_crl_expiration_time_in_days
      s3_bucket_name     = aws_s3_bucket.pca_crl[0].id
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
    }

    ocsp_configuration {
      enabled = var.ca_ocsp_enabled
    }
  }

  permanent_deletion_time_in_days = var.permanent_deletion_time_in_days

  tags = var.tags

  depends_on = [aws_s3_bucket_policy.pca_crl]
}

# Allow ACM (if used) to request and rotate certificates from PCA
resource "aws_acmpca_permission" "this" {
  count = var.pca_acm_access ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.this.arn
  actions                   = ["IssueCertificate", "GetCertificate", "ListPermissions"]
  principal                 = "acm.amazonaws.com"

  depends_on = [aws_acmpca_certificate_authority.this]
}

### If CA is created in ROOT Mode create self signed certificate
resource "aws_acmpca_certificate" "root" {
  count = upper(trimspace(var.pca_type)) == "ROOT" ? 1 : 0

  certificate_authority_arn   = aws_acmpca_certificate_authority.this.arn
  certificate_signing_request = aws_acmpca_certificate_authority.this.certificate_signing_request
  signing_algorithm           = var.ca_signing_algorithm

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/RootCACertificate/V1"

  validity {
    type  = "YEARS"
    value = var.pca_certificate_validity_in_years
  }

  depends_on = [aws_acmpca_certificate_authority.this]
}

resource "aws_acmpca_certificate_authority_certificate" "root" {
  count = upper(trimspace(var.pca_type)) == "ROOT" ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.this.arn

  certificate       = aws_acmpca_certificate.root[0].certificate
  certificate_chain = aws_acmpca_certificate.root[0].certificate_chain

  depends_on = [aws_acmpca_certificate.root]
}

### If CA is created in SUBORDINATE Mode you will need to provide a cert from a root CA
resource "aws_acmpca_certificate" "subordinate" {
  count = upper(trimspace(var.pca_type)) == "SUBORDINATE" ? 1 : 0

  certificate_authority_arn   = var.sub_pca_root_pca_arn
  certificate_signing_request = aws_acmpca_certificate_authority.this.certificate_signing_request
  signing_algorithm           = var.ca_signing_algorithm

  template_arn = "arn:${data.aws_partition.current.partition}:acm-pca:::template/SubordinateCACertificate_PathLen0/V1"

  validity {
    type  = "YEARS"
    value = var.pca_certificate_validity_in_years
  }

  depends_on = [aws_acmpca_certificate_authority.this]
}

resource "aws_acmpca_certificate_authority_certificate" "subordinate" {
  count = upper(trimspace(var.pca_type)) == "SUBORDINATE" ? 1 : 0

  certificate_authority_arn = aws_acmpca_certificate_authority.this.arn

  certificate       = aws_acmpca_certificate.subordinate[0].certificate
  certificate_chain = aws_acmpca_certificate.subordinate[0].certificate_chain

  depends_on = [aws_acmpca_certificate.subordinate]
}

###
# Resource Policy - For Cross account, generally just used for requesting certs
###

data "aws_iam_policy_document" "pca_cross_account_resource_policy_organisations" {
  count = length(var.pca_allowed_aws_organisation) > 0 ? 1 : 0
  statement {
    sid    = "CrossAccountPCAAccessOrganisation1"
    effect = "Allow"
    actions = [
      "acm-pca:DescribeCertificateAuthority",
      "acm-pca:GetCertificate",
      "acm-pca:GetCertificateAuthorityCertificate",
      "acm-pca:ListPermissions"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.pca_allowed_aws_organisation]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }

  statement {
    sid    = "CrossAccountPCAAccessOrganisation2"
    effect = "Allow"
    actions = [
      "acm-pca:IssueCertificate"
    ]

    principals {
      identifiers = ["*"]
      type        = "*"
    }

    condition {
      test     = "StringEquals"
      variable = "acm-pca:TemplateArn"
      values   = "arn:aws:acm-pca:::template/EndEntityCertificate/V1"
    }

    condition {
      test     = "StringEquals"
      variable = "aws:PrincipalOrgID"
      values   = [var.pca_allowed_aws_organisation]
    }

    condition {
      test     = "StringNotEquals"
      variable = "aws:PrincipalAccount"
      values   = ["${data.aws_caller_identity.current.account_id}"]
    }
  }
}

data "aws_iam_policy_document" "pca_cross_account_resource_policy_accounts" {
  count = length(var.pca_allowed_aws_accounts) > 0 ? 1 : 0
  statement {
    sid    = "CrossAccountPCAAccessAccount1"
    effect = "Allow"
    actions = [
      "acm-pca:DescribeCertificateAuthority",
      "acm-pca:GetCertificate",
      "acm-pca:GetCertificateAuthorityCertificate",
      "acm-pca:ListPermissions"
    ]

    principals {
      type        = "AWS"
      identifiers = var.pca_allowed_aws_accounts
    }
  }

  statement {
    sid    = "CrossAccountPCAAccessAccount2"
    effect = "Allow"
    actions = [
      "acm-pca:IssueCertificate"
    ]

    principals {
      type        = "AWS"
      identifiers = var.pca_allowed_aws_accounts
    }

    condition {
      test     = "StringEquals"
      variable = "acm-pca:TemplateArn"
      values   = "arn:aws:acm-pca:::template/EndEntityCertificate/V1"
    }
  }
}

data "aws_iam_policy_document" "pca_cross_account_resource_policy_combined" {
  count = (length(var.pca_allowed_aws_organisation) > 0 || length(var.pca_allowed_aws_accounts) > 0) ? 1 : 0
  override_policy_documents = [
    try(data.aws_iam_policy_document.pca_cross_account_resource_policy_organisations[0].json, ""),
    try(data.aws_iam_policy_document.pca_cross_account_resource_policy_accounts[0].json, "")
  ]
}

resource "aws_acmpca_policy" "pca_cross_account_resource_policy" {
  count        = (length(var.pca_allowed_aws_organisation) > 0 || length(var.pca_allowed_aws_accounts) > 0) ? 1 : 0
  resource_arn = aws_acmpca_certificate_authority.this.arn
  policy       = data.aws_iam_policy_document.pca_cross_account_resource_policy_combined[0].json
}
