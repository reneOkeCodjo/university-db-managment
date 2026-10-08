# Dictionnaire de données — Maquette pédagogique (MCD v2 · étape 2)


| Champ           | Valeur                                                                                                                   |
| --------------- | ------------------------------------------------------------------------------------------------------------------------ |
| **Projet**      | CampusData — Conception BD Formations / Étudiants                                                                        |
| **Zone MCD**    | `2. PÔLE MAQUETTE PÉDAGOGIQUE (BCC → UE → EC → ENSEIGNANT)`                                                              |
| **Fichier MCD** | `dataModels.drawio` → page `MCD v2 — construction`                                                                       |
| **Complète**    | `dictionnaire_academique.md` (étape 1) · `dictionnaire_scolarite.md` (étape 3) · `dictionnaire_evaluations.md` (étape 4) |
| **Statut**      | Étape 2 maquette **terminée** — BCC + UE + EC + ENSEIGNANT                                                               |
| **Références**  | Sujet CampusData Partie 1 · RGE FSTS Master Informatique                                                                 |




### Légende


| Colonne         | Signification                                |
| --------------- | -------------------------------------------- |
| **Attribut**    | Nom relationnel (snake_case)                 |
| **Entité**      | Entité Merise porteuse                       |
| **Id**          | Identifiant conceptuel (souligné sur le MCD) |
| **Obl.**        | Obligatoire métier                           |
| **Domaine**     | Ensemble de valeurs autorisées               |
| **Source**      | Origine (`Sujet` / `RGE` / `MCD`)            |
| **Description** | Sens métier                                  |
| **Exemple**     | Valeur illustrative                          |


> Types SQL au **MLD** uniquement.  
> Les FK ne figurent pas dans les entités MCD : elles viennent des associations.  
> **ANNEE_FORMATION** et **SEMESTRE** sont repris hors zone (pointillés) ; leur dictionnaire est dans `dictionnaire_academique.md`.



### Chaîne étape 2

```
ANNEE_FORMATION (hors zone)
        │ DÉFINIR_BCC (1,n) — (1,1)
        ▼
       BCC
        │ RATTACHER + coefficient_ue (2,2) — (1,1)
        ▼
       UE ── DISPENSER (1,1) — (1,n) ──► SEMESTRE (hors zone)
        │
        │ COMPOSER + coefficient_ec (1,n) — (1,1)
        ▼
       EC ◄── RESPONSABLE (1,1) — (1,n) ── ENSEIGNANT
```

---



## 1. BCC

Bloc de connaissances et de compétences d’une année de formation.


| Attribut          | Entité | Id  | Obl. | Domaine            | Source      | Description                    | Exemple                                 |
| ----------------- | ------ | --- | ---- | ------------------ | ----------- | ------------------------------ | --------------------------------------- |
| `id_bcc`          | BCC    | oui | oui  | Identifiant unique | MCD         | Clé primaire du BCC            | `BCC1_DFS_M1`                           |
| `code_bcc`        | BCC    | non | oui  | `BCC1`…`BCC4`      | Sujet / RGE | Code du bloc                   | `BCC1`                                  |
| `intitule`        | BCC    | non | oui  | Texte              | Sujet / RGE | Libellé du bloc                | Concevoir et programmer une application |
| `coefficient_bcc` | BCC    | non | oui  | Nombre > 0         | Sujet       | Poids dans la moyenne annuelle | `1`                                     |




### Association DÉFINIR_BCC


| Côté            | Cardinalité | Signification                       |
| --------------- | ----------- | ----------------------------------- |
| ANNEE_FORMATION | `(1,n)`     | Une année définit plusieurs BCC     |
| BCC             | `(1,1)`     | Un BCC appartient à une seule année |




### Règles


| Règle                 | Détail                                   |
| --------------------- | ---------------------------------------- |
| Plusieurs BCC / année | Exigence sujet                           |
| Composition           | Chaque BCC = **1 UE impair + 1 UE pair** |
| Compensation          | **Intra-BCC** uniquement (pas inter-BCC) |
| Validation BCC        | Moyenne des 2 UE ≥ 10                    |




### Jeux d’exemples — BCC


| id_bcc        | code_bcc | intitule                                                                | coefficient_bcc | id_annee_formation |
| ------------- | -------- | ----------------------------------------------------------------------- | --------------- | ------------------ |
| `BCC1_DFS_M1` | `BCC1`   | Concevoir et programmer une application informatique multiplateforme    | 1               | `AF_MINF_DFS_M1`   |
| `BCC2_DFS_M1` | `BCC2`   | Piloter et déployer une application informatique                        | 1               | `AF_MINF_DFS_M1`   |
| `BCC4_DE_M1`  | `BCC4`   | Évaluer et élaborer de nouvelles connaissances à partir de plusieurs BD | 1               | `AF_MINF_DE_M1`    |


---



## 2. UE

