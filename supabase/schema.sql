-- =====================================================================
--  BILLY : base de données (Supabase / PostgreSQL)
--  À coller en entier dans Supabase > SQL Editor > New query > Run.
--  Le script peut être relancé sans danger.
-- =====================================================================

-- ---------- Profils : un par compte, le pseudo est unique ----------
create table if not exists public.profils (
  id         uuid primary key references auth.users(id) on delete cascade,
  pseudo     text not null check (char_length(pseudo) between 3 and 20),
  cree_le    timestamptz not null default now()
);
create unique index if not exists profils_pseudo_unique on public.profils (lower(pseudo));

-- le profil est créé automatiquement à l'inscription, avec le pseudo choisi
create or replace function public.creer_profil() returns trigger
language plpgsql security definer set search_path = public as $$
declare p text := coalesce(nullif(trim(new.raw_user_meta_data->>'pseudo'), ''), 'Billeur');
begin
  -- pseudo déjà pris : on ajoute un petit numéro
  if exists (select 1 from profils where lower(pseudo) = lower(p)) then
    p := left(p, 15) || '_' || floor(random()*9000+1000)::int;
  end if;
  insert into profils (id, pseudo) values (new.id, p);
  return new;
end $$;
drop trigger if exists a_l_inscription on auth.users;
create trigger a_l_inscription after insert on auth.users
  for each row execute function public.creer_profil();

-- ---------- Sauvegarde : tout sauf les billes (bonbecs, titres, défis…) ----------
create table if not exists public.sauvegardes (
  joueur      uuid primary key references auth.users(id) on delete cascade default auth.uid(),
  donnees     jsonb not null,
  appareil    text,
  maj_le      timestamptz not null default now()
);

-- ---------- Billes : une ligne par bille, identifiant unique ----------
create table if not exists public.billes (
  id               uuid primary key default gen_random_uuid(),
  numero           bigint generated always as identity unique,   -- numéro de série unique, dans l'ordre d'apparition
  proprietaire     uuid not null references auth.users(id) default auth.uid(),
  seed             bigint not null,
  taille           text not null,
  decor            int not null,
  coloris          int not null,
  shiny            int not null default 0,
  secrete          text,
  donnees          jsonb not null,            -- la bille complète telle que le jeu la connaît
  obtenue_le       timestamptz not null default now(),
  creee_le         timestamptz not null default now(),
  detruite_le      timestamptz,               -- recyclée ou fusionnée : on garde la trace
  detruite_raison  text
);
create index if not exists billes_proprietaire on public.billes (proprietaire) where detruite_le is null;

-- ---------- Historique : chaque changement de propriétaire ----------
create table if not exists public.billes_historique (
  id      bigint generated always as identity primary key,
  bille   uuid not null references public.billes(id) on delete cascade,
  de      uuid references auth.users(id),
  vers    uuid references auth.users(id),
  motif   text not null,                      -- 'trouvee', 'echange', 'vente', 'detruite'…
  le      timestamptz not null default now()
);
create index if not exists billes_historique_bille on public.billes_historique (bille);

-- =====================================================================
--  SÉCURITÉ (Row Level Security)
--  Un joueur ne lit et n'écrit que ses propres données.
--  Personne ne peut changer le propriétaire d'une bille directement :
--  seules les fonctions ci-dessous le peuvent.
-- =====================================================================
alter table public.profils           enable row level security;
alter table public.sauvegardes       enable row level security;
alter table public.billes            enable row level security;
alter table public.billes_historique enable row level security;

revoke all on public.profils, public.sauvegardes, public.billes, public.billes_historique from anon, authenticated;

-- profils : lisibles par les joueurs connectés (pour les échanges plus tard), modifiables par soi
grant select, update (pseudo) on public.profils to authenticated;
drop policy if exists profils_lire on public.profils;
create policy profils_lire on public.profils for select to authenticated using (true);
drop policy if exists profils_modifier on public.profils;
create policy profils_modifier on public.profils for update to authenticated using (id = auth.uid()) with check (id = auth.uid());

-- sauvegardes : uniquement la sienne
grant select, insert, update (joueur, donnees, appareil, maj_le) on public.sauvegardes to authenticated;
drop policy if exists sauvegardes_soi on public.sauvegardes;
create policy sauvegardes_soi on public.sauvegardes for all to authenticated
  using (joueur = auth.uid()) with check (joueur = auth.uid());

-- billes : on lit les siennes, on ajoute les siennes. Jamais de modification ni de suppression directe.
grant select on public.billes to authenticated;
grant insert (id, seed, taille, decor, coloris, shiny, secrete, donnees, obtenue_le) on public.billes to authenticated;
drop policy if exists billes_lire on public.billes;
create policy billes_lire on public.billes for select to authenticated using (proprietaire = auth.uid());
drop policy if exists billes_ajouter on public.billes;
create policy billes_ajouter on public.billes for insert to authenticated with check (proprietaire = auth.uid());

grant select on public.billes_historique to authenticated;
drop policy if exists historique_lire on public.billes_historique;
create policy historique_lire on public.billes_historique for select to authenticated
  using (exists (select 1 from public.billes b where b.id = bille and b.proprietaire = auth.uid()));

-- la trouvaille est notée dans l'historique automatiquement
create or replace function public.noter_trouvaille() returns trigger
language plpgsql security definer set search_path = public as $$
begin
  insert into billes_historique (bille, de, vers, motif) values (new.id, null, new.proprietaire, 'trouvee');
  return new;
end $$;
drop trigger if exists a_la_trouvaille on public.billes;
create trigger a_la_trouvaille after insert on public.billes
  for each row execute function public.noter_trouvaille();

-- ---------- Recyclage / fusion : le joueur retire ses propres billes ----------
create or replace function public.detruire_billes(ids uuid[], raison text default 'recyclee')
returns int language plpgsql security definer set search_path = public as $$
declare n int;
begin
  with d as (
    update billes set detruite_le = now(), detruite_raison = left(raison, 30)
    where id = any(ids) and proprietaire = auth.uid() and detruite_le is null
    returning id
  ), h as (
    insert into billes_historique (bille, de, vers, motif) select id, auth.uid(), null, 'detruite' from d
  )
  select count(*) into n from d;
  return n;
end $$;
revoke all on function public.detruire_billes(uuid[], text) from public, anon;
grant execute on function public.detruire_billes(uuid[], text) to authenticated;

-- ---------- Changement de propriétaire (base des futurs échanges et du marché) ----------
-- Interne : les joueurs ne peuvent pas l'appeler directement. Les fonctions d'échange et de
-- vente de la cour de récré l'utiliseront après avoir vérifié l'accord des deux joueurs.
create or replace function public.transferer_bille(b uuid, de_qui uuid, vers_qui uuid, motif text)
returns void language plpgsql security definer set search_path = public as $$
begin
  -- la bille garde sa date de trouvaille (found) et note d'où elle vient : via = {k: 'echange' | 'vente', de: pseudo}
  update billes set proprietaire = vers_qui, obtenue_le = now(),
      donnees = donnees || jsonb_build_object('at', floor(extract(epoch from now())*1000)::bigint,
        'found', coalesce(donnees->'found', donnees->'at'),
        'via', jsonb_build_object('k', motif, 'de', (select p.pseudo from profils p where p.id = de_qui)))
    where id = b and proprietaire = de_qui and detruite_le is null;
  if not found then raise exception 'Cette bille n''appartient pas (ou plus) à ce joueur'; end if;
  insert into billes_historique (bille, de, vers, motif) values (b, de_qui, vers_qui, motif);
end $$;
revoke all on function public.transferer_bille(uuid, uuid, uuid, text) from public, anon, authenticated;
