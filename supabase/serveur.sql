-- =====================================================================
--  BILLY : le serveur décide (anti-triche)
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
  if new.coloris < 48 then   -- les billes de saison et secrètes n'ont pas d'édition
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
  bonbecs      int  not null default 1000 check (bonbecs >= 0),
  sacs         jsonb not null default '{}',                 -- sacs offerts en réserve : {"premium": 2, …}
  gratuit_t0   timestamptz not null default now() - interval '50 minutes',
  pity         int  not null default 0,                     -- sacs ouverts depuis le dernier Boulet ou Mammouth
  sacs_ouverts int  not null default 0,
  serie        int  not null default 0,                     -- bonbec du jour : jours de suite
  serie_jour   date,
  maj_le       timestamptz not null default now()
);
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
$$ select array[0,0,4,2,0,1,0,1,2,3,3,0,2,1,3,0,1,3,2,2,0,0,1,1,0,1,3,3,1,2,4,2, 5, 3,4, 5,5,5,5,5,5,5,5,5,5,5,5, 5] $$;   -- 32 : Pirate (événement, 5 = jamais dans les sacs) ; 33 Vitrail ; 34 Trou noir ; 35 à 46 : décors de saison (passe seulement) ; 47 : Bêta
create or replace function interne.poids_rarete() returns numeric[] language sql immutable as
$$ select array[10,5,2.5,0.8,0.2,0]::numeric[] $$;   -- la 6e : décors d'événement, jamais tirés

create or replace function interne.coloris_base() returns int language sql immutable as $$ select 48 $$;
-- La bêta : tant qu'elle dure, chaque joueur peut réclamer une bille Bêta de chaque taille (décor 47, coloris 70 + rang de la taille :
-- Rubis, Émeraude, Saphir, Améthyste, Onyx, Diamant ; BETA dans index.html).
-- Elles sont rangées avec les billes secrètes (secrete = 'beta') : ni troc, ni marché, ni recyclage, ni classement.
-- supabase/reset.sql les garde. Au lancement : remplacer true par false (et BETA.open:false dans index.html).
create or replace function interne.beta_ouverte() returns boolean language sql immutable as $$ select true $$;
create or replace function interne.taux_shiny() returns numeric language sql immutable as $$ select 0.0005::numeric $$;   -- 1 sur 2 000 (relevé le 2 octobre 2026 : 1 sur 10 000, c'était presque jamais)
create or replace function interne.revente() returns int[] language sql immutable as $$ select array[5,8,20,50,150,600] $$;
create or replace function interne.prime_shiny() returns int[] language sql immutable as $$ select array[2000,5000,15000] $$;
create or replace function interne.fusion_n() returns int[] language sql immutable as $$ select array[3,5,5,6,8] $$;

-- les sacs : prix, nombre de billes, taille garantie (rang), chances de shiny, et chances de chaque taille position par position
-- (une ligne par bille, dans l'ordre d'ouverture ; la dernière est la vedette). Mêmes valeurs que BAGS dans index.html.
drop function if exists interne.sac(text);
create or replace function interne.sac(nom text, out prix int, out n int, out garantie int, out shiny numeric, out cotes numeric[])
language sql immutable as $$
  select v.prix, v.n, v.garantie, v.shiny, v.cotes from (values
    ('gratuit',     0, 3, null::int, 0.0005, array[[75,25,0,0,0,0],[55,35,10,0,0,0],[30,33,20,12,4,1]]::numeric[]),
    ('classique', 300, 5, null,      0.0005, array[[70,30,0,0,0,0],[50,38,12,0,0,0],[35,40,20,5,0,0],[20,35,30,13,2,0],[10,25,30,20,12,3]]::numeric[]),
    ('premium',   600, 5, 3,         0.0010, array[[0,80,20,0,0,0],[0,60,35,5,0,0],[0,40,45,15,0,0],[0,0,55,38,7,0],[0,0,0,60,34,6]]::numeric[]),
    ('collector',1500, 5, 4,         0.0025, array[[0,0,85,15,0,0],[0,0,65,35,0,0],[0,0,40,50,10,0],[0,0,0,60,38,2],[0,0,0,0,87,13]]::numeric[]),
    ('pirate',    600, 3, null,      0.0010, array[[60,32,8,0,0,0],[40,35,18,6,1,0],[20,28,24,17,8,3]]::numeric[])
  ) v(nom, prix, n, garantie, shiny, cotes) where v.nom = sac.nom
$$;

-- Événements : leurs dates (heure de Paris), le décor et les coloris de leurs billes (mêmes valeurs que EVENTS dans index.html)
create or replace function interne.evenement(nom text, out debut timestamptz, out fin timestamptz, out sac text, out decor int, out coloris int[])
language sql immutable as $$
  select v.debut, v.fin, v.sac, v.decor, v.coloris from (values
    ('pirates', timestamptz '2026-09-30 00:00:00 Europe/Paris', timestamptz '2026-10-14 23:59:59 Europe/Paris', 'pirate', 32, array[65,66,67,68,69])
  ) v(nom, debut, fin, sac, decor, coloris) where v.nom = evenement.nom
$$;
create or replace function interne.evenement_du_sac(s text) returns text language sql immutable as $$
  select case s when 'pirate' then 'pirates' end
$$;

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
  shiny int default 0, secrete text default null, graine bigint default null, extra jsonb default '{}', bid uuid default null, src text default null)
