terraform {
  cloud {
    organization = "fancycorp"

    workspaces {
      name = "hvs-dynamic-creds"
    }
  }
}

provider "aws" {
  region = "eu-west-2"

  default_tags {
    tags = {
      Name      = "HCP Vault Secrets"
      Owner     = "lucy.davinhart@hashicorp.com"
      Purpose   = "TFC"
      TTL       = "Persistent"
      Terraform = "true"
      Source    = "https://github.com/FancyCorp-Demo/tf-workspace-hvs/tree/main/"
      Workspace = terraform.workspace
    }
  }
}


# From https://developer.hashicorp.com/hcp/docs/vault-secrets/dynamic-secrets/aws
variable "organization_id" {
  type        = string
  description = "Your HCP organization ID."

  # hashi-strawb
  default = "ffa120a5-d7b1-4b9c-be17-33a71e45f43f"
}
variable "project_id" {
  type        = string
  description = "Your HCP project ID."

  # fancycorp
  default = "d6c96d2b-616b-4cb8-b78c-9e17a78c2167"
}
variable "integration_name" {
  type        = string
  description = "Your AWS integration name. Must match the name of the AWS integration you'll eventually create in HCP Vault Secrets."

  default = "aws-sandbox"
}

data "aws_caller_identity" "current" {}

locals {
  account_id = data.aws_caller_identity.current.account_id
  issuer     = "idp.hashicorp.com/oidc/organization/${var.organization_id}"
  audience   = "arn:aws:iam::${local.account_id}:oidc-provider/${local.issuer}"
  subject    = "project:${var.project_id}:geo:us:service:vault-secrets:type:integration:name:${var.integration_name}"
}

resource "aws_iam_openid_connect_provider" "hcp_vault_secrets" {
  url             = "https://${local.issuer}"
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]
  client_id_list  = [local.audience]
}

resource "aws_iam_role" "integration_role" {
  name = "hcp-vault-secrets-integration"
  assume_role_policy = jsonencode({
    Version = "2012-10-17"
    Statement = [
      {
        Action = "sts:AssumeRoleWithWebIdentity"
        Effect = "Allow"
        Principal = {
          Federated = aws_iam_openid_connect_provider.hcp_vault_secrets.arn
        }
        Condition = {
          StringEquals = {
            "${local.issuer}:sub" = local.subject
          }
        }
      }
    ]
  })
}

resource "aws_iam_role" "dynamic_secret_role" {
  name = "hcp-vault-secrets-dynamic-secret"
  assume_role_policy = jsonencode({
    "Version" : "2012-10-17",
    "Statement" : [
      {
        "Effect" : "Allow",
        "Action" : "sts:AssumeRole",
        "Principal" : {
          "AWS" : aws_iam_role.integration_role.arn
        },
        "Condition" : {}
      }
    ]
  })

  inline_policy {
    name   = "hcp-vault-secrets-s3-lister"
    policy = data.aws_iam_policy_document.dynamic_secret_policy.json
  }
}

data "aws_iam_policy_document" "dynamic_secret_policy" {
  # Replace with the permissions to grant to your dynamic secret
  statement {
    effect = "Allow"
    actions = [
      "s3:List*"
    ]
    resources = ["*"]
  }
}

output "integration_name" {
  value = var.integration_name
}

output "audience" {
  value = local.audience
}

output "integration_role_arn" {
  value = aws_iam_role.integration_role.arn
}

output "dynamic_secret_role_arn" {
  value = aws_iam_role.dynamic_secret_role.arn
}

