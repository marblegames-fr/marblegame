-- =====================================================================
--  BILLY : le numéro de remise à zéro
--  Une page restée ouverte pendant un reset garde l'ancienne partie en mémoire et la renverrait
--  (succès, séries, passe… ressuscités). Chaque page lit ce numéro au démarrage et le joint à ses
--  sauvegardes : le serveur refuse une sauvegarde d'un autre numéro, et la page se recharge à zéro.
--  Tant qu'aucun reset n'a été fait (pas de ligne), toutes les sauvegardes passent.
--  supabase/reset.sql change le numéro.
-- =====================================================================

create table if not exists public.remise (id int primary key default 1 check (id = 1), numero bigint not null);
alter table public.remise enable row level security;
drop policy if exists remise_lire on public.remise;
create policy remise_lire on public.remise for select to authenticated using (true);
revoke all on public.remise from anon, authenticated;
grant select on public.remise to authenticated;

create or replace function interne.sauvegarde_remise() returns trigger language plpgsql security definer set search_path = public as $$
declare n bigint;
begin
  select numero into n from public.remise where id = 1;
  if n is not null and (new.donnees->>'remise') is distinct from n::text then raise exception 'remise'; end if;
  return new;
end $$;

drop trigger if exists sauvegarde_remise on public.sauvegardes;
create trigger sauvegarde_remise before insert or update on public.sauvegardes for each row execute function interne.sauvegarde_remise();
