-- =====================================================================
--  BILLY : la cour de récré (copains, troc, marché)
--  À coller dans Supabase > SQL Editor > New query > Run, APRÈS schema.sql et serveur.sql.
--  Le script peut être relancé sans danger.
--
--  Tout passe par des fonctions du serveur : le téléphone ne peut ni lire les billes des autres
--  directement, ni changer le propriétaire d'une bille, ni toucher aux bonbecs de quelqu'un.
--  Seules les billes tirées par le serveur (origine = 'serveur'), non secrètes, peuvent circuler.
-- =====================================================================

-- ---------- Copains ----------
create table if not exists public.amis (
  joueur uuid not null references auth.users(id) on delete cascade,
  ami    uuid not null references auth.users(id) on delete cascade,
  depuis timestamptz not null default now(),
  primary key (joueur, ami)
);
create table if not exists public.demandes_amis (
  de   uuid not null references auth.users(id) on delete cascade,
  vers uuid not null references auth.users(id) on delete cascade,
  le   timestamptz not null default now(),
  primary key (de, vers)
);

-- ---------- Troc : des billes contre des billes, entre copains ----------
create table if not exists public.trocs (
  id        bigint generated always as identity primary key,
  de        uuid not null references auth.users(id) on delete cascade,
  vers      uuid not null references auth.users(id) on delete cascade,
  donne     uuid[] not null default '{}',     -- billes proposées par « de »
  demande   uuid[] not null default '{}',     -- billes demandées à « vers »
  mot       text check (char_length(mot) <= 140),
  statut    text not null default 'attente',  -- attente, accepte, refuse, annule, impossible, contre
  le        timestamptz not null default now(),
  fini_le   timestamptz
);
-- des bonbecs en plus des billes, d'un seul côté (au plus TROC_BONBECS_MAX = 5000 ; même valeur dans index.html)
alter table public.trocs add column if not exists donne_bonbecs   int not null default 0 check (donne_bonbecs between 0 and 5000);
alter table public.trocs add column if not exists demande_bonbecs int not null default 0 check (demande_bonbecs between 0 and 5000);
create index if not exists trocs_vers on public.trocs (vers) where statut = 'attente';
create index if not exists trocs_de on public.trocs (de) where statut = 'attente';

-- ---------- Marché : une bille contre des bonbecs, sans commission ----------
create table if not exists public.annonces (
  id         bigint generated always as identity primary key,
  vendeur    uuid not null references auth.users(id) on delete cascade,
  bille      uuid not null references public.billes(id) on delete cascade,
  prix       int  not null check (prix between 1 and 1000000),
  le         timestamptz not null default now(),
  vendue_le  timestamptz,
  acheteur   uuid references auth.users(id),
  retiree_le timestamptz
);
create unique index if not exists annonces_une_par_bille on public.annonces (bille) where vendue_le is null and retiree_le is null;
-- une annonce dure 1, 3 ou 7 jours (au choix du vendeur) ; ensuite elle se retire toute seule
alter table public.annonces add column if not exists expire_le timestamptz;
update public.annonces set expire_le = le + interval '3 days' where expire_le is null;
alter table public.annonces alter column expire_le set default now() + interval '3 days';
alter table public.annonces alter column expire_le set not null;
create index if not exists annonces_actives on public.annonces (le desc) where vendue_le is null and retiree_le is null;

alter table public.amis          enable row level security;
alter table public.demandes_amis enable row level security;
alter table public.trocs         enable row level security;
alter table public.annonces      enable row level security;
revoke all on public.amis, public.demandes_amis, public.trocs, public.annonces from anon, authenticated;

-- =====================================================================
--  OUTILS INTERNES
-- =====================================================================
create or replace function interne.sont_amis(a uuid, b uuid) returns boolean language sql stable as
$$ select exists (select 1 from public.amis where joueur = a and ami = b) $$;

-- une bille telle que le jeu la connaît
create or replace function interne.bille_json(b public.billes) returns jsonb language sql stable as
$$ select b.donnees || jsonb_build_object('id', b.id, 'no', b.numero, 'srv', b.origine = 'serveur') $$;

