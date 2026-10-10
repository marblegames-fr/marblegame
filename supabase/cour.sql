-- =====================================================================
--  TIKALO : la cour de récré (copains, troc, marché)
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
  statut    text not null default 'attente',  -- attente, accepte, refuse, annule, impossible, contre, expire (48 h sans réponse)
  le        timestamptz not null default now(),
  fini_le   timestamptz
);
-- des bonbecs en plus des billes, d'un seul côté : retiré le 6 octobre 2026 (troc_proposer refuse 'troc_bonbecs'), colonnes gardées pour l'historique
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
-- ---------- Enchères : une annonce « enchère » part au plus offrant quand le temps est écoulé ----------
-- prix = mise à prix (puis le prix final une fois vendue). Les bonbecs de la meilleure offre sont mis de côté
-- (retirés du portefeuille) ; celui qui se fait dépasser est remboursé tout de suite.
alter table public.annonces add column if not exists enchere      boolean not null default false;
alter table public.annonces add column if not exists offre        int;
alter table public.annonces add column if not exists encherisseur uuid references auth.users(id);
alter table public.annonces add column if not exists nb_offres    int not null default 0;
create table if not exists public.offres (
  id      bigint generated always as identity primary key,
  annonce bigint not null references public.annonces(id) on delete cascade,
  joueur  uuid not null references auth.users(id) on delete cascade,
  montant int  not null,
  le      timestamptz not null default now()
);
create index if not exists offres_annonce on public.offres (annonce, le);
create index if not exists offres_joueur on public.offres (joueur);

alter table public.amis          enable row level security;
alter table public.demandes_amis enable row level security;
alter table public.trocs         enable row level security;
alter table public.annonces      enable row level security;
alter table public.offres        enable row level security;
revoke all on public.amis, public.demandes_amis, public.trocs, public.annonces, public.offres from anon, authenticated;

-- =====================================================================
--  OUTILS INTERNES
-- =====================================================================
create or replace function interne.sont_amis(a uuid, b uuid) returns boolean language sql stable as
$$ select exists (select 1 from public.amis where joueur = a and ami = b) $$;

-- une bille telle que le jeu la connaît
create or replace function interne.bille_json(b public.billes) returns jsonb language sql stable as
$$ select b.donnees || jsonb_build_object('id', b.id, 'no', b.numero, 'srv', b.origine = 'serveur') $$;

-- les annonces arrivées à leur fin (appelé avant de lire ou de modifier le marché) :
-- une enchère avec une offre part au plus offrant ; tout le reste est retiré et la bille reste chez son propriétaire
create or replace function interne.expirer_annonces() returns void language plpgsql as $$
declare a record;
begin
  for a in select * from public.annonces where enchere and encherisseur is not null and vendue_le is null and retiree_le is null
             and expire_le <= now() order by id for update skip locked loop
    begin
      perform public.transferer_bille(a.bille, a.vendeur, a.encherisseur, 'vente');
      perform interne.crediter(a.vendeur, a.offre);
      update public.annonces set vendue_le = now(), acheteur = a.encherisseur, prix = a.offre where id = a.id;
      update public.trocs x set statut = 'impossible', fini_le = now() where x.statut = 'attente' and (a.bille = any(x.donne) or a.bille = any(x.demande));
    exception when others then   -- la bille n'est plus là (ne devrait pas arriver) : on rembourse et on retire
      perform interne.crediter(a.encherisseur, a.offre);
      update public.annonces set retiree_le = now() where id = a.id;
    end;
  end loop;
  update public.annonces set retiree_le = expire_le where vendue_le is null and retiree_le is null and expire_le <= now();
  perform interne.expirer_trocs();
end $$;
-- (7 octobre 2026) un troc sans réponse au bout de 48 h expire (TROC_HEURES dans index.html)
create or replace function interne.expirer_trocs() returns void language sql as $$
  update public.trocs set statut = 'expire', fini_le = le + interval '48 hours'
  where statut = 'attente' and le <= now() - interval '48 hours'
$$;
-- une annonce qui bloque sa bille : en cours, ou enchère terminée qui attend de partir chez le gagnant
create or replace function interne.en_vente(bid uuid) returns boolean language sql stable as $$
  select exists (select 1 from public.annonces a where a.bille = bid and a.vendue_le is null and a.retiree_le is null
                   and (a.expire_le > now() or a.encherisseur is not null))
$$;

