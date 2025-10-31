Déployer Flutter Web sur Cloudflare Pages (gratuit)

Pré-requis: compte Cloudflare et repo GitHub.

Étapes:
1) Sur votre machine: `flutter build web` (ou laissez CF builder le faire).
2) Cloudflare Dashboard → Pages → Connect to Git → choisissez le repo.
3) Build command: `flutter build web`
4) Output directory: `build/web`
5) Variables d’environnement (si besoin): `--no-sound-null-safety` non nécessaire ici.
6) Déployer. Votre app sera disponible sur `*.pages.dev`.

Astuces:
- Pour perfs: activer compression et caching par défaut.
- Domaine custom: l’ajouter plus tard quand revenu.


