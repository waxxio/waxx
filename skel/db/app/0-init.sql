BEGIN;
CREATE FUNCTION generate_key() RETURNS character varying
    LANGUAGE sql IMMUTABLE
        AS $$select md5(now()::varchar||random()::varchar||random()::varchar);$$;
CREATE TABLE app_log (
	id serial primary key,
	date_time timestamp without time zone DEFAULT now(),
	usr_id integer,
	category character varying(32),
	name character varying(64),
	value character varying(254),
	related_id integer,
	ip_address character varying(39),
	user_agent character varying(1000)
);
CREATE TABLE email (
	id seriall primary key,
	to_email character varying(254) NOT NULL,
	to_name character varying(254),
	to_person_id integer,
	from_email character varying(254) NOT NULL,
	from_name character varying(254),
	from_person_id integer,
	reply_to_name character varying(254),
	reply_to_email character varying(254),
	subject character varying(254) NOT NULL,
	body_text text,
	body_html text,
	headers text,
	email_type character varying(254),
	document_id integer,
	process_status character varying(32) DEFAULT 'draft'::character varying NOT NULL,
	process_id integer,
	process_start timestamp with time zone,
	process_end timestamp with time zone,
	process_error text,
	create_date timestamp without time zone DEFAULT now() NOT NULL,
	mod_date timestamp without time zone DEFAULT now() NOT NULL,
	create_by_id integer,
	mod_by_id integer,
	cc character varying(4000),
	bcc character varying(4000)
);
CREATE TABLE grp (
	id serial primary key,
	name character varying(64),
	description character varying(254),
	create_date timestamp without time zone DEFAULT now(),
	mod_date timestamp without time zone DEFAULT now(),
	create_by_id integer,
	mod_by_id integer,
	CONSTRAINT grp_uniq UNIQUE(name)
);
INSERT INTO grp (name, description, create_by_id, mod_by_id) 
  VALUES ('admin', 'People who can do everything', 1, 1),
         ('dev', 'People who can do everything else', 1, 1);
CREATE TABLE usr (
	id serial primary key,
	usr_name character varying(254) NOT NULL,
	password_sha256 character varying(64),
	salt_aes256 character varying(254),
	failed_login_count smallint DEFAULT 0 NOT NULL,
	require_new_password boolean NOT NULL DEFAULT false,
	password_mod_date date DEFAULT now() NOT NULL,
	last_login_host character varying(254),
	last_login_date timestamp without time zone,
	create_date timestamp without time zone DEFAULT now(),
	mod_date timestamp without time zone DEFAULT now(),
	create_by_id integer,
	mod_by_id integer,
	key character varying(32) DEFAULT generate_key(),
	key_sent_date timestamp without time zone,
	CONSTRAINT usr_uniq UNIQUE(usr_name)
);  
CREATE TABLE usr_grp (
	id serial primary key,
	usr_id integer NOT NULL,
	grp_id integer NOT NULL,
	create_date timestamp without time zone DEFAULT now(),
	mod_date timestamp without time zone DEFAULT now(),
	create_by_id integer,
	mod_by_id integer,
	CONSTRAINT usr_grp_uniq UNIQUE(usr_id, grp_id)
);
INSERT INTO usr_grp (usr_id, grp_id, create_by_id, mod_by_id) 
  VALUES (1, 1, 1, 1),
         (1, 2, 1, 1);
COMMIT;
