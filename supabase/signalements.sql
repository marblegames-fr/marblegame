-- =====================================================================
--  BILLY : « Signaler un bug » (7 octobre 2026)
--  À installer après serveur.sql (utilise public.testeurs).
--
--  Un joueur connecté envoie un message (catégorie + texte) ; le jeu y joint tout seul quelques détails
--  utiles (page, appareil, taille d'écran, dernières erreurs). Seuls les comptes de public.testeurs
--  (l'admin) peuvent les lire et les marquer comme réglés, depuis Paramètres.
-- =====================================================================

create table if not exists public.signalements (
  id        bigint generated always as identity primary key,
  joueur    uuid references auth.users(id) on delete set null,
  pseudo    text,
  categorie text not null check (categorie in ('bug','affichage','idee','autre')),
  texte     text not null check (length(texte) between 3 and 2000),
  details   jsonb not null default '{}',
  le        timestamptz not null default now(),
  regle     boolean not null default false
);
alter table public.signalements enable row level security;
revoke all on public.signalements from anon, authenticated;

-- envoyer : 20 messages par jour au plus (contre les abus)
create or replace function public.signaler(categorie text, texte text, details jsonb default '{}')
returns bigint language plpgsql security definer set search_path = public as $$
declare qui uuid := auth.uid(); n int; nouvel bigint;
begin
  if qui is null then raise exception 'non_connecte'; end if;
  if categorie not in ('bug','affichage','idee','autre') then raise exception 'categorie'; end if;
  texte := btrim(coalesce(texte, ''));
  if length(texte) < 3 then raise exception 'trop_court'; end if;
  if length(texte) > 2000 then texte := left(texte, 2000); end if;
  if length(coalesce(details, '{}')::text) > 8000 then details := '{}'; end if;
  select count(*) into n from signalements s where s.joueur = qui and s.le > now() - interval '1 day';
  if n >= 20 then raise exception 'trop'; end if;
  insert into signalements (joueur, pseudo, categorie, texte, details)
    values (qui, (select p.pseudo from profils p where p.id = qui), categorie, texte, coalesce(details, '{}'))
    returning id into nouvel;
  return nouvel;
end $$;

-- lire (admin) : les plus récents d'abord, les non réglés seulement si tous = false
create or replace function public.signalements_liste(tous boolean default false)
returns setof public.signalements language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from testeurs t where t.joueur = auth.uid()) then raise exception 'reserve_aux_testeurs'; end if;
  return query select * from signalements s where tous or not s.regle order by s.le desc limit 300;
end $$;

-- marquer réglé / pas réglé (admin)
create or replace function public.signalement_regle(sid bigint, oui boolean)
returns void language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from testeurs t where t.joueur = auth.uid()) then raise exception 'reserve_aux_testeurs'; end if;
  update signalements set regle = oui where id = sid;
end $$;

revoke all on function public.signaler(text, text, jsonb), public.signalements_liste(boolean), public.signalement_regle(bigint, boolean) from public, anon;
grant execute on function public.signaler(text, text, jsonb), public.signalements_liste(boolean), public.signalement_regle(bigint, boolean) to authenticated;
