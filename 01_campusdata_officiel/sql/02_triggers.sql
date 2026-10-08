-- =============================================================================
-- CampusData — Triggers (sujet Partie 1 + intégrité maquette)
-- Dépend de : 01_mpd_schema.sql
--
-- Sujet (inscription) :
-- 1. Capacité d'accueil : refuse si effectif (année formation × année univ.)
--    ≥ capacite_accueil
-- 2. Redoublement borné : refuse si > 2 inscriptions pour le même couple
--    (étudiant, année de diplôme / annee_formation)
--
-- Maquette (optionnel sujet, utile MLD) :
-- 3. Cohérence rattacher : le semestre de l'UE ∈ la même annee_formation que le BCC
-- =============================================================================

BEGIN;

-- -----------------------------------------------------------------------------
-- 1. Capacité d'accueil
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION trg_fn_inscription_capacite()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_capacite   INTEGER;
    v_effectif   INTEGER;
BEGIN
    SELECT capacite_accueil
      INTO v_capacite
      FROM annee_formation
     WHERE id_annee_formation = NEW.id_annee_formation;

    IF v_capacite IS NULL THEN
        RAISE EXCEPTION
            'ANNEE_FORMATION % introuvable', NEW.id_annee_formation;
    END IF;

    SELECT COUNT(*)
      INTO v_effectif
      FROM inscription
     WHERE id_annee_formation  = NEW.id_annee_formation
       AND annee_universitaire = NEW.annee_universitaire
       AND (TG_OP = 'INSERT' OR id_inscription <> NEW.id_inscription);

    IF v_effectif >= v_capacite THEN
        RAISE EXCEPTION
            'Capacité d''accueil atteinte pour % / % (max %)',
            NEW.id_annee_formation,
            NEW.annee_universitaire,
            v_capacite;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inscription_capacite ON inscription;

CREATE TRIGGER trg_inscription_capacite
    BEFORE INSERT OR UPDATE OF id_annee_formation, annee_universitaire
    ON inscription
    FOR EACH ROW
    EXECUTE PROCEDURE trg_fn_inscription_capacite();

-- -----------------------------------------------------------------------------
-- 2. Au plus 2 inscriptions pour (étudiant, année de diplôme)
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION trg_fn_inscription_max_deux()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_nb INTEGER;
BEGIN
    SELECT COUNT(*)
      INTO v_nb
      FROM inscription
     WHERE id_etudiant         = NEW.id_etudiant
       AND id_annee_formation  = NEW.id_annee_formation
       AND (TG_OP = 'INSERT' OR id_inscription <> NEW.id_inscription);

    IF v_nb >= 2 THEN
        RAISE EXCEPTION
            'Plus de 2 inscriptions interdites pour étudiant % sur année %',
            NEW.id_etudiant,
            NEW.id_annee_formation;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_inscription_max_deux ON inscription;

CREATE TRIGGER trg_inscription_max_deux
    BEFORE INSERT OR UPDATE OF id_etudiant, id_annee_formation
    ON inscription
    FOR EACH ROW
    EXECUTE PROCEDURE trg_fn_inscription_max_deux();

-- -----------------------------------------------------------------------------
-- 3. Cohérence RATTACHER : UE et BCC sur la même année de formation
-- -----------------------------------------------------------------------------

CREATE OR REPLACE FUNCTION trg_fn_rattacher_meme_annee()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_annee_bcc  VARCHAR(20);
    v_annee_ue   VARCHAR(20);
BEGIN
    SELECT id_annee_formation
      INTO v_annee_bcc
      FROM bcc
     WHERE id_bcc = NEW.id_bcc;

    SELECT s.id_annee_formation
      INTO v_annee_ue
      FROM ue u
      JOIN semestre s ON s.id_semestre = u.id_semestre
     WHERE u.id_ue = NEW.id_ue;

    IF v_annee_bcc IS NULL THEN
        RAISE EXCEPTION 'BCC % introuvable', NEW.id_bcc;
    END IF;

    IF v_annee_ue IS NULL THEN
        RAISE EXCEPTION 'UE % introuvable (ou sans semestre)', NEW.id_ue;
    END IF;

    IF v_annee_bcc <> v_annee_ue THEN
        RAISE EXCEPTION
            'RATTACHER incohérent : BCC % (année %) ≠ UE % (année %)',
            NEW.id_bcc, v_annee_bcc, NEW.id_ue, v_annee_ue;
    END IF;

    RETURN NEW;
END;
$$;

DROP TRIGGER IF EXISTS trg_rattacher_meme_annee ON rattacher;

CREATE TRIGGER trg_rattacher_meme_annee
    BEFORE INSERT OR UPDATE OF id_bcc, id_ue
    ON rattacher
    FOR EACH ROW
    EXECUTE PROCEDURE trg_fn_rattacher_meme_annee();

COMMIT;

-- =============================================================================
-- Notes
-- • Triggers 1–2 = exigence sujet ; trigger 3 = intégrité maquette (CHECK MLD).
-- • EXECUTE PROCEDURE : syntaxe standard des triggers PostgreSQL.
-- • Procédures de délibération / archivage : script suivant.
-- =============================================================================
