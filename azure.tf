# Configuration du fournisseur Azure Active Directory
terraform {
  required_providers {
    azuread = {
      source  = "hashicorp/azuread"
      version = "~> 2.47.0"
    }
  }
}

# Provider pour configurer le locataire Azure (Tenant)
provider "azuread" {
  # Les informations d'identification seront fournies via variables d'environnement dans la CI/CD
  # ARM_CLIENT_ID, ARM_CLIENT_SECRET, ARM_TENANT_ID
}

# 1. Création de l'Application dans Azure AD (Entra ID) pour DIGITRANS-CM
resource "azuread_application" "digitrans_auth" {
  display_name     = "DIGITRANS-CM-Auth-App"
  sign_in_audience = "AzureADMyOrg"

  # Configuration de l'API web pour OAuth 2.0 / JWT
  api {
    mapped_claims_enabled          = true
    requested_access_token_version = 2
  }

  web {
    redirect_uris = ["https://crm.savoirmanger.cm/oauth2/callback"]
    implicit_grant {
      access_token_issuance_enabled = true
      id_token_issuance_enabled     = true
    }
  }
}

# 2. Création d'un Service Principal pour permettre aux microservices AWS de s'authentifier
resource "azuread_service_principal" "digitrans_sp" {
  application_id               = azuread_application.digitrans_auth.application_id
  app_role_assignment_required = false
}

# 3. Création d'un mot de passe (secret) pour l'application
resource "azuread_application_password" "digitrans_app_pwd" {
  application_object_id = azuread_application.digitrans_auth.object_id
  end_date             = "2027-01-01T01:02:03Z"
}

# Rôles applicatifs (ex: Admin, Utilisateur standard pour le module CRM)
resource "azuread_application_app_role" "admin_role" {
  application_object_id = azuread_application.digitrans_auth.object_id
  allowed_member_types  = ["User"]
  description           = "Administrateur DIGITRANS-CM (Accès complet ERP/BI)"
  display_name          = "Admin"
  id                    = "00000000-0000-0000-0000-000000000001"
  value                 = "admin"
}

resource "azuread_application_app_role" "user_role" {
  application_object_id = azuread_application.digitrans_auth.object_id
  allowed_member_types  = ["User"]
  description           = "Utilisateur standard (Accès CRM/Supply Chain)"
  display_name          = "User"
  id                    = "00000000-0000-0000-0000-000000000002"
  value                 = "user"
}