-- une bille qui peut circuler : à ce joueur, pas détruite, tirée par le serveur, pas secrète, pas liée au compte (15 jours après l'inscription), pas en vente
create or replace function interne.bille_libre(bid uuid, qui uuid) returns boolean language sql stable as $$
  select exists (select 1 from public.billes b where b.id = bid and b.proprietaire = qui and b.detruite_le is null
                   and b.origine = 'serveur' and b.secrete is null and not interne.encore_liee(b.liee, b.proprietaire))
     and not interne.en_vente(bid)
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
  perform interne.expirer_trocs();
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

-- le profil d'un joueur (refait le 3 octobre 2026) : tout le monde peut le voir (depuis le classement par exemple) ; le troc reste entre copains.
-- Sa vitrine (dans son ordre), sa plus belle bille, l'avancement de son album, ses billes par taille, ses shiny par sorte,
-- ses collections d'événement et ses dernières belles trouvailles (avec leur date).
create or replace function public.profil_joueur(qui uuid) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid(); vit jsonb;
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  if not exists (select 1 from portefeuilles where joueur = qui) then raise exception 'inconnu'; end if;
  select s.donnees->'vitrine' into vit from sauvegardes s where s.joueur = qui;
  return interne.carte(qui) || jsonb_build_object(
    'ami', qui = moi or interne.sont_amis(moi, qui), 'moi', qui = moi,
    'depuis', (select floor(extract(epoch from p.cree_le)*1000)::bigint from profils p where p.id = qui),
    -- la vitrine, dans l'ordre choisi par le joueur
    'vitrine', coalesce((select jsonb_agg(interne.bille_json(b) order by v.pos) from jsonb_array_elements_text(coalesce(vit, '[]')) with ordinality v(id, pos)
                 join billes b on b.id::text = v.id and b.proprietaire = qui and b.detruite_le is null), '[]'),
    -- sa plus belle bille : la shiny la plus rare, puis la plus grosse, puis le décor le plus rare
    'top', (select interne.bille_json(b) from billes b where b.proprietaire = qui and b.detruite_le is null and coalesce(b.donnees->>'src', '') <> 'test'
              and b.secrete is null   -- (7 octobre 2026) jamais une bille secrète (ni la Bêta)
              and (interne.decor_rarete())[b.decor+1] <> 5 and interne.coloris_normal(b.coloris)   -- (9 octobre 2026) ni une bille d'événement ni du passe de saison, comme pour l'album
              order by b.shiny desc, interne.rang(b.taille) desc, (interne.decor_rarete())[b.decor+1] desc, b.numero limit 1),
    'billes', (select count(*) from billes b where b.proprietaire = qui and b.detruite_le is null),
    -- l'album : les billes différentes (taille, décor, coloris) et les cases (taille, décor), hors événements, saisons et secrètes
    'album', (select count(distinct (b.taille, b.decor, b.coloris)) from billes b where b.proprietaire = qui and b.detruite_le is null
                and interne.coloris_normal(b.coloris) and (interne.decor_rarete())[b.decor+1] <> 5),
    'cases', (select count(distinct (b.taille, b.decor)) from billes b where b.proprietaire = qui and b.detruite_le is null and (interne.decor_rarete())[b.decor+1] <> 5),
    'completes', (select count(*) from (select 1 from billes b where b.proprietaire = qui and b.detruite_le is null and interne.coloris_normal(b.coloris)
                and (interne.decor_rarete())[b.decor+1] <> 5 group by b.taille, b.decor having count(distinct b.coloris) >= interne.nb_coloris()) x),
    'tailles', (select coalesce(jsonb_object_agg(t, n), '{}') from (select b.taille t, count(*) n from billes b where b.proprietaire = qui and b.detruite_le is null group by b.taille) x),
    'shinies', (select jsonb_build_array(count(*) filter (where b.shiny = 1), count(*) filter (where b.shiny = 2), count(*) filter (where b.shiny = 3))
                from billes b where b.proprietaire = qui and b.detruite_le is null),
    'shiny', (select count(*) from billes b where b.proprietaire = qui and b.detruite_le is null and b.shiny > 0),
    -- les collections d'événement : les billes différentes (taille, coloris) de chaque décor d'événement
    'evenements', (select coalesce(jsonb_object_agg(d, n), '{}') from (select b.decor d, count(distinct (b.taille, b.coloris)) n from billes b
                where b.proprietaire = qui and b.detruite_le is null and interne.decor_evenement(b.decor) group by b.decor) x),
    'trouvailles', coalesce((select jsonb_agg(x.j order by x.le desc) from (select interne.bille_json(b) || jsonb_build_object('le', floor(extract(epoch from b.obtenue_le)*1000)::bigint) j, b.obtenue_le le
                 from billes b where b.proprietaire = qui and b.detruite_le is null and (interne.rang(b.taille) >= 4 or b.shiny > 0)
                 order by b.obtenue_le desc limit 6) x), '[]')
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
    where b.proprietaire = qui and b.detruite_le is null and b.origine = 'serveur' and b.secrete is null and not interne.encore_liee(b.liee, b.proprietaire)
      and not interne.en_vente(b.id)
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
    order by h.le desc limit 60) x), '[]');   -- 60 depuis le 10 octobre 2026 : la cour montre 72 h de trouvailles rares, par pages
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
  -- 6 octobre 2026 : plus de bonbecs dans les trocs (on pouvait vider un compte secondaire dans le principal), seulement des billes
  if donne_bonbecs <> 0 or demande_bonbecs <> 0 then raise exception 'troc_bonbecs'; end if;
  if donne_bonbecs not between 0 and 5000 or demande_bonbecs not between 0 and 5000 or (donne_bonbecs > 0 and demande_bonbecs > 0) then raise exception 'troc_invalide'; end if;
  if donne_bonbecs > 0 and not exists (select 1 from portefeuilles p where p.joueur = moi and p.bonbecs >= donne_bonbecs) then raise exception 'pas_assez'; end if;
  if donne_bonbecs > interne.libres(moi) then raise exception 'bonbecs_depart'; end if;   -- les bonbecs de départ ne se donnent pas
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
  perform interne.expirer_trocs();
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
  -- un vieux troc avec des bonbecs (d'avant le 6 octobre 2026) ne peut plus être accepté
  if t.donne_bonbecs > 0 or t.demande_bonbecs > 0 then
    update trocs set statut = 'impossible', fini_le = now() where id = t.id;
    return jsonb_build_object('statut', 'impossible');
  end if;
  -- (code d'avant, jamais atteint) les bonbecs : celui qui les propose doit toujours les avoir, sinon le troc tombe
  if t.donne_bonbecs > 0 or t.demande_bonbecs > 0 then
    perform 1 from portefeuilles where joueur in (t.de, t.vers) order by joueur for update;
    if not exists (select 1 from portefeuilles where joueur = t.vers and bonbecs >= t.demande_bonbecs) then raise exception 'pas_assez'; end if;
    if t.demande_bonbecs > interne.libres(t.vers) then raise exception 'bonbecs_depart'; end if;
    if interne.libres(t.de) < t.donne_bonbecs then
      update trocs set statut = 'impossible', fini_le = now() where id = t.id;
      return jsonb_build_object('statut', 'impossible');
    end if;
    -- seuls des bonbecs libres changent de main : la part de départ de chacun ne bouge pas
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
  perform interne.expirer_trocs();
  return jsonb_build_object(
    'recus', coalesce((select jsonb_agg(interne.troc_json(t) order by t.le desc) from trocs t where t.vers = moi and t.statut = 'attente'), '[]'),
    'envoyes', coalesce((select jsonb_agg(interne.troc_json(t) order by t.le desc) from trocs t where t.de = moi and t.statut = 'attente'), '[]'),
    'finis', coalesce((select jsonb_agg(x.j) from (select interne.troc_json(t) j from trocs t
                where (t.de = moi or t.vers = moi) and t.statut <> 'attente' order by t.fini_le desc limit 10) x), '[]'));
end $$;

-- =====================================================================
--  MARCHÉ
-- =====================================================================
-- la plus petite offre acceptée : la mise à prix, puis au moins 5 % de plus que la meilleure offre (1 bonbec minimum)
create or replace function interne.offre_min(prix int, offre int) returns int language sql immutable as
$$ select case when offre is null then prix else offre + greatest(1, ceil(offre * 0.05))::int end $$;
-- une annonce telle que le marché l'affiche (avec le prix moyen payé pour ce modèle ces 30 derniers jours)
create or replace function interne.annonce_json(a public.annonces, b public.billes, moi uuid) returns jsonb language sql stable as $$
  select jsonb_build_object('id', a.id, 'prix', a.prix, 'le', floor(extract(epoch from a.le)*1000)::bigint,
    'fin', floor(extract(epoch from a.expire_le)*1000)::bigint,
    'vendeur', interne.pseudo(a.vendeur), 'moi', a.vendeur = moi, 'bille', interne.bille_json(b),
    'enchere', a.enchere, 'offre', a.offre, 'nb_offres', a.nb_offres, 'min', interne.offre_min(a.prix, a.offre),
    'meilleur', interne.pseudo(a.encherisseur), 'en_tete', coalesce(a.encherisseur = moi, false),
    'vendue', a.vendue_le is not null, 'acheteur', interne.pseudo(a.acheteur),
    'moyen', (select round(avg(a2.prix))::int from public.annonces a2 join public.billes b2 on b2.id = a2.bille
              where a2.vendue_le > now() - interval '30 days' and b2.taille = b.taille and b2.decor = b.decor
                and b2.coloris = b.coloris and (b2.shiny > 0) = (b.shiny > 0)))
$$;

drop function if exists public.vendre(uuid, int);
drop function if exists public.vendre(uuid, int, int);
-- durée : en jours (1, 3, 7) ou, si heures est donné, 3 h ou 12 h (ajouté le 2 octobre 2026)
create or replace function public.vendre(bille uuid, prix int, jours int default 3, heures int default null) returns bigint language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); aid bigint;
begin
  perform interne.expirer_annonces();
  if prix < 1 or prix > 100000 then raise exception 'prix_invalide'; end if;
  if heures is not null then
    if heures not in (3, 12) then raise exception 'duree_invalide'; end if;
  elsif jours not in (1, 3, 7) then raise exception 'duree_invalide'; end if;
  if not interne.bille_libre(bille, moi) then raise exception 'bille_indisponible'; end if;
  if (select count(*) from annonces a where a.vendeur = moi and a.vendue_le is null and a.retiree_le is null) >= 30 then raise exception 'trop_annonces'; end if;
  insert into annonces (vendeur, bille, prix, expire_le)
    values (moi, vendre.bille, vendre.prix, now() + case when heures is not null then make_interval(hours => heures) else make_interval(days => jours) end) returning id into aid;
  return aid;
end $$;

-- une enchère : mise à prix, et durée en heures (1 h, 6 h, 1 jour ou 3 jours)
create or replace function public.mettre_aux_encheres(bille uuid, prix int, heures int default 24) returns bigint language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); aid bigint;
begin
  perform interne.expirer_annonces();
  if prix < 1 or prix > 100000 then raise exception 'prix_invalide'; end if;
  if heures not in (1, 6, 24, 72) then raise exception 'duree_invalide'; end if;
  if not interne.bille_libre(bille, moi) then raise exception 'bille_indisponible'; end if;
  if (select count(*) from annonces a where a.vendeur = moi and a.vendue_le is null and a.retiree_le is null) >= 30 then raise exception 'trop_annonces'; end if;
  insert into annonces (vendeur, bille, prix, expire_le, enchere)
    values (moi, mettre_aux_encheres.bille, mettre_aux_encheres.prix, now() + make_interval(hours => heures), true) returning id into aid;
  return aid;
end $$;

-- enchérir : les bonbecs sont mis de côté tout de suite, l'ancien meilleur enchérisseur est remboursé.
-- Une offre dans la dernière minute repousse la fin à une minute : personne ne gagne en dernière seconde.
create or replace function public.encherir(annonce bigint, montant int) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); a annonces; b billes;
begin
  perform interne.expirer_annonces();
  select * into a from annonces where id = annonce and enchere and vendue_le is null and retiree_le is null and expire_le > now() for update;
  if a.id is null then raise exception 'enchere_finie'; end if;
  if a.vendeur = moi then raise exception 'ta_bille'; end if;
  if a.encherisseur = moi then raise exception 'deja_en_tete'; end if;
  if montant is null or montant < interne.offre_min(a.prix, a.offre) or montant > 100000 then raise exception 'offre_trop_basse'; end if;
  perform 1 from portefeuilles where joueur in (moi, coalesce(a.encherisseur, moi)) order by joueur for update;
  perform interne.payer_libre(moi, montant);   -- les bonbecs de départ ne servent pas aux enchères
  if a.encherisseur is not null then perform interne.crediter(a.encherisseur, a.offre); end if;
  insert into offres (annonce, joueur, montant) values (a.id, moi, montant);
  update annonces set offre = montant, encherisseur = moi, nb_offres = nb_offres + 1,
    expire_le = greatest(expire_le, now() + interval '1 minute') where id = a.id returning * into a;
  select * into b from billes where id = a.bille;
  return jsonb_build_object('eco', interne.etat(moi), 'annonce', interne.annonce_json(a, b, moi));
