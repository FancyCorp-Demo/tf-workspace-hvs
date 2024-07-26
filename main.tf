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


resource "aws_iam_openid_connect_provider" "tfc_provider" {
  url = "https://idp.hashicorp.com/oidc/organization/ffa120a5-d7b1-4b9c-be17-33a71e45f43f"
  client_id_list = [
    "arn:aws:iam::564784738291:oidc-provider/idp.hcp.to/oidc/organization/ffa120a5-d7b1-4b9c-be17-33a71e45f43f"
  ]
  thumbprint_list = ["9e99a48a9960b14926bb7f3b02e22da2b0ab7280"]

}




# TODO: The rest of the stuff from https://developer.hashicorp.com/hcp/docs/vault-secrets/dynamic-secrets/aws
# (there's some pre-existing TF code there)
