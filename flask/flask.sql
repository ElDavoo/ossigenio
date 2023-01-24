--
-- PostgreSQL database dump
--

-- Dumped from database version 13.9 (Debian 13.9-0+deb11u1)
-- Dumped by pg_dump version 13.9 (Debian 13.9-0+deb11u1)

SET statement_timeout = 0;
SET lock_timeout = 0;
SET idle_in_transaction_session_timeout = 0;
SET client_encoding = 'UTF8';
SET standard_conforming_strings = on;
SELECT pg_catalog.set_config('search_path', '', false);
SET check_function_bodies = false;
SET xmloption = content;
SET client_min_messages = warning;
SET row_security = off;

--
-- Name: postgis; Type: EXTENSION; Schema: -; Owner: -
--

CREATE EXTENSION IF NOT EXISTS postgis WITH SCHEMA public;


--
-- Name: EXTENSION postgis; Type: COMMENT; Schema: -; Owner:
--

COMMENT ON EXTENSION postgis IS 'PostGIS geometry and geography spatial types and functions';


SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- Name: co2_history; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.co2_history (
    place_id integer NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    co2 integer NOT NULL
);


ALTER TABLE public.co2_history OWNER TO iot;

--
-- Name: device; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.device (
    id bigint NOT NULL,
    model smallint NOT NULL,
    revision smallint NOT NULL,
    owner integer
);


ALTER TABLE public.device OWNER TO iot;

--
-- Name: device_models; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.device_models (
    model_id smallint NOT NULL,
    model_revision smallint NOT NULL,
    model_name character varying NOT NULL,
    model_description character varying
);


ALTER TABLE public.device_models OWNER TO iot;

--
-- Name: device_models_model_id_seq; Type: SEQUENCE; Schema: public; Owner: iot
--

CREATE SEQUENCE public.device_models_model_id_seq
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.device_models_model_id_seq OWNER TO iot;

--
-- Name: device_models_model_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: iot
--

ALTER SEQUENCE public.device_models_model_id_seq OWNED BY public.device_models.model_id;


--
-- Name: device_models_model_revision_seq; Type: SEQUENCE; Schema: public; Owner: iot
--

CREATE SEQUENCE public.device_models_model_revision_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.device_models_model_revision_seq OWNER TO iot;

--
-- Name: device_models_model_revision_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: iot
--

ALTER SEQUENCE public.device_models_model_revision_seq OWNED BY public.device_models.model_revision;


--
-- Name: place; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.place (
    id smallint NOT NULL,
    location public.geometry NOT NULL,
    name character varying NOT NULL,
    description character varying,
    floor smallint
);


ALTER TABLE public.place OWNER TO iot;

--
-- Name: place_text; Type: VIEW; Schema: public; Owner: iot
--

CREATE VIEW public.place_text AS
 SELECT place.id,
    public.st_astext(place.location) AS st_astext,
    place.name,
    place.description
   FROM public.place;


ALTER TABLE public.place_text OWNER TO iot;

--
-- Name: places_id_seq; Type: SEQUENCE; Schema: public; Owner: iot
--

CREATE SEQUENCE public.places_id_seq
    AS smallint
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.places_id_seq OWNER TO iot;

--
-- Name: places_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: iot
--

ALTER SEQUENCE public.places_id_seq OWNED BY public.place.id;


--
-- Name: prophet_models; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.prophet_models (
    place_id integer NOT NULL,
    model jsonb NOT NULL
);


ALTER TABLE public.prophet_models OWNER TO iot;

--
-- Name: sensor_data; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.sensor_data (
    sensor_id bigint NOT NULL,
    "timestamp" timestamp without time zone NOT NULL,
    co2 integer,
    humidity integer,
    rawdata integer,
    temperature integer,
    feedback character varying,
    place integer
);


ALTER TABLE public.sensor_data OWNER TO iot;

--
-- Name: telegram_users; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.telegram_users (
    telegram_id integer NOT NULL,
    id integer NOT NULL,
    place integer NOT NULL,
    soglia integer DEFAULT 800 NOT NULL,
    last_notification timestamp without time zone
);


ALTER TABLE public.telegram_users OWNER TO iot;

