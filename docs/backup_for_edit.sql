--
-- PostgreSQL database dump
--

-- Dumped from database version 13.2
-- Dumped by pg_dump version 13.2

-- Started on 2022-01-08 19:35:58

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
-- TOC entry 214 (class 1255 OID 29427)
-- Name: plappinco(text); Type: FUNCTION; Schema: public; Owner: postgres
--

CREATE FUNCTION public.plappinco(couloirname text) RETURNS TABLE(nom_plateforme character varying, nom_application character varying)
    LANGUAGE plpgsql
    AS $$
begin
	return query
		SELECT pl.nom, ap.nom
		FROM application ap
		INNER JOIN couloir_plateforme_application_reservation coPlAppRe
		ON ap.id_application = coPlAppRe.id_application
		INNER JOIN plateforme pl 
		ON coPlAppRe.id_plateforme = pl.id_plateforme
		INNER JOIN couloir co
		ON coPlAppRe.id_couloir = co.id_couloir
		WHERE co.nom = couloirName;
end;
$$;


ALTER FUNCTION public.plappinco(couloirname text) OWNER TO postgres;

--
-- TOC entry 215 (class 1255 OID 29428)
-- Name: updateplandapp(text, text); Type: PROCEDURE; Schema: public; Owner: postgres
--

CREATE PROCEDURE public.updateplandapp(updatedate text, couloirname text)
    LANGUAGE plpgsql
    AS $$
declare
	basePath text := '/var/www/html/alimbdd/HDO_Gestion_Env_SDIT_';
	finalPath text := basePath || updateDate || ' - Gucci_' || couloirName || '.csv';
	tbImport record;
	tbPlAppInCo record;
	idCouloir integer := (select id_couloir from couloir where nom = couloirName);
	currentPlId integer;
	currentAppId integer;
	-- On récupère l'id maximum actuel de la table plateforme et de la table application et on y ajoute 1 afin d'avoir la valeur
	-- de la prochaine ligne qui sera insérée
	newPlId integer := (select max(id_plateforme) from plateforme) + 1;
	newAppId integer := (select max(id_application) from application) + 1;