Unité d’enseignement rattachée à un BCC et dispensée dans un semestre.


| Attribut       | Entité | Id  | Obl. | Domaine            | Source      | Description          | Exemple                      |
| -------------- | ------ | --- | ---- | ------------------ | ----------- | -------------------- | ---------------------------- |
| `id_ue`        | UE     | oui | oui  | Identifiant unique | MCD         | Clé primaire         | `UE1.1_DFS_M1`               |
| `code_ue`      | UE     | non | oui  | Texte court        | Sujet / RGE | Code UE (ex. UE 1.1) | `UE 1.1`                     |
| `intitule`     | UE     | non | oui  | Texte              | Sujet / RGE | Libellé de l’UE      | Concevoir et programmer (S1) |
| `credits_ects` | UE     | non | oui  | Entier > 0         | Sujet       | Crédits ECTS de l’UE | `6`                          |


> Renommage vs MCD v1 : `intitule_ue` → `intitule` ; `ects_ue` → `credits_ects`.



### Association RATTACHER


| Côté | Cardinalité | Attribut d’association | Signification                   |
| ---- | ----------- | ---------------------- | ------------------------------- |
| BCC  | `(2,2)`     | `coefficient_ue`       | Exactement **2** UE par BCC     |
| UE   | `(1,1)`     |                        | Une UE appartient à un seul BCC |


> Au MLD : `ue.id_bcc` (FK) + `coefficient_ue` (sur UE ou table d’asso).



### Association DISPENSER


| Côté     | Cardinalité | Signification                             |
| -------- | ----------- | ----------------------------------------- |
| UE       | `(1,1)`     | Une UE est dispensée dans **un** semestre |
| SEMESTRE | `(1,n)`     | Un semestre accueille plusieurs UE        |




### Règles


| Règle           | Détail                                                                                     |
| --------------- | ------------------------------------------------------------------------------------------ |
| 2 UE / BCC      | Une en semestre **impair** (`numero_semestre = 1`), une en **pair** (`= 2`)                |
| Cohérence année | Le semestre de l’UE doit appartenir à la **même** `ANNEE_FORMATION` que le BCC (CHECK MLD) |
| Validation UE   | Moyenne pondérée des EC ≥ 10 ; sinon compensation possible **dans le BCC**                 |




### Jeux d’exemples — UE


| id_ue          | code_ue  | intitule                     | credits_ects | coefficient_ue | id_bcc        | id_semestre    |
| -------------- | -------- | ---------------------------- | ------------ | -------------- | ------------- | -------------- |
| `UE1.1_DFS_M1` | `UE 1.1` | Concevoir et programmer (S1) | 6            | 1              | `BCC1_DFS_M1` | `SEM_DFS_M1_1` |
| `UE1.2_DFS_M1` | `UE 1.2` | Concevoir et programmer (S2) | 6            | 1              | `BCC1_DFS_M1` | `SEM_DFS_M1_2` |


---



## 3. EC

Élément constitutif d’une UE (sujet : intitulé, volumes CM/TD/TP, coefficient ; une note finale /20 par étudiant et par EC).


| Attribut   | Entité | Id  | Obl. | Domaine            | Source      | Description               | Exemple           |
| ---------- | ------ | --- | ---- | ------------------ | ----------- | ------------------------- | ----------------- |
| `id_ec`    | EC     | oui | oui  | Identifiant unique | MCD         | Clé primaire de l’EC      | `EC_DFS_M1_PROG`  |
| `code_ec`  | EC     | non | oui  | Texte court        | Sujet / RGE | Code de l’élément         | `PROG`            |
| `intitule` | EC     | non | oui  | Texte              | Sujet / RGE | Libellé de l’EC           | Programmation Web |
| `vol_cm`   | EC     | non | oui  | Entier ≥ 0         | Sujet       | Heures de cours magistral | `12`              |
| `vol_td`   | EC     | non | oui  | Entier ≥ 0         | Sujet       | Heures de TD              | `18`              |
| `vol_tp`   | EC     | non | oui  | Entier ≥ 0         | Sujet       | Heures de TP              | `12`              |


> Renommage vs MCD v1 : `intitule_ec` → `intitule`. Volumes : `vol_cm` / `vol_td` / `vol_tp`.



### Association COMPOSER


| Côté | Cardinalité | Attribut d’association | Signification                   |
| ---- | ----------- | ---------------------- | ------------------------------- |
| UE   | `(1,n)`     | `coefficient_ec`       | Une UE contient plusieurs EC    |
| EC   | `(1,1)`     |                        | Un EC appartient à une seule UE |


> Au MLD : `ec.id_ue` (FK) + `coefficient_ec` (sur EC ou table d’asso).



### Règles