--
-- Name: utente; Type: TABLE; Schema: public; Owner: iot
--

CREATE TABLE public.utente (
    id integer NOT NULL,
    email text NOT NULL,
    password text NOT NULL,
    name text NOT NULL,
    admin boolean DEFAULT false NOT NULL
);


ALTER TABLE public.utente OWNER TO iot;

--
-- Name: user_id_seq; Type: SEQUENCE; Schema: public; Owner: iot
--

CREATE SEQUENCE public.user_id_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.user_id_seq OWNER TO iot;

--
-- Name: user_id_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: iot
--

ALTER SEQUENCE public.user_id_seq OWNED BY public.utente.id;


--
-- Name: place id; Type: DEFAULT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.place ALTER COLUMN id SET DEFAULT nextval('public.places_id_seq'::regclass);


--
-- Name: utente id; Type: DEFAULT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.utente ALTER COLUMN id SET DEFAULT nextval('public.user_id_seq'::regclass);


--
-- Name: co2_history co2_history_pk; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.co2_history
    ADD CONSTRAINT co2_history_pk PRIMARY KEY (place_id, "timestamp");


--
-- Name: device_models device_models_pk; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.device_models
    ADD CONSTRAINT device_models_pk PRIMARY KEY (model_id, model_revision);


--
-- Name: device device_pkey; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT device_pkey PRIMARY KEY (id);


--
-- Name: prophet_models place_id_pk; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.prophet_models
    ADD CONSTRAINT place_id_pk PRIMARY KEY (place_id);


--
-- Name: place place_pk; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.place
    ADD CONSTRAINT place_pk UNIQUE (name);


--
-- Name: place places_pk; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.place
    ADD CONSTRAINT places_pk PRIMARY KEY (id);


--
-- Name: sensor_data sensor_data_pkey; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.sensor_data
    ADD CONSTRAINT sensor_data_pkey PRIMARY KEY (sensor_id, "timestamp");


--
-- Name: telegram_users telegram_users_pk; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.telegram_users
    ADD CONSTRAINT telegram_users_pk PRIMARY KEY (id, telegram_id, place);


--
-- Name: utente user_pkey; Type: CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.utente
    ADD CONSTRAINT user_pkey PRIMARY KEY (id);


--
-- Name: co2_history co2_history_place_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.co2_history
    ADD CONSTRAINT co2_history_place_id_fk FOREIGN KEY (place_id) REFERENCES public.place(id) ON UPDATE CASCADE ON DELETE CASCADE;


--
-- Name: device foreign; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT "foreign" FOREIGN KEY (revision, model) REFERENCES public.device_models(model_revision, model_id) ON UPDATE CASCADE;


--
-- Name: prophet_models place_id_k; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.prophet_models
    ADD CONSTRAINT place_id_k FOREIGN KEY (place_id) REFERENCES public.place(id);


--
-- Name: sensor_data sensor_data_place_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.sensor_data
    ADD CONSTRAINT sensor_data_place_id_fk FOREIGN KEY (place) REFERENCES public.place(id);


--
-- Name: sensor_data sensor_data_sensor_id_fkey; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.sensor_data
    ADD CONSTRAINT sensor_data_sensor_id_fkey FOREIGN KEY (sensor_id) REFERENCES public.device(id);


--
-- Name: telegram_users telegram_users_place_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.telegram_users
    ADD CONSTRAINT telegram_users_place_id_fk FOREIGN KEY (place) REFERENCES public.place(id);


--
-- Name: telegram_users telegram_users_utente_id_fk; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.telegram_users
    ADD CONSTRAINT telegram_users_utente_id_fk FOREIGN KEY (id) REFERENCES public.utente(id);


--
-- Name: device utente_fk; Type: FK CONSTRAINT; Schema: public; Owner: iot
--

ALTER TABLE ONLY public.device
    ADD CONSTRAINT utente_fk FOREIGN KEY (owner) REFERENCES public.utente(id) ON UPDATE CASCADE ON DELETE SET NULL;


--
-- Name: SCHEMA public; Type: ACL; Schema: -; Owner: postgres
--

GRANT ALL ON SCHEMA public TO iot;


--
-- PostgreSQL database dump complete
--