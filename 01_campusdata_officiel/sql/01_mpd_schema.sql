-- =============================================================================
-- CampusData — MPD (Modèle Physique de Données) PostgreSQL
-- Source : MLD v2 — SQL (dataModels.drawio) + dictionnaires MCD v2
-- Hors scope ici : triggers, procédures PL/pgSQL, rôles, peuplement
-- =============================================================================

BEGIN;

DROP TABLE IF EXISTS note_ec CASCADE;
DROP TABLE IF EXISTS resultats_archives CASCADE;
DROP TABLE IF EXISTS inscription CASCADE;
DROP TABLE IF EXISTS etudiant CASCADE;
DROP TABLE IF EXISTS composer CASCADE;
DROP TABLE IF EXISTS ec CASCADE;
DROP TABLE IF EXISTS rattacher CASCADE;
DROP TABLE IF EXISTS ue CASCADE;
DROP TABLE IF EXISTS enseignant CASCADE;
DROP TABLE IF EXISTS bcc CASCADE;
DROP TABLE IF EXISTS semestre CASCADE;
DROP TABLE IF EXISTS annee_formation CASCADE;
DROP TABLE IF EXISTS parcours CASCADE;
DROP TABLE IF EXISTS formation CASCADE;

-- -----------------------------------------------------------------------------
-- Structure académique
-- -----------------------------------------------------------------------------

CREATE TABLE formation (
    id_formation   VARCHAR(20)  PRIMARY KEY,
    intitule       VARCHAR(150) NOT NULL,
    type_diplome   VARCHAR(20)  NOT NULL,
    duree_annees   INTEGER      NOT NULL,
    composante     VARCHAR(50)  NOT NULL,
    code_rncp      VARCHAR(20),
    niveau_eqf     VARCHAR(10),
    CONSTRAINT chk_formation_type_duree CHECK (
        (type_diplome = 'Licence' AND duree_annees = 3)
        OR (type_diplome = 'Master' AND duree_annees = 2)
    ),
    CONSTRAINT chk_formation_type CHECK (type_diplome IN ('Licence', 'Master'))
);

CREATE TABLE parcours (
    id_parcours    VARCHAR(20)  PRIMARY KEY,
    id_formation   VARCHAR(20)  NOT NULL REFERENCES formation (id_formation),
    code_parcours  VARCHAR(20)  NOT NULL,
    intitule       VARCHAR(150) NOT NULL,
    CONSTRAINT uq_parcours_formation_code UNIQUE (id_formation, code_parcours)
);

CREATE INDEX idx_parcours_formation ON parcours (id_formation);

CREATE TABLE annee_formation (
    id_annee_formation VARCHAR(20) PRIMARY KEY,
    id_parcours        VARCHAR(20) NOT NULL REFERENCES parcours (id_parcours),
    niveau_annee       VARCHAR(10) NOT NULL,
    capacite_accueil   INTEGER     NOT NULL,
    CONSTRAINT chk_annee_niveau CHECK (niveau_annee IN ('L1', 'L2', 'L3', 'M1', 'M2')),
    CONSTRAINT chk_annee_capacite CHECK (capacite_accueil > 0)
);

CREATE INDEX idx_annee_parcours ON annee_formation (id_parcours);

CREATE TABLE semestre (
    id_semestre          VARCHAR(20) PRIMARY KEY,
    id_annee_formation   VARCHAR(20) NOT NULL REFERENCES annee_formation (id_annee_formation),
    numero_semestre      INTEGER     NOT NULL,
    CONSTRAINT chk_semestre_numero CHECK (numero_semestre IN (1, 2)),
    CONSTRAINT uq_semestre_annee_numero UNIQUE (id_annee_formation, numero_semestre)
);

CREATE INDEX idx_semestre_annee ON semestre (id_annee_formation);

-- -----------------------------------------------------------------------------
-- Maquette pédagogique
-- -----------------------------------------------------------------------------

CREATE TABLE bcc (
    id_bcc               VARCHAR(20)    PRIMARY KEY,
    id_annee_formation   VARCHAR(20)    NOT NULL REFERENCES annee_formation (id_annee_formation),
    code_bcc             VARCHAR(10)    NOT NULL,
    intitule             VARCHAR(200)   NOT NULL,
    coefficient_bcc      NUMERIC(5, 2)  NOT NULL,
    CONSTRAINT chk_bcc_coeff CHECK (coefficient_bcc > 0),
    CONSTRAINT uq_bcc_annee_code UNIQUE (id_annee_formation, code_bcc)
);

CREATE INDEX idx_bcc_annee ON bcc (id_annee_formation);

CREATE TABLE enseignant (
    id_enseignant VARCHAR(20)  PRIMARY KEY,
    nom           VARCHAR(50)  NOT NULL,
    prenom        VARCHAR(50)  NOT NULL,
    email         VARCHAR(100) NOT NULL,
    statut        VARCHAR(50),
    CONSTRAINT uq_enseignant_email UNIQUE (email)
);

CREATE TABLE ue (
    id_ue          VARCHAR(20)  PRIMARY KEY,
    id_semestre    VARCHAR(20)  NOT NULL REFERENCES semestre (id_semestre),
    code_ue        VARCHAR(20)  NOT NULL,
    intitule       VARCHAR(150) NOT NULL,
    credits_ects   INTEGER      NOT NULL,
    CONSTRAINT chk_ue_ects CHECK (credits_ects > 0)
);

