 Projet DIGITRANS-CM : Transformation Numérique d'AGROCAM S.A.

Auteur : Équipe Projet CAMTECH SOLUTIONS S.A.  
Contexte : Évaluation BC04 / EC04 — Optimiser le Système d'Information (SI) par l'apport du Cloud Computing (2025/2026).



 1. Contexte du Projet

Le projet DIGITRANS-CM:  vise à moderniser intégralement le Système d'Information de 
AGROCAM S.A. (leader agroalimentaire au Cameroun : transformation cacao/café, distribution, restauration rapide « SavoirManger »). L'ancien système monolithique de 2009 est remplacé par un écosystème applicatif moderne, distribué, et hébergé sur une architecture cloud hybride (AWS & Azure).

Ce projet s'inscrit dans un contexte technologique camerounais spécifique :
- Coupures d'électricité fréquentes (Délestages à Douala).
- Connectivité inégale (exigeant une approche Offline-First).
- Souveraineté des données (Données sensibles hébergées en local ou sur des plaques africaines).



 2. Architecture Cloud Hybride (AWS & Azure)

Afin de répondre au point C21 (Intégration des services cloud), une approche multicloud a été adoptée pour allier robustesse, conformité et performance :

A. Plateforme AWS (Amazon Web Services)
Utilisée pour héberger les services à forte charge et le stockage. Le choix s'est porté sur la région Afrique du Sud (af-south-1) pour garantir la souveraineté continentale des données et minimiser la latence depuis le Cameroun (~150 ms).
- AWS RDS (PostgreSQL) : Base de données relationnelle hautement disponible pour l'ERP et le CRM.
- AWS EC2 (Bastion) : Serveur sécurisé d'administration.
- AWS SQS : File d'attente permettant le fonctionnement en mode dégradé (**Offline-First**). En cas de coupure de connectivité des terminaux ruraux, les actions (ex: Supply Chain) sont mises en cache puis synchronisées via SQS dès reconnexion.
- AWS S3 : Stockage d'objets pour l'archivage documentaire.


B. Microsoft Azure (Identité et Sécurité)
Conformément aux exigences, Azure est le cœur de la gestion des identités.
- Azure Active Directory (Entra ID)** : Fournit le système d'authentification centralisé (SSO). Utilisation de protocoles standards (OAuth 2.0 / JWT) sécurisant l'accès aux APIs.
- Configuration du contrôle d'accès basé sur les rôles (RBAC) pour distinguer les profils "Admin" (Direction) et "User" (Vendeurs SavoirManger).


3. Architecture Applicative Microservices

L'application abandonne son architecture monolithique au profit de 4 microservices distincts, conteneurisés via Docker. Bien qu'actuellement orchestrés par `docker-compose` pour les tests locaux, ils sont conçus pour être basculés sur un cluster Kubernetes (AWS EKS / Azure AKS) en production.

1. ERP Backend : Gestion RH, comptabilité, approvisionnement.
2.CRM Backend : Relation client, utilisé massivement par les restaurants SavoirManger.
3. Supply Chain Backend** : Suivi des flux logistiques entre plantations et points de vente.
4. BI Backend: Tableaux de bord stratégiques pour le top management.

Optimisation des performances (C24) :  
Un cache Redis a été intégré aux microservices pour soulager la base de données PostgreSQL, crucial pour réduire les latences dues au réseau africain. 



 4. Pratiques DevOps et Automatisation (C22 & C23)

 Infrastructure as Code (IaC)
L'intégralité de l'infrastructure est codée avec Terraform. Cela permet des déploiements reproductibles, l'audit de la configuration, et la séparation des environnements (Dev, Test, Prod). Les scripts génèrent automatiquement l'infrastructure AWS (`main.tf`) et la configuration d'identité Azure (`azure.tf`).

Intégration et Déploiement Continus (CI/CD)
Un pipeline **GitHub Actions (`.github/workflows/terraform.yml`) a été mis en place pour garantir la qualité :
- Validation de la syntaxe Terraform (`terraform validate`).
- Planification sécurisée sans modification non désirée (`terraform plan`).
- Déploiement automatique lors d'une validation vers la branche principale.

Monitoring et Observabilité
Pour l'administration en condition opérationnelle (C23) :
- Les APIs Node.js intègrent `prom-client` pour générer des métriques en temps réel.
- Prometheus collecte ces métriques (Temps de réponse, taux d'erreurs).
- Grafana (virtuellement ou via CloudWatch/Azure Monitor) permet la visualisation des pics de charge, facilitant la prise de décision sur l'auto-scaling.



5. Instructions de Déploiement

Déploiement de l'Infrastructure Cloud (Terraform)
1. Configurez vos identifiants via GitHub Secrets ou variables locales :
   - `AWS_ACCESS_KEY_ID` & `AWS_SECRET_ACCESS_KEY`
   - `ARM_CLIENT_ID` & `ARM_CLIENT_SECRET` (Azure)
   - `TF_VAR_db_password`
2. Exécutez les commandes :
   ```bash
   terraform init
   terraform plan
   terraform apply -auto-approve
   ```

 Déploiement Local des Microservices (Docker)
1. Naviguez dans le dossier de l'application : `cd DIGITRANS-CM`
2. Lancez l'environnement :
   bash
   docker-compose up -d --build
   
3. L'API CRM sera disponible sur `http://localhost:3002` et les métriques de supervision sur `http://localhost:3002/metrics`.

