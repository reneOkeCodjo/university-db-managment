# Dictionnaire de données — Scolarité (MCD v2 · étape 3)

| Champ | Valeur |
|-------|--------|
| **Projet** | CampusData — Conception BD Formations / Étudiants |
| **Zone MCD** | `3. PÔLE SCOLARITÉ (étape 3)` |
| **Fichier MCD** | `dataModels.drawio` → page `MCD v2 — construction` |
| **Complète** | `dictionnaire_academique.md` · `dictionnaire_maquette.md` · `dictionnaire_evaluations.md` |
| **Statut** | Étape 3 terminée — ETUDIANT / INSCRIPTION |
| **Références** | Sujet CampusData Partie 1 (triggers capacité & ≤ 2 inscriptions) |

### Légende

| Colonne | Signification |
|---------|----------------|
| **Attribut** | Nom relationnel (snake_case) |
| **Entité** | Entité Merise porteuse |
| **Id** | Identifiant conceptuel (souligné sur le MCD) |
| **Obl.** | Obligatoire métier |
| **Domaine** | Ensemble de valeurs autorisées |
| **Source** | Origine (`Sujet` / `MCD`) |
| **Description** | Sens métier |
| **Exemple** | Valeur illustrative |

> Types SQL et FK au **MLD** uniquement.  
> Les FK viennent des associations (pas listées dans les entités MCD).

### Chaîne

```
ETUDIANT ── EFFECTUER (1,n)—(1,1) ──► INSCRIPTION ── CONCERNER (1,1)—(1,n) ──► ANNEE_FORMATION
                                                                         (capacite_accueil)
```

---

## 1. ETUDIANT

Personne inscrite dans une (ou plusieurs) années de formation au fil du temps.

| Attribut | Entité | Id | Obl. | Domaine | Source | Description | Exemple |
|----------|--------|:--:|:----:|---------|--------|-------------|---------|
| `id_etudiant` | ETUDIANT | oui | oui | Identifiant unique | MCD | Clé primaire | `ETU_10042` |
| `ine` | ETUDIANT | non | oui | Identifiant national | Sujet | INE (unique) | `1234567890A` |
| `nom` | ETUDIANT | non | oui | Texte | Sujet | Nom de famille | Martin |
| `prenom` | ETUDIANT | non | oui | Texte | Sujet | Prénom | Léa |
| `date_naissance` | ETUDIANT | non | oui | Date | Sujet | Date de naissance | `2003-04-12` |
| `email` | ETUDIANT | non | oui | Email unique | Sujet | Courriel | lea.martin@etu.univ-corse.fr |

> Renommage vs MCD v1 : `nom_etudiant` → **`nom`** ; `prenom_etudiant` → **`prenom`** ; `email_etudiant` → **`email`**.

### Association EFFECTUER

| Côté | Cardinalité | Signification |
|------|:-------------:|---------------|
| ETUDIANT | `(1,n)` | Un étudiant a au moins une inscription (peuplement) |
| INSCRIPTION | `(1,1)` | Une inscription appartient à un seul étudiant |

### Règles

| Règle | Détail |
|-------|--------|
| Peuplement | ≥ 1 inscription / étudiant |
| Unicité | `ine` et `email` UNIQUE au MLD |

---

## 2. INSCRIPTION

Inscription d’un étudiant sur une **année de formation** pour une **année universitaire** donnée.

| Attribut | Entité | Id | Obl. | Domaine | Source | Description | Exemple |
|----------|--------|:--:|:----:|---------|--------|-------------|---------|
| `id_inscription` | INSCRIPTION | oui | oui | Identifiant unique | MCD | Clé primaire | `INS_2024_ETU10042_M1` |
| `annee_universitaire` | INSCRIPTION | non | oui | `AAAA-AAAA` | Sujet | Année civile d’inscription | `2024-2025` |
| `date_inscription` | INSCRIPTION | non | oui | Date | Sujet | Date d’effet | `2024-09-01` |
| `statut` | INSCRIPTION | non | non | Texte | MCD | État administratif | `active` |

### Association CONCERNER

| Côté | Cardinalité | Signification |
|------|:-------------:|---------------|
| INSCRIPTION | `(1,1)` | Une inscription vise une seule année de formation |
| ANNEE_FORMATION | `(1,n)` | Une année accueille plusieurs inscriptions |

> Au MLD : `inscription.id_etudiant`, `inscription.id_annee_formation`.

### Règles / triggers (sujet)

| Règle | Détail |
|-------|--------|
| Capacité | Refuser si nb d’inscrits pour `(ANNEE_FORMATION, annee_universitaire)` ≥ `capacite_accueil` |
| Doublons année diplôme | Refuser si **> 2** inscriptions pour le même `(étudiant, ANNEE_FORMATION)` |
| Cursus | Dates / niveaux cohérents (pas L2 avant L1) — contrôle peuplement / trigger optionnel |
| R1 | Agrégats par année de formation × année universitaire |

### Jeux d’exemples — INSCRIPTION

| id_inscription | id_etudiant | id_annee_formation | annee_universitaire | date_inscription | statut |
|----------------|-------------|--------------------|---------------------|------------------|--------|
| `INS_24_10042_M1` | `ETU_10042` | `AF_MINF_DFS_M1` | `2024-2025` | `2024-09-01` | `active` |
| `INS_25_10042_M2` | `ETU_10042` | `AF_MINF_DFS_M2` | `2025-2026` | `2025-09-01` | `active` |

---

## 3. Attributs d’association (récap)

| Association | Attribut | Porté par (MLD) | Description |
|-------------|----------|-----------------|-------------|
| **EFFECTUER** | — | FK `inscription.id_etudiant` | Étudiant → inscription |
| **CONCERNER** | — | FK `inscription.id_annee_formation` | Inscription → année |

---

## 4. Suite

| Document / suite | Contenu |
|------------------|---------|
| **`dictionnaire_evaluations.md`** | Association **NOTER** · pôle 4 MCD |
| **Hors MCD** | Délibérations / archives → procédures PL/pgSQL |

---

*Dictionnaire pôle scolarité — aligné `MCD v2 — construction` (INSCRIPTION → ANNEE_FORMATION).*