-- les annonces arrivées à leur fin sont retirées (appelé avant de lire ou de modifier le marché)
create or replace function interne.expirer_annonces() returns void language sql as $$
  update public.annonces set retiree_le = expire_le where vendue_le is null and retiree_le is null and expire_le <= now()
$$;

-- une bille qui peut circuler : à ce joueur, pas détruite, tirée par le serveur, pas secrète, pas en vente
create or replace function interne.bille_libre(bid uuid, qui uuid) returns boolean language sql stable as $$
  select exists (select 1 from public.billes b where b.id = bid and b.proprietaire = qui and b.detruite_le is null
                   and b.origine = 'serveur' and b.secrete is null)
     and not exists (select 1 from public.annonces a where a.bille = bid and a.vendue_le is null and a.retiree_le is null and a.expire_le > now())
$$;

create or replace function interne.pseudo(qui uuid) returns text language sql stable as
$$ select pseudo from public.profils where id = qui $$;

-- ce que le joueur montre aux copains (lu dans sa sauvegarde) : titre et bille active
create or replace function interne.carte(qui uuid) returns jsonb language sql stable as $$
  select jsonb_build_object('id', qui, 'pseudo', interne.pseudo(qui),
    'titre', s.donnees->>'title',
    'active', (select interne.bille_json(b) from public.billes b where b.id::text = s.donnees->>'active' and b.proprietaire = qui and b.detruite_le is null))
  from (select qui) x left join public.sauvegardes s on s.joueur = qui
$$;

-- =====================================================================
--  COPAINS
-- =====================================================================
create or replace function public.cour_moi() returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := auth.uid();
begin
  if qui is null then raise exception 'connexion_requise'; end if;
  return jsonb_build_object(
    'amis', coalesce((select jsonb_agg(interne.carte(a.ami) order by lower(interne.pseudo(a.ami))) from amis a where a.joueur = qui), '[]'),
    'recues', coalesce((select jsonb_agg(jsonb_build_object('id', d.de, 'pseudo', interne.pseudo(d.de), 'le', d.le) order by d.le desc) from demandes_amis d where d.vers = qui), '[]'),
    'envoyees', coalesce((select jsonb_agg(jsonb_build_object('id', d.vers, 'pseudo', interne.pseudo(d.vers), 'le', d.le) order by d.le desc) from demandes_amis d where d.de = qui), '[]'),
    'trocs', (select count(*) from trocs t where t.vers = qui and t.statut = 'attente'),
    'ventes', coalesce((select jsonb_agg(jsonb_build_object('prix', an.prix, 'le', an.vendue_le, 'acheteur', interne.pseudo(an.acheteur),
                 'bille', (select interne.bille_json(b) from billes b where b.id = an.bille)) order by an.vendue_le desc)
               from annonces an where an.vendeur = qui and an.vendue_le > now() - interval '7 days'), '[]')
  );
end $$;

create or replace function public.ami_demander(pseudo text) returns text language plpgsql security definer set search_path = public as $$
declare qui uuid := auth.uid(); cible uuid;
begin
  if qui is null then raise exception 'connexion_requise'; end if;
  select id into cible from profils p where lower(p.pseudo) = lower(trim(ami_demander.pseudo));
  if cible is null then raise exception 'inconnu'; end if;
  if cible = qui then raise exception 'soi_meme'; end if;
  if interne.sont_amis(qui, cible) then raise exception 'deja_ami'; end if;
  if (select count(*) from amis where joueur = qui) >= 200 then raise exception 'trop_amis'; end if;
  -- il m'avait déjà demandé : on devient copains tout de suite
  if exists (select 1 from demandes_amis where de = cible and vers = qui) then
    delete from demandes_amis where (de = cible and vers = qui) or (de = qui and vers = cible);
    insert into amis (joueur, ami) values (qui, cible), (cible, qui) on conflict do nothing;
    return 'ami';
  end if;
  if (select count(*) from demandes_amis where de = qui) >= 50 then raise exception 'trop_demandes'; end if;
  insert into demandes_amis (de, vers) values (qui, cible) on conflict do nothing;
  return 'demande';
end $$;

