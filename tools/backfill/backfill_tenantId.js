/*
  Backfill tenantId dans les collections top-level Firestore (products, operations).
  Prérequis:
    - Installer deps: npm install
    - Exporter GOOGLE_APPLICATION_CREDENTIALS vers un fichier Service Account JSON
      Windows PowerShell: $env:GOOGLE_APPLICATION_CREDENTIALS = "C:\\chemin\\sa.json"

  Usage (dry-run par défaut):
    node backfill_tenantId.js --project imanagement-7bd21 --tenant default --collections products,operations

  Appliquer réellement (écrit en base):
    node backfill_tenantId.js --project imanagement-7bd21 --tenant default --collections products,operations --apply

  Options:
    --project       ID du projet Firebase
    --tenant        Valeur tenantId à injecter
    --collections   Liste CSV des collections à traiter (ex: products,operations)
    --apply         Effectue les writes (sinon dry-run)
    --force         Réécrit même si tenantId existe déjà (par défaut, met uniquement si manquant)
    --batch         Taille du batch (par défaut 450)
*/

const admin = require('firebase-admin');

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { apply: false, force: false, batch: 450 };
  for (let i = 0; i < args.length; i++) {
    const a = args[i];
    if (a === '--apply') opts.apply = true;
    else if (a === '--force') opts.force = true;
    else if (a === '--batch') opts.batch = parseInt(args[++i] || '450', 10);
    else if (a === '--project') opts.project = args[++i];
    else if (a === '--tenant') opts.tenant = args[++i];
    else if (a === '--collections') opts.collections = (args[++i] || '').split(',').map(s => s.trim()).filter(Boolean);
  }
  if (!opts.project || !opts.tenant || !opts.collections || opts.collections.length === 0) {
    console.error('Args manquants. Ex: --project <id> --tenant <valeur> --collections products,operations [--apply]');
    process.exit(1);
  }
  return opts;
}

async function main() {
  const opts = parseArgs();

  if (!process.env.GOOGLE_APPLICATION_CREDENTIALS) {
    console.error('GOOGLE_APPLICATION_CREDENTIALS non défini. Pointez vers un Service Account JSON.');
    process.exit(1);
  }

  admin.initializeApp({ projectId: opts.project, credential: admin.credential.applicationDefault() });
  const db = admin.firestore();

  console.log(`Projet=${opts.project} | tenantId='${opts.tenant}' | collections=${opts.collections.join(', ')} | mode=${opts.apply ? 'APPLY' : 'DRY-RUN'} | force=${opts.force}`);

  for (const coll of opts.collections) {
    console.log(`\n-- Collection: ${coll}`);
    const snap = await db.collection(coll).get();
    console.log(`Docs trouvés: ${snap.size}`);

    let toUpdate = [];
    snap.forEach(doc => {
      const data = doc.data() || {};
      const hasTenant = typeof data.tenantId === 'string' && data.tenantId.length > 0;
      if (!hasTenant || opts.force) {
        toUpdate.push({ id: doc.id, ref: doc.ref, current: data.tenantId });
      }
    });

    console.log(`Docs à mettre à jour: ${toUpdate.length}`);
    if (!opts.apply) {
      // Aperçu
      console.log(toUpdate.slice(0, 10).map(d => ({ id: d.id, before: d.current, after: opts.tenant })));
      continue;
    }

    let processed = 0;
    while (toUpdate.length > 0) {
      const chunk = toUpdate.splice(0, opts.batch);
      const batch = db.batch();
      for (const d of chunk) {
        batch.update(d.ref, { tenantId: opts.tenant });
      }
      await batch.commit();
      processed += chunk.length;
      console.log(`Batch écrit: +${chunk.length} (total ${processed})`);
    }
    console.log(`Terminé pour ${coll}.`);
  }

  console.log('\nBackfill terminé.');
  process.exit(0);
}

main().catch(err => {
  console.error(err);
  process.exit(1);
});