returns jsonb language plpgsql volatile as $$
declare d int := coalesce(decor, interne.tirer_decor());
        c int := coalesce(coloris, floor(random()*interne.coloris_base())::int);
        s bigint := coalesce(graine, floor(random()*4294967296)::bigint);
        don jsonb; r record;
begin
  don := jsonb_build_object('seed', s, 'type', taille, 'family', d, 'pal', c, 'shiny', shiny,
           'at', floor(extract(epoch from now())*1000)::bigint) || extra;
  if secrete is not null then don := don || jsonb_build_object('secret', secrete); end if;
  if src is not null then don := don || jsonb_build_object('src', src); end if;
  insert into public.billes (id, proprietaire, seed, taille, decor, coloris, shiny, secrete, donnees, origine)
    values (coalesce(bid, gen_random_uuid()), qui, s, taille, d, c, shiny, secrete, don, 'serveur')
    returning id, numero, donnees into r;   -- donnees : avec l'édition ajoutée par la base
  return r.donnees || jsonb_build_object('id', r.id, 'no', r.numero, 'srv', true);
end $$;

-- l'état du portefeuille, envoyé au jeu après chaque action
create or replace function interne.etat(qui uuid) returns jsonb language sql stable as $$
  select jsonb_build_object('bonbecs', p.bonbecs, 'sacs', p.sacs,
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

-- =====================================================================
--  FONCTIONS APPELÉES PAR LE JEU
-- =====================================================================

-- Première connexion après la mise en place du serveur : on reprend les bonbecs et les sacs offerts
-- de la partie (plafonnés), ensuite c'est le serveur qui compte.
create or replace function public.eco_demarrer(bonbecs int default 1000, sacs jsonb default '{}', pity int default 0)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := auth.uid(); s jsonb := '{}'; k text;
begin
  if qui is null then raise exception 'connexion_requise'; end if;
  if not exists (select 1 from portefeuilles where joueur = qui) then
    foreach k in array array['classique','premium','collector'] loop
      if coalesce((sacs->>k)::int,0) > 0 then s := s || jsonb_build_object(k, least((sacs->>k)::int, 5)); end if;
    end loop;
    insert into portefeuilles (joueur, bonbecs, sacs, pity)
      values (qui, least(greatest(coalesce(bonbecs,1000),0), 10000), s, least(greatest(coalesce(pity,0),0), 9))
      on conflict (joueur) do nothing;
  end if;
  return interne.etat(qui);
end $$;

create or replace function public.eco_etat() returns jsonb language plpgsql security definer set search_path = public as $$
begin return interne.etat(interne.moi()); end $$;

-- Ouvrir un sac (acheté, gratuit ou offert). Renvoie les billes tirées.
create or replace function public.ouvrir_sac(nom text, offert boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); p portefeuilles; r record; ev record; evb boolean; stock int; t int; i int;
        tirees int[] := '{}'; shinies int[] := '{}'; billes jsonb := '[]'; force boolean := false;
begin
  select * into r from interne.sac(nom);
  if r.n is null then raise exception 'sac_inconnu'; end if;
  -- un sac d'événement : on ne l'achète que pendant l'événement (un sac offert s'ouvre quand on veut)
  select * into ev from interne.evenement(coalesce(interne.evenement_du_sac(nom), ''));   -- aucune ligne : tout à null
  if ev.sac is not null and not offert and not (now() between ev.debut and ev.fin) then raise exception 'evenement_fini'; end if;
  select * into p from portefeuilles where joueur = qui for update;
  if offert then
    if coalesce((p.sacs->>nom)::int,0) < 1 then raise exception 'plus_de_sac'; end if;
    update portefeuilles set sacs = jsonb_set(sacs, array[nom], to_jsonb((sacs->>nom)::int - 1)) where joueur = qui;
  elsif r.prix = 0 then
    stock := least(10, floor(extract(epoch from now() - p.gratuit_t0) / 600)::int);   -- jusqu'à 10 d'avance (FREE_MAX)
    if stock < 1 then raise exception 'pas_encore'; end if;
    update portefeuilles set gratuit_t0 = case when stock >= 10 then now() - interval '90 minutes' else gratuit_t0 + interval '10 minutes' end
      where joueur = qui;
  else
    if p.bonbecs < r.prix then raise exception 'pas_assez'; end if;
    update portefeuilles set bonbecs = bonbecs - r.prix where joueur = qui;
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
    -- sac d'événement : chaque bille a une chance d'être du décor de l'événement (12 %, 30 % pour la dernière,
    -- garantie pour la dernière d'un sac offert), sinon c'est une bille normale
    evb := ev.decor is not null and (case when i = r.n and offert then true else random() < case when i = r.n then 0.3 else 0.12 end end);
    billes := billes || interne.nouvelle_bille(qui, (interne.tailles())[tirees[i]+1], shiny => shinies[i], src => nom,
      decor => case when evb then ev.decor end,
      coloris => case when evb then ev.coloris[1 + floor(random()*array_length(ev.coloris,1))::int] end);
  end loop;
  return jsonb_build_object('eco', interne.etat(qui), 'billes', billes, 'force', force);
