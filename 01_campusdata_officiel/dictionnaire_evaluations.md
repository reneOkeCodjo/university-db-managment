# Dictionnaire de données — Évaluations & notes (MCD v2 · étape 4)

| Champ | Valeur |
|-------|--------|
| **Projet** | CampusData — Conception BD Formations / Étudiants |
| **Zone MCD** | `4. PÔLE ÉVALUATIONS & NOTES (étape 4)` |
| **Fichier MCD** | `dataModels.drawio` → page `MCD v2 — construction` |
| **Complète** | `dictionnaire_academique.md` · `dictionnaire_maquette.md` · `dictionnaire_scolarite.md` |
| **Statut** | Étape 4 terminée pour NOTER — délibérations = PL/pgSQL (hors MCD) |
| **Références** | Sujet CampusData Partie 1 (1 note / EC ; compensation ; délibérations) |

### Légende

| Colonne | Signification |
|---------|----------------|
| **Attribut** | Nom relationnel (snake_case) |
| **Porté par** | Association Merise ou table MLD |
| **Id** | Identifiant conceptuel |
| **Obl.** | Obligatoire métier |
| **Domaine** | Ensemble de valeurs autorisées |
| **Source** | Origine (`Sujet` / `MCD`) |
| **Description** | Sens métier |
| **Exemple** | Valeur illustrative |

> Types SQL et FK au **MLD**.  
> Les FK viennent des associations.  
> Moyennes UE / BCC / délibérations **ne sont pas** des attributs persistés du MCD étape 4 : ce sont des **calculs** (procédures).

### Chaîne

```
INSCRIPTION (0,n) ── NOTER (note_ec) ── (0,n) EC
```

Au MLD : table `note_ec` (`id_inscription`, `id_ec`, `note_ec`) + UNIQUE `(id_inscription, id_ec)`.

---

## 1. Association NOTER

Relie une **inscription** à un **EC** avec la note finale de l’étudiant pour cet EC (dans le contexte de cette inscription / année).

| Attribut | Porté par | Id | Obl. | Domaine | Source | Description | Exemple |
|----------|-----------|:--:|:----:|---------|--------|-------------|---------|
| `note_ec` | NOTER | non | oui | `[0 ; 20]` | Sujet | Note finale de l’EC | `14.5` |

### Cardinalités

| Côté | Cardinalité | Signification |
|------|:-------------:|---------------|
| INSCRIPTION | `(0,n)` | Une inscription peut avoir des notes sur plusieurs EC (ou aucune encore) |
| EC | `(0,n)` | Un EC est noté pour plusieurs inscriptions |

### Pourquoi INSCRIPTION et pas ETUDIANT ?

Une même personne peut s’inscrire plusieurs fois (années univ. différentes, redoublement). La note est relative à **l’inscription** (année de formation + année universitaire), pas à l’étudiant seul — requis pour R1–R3 et les triggers.

### Règles

| Règle | Détail |
|-------|--------|
| Une note / couple | UNIQUE `(id_inscription, id_ec)` au MLD |
| Domaine | CHECK `note_ec BETWEEN 0 AND 20` |
| Saisie | Enseignant **responsable** de l’EC (rôle + RESPONSABLE) |
| Simplification sujet | Pas de détail CC/CT, sessions, absences ABI/ABJ |

### Jeux d’exemples

| id_inscription | id_ec | note_ec |
|----------------|-------|---------|
| `INS_24_10042_M1` | `EC_DFS_M1_PROG` | `14.5` |
| `INS_24_10042_M1` | `EC_DFS_M1_MOB` | `12.0` |

---

## 2. Règles de calcul (hors attributs MCD)

Documentées ici pour le MLD / PL/pgSQL ; **pas** d’entités moyennes sur le MCD.

| Calcul | Formule / règle (sujet) |
|--------|-------------------------|
| Note UE | Moyenne **pondérée** des `note_ec` (`coefficient_ec`) |
| Validation UE | Note UE ≥ 10 |
| Compensation | Si UE < 10, possible **dans le BCC** uniquement (pas inter-BCC) |
| Note BCC | Moyenne pondérée des **2** UE (`coefficient_ue`) |
| Validation BCC | Note BCC ≥ 10 |
| Délib. semestre impair | Semestre acquis si toutes les UE du semestre ≥ 10 |
| Délib. annuelle | Année validée si **tous** les BCC validés ; moyenne annuelle = BCC pondérés (`coefficient_bcc`) |
| ADMIS / AJOURNÉ | Résultat de la procédure de délibération annuelle |

---

## 3. Hors scope MCD étape 4 (plus tard / procédures)

| Élément | Traitement |
|---------|------------|
| Délibération semestre / annuelle | Procédures PL/pgSQL (sujet § procédures 1–2) |
| Fiche de résultats | Procédure 3 |
| `resultats_archives` | Procédure 4 (archivage > 1 an) |

---

## 4. Attributs d’association (récap)

| Association | Attribut | Porté par (MLD) | Description |
|-------------|----------|-----------------|-------------|
| **NOTER** | `note_ec` | table `note_ec` | Note finale /20 |

---

*Dictionnaire pôle évaluations — aligné `MCD v2 — construction` · NOTER (INSCRIPTION × EC).*