create or replace function public.ami_repondre(de uuid, oui boolean) returns void language plpgsql security definer set search_path = public as $$
declare qui uuid := auth.uid();
begin
  delete from demandes_amis d where d.de = ami_repondre.de and d.vers = qui;
  if not found then raise exception 'plus_de_demande'; end if;
  if oui then insert into amis (joueur, ami) values (qui, ami_repondre.de), (ami_repondre.de, qui) on conflict do nothing; end if;
end $$;

-- retirer un copain (ou annuler une demande envoyée) : les trocs en attente entre vous sont annulés
create or replace function public.ami_retirer(ami uuid) returns void language plpgsql security definer set search_path = public as $$
declare qui uuid := auth.uid();
begin
  delete from amis a where (a.joueur = qui and a.ami = ami_retirer.ami) or (a.joueur = ami_retirer.ami and a.ami = qui);
  delete from demandes_amis d where d.de = qui and d.vers = ami_retirer.ami;
  update trocs t set statut = 'annule', fini_le = now() where t.statut = 'attente'
    and ((t.de = qui and t.vers = ami_retirer.ami) or (t.de = ami_retirer.ami and t.vers = qui));
end $$;

-- le profil d'un copain : sa vitrine, sa bille active, ses chiffres et ses dernières belles trouvailles
create or replace function public.profil_joueur(qui uuid) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid(); vit jsonb;
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  if qui <> moi and not interne.sont_amis(moi, qui) then raise exception 'pas_ami'; end if;
  select s.donnees->'vitrine' into vit from sauvegardes s where s.joueur = qui;
  return interne.carte(qui) || jsonb_build_object(
    'vitrine', coalesce((select jsonb_agg(interne.bille_json(b)) from billes b
                 where b.proprietaire = qui and b.detruite_le is null
                   and b.id::text in (select jsonb_array_elements_text(coalesce(vit, '[]')) )), '[]'),
    'billes', (select count(*) from billes b where b.proprietaire = qui and b.detruite_le is null),
    'cases', (select count(distinct (b.taille, b.decor)) from billes b where b.proprietaire = qui and b.detruite_le is null),
    'shiny', (select count(*) from billes b where b.proprietaire = qui and b.detruite_le is null and b.shiny > 0),
    'trouvailles', coalesce((select jsonb_agg(x.j) from (select interne.bille_json(b) j from billes b
                 where b.proprietaire = qui and b.detruite_le is null and (interne.rang(b.taille) >= 4 or b.shiny > 0)
                 order by b.obtenue_le desc limit 8) x), '[]')
  );
end $$;

-- les billes qu'un copain (ou soi-même) peut mettre dans un troc
create or replace function public.billes_echangeables(qui uuid) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  if qui <> moi and not interne.sont_amis(moi, qui) then raise exception 'pas_ami'; end if;
  return coalesce((select jsonb_agg(x.j) from (
    select interne.bille_json(b) j from billes b
    where b.proprietaire = qui and b.detruite_le is null and b.origine = 'serveur' and b.secrete is null
      and not exists (select 1 from annonces a where a.bille = b.id and a.vendue_le is null and a.retiree_le is null and a.expire_le > now())
    order by interne.rang(b.taille) desc, b.shiny desc, b.numero desc limit 500) x), '[]');
end $$;

-- les belles trouvailles des copains (Boulets, Mammouths, shiny), tirées depuis moins d'un mois
create or replace function public.fil_amis() returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  return coalesce((select jsonb_agg(x.j) from (
    select jsonb_build_object('who', interne.pseudo(h.vers), 'at', floor(extract(epoch from h.le)*1000)::bigint, 's', interne.bille_json(b)) j
    from billes_historique h join billes b on b.id = h.bille
    where h.motif = 'trouvee' and h.vers in (select ami from amis where joueur = moi)
      and h.le > now() - interval '30 days' and (interne.rang(b.taille) >= 4 or b.shiny > 0)
    order by h.le desc limit 20) x), '[]');
end $$;

-- =====================================================================
--  TROC
-- =====================================================================
-- « remplace » : une contre-proposition à un troc reçu de ce copain ; l'ancien troc est clos (statut « contre »)
-- « donne_bonbecs » / « demande_bonbecs » : des bonbecs ajoutés d'un côté du troc (payés seulement quand le troc est accepté)
drop function if exists public.troc_proposer(uuid, uuid[], uuid[], text);
drop function if exists public.troc_proposer(uuid, uuid[], uuid[], text, bigint);
create or replace function public.troc_proposer(vers uuid, donne uuid[], demande uuid[], mot text default null, remplace bigint default null,
  donne_bonbecs int default 0, demande_bonbecs int default 0)
