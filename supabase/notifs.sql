-- =====================================================================
--  TIKALO : les notifications en temps réel (4 octobre 2026)
--  À installer après cour.sql.
--
--  Une toute petite table « pings » : une ligne par joueur, mise à jour dès qu'il se passe quelque chose
--  qui le concerne (un troc reçu ou répondu, une demande de copain, une vente, une enchère dépassée…).
--  Le jeu écoute SA ligne en temps réel (Supabase Realtime) et va alors chercher les nouvelles
--  (cour_journal, cour_moi) : la table ne contient aucune information, juste « il y a du nouveau ».
-- =====================================================================

create table if not exists public.pings (
  joueur uuid primary key references auth.users(id) on delete cascade,
  le     timestamptz not null default now(),
  quoi   text
);
alter table public.pings enable row level security;
drop policy if exists "pings : le sien" on public.pings;
create policy "pings : le sien" on public.pings for select to authenticated using (joueur = auth.uid());
revoke insert, update, delete on public.pings from anon, authenticated;
grant select on public.pings to authenticated;
do $$ begin
  if not exists (select 1 from pg_publication_tables where pubname = 'supabase_realtime' and schemaname = 'public' and tablename = 'pings') then
    alter publication supabase_realtime add table public.pings;
  end if;
end $$;

create or replace function interne.ping(qui uuid[], quoi text) returns void language sql security definer set search_path = public as $$
  insert into public.pings (joueur, le, quoi)
    select distinct j, now(), quoi from unnest(qui) j where j is not null
  on conflict (joueur) do update set le = excluded.le, quoi = excluded.quoi;
$$;

create or replace function interne.ping_trocs() returns trigger language plpgsql security definer set search_path = public as $$
begin perform interne.ping(array[new.de, new.vers], 'troc'); return null; end $$;
create or replace function interne.ping_demandes() returns trigger language plpgsql security definer set search_path = public as $$
declare r record;
begin r := coalesce(new, old); perform interne.ping(array[r.de, r.vers], 'ami'); return null; end $$;
create or replace function interne.ping_amis() returns trigger language plpgsql security definer set search_path = public as $$
declare r record;
begin r := coalesce(new, old); perform interne.ping(array[r.joueur, r.ami], 'ami'); return null; end $$;
-- une annonce change : vendue, retirée, expirée, ou une nouvelle offre (le vendeur, l'acheteur, l'ancien et le nouvel enchérisseur)
create or replace function interne.ping_annonces() returns trigger language plpgsql security definer set search_path = public as $$
begin perform interne.ping(array[new.vendeur, new.acheteur, old.encherisseur, new.encherisseur], 'marche'); return null; end $$;

drop trigger if exists ping on public.trocs;
create trigger ping after insert or update on public.trocs for each row execute function interne.ping_trocs();
drop trigger if exists ping on public.demandes_amis;
create trigger ping after insert or delete on public.demandes_amis for each row execute function interne.ping_demandes();
drop trigger if exists ping on public.amis;
create trigger ping after insert or delete on public.amis for each row execute function interne.ping_amis();
drop trigger if exists ping on public.annonces;
create trigger ping after update on public.annonces for each row execute function interne.ping_annonces();

revoke all on all functions in schema interne from public, anon, authenticated;
