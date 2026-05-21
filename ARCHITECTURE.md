# Architecture Hybride DIGITRANS-CM

Ce schéma illustre la topologie cloud hybride mise en place pour AGROCAM S.A.

```mermaid
graph TD
    %% Azure Cloud
    subgraph Azure ["Microsoft Azure (South Africa North)"]
        AzureAD[/"Azure Active Directory (Entra ID)"/]
        RoleAdmin(["Rôle: Admin"])
        RoleUser(["Rôle: User"])
        AzureAD --> RoleAdmin
        AzureAD --> RoleUser
    end

    %% AWS Cloud
    subgraph AWS ["Amazon Web Services (af-south-1)"]
        ALB[/"Elastic Load Balancer"/]
        SQS[["AWS SQS (Offline-First Sync)"]]
        S3[("AWS S3 (Document Archive)")]
        RDS[("AWS RDS (PostgreSQL)")]
        Bastion[("Bastion EC2")]
    end

    %% Kubernetes / Docker Microservices
    subgraph K8S ["Orchestration (Docker/EKS)"]
        ERP["ERP Backend"]
        CRM["CRM Backend"]
        SC["Supply Chain Backend"]
        BI["BI Backend"]
        Redis[("Cache Redis")]
        Prometheus[["Prometheus / Grafana"]]
    end

    %% Client Layer
    Client(("Clients/Terminaux\n(SavoirManger / AGROCAM)"))

    %% Connections
    Client == "Authentification (OAuth 2.0/JWT)" ==> AzureAD
    Client == "Requêtes API" ==> ALB
    ALB --> ERP
    ALB --> CRM
    ALB --> SC
    ALB --> BI

    %% Microservices interactions
    ERP --> Redis
    CRM --> Redis
    SC --> Redis
    BI --> Redis
    
    ERP --> RDS
    CRM --> RDS
    
    SC -. "Mise en file d'attente\nen cas de coupure" .-> SQS
    SQS -. "Dépilage asynchrone" .-> RDS
    
    ERP --> S3
    
    %% Monitoring
    Prometheus -. "Collecte de métriques" .-> ERP
    Prometheus -. "Collecte de métriques" .-> CRM
    
    %% Security
    Bastion -. "Accès SSH sécurisé" .-> RDS
    
    %% Styles
    style Azure fill:#0072C6,stroke:#fff,stroke-width:2px,color:#fff
    style AWS fill:#FF9900,stroke:#fff,stroke-width:2px,color:#000
    style K8S fill:#326CE5,stroke:#fff,stroke-width:2px,color:#fff
    style Client fill:#8BC34A,stroke:#fff,stroke-width:2px,color:#000
```

## Explications
1. **Authentification** : Lorsqu'un utilisateur d'AGROCAM (ex: vendeur en restaurant SavoirManger) se connecte, l'authentification est gérée par **Azure AD**, garantissant une identité centralisée.
2. **Offline-First** : En cas de coupure de réseau, le module Supply Chain continue de fonctionner localement. Dès le retour de la connexion, les actions sont envoyées dans **AWS SQS** qui agit comme tampon sécurisé avant l'insertion dans la base de données.
3. **Haute Disponibilité** : Les microservices s'appuient sur un cache **Redis** local, allégeant la pression sur la base de données distante (**AWS RDS**) et compensant les problèmes de latence du réseau africain.