returns bigint language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); b uuid; tid bigint;
begin
  donne_bonbecs := coalesce(donne_bonbecs, 0); demande_bonbecs := coalesce(demande_bonbecs, 0);
  if donne_bonbecs not between 0 and 5000 or demande_bonbecs not between 0 and 5000 or (donne_bonbecs > 0 and demande_bonbecs > 0) then raise exception 'troc_invalide'; end if;
  if donne_bonbecs > 0 and not exists (select 1 from portefeuilles p where p.joueur = moi and p.bonbecs >= donne_bonbecs) then raise exception 'pas_assez'; end if;
  if remplace is not null then
    update trocs t set statut = 'contre', fini_le = now() where t.id = remplace and t.vers = moi and t.de = troc_proposer.vers and t.statut = 'attente';
    if not found then raise exception 'plus_de_troc'; end if;
  end if;
  if not interne.sont_amis(moi, vers) then raise exception 'pas_ami'; end if;
  donne := coalesce(donne, '{}'); demande := coalesce(demande, '{}');
  if cardinality(donne) + cardinality(demande) = 0 or cardinality(donne) > 6 or cardinality(demande) > 6 then raise exception 'troc_invalide'; end if;
  if (select count(*) from (select distinct unnest(donne || demande)) x) <> cardinality(donne) + cardinality(demande) then raise exception 'troc_invalide'; end if;
  foreach b in array donne loop if not interne.bille_libre(b, moi) then raise exception 'bille_indisponible'; end if; end loop;
  foreach b in array demande loop if not interne.bille_libre(b, vers) then raise exception 'bille_indisponible'; end if; end loop;
  if (select count(*) from trocs t where t.de = moi and t.statut = 'attente') >= 20 then raise exception 'trop_trocs'; end if;
  insert into trocs (de, vers, donne, demande, mot, donne_bonbecs, demande_bonbecs)
    values (moi, troc_proposer.vers, donne, demande, nullif(trim(mot), ''), troc_proposer.donne_bonbecs, troc_proposer.demande_bonbecs)
    returning id into tid;
  return tid;
end $$;

create or replace function public.troc_repondre(troc bigint, oui boolean) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); t trocs; b uuid;
begin
  select * into t from trocs where id = troc and vers = moi and statut = 'attente' for update;
  if t.id is null then raise exception 'plus_de_troc'; end if;
  if not oui then
    update trocs set statut = 'refuse', fini_le = now() where id = t.id;
    return jsonb_build_object('statut', 'refuse');
  end if;
  -- tout doit être encore là (une bille a pu être vendue, échangée ou fusionnée entre-temps)
  if not interne.sont_amis(t.de, t.vers)
     or exists (select 1 from unnest(t.donne) x where not interne.bille_libre(x, t.de))
     or exists (select 1 from unnest(t.demande) x where not interne.bille_libre(x, t.vers)) then
    update trocs set statut = 'impossible', fini_le = now() where id = t.id;
    return jsonb_build_object('statut', 'impossible');
  end if;
  -- les bonbecs : celui qui les propose doit toujours les avoir, sinon le troc tombe ; celui qui accepte doit avoir ceux qu'on lui demande
  if t.donne_bonbecs > 0 or t.demande_bonbecs > 0 then
    perform 1 from portefeuilles where joueur in (t.de, t.vers) order by joueur for update;
    if not exists (select 1 from portefeuilles where joueur = t.vers and bonbecs >= t.demande_bonbecs) then raise exception 'pas_assez'; end if;
    if not exists (select 1 from portefeuilles where joueur = t.de and bonbecs >= t.donne_bonbecs) then
      update trocs set statut = 'impossible', fini_le = now() where id = t.id;
      return jsonb_build_object('statut', 'impossible');
    end if;
    update portefeuilles set bonbecs = bonbecs - t.donne_bonbecs + t.demande_bonbecs, maj_le = now() where joueur = t.de;
    update portefeuilles set bonbecs = bonbecs + t.donne_bonbecs - t.demande_bonbecs, maj_le = now() where joueur = t.vers;
  end if;
  perform 1 from billes where id = any(t.donne || t.demande) for update;
  foreach b in array t.donne loop perform public.transferer_bille(b, t.de, t.vers, 'echange'); end loop;
  foreach b in array t.demande loop perform public.transferer_bille(b, t.vers, t.de, 'echange'); end loop;
  update trocs set statut = 'accepte', fini_le = now() where id = t.id;
  -- les autres trocs qui comptaient sur ces billes ne sont plus possibles
  update trocs x set statut = 'impossible', fini_le = now() where x.statut = 'attente' and x.id <> t.id
    and (x.donne && (t.donne || t.demande) or x.demande && (t.donne || t.demande));
  return jsonb_build_object('statut', 'accepte', 'eco', interne.etat(moi));
