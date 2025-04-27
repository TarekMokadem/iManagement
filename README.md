# App InvV1 - Application de Gestion d'Inventaire

Application multiplateforme (tablette/PC) pour simplifier la gestion d'inventaire à destination des employés et des responsables via une interface intuitive et connectée à Firebase.

## Fonctionnalités

- Connexion / Déconnexion avec un code
- Interface Employé :
  - Liste des produits avec seuil critique (en rouge)
  - Recherche de produits
  - Gestion des entrées/sorties
- Interface Admin :
  - Vue rapide des produits critiques
  - Gestion complète des produits
  - Gestion des utilisateurs
  - Export Excel

## Prérequis

- Flutter SDK (dernière version stable)
- Firebase project
- Android Studio / VS Code avec extensions Flutter

## Installation

1. Cloner le projet :
```bash
git clone [URL_DU_PROJET]
cd app_invv1
```

2. Installer les dépendances :
```bash
flutter pub get
```

3. Configurer Firebase :
   - Créer un projet Firebase
   - Ajouter les applications Android et iOS
   - Télécharger et placer les fichiers de configuration :
     - `android/app/google-services.json`
     - `ios/Runner/GoogleService-Info.plist`

4. Lancer l'application :
```bash
flutter run
```

## Configuration Firebase

1. Activer l'authentification anonyme dans Firebase Console
2. Créer les collections suivantes dans Firestore :
   - `products`
   - `users`
   - `logs`

3. Structure des collections :

**Products**:
```json
{
  "name": "string",
  "quantity": "number",
  "criticalThreshold": "number"
}
```

**Users**:
```json
{
  "code": "string",
  "name": "string",
  "isAdmin": "boolean"
}
```

**Logs**:
```json
{
  "productId": "string",
  "productName": "string",
  "type": "string",
  "quantity": "number",
  "timestamp": "timestamp"
}
```

## Utilisation

1. **Connexion** :
   - Les employés se connectent avec leur code personnel
   - Les administrateurs ont accès à toutes les fonctionnalités

2. **Interface Employé** :
   - Visualiser la liste des produits
   - Effectuer des entrées/sorties
   - Voir les produits en seuil critique

3. **Interface Admin** :
   - Gérer les produits (ajout, modification, suppression)
   - Gérer les utilisateurs
   - Exporter les données en Excel
   - Surveiller les produits critiques

## Contribution

Les contributions sont les bienvenues ! N'hésitez pas à :
1. Fork le projet
2. Créer une branche pour votre fonctionnalité
3. Commiter vos changements
4. Pousser vers la branche
5. Ouvrir une Pull Request

## Licence

Ce projet est sous licence MIT. Voir le fichier `LICENSE` pour plus de détails. 