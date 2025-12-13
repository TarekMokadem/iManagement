class WorkerConfig {
  const WorkerConfig._();

  // Même Worker que Stripe/billing : on y ajoute aussi des endpoints d'auth bootstrap.
  static const String baseUrl = 'https://imanagement-stripe.mokadem59200.workers.dev';
}