end $$;

create or replace function public.troc_annuler(troc bigint) returns void language plpgsql security definer set search_path = public as $$
begin
  update trocs set statut = 'annule', fini_le = now() where id = troc and de = auth.uid() and statut = 'attente';
  if not found then raise exception 'plus_de_troc'; end if;
end $$;

create or replace function interne.troc_json(t public.trocs) returns jsonb language sql stable as $$
  select jsonb_build_object('id', t.id, 'de', t.de, 'vers', t.vers, 'de_pseudo', interne.pseudo(t.de), 'vers_pseudo', interne.pseudo(t.vers),
    'mot', t.mot, 'statut', t.statut, 'le', floor(extract(epoch from t.le)*1000)::bigint,
    'donne_bonbecs', t.donne_bonbecs, 'demande_bonbecs', t.demande_bonbecs,
    'donne', coalesce((select jsonb_agg(interne.bille_json(b)) from public.billes b where b.id = any(t.donne)), '[]'),
    'demande', coalesce((select jsonb_agg(interne.bille_json(b)) from public.billes b where b.id = any(t.demande)), '[]'))
$$;

create or replace function public.mes_trocs() returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  return jsonb_build_object(
    'recus', coalesce((select jsonb_agg(interne.troc_json(t) order by t.le desc) from trocs t where t.vers = moi and t.statut = 'attente'), '[]'),
    'envoyes', coalesce((select jsonb_agg(interne.troc_json(t) order by t.le desc) from trocs t where t.de = moi and t.statut = 'attente'), '[]'),
    'finis', coalesce((select jsonb_agg(x.j) from (select interne.troc_json(t) j from trocs t
                where (t.de = moi or t.vers = moi) and t.statut <> 'attente' order by t.fini_le desc limit 10) x), '[]'));
end $$;

-- =====================================================================
--  MARCHÉ
-- =====================================================================
drop function if exists public.vendre(uuid, int);
create or replace function public.vendre(bille uuid, prix int, jours int default 3) returns bigint language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); aid bigint;
begin
  perform interne.expirer_annonces();
  if prix < 1 or prix > 1000000 then raise exception 'prix_invalide'; end if;
  if jours not in (1, 3, 7) then raise exception 'duree_invalide'; end if;
  if not interne.bille_libre(bille, moi) then raise exception 'bille_indisponible'; end if;
  if (select count(*) from annonces a where a.vendeur = moi and a.vendue_le is null and a.retiree_le is null) >= 30 then raise exception 'trop_annonces'; end if;
  insert into annonces (vendeur, bille, prix, expire_le) values (moi, vendre.bille, vendre.prix, now() + make_interval(days => jours)) returning id into aid;
  return aid;
end $$;

create or replace function public.retirer_annonce(annonce bigint) returns void language plpgsql security definer set search_path = public as $$
begin
  update annonces set retiree_le = now() where id = annonce and vendeur = auth.uid() and vendue_le is null and retiree_le is null;
  if not found then raise exception 'plus_en_vente'; end if;
end $$;

