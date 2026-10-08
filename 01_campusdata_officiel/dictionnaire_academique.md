# Dictionnaire de données — CampusData (MCD v2)

| Champ | Valeur |
|-------|--------|
| **Projet** | CampusData — Conception BD Formations / Étudiants |
| **Université** | Università di Corsica – Pasquale Paoli |
| **Zone MCD** | `1. PÔLE STRUCTURE ACADÉMIQUE` |
| **Fichier MCD** | `dataModels.drawio` → page `MCD v2 — construction` |
| **Complète** | `dictionnaire_maquette.md` · `dictionnaire_scolarite.md` · `dictionnaire_evaluations.md` |
| **Statut** | Étape 1 terminée — structure académique complète |
| **Références** | Sujet Partie 1 CampusData · RGE FSTS Master Informatique · Catalogue Studià · RNCP |

### Légende

| Colonne | Signification |
|---------|----------------|
| **Attribut** | Nom relationnel (snake_case) |
| **Entité** | Entité Merise porteuse |
| **Id** | Identifiant conceptuel (souligné sur le MCD) |
| **Obl.** | Obligatoire métier |
| **Domaine** | Ensemble de valeurs autorisées |
| **Source** | Origine (`Sujet` / `RGE` / `Catalogue` / `RNCP` / `MCD`) |
| **Description** | Sens métier |
| **Exemple** | Valeur illustrative |

> Les types SQL seront précisés au **MLD** — absents du MCD.  
> Les clés étrangères ne figurent pas dans les entités : elles viennent des associations.

---

## 1. FORMATION

Diplôme universitaire (Licence ou Master) proposé dans les filières informatiques.

| Attribut | Entité | Id | Obl. | Domaine | Source | Description | Exemple |
|----------|--------|:--:|:----:|---------|--------|-------------|---------|
| `id_formation` | FORMATION | oui | oui | Identifiant unique | MCD | Clé primaire de la formation | `FOR_MINF` |
| `intitule` | FORMATION | non | oui | Texte libre | Sujet / RNCP | Intitulé officiel du diplôme | Master mention Informatique |
| `type_diplome` | FORMATION | non | oui | `{Licence, Master}` | Sujet | Grade / type de diplôme | `Master` |
| `duree_annees` | FORMATION | non | oui | `{2, 3}` | Sujet | Durée du cursus en années | `2` |
| `composante` | FORMATION | non | oui | Texte / code UFR | Catalogue Corse | Faculté, école ou institut porteur | `FSTS` |
| `code_rncp` | FORMATION | non | non | `RNCP` + chiffres | RNCP | Code fiche France compétences | `RNCP39278` |
| `niveau_eqf` | FORMATION | non | non | `NIV6`, `NIV7`… | RNCP | Niveau européen EQF | `NIV7` |

### Règles d’intégrité (CHECK au MLD)

| Règle | Expression |
|-------|------------|
| Cohérence durée / type | `(type_diplome = 'Licence' AND duree_annees = 3) OR (type_diplome = 'Master' AND duree_annees = 2)` |
| Capacité d’accueil | Portée par `ANNEE_FORMATION`, pas FORMATION |
| Niveau EQF indicatif | Licence → `NIV6` ; Master → `NIV7` |

### Jeux d’exemples — FORMATION

| id_formation | intitule | type_diplome | duree_annees | composante | code_rncp | niveau_eqf |
|--------------|----------|--------------|--------------|------------|-----------|------------|
| `FOR_MINF` | Master mention Informatique | Master | 2 | `FSTS` | `RNCP39278` | `NIV7` |
| `FOR_L3INFO` | Licence Informatique | Licence | 3 | `FSTS` | *(à renseigner)* | `NIV6` |

> **composante** : filtre Studià *Faculté, école, institut* (ex. FSTS = code catalogue `CST`).

---

## 2. PARCOURS

Spécialisation **optionnelle** d’une formation. Attributs **confirmés** (catalogue Studià + RGE FSTS Art.1 + sujet R2).

| Attribut | Entité | Id | Obl. | Domaine | Source | Description | Exemple |
|----------|--------|:--:|:----:|---------|--------|-------------|---------|
| `id_parcours` | PARCOURS | oui | oui | Identifiant unique | MCD | Clé primaire du parcours | `PAR_DFS` |
| `code_parcours` | PARCOURS | non | oui | Sigle court | Sujet / RGE | Sigle métier (filtre R2) | `DFS` |
| `intitule` | PARCOURS | non | oui | Texte | Catalogue / RGE | Libellé officiel (label Studià « Parcours ») | Développeur Full Stack Web et Mobiles |

### Décision de recherche

| Décision | Détail |
|----------|--------|
| **Confirmé** | `id_parcours`, `code_parcours` |
| **Renommé** | `nom_parcours` → `intitule` (aligné FORMATION + catalogue) |
| **Non ajouté** | `id_fiche` Studià, ECTS, durée, fonctionnement, régime FI/FA |
| **Hors entité** | Niveau / ECTS / Durée / Fonctionnement → restent sur **FORMATION** |

Sources : fiches Studià Master Info (DFS / DE) · RGE FSTS 2025-2026 Art.1 (*DFS* / *DE*, S1 commun) · sujet CampusData R2.

### Association PROPOSER

| Côté | Cardinalité | Signification |
|------|:-------------:|---------------|
| FORMATION | `(0,n)` | Une formation **peut** n’avoir aucun parcours |
| PARCOURS | `(1,1)` | Un parcours appartient à une seule formation |

