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



removed {
  from = aws_iam_openid_connect_provider.hcp_vault_secrets
  lifecycle {
    destroy = false
  }
}