end $$;

-- La Confiserie : échange des billes contre des bonbecs. Seules les billes tirées par le serveur rapportent.
create or replace function public.echanger_billes(ids uuid[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); total int := 0; n int := 0; b record;
begin
  perform 1 from portefeuilles where joueur = qui for update;
  for b in select * from billes where id = any(ids) and proprietaire = qui and detruite_le is null and secrete is null for update loop
    if b.origine = 'serveur' then
      total := total + case when b.shiny > 0 and b.coloris < interne.coloris_base()
        then (interne.revente())[interne.rang(b.taille)+1] * 10 + (interne.prime_shiny())[b.shiny]
        else (interne.revente())[interne.rang(b.taille)+1] end;
    end if;
    update billes set detruite_le = now(), detruite_raison = 'recyclee' where id = b.id;
    insert into billes_historique (bille, de, vers, motif) values (b.id, qui, null, 'detruite');
    n := n + 1;
  end loop;
  perform interne.crediter(qui, total);
  return jsonb_build_object('eco', interne.etat(qui), 'total', total, 'n', n);
end $$;

-- La fusion : N billes d'une même taille contre une de la taille au-dessus
create or replace function public.fusionner(ids uuid[])
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); tailles text[]; rg int; nb int; b record;
begin
  select array_agg(distinct taille), count(*) into tailles, nb from billes
    where id = any(ids) and proprietaire = qui and detruite_le is null and secrete is null
      and shiny = 0 and coloris < interne.coloris_base() and origine = 'serveur';
  if tailles is null or array_length(tailles,1) <> 1 then raise exception 'fusion_invalide'; end if;
  rg := interne.rang(tailles[1]);
  if rg >= 5 or nb <> (interne.fusion_n())[rg+1] or nb <> array_length(ids,1) then raise exception 'fusion_invalide'; end if;
  for b in select id from billes where id = any(ids) for update loop
    update billes set detruite_le = now(), detruite_raison = 'fusionnee' where id = b.id;
    insert into billes_historique (bille, de, vers, motif) values (b.id, qui, null, 'detruite');
  end loop;
  return jsonb_build_object('eco', interne.etat(qui),
    'bille', interne.nouvelle_bille(qui, (interne.tailles())[rg+2], shiny => interne.tirer_shiny(interne.taux_shiny() * nb), src => 'fusion'));
end $$;

-- Le bonbec du jour : calendrier de 4 semaines, calculé par le serveur
create or replace function public.bonbec_du_jour()
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); p portefeuilles; today date := interne.aujourdhui(); s int; i int;
        j int[] := array[60,80,100,0,120,150,0, 100,120,150,0,180,200,0, 120,150,180,0,200,250,0, 150,180,200,0,250,300,0];
        sac text[] := array[null,null,null,'classique',null,null,'classique', null,null,null,'classique',null,null,'premium',
                            null,null,null,'classique',null,null,'premium', null,null,null,'premium',null,null,'collector'];
begin
  select * into p from portefeuilles where joueur = qui for update;
  if p.serie_jour = today then raise exception 'deja'; end if;
  s := case when p.serie_jour = today - 1 then p.serie + 1 else 1 end;
  i := case when s <= 28 then s else 22 + (s - 29) % 7 end;   -- après 28 jours, la 4e semaine recommence
  update portefeuilles set serie = s, serie_jour = today where joueur = qui;
  perform interne.crediter(qui, j[i], sac[i]);
  return jsonb_build_object('eco', interne.etat(qui), 'j', j[i], 'sac', sac[i], 'jour', i, 'serie', s);
end $$;