CREATE INDEX idx_ue_semestre ON ue (id_semestre);

-- Association RATTACHER (BCC ↔ UE) + coefficient_ue
CREATE TABLE rattacher (
    id_bcc          VARCHAR(20)   NOT NULL REFERENCES bcc (id_bcc),
    id_ue           VARCHAR(20)   NOT NULL REFERENCES ue (id_ue),
    coefficient_ue  NUMERIC(5, 2) NOT NULL,
    CONSTRAINT pk_rattacher PRIMARY KEY (id_bcc, id_ue),
    CONSTRAINT uq_rattacher_ue UNIQUE (id_ue),  -- UE ↔ 1 BCC
    CONSTRAINT chk_rattacher_coeff CHECK (coefficient_ue > 0)
);

CREATE INDEX idx_rattacher_bcc ON rattacher (id_bcc);

CREATE TABLE ec (
    id_ec          VARCHAR(20)  PRIMARY KEY,
    id_enseignant  VARCHAR(20)  NOT NULL REFERENCES enseignant (id_enseignant),
    code_ec        VARCHAR(20)  NOT NULL,
    intitule       VARCHAR(150) NOT NULL,
    vol_cm         INTEGER      NOT NULL DEFAULT 0,
    vol_td         INTEGER      NOT NULL DEFAULT 0,
    vol_tp         INTEGER      NOT NULL DEFAULT 0,
    CONSTRAINT chk_ec_volumes CHECK (vol_cm >= 0 AND vol_td >= 0 AND vol_tp >= 0)
);

CREATE INDEX idx_ec_enseignant ON ec (id_enseignant);

-- Association COMPOSER (UE ↔ EC) + coefficient_ec
CREATE TABLE composer (
    id_ue           VARCHAR(20)   NOT NULL REFERENCES ue (id_ue),
    id_ec           VARCHAR(20)   NOT NULL REFERENCES ec (id_ec),
    coefficient_ec  NUMERIC(5, 2) NOT NULL,
    CONSTRAINT pk_composer PRIMARY KEY (id_ue, id_ec),
    CONSTRAINT uq_composer_ec UNIQUE (id_ec),  -- EC ↔ 1 UE
    CONSTRAINT chk_composer_coeff CHECK (coefficient_ec > 0)
);

CREATE INDEX idx_composer_ue ON composer (id_ue);

-- -----------------------------------------------------------------------------
-- Scolarité & notes
-- -----------------------------------------------------------------------------

CREATE TABLE etudiant (
    id_etudiant     VARCHAR(20)  PRIMARY KEY,
    ine             VARCHAR(11)  NOT NULL,
    nom             VARCHAR(50)  NOT NULL,
    prenom          VARCHAR(50)  NOT NULL,
    date_naissance  DATE         NOT NULL,
    email           VARCHAR(100) NOT NULL,
    CONSTRAINT uq_etudiant_ine UNIQUE (ine),
    CONSTRAINT uq_etudiant_email UNIQUE (email)
);

CREATE TABLE inscription (
    id_inscription       VARCHAR(20) PRIMARY KEY,
    id_etudiant          VARCHAR(20) NOT NULL REFERENCES etudiant (id_etudiant),
    id_annee_formation   VARCHAR(20) NOT NULL REFERENCES annee_formation (id_annee_formation),
    annee_universitaire  VARCHAR(9)  NOT NULL,
    date_inscription     DATE        NOT NULL,
    statut               VARCHAR(20),
    CONSTRAINT chk_inscription_annee_univ CHECK (annee_universitaire ~ '^[0-9]{4}-[0-9]{4}$')
);

CREATE INDEX idx_inscription_etudiant ON inscription (id_etudiant);
CREATE INDEX idx_inscription_annee ON inscription (id_annee_formation);
CREATE INDEX idx_inscription_annee_univ ON inscription (id_annee_formation, annee_universitaire);

-- Association NOTER (inscription × EC)
CREATE TABLE note_ec (
    id_inscription  VARCHAR(20)   NOT NULL REFERENCES inscription (id_inscription),
    id_ec           VARCHAR(20)   NOT NULL REFERENCES ec (id_ec),
    note_ec         NUMERIC(4, 2) NOT NULL,
    CONSTRAINT pk_note_ec PRIMARY KEY (id_inscription, id_ec),
    CONSTRAINT chk_note_ec_domaine CHECK (note_ec >= 0 AND note_ec <= 20)
);

CREATE INDEX idx_note_ec_ec ON note_ec (id_ec);

-- Archivage (procédure 4 PL/pgSQL — peuplement hors DDL courant)
CREATE TABLE resultats_archives (
    id_archive           VARCHAR(20) PRIMARY KEY,
    id_inscription       VARCHAR(20) NOT NULL REFERENCES inscription (id_inscription),
    annee_universitaire  VARCHAR(9)  NOT NULL,
    moyenne_annuelle     NUMERIC(4, 2),
    decision_jury        VARCHAR(20),
    date_archivage       DATE        NOT NULL DEFAULT CURRENT_DATE
);

CREATE INDEX idx_archives_inscription ON resultats_archives (id_inscription);

COMMIT;

-- =============================================================================
-- Suite
-- • Triggers : sql/02_triggers.sql (capacité, max 2 inscriptions, rattacher même année)
-- • Procédures : délib. semestre impair · délib. annuelle · fiche · archivage
-- =============================================================================