create or replace function public.acheter(annonce bigint) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); a annonces; b billes;
begin
  select * into a from annonces where id = annonce and vendue_le is null and retiree_le is null and expire_le > now() for update;
  if a.id is null then raise exception 'plus_en_vente'; end if;
  if a.vendeur = moi then raise exception 'ta_bille'; end if;
  -- on verrouille les deux portefeuilles dans le même ordre pour ne jamais se bloquer
  perform 1 from portefeuilles where joueur in (moi, a.vendeur) order by joueur for update;
  update portefeuilles set bonbecs = bonbecs - a.prix, maj_le = now() where joueur = moi and bonbecs >= a.prix;
  if not found then raise exception 'pas_assez'; end if;
  update portefeuilles set bonbecs = bonbecs + a.prix, maj_le = now() where joueur = a.vendeur;
  perform public.transferer_bille(a.bille, a.vendeur, moi, 'vente');
  update annonces set vendue_le = now(), acheteur = moi where id = a.id;
  update trocs x set statut = 'impossible', fini_le = now() where x.statut = 'attente' and (a.bille = any(x.donne) or a.bille = any(x.demande));
  select * into b from billes where id = a.bille;
  return jsonb_build_object('eco', interne.etat(moi), 'bille', interne.bille_json(b));
end $$;

-- les annonces, avec des filtres ; pour chaque bille, le prix moyen payé pour ce modèle ces 30 derniers jours
create or replace function public.marche(taille text default null, decor int default null, coloris int default null,
  shiny boolean default null, tri text default 'recent', page int default 0)
returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  perform interne.expirer_annonces();
  return coalesce((select jsonb_agg(x.j) from (
    select jsonb_build_object('id', a.id, 'prix', a.prix, 'le', floor(extract(epoch from a.le)*1000)::bigint,
      'fin', floor(extract(epoch from a.expire_le)*1000)::bigint,
      'vendeur', interne.pseudo(a.vendeur), 'moi', a.vendeur = moi, 'bille', interne.bille_json(b),
      'moyen', (select round(avg(a2.prix))::int from annonces a2 join billes b2 on b2.id = a2.bille
                where a2.vendue_le > now() - interval '30 days' and b2.taille = b.taille and b2.decor = b.decor
                  and b2.coloris = b.coloris and (b2.shiny > 0) = (b.shiny > 0))) j
    from annonces a join billes b on b.id = a.bille
    where a.vendue_le is null and a.retiree_le is null
      and (marche.taille is null or b.taille = marche.taille)
      and (marche.decor is null or b.decor = marche.decor)
      and (marche.coloris is null or b.coloris = marche.coloris)
      and (marche.shiny is null or (b.shiny > 0) = marche.shiny)
    order by case when tri = 'prix' then a.prix end asc, case when tri = 'rare' then interne.rang(b.taille) end desc,
             case when tri = 'rare' then b.shiny end desc, a.le desc
    limit 60 offset greatest(page,0) * 60) x), '[]');
end $$;

create or replace function public.mes_annonces() returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  perform interne.expirer_annonces();
  return coalesce((select jsonb_agg(x.j) from (
    select jsonb_build_object('id', a.id, 'prix', a.prix, 'le', floor(extract(epoch from a.le)*1000)::bigint,
      'fin', floor(extract(epoch from a.expire_le)*1000)::bigint,
      'vendue', a.vendue_le is not null, 'acheteur', interne.pseudo(a.acheteur), 'bille', interne.bille_json(b)) j
    from annonces a join billes b on b.id = a.bille
    where a.vendeur = moi and a.retiree_le is null and (a.vendue_le is null or a.vendue_le > now() - interval '7 days')
    order by a.vendue_le is not null, a.le desc) x), '[]');
end $$;

-- une bille en vente qui part à la Confiserie ou en fusion : son annonce est retirée
create or replace function interne.retirer_si_detruite() returns trigger language plpgsql as $$
begin
  update public.annonces set retiree_le = now() where bille = new.id and vendue_le is null and retiree_le is null;
  return new;
end $$;
drop trigger if exists pas_en_vente on public.billes;
drop trigger if exists retirer_si_detruite on public.billes;
create trigger retirer_si_detruite after update of detruite_le on public.billes for each row
  when (new.detruite_le is not null and old.detruite_le is null) execute function interne.retirer_si_detruite();

