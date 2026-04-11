# Fastlane Match & TestFlight — Setup Guide

## Prérequis

1. **Apple Developer Account** avec accès App Store Connect
2. **Repo privé GitHub** pour les certificats : `stephancj/trackeo-certs`
3. **App Store Connect API Key** (recommandé pour CI/CD)

---

## Étape 1 : Initialiser Match (une seule fois, en local)

```bash
cd apps/mobile

# Variables d'environnement
export APPLE_ID="mamy.dev.apple@gmail.com"
export APPLE_TEAM_ID="6B673XM2ST"
export MATCH_PASSWORD="<mot de passe pour chiffrer les certificats>"
export MATCH_GIT_URL="https://github.com/stephancj/trackeo-certs.git"

# Initialiser Match — crée les certificats et profils
bundle exec fastlane ios init_match
```

Cela va :
- Créer un certificat Distribution sur Apple Developer Portal
- Créer un profil de provisioning App Store pour `com.trackeo.client.app`
- Chiffrer et pousser le tout dans `trackeo-certs`

---

## Étape 2 : Créer une App Store Connect API Key

1. Aller sur [App Store Connect → Users and Access → Integrations → App Store Connect API](https://appstoreconnect.apple.com/access/integrations/api)
2. Créer une nouvelle clé avec le rôle **App Manager**
3. Télécharger le fichier `.p8` (une seule fois !)
4. Noter le **Key ID** et **Issuer ID**

---

## Étape 3 : Configurer les GitHub Secrets

Dans le repo GitHub → Settings → Secrets and variables → Actions, ajouter :

| Secret | Description |
|--------|------------|
| `APPLE_ID` | `mamy.dev.apple@gmail.com` |
| `APPLE_TEAM_ID` | `6B673XM2ST` |
| `MATCH_PASSWORD` | Mot de passe utilisé pour chiffrer les certificats Match |
| `MATCH_GIT_URL` | `https://github.com/stephancj/trackeo-certs.git` |
| `MATCH_GIT_BASIC_AUTHORIZATION` | `base64(github_username:github_pat)` — pour accéder au repo privé |
| `APP_STORE_CONNECT_API_KEY_ID` | Key ID de l'API Key (ex: `ABCD1234EF`) |
| `APP_STORE_CONNECT_ISSUER_ID` | Issuer ID (ex: `12345678-abcd-...`) |
| `APP_STORE_CONNECT_API_KEY` | Contenu du fichier `.p8` (texte brut, avec les `-----BEGIN/END-----`) |

### Générer MATCH_GIT_BASIC_AUTHORIZATION

```bash
echo -n "stephancj:<GITHUB_PAT>" | base64
```

Le PAT GitHub doit avoir le scope `repo` pour accéder à `trackeo-certs`.

---

## Étape 4 : Tester en local

```bash
cd apps/mobile

# Sync les certificats (lecture seule)
bundle exec fastlane ios sync_certs

# Build complet + upload TestFlight
bundle exec fastlane ios release
```

---

## Étape 5 : Déployer via CI/CD

Le workflow GitHub Actions se déclenche :
- **Automatiquement** quand `apps/mobile/` change sur `main`
- **Manuellement** via `workflow_dispatch` → target `ios`

```
GitHub Actions → macos-latest → Flutter build → Match → Xcode archive → TestFlight
```

---

## Troubleshooting

### "No matching provisioning profiles found"
→ Relancer `fastlane ios init_match` en local

### "Could not create Apple Distribution certificate"
→ Vérifier que le compte Apple Developer n'a pas atteint la limite de certificats (max 3).
  Révoquer les anciens dans le Apple Developer Portal si nécessaire.

### "Authentication failed" en CI
→ Vérifier `APP_STORE_CONNECT_API_KEY` — le contenu `.p8` doit inclure les lignes BEGIN/END.
  Alternative : utiliser `FASTLANE_PASSWORD` (App-Specific Password) à la place de l'API Key.

### Build number rejected ("already used")
→ Le build number est `github.run_number` (auto-increment). Si un build a été uploadé manuellement avec le même numéro, re-run le workflow.