begin 
	-- Suppression de toutes les lignes de la table import
	truncate table "import";
	-- Chargement du csv dans la table import
	execute format('copy import from ''%s'' delimiter '';'' csv header', finalPath);
	
	-- On boucle sur chaque ligne de la table import 	
	for tbImport in select plateforme, application
							from "import"
		loop
			-- Si le couple plateforme/application de la ligne courante n'existe pas dans le couloir cible de la BDD
			if (
				not exists (
								select * from plAppInCo(couloirName ) 
								where nom_plateforme = tbImport.plateforme
								and nom_application = tbImport.application
							  ) 
				-- Et si ce couple n'est pas null 
				and tbImport.plateforme is not null 
				and tbImport.application is not null 
			) then 
						-- Si la plateforme ET l'application n'existe pas dans la BDD
						if (
								not exists (select nom from plateforme where nom = tbImport.plateforme)
								and 
								not exists (select nom from application where nom = tbImport.application)
						  -- On créer la plateforme et l'application ainsi que l'association couloir/plateforme/application/reservation		
						) then
								insert into plateforme
								values (newPlId, tbImport.plateforme);
								insert into application
								values (newAppId, tbImport.application, null);
								insert into couloir_plateforme_application_reservation
								values (idCouloir, newPlId, newAppId, 0);
								-- On incrémente l'id de la plateforme et de l'application pour qu'il soit à jour pour le prochain tour de boucle
								newPlId := newPlId + 1;
								newAppId := newAppId + 1;
						-- Si la plateforme n'existe pas ET l'application existe
					 	elsif (
								not exists (select nom from plateforme where nom = tbImport.plateforme)
								and
								exists (select nom from application where nom = tbImport.application)
						  -- 
						) then 
								-- On récupère l'id courant de l'application existante
								currentAppId := (select id_application from application where nom = tbImport.application);
								-- On créer la plateforme ainsi que l'association couloir/plateforme/application/reservation
								insert into plateforme
								values (newPlId, tbImport.plateforme);
								insert into couloir_plateforme_application_reservation
								values (idCouloir, newPlId, currentAppId, 0);
								-- On incrémente l'id de la plateforme pour qu'il soit à jour pour le prochain tour de boucle
								newPlId := newPlId + 1;
						-- Si la plateforme existe ET l'application n'existe pas
						elsif (
								exists (select nom from plateforme where nom = tbImport.plateforme)
								and 
								not exists (select nom from application where nom = tbImport.application)
						) then 
								-- On récupère l'id courant de la plateforme existante
								currentPlId := (select id_plateforme from plateforme where nom = tbImport.plateforme);
								-- On créer l'application ainsi que l'association couloir/plateforme/application/reservation
								insert into application
								values (newAppId, tbImport.application, null);
								insert into couloir_plateforme_application_reservation 
								values (idCouloir, currentPlId, newAppId, 0);
								-- On incrémente l'id de l'application pour qu'il soit à jour pour le prochain tour de boucle
								newAppId := newAppId + 1;
						-- Si la plateforme ET l'application existent
						elsif (
								exists (select nom from plateforme where nom = tbImport.plateforme)
								and 
								exists (select nom from application where nom = tbImport.application)
						) then
								-- On récupère l'id courant de la plateforme et de l'application
								currentPlId := (select id_plateforme from plateforme where nom = tbImport.plateforme);
								currentAppId := (select id_application from application where nom = tbImport.application);
								-- On créer l'association couloir/plateforme/application/reservation
								insert into couloir_plateforme_application_reservation
								values (idCouloir, currentPlId, currentAppId, 0);
						end if;
			end if;
		end loop;
	-- On boucle sur chaque ligne de la table retournée par la fonction plAppInCo
	for tbPlAppInCo in select nom_plateforme, nom_application
								from plAppInCo(couloirName ) 
		loop
			-- Si cette ligne n'existe pas dans la table import cela veut dire que ce couple 
			-- plateforme/application a été supprimée dans le fichier Excel source
			if not exists (
								select * from "import" 
								where plateforme = tbPlAppInCo.nom_plateforme
								and application = tbPlAppInCo.nom_application
			  -- On supprime donc l'association couloir/plateforme/application/reservation, correspondant au couple qui n'existe plus, de la BDD,
			  -- sauf si cette association a un id_reservation supérieur à 0, ce qui voudrait dire qu'il y a encore une réservation attribuée
			  -- à cette ligne. Dans ce cas on ne supprime donc pas cette ligne automatiquement, il faudra faire la manipulation en BDD à la main une fois que 
			  -- l'on aura vérifié que la réservation existante n'a plus lieu d'être.
			  -- On ne supprime pas la plateforme et l'application concernée car on ne sait pas si ce couple n'existe pas dans d'autre couloir.
			  -- Si jamais cette application et/ou cette plateforme ne sont plus du tout utilisées, on fera une suppression à la main, ce qui 
			  -- permettra d'éviter de nombreux problèmes en cas de suppression accidentelle d'un couple plateforme/application dans 
			  -- le fichier Excel.
			) then
					currentPlId := (select id_plateforme from plateforme where nom = tbPlAppInCo.nom_plateforme);
					currentAppId := (select id_application from application where nom = tbPlAppInCo.nom_application);
					if not exists (
										select *
										from couloir_plateforme_application_reservation
										where id_couloir = idCouloir
										and id_plateforme = currentPlId
										and id_application = currentAppId
										and id_reservation > 0
					) then
							delete from couloir_plateforme_application_reservation
							where id_couloir = idCouloir
							and id_plateforme = currentPlId
							and id_application = currentAppId
							and id_reservation = 0;
					end if;
			end if;
		end loop;
end;
$$;


ALTER PROCEDURE public.updateplandapp(updatedate text, couloirname text) OWNER TO postgres;

SET default_tablespace = '';

SET default_table_access_method = heap;

--
-- TOC entry 200 (class 1259 OID 29430)
-- Name: application; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.application (
    id_application integer NOT NULL,
    nom character varying,
    version character varying
);


ALTER TABLE public.application OWNER TO postgres;

--
-- TOC entry 201 (class 1259 OID 29436)
-- Name: application_dependance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.application_dependance (
    id_application integer NOT NULL,
    id_dependance integer NOT NULL
);


ALTER TABLE public.application_dependance OWNER TO postgres;

--
-- TOC entry 202 (class 1259 OID 29439)
-- Name: application_id_application_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.application_id_application_seq
    AS integer
    START WITH 312
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.application_id_application_seq OWNER TO postgres;

--
-- TOC entry 3067 (class 0 OID 0)
-- Dependencies: 202
-- Name: application_id_application_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.application_id_application_seq OWNED BY public.application.id_application;


