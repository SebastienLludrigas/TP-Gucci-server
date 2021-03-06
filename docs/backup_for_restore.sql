PGDMP         2                y            Gucci    13.3    13.4 <    ?           0    0    ENCODING    ENCODING        SET client_encoding = 'UTF8';
                      false            ?           0    0 
   STDSTRINGS 
   STDSTRINGS     (   SET standard_conforming_strings = 'on';
                      false            ?           0    0 
   SEARCHPATH 
   SEARCHPATH     8   SELECT pg_catalog.set_config('search_path', '', false);
                      false            ?           1262    16757    Gucci    DATABASE     [   CREATE DATABASE "Gucci" WITH TEMPLATE = template0 ENCODING = 'UTF8' LOCALE = 'fr_FR.utf8';
    DROP DATABASE "Gucci";
                postgres    false            ?            1255    16758    plappinco(text)    FUNCTION       CREATE FUNCTION public.plappinco(couloirname text) RETURNS TABLE(nom_plateforme character varying, nom_application character varying)
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
 2   DROP FUNCTION public.plappinco(couloirname text);
       public          postgres    false            ?            1255    16759    updateplandapp(text, text) 	   PROCEDURE     s  CREATE PROCEDURE public.updateplandapp(updatedate text, couloirname text)
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
 I   DROP PROCEDURE public.updateplandapp(updatedate text, couloirname text);
       public          postgres    false            ?            1259    16761    application    TABLE     ?   CREATE TABLE public.application (
    id_application integer NOT NULL,
    nom character varying,
    version character varying
);
    DROP TABLE public.application;
       public         heap    postgres    false            ?            1259    16767    application_dependance    TABLE     x   CREATE TABLE public.application_dependance (
    id_application integer NOT NULL,
    id_dependance integer NOT NULL
);
 *   DROP TABLE public.application_dependance;
       public         heap    postgres    false            ?            1259    16894    application_id_application_seq    SEQUENCE     ?   CREATE SEQUENCE public.application_id_application_seq
    AS integer
    START WITH 312
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.application_id_application_seq;
       public          postgres    false    200            ?           0    0    application_id_application_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.application_id_application_seq OWNED BY public.application.id_application;
          public          postgres    false    212            ?            1259    16770    couloir    TABLE     \   CREATE TABLE public.couloir (
    id_couloir integer NOT NULL,
    nom character varying
);
    DROP TABLE public.couloir;
       public         heap    postgres    false            ?            1259    16891    couloir_id_couloir_seq    SEQUENCE     ?   CREATE SEQUENCE public.couloir_id_couloir_seq
    AS integer
    START WITH 10
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 -   DROP SEQUENCE public.couloir_id_couloir_seq;
       public          postgres    false    202            ?           0    0    couloir_id_couloir_seq    SEQUENCE OWNED BY     Q   ALTER SEQUENCE public.couloir_id_couloir_seq OWNED BY public.couloir.id_couloir;
          public          postgres    false    211            ?            1259    16776 *   couloir_plateforme_application_reservation    TABLE     ?   CREATE TABLE public.couloir_plateforme_application_reservation (
    id_couloir integer NOT NULL,
    id_plateforme integer NOT NULL,
    id_application integer NOT NULL,
    id_reservation integer NOT NULL,
    leader boolean,
    partageable boolean
);
 >   DROP TABLE public.couloir_plateforme_application_reservation;
       public         heap    postgres    false            ?            1259    16779 
   dependance    TABLE     ?   CREATE TABLE public.dependance (
    id_dependance integer NOT NULL,
    nom character varying,
    version character varying
);
    DROP TABLE public.dependance;
       public         heap    postgres    false            ?            1259    16785    habilite    TABLE     ?   CREATE TABLE public.habilite (
    id_habilite integer NOT NULL,
    nom character varying,
    fonction character varying,
    telephone character varying,
    email character varying,
    login character varying,
    password character varying
);
    DROP TABLE public.habilite;
       public         heap    postgres    false            ?            1259    16791    habilite_id_habilite_seq    SEQUENCE     ?   CREATE SEQUENCE public.habilite_id_habilite_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 /   DROP SEQUENCE public.habilite_id_habilite_seq;
       public          postgres    false    205            ?           0    0    habilite_id_habilite_seq    SEQUENCE OWNED BY     U   ALTER SEQUENCE public.habilite_id_habilite_seq OWNED BY public.habilite.id_habilite;
          public          postgres    false    206            ?            1259    16793    import    TABLE     d   CREATE TABLE public.import (
    plateforme character varying,
    application character varying
);
    DROP TABLE public.import;
       public         heap    postgres    false            ?            1259    16799 
   plateforme    TABLE     b   CREATE TABLE public.plateforme (
    id_plateforme integer NOT NULL,
    nom character varying
);
    DROP TABLE public.plateforme;
       public         heap    postgres    false            ?            1259    16897    plateforme_id_plateforme_seq    SEQUENCE     ?   CREATE SEQUENCE public.plateforme_id_plateforme_seq
    AS integer
    START WITH 141
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 3   DROP SEQUENCE public.plateforme_id_plateforme_seq;
       public          postgres    false    208            ?           0    0    plateforme_id_plateforme_seq    SEQUENCE OWNED BY     ]   ALTER SEQUENCE public.plateforme_id_plateforme_seq OWNED BY public.plateforme.id_plateforme;
          public          postgres    false    213            ?            1259    16805    reservation    TABLE     ?  CREATE TABLE public.reservation (
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
    DROP TABLE public.reservation;
       public         heap    postgres    false            ?            1259    16812    reservation_id_reservation_seq    SEQUENCE     ?   CREATE SEQUENCE public.reservation_id_reservation_seq
    AS integer
    START WITH 1
    INCREMENT BY 1
    NO MINVALUE
    NO MAXVALUE
    CACHE 1;
 5   DROP SEQUENCE public.reservation_id_reservation_seq;
       public          postgres    false    209            ?           0    0    reservation_id_reservation_seq    SEQUENCE OWNED BY     a   ALTER SEQUENCE public.reservation_id_reservation_seq OWNED BY public.reservation.id_reservation;
          public          postgres    false    210            /           2604    16896    application id_application    DEFAULT     ?   ALTER TABLE ONLY public.application ALTER COLUMN id_application SET DEFAULT nextval('public.application_id_application_seq'::regclass);
 I   ALTER TABLE public.application ALTER COLUMN id_application DROP DEFAULT;
       public          postgres    false    212    200            0           2604    16893    couloir id_couloir    DEFAULT     x   ALTER TABLE ONLY public.couloir ALTER COLUMN id_couloir SET DEFAULT nextval('public.couloir_id_couloir_seq'::regclass);
 A   ALTER TABLE public.couloir ALTER COLUMN id_couloir DROP DEFAULT;
       public          postgres    false    211    202            1           2604    16814    habilite id_habilite    DEFAULT     |   ALTER TABLE ONLY public.habilite ALTER COLUMN id_habilite SET DEFAULT nextval('public.habilite_id_habilite_seq'::regclass);
 C   ALTER TABLE public.habilite ALTER COLUMN id_habilite DROP DEFAULT;
       public          postgres    false    206    205            2           2604    16899    plateforme id_plateforme    DEFAULT     ?   ALTER TABLE ONLY public.plateforme ALTER COLUMN id_plateforme SET DEFAULT nextval('public.plateforme_id_plateforme_seq'::regclass);
 G   ALTER TABLE public.plateforme ALTER COLUMN id_plateforme DROP DEFAULT;
       public          postgres    false    213    208            4           2604    16815    reservation id_reservation    DEFAULT     ?   ALTER TABLE ONLY public.reservation ALTER COLUMN id_reservation SET DEFAULT nextval('public.reservation_id_reservation_seq'::regclass);
 I   ALTER TABLE public.reservation ALTER COLUMN id_reservation DROP DEFAULT;
       public          postgres    false    210    209            ?          0    16761    application 
   TABLE DATA           C   COPY public.application (id_application, nom, version) FROM stdin;
    public          postgres    false    200   $g       ?          0    16767    application_dependance 
   TABLE DATA           O   COPY public.application_dependance (id_application, id_dependance) FROM stdin;
    public          postgres    false    201   ?m       ?          0    16770    couloir 
   TABLE DATA           2   COPY public.couloir (id_couloir, nom) FROM stdin;
    public          postgres    false    202   ?m       ?          0    16776 *   couloir_plateforme_application_reservation 
   TABLE DATA           ?   COPY public.couloir_plateforme_application_reservation (id_couloir, id_plateforme, id_application, id_reservation, leader, partageable) FROM stdin;
    public          postgres    false    203   ?m       ?          0    16779 
   dependance 
   TABLE DATA           A   COPY public.dependance (id_dependance, nom, version) FROM stdin;
    public          postgres    false    204   ?y       ?          0    16785    habilite 
   TABLE DATA           a   COPY public.habilite (id_habilite, nom, fonction, telephone, email, login, password) FROM stdin;
    public          postgres    false    205   ?y       ?          0    16793    import 
   TABLE DATA           9   COPY public.import (plateforme, application) FROM stdin;
    public          postgres    false    207   x?       ?          0    16799 
   plateforme 
   TABLE DATA           8   COPY public.plateforme (id_plateforme, nom) FROM stdin;
    public          postgres    false    208   ??       ?          0    16805    reservation 
   TABLE DATA           ?   COPY public.reservation (id_reservation, intitule, id_habilite, date_debut, date_fin, created_at, name, fonction, email, telephone, comments) FROM stdin;
    public          postgres    false    209   ?       ?           0    0    application_id_application_seq    SEQUENCE SET     N   SELECT pg_catalog.setval('public.application_id_application_seq', 312, true);
          public          postgres    false    212            ?           0    0    couloir_id_couloir_seq    SEQUENCE SET     E   SELECT pg_catalog.setval('public.couloir_id_couloir_seq', 10, true);
          public          postgres    false    211            ?           0    0    habilite_id_habilite_seq    SEQUENCE SET     G   SELECT pg_catalog.setval('public.habilite_id_habilite_seq', 42, true);
          public          postgres    false    206            ?           0    0    plateforme_id_plateforme_seq    SEQUENCE SET     L   SELECT pg_catalog.setval('public.plateforme_id_plateforme_seq', 141, true);
          public          postgres    false    213            ?           0    0    reservation_id_reservation_seq    SEQUENCE SET     M   SELECT pg_catalog.setval('public.reservation_id_reservation_seq', 1, false);
          public          postgres    false    210            6           2606    16817    application application_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.application
    ADD CONSTRAINT application_pkey PRIMARY KEY (id_application);
 F   ALTER TABLE ONLY public.application DROP CONSTRAINT application_pkey;
       public            postgres    false    200            :           2606    16819    couloir couloir_pkey 
   CONSTRAINT     Z   ALTER TABLE ONLY public.couloir
    ADD CONSTRAINT couloir_pkey PRIMARY KEY (id_couloir);
 >   ALTER TABLE ONLY public.couloir DROP CONSTRAINT couloir_pkey;
       public            postgres    false    202            <           2606    16821 Z   couloir_plateforme_application_reservation couloir_plateforme_application_reservation_pkey 
   CONSTRAINT     ?   ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT couloir_plateforme_application_reservation_pkey PRIMARY KEY (id_couloir, id_plateforme, id_application, id_reservation);
 ?   ALTER TABLE ONLY public.couloir_plateforme_application_reservation DROP CONSTRAINT couloir_plateforme_application_reservation_pkey;
       public            postgres    false    203    203    203    203            >           2606    16823    dependance dependance_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.dependance
    ADD CONSTRAINT dependance_pkey PRIMARY KEY (id_dependance);
 D   ALTER TABLE ONLY public.dependance DROP CONSTRAINT dependance_pkey;
       public            postgres    false    204            @           2606    16825    habilite habilite_email_key 
   CONSTRAINT     W   ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_email_key UNIQUE (email);
 E   ALTER TABLE ONLY public.habilite DROP CONSTRAINT habilite_email_key;
       public            postgres    false    205            B           2606    16827    habilite habilite_login_key 
   CONSTRAINT     W   ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_login_key UNIQUE (login);
 E   ALTER TABLE ONLY public.habilite DROP CONSTRAINT habilite_login_key;
       public            postgres    false    205            D           2606    16829    habilite habilite_password_key 
   CONSTRAINT     ]   ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_password_key UNIQUE (password);
 H   ALTER TABLE ONLY public.habilite DROP CONSTRAINT habilite_password_key;
       public            postgres    false    205            F           2606    16831    habilite habilite_pkey 
   CONSTRAINT     ]   ALTER TABLE ONLY public.habilite
    ADD CONSTRAINT habilite_pkey PRIMARY KEY (id_habilite);
 @   ALTER TABLE ONLY public.habilite DROP CONSTRAINT habilite_pkey;
       public            postgres    false    205            8           2606    16833 0   application_dependance pk_application_dependance 
   CONSTRAINT     ?   ALTER TABLE ONLY public.application_dependance
    ADD CONSTRAINT pk_application_dependance PRIMARY KEY (id_application, id_dependance);
 Z   ALTER TABLE ONLY public.application_dependance DROP CONSTRAINT pk_application_dependance;
       public            postgres    false    201    201            H           2606    16835    plateforme plateforme_pkey 
   CONSTRAINT     c   ALTER TABLE ONLY public.plateforme
    ADD CONSTRAINT plateforme_pkey PRIMARY KEY (id_plateforme);
 D   ALTER TABLE ONLY public.plateforme DROP CONSTRAINT plateforme_pkey;
       public            postgres    false    208            J           2606    16837    reservation reservation_pkey 
   CONSTRAINT     f   ALTER TABLE ONLY public.reservation
    ADD CONSTRAINT reservation_pkey PRIMARY KEY (id_reservation);
 F   ALTER TABLE ONLY public.reservation DROP CONSTRAINT reservation_pkey;
       public            postgres    false    209            K           2606    16838 A   application_dependance application_dependance_id_application_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.application_dependance
    ADD CONSTRAINT application_dependance_id_application_fkey FOREIGN KEY (id_application) REFERENCES public.application(id_application);
 k   ALTER TABLE ONLY public.application_dependance DROP CONSTRAINT application_dependance_id_application_fkey;
       public          postgres    false    201    200    3638            L           2606    16843 @   application_dependance application_dependance_id_dependance_fkey    FK CONSTRAINT     ?   ALTER TABLE ONLY public.application_dependance
    ADD CONSTRAINT application_dependance_id_dependance_fkey FOREIGN KEY (id_dependance) REFERENCES public.dependance(id_dependance);
 j   ALTER TABLE ONLY public.application_dependance DROP CONSTRAINT application_dependance_id_dependance_fkey;
       public          postgres    false    201    3646    204            M           2606    16848 9   couloir_plateforme_application_reservation fk_application    FK CONSTRAINT     ?   ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT fk_application FOREIGN KEY (id_application) REFERENCES public.application(id_application) NOT VALID;
 c   ALTER TABLE ONLY public.couloir_plateforme_application_reservation DROP CONSTRAINT fk_application;
       public          postgres    false    203    200    3638            N           2606    16853 5   couloir_plateforme_application_reservation fk_couloir    FK CONSTRAINT     ?   ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT fk_couloir FOREIGN KEY (id_couloir) REFERENCES public.couloir(id_couloir) NOT VALID;
 _   ALTER TABLE ONLY public.couloir_plateforme_application_reservation DROP CONSTRAINT fk_couloir;
       public          postgres    false    202    3642    203            O           2606    16858 8   couloir_plateforme_application_reservation fk_plateforme    FK CONSTRAINT     ?   ALTER TABLE ONLY public.couloir_plateforme_application_reservation
    ADD CONSTRAINT fk_plateforme FOREIGN KEY (id_plateforme) REFERENCES public.plateforme(id_plateforme) NOT VALID;
 b   ALTER TABLE ONLY public.couloir_plateforme_application_reservation DROP CONSTRAINT fk_plateforme;
       public          postgres    false    208    3656    203            ?   S  x?m?Ɏ?6@Ϝ??[&?D$???x???1?AN????g???w??R??j 7?Sq?U%Yhь?b??p??Ҏ????N?i?d?"?K??)&?X???s.?o??,?}???-m??????fF?c??o???3aC??|?"??9y?V?q?/aF9?????? ?K???+?f{B???6?Ј?РL4sډ?b?POi?&8?yD?ZMF?3??????6x???&-YT??=}?????ݤK???F<JWb
#??O?َ\mD;:r)????n????a?pU[??lu?'?
y%V+??\%œ]??gwvi?WP?_m???@V%y?'?a??ழa??m?lg?я>??N????JLv?On-?[?L(?º??O(Wb???c?-Ʈ4??Q)???ַƼ?i?p?7?@U;4?$0???w?]UE(?6??i???8?R?	_?J?"I????P??VGvgO+???X??i??(V.?????	?	}QC??@?&p?qЍF??f\k?h?>kU"PW?;?i?@K1??TS?????Z87??ǘ?c???Y?e???)d??K????\??#w?[G??b?׶????2Z?X@?M$?"?? Z???}hK????^\??f??RP:#??	k????n??????L?
B?H???;???T??-9\B;9y?RK??>??n/[? k{?A??w~J(W??$¥~?{?u?O?d???o׮???Տ6?????`???? 0k;?%???!?q}1??K??^??<7b?????R?fb??3??8????f??&?\HE-?a?ty????d??N?R??Δ??sn??v??:jB}+r?ʜX??j?讙3F;?9?dK?12?d?a??"S??&c?D??1??πQܓ?"?ܓ?r?Id?dM?1?????w??ܻ??.???dK????$?82?=?Ls?#˙??	Jy??m:??????-2??????O?kt??\?!G?<bx~n?e??P"?<4??d?R???V??Y29????&fxP#S,|ʐk??AEM@b??jd9*?dI?*/?t2?7???????t?ٷ?XaU2?G+?8?4Od9K??6?%???I???}*??>5Ϝ12?3'?<㙃L??@?xF ?<#??<??X??Y??<??Y??"K??yZ???vZ??$݂?w-n?^?3U!cy??1{rb7-?MGv?c?n*?m?WL???^???2??1?<G.???h?76fI??f??_t>^?_<<?????Z????}????_>?樥??????7?U?????Zg?????/????ӻ?i?bM??^?ɶ.a???m??r%`?>? F?n>]p?o????-??"?>??60?w?Z??o??a?<?_?4u-?P??K??Z?ߙ?gd?Qw???b?-???????O?;?`?8?&?D,zS?	?.?????????H??W?x?'?r	Ct?Q+*????y??}?pPl? =d???_u?_@6J??*Yi???]?c???$??	?D([B????C?V??st?^'????g????q좨?}P??2d?G??J޳?U??/???nd?????"??u???????x$?      ?      x?????? ? ?      ?   8   x?5ƻ E???????F???!???}??+f???j????v?:(??????Z?      ?   ?  x?u?[?&D??.&e?xm"+?2??
???J??H?yH?F??r?j?]????????????/?C.??u*?+??x(?륩????~?/?_=?+N?3vpN??O9\C???s??tȺ???????6ƌ?pK=???t?6?0??E??>Dn?X?/?!{?#d??>v(??)?U??|??,r??"?s?>??]?????????9]?~b??? ??	x??????4????????LE????ǁ?Cv??ӹ?<v{X?{&??z???Ia?r?l????/??????#?[??_-?d](?b???,^?!*5D?b5DPC5DPC?E?]D?GPGuL9@[w??~_|??uvܷ_+??????¹@pS??I???JVĒ?X2"1#?/???r?*?Vm??0??@N9?ё?ތ??;:???Dk?,R?????Lꀘb?9 ??h?@?????~h?M?????T ???]???V???q?,k??????ՀE#X4?=]9_@??ƪ!?0?f??햃I???mHi?!p]?d???R?????7!\??????//?k?$$*?3Y????ex=ë?C pڊ?3??Ӎ;8???/9SH???L??5YC+?B+?BQ+X? 	?^?,Wh?B??b??F.?}?*g?	?die?!?<^
????+?????r_U???uU???F???p?
|T8?p.?????b?R|?3?рG???7T??????PBJ?NQ??I???#?(?Zˆ?\?z"?9?r?&???D(V?B???l5???M?????n0u???n????߀???yd??YR_*3?i?B?S!'?T*?J?>?ш? 25?L&??)?3G,?jY?e?`X??2??1?r0??1??t? s?k]?ZG?뀰?z?#G8??A??!?d??`g??F?v??i?"???$ňZ#j?@?ﱃ?0?sfu0?#????@8???.~?ڛ?n?=Ze@?;???K?'?(Y& '9	?I@^R?$EJ?5??4??
E???bhǘ?iH{?S?HCS?`:#???\cyn?0:P??i???2???4?@??I?͆<9?d??@?S?~???Q:L?(??t???+	???	????()?l?઄?>??OLt{i?EH?"$}????|?߃?? b?p?QqA???P%=?^
??b?????{Pq?\$?C?k?"}?U?l}͒???? 	?8?B?5?Xh????p?sI????4Yo?H?u?JA??Ť?z[L???Ť?:R0??밡I?u??.mRw
?tͽ`?d??bv??C?Ț????5wz?????]?It:39??MR?aC?8?I???Ђ?fvI4c???Fir???	&M?ay?fư???yX^????&k?7Y????Mۛɚ?/L?<|a壩M?Fs?qTk?6|?ΣV?5wF??'}4??9??????????+?~?K??)I?O?$?ۧe???sьq$???,?Ѧ?5_??yX?e???I?ܭ???R?2?"I?i,0??bI?Tb)?f??E3?s??3xށ???V?={>?A??9?;Cc???H????8Q??]????4?=?6Q??r}.?,??$?????????#?K?)???|?~?*?-??vJ?ז0??(>??y??????kI???0'????k?-?!???2??=?)???g[?????:???r?O~?ɲ??8???%?II?Sͤ?n??m???wK??D?t?t??`[?p?*?????Ʉ????>?K?j?1?:?^?:B^???C1????y??y??yz,śF??(f>^??#1??7?x?`=ޘ???Ʋz]????G;'z++]?s?d?v?,zy?tK??????z+?Y?'?5;?|??,iq?ݏ8??G?炌v???ѣ??Yb<?=?R"'?k7??/iVKܝDK[\vJ?8?????6?^]?V??Ok{?w]?C,*?-?eC|xt???b??K?tˢ=_?j Ƈ?G$K??4???M?h?G?>?w=??^???"o?nŶ???T?M5K?צ???????p?:|????g???Q???xt?T?!??Y??,L?.?N??z?d?C1??U,?>ޘ???yc2???o$???F???6i3??ig5?6)nL;?vv?w????U???xc&??be??3?Λ+w??w`m>??a??<???B-?H^?HN8Fr?n??䕿??@f??*V?y?1?㍙?o?d6?g/?<?GbaFp(??W.l?l?l?-?,/M?*?
ߕ??13???cQ??Ǫ?K???Dk?b/??K:mPt?4͇B??]?˴>??????8??
?cJ?Q1>?.{w?t??B?(?}?ݡq8?;?0???Y{C?yM{C?Y-??t7??7?v?W4 $????Ŷ????	Z`???	6???>?Ͱ;R???d@o|?7g#??D$ " 	?@D"???D$ "	?H@D"??gG?????tu?g#=??HϮ?L?o??:??c?? ?͍a?C7??vva '?pp??	?p????A??N,8??ĂN,8nf??vz??i???ns?͗?Ζ\???D?$X<1??+Ѥ?&M4i?I???V>???4h?u???[??[????H?E?//r}?i?L+e? ??|??????p?B_?R8K??O?9
?Qh?BsT¬f?0??X??I?N*???^?Un?⮭b??[????ͪ???z?Ui?????xi?rT?Ұ????0?:;??w#o6܊7?k7"?????o??ƨntA?Du?Du?Du?Du?Du?????_?pf?s???F?52pc?????K[?c3???N????*??9?]kGN=?:??*?B??鋪]?G????>ЫX?
??U?J???ޯ<	?}??U?T??i???<?'W?"zFE?ͦ??i6ݽ???S??-L??`??O{+??uno?;;??\ە??c?}???G\[~????%??ן???	??      ?   !   x?3?LI-H?KI?KN5䬨??b?=... },      ?   ?  x??Vɶ?Z?W0?i?Vg????(???Mp??F??z?Q?V?{+?e???Z??V??;v??L	)?iI)(H?H?PۥUI??N?5g?9O?<?2|?@???7??qC?a??m?|cکr=??????*?]????k?\??????0*???]K???C?(OKD)????)=?D??-?7%? ?Խ#?y??î?/?ʉ???Ьu};??ю?ɘ5????G?If{q#?P?4?䵴?<??Q[S??????'F?0???w?:?ٗM9??Rv?????a??T????݊y???K??9??=????>??t?TW?j?????r/P???_??]zԼ#_?d??\?ic?+?l?ǾU??????L?X??(??К?xD?Ɉ???uPmC2U??(A??9%b	,Q|??5,#????ډ??"e]?^?U?m?Ga#??ߋat??6??????m?6??ZB???5?ò??f:[?{~?_???ڢj?GZ?Y?C??'!?^?K?l??*?`?g|rs?\??\????;?@?a???*a)?̜p`ʕ????3???BnN??ߠ?͘?{?y?x6??zrф]???~?5h?I??V?'ǣ???1??łdi?A?ӆJʐl??b?)??l???V??j???a?l?n?d7<oN`?Rs`ӦI???j?릅&?\?O	'MP?????Wr?? ?}??o???r?4?Z?|C?h??$??ѿL57G????~?W]???mE?$???A?H???????4??ha9?Q??w
??-9??-?ս??=3?U?<?Z/?MoYrS8????ֵ???
%C?,va?k?3??vV??? pO?????U ?hn?g???_??????W˅}????????OF?탉????d9¨X????x?,O^?<?(>A fx??>L?I???8"ޜ_A?[?l???e?o}9???^m?2??ВjNS9$N4???ϐΪ??c??S?y!A?pD????ŝ???s֨vXo????5?J?M???p??F??????!?>?w?ٯ??E??_?g?^???_??a+?w2??G>҄???lZ????i?L#???޴??2?1a??Ǒ1??E?F??N?4?x?W3~#%??b?-??WN????:絶????:???0????ʉ???,?e??qJ?3l???mm?ɲfj???4??C??wu??Pr?uY???)?}??o??i?_2?k?qc?h?B0h??ӝL????I?=뒜?i?+??nz???d???f>d???c?rb? ?\?]mQm??;????O[?oS?fV9l)C???z&dš??n????@P?&L??Ҿ@-?¿???Vٹ}(V?x?
?{Z???M???^??%V???l'?Ж@?	$?k<MG-$]?L?k??D?? ̣???B?w???????q?҅??rO?}???s?5)???<#5?vW[???5j???Mޗ?%Sj?	????Ηm%+zB^???1y??A???,4??|??]??fi???$?(<?%??,o????S8U릺???5μ??uZux????R"?Cwg??r?ޕ_Q?????9?p[<v?F
?.NR???f?kW????o??wD?vo[?*??ë&$~?i?_???ց?O4??K.~6????c~?W?by?? I??3:p?      ?   b  x?m?_o? ş?S?m?C??O??ѱ??jj[??^&UX?d??????M??????1?5I??M????y???]'#|=???&)A#jّ?qZ??q???IIQ??9f??Q|????-?!m??4)???y?A???X!???K??v??[?ͳ*E?j???$?i???8??aσ͚q?39??b?uB?5t?f?{??M??H?ҽ??(>???8t/𖤈2f?i??*C?pg?{O?W??b5t^2??n6f???r?5=
?`???#?'?u?B?????YxGsA?nr?(W???MVK??d`???߽s?J??D?	???l?6`RT?M?{n??-??]?d??Nʔ????
0?-???j=?7E??????Ph?<???,h??$?SĬ?????A?ϑJ:??9a??q?Ů??`^*z1*U? ?9৪I?)??d??H?&?"?f?2"/?-?8???#:??????,??g1??~)?
?$Ӹ?	w???.??<??#?-nwY???^t???֋Npa?-?????E?A??Gq??????G???r.{z??????X ?/?_??W z??`???r??+?_??zuE?Հ}??p}N/      ?     x?]T???&]K????`????&??=??+L_?WIfӕ$W?E??]??Yӷ?ﭖ|????Z/?^??8G?l>????RK9V??[??|???????2??)?:bhI?fu???V??????????'???F?#?X:???{?FV?j{F?̴1?r/y?'tOO??X:S??????U??kM=???'뉶?4?:z.??ܡ?3??"k$??????:?R?	E ?ʓBn?T=iJ??2?PBM??LZ??7?E?^xxEK??w?? ?u?)??6W)????`?????Lt<Kjl:|??E+wy5~?#?y弜?????	t?:,??c-+?Wާ?y?Y???+&q????c????Ѡ?,l%X]ۙ????<X?????$l?3??UK?Y?F??YK?E?0c??l Ư?g+???<Ϣ?????x?U/????	?m??S4?%?????/;?M
?[dg????zV?v?б????V4{??ʑ?+??L???X?I???C?7h??WM5>????z?X?{OM???#Ě??9\?m䀙?#??s@?Җ?Af.[>??&~q@????f!?t֧??ݏ??+?pտ_????????h?A?Tz?w,????+"???g?ئ!?'u???r 핔ث'?5??CNd?؆?iɽ?R?9k =?׻@A?@? 6?A??fȉ&? ????7#?w?%????@F?@L#????ҿ?	??#??Q??7ltG??????P????O
D=?%??|_?PiHPU#??0???      ?   s  x??Z]r??~?N1UyIj#d??/Y???ܵH?Hy??MmAl!?@Iym???@^u?$'I??$@?Ҋ?????(	?7??????~???q??!???DC?Tl??o8l??/?)???l??/????"??}(tu)????*z?p??1??s???k?F?,??N??hNW???~?M??y?~q?@rk??<:?"?|?;??/9:Q.??uRH???e1g???t???8a?lrQD?t???????E>+?&>.??????N^wN#??Xp?N,/??z? L?D?l?A{???q6+?j??Y6_y??x?« _?	?j7@?(???-?n?c?x?+- ?n??G:?RK.?D??)KS??wdj?6??A`뻘L2?2?Y?B Ᾱ9?g?*?</?i pqV???WYqO?W??????G?Q??Q?Mr?l.?{?Z؄???????*??Mw???73F?8???l?퍣|VL??Ev?ݜ7?V1/??Lk&?ԍ?w?ȉf??2???,VA?:6H?K?J???q???????<co?2?p?Ϣ?F?t#?\?h2 ?6օ ?????7??!x?ۇJh?????^?x??7Rn???? ?rˤ?kA?X?S?41??N???<Jr????B????Ŏsc??,\????^G?L_???.??$?cNH[???y9?ٻ|v????%??????,[ӒU???~.????F?c??JK??u乄030-09V?*uqB??~?????۟????Fqۨs0U?Q???U4,.???)???4?S?=?ݣN/Z?A#????2??(?@????ˢ̃2Mr??ϧ_?E??Y??????	?>???@?A]"D?1????n?2?????c?*??_z??+?5???T???xp2????Ћz??(?.??,??W??????,R??ux????????$=?f]wT?I$?R???2?V?|T???n?^-z<f?I?;??-???n??G?鐦"$x???J?????-4
?w(?? ?}
??.V?r??????k????y?뻡????pc)??z????h??6R????<.?/wu;`?K??uޥc??׿Y?????'$y"?^;#v7 ??????O#t?1Yv?~?P????1?Qd??R)L???	ʟjQWb????܎??a??VLq?0?K{g?;?\9??DWG?sT;???%⏸?{KEk??T?:?v-`U??a??K???OǽQ:???eY?f}???e?9ml??k6???V??l?"???Z?a͟h@W??
H]?A?҂4\z!?nـ?p=?M?C=?U?޴j~*?Tm?_-???|???=%j?,?^b??Dkj???x??=z?;?9z?H??<????G?eV??y~V?_?F??\2h??mI8n#W??^$D[?D?i?*?	?#??o???|???&	?z)??Ć銶??X??U0?J??A????~? ??$?O?h8?w:8???????w?????u3?껒?nm?j?PzE4??X?w??(??W?>??????????OZ?	??ŧ?C9-??A????)vv?v??Js͡?k뢀wŃk곅RVV?????u<0?E>?D??f???Zj??`>?????B??LV??=?&.<??%?????L?g?6?&??^o0 zJ?(?;;e?'?>???'?-?R????¸/?Č?/?F=l?V?????H_)???𰛦"???Y???Y/?Xch??'9_y?}??????Kȋ9?@??r????????,???J?Lꇋ%?[5??iC????????J?Tԫݘ?U??A???z湠f5??u/??En??3Jkr??
 ?|?ƴX?{x?I?6<????e?m?g`?q??}K&?3??g?3?	??f0*???ag<???4?d]???$,?])`??i??pgSHQ???U~???>
$??Q???q??iz3??&???i;P??g?eb??Sno?d[?@??:m?1|3?ڒ j)???$|[?|?eM?IB?hܪ?@߆ى??A?M´$?[????;?$l[?? ??z?wo%?~????NLԧ6$????R???nZG??b??Z̲r?>?-?k*??j????p~?5??5?K??????߳#???7?e-??e??G'??????O.ƴ??kr?ݩb??.Jrn?s?????v??!??Z?Z ???&??Fg?Z??
e?Ж???V???g????㑬g? ?Wlܛ??+?4?=?z??????????gg??%?ݜcR|????$??t;B??虱K2$?/Fȉ{?DMhc	??_ԷщH̵?F?$!? ?A=Q?f?_R?:?R??+???e?nO??Q4?y?x???c?&?;:+??a4?FԵQ?8#?4???I??=??K????x^$[??p????3B?|?N)?֖z?X???I?Z?ج'?ۛ?0[[Nu%?????Vb=?O?v{?Ap??V???o?D??ʷӓa???\?ȯ???e??ş??:?~Gopsk?j4Kn?F?Fko???X?/'??["???3Qw??bc?`u?W??|<bX1?H?9M??fU????????b8?{?*C??u??G?<JU??[?3?????ºj<?????B??c*???FV[SGD7??W???pƉ?T?-???yC?<??{\'W?z?*???pp???:X@?%?z???kS???????+Hv????H?A?ʁs;????ˏ?4X/^??_T?t?????j?'t???N??!VCIۜ~@8(??6???{??f??`|2??????=?,??M??/?{?2?.??????W ?HS???y?I?w??|>ϊY^<??W??2,??x?r?HCx?????|?e?c:o'?	B?>??}?v????X?@??}aXU?g???l?=J?????a???7<j?????????GU     