-- =====================================================================
--  TIKALO : compteur de fréquentation anonyme (19 octobre 2026)
--  À installer après serveur.sql (utilise public.testeurs).
--
--  Le jeu compte les étapes du parcours d'un nouveau visiteur : arrivée sur le site, début de l'inscription,
--  formulaire envoyé, premier passage du compte, bille de départ, premier sachet (une seule fois par appareil),
--  plus une visite par appareil et par jour. Rien ne permet de savoir QUI : juste un total par jour, par étape
--  et par provenance (« insta » = arrivé par Instagram/Facebook, « autre » sinon).
--  Seuls les comptes de public.testeurs (l'admin) lisent les totaux, depuis Paramètres.
-- =====================================================================

create table if not exists public.frequentation (
  jour   date not null,
  etape  text not null,
  source text not null,
  n      int  not null default 0,
  primary key (jour, etape, source)
);
alter table public.frequentation enable row level security;
revoke all on public.frequentation from anon, authenticated;

create or replace function public.compter(etape text, source text)
returns void language plpgsql security definer set search_path = public as $$
declare e text := compter.etape; s text := compter.source;   -- mêmes noms que les colonnes : on les recopie
begin
  if e not in ('arrivee','visite','invite','inscription','envoye','compte','depart','sachet') then return; end if;
  if s is null or s not in ('insta','autre') then s := 'autre'; end if;
  insert into frequentation as f (jour, etape, source, n) values ((now() at time zone 'Europe/Paris')::date, e, s, 1)
    on conflict on constraint frequentation_pkey do update set n = f.n + 1;
end $$;

-- lire (admin) : les derniers jours
create or replace function public.frequentation_liste(jours int default 14)
returns setof public.frequentation language plpgsql security definer set search_path = public as $$
begin
  if not exists (select 1 from testeurs t where t.joueur = auth.uid()) then raise exception 'reserve_aux_testeurs'; end if;
  return query select * from frequentation f
    where f.jour > (now() at time zone 'Europe/Paris')::date - least(greatest(jours, 1), 120) order by f.jour desc;
end $$;

revoke all on function public.compter(text, text), public.frequentation_liste(int) from public, anon, authenticated;
grant execute on function public.compter(text, text) to anon, authenticated;
grant execute on function public.frequentation_liste(int) to authenticated;