--
-- TOC entry 203 (class 1259 OID 29441)
-- Name: couloir; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.couloir (
    id_couloir integer NOT NULL,
    nom character varying
);


ALTER TABLE public.couloir OWNER TO postgres;

--
-- TOC entry 204 (class 1259 OID 29447)
-- Name: couloir_id_couloir_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.couloir_id_couloir_seq
    AS integer
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.couloir_id_couloir_seq OWNER TO postgres;

--
-- TOC entry 3068 (class 0 OID 0)
-- Dependencies: 204
-- Name: couloir_id_couloir_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.couloir_id_couloir_seq OWNED BY public.couloir.id_couloir;


--
-- TOC entry 205 (class 1259 OID 29449)
-- Name: couloir_plateforme_application_reservation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.couloir_plateforme_application_reservation (
    id_couloir integer NOT NULL,
    id_plateforme integer NOT NULL,
    id_application integer NOT NULL,
    id_reservation integer NOT NULL,
    leader boolean,
    partageable boolean
);


ALTER TABLE public.couloir_plateforme_application_reservation OWNER TO postgres;

--
-- TOC entry 206 (class 1259 OID 29452)
-- Name: dependance; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.dependance (
    id_dependance integer NOT NULL,
    nom character varying,
    version character varying
);


ALTER TABLE public.dependance OWNER TO postgres;

--
-- TOC entry 207 (class 1259 OID 29458)
-- Name: habilite; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.habilite (
    id_habilite integer NOT NULL,
    nom character varying,
    fonction character varying,
    telephone character varying,
    email character varying,
    login character varying,
    password character varying
);


ALTER TABLE public.habilite OWNER TO postgres;

--
-- TOC entry 208 (class 1259 OID 29464)
-- Name: habilite_id_habilite_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.habilite_id_habilite_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.habilite_id_habilite_seq OWNER TO postgres;

--
-- TOC entry 3069 (class 0 OID 0)
-- Dependencies: 208
-- Name: habilite_id_habilite_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.habilite_id_habilite_seq OWNED BY public.habilite.id_habilite;


--
-- TOC entry 209 (class 1259 OID 29466)
-- Name: import; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.import (
    plateforme character varying,
    application character varying
);


ALTER TABLE public.import OWNER TO postgres;

--
-- TOC entry 210 (class 1259 OID 29472)
-- Name: plateforme; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.plateforme (
    id_plateforme integer NOT NULL,
    nom character varying
);


ALTER TABLE public.plateforme OWNER TO postgres;

--
-- TOC entry 211 (class 1259 OID 29478)
-- Name: plateforme_id_plateforme_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.plateforme_id_plateforme_seq
    AS integer
    START WITH 141
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;


ALTER TABLE public.plateforme_id_plateforme_seq OWNER TO postgres;

--
-- TOC entry 3070 (class 0 OID 0)
-- Dependencies: 211
-- Name: plateforme_id_plateforme_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.plateforme_id_plateforme_seq OWNED BY public.plateforme.id_plateforme;


--
-- TOC entry 212 (class 1259 OID 29480)
-- Name: reservation; Type: TABLE; Schema: public; Owner: postgres
--

CREATE TABLE public.reservation (
    id_reservation integer NOT NULL,
    intitule character varying,
    id_habilite integer,
    date_debut date,
    date_fin date,
    created_at timestamp with time zone DEFAULT CURRENT_TIMESTAMP,
    name character varying,
    fonction character varying,
    email character varying,
    telephone character varying,
    comments character varying(255)
);


ALTER TABLE public.reservation OWNER TO postgres;

--
-- TOC entry 213 (class 1259 OID 29487)
-- Name: reservation_id_reservation_seq; Type: SEQUENCE; Schema: public; Owner: postgres
--

CREATE SEQUENCE public.reservation_id_reservation_seq
	AS integer
	START WITH 1
	INCREMENT BY 1
	NO MINVALUE
	NO MAXVALUE
	CACHE 1;


ALTER TABLE public.reservation_id_reservation_seq OWNER TO postgres;

--
-- TOC entry 3071 (class 0 OID 0)
-- Dependencies: 213
-- Name: reservation_id_reservation_seq; Type: SEQUENCE OWNED BY; Schema: public; Owner: postgres
--

ALTER SEQUENCE public.reservation_id_reservation_seq OWNED BY public.reservation.id_reservation;


--
-- TOC entry 2899 (class 2604 OID 29489)
-- Name: application id_application; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application ALTER COLUMN id_application SET DEFAULT nextval('public.application_id_application_seq'::regclass);