end $$;

-- retirer une annonce : possible tant que personne n'a enchéri
create or replace function public.retirer_annonce(annonce bigint) returns void language plpgsql security definer set search_path = public as $$
begin
  if exists (select 1 from annonces where id = annonce and vendeur = auth.uid() and encherisseur is not null and vendue_le is null and retiree_le is null)
    then raise exception 'deja_des_offres'; end if;
  update annonces set retiree_le = now() where id = annonce and vendeur = auth.uid() and vendue_le is null and retiree_le is null;
  if not found then raise exception 'plus_en_vente'; end if;
end $$;

create or replace function public.acheter(annonce bigint) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := interne.moi(); a annonces; b billes;
begin
  select * into a from annonces where id = annonce and not enchere and vendue_le is null and retiree_le is null and expire_le > now() for update;
  if a.id is null then raise exception 'plus_en_vente'; end if;
  if a.vendeur = moi then raise exception 'ta_bille'; end if;
  -- on verrouille les deux portefeuilles dans le même ordre pour ne jamais se bloquer
  perform 1 from portefeuilles where joueur in (moi, a.vendeur) order by joueur for update;
  perform interne.payer_libre(moi, a.prix);   -- les bonbecs de départ ne paient pas au marché
  update portefeuilles set bonbecs = bonbecs + a.prix, maj_le = now() where joueur = a.vendeur;
  perform public.transferer_bille(a.bille, a.vendeur, moi, 'vente');
  update annonces set vendue_le = now(), acheteur = moi where id = a.id;
  update trocs x set statut = 'impossible', fini_le = now() where x.statut = 'attente' and (a.bille = any(x.donne) or a.bille = any(x.demande));
  select * into b from billes where id = a.bille;
  return jsonb_build_object('eco', interne.etat(moi), 'bille', interne.bille_json(b));
end $$;

-- les annonces, avec des filtres ; genre : 'fixe' (achat immédiat) ou 'enchere'
drop function if exists public.marche(text, int, int, boolean, text, int);
create or replace function public.marche(taille text default null, decor int default null, coloris int default null,
  shiny boolean default null, tri text default 'recent', page int default 0, genre text default null)
returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  perform interne.expirer_annonces();
  return coalesce((select jsonb_agg(x.j) from (
    select interne.annonce_json(a, b, moi) j
    from annonces a join billes b on b.id = a.bille
    where a.vendue_le is null and a.retiree_le is null
      and (marche.taille is null or b.taille = marche.taille)
      and (marche.decor is null or b.decor = marche.decor)
      and (marche.coloris is null or b.coloris = marche.coloris)
      and (marche.shiny is null or (b.shiny > 0) = marche.shiny)
      and (marche.genre is null or a.enchere = (marche.genre = 'enchere'))
    order by case when tri = 'prix' then coalesce(a.offre, a.prix) end asc, case when tri = 'rare' then interne.rang(b.taille) end desc,
             case when tri = 'rare' then b.shiny end desc, case when tri = 'fin' then a.expire_le end asc, a.le desc
    limit 60 offset greatest(page,0) * 60) x), '[]');
end $$;

-- les enchères où j'ai fait une offre et qui ne sont pas finies (en tête, ou dépassé)
create or replace function public.mes_encheres() returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  perform interne.expirer_annonces();
  return coalesce((select jsonb_agg(x.j order by x.fin) from (
    select interne.annonce_json(a, b, moi) j, a.expire_le fin
    from annonces a join billes b on b.id = a.bille
    where a.enchere and a.vendue_le is null and a.retiree_le is null
      and exists (select 1 from offres o where o.annonce = a.id and o.joueur = moi)) x), '[]');
end $$;

create or replace function public.mes_annonces() returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  perform interne.expirer_annonces();
  return coalesce((select jsonb_agg(x.j) from (
    select interne.annonce_json(a, b, moi) j
    from annonces a join billes b on b.id = a.bille
    where a.vendeur = moi and a.retiree_le is null and (a.vendue_le is null or a.vendue_le > now() - interval '7 days')
    order by a.vendue_le is not null, a.le desc) x), '[]');
end $$;

-- une bille en vente qui part à la Confiserie ou en fusion : son annonce est retirée
-- (sauf une enchère où quelqu'un a déjà fait une offre : la bille est promise, on ne peut plus la détruire)
create or replace function interne.retirer_si_detruite() returns trigger language plpgsql as $$
begin
  if exists (select 1 from public.annonces where bille = new.id and vendue_le is null and retiree_le is null and encherisseur is not null)
    then raise exception 'en_enchere'; end if;
  update public.annonces set retiree_le = now() where bille = new.id and vendue_le is null and retiree_le is null;
  return new;
end $$;
drop trigger if exists pas_en_vente on public.billes;
drop trigger if exists retirer_si_detruite on public.billes;
create trigger retirer_si_detruite before update of detruite_le on public.billes for each row
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
      select a.le, jsonb_build_object('k', 'annonce', 'prix', a.prix, 'enchere', a.enchere, 'bille', interne.bille_json(b)) from annonces a join billes b on b.id = a.bille where a.vendeur = moi
      union all
      select a.vendue_le, jsonb_build_object('k', 'vendue', 'prix', a.prix, 'enchere', a.enchere, 'autre', interne.pseudo(a.acheteur), 'bille', interne.bille_json(b))
        from annonces a join billes b on b.id = a.bille where a.vendeur = moi and a.vendue_le is not null
      union all
      select a.retiree_le, jsonb_build_object('k', case when a.retiree_le = a.expire_le then 'expiree' else 'retiree' end, 'prix', a.prix, 'enchere', a.enchere, 'bille', interne.bille_json(b))
        from annonces a join billes b on b.id = a.bille where a.vendeur = moi and a.retiree_le is not null
      union all
      -- mes achats (et les enchères gagnées)
      select a.vendue_le, jsonb_build_object('k', case when a.enchere then 'gagnee' else 'achat' end, 'prix', a.prix, 'autre', interne.pseudo(a.vendeur), 'bille', interne.bille_json(b))
        from annonces a join billes b on b.id = a.bille where a.acheteur = moi
      union all
      -- enchères : les offres sur mes billes, les miennes, et quand quelqu'un me dépasse
      select o.le, jsonb_build_object('k', case when a.vendeur = moi then 'offre' when o.joueur = moi then 'mon_offre' else 'depasse' end,
          'prix', o.montant, 'autre', interne.pseudo(case when o.joueur = moi then a.vendeur else o.joueur end), 'bille', interne.bille_json(b))
        from (select o.*, lag(o.joueur) over (partition by o.annonce order by o.le, o.id) avant from offres o
              where o.annonce in (select a2.id from annonces a2 where a2.vendeur = moi union select o2.annonce from offres o2 where o2.joueur = moi)) o
        join annonces a on a.id = o.annonce join billes b on b.id = a.bille
        where a.vendeur = moi or o.joueur = moi or (o.avant = moi and o.joueur <> moi)
    ) u where u.le > apres
    order by u.le desc limit least(greatest(coalesce(limite, 80), 1), 200)
  ) e), '[]');
end $$;

-- =====================================================================
--  CLASSEMENT : des points pour la collection (les doubles ne comptent pas)
--  Seules les billes tirées par le serveur comptent (pas les billes de départ, ni les secrètes, ni les billes de test).
--  Barème (mêmes valeurs dans index.html : SCORE) :
--    - chaque case (une taille + un décor) : points de la taille × multiplicateur de rareté du décor
--    - chaque coloris en plus dans une case : un cinquième des points de la taille
--    - chaque shiny différente : 150 (Irisée), 300 (Dorée), 600 (Lumineuse)
--    - un décor dans les 6 tailles : 200 × multiplicateur du décor
--    - une taille dans tous les décors : 20 × les points de la taille
--    - une case avec les 48 coloris de base : 20 × les points de la taille
--    (les séries à thème ont été retirées du jeu le 8 octobre 2026 : elles ne rapportent plus de points)
-- =====================================================================
create or replace function interne.pts_taille() returns int[] language sql immutable as $$ select array[10,15,20,30,60,120] $$;
create or replace function interne.mult_decor() returns numeric[] language sql immutable as $$ select array[1,1.5,2,3,5,0,8]::numeric[] $$;   -- 6e : événements (ne comptent pas) ; 7e : mythique (10 octobre 2026)
create or replace function interne.pts_shiny() returns int[] language sql immutable as $$ select array[150,300,600] $$;

drop function if exists interne.series();
drop function if exists interne.pts_grands();