> Au MLD : `parcours.id_formation` (FK) + UNIQUE `(id_formation, code_parcours)`.

### Convention projet — parcours par défaut

| code | intitule | Usage |
|------|----------|--------|
| `TRC` | **Tronc commun** | Formation sans spécialisation, ou rattachement par défaut |

### Jeux d’exemples — PARCOURS

| id_parcours | code_parcours | intitule | id_formation |
|-------------|---------------|----------|--------------|
| `PAR_DFS` | `DFS` | Développeur Full Stack Web et Mobiles | `FOR_MINF` |
| `PAR_DE` | `DE` | Data Engineer | `FOR_MINF` |
| `PAR_L3TRC` | `TRC` | Tronc commun | `FOR_L3INFO` |

---

## 3. ANNEE_FORMATION

Année d’études d’un parcours (ex. M1, M2). Porte la **capacité d’accueil** exigée par le sujet et le trigger d’inscription.

| Attribut | Entité | Id | Obl. | Domaine | Source | Description | Exemple |
|----------|--------|:--:|:----:|---------|--------|-------------|---------|
| `id_annee_formation` | ANNEE_FORMATION | oui | oui | Identifiant unique | MCD | Clé primaire | `AF_MINF_DFS_M1` |
| `niveau_annee` | ANNEE_FORMATION | non | oui | `{L1, L2, L3, M1, M2}` | Sujet | Rang dans le cursus | `M1` |
| `capacite_accueil` | ANNEE_FORMATION | non | oui | Entier > 0 | Sujet | Nb max d’inscrits | `40` |

> Renommage vs MCD v1 : `nb_max_etudiants` → **`capacite_accueil`** (vocabulaire scolarité / cadre CampusData).

### Association COMPORTER

| Côté | Cardinalité | Signification |
|------|:-------------:|---------------|
| PARCOURS | `(1,n)` | Un parcours comporte une ou plusieurs années |
| ANNEE_FORMATION | `(1,1)` | Une année appartient à un seul parcours |

### Règles d’intégrité

| Règle | Détail |
|-------|--------|
| Cohérence cursus | Master → `{M1, M2}` ; Licence → `{L1, L2, L3}` (CHECK au MLD avec `duree_annees`) |
| Trigger capacité | Refuser une inscription si effectif ≥ `capacite_accueil` |
| Peuplement | Inscrits par année ∈ `[2 ; capacite_accueil]` |
| Année universitaire | Ex. `2024-2025` → attribut d’**INSCRIPTION**, pas d’ANNEE_FORMATION |

### Jeux d’exemples — ANNEE_FORMATION

| id_annee_formation | niveau_annee | capacite_accueil | id_parcours |
|--------------------|--------------|------------------|-------------|
| `AF_MINF_DFS_M1` | `M1` | 40 | `PAR_DFS` |
| `AF_MINF_DFS_M2` | `M2` | 35 | `PAR_DFS` |
| `AF_MINF_DE_M1` | `M1` | 40 | `PAR_DE` |
| `AF_L3TRC_L3` | `L3` | 50 | `PAR_L3TRC` |

---

## 4. SEMESTRE

Découpage d’une année de formation en **exactement 2** semestres (impair / pair).

| Attribut | Entité | Id | Obl. | Domaine | Source | Description | Exemple |
|----------|--------|:--:|:----:|---------|--------|-------------|---------|
| `id_semestre` | SEMESTRE | oui | oui | Identifiant unique | MCD | Clé primaire | `SEM_DFS_M1_1` |
| `numero_semestre` | SEMESTRE | non | oui | `{1, 2}` | Sujet | `1` = impair, `2` = pair (dans l’année) | `1` |

> Pas de `est_impair` redondant : dérivable de `numero_semestre = 1`.

### Association DÉCOUPER

| Côté | Cardinalité | Signification |
|------|:-------------:|---------------|
| ANNEE_FORMATION | `(2,2)` | Chaque année est découpée en **exactement 2** semestres |
| SEMESTRE | `(1,1)` | Un semestre appartient à une seule année |

### Règles d’intégrité

| Règle | Détail |
|-------|--------|
| Exactement 2 / année | Cardinalité `(2,2)` + UNIQUE `(id_annee_formation, numero_semestre)` au MLD |
| Impair / pair | `1` → délibération semestre impair ; `2` → fin d’année / délibération annuelle |
| Numérotation RGE (S1…S4) | Calculable : M1→1–2, M2→3–4 — pas stockée ici (choix projet) |

### Jeux d’exemples — SEMESTRE

| id_semestre | numero_semestre | Période | id_annee_formation |
|-------------|-----------------|---------|--------------------|
| `SEM_DFS_M1_1` | `1` | Impair | `AF_MINF_DFS_M1` |
| `SEM_DFS_M1_2` | `2` | Pair | `AF_MINF_DFS_M1` |
| `SEM_DE_M1_1` | `1` | Impair | `AF_MINF_DE_M1` |

---

## 5. Suite — dictionnaires liés

| Document | Contenu |
|----------|---------|
| **`dictionnaire_maquette.md`** | BCC, UE, EC, ENSEIGNANT · DÉFINIR_BCC / RATTACHER / DISPENSER / COMPOSER / RESPONSABLE |
| **`dictionnaire_scolarite.md`** | ETUDIANT, INSCRIPTION · EFFECTUER / CONCERNER |
| **`dictionnaire_evaluations.md`** | NOTE · NOTER |
| **Hors MCD** | Procédures PL/pgSQL (délibérations, triggers capacité) |

---

*Étape 1 (structure académique) complète sur `MCD v2 — construction`.*
