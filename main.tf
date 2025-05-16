data "aws_partition" "current" {}

resource "aws_s3_bucket" "pca_crl" {
  bucket        = "${substr(var.ca_subject_common_name, 0, 55)}-pca-crl"
  force_destroy = true

  tags = var.tags
}

data "aws_iam_policy_document" "pca_crl_bucket_access" {
  statement {
    actions = [
      "s3:GetBucketAcl",
      "s3:GetBucketLocation",
      "s3:PutObject",
      "s3:PutObjectAcl",
    ]

    resources = [
      aws_s3_bucket.pca_crl.arn,
      "${aws_s3_bucket.pca_crl.arn}/*",
    ]

    principals {
      identifiers = ["acm-pca.amazonaws.com"]
      type        = "Service"
    }
  }
}

resource "aws_s3_bucket_policy" "pca_crl" {
  bucket = aws_s3_bucket.pca_crl.id
  policy = data.aws_iam_policy_document.pca_crl_bucket_access.json
}

resource "aws_acmpca_certificate_authority" "this" {
  enabled    = var.enabled                      # Default to true - switch to disable if desired
  usage_mode = upper(trimspace(var.usage_mode)) #"SHORT_LIVED_CERTIFICATE" # Default to Short Lived Certificate
  type       = upper(trimspace(var.pca_type))

  key_storage_security_standard = var.key_storage_security_standard

  certificate_authority_configuration {
    key_algorithm     = upper(trimspace(var.ca_key_algorithm))
    signing_algorithm = upper(trimspace(var.ca_signing_algorithm))

    subject {
      common_name  = var.ca_subject_common_name
      country      = var.ca_subject_country
      organization = var.ca_subject_organization
    }
  }

  revocation_configuration {
    crl_configuration {
      enabled            = true
      expiration_in_days = var.ca_crl_expiration_time_in_days
      s3_bucket_name     = aws_s3_bucket.pca_crl.id
      s3_object_acl      = "BUCKET_OWNER_FULL_CONTROL"
    }

    ocsp_configuration {
      enabled = true
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
    value = var.sub_pca_certificate_validity_in_years
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
    value = var.sub_pca_certificate_validity_in_years
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
