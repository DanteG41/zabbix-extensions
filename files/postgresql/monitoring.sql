--
-- PostgreSQL database dump
--

-- Dumped from database version 9.6.9
-- Dumped by pg_dump version 9.6.9

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: monitoring; Type: SCHEMA; Schema: -; Owner: postgres
--

CREATE SCHEMA IF NOT EXISTS monitoring;

ALTER SCHEMA monitoring OWNER TO postgres;

--
-- Name: monitored_relations_add_relid(); Type: FUNCTION; Schema: monitoring; Owner: postgres
--

CREATE OR REPLACE FUNCTION monitoring.monitored_relations_add_relid() RETURNS trigger
    LANGUAGE plpgsql
    AS $$
BEGIN
  NEW.relid := NEW.relname::regclass::oid;
  RETURN NEW;
END;
$$;

ALTER FUNCTION monitoring.monitored_relations_add_relid() OWNER TO postgres;

SET default_tablespace = '';

SET default_with_oids = false;

--
-- Name: monitored_relations; Type: TABLE; Schema: monitoring; Owner: postgres
--

CREATE TABLE IF NOT EXISTS monitoring.monitored_relations (
    relname name NOT NULL,
    relid oid NOT NULL,
    monitored boolean DEFAULT true NOT NULL,
    inheritance boolean DEFAULT false NOT NULL,
    CONSTRAINT monitored_relations_uniq UNIQUE(relid)
);

ALTER TABLE monitoring.monitored_relations OWNER TO postgres;

--
-- Name: monitored_relations tr_monitored_relations_add_relid; Type: TRIGGER; Schema: monitoring; Owner: postgres
--

CREATE TRIGGER tr_monitored_relations_add_relid BEFORE INSERT ON monitoring.monitored_relations FOR EACH ROW WHEN ((new.relid IS NULL)) EXECUTE PROCEDURE monitoring.monitored_relations_add_relid();

--
-- Name: SCHEMA monitoring; Type: ACL; Schema: -; Owner: postgres
--

CREATE ROLE monitoring_op;

GRANT USAGE ON SCHEMA monitoring TO monitoring_op;


--
-- Name: TABLE monitored_relations; Type: ACL; Schema: monitoring; Owner: postgres
--

GRANT SELECT,INSERT,DELETE,UPDATE ON TABLE monitoring.monitored_relations TO monitoring_op;


--
-- PostgreSQL database dump complete
--
