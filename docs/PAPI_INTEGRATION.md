# Intégration PAPI.mg

Implémentation basée sur le [guide officiel](https://docs.papi.mg/fr/docs/developper-guide/integration-guide).

## Flux retenu

1. L’API crée une ligne `payments` avec une référence unique.
2. Elle appelle l’endpoint PAPI `payment-links` avec l’en-tête `Token`.
3. Le `paymentLink` et le `notificationToken` restent côté serveur.
4. La PWA redirige la fenêtre courante. Android/iOS ouvrent le navigateur externe.
5. PAPI revient sur `https://app.iooeh.com/payment/return?...`.
6. Cette URL est une route Flutter Web et un Universal Link/App Link natif.
7. Le callback `POST https://api.iooeh.com/payments/papi/notification` vérifie référence, token, montant et devise avant activation.

Le retour navigateur n’active jamais l’abonnement : seul le callback serveur vérifié le fait.

## Configuration native

- iOS : `applinks:app.iooeh.com` et fichier Apple AASA fournis.
- Android : intent filter fourni. Ajouter `assetlinks.json` lorsque l’empreinte SHA-256 de la clé Play/release est définitive.
- Le build Android utilise encore une clé debug ; aucun fingerprint instable n’est publié.

## Production

Configurer `PAPI_API_KEY`, `PAPI_TEST_MODE=false`, `PUBLIC_APP_URL` et `PUBLIC_API_URL`. Selon la documentation PAPI, l’indicateur `isTestMode` peut malgré tout déplacer de l’argent ; utiliser le mode test de la boutique pour les tests carte sans débit.
