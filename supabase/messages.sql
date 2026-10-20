-- =====================================================================
--  TIKALO : un mot de l'équipe à un joueur (20 octobre 2026)
--  À installer après serveur.sql (utilise interne.moi et interne.crediter).
--
--  Une excuse après un bug, avec un cadeau : on l'écrit à la main (insert dans public.messages),
--  le jeu l'affiche une fois à l'arrivée du joueur, et le cadeau (bonbecs, sachet offert) est versé
--  quand il ferme la fenêtre (message_lu), une seule fois.
--    insert into public.messages (joueur, titre, texte, bonbecs, sac) values ('<uuid>', 'Oups !', 'Désolé…', 30, 'premium');
-- =====================================================================

create table if not exists public.messages (
  id      bigint generated always as identity primary key,
  joueur  uuid not null references auth.users(id) on delete cascade,
  titre   text not null,
  texte   text not null,                -- texte simple (le jeu l'échappe)
  bonbecs int  not null default 0 check (bonbecs >= 0),
  sac     text check (sac in ('classique','premium','collector')),
  le      timestamptz not null default now(),
  lu_le   timestamptz
);
create index if not exists messages_a_lire on public.messages (joueur) where lu_le is null;
alter table public.messages enable row level security;
revoke all on public.messages from anon, authenticated;

-- les messages pas encore lus du joueur connecté, les plus anciens d'abord
create or replace function public.messages_a_lire()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'titre', m.titre, 'texte', m.texte, 'bonbecs', m.bonbecs, 'sac', m.sac) order by m.id), '[]')
  from messages m where m.joueur = interne.moi() and m.lu_le is null $$;

-- lu : le cadeau est versé (une fois), et le jeu reçoit le nouvel état du portefeuille
create or replace function public.message_lu(mid bigint)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); m record;
begin
  update messages set lu_le = now() where id = mid and joueur = qui and lu_le is null returning * into m;
  if found then
    perform 1 from portefeuilles where joueur = qui for update;
    if m.bonbecs > 0 or m.sac is not null then perform interne.crediter(qui, m.bonbecs, m.sac); end if;
  end if;
  return interne.etat(qui);
end $$;

revoke all on function public.messages_a_lire(), public.message_lu(bigint) from public, anon;
grant execute on function public.messages_a_lire(), public.message_lu(bigint) to authenticated;