create or replace function interne.scores() returns table (joueur uuid, total int, cases int, pts_cases int, pts_coloris int, pts_shiny int,
  pts_series int, nb_series int) language sql stable as $$
  with b as (
    select proprietaire j, interne.rang(taille) t, decor d, coloris c, shiny sh from public.billes
    where detruite_le is null and origine = 'serveur' and secrete is null and coalesce(donnees->>'src', '') <> 'test'
      and coalesce((interne.decor_rarete())[decor+1], 5) <> 5),   -- les décors d'événement ne comptent pas (le mythique, 6, compte)
  k as (   -- les cases
    select j, t, d, count(distinct c)::int nc, count(distinct c) filter (where interne.coloris_normal(c))::int nb,
      (interne.pts_taille())[t+1] pt, (interne.mult_decor())[(interne.decor_rarete())[d+1]+1] m
    from b group by j, t, d),
  -- les shiny du passe de saison (coloris de saison) ne comptent pas
  sh as (select j, sum((interne.pts_shiny())[sh])::int p from (select distinct j, t, d, c, sh from b where sh > 0 and interne.coloris_normal(c)) x group by j),
  sd as (select j, sum(round(200 * m))::int p, count(*)::int n from (select j, d, max(m) m from k group by j, d having count(*) = 6) x group by j),
  st as (select j, sum(20 * pt)::int p, count(*)::int n from (select j, t, max(pt) pt from k group by j, t
           having count(*) = (select count(*) from unnest(interne.decor_rarete()) x where x <> 5)) x group by j),
  sc as (select j, sum(20 * pt)::int p, count(*)::int n from k where nb >= interne.nb_coloris() group by j),
  tot as (select j, count(*)::int cases, sum(round(pt * m))::int pc, sum((pt / 5) * (nc - 1))::int pk from k group by j),
  x as (select tot.*, coalesce(sh.p,0) psh,
          coalesce(sd.p,0) + coalesce(st.p,0) + coalesce(sc.p,0) pse,
          coalesce(sd.n,0) + coalesce(st.n,0) + coalesce(sc.n,0) nse
        from tot left join sh on sh.j = tot.j left join sd on sd.j = tot.j left join st on st.j = tot.j left join sc on sc.j = tot.j)
  select j, (pc + pk + psh + pse)::int, cases, pc, pk, psh, pse::int, nse::int from x
$$;

