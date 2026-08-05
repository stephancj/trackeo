# Roadmap Trackeo — lots différés

Ce document conserve les fonctionnalités exclues du one shot du 6 août 2026. Les lots 1 (Sécurité & Support), 3 (paiement PAPI.mg) et 4 (trips, playback et exports) sont implémentés dans le produit.

## Lot 2 — Activation QR / OTP

- QR contenant l’identifiant matériel ou l’IMEI.
- OTP WhatsApp/SMS valable 10 minutes, hashé et limité par téléphone, IP et appareil.
- Tables `device_activation_codes`, `device_activation_attempts`, `device_claims`.
- Provisionnement atomique du device et démarrage de l’essai.
- Révocation et diagnostic depuis l’admin.

## Lot 5 — Télémétrie carburant

- Ingestion `fuel_pct` et `fuel_v`, calibration par véhicule et capacité du réservoir.
- Historique, consommation par trajet, seuil bas et détection de chute soudaine.
- Droits prévus : `fuel_monitoring`, `fuel_history_days`, `fuel_theft_alerts`, `fuel_consumption_reports`.

## Lot 6 — Flotte B2B

- Organisations, équipes, groupes, chauffeurs, invitations et assignations.
- RBAC : propriétaire, admin flotte, opérateur, support, analyste, lecture seule.
- Import CSV jusqu’à 1 000 appareils avec prévalidation et rapport d’erreurs.
- Rapports planifiés hebdomadaires/mensuels par email.

## Lot 7 — API partenaires

- Clés API rotatives, scopes et rate limiting.
- Scopes : `location:read`, `vehicles:read`, `alerts:read`, `alerts:subscribe`, `alerts:ack`.
- Webhooks HMAC, protection anti-rejeu, retries exponentiels et dead-letter queue.
- Consentement explicite du propriétaire pour l’historique et les positions sensibles.

## Lot 8 — Installation

- Tracker, VIN, plaque, photos, emplacement du boîtier et test de communication.
- Validation de la première position et confirmation/signature client.
- Maintien de WhatsApp/Google Form avant montée en volume.

## Lot 9 — Livraison

- Marchand, chauffeur, client, missions, collecte et livraison.
- Preuve photo, ETA, lien public et dispatch vers le chauffeur le plus proche.
- Module isolé du cœur sécurité GPS.

## Lot 10 — OTA, immobilisation et IA

- Firmware : catalogue, compatibilité, checksum SHA-256, canary, progression et rollback.
- Immobilisation : MFA, véhicule à l’arrêt, interlock, validation humaine et audit légal.
- Analytics : comportement chauffeur, anomalies, maintenance prédictive, scoring explicable et opt-in.

## Conditions avant démarrage

Chaque lot doit préciser son matériel compatible, ses droits commerciaux, ses migrations, ses métriques et ses critères d’acceptation. Une fonctionnalité n’est activée dans un plan qu’après validation de bout en bout.