| Règle        | Détail                                                                     |
| ------------ | -------------------------------------------------------------------------- |
| Note UE      | Moyenne **pondérée** des EC (`coefficient_ec`) ; UE validée si ≥ 10        |
| Note EC      | **Une** note finale /20 par étudiant et par EC (sujet — hors détail CC/CT) |
| Compensation | Si UE < 10, compensation possible **dans le BCC** uniquement               |
| Volumes      | Entiers ≥ 0 ; au moins un volume > 0 recommandé (règle métier optionnelle) |




### Jeux d’exemples — EC


| id_ec            | code_ec | intitule             | vol_cm | vol_td | vol_tp | coefficient_ec | id_ue          |
| ---------------- | ------- | -------------------- | ------ | ------ | ------ | -------------- | -------------- |
| `EC_DFS_M1_PROG` | `PROG`  | Programmation Web    | 12     | 18     | 12     | 2              | `UE1.1_DFS_M1` |
| `EC_DFS_M1_MOB`  | `MOB`   | Développement Mobile | 9      | 12     | 18     | 1              | `UE1.1_DFS_M1` |


---



## 4. ENSEIGNANT

Personne responsable pédagogique d’un ou plusieurs EC (consultation maquette ; saisie des notes de ses EC).


| Attribut        | Entité     | Id  | Obl. | Domaine            | Source | Description             | Exemple                                             |
| --------------- | ---------- | --- | ---- | ------------------ | ------ | ----------------------- | --------------------------------------------------- |
| `id_enseignant` | ENSEIGNANT | oui | oui  | Identifiant unique | MCD    | Clé primaire            | `ENS_DUPONT`                                        |
| `nom`           | ENSEIGNANT | non | oui  | Texte              | Sujet  | Nom de famille          | Dupont                                              |
| `prenom`        | ENSEIGNANT | non | oui  | Texte              | Sujet  | Prénom                  | Marie                                               |
| `email`         | ENSEIGNANT | non | oui  | Email unique       | Sujet  | Adresse professionnelle | [dupont@univ-corse.fr](mailto:dupont@univ-corse.fr) |
| `statut`        | ENSEIGNANT | non | non  | Texte              | MCD    | Statut pédagogique      | Titulaire                                           |


> Renommage vs MCD v1 : `nom_enseignant` → `nom` ; `prenom_enseignant` → `prenom` ; `email_enseignant` → `email` ; `statut_enseignant` → `statut`.



### Association RESPONSABLE


| Côté       | Cardinalité | Signification                                       |
| ---------- | ----------- | --------------------------------------------------- |
| ENSEIGNANT | `(1,n)`     | Un enseignant peut être responsable de plusieurs EC |
| EC         | `(1,1)`     | Un EC a **un** responsable (saisie notes / R2)      |


> Au MLD : `ec.id_enseignant` (FK). Pas de lien enseignant → UE : la composition reste **COMPOSER**.



### Règles


| Règle  | Détail                                                                           |
| ------ | -------------------------------------------------------------------------------- |
| Droits | Consulte programmes ; saisit uniquement les notes des EC dont il est responsable |
| R2     | EC + enseignant responsable + filtre notes / moyenne annuelle                    |
| Email  | UNIQUE au MLD                                                                    |




### Jeux d’exemples — ENSEIGNANT


| id_enseignant | nom    | prenom | email                                               | statut    | EC responsables (ex.) |
| ------------- | ------ | ------ | --------------------------------------------------- | --------- | --------------------- |
| `ENS_DUPONT`  | Dupont | Marie  | [dupont@univ-corse.fr](mailto:dupont@univ-corse.fr) | Titulaire | `EC_DFS_M1_PROG`      |
| `ENS_ROSSI`   | Rossi  | Jean   | [rossi@univ-corse.fr](mailto:rossi@univ-corse.fr)   | Vacataire | `EC_DFS_M1_MOB`       |


---



## 5. Attributs d’association (récap)


| Association     | Attribut         | Porté par (MLD)             | Description               |
| --------------- | ---------------- | --------------------------- | ------------------------- |
| **RATTACHER**   | `coefficient_ue` | table asso ou `UE`          | Poids de l’UE dans le BCC |
| **DISPENSER**   | —                | FK `ue.id_semestre`         | Lien UE → semestre        |
| **DÉFINIR_BCC** | —                | FK `bcc.id_annee_formation` | Lien année → BCC          |
| **COMPOSER**    | `coefficient_ec` | table asso ou `EC`          | Poids de l’EC dans l’UE   |
| **RESPONSABLE** | —                | FK `ec.id_enseignant`       | Lien enseignant → EC      |


---



## 6. Note ANNEE / BCC / UE / SEMESTRE

**ANNEE_FORMATION** et **SEMESTRE** sont hors zone (reprise visuelle). Le modèle conserve :

1. UE → BCC (via RATTACHER)
2. UE → SEMESTRE (via DISPENSER)

L’intégrité « même année » se formalise au **MLD** (CHECK).

---

*Dictionnaire zone 2 — étape 2 **terminée** ·* `MCD v2 — construction` *· BCC → UE → EC ← ENSEIGNANT.*