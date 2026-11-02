-- =====================================================================
--  TIKALO : l'annonce des billes mythiques (2 novembre 2026)
--  À installer après cour.sql (utilise interne.moi, interne.pseudo, interne.bille_json, interne.decor_rarete).
--
--  Quand quelqu'un trouve une bille mythique, tous les joueurs voient une grande fenêtre, une seule fois chacun :
--  « Tcherno Bille a trouvé la 1re mythique du serveur ! ». Celui qui l'a trouvée la voit aussi (« C'est toi ! »).
--  Seulement les mythiques des 7 derniers jours (un joueur qui revient après un mois n'a pas une pile d'annonces).
--  Ne comptent pas : les billes de test, les secrètes, et les comptes de test (table testeurs).
--  Le numéro (1re, 2e…) compte toutes les mythiques du serveur, depuis le début.
-- =====================================================================

create index if not exists billes_decor on public.billes (decor);

create table if not exists public.mythiques_vues (
  joueur uuid not null references auth.users(id) on delete cascade,
  bille  uuid not null,
  le     timestamptz not null default now(),
  primary key (joueur, bille)
);
alter table public.mythiques_vues enable row level security;
revoke all on public.mythiques_vues from anon, authenticated;

-- toutes les mythiques du serveur, dans l'ordre : qui l'a trouvée (le premier à l'avoir eue), quand, et son numéro
create or replace function interne.mythiques() returns table (bille uuid, qui uuid, le timestamptz, n int, b public.billes) language sql stable as $$
  select x.id, x.qui, x.le, (row_number() over (order by x.le, x.id))::int, x.b from (
    select b.id, b as b,
      coalesce((select h.vers from public.billes_historique h where h.bille = b.id order by h.le, h.id limit 1), b.proprietaire) qui,
      coalesce((select min(h.le) from public.billes_historique h where h.bille = b.id), b.creee_le) le
    from public.billes b
    where b.decor = any(array(select (u.i - 1)::int from unnest(interne.decor_rarete()) with ordinality u(r, i) where u.r = 6))
      and b.origine = 'serveur' and b.secrete is null and coalesce(b.donnees->>'src', '') <> 'test') x
  where x.qui not in (select t.joueur from public.testeurs t)
$$;

-- les annonces que le joueur connecté n'a pas encore vues (les plus anciennes d'abord)
create or replace function public.mythiques_a_voir() returns jsonb language plpgsql stable security definer set search_path = public as $$
declare moi uuid := interne.moi();
begin
  return coalesce((select jsonb_agg(jsonb_build_object('id', m.bille, 'n', m.n, 'qui', m.qui, 'who', interne.pseudo(m.qui), 'moi', m.qui = moi,
      'at', floor(extract(epoch from m.le)*1000)::bigint, 's', interne.bille_json(m.b)) order by m.le)
    from interne.mythiques() m
    where m.le > now() - interval '7 days'
      and not exists (select 1 from mythiques_vues v where v.joueur = moi and v.bille = m.bille)), '[]');
end $$;

-- vue : elle ne revient plus
create or replace function public.mythique_vue(bid uuid) returns void language sql security definer set search_path = public as $$
  insert into mythiques_vues (joueur, bille) values (interne.moi(), bid) on conflict do nothing $$;

revoke all on function public.mythiques_a_voir(), public.mythique_vue(uuid) from public, anon;
grant execute on function public.mythiques_a_voir(), public.mythique_vue(uuid) to authenticated;
revoke all on function interne.mythiques() from public, anon, authenticated;
