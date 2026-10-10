-- =====================================================================
--  TIKALO : le serveur décide (anti-triche)
--  À coller dans Supabase > SQL Editor > New query > Run, APRÈS schema.sql.
--  Le script peut être relancé sans danger.
--
--  Avec un compte, c'est la base qui :
--    - tient les bonbecs et les sacs offerts (le téléphone ne peut plus les modifier),
--    - tire les billes des sacs, des fusions et des récompenses,
--    - paie la Confiserie d'après les vraies billes échangées,
--    - plafonne chaque gain (une quête, un jeu, un succès… ne paie qu'une fois).
--  Seules les billes tirées par le serveur (origine = 'serveur') pourront être
--  troquées ou vendues dans la cour de récré.
--
--  Les règles ci-dessous (prix, chances, valeurs) doivent rester les mêmes que dans index.html.
-- =====================================================================

create schema if not exists interne;   -- fonctions internes : pas accessibles depuis le site
revoke all on schema interne from public, anon, authenticated;

create table if not exists interne.migrations (nom text primary key, le timestamptz not null default now());

-- ---------- Billes : d'où vient chaque bille ----------
-- 'serveur' : tirée par la base (échangeable). 'appareil' : créée par le téléphone (billes de départ,
-- collection importée d'une partie sans compte…) : on peut jouer avec, pas la vendre ni la troquer.
alter table public.billes add column if not exists origine text not null default 'appareil';
-- une seule fois : les billes des testeurs déjà en base sont considérées comme sûres
do $$ begin
  if not exists (select 1 from interne.migrations where nom = 'origine-billes-existantes') then
    update public.billes set origine = 'serveur';
    insert into interne.migrations (nom) values ('origine-billes-existantes');
  end if;
end $$;
-- (le droit d'insérer des billes, donné dans schema.sql, ne comprend pas la colonne origine : le téléphone ne peut pas la choisir)
grant select (origine) on public.billes to authenticated;

-- ---------- Édition : la combientième bille de ce modèle (taille + décor + coloris) trouvée dans le monde ----------
alter table public.billes add column if not exists edition int;
-- security definer : le compte doit voir toutes les billes du monde, pas seulement celles du joueur
create or replace function interne.numeroter_edition() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if interne.coloris_normal(new.coloris) then   -- les billes de saison et secrètes n'ont pas d'édition
    perform pg_advisory_xact_lock(hashtext('edition|' || new.taille || '|' || new.decor || '|' || new.coloris));
    select count(*) + 1 into new.edition from public.billes b
      where b.taille = new.taille and b.decor = new.decor and b.coloris = new.coloris;
    new.donnees := new.donnees || jsonb_build_object('edn', new.edition);
  end if;
  return new;
end $$;
drop trigger if exists numeroter_edition on public.billes;
create trigger numeroter_edition before insert on public.billes for each row execute function interne.numeroter_edition();
-- une seule fois : les billes déjà en base reçoivent leur vraie édition, dans l'ordre où elles ont été trouvées
do $$ begin
  if not exists (select 1 from interne.migrations where nom = 'editions-reelles') then
    update public.billes b set edition = x.rn, donnees = b.donnees || jsonb_build_object('edn', x.rn)
      from (select id, row_number() over (partition by taille, decor, coloris order by numero) rn from public.billes where coloris < 48) x
      where b.id = x.id;
    insert into interne.migrations (nom) values ('editions-reelles');
  end if;
end $$;
grant select (edition) on public.billes to authenticated;

-- ---------- Portefeuille : bonbecs, sacs offerts, sac gratuit, bonbec du jour ----------
create table if not exists public.portefeuilles (
  joueur       uuid primary key references auth.users(id) on delete cascade,
  bonbecs      int  not null default 100 check (bonbecs >= 0),
  sacs         jsonb not null default '{}',                 -- sacs offerts en réserve : {"premium": 2, …}
  gratuit_t0   timestamptz not null default now() - interval '50 minutes',
  pity         int  not null default 0,                     -- sacs ouverts depuis le dernier Boulet ou Mammouth
  sacs_ouverts int  not null default 0,
  serie        int  not null default 0,                     -- bonbec du jour : jours de suite
  serie_jour   date,
  maj_le       timestamptz not null default now()
);
-- Le cadeau de bienvenue est lié au compte (4 octobre 2026, contre les faux comptes qui donnent tout à un compte principal) :
--  - depart : la part des bonbecs qui vient du cadeau de départ (1000). Elle est dépensée en premier (sachets, Pachinko),
--    mais ne peut ni partir dans un troc, ni payer au marché, ni servir aux enchères.
--  - ce qu'on obtient avec (billes, bonbecs ou sachets gagnés au Pachinko, recyclage, fusion) reste lié au compte.
--  - gratuits_lies : les sachets gratuits qu'on a en arrivant (5) donnent eux aussi des billes liées.
--  - sacs_lies : parmi les sachets offerts en réserve, ceux gagnés avec des bonbecs de départ.
alter table public.portefeuilles add column if not exists depart int not null default 0;
alter table public.portefeuilles add column if not exists gratuits_lies int not null default 0;
alter table public.portefeuilles add column if not exists sacs_lies jsonb not null default '{}';
alter table public.billes add column if not exists liee boolean not null default false;   -- une bille du cadeau de bienvenue : ne s'échange pas tout de suite
grant select (liee) on public.billes to authenticated;
-- (4 octobre 2026, plus tard) les billes liées deviennent échangeables 15 jours après l'inscription du joueur
create or replace function interne.fin_liee(qui uuid) returns timestamptz language sql stable as
$$ select created_at + interval '15 days' from auth.users where id = qui $$;
create or replace function interne.encore_liee(liee boolean, qui uuid) returns boolean language sql stable as
$$ select coalesce(liee and now() < coalesce(interne.fin_liee(qui), 'infinity'), false) $$;
-- chaque gain déjà payé (une quête du jour, un succès, un palier du passe…) : impossible de le toucher deux fois
create table if not exists public.gains (
  id      bigint generated always as identity primary key,
  joueur  uuid not null references auth.users(id) on delete cascade,
  source  text not null,
  cle     text not null,
  montant int  not null default 0,
  sac     text,
  le      timestamptz not null default now(),
  unique (joueur, source, cle)
);
-- mises des jeux à plusieurs (Course, Tic)
create table if not exists public.mises (
  id        bigint generated always as identity primary key,
  joueur    uuid not null references auth.users(id) on delete cascade,
  jeu       text not null,
  montant   int  not null,
  gain      int,
  le        timestamptz not null default now(),
  reglee_le timestamptz
);
-- comptes qui ont droit aux outils de test (à remplir à la main : insert into public.testeurs values ('<uuid>'))
create table if not exists public.testeurs (joueur uuid primary key references auth.users(id) on delete cascade);

alter table public.portefeuilles enable row level security;
alter table public.gains         enable row level security;
alter table public.mises         enable row level security;
alter table public.testeurs      enable row level security;
revoke all on public.portefeuilles, public.gains, public.mises, public.testeurs from anon, authenticated;
grant select on public.portefeuilles, public.gains to authenticated;
drop policy if exists portefeuille_lire on public.portefeuilles;
create policy portefeuille_lire on public.portefeuilles for select to authenticated using (joueur = auth.uid());
drop policy if exists gains_lire on public.gains;
create policy gains_lire on public.gains for select to authenticated using (joueur = auth.uid());

-- =====================================================================
--  LES RÈGLES DU JEU (mêmes valeurs que index.html)
-- =====================================================================
create or replace function interne.tailles() returns text[] language sql immutable as
$$ select array['mini','bille','chinoise','calot','boulet','mammouth'] $$;
create or replace function interne.rang(t text) returns int language sql immutable as
$$ select array_position(interne.tailles(), t) - 1 $$;   -- 0 (Mini) à 5 (Mammouth)

-- rareté de chaque décor (dans l'ordre de FAMILIES) et poids de chaque rareté
create or replace function interne.decor_rarete() returns int[] language sql immutable as
$$ select array[0,0,4,1,0,2,0,0,2,2,3,2,1,1,1,2,2,3,2,2,0,0,1,1,0,1,3,3,1,2,4,2, 5, 1,4, 5,5,5,5,5,5,5,5,5,5,5,5, 5, 5, 3,3,3, 0,0,0,0,0,1,1,1,2,3,1,4, 6] $$;   -- 32 : Pirate (événement, 5 = jamais dans les sacs) ; 33 Vitrail ; 34 Trou noir ; 35 à 46 : décors de saison (passe seulement) ; 47 : Bêta ; 48 : Super-héros (événement de novembre 2026) ; 49 Prisme, 50 Orage et 51 Méduse ; 10 octobre 2026 : nouvelle tier list (Opaline, Berlingot → commun ; Agate, Arlequin, Millefiori, Vitrail → peu commun ; Cristal, Givrée, Acier → rare), 52 à 63 nouveaux motifs (Étoilée, Cœurs, Bicolore, Vagues, Zigzag, Tricot, Nuages, Mouchetée, Jean, Ambre, Circuit, Feu d'artifice), 64 Vortex : MYTHIQUE (6)
create or replace function interne.poids_rarete() returns numeric[] language sql immutable as
$$ select array[10,5,2.5,0.8,0.2,0,0.02]::numeric[] $$;   -- la 6e : décors d'événement, jamais tirés ; la 7e : mythique (10 octobre 2026, DECOR_RAR[5] dans index.html)

create or replace function interne.coloris_base() returns int language sql immutable as $$ select 48 $$;   -- les coloris de saison commencent à 48
-- Les coloris qu'on tire dans les sachets : les 48 d'origine, puis ceux inventés par les joueurs (2 octobre 2026 : 76 Zède, 77 uwu ; 3 octobre : 78 Poups).
-- Mêmes numéros que PLAYER_PALS dans index.html. Un coloris « normal » compte dans l'album, les cases, l'édition, le recyclage et la fusion.
create or replace function interne.coloris_tirables() returns int[] language sql immutable as $$ select array(select generate_series(0, 47)) || array[76, 77, 78] $$;
create or replace function interne.coloris_normal(c int) returns boolean language sql immutable as $$ select c < 48 or c = any(array[76, 77, 78]) $$;
create or replace function interne.nb_coloris() returns int language sql immutable as $$ select 51 $$;
-- La bêta : tant qu'elle dure, chaque joueur peut réclamer une bille Bêta de chaque taille (décor 47, coloris 70 + rang de la taille :
-- Rubis, Émeraude, Saphir, Améthyste, Onyx, Diamant ; BETA dans index.html).
-- Elles sont rangées avec les billes secrètes (secrete = 'beta') : ni troc, ni marché, ni recyclage, ni classement.
-- supabase/reset.sql les garde. Au lancement : remplacer true par false (et BETA.open:false dans index.html).
create or replace function interne.beta_ouverte() returns boolean language sql immutable as $$ select true $$;
create or replace function interne.taux_shiny() returns numeric language sql immutable as $$ select 0.0005::numeric $$;   -- sac gratuit et fusions ; Classique ×2, Premium et Pirate ×4, Collector ×10 (interne.sac) ; 1 sur 2 000 (relevé le 2 octobre 2026 : 1 sur 10 000, c'était presque jamais)
create or replace function interne.revente() returns int[] language sql immutable as $$ select array[1,2,4,8,20,50] $$;   -- 6 octobre 2026 : toute la monnaie divisée par 10 (supabase/division10.sql)
create or replace function interne.prime_shiny() returns int[] language sql immutable as $$ select array[200,500,1500] $$;
create or replace function interne.fusion_n() returns int[] language sql immutable as $$ select array[3,5,5,6,8] $$;

-- les sacs : prix, nombre de billes, taille garantie (rang), chances de shiny, et chances de chaque taille position par position
-- (une ligne par bille, dans l'ordre d'ouverture ; la dernière est la vedette). Mêmes valeurs que BAGS dans index.html.
drop function if exists interne.sac(text);
create or replace function interne.sac(nom text, out prix int, out n int, out garantie int, out shiny numeric, out cotes numeric[])
language sql immutable as $$
  select v.prix, v.n, v.garantie, v.shiny, v.cotes from (values
    ('gratuit',     0, 3, null::int, 0.0005, array[[75,25,0,0,0,0],[55,35,10,0,0,0],[30,33,20,12,4,1]]::numeric[]),
    ('classique',  30, 5, null,      0.0010, array[[70,30,0,0,0,0],[50,38,12,0,0,0],[35,40,20,5,0,0],[20,35,30,13,2,0],[10,25,30,20,12,3]]::numeric[]),
    ('premium',    60, 5, 3,         0.0020, array[[0,80,20,0,0,0],[0,60,35,5,0,0],[0,40,45,15,0,0],[0,0,55,38,7,0],[0,0,0,60,34,6]]::numeric[]),
    ('collector', 150, 5, 4,         0.0050, array[[0,0,85,15,0,0],[0,0,65,35,0,0],[0,0,40,50,10,0],[0,0,0,60,38,2],[0,0,0,0,87,13]]::numeric[])
    -- (le Sachet Pirate et le Sachet Pirate Premium ont été retirés le 6 octobre 2026 : les billes d'événement viennent de la case à cocher)
  ) v(nom, prix, n, garantie, shiny, cotes) where v.nom = sac.nom
$$;

-- Événements : leurs dates (heure de Paris), le décor et les coloris de leurs billes (mêmes valeurs que EVENTS dans index.html)
create or replace function interne.evenement(nom text, out debut timestamptz, out fin timestamptz, out sac text, out decor int, out coloris int[])
language sql immutable as $$
  select v.debut, v.fin, v.sac, v.decor, v.coloris from (values
    -- le Pirate prolongé exceptionnellement jusqu'au 31 octobre (10 octobre 2026) ; les suivants restent sur deux semaines
    ('pirates', timestamptz '2026-09-30 00:00:00 Europe/Paris', timestamptz '2026-10-31 23:59:59 Europe/Paris', null, 32, array[65,66,67,68,69]),
    -- novembre 2026 : « Super-héros ! », pas de sachet à lui (on coche la case), décor 48, coloris 79 à 83 (après ceux des joueurs)
    ('superheros', timestamptz '2026-11-01 00:00:00 Europe/Paris', timestamptz '2026-11-14 23:59:59 Europe/Paris', null, 48, array[79,80,81,82,83])
  ) v(nom, debut, fin, sac, decor, coloris) where v.nom = evenement.nom
$$;
create or replace function interne.evenement_du_sac(s text) returns text language sql immutable as $$
  select null::text   -- plus aucun sachet d'événement (6 octobre 2026)
$$;
-- Billes d'événement (3 octobre 2026) : plus de sac d'événement en vente. Pendant l'événement, le joueur coche (ou non) « billes
-- d'événement » sur les sacs Classique, Premium et Collector : case cochée, chaque bille a 50 % de chances d'être du décor de l'événement
-- et la vedette (la dernière) l'est toujours ; case décochée, aucune. En simulation (fusion d'événement comprise), un joueur qui ouvre
-- surtout des Classiques finit l'album d'événement avec ~20 000 bonbecs. Mêmes valeurs dans index.html (EV_DROP).
-- (Les doublons et la boutique d'événement ont été retirés le même jour.)
alter table public.portefeuilles drop column if exists doublons;
drop function if exists public.boutique_evenement(text, int);
drop function if exists interne.doublons_du_sac(text);
drop function if exists interne.prix_doublons();
create or replace function interne.evenement_en_cours(out nom text, out debut timestamptz, out fin timestamptz, out decor int, out coloris int[])
language sql stable as $$
  select e.nom, v.debut, v.fin, v.decor, v.coloris from unnest(array['pirates','superheros']) e(nom), interne.evenement(e.nom) v
  where now() between v.debut and v.fin limit 1
$$;
create or replace function interne.taux_evenement(s text) returns numeric language sql immutable as $$
  select case when s in ('classique', 'premium', 'collector') then 0.5 else 0 end::numeric $$;

-- la date du jour, à l'heure française (les quêtes et le bonbec du jour changent à minuit)
create or replace function interne.aujourdhui() returns date language sql stable as
$$ select (now() at time zone 'Europe/Paris')::date $$;
-- la saison en cours, comme dans le jeu : « 2026-9 »
create or replace function interne.saison() returns text language sql stable as
$$ select to_char(now() at time zone 'Europe/Paris', 'YYYY') || '-' || extract(month from now() at time zone 'Europe/Paris')::int $$;

-- une saison du passe dont on peut encore payer les paliers : celle du mois,
-- ou celle du mois d'avant pendant les 7 premiers jours (récompenses oubliées versées au changement de mois)
create or replace function interne.saison_valide(s text, quand timestamptz default now()) returns boolean language sql stable as $$
  select s = to_char(quand at time zone 'Europe/Paris', 'YYYY') || '-' || extract(month from quand at time zone 'Europe/Paris')::int
      or (extract(day from quand at time zone 'Europe/Paris') <= 7
          and s = to_char((quand at time zone 'Europe/Paris') - interval '1 month', 'YYYY') || '-' || extract(month from (quand at time zone 'Europe/Paris') - interval '1 month')::int)
$$;

-- =====================================================================
--  OUTILS INTERNES
-- =====================================================================
-- tirage pondéré : renvoie un indice à partir de 1
create or replace function interne.tirer(poids numeric[], depuis int default 1) returns int language plpgsql volatile as $$
declare tot numeric := 0; x numeric; i int;
begin
  for i in depuis..array_length(poids,1) loop tot := tot + poids[i]; end loop;
  x := random() * tot;
  for i in depuis..array_length(poids,1) loop
    x := x - poids[i];
    if x < 0 then return i; end if;
  end loop;
  return array_length(poids,1);
end $$;

create or replace function interne.tirer_decor() returns int language plpgsql volatile as $$
declare r int[] := interne.decor_rarete(); w numeric[] := interne.poids_rarete(); p numeric[] := '{}'; i int;
begin
  for i in 1..array_length(r,1) loop p := p || w[r[i]+1]; end loop;
  return interne.tirer(p) - 1;
end $$;

-- 0 = pas shiny, 1 Irisée (75 %), 2 Dorée (21 %), 3 Lumineuse (4 %)
create or replace function interne.tirer_shiny(taux numeric) returns int language sql volatile as $$
  select case when random() < taux then interne.tirer(array[75,21,4]::numeric[]) else 0 end
$$;

-- crée une bille en base pour ce joueur et la renvoie telle que le jeu la connaît
-- src : d'où elle vient (gratuit, classique, premium, collector, fusion, chateau, passe, secrete, test)
drop function if exists interne.nouvelle_bille(uuid, text, int, int, int, text, bigint, jsonb, uuid);
create or replace function interne.nouvelle_bille(qui uuid, taille text, decor int default null, coloris int default null,
  shiny int default 0, secrete text default null, graine bigint default null, extra jsonb default '{}', bid uuid default null, src text default null,
  liee boolean default false)
returns jsonb language plpgsql volatile as $$
declare d int := coalesce(decor, interne.tirer_decor());
        c int := coalesce(coloris, (interne.coloris_tirables())[1 + floor(random()*array_length(interne.coloris_tirables(), 1))::int]);
        s bigint := coalesce(graine, floor(random()*4294967296)::bigint);
        don jsonb; r record;
begin
  don := jsonb_build_object('seed', s, 'type', taille, 'family', d, 'pal', c, 'shiny', shiny,
           'at', floor(extract(epoch from now())*1000)::bigint) || extra;
  if secrete is not null then don := don || jsonb_build_object('secret', secrete); end if;
  if src is not null then don := don || jsonb_build_object('src', src); end if;
  if liee then don := don || jsonb_build_object('lie', floor(extract(epoch from coalesce(interne.fin_liee(qui), now()))*1000)::bigint); end if;   -- échangeable à partir de (ms)
  insert into public.billes (id, proprietaire, seed, taille, decor, coloris, shiny, secrete, donnees, origine, liee)
    values (coalesce(bid, gen_random_uuid()), qui, s, taille, d, c, shiny, secrete, don, 'serveur', coalesce(liee, false))
    returning id, numero, donnees into r;   -- donnees : avec l'édition ajoutée par la base
  return r.donnees || jsonb_build_object('id', r.id, 'no', r.numero, 'srv', true);
end $$;

-- (l'ancienne version, sans « liee », rendrait les appels ambigus)
drop function if exists interne.nouvelle_bille(uuid, text, int, int, int, text, bigint, jsonb, uuid, text);

-- l'état du portefeuille, envoyé au jeu après chaque action
create or replace function interne.etat(qui uuid) returns jsonb language sql stable as $$
  select jsonb_build_object('bonbecs', p.bonbecs, 'depart', least(p.depart, p.bonbecs), 'sacs', p.sacs,
    'gratuit_t0', floor(extract(epoch from p.gratuit_t0)*1000)::bigint, 'pity', p.pity, 'sacs_ouverts', p.sacs_ouverts,
    'serie', p.serie, 'serie_jour', p.serie_jour, 'testeur', exists (select 1 from public.testeurs t where t.joueur = qui))
  from public.portefeuilles p where p.joueur = qui
$$;

create or replace function interne.moi() returns uuid language plpgsql stable as $$
begin
  if auth.uid() is null then raise exception 'connexion_requise'; end if;
  if not exists (select 1 from public.portefeuilles where joueur = auth.uid()) then raise exception 'portefeuille_absent'; end if;
  return auth.uid();
end $$;

create or replace function interne.crediter(qui uuid, j int, sac text default null) returns void language plpgsql as $$
begin
  update public.portefeuilles set bonbecs = bonbecs + greatest(j,0), maj_le = now(),
    sacs = case when sac is null then sacs else jsonb_set(sacs, array[sac], to_jsonb(coalesce((sacs->>sac)::int,0) + 1)) end
  where joueur = qui;
end $$;

-- un gain obtenu avec des bonbecs de départ : il reste de départ
create or replace function interne.crediter_lie(qui uuid, j int, sac text default null) returns void language plpgsql as $$
begin
  perform interne.crediter(qui, j, sac);
  update public.portefeuilles set depart = depart + greatest(j,0),
    sacs_lies = case when sac is null then sacs_lies else jsonb_set(sacs_lies, array[sac], to_jsonb(coalesce((sacs_lies->>sac)::int,0) + 1)) end
  where joueur = qui;
end $$;
-- payer pour jouer (sachet, Pachinko) : les bonbecs de départ partent en premier. Renvoie vrai si on en a utilisé (ce qu'on obtient est alors lié).
create or replace function interne.payer(qui uuid, montant int) returns boolean language plpgsql as $$
declare d int;
begin
  select least(depart, bonbecs) into d from public.portefeuilles where joueur = qui;
  update public.portefeuilles set bonbecs = bonbecs - montant, depart = greatest(least(depart, bonbecs) - montant, 0), maj_le = now()
    where joueur = qui and bonbecs >= montant;
  if not found then raise exception 'pas_assez'; end if;
  return coalesce(d, 0) > 0;
end $$;
-- payer un autre joueur (troc, marché, enchère) : seulement avec les bonbecs gagnés en jouant, jamais ceux du départ
create or replace function interne.payer_libre(qui uuid, montant int) returns void language plpgsql as $$
begin
  if montant <= 0 then return; end if;
  if not exists (select 1 from public.portefeuilles where joueur = qui and bonbecs >= montant) then raise exception 'pas_assez'; end if;
  update public.portefeuilles set bonbecs = bonbecs - montant, maj_le = now() where joueur = qui and bonbecs - least(depart, bonbecs) >= montant;
  if not found then raise exception 'bonbecs_depart'; end if;
end $$;
-- ce qu'on peut donner à un autre joueur
create or replace function interne.libres(qui uuid) returns int language sql stable as
$$ select coalesce((select bonbecs - least(depart, bonbecs) from public.portefeuilles where joueur = qui), 0) $$;

-- =====================================================================
--  FONCTIONS APPELÉES PAR LE JEU
-- =====================================================================

-- Première connexion d'un compte : le cadeau de bienvenue, toujours le même (1000 bonbecs de départ et 5 sachets gratuits liés).
-- (4 octobre 2026 : on ne reprend plus les bonbecs ni les sacs annoncés par la page, qu'un tricheur pouvait gonfler.
--  Les paramètres restent pour les pages déjà ouvertes, mais sont ignorés.)
create or replace function public.eco_demarrer(bonbecs int default 100, sacs jsonb default '{}', pity int default 0)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := auth.uid();
begin
  if qui is null then raise exception 'connexion_requise'; end if;
  if not exists (select 1 from portefeuilles where joueur = qui) then
    insert into portefeuilles (joueur, bonbecs, depart, gratuits_lies) values (qui, 100, 100, 5)
      on conflict (joueur) do nothing;
  end if;
  return interne.etat(qui);
end $$;

create or replace function public.eco_etat() returns jsonb language plpgsql security definer set search_path = public as $$
begin return interne.etat(interne.moi()); end $$;

-- Ouvrir un sac (acheté, gratuit ou offert). Renvoie les billes tirées.
drop function if exists public.ouvrir_sac(text, boolean);
-- evenement : la case « billes d'événement » cochée par le joueur
create or replace function public.ouvrir_sac(nom text, offert boolean default false, evenement boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); p portefeuilles; r record; ev record; evc record; evb boolean; stock int; t int; i int; d int; c int;
        tirees int[] := '{}'; shinies int[] := '{}'; billes jsonb := '[]'; force boolean := false; lie boolean := false;
begin
  select * into r from interne.sac(nom);
  if r.n is null then raise exception 'sac_inconnu'; end if;
  select * into evc from interne.evenement_en_cours();
  select * into p from portefeuilles where joueur = qui for update;
  if offert then
    if coalesce((p.sacs->>nom)::int,0) < 1 then raise exception 'plus_de_sac'; end if;
    lie := coalesce((p.sacs_lies->>nom)::int,0) > 0;   -- un sachet gagné avec des bonbecs de départ
    update portefeuilles set sacs = jsonb_set(sacs, array[nom], to_jsonb((sacs->>nom)::int - 1)),
      sacs_lies = case when lie then jsonb_set(sacs_lies, array[nom], to_jsonb((sacs_lies->>nom)::int - 1)) else sacs_lies end
      where joueur = qui;
  elsif r.prix = 0 then
    stock := least(10, floor(extract(epoch from now() - p.gratuit_t0) / 600)::int);   -- jusqu'à 10 d'avance (FREE_MAX)
    if stock < 1 then raise exception 'pas_encore'; end if;
    lie := p.gratuits_lies > 0;   -- les sachets gratuits du cadeau de bienvenue
    update portefeuilles set gratuit_t0 = case when stock >= 10 then now() - interval '90 minutes' else gratuit_t0 + interval '10 minutes' end,
      gratuits_lies = greatest(gratuits_lies - 1, 0)
      where joueur = qui;
  else
    lie := interne.payer(qui, r.prix);
  end if;
  -- les tailles
  for i in 1..r.n loop
    t := interne.tirer(array(select unnest(r.cotes[i:i][1:6]))) - 1;   -- les chances de la position i
    tirees := tirees || t;
    shinies := shinies || interne.tirer_shiny(r.shiny);
  end loop;
  -- garantie de la cour : un Boulet au plus tard tous les 10 sacs
  if p.pity + 1 >= 10 and not exists (select 1 from unnest(tirees) x where x >= 4) then
    tirees[r.n] := case when random() * (r.cotes[r.n][5] + r.cotes[r.n][6]) < r.cotes[r.n][6] then 5 else 4 end;
    force := true;
  end if;
  update portefeuilles set sacs_ouverts = sacs_ouverts + 1, maj_le = now(),
    pity = case when exists (select 1 from unnest(tirees) x where x >= 4) then 0 else pity + 1 end
    where joueur = qui;
  for i in 1..r.n loop
    d := null; c := null;
    -- pendant l'événement, si le joueur l'a choisi : une bille d'un sac Classique, Premium ou Collector peut être une bille
    -- d'événement (50 %), et la vedette l'est toujours
    if d is null and evc.decor is not null and evenement and interne.taux_evenement(nom) > 0 and (i = r.n or random() < interne.taux_evenement(nom)) then
      d := evc.decor; c := evc.coloris[1 + floor(random()*array_length(evc.coloris,1))::int];
    end if;
    billes := billes || interne.nouvelle_bille(qui, (interne.tailles())[tirees[i]+1], shiny => shinies[i], src => nom, decor => d, coloris => c, liee => lie);
  end loop;
  return jsonb_build_object('eco', interne.etat(qui), 'billes', billes, 'force', force);
end $$;

-- La Confiserie : échange des billes contre des bonbecs. Seules les billes tirées par le serveur rapportent.
create or replace function public.echanger_billes(ids uuid[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); total int := 0; lie int := 0; v int; n int := 0; b record;
begin
  perform 1 from portefeuilles where joueur = qui for update;
  for b in select * from billes where id = any(ids) and proprietaire = qui and detruite_le is null and secrete is null for update loop
    if b.origine = 'serveur' then
      v := case when b.shiny > 0 and interne.coloris_normal(b.coloris)
        then (interne.revente())[interne.rang(b.taille)+1] * 10 + (interne.prime_shiny())[b.shiny]
        else (interne.revente())[interne.rang(b.taille)+1] end
        * case when (interne.decor_rarete())[b.decor+1] = 6 then 20 else 1 end;   -- (10 octobre 2026) le motif mythique : ×20 (MYTH_RECYCLE_MULT dans index.html)
      total := total + v; if interne.encore_liee(b.liee, qui) then lie := lie + v; end if;   -- une bille encore liée rend des bonbecs de départ
    end if;
    update billes set detruite_le = now(), detruite_raison = 'recyclee' where id = b.id;
    insert into billes_historique (bille, de, vers, motif) values (b.id, qui, null, 'detruite');
    n := n + 1;
  end loop;
  perform interne.crediter(qui, total - lie);
  perform interne.crediter_lie(qui, lie);
  return jsonb_build_object('eco', interne.etat(qui), 'total', total, 'n', n);
end $$;

-- La fusion : N billes d'une même taille contre une de la taille au-dessus
create or replace function public.fusionner(ids uuid[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); tailles text[]; rg int; nb int; b record; lie boolean;
begin
  select array_agg(distinct taille), count(*), bool_or(interne.encore_liee(liee, qui)) into tailles, nb, lie from billes
    where id = any(ids) and proprietaire = qui and detruite_le is null and secrete is null
      and shiny = 0 and interne.coloris_normal(coloris) and origine = 'serveur';
  if tailles is null or array_length(tailles,1) <> 1 then raise exception 'fusion_invalide'; end if;
  rg := interne.rang(tailles[1]);
  if rg >= 5 or nb <> (interne.fusion_n())[rg+1] or nb <> array_length(ids,1) then raise exception 'fusion_invalide'; end if;
  for b in select id from billes where id = any(ids) for update loop
    update billes set detruite_le = now(), detruite_raison = 'fusionnee' where id = b.id;
    insert into billes_historique (bille, de, vers, motif) values (b.id, qui, null, 'detruite');
  end loop;
  return jsonb_build_object('eco', interne.etat(qui),
    'bille', interne.nouvelle_bille(qui, (interne.tailles())[rg+2], shiny => interne.tirer_shiny(interne.taux_shiny() * nb), src => 'fusion', liee => lie));   -- une bille liée dedans : le résultat l'est aussi
end $$;

-- Fusion d'événement (2 octobre 2026) : des billes d'événement (décor 32 Pirate…) d'une même taille, d'un même décor et d'un même coloris
-- donnent une bille de la taille au-dessus, dans ce décor et ce coloris. 3 billes jusqu'à la Chinoise, puis 2 (FUSION_EV dans index.html).
-- Pas de shiny en entrée ; la shiny peut sortir comme pour une fusion normale. Les billes en vente ou dans un troc ne peuvent pas fusionner.
create or replace function interne.fusion_ev_n() returns int[] language sql immutable as $$ select array[3,3,2,2,2] $$;
create or replace function interne.decor_evenement(d int) returns boolean language sql immutable as $$
  select exists (select 1 from unnest(array['pirates','superheros']) e(nom), interne.evenement(e.nom) v where v.decor = d)
$$;
create or replace function public.fusion_evenement(ids uuid[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); g record; rg int; b record;
begin
  select count(*) nb, count(distinct taille) nt, count(distinct decor) nd, count(distinct coloris) nc, min(taille) taille, min(decor) decor, min(coloris) coloris,
    bool_or(interne.encore_liee(liee, qui)) lie
    into g from billes
    where id = any(ids) and proprietaire = qui and detruite_le is null and secrete is null and shiny = 0 and origine = 'serveur';
  if g.nb = 0 or g.nt <> 1 or g.nd <> 1 or g.nc <> 1 or g.nb <> array_length(ids,1) or not interne.decor_evenement(g.decor) then raise exception 'fusion_invalide'; end if;
  rg := interne.rang(g.taille);
  if rg >= 5 or g.nb <> (interne.fusion_ev_n())[rg+1] then raise exception 'fusion_invalide'; end if;
  for b in select id from billes where id = any(ids) for update loop
    if interne.en_vente(b.id) then raise exception 'bille_indisponible'; end if;   -- (une bille liée peut fusionner)
    update billes set detruite_le = now(), detruite_raison = 'fusionnee' where id = b.id;
    insert into billes_historique (bille, de, vers, motif) values (b.id, qui, null, 'detruite');
  end loop;
  return jsonb_build_object('eco', interne.etat(qui),
    'bille', interne.nouvelle_bille(qui, (interne.tailles())[rg+2], decor => g.decor, coloris => g.coloris,
                                    shiny => interne.tirer_shiny(interne.taux_shiny() * g.nb), src => 'fusion', liee => g.lie));
end $$;

-- Le Pachinko (2 octobre 2026) : une bille gratuite par jour (elle compte dans les 6 jeux du jour), puis 100 bonbecs la bille (200 jusqu'au 2 octobre au soir).
-- Le serveur tire la case ; le jeu fait tomber la bille jusqu'à elle. Cases de gauche à droite : mêmes valeurs que PACHI dans index.html.
-- Plus un lot vaut cher, plus il est rare : 50 > 200 > Classique (300) > 400 > Premium (600) > 1000 > Collector (1 500) > Bille.
-- Réglé « comme un vrai casino » (2 octobre 2026, le soir) : en moyenne une bille de 100 rend ~94,5 (sachets comptés à leur prix),
-- ~62 en bonbecs seuls ; on retrouve au moins sa mise 1 fois sur 5.
-- Case Mammouth : 0,05 %, un Mammouth garanti (décor tiré comme dans un sachet, coloris au hasard, shiny comme dans le Sachet Collector).
create or replace function interne.pachinko_cases() returns table(k int, poids numeric, bonbecs int, sac text, taille text) language sql immutable as $$
  -- 3 octobre 2026 : bille à 150, et 0 → 32,9 %, 50 → 26 %, 200 → 18 %, Classique 13 %, 400 → 4 %, Premium 3 %, 1000 → 2 %, Collector 1 %, Mammouth 0,1 % (PACHI dans index.html)
  -- 6 octobre 2026 : montants divisés par 10 (bille 15 ; cases 100, 40, 20, 5)
  select * from (values (0, 0.1, 0, null::text, 'mammouth'::text), (1, 2, 100, null, null), (2, 4, 40, null, null),
    (3, 9, 20, null, null), (4, 13, 5, null, null), (5, 32.9, 0, null, null), (6, 13, 5, null, null),
    (7, 9, 20, null, null), (8, 13, 0, 'classique', null), (9, 3, 0, 'premium', null), (10, 1, 0, 'collector', null)) v(k, poids, bonbecs, sac, taille)
$$;
create or replace function interne.pachinko_roue() returns numeric[] language sql immutable as $$ select array[10,15,20,25,20,10]::numeric[] $$;   -- Mini → Mammouth
create or replace function public.pachinko(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); today text := interne.aujourdhui()::text; c record; b jsonb := null; x numeric; acc numeric := 0; t text := null; lie boolean := false; n int := null;
begin
  perform 1 from portefeuilles where joueur = qui for update;
  if not payer then   -- la bille du jour (une seule)
    begin insert into gains (joueur, source, cle, montant) values (qui, 'jeu', today || '|pachinko', 0);
    exception when unique_violation then raise exception 'deja'; end;
  else
    -- 5 octobre 2026 : 20 billes achetées par jour au plus (PACHI_MAX dans index.html), la bille du jour en plus
    select count(*) into n from gains g where g.joueur = qui and g.source = 'plinko' and g.cle like today || '|%';
    if n >= 4 then raise exception 'limite_plinko'; end if;   -- une bille offerte + 4 achetées par jour (2 du 6 au 9 octobre 2026) (comme les autres jeux de hasard)
    lie := interne.payer(qui, 15);   -- la bille de plus : 15 (PACHI_PRICE) ; payée avec des bonbecs de départ, le lot reste lié
    n := n + 1;
    insert into gains (joueur, source, cle) values (qui, 'plinko', today || '|' || n);
  end if;
  x := random() * (select sum(poids) from interne.pachinko_cases());
  for c in select * from interne.pachinko_cases() order by k loop
    acc := acc + c.poids; exit when x < acc;
  end loop;
  if lie then perform interne.crediter_lie(qui, c.bonbecs, c.sac); else perform interne.crediter(qui, c.bonbecs, c.sac); end if;
  if not payer and c.bonbecs > 0 then update gains set montant = c.bonbecs where joueur = qui and source = 'jeu' and cle = today || '|pachinko'; end if;
  if c.taille = 'mammouth' then
    t := 'mammouth';
    b := interne.nouvelle_bille(qui, t, shiny => interne.tirer_shiny(interne.taux_shiny() * 10), src => 'pachinko', liee => lie);
  end if;
  return jsonb_build_object('eco', interne.etat(qui), 'case', c.k, 'bonbecs', c.bonbecs, 'sac', c.sac, 'taille', t, 'bille', b, 'achetees', n);
end $$;

-- La Roue du jour (6 octobre 2026) : un tour gratuit par jour, à la place du Casse-briques. Compte dans les 6 jeux du jour (gains 'jeu' today|roue).
-- Parts dans l'ordre de la roue (ROUE dans index.html) ; chances proches du Plinko : 5 → 30,7 %, 10 → 22 %, 20 → 16 %, Classique 13 %,
-- 40 → 7 %, Premium 6 %, 100 → 3 %, Collector 2 %, Mammouth 0,3 % (shiny comme dans le Sachet Collector).
create or replace function interne.roue_cases() returns table(k int, poids numeric, bonbecs int, sac text, taille text) language sql immutable as $$
  -- (6 octobre 2026, le soir) un tour acheté coûte 15 : 5 → 35,8 %, 10 → 25 %, 20 → 16 %, Classique 10 %, 40 → 6 %, Premium 4 %, 100 → 2 %, Collector 1 %, Mammouth 0,2 %
  select * from (values (0, 0.2, 0, null::text, 'mammouth'::text), (1, 17.9, 5, null, null), (2, 10, 0, 'classique', null), (3, 12.5, 10, null, null),
    (4, 6, 40, null, null), (5, 17.9, 5, null, null), (6, 4, 0, 'premium', null), (7, 16, 20, null, null), (8, 12.5, 10, null, null),
    (9, 2, 100, null, null), (10, 1, 0, 'collector', null)) v(k, poids, bonbecs, sac, taille)
$$;
-- public.roue(payer) est dans supabase/chance.sql (6 octobre 2026 : un tour offert + 2 achetés par jour)
drop function if exists public.roue();

-- Le bonbec du jour : calendrier de 4 semaines, calculé par le serveur
create or replace function public.bonbec_du_jour()
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); p portefeuilles; today date := interne.aujourdhui(); s int; i int;
        -- 6 octobre 2026 : ÷10 et presque 2 fois plus généreux (DAILY_CAL dans index.html)
        -- un seul Sachet Collector par tour de 28 jours (avant, la 4e semaine recommençait et en donnait un chaque semaine)
        j int[] := array[10,15,20,10,25,30,0, 15,20,25,15,30,35,20, 20,25,30,0,35,40,20, 25,30,35,25,40,50,50];
        sac text[] := array[null,null,null,'classique',null,null,'premium', null,null,null,'classique',null,null,'premium',
                            null,null,null,'premium',null,null,'premium', null,null,null,'premium',null,null,'collector'];
begin
  select * into p from portefeuilles where joueur = qui for update;
  if p.serie_jour = today then raise exception 'deja'; end if;
  s := case when p.serie_jour = today - 1 then p.serie + 1 else 1 end;
  i := 1 + (s - 1) % 28;   -- après 28 jours, le calendrier repart au jour 1
  update portefeuilles set serie = s, serie_jour = today where joueur = qui;
  perform interne.crediter(qui, j[i], sac[i]);
  return jsonb_build_object('eco', interne.etat(qui), 'j', j[i], 'sac', sac[i], 'jour', i, 'serie', s);
end $$;

-- Les 3 jeux du jour (6 octobre 2026) : les mêmes pour tout le monde, calculés à partir de la date (même calcul que jeuxDuJour dans index.html).
-- Toujours un jeu d'adresse (Tir, Pot, Château ou Tic) en premier, puis 2 autres parmi les 7 restants.
-- Hasard : x → (x² + 7) mod 65521 (petits nombres : le même résultat exact en SQL et en JavaScript).
-- (9 octobre 2026) la Marelle prend la place du Pot, à la même position (JEUX_TOUS dans index.html)
create or replace function interne.jeux_du_jour(j date) returns text[] language plpgsql immutable as $$
declare tous text[] := array['tir','marelle','chateau','tic','roue','pachinko','grattage','distributeur'];
        x bigint := ((j - date '2026-01-01') * 7919 + 12345) % 65521; a text; b text; c text; r text[];
begin
  x := (x * x + 7) % 65521; x := (x * x + 7) % 65521; a := tous[1 + x % 4];
  r := array_remove(tous, a);  x := (x * x + 7) % 65521; b := r[1 + x % 7];
  r := array_remove(r, b);     x := (x * x + 7) % 65521; c := r[1 + x % 6];
  return array[a, b, c];
end $$;

-- Tous les autres gains : chacun ne paie qu'une fois, et jamais plus que ce que le jeu peut donner
create or replace function public.gagner(source text, cle text, montant int, sac text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); today text := interne.aujourdhui()::text; k text; maxi int; nq int; ev record;
        -- (8 octobre 2026) les 4 mêmes quêtes chaque jour (QUESTS dans index.html)
        quetes jsonb := '{"sachets20":15,"jeux6":15,"boulets3":15,"confiserie":5}';
begin
  if montant < 0 then raise exception 'montant_invalide'; end if;
  if sac is not null and sac not in ('classique','premium','collector') then raise exception 'sac_inconnu'; end if;
  perform 1 from portefeuilles where joueur = qui for update;
  case source
    when 'quete' then   -- les 4 quêtes du jour, chacune une fois par jour, au tarif de la quête
      if not quetes ? cle or montant <> (quetes->>cle)::int or sac is not null then raise exception 'montant_invalide'; end if;
      k := today || '|' || cle;
    when 'quetes-bonus' then   -- les 4 quêtes : un Sac Premium offert (8 octobre 2026 ; avant, un Classique)
      if montant <> 0 or sac is distinct from 'premium' then raise exception 'montant_invalide'; end if;
      select count(*) into nq from gains g where g.joueur = qui and g.source = 'quete' and g.cle in (select today || '|' || x from jsonb_object_keys(quetes) x);
      if nq < 4 then raise exception 'pas_fini'; end if;
      k := today || '|premium';
    when 'jeu' then     -- une récompense par jour et par jeu (au Tir : par trou)
      maxi := case when cle ~ '^tir\|[0-5]$' then 25 when cle = 'pot' then 25 when cle = 'chateau' then 34
                   when cle in ('course','tic') then 20 end;   -- une partie par jour et par jeu (DAY_GAMES dans index.html)
      if maxi is null or montant > maxi or sac is not null then raise exception 'montant_invalide'; end if;
      k := today || '|' || cle;
    when 'jeux-bonus' then   -- les 6 jeux du jour joués (le Tir et les 5 autres) : un Sac Premium
      if montant <> 0 or sac is distinct from 'premium' then raise exception 'montant_invalide'; end if;
      -- (6 octobre 2026) les 3 jeux du jour, tirés chaque jour parmi 8 (interne.jeux_du_jour) : seule la partie offerte compte
      if (select count(*) from gains g where g.joueur = qui and g.source = 'jeu'
            and g.cle in (select today || '|' || case when x = 'tir' then 'tir|0' else x end from unnest(interne.jeux_du_jour(today::date)) x)) < 3
        then raise exception 'pas_encore'; end if;
      k := today;
    when 'succes' then
      if montant > 1000 then raise exception 'montant_invalide'; end if;
      k := cle;
    when 'serie' then   -- (8 octobre 2026) les séries à thème ont été retirées du jeu
      raise exception 'deja';   -- 'deja' : une vieille page encore ouverte ne montre pas d'erreur
    when 'evenement' then   -- (4 octobre 2026) plus de sachet d'événement offert : on coche « billes d'événement » sur les sachets.
      raise exception 'deja';   -- 'deja' : les anciens clients ne montrent pas d'erreur, et le serveur corrige leur compte de sachets
    when 'passe' then   -- paliers de la saison en cours seulement
      if not interne.saison_valide(split_part(cle, '|', 1)) or montant > 40 then raise exception 'montant_invalide'; end if;
      k := cle;
    when 'depart' then  -- (8 octobre 2026) la fin du premier lancement guidé : un Sachet Premium, une fois par compte
      if montant <> 0 or sac is distinct from 'premium' then raise exception 'montant_invalide'; end if;
      k := 'depart';
    else raise exception 'source_inconnue';
  end case;
  begin
    insert into gains (joueur, source, cle, montant, sac) values (qui, source, k, montant, sac);
  exception when unique_violation then raise exception 'deja';
  end;
  perform interne.crediter(qui, montant, sac);
  return interne.etat(qui);
end $$;

-- Billes gagnées ailleurs que dans les sacs : bille du Château, billes du passe, billes secrètes
drop function if exists public.bille_gagnee(text, text, bigint);
create or replace function public.bille_gagnee(source text, cle text, graine bigint default null, bid uuid default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); b jsonb; m int; c int; t text; sh int;
        noms text[] := array['Givre','Carnaval','Printemps','Poisson d''avril','Papillons','Plein soleil','Grandes vacances',
                             'Étoiles filantes','Rentrée','Citrouille','Feuilles mortes','Flocon'];
        fams int[] := array[35,36,37,38,39,40,41,42,43,44,45,46];   -- un décor de saison par mois (édition limitée)
begin
  case source
    when 'chateau' then   -- Château rasé en un seul tir : un Mammouth, une fois par jour ; décor tiré comme dans un sachet, shiny comme le Collector
      -- seulement pendant la partie du jour : si elle est déjà enregistrée (depuis plus d'une minute), c'est une partie pour le plaisir (3 octobre 2026)
      if exists (select 1 from gains g where g.joueur = qui and g.source = 'jeu' and g.cle = interne.aujourdhui()::text || '|chateau'
                   and g.le < now() - interval '1 minute') then raise exception 'deja'; end if;
      begin insert into gains (joueur, source, cle) values (qui, 'bille-chateau', interne.aujourdhui()::text);
      exception when unique_violation then raise exception 'deja'; end;
      b := interne.nouvelle_bille(qui, 'mammouth', shiny => interne.tirer_shiny(interne.taux_shiny() * 10), src => 'chateau');
    when 'passe' then     -- cle : « 2026-9|free|10 »
      if not interne.saison_valide(split_part(cle, '|', 1)) then raise exception 'montant_invalide'; end if;
      select x.t, x.sh into t, sh from (values ('free|1','mini',0), ('free|10','bille',0), ('free|20','chinoise',0), ('free|30','calot',1),
        ('prem|5','boulet',0), ('prem|10','mammouth',0), ('prem|20','boulet',2), ('prem|30','mammouth',3)) x(k, t, sh)
        where x.k = split_part(cle,'|',2) || '|' || split_part(cle,'|',3);
      if t is null then raise exception 'montant_invalide'; end if;
      begin insert into gains (joueur, source, cle) values (qui, 'bille-passe', cle);
      exception when unique_violation then raise exception 'deja'; end;
      m := split_part(split_part(cle,'|',1), '-', 2)::int;
      b := interne.nouvelle_bille(qui, t, fams[m], interne.coloris_base() + m - 1, sh, graine => graine,
             extra => jsonb_build_object('ed', noms[m] || ' ' || split_part(split_part(cle,'|',1), '-', 1)), bid => bid, src => 'passe');
    when 'secrete' then   -- une seule de chaque par joueur
      select x.t, x.f, x.c, x.sh into t, m, c, sh from (values
        ('folle','calot',1,60,1), ('arcade','boulet',25,61,3), ('grenier','mammouth',8,62,2),
        ('gouter','calot',20,63,0), ('preau','boulet',16,64,0)) x(k, t, f, c, sh) where x.k = cle;
      if t is null then raise exception 'secrete_inconnue'; end if;
      -- une seule à la fois : si elle a été retirée (outil de test), on peut la retrouver
      if exists (select 1 from billes where proprietaire = qui and secrete = cle and detruite_le is null) then raise exception 'deja'; end if;
      b := interne.nouvelle_bille(qui, t, m, c, sh, cle, graine, bid => bid, src => 'secrete');
    when 'beta' then      -- cle : la taille ; une de chaque par joueur, seulement pendant la bêta
      if not interne.beta_ouverte() then raise exception 'beta_finie'; end if;
      if cle is null or not cle = any(interne.tailles()) then raise exception 'montant_invalide'; end if;
      perform 1 from portefeuilles where joueur = qui for update;
      if exists (select 1 from billes where proprietaire = qui and secrete = 'beta' and taille = cle and origine = 'serveur' and detruite_le is null)
        then raise exception 'deja'; end if;
      b := interne.nouvelle_bille(qui, cle, 47, 70 + interne.rang(cle), 0, 'beta', graine, jsonb_build_object('ed', 'Bêta 2026'), bid, 'beta');
    when 'depart' then    -- (8 octobre 2026) la bille de départ : un Calot, une seule par joueur, dans l'un des 3 coloris réservés (84 à 86, comme DEPART dans index.html).
      -- Rangée avec les secrètes (secrete = 'depart') : ni troc, ni marché, ni Confiserie, ni fusion, ni classement.
      select x.f, x.c into m, c from (values ('cartable', 0, 84), ('craie', 1, 85), ('pelouse', 3, 86)) x(k, f, c) where x.k = cle;
      if m is null then raise exception 'montant_invalide'; end if;
      perform 1 from portefeuilles where joueur = qui for update;
      if exists (select 1 from billes where proprietaire = qui and secrete = 'depart') then raise exception 'deja'; end if;
      b := interne.nouvelle_bille(qui, 'calot', m, c, 0, 'depart', graine, jsonb_build_object('ed', 'Bille de départ'), bid, 'depart');
    else raise exception 'source_inconnue';
  end case;
  return jsonb_build_object('eco', interne.etat(qui), 'bille', b);
end $$;

-- Jeux à plusieurs : la mise part tout de suite, le gain est plafonné (et limité à +2 000 par jour)
-- (plus utilisé par le jeu depuis octobre 2026 : Course et Tic passent par gagner('jeu'). Gardé pour les anciennes pages encore ouvertes.)
create or replace function public.miser(jeu text, montant int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); mid bigint;
begin
  raise exception 'mise_invalide';   -- 6 octobre 2026 : fermé (plus utilisé depuis début octobre, et les montants ont été divisés par 10)
  if jeu not in ('course','tic') or montant not in (10,25,50,100) then raise exception 'mise_invalide'; end if;
  perform interne.payer_libre(qui, montant);
  insert into mises (joueur, jeu, montant) values (qui, jeu, montant) returning mises.id into mid;
  return jsonb_build_object('eco', interne.etat(qui), 'mise', mid);
end $$;

create or replace function public.regler_mise(mise bigint, gain int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); m mises; net int;
begin
  select * into m from mises where id = mise and joueur = qui and reglee_le is null for update;
  if m.id is null then raise exception 'deja'; end if;
  gain := least(greatest(gain,0), m.montant * case m.jeu when 'course' then 4 else 2 end);
  select coalesce(sum(x.gain - x.montant), 0) into net from mises x
    where x.joueur = qui and x.reglee_le is not null and (x.reglee_le at time zone 'Europe/Paris')::date = interne.aujourdhui();
  gain := least(gain, greatest(m.montant, m.montant + 2000 - net));   -- on récupère toujours sa mise si on gagne
  update mises set gain = regler_mise.gain, reglee_le = now() where id = m.id;
  perform interne.crediter(qui, gain);
  return interne.etat(qui);
end $$;

-- Outils de test (seulement pour les comptes listés dans public.testeurs)
create or replace function public.outil_test(action text)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); b jsonb;
begin
  if not exists (select 1 from testeurs where joueur = qui) then raise exception 'reserve_aux_testeurs'; end if;
  case action
    when 'bonbecs' then perform interne.crediter(qui, 100);
    when 'gratuit' then update portefeuilles set gratuit_t0 = now() - interval '100 minutes' where joueur = qui;
    -- une shiny de test, dans n'importe quelle taille
    when 'shiny' then b := interne.nouvelle_bille(qui, (interne.tailles())[1 + floor(random()*6)::int], shiny => 1 + floor(random()*3)::int, src => 'test');
    else raise exception 'action_inconnue';
  end case;
  return jsonb_build_object('eco', interne.etat(qui), 'bille', b);
end $$;

-- droits : le site ne peut appeler que ces fonctions-là
do $$ declare f text; begin
  foreach f in array array['eco_demarrer(int,jsonb,int)','eco_etat()','ouvrir_sac(text,boolean,boolean)','echanger_billes(uuid[])',
    'fusionner(uuid[])','fusion_evenement(uuid[])','pachinko(boolean)','bonbec_du_jour()','gagner(text,text,int,text)','bille_gagnee(text,text,bigint,uuid)',
    'miser(text,int)','regler_mise(bigint,int)','outil_test(text)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