--
-- TOC entry 2900 (class 2604 OID 29490)
-- Name: couloir id_couloir; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.couloir ALTER COLUMN id_couloir SET DEFAULT nextval('public.couloir_id_couloir_seq'::regclass);


--
-- TOC entry 2901 (class 2604 OID 29491)
-- Name: habilite id_habilite; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilite ALTER COLUMN id_habilite SET DEFAULT nextval('public.habilite_id_habilite_seq'::regclass);


--
-- TOC entry 2902 (class 2604 OID 29492)
-- Name: plateforme id_plateforme; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plateforme ALTER COLUMN id_plateforme SET DEFAULT nextval('public.plateforme_id_plateforme_seq'::regclass);


--
-- TOC entry 2904 (class 2604 OID 29493)
-- Name: reservation id_reservation; Type: DEFAULT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation ALTER COLUMN id_reservation SET DEFAULT nextval('public.reservation_id_reservation_seq'::regclass);


--
-- TOC entry 2906 (class 2606 OID 29495)
-- Name: application application_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_pkey PRIMARY KEY (id_application);


--
-- TOC entry 2910 (class 2606 OID 29497)
-- Name: couloir couloir_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.couloir
    ADD CONSTRAINT couloir_pkey PRIMARY KEY (id_couloir);


--
-- TOC entry 2912 (class 2606 OID 29499)
-- Name: couloir_plateforme_application_reservation couloir_plateforme_application_reservation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT couloir_plateforme_application_reservation_pkey PRIMARY KEY (id_couloir, id_plateforme, id_application, id_reservation);


--
-- TOC entry 2914 (class 2606 OID 29501)
-- Name: dependance dependance_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.dependance
    ADD CONSTRAINT dependance_pkey PRIMARY KEY (id_dependance);


--
-- TOC entry 2916 (class 2606 OID 29503)
-- Name: habilite habilite_email_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_email_key UNIQUE (email);


--
-- TOC entry 2918 (class 2606 OID 29505)
-- Name: habilite habilite_login_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_login_key UNIQUE (login);


--
-- TOC entry 2920 (class 2606 OID 29507)
-- Name: habilite habilite_password_key; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_password_key UNIQUE (password);


--
-- TOC entry 2922 (class 2606 OID 29509)
-- Name: habilite habilite_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_pkey PRIMARY KEY (id_habilite);


--
-- TOC entry 2908 (class 2606 OID 29511)
-- Name: application_dependance pk_application_dependance; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_dependance
    ADD CONSTRAINT pk_application_dependance PRIMARY KEY (id_application, id_dependance);


--
-- TOC entry 2924 (class 2606 OID 29513)
-- Name: plateforme plateforme_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.plateforme
    ADD CONSTRAINT plateforme_pkey PRIMARY KEY (id_plateforme);


--
-- TOC entry 2926 (class 2606 OID 29515)
-- Name: reservation reservation_pkey; Type: CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (id_reservation);


--
-- TOC entry 2927 (class 2606 OID 29516)
-- Name: application_dependance application_dependance_id_application_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_dependance
    ADD CONSTRAINT application_dependance_id_application_fkey FOREIGN KEY (id_application) REFERENCES public.application(id_application);


--
-- TOC entry 2928 (class 2606 OID 29521)
-- Name: application_dependance application_dependance_id_dependance_fkey; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.application_dependance
    ADD CONSTRAINT application_dependance_id_dependance_fkey FOREIGN KEY (id_dependance) REFERENCES public.dependance(id_dependance);


--
-- TOC entry 2929 (class 2606 OID 29526)
-- Name: couloir_plateforme_application_reservation fk_application; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT fk_application FOREIGN KEY (id_application) REFERENCES public.application(id_application) NOT VALID;


--
-- TOC entry 2930 (class 2606 OID 29531)
-- Name: couloir_plateforme_application_reservation fk_couloir; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT fk_couloir FOREIGN KEY (id_couloir) REFERENCES public.couloir(id_couloir) NOT VALID;


--
-- TOC entry 2931 (class 2606 OID 29536)
-- Name: couloir_plateforme_application_reservation fk_plateforme; Type: FK CONSTRAINT; Schema: public; Owner: postgres
--

ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT fk_plateforme FOREIGN KEY (id_plateforme) REFERENCES public.plateforme(id_plateforme) NOT VALID;


-- Completed on 2022-01-08 19:35:59

--
-- PostgreSQL database dump complete
--

