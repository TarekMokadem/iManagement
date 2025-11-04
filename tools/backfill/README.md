Backfill tenantId pour Firestore (products, operations)

Prérequis
- Créer un Service Account avec rôle Datastore User (ou Owner) et télécharger le JSON.
- Ne pas commiter le JSON; gardez-le en local.
- Node.js 18+ installé.

Installation (Windows PowerShell)
1. Ouvrir un terminal dans ce dossier:
   cd tools/backfill
2. Installer les dépendances:
   npm install
3. Pointer vers le Service Account JSON:
   $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\chemin\\vers\\service-account.json"

Dry-run (aucune écriture)
   node backfill_tenantId.js --project imanagement-7bd21 --tenant default --collections products,operations

Appliquer (écrit tenantId sur les docs manquants)
   node backfill_tenantId.js --project imanagement-7bd21 --tenant default --collections products,operations --apply

Options utiles
- --force : réécrit tenantId même s’il existe déjà
- --batch 300 : taille du batch d’écriture (défaut 450)

Sécurité
- Le script utilise GOOGLE_APPLICATION_CREDENTIALS; rien n’est stocké dans le repo.
- Exécutez d’abord en dry-run pour vérifier l’aperçu des modifications.