-- =====================================================================
--  JOURNAL : l'historique du troc et du marché (et les nouvelles depuis la dernière visite)
--  depuis : en millisecondes, on ne renvoie que ce qui s'est passé après.
-- =====================================================================
create or replace function public.cour_journal(depuis bigint default 0, limite int default 80) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid(); apres timestamptz := to_timestamp(greatest(coalesce(depuis,0),0) / 1000.0);
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  perform interne.expirer_annonces();
  return coalesce((select jsonb_agg(e.j || jsonb_build_object('le', floor(extract(epoch from e.le)*1000)::bigint) order by e.le desc) from (
    select * from (
      -- trocs (reçus en attente, ou terminés)
      select coalesce(t.fini_le, t.le) le, jsonb_build_object('k', 'troc', 'id', t.id, 'statut', t.statut, 'moi_de', t.de = moi,
        'autre', interne.pseudo(case when t.de = moi then t.vers else t.de end), 'mot', t.mot,
        'bonbecs_recus', case when t.de = moi then t.demande_bonbecs else t.donne_bonbecs end,
        'bonbecs_donnes', case when t.de = moi then t.donne_bonbecs else t.demande_bonbecs end,
        'recu', coalesce((select jsonb_agg(interne.bille_json(b)) from billes b where b.id = any(case when t.de = moi then t.demande else t.donne end)), '[]'),
        'donne', coalesce((select jsonb_agg(interne.bille_json(b)) from billes b where b.id = any(case when t.de = moi then t.donne else t.demande end)), '[]')) j
      from trocs t where (t.de = moi or t.vers = moi) and (t.statut <> 'attente' or t.vers = moi)
      union all
      -- mes ventes : mise en vente, vendue, retirée ou arrivée au bout
      select a.le, jsonb_build_object('k', 'annonce', 'prix', a.prix, 'bille', interne.bille_json(b)) from annonces a join billes b on b.id = a.bille where a.vendeur = moi
      union all
      select a.vendue_le, jsonb_build_object('k', 'vendue', 'prix', a.prix, 'autre', interne.pseudo(a.acheteur), 'bille', interne.bille_json(b))
        from annonces a join billes b on b.id = a.bille where a.vendeur = moi and a.vendue_le is not null
      union all
      select a.retiree_le, jsonb_build_object('k', case when a.retiree_le = a.expire_le then 'expiree' else 'retiree' end, 'prix', a.prix, 'bille', interne.bille_json(b))
        from annonces a join billes b on b.id = a.bille where a.vendeur = moi and a.retiree_le is not null
      union all
      -- mes achats
      select a.vendue_le, jsonb_build_object('k', 'achat', 'prix', a.prix, 'autre', interne.pseudo(a.vendeur), 'bille', interne.bille_json(b))
        from annonces a join billes b on b.id = a.bille where a.acheteur = moi
    ) u where u.le > apres
    order by u.le desc limit least(greatest(coalesce(limite, 80), 1), 200)
  ) e), '[]');
end $$;

-- une seule fois : les billes déjà échangées ou vendues retrouvent leur provenance (voir transferer_bille dans schema.sql)
do $$ begin
  if not exists (select 1 from interne.migrations where nom = 'provenance-echanges') then
    update public.billes b set obtenue_le = h.le,
      donnees = b.donnees || jsonb_build_object('at', floor(extract(epoch from h.le)*1000)::bigint,
        'found', coalesce(b.donnees->'found', b.donnees->'at'), 'via', jsonb_build_object('k', h.motif, 'de', interne.pseudo(h.de)))
    from (select distinct on (bille) bille, de, motif, le from public.billes_historique where motif in ('echange', 'vente') order by bille, le desc) h
    where h.bille = b.id;
    insert into interne.migrations (nom) values ('provenance-echanges');
  end if;
end $$;

-- droits : le site ne peut appeler que ces fonctions-là
do $$ declare f text; begin
  foreach f in array array['cour_moi()','ami_demander(text)','ami_repondre(uuid,boolean)','ami_retirer(uuid)','profil_joueur(uuid)',
    'billes_echangeables(uuid)','fil_amis()','troc_proposer(uuid,uuid[],uuid[],text,bigint,int,int)','troc_repondre(bigint,boolean)','troc_annuler(bigint)',
    'mes_trocs()','vendre(uuid,int,int)','retirer_annonce(bigint)','acheter(bigint)','marche(text,int,int,boolean,text,int)','mes_annonces()','cour_journal(bigint,int)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