-- Tous les autres gains : chacun ne paie qu'une fois, et jamais plus que ce que le jeu peut donner
create or replace function public.gagner(source text, cle text, montant int, sac text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); today text := interne.aujourdhui()::text; k text; maxi int; nq int; ev record;
        quetes jsonb := '{"open_bag":80,"open_free":100,"hole":90,"par":70,"twoshots":90,"find_bille":90,"find_calot":120,
                          "new_slot":100,"new_color":100,"open_paid":120,"craft":120,"shake":60,"recycle":60}';
begin
  if montant < 0 then raise exception 'montant_invalide'; end if;
  if sac is not null and sac not in ('classique','premium','collector','pirate') then raise exception 'sac_inconnu'; end if;
  perform 1 from portefeuilles where joueur = qui for update;
  case source
    when 'quete' then   -- 3 quêtes par jour, au tarif de la quête
      if not quetes ? cle or montant <> (quetes->>cle)::int or sac is not null then raise exception 'montant_invalide'; end if;
      select count(*) into nq from gains g where g.joueur = qui and g.source = 'quete' and g.cle like today || '|%';
      if nq >= 3 then raise exception 'deja'; end if;
      k := today || '|' || cle;
    when 'quetes-bonus' then   -- les 3 quêtes : un Sac Classique offert
      if montant <> 0 or sac is distinct from 'classique' then raise exception 'montant_invalide'; end if;
      k := today;
    when 'jeu' then     -- une récompense par jour et par jeu (au Tir : par trou)
      maxi := case when cle ~ '^tir\|[0-5]$' then 100 when cle = 'pot' then 200 when cle = 'chateau' then 240 when cle = 'casse' then 200
                   when cle in ('course','tic') then 200 end;   -- une partie par jour et par jeu (DAY_GAMES dans index.html)
      if maxi is null or montant > maxi or sac is not null then raise exception 'montant_invalide'; end if;
      k := today || '|' || cle;
    when 'jeux-bonus' then   -- les 6 jeux du jour joués (le Tir et les 5 autres) : un Sac Premium
      if montant <> 0 or sac is distinct from 'premium' then raise exception 'montant_invalide'; end if;
      if (select count(*) from gains g where g.joueur = qui and g.source = 'jeu'
            and g.cle in (today||'|tir|0', today||'|pot', today||'|chateau', today||'|casse', today||'|course', today||'|tic')) < 6
        then raise exception 'pas_encore'; end if;
      k := today;
    when 'succes' then
      if montant > 10000 then raise exception 'montant_invalide'; end if;
      k := cle;
    when 'serie' then
      if montant > 6000 then raise exception 'montant_invalide'; end if;
      k := cle;
    when 'evenement' then   -- le sac offert à chacun, une fois, pendant l'événement
      select * into ev from interne.evenement(cle);
      if ev.sac is null or montant <> 0 or sac is distinct from ev.sac or not (now() between ev.debut and ev.fin) then raise exception 'montant_invalide'; end if;
      k := cle;
    when 'passe' then   -- paliers de la saison en cours seulement
      if not interne.saison_valide(split_part(cle, '|', 1)) or montant > 400 then raise exception 'montant_invalide'; end if;
      k := cle;
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
    when 'chateau' then   -- 3 étoiles au Château : une Bille, une fois par jour
      begin insert into gains (joueur, source, cle) values (qui, 'bille-chateau', interne.aujourdhui()::text);
      exception when unique_violation then raise exception 'deja'; end;
      b := interne.nouvelle_bille(qui, 'bille', src => 'chateau');
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
  if jeu not in ('course','tic') or montant not in (10,25,50,100) then raise exception 'mise_invalide'; end if;
  update portefeuilles set bonbecs = bonbecs - montant where joueur = qui and bonbecs >= montant;
  if not found then raise exception 'pas_assez'; end if;
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
    when 'bonbecs' then perform interne.crediter(qui, 1000);
    when 'gratuit' then update portefeuilles set gratuit_t0 = now() - interval '100 minutes' where joueur = qui;
    when 'shiny' then b := interne.nouvelle_bille(qui, (interne.tailles())[3 + floor(random()*4)::int], shiny => 1 + floor(random()*3)::int, src => 'test');
    else raise exception 'action_inconnue';
  end case;
  return jsonb_build_object('eco', interne.etat(qui), 'bille', b);
end $$;

-- droits : le site ne peut appeler que ces fonctions-là
do $$ declare f text; begin
  foreach f in array array['eco_demarrer(int,jsonb,int)','eco_etat()','ouvrir_sac(text,boolean)','echanger_billes(uuid[])',
    'fusionner(uuid[])','bonbec_du_jour()','gagner(text,text,int,text)','bille_gagnee(text,text,bigint,uuid)',
    'miser(text,int)','regler_mise(bigint,int)','outil_test(text)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