-- le classement : tout le monde, ou moi et mes copains. Ma place à moi, et :
--  · sans « page » (anciennes pages du site) : les 50 premiers ;
--  · page = 0 : le podium (3 premiers) et la page de 10 où je suis ; page >= 1 : cette page-là (10 octobre 2026).
--    Page 1 = places 1 à 10, page 2 = 11 à 20… (le site n'affiche pas en liste ceux déjà sur le podium).
drop function if exists public.classement(text);
create or replace function public.classement(portee text default 'tous', page int default null) returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  return (with r as (
      select p.joueur, coalesce(s.total, 0) total, coalesce(s.cases, 0) cases, s.pts_cases, s.pts_coloris, s.pts_shiny, s.pts_series, s.nb_series,
        rank() over (order by coalesce(s.total, 0) desc) rang,
        row_number() over (order by coalesce(s.total, 0) desc, coalesce(s.cases, 0) desc, p.joueur) pos
      from portefeuilles p left join interne.scores() s on s.joueur = p.joueur
      -- les comptes de test (table testeurs : le compte « admin ») ne sont pas classés
      where p.joueur not in (select joueur from testeurs)
        and (portee <> 'copains' or p.joueur = moi or p.joueur in (select ami from amis where joueur = moi))),
    m as (select r.* from r where r.joueur = moi),
    nb as (select count(*)::int n, greatest(1, ceil(count(*) / 10.0))::int pages from r),
    pg as (select case when page is null then null when page >= 1 then least(page, nb.pages)
                       else coalesce((select ceil(m.pos / 10.0)::int from m), 1) end p from nb),
    ligne as (select r.*, interne.carte(r.joueur) || jsonb_build_object('rang', r.rang, 'pos', r.pos, 'total', r.total, 'cases', r.cases, 'moi', r.joueur = moi) j from r)
    select jsonb_build_object('nb', nb.n,
      'liste', coalesce((select jsonb_agg(l.j order by l.pos) from ligne l
                 where (pg.p is null and l.pos <= 50) or (pg.p is not null and l.pos between (pg.p - 1) * 10 + 1 and pg.p * 10)), '[]'),
      'moi', (select jsonb_build_object('rang', m.rang, 'pos', m.pos, 'total', m.total, 'cases', m.cases, 'pts_cases', coalesce(m.pts_cases,0),
                 'pts_coloris', coalesce(m.pts_coloris,0), 'pts_shiny', coalesce(m.pts_shiny,0), 'pts_series', coalesce(m.pts_series,0),
                 'nb_series', coalesce(m.nb_series,0)) from m))
      || case when pg.p is null then '{}'::jsonb else jsonb_build_object('page', pg.p, 'pages', nb.pages,
           'podium', coalesce((select jsonb_agg(l.j order by l.pos) from ligne l where l.pos <= 3), '[]'),
           -- le joueur juste devant moi (pour « Plus que … pts pour passer devant »), même s'il est sur une autre page
           'devant', (select jsonb_build_object('pseudo', interne.pseudo(r.joueur), 'total', r.total) from r, m where r.pos = m.pos - 1)) end
    from nb, pg);
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

-- Mes statistiques (page Profil) : tout ce que le serveur a noté depuis l'arrivée du joueur
-- (10 octobre 2026, revu) en plus de la cour : les parties de chaque jeu (offertes + achetées, d'après gains),
-- les quêtes, les succès, les jours où les 3 jeux du jour sont faits, la Grande Course, la Loterie, les billes
-- échangées contre des bonbecs et la place au classement. Le site garde le plus grand de ses compteurs et de ceux-ci.
create or replace function public.cour_stats() returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid(); g jsonb; mon int;
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  -- parties jouées par jeu : la partie offerte (source 'jeu', clé « jour|jeu ») + les parties achetées (source = le jeu ; 'plinko' pour le Plinko)
  select coalesce(jsonb_object_agg(k, n), '{}') into g from (
    select case when source = 'jeu' then split_part(cle, '|', 2) when source = 'plinko' then 'pachinko' else source end k, count(*) n
    from gains where joueur = moi and (source in ('jeu', 'plinko', 'roue', 'grattage', 'distributeur', 'marelle'))
    group by 1) x;
  select s.total into mon from interne.scores() s where s.joueur = moi;
  return jsonb_build_object(
    'trocs',    (select count(*) from trocs t where (t.de = moi or t.vers = moi) and t.statut = 'accepte'),
    'vendues',  (select count(*) from annonces a where a.vendeur = moi and a.vendue_le is not null),
    'achetees', (select count(*) from annonces a where a.acheteur = moi and not a.enchere),
    'encheres', (select count(*) from annonces a where a.acheteur = moi and a.enchere),
    'copains',  (select count(*) from amis where joueur = moi),
    'gagne_marche', (select coalesce(sum(prix), 0) from annonces a where a.vendeur = moi and a.vendue_le is not null),
    'parties',  g,
    'quetes',   (select count(*) from gains where joueur = moi and source = 'quete'),
    'bonus_quetes', (select count(*) from gains where joueur = moi and source = 'quetes-bonus'),
    'jeux_bonus',   (select count(*) from gains where joueur = moi and source = 'jeux-bonus'),
    'succes',   (select count(*) from gains where joueur = moi and source = 'succes'),
    'sachets',  (select sacs_ouverts from portefeuilles where joueur = moi),
    'recyclees', (select count(*) from billes where proprietaire = moi and detruite_raison = 'recyclee'),
    'course_inscrit', (select count(*) from course_inscrits where joueur = moi),
    'course_podiums', (select count(*) from courses c, jsonb_array_elements(c.resultats) with ordinality e(v, pos) where e.v->>'joueur' = moi::text and e.pos <= 3),
    'course_victoires', (select count(*) from courses c where c.resultats->0->>'joueur' = moi::text),
    'loterie_tickets', (select count(*) from loterie_tickets where joueur = moi),
    'loterie_gagnants', (select count(*) from loterie_tickets where joueur = moi and bons >= 1),
    'loterie_meilleur', (select coalesce(max(bons), 0) from loterie_tickets where joueur = moi),
    -- la place au classement de tous les joueurs (comme public.classement : les comptes de test ne sont pas classés)
    'rang', case when moi in (select joueur from testeurs) or moi not in (select joueur from portefeuilles) then null
                 else 1 + (select count(*) from portefeuilles p left join interne.scores() s on s.joueur = p.joueur
                           where coalesce(s.total, 0) > coalesce(mon, 0) and p.joueur not in (select joueur from testeurs)) end,
    'classes', (select count(*) from portefeuilles p where p.joueur not in (select joueur from testeurs)));
end $$;

-- droits : le site ne peut appeler que ces fonctions-là
do $$ declare f text; begin
  foreach f in array array['cour_moi()','ami_demander(text)','ami_repondre(uuid,boolean)','ami_retirer(uuid)','profil_joueur(uuid)',
    'billes_echangeables(uuid)','fil_amis()','troc_proposer(uuid,uuid[],uuid[],text,bigint,int,int)','troc_repondre(bigint,boolean)','troc_annuler(bigint)',
    'mes_trocs()','vendre(uuid,int,int,int)','retirer_annonce(bigint)','acheter(bigint)','marche(text,int,int,boolean,text,int,text)','mes_annonces()','cour_journal(bigint,int)',
    'mettre_aux_encheres(uuid,int,int)','encherir(bigint,int)','mes_encheres()','classement(text,int)','cour_stats()'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
