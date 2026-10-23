-- La Pince, tous les lots dans la machine (23 octobre 2026). À installer APRÈS jeux-chance-2.sql (remplace pince_remplir et pince).
-- Avant : 24 boules tirées comme à la Roue et une boule prise au hasard (1 chance sur 24) ; le Mammouth (0,2 %) n'était presque jamais dans la machine.
-- Maintenant : chacun des 9 lots (Mammouth, Collector, Premium, Classique, 100, 40, 20, 10, 5) est toujours dans la machine au moins une fois,
-- et le lot gagné est tiré comme à la Roue (mêmes chances qu'avant) ; la pince va chercher une boule de ce lot.
-- La page fait parfois glisser un gros lot de la pince avant d'attraper la bonne boule : c'est seulement l'animation, on gagne toujours un lot.

-- le « genre » d'une case (les cases 1 et 5 sont toutes les deux « 5 bonbecs », 3 et 8 « 10 bonbecs »)
create or replace function interne.roue_sig(p_k int) returns text language sql immutable as $$
  select coalesce(r.bonbecs, 0) || '|' || coalesce(r.sac, '') || '|' || coalesce(r.taille, '') from interne.roue_cases() r where r.k = p_k
$$;

-- il manque un lot dans la machine : une boule d'un lot en double (au hasard) le devient
create or replace function interne.pince_complet(m int[]) returns int[] language plpgsql volatile as $$
declare c record; cand int[];
begin
  for c in select distinct on (interne.roue_sig(r.k)) r.k, interne.roue_sig(r.k) s from interne.roue_cases() r order by interne.roue_sig(r.k), r.k loop
    if not exists (select 1 from unnest(m) x where interne.roue_sig(x) = c.s) then
      select array_agg(o) into cand from generate_series(1, array_length(m, 1)) o
        where (select count(*) from unnest(m) y where interne.roue_sig(y) = interne.roue_sig(m[o])) > 1;
      m[cand[1 + floor(random() * array_length(cand, 1))::int]] := c.k;
    end if;
  end loop;
  return m;
end $$;

create or replace function interne.pince_remplir(qui uuid) returns int[] language plpgsql as $$
declare m int[]; m2 int[];
begin
  select boules into m from pince_machines where joueur = qui for update;
  if m is null or coalesce(array_length(m, 1), 0) <> 24 then
    select array_agg(interne.roue_tirage()) into m from generate_series(1, 24);
  end if;
  m2 := interne.pince_complet(m);
  insert into pince_machines (joueur, boules) values (qui, m2) on conflict (joueur) do update set boules = excluded.boules, maj = now();
  return m2;
end $$;

create or replace function public.pince(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j record; m int[]; i int; k int; s text; cand int[]; neuve int; b jsonb;
begin
  select * into j from interne.jeu_chance(qui, 'pince', payer, 15);
  m := interne.pince_remplir(qui);
  -- le lot gagné, tiré comme à la Roue ; puis une boule de ce lot dans la machine (il y en a toujours au moins une)
  s := interne.roue_sig(interne.roue_tirage());
  select array_agg(o) into cand from generate_series(1, 24) o where interne.roue_sig(m[o]) = s;
  i := cand[1 + floor(random() * array_length(cand, 1))::int]; k := m[i];
  -- une boule neuve retombe ; si c'était la dernière de son lot, elle est du même lot (tous les lots restent dans la machine)
  neuve := case when array_length(cand, 1) > 1 then interne.roue_tirage() else k end;
  m[i] := neuve;
  update pince_machines set boules = m, maj = now() where joueur = qui;
  b := interne.roue_verser(qui, k, j.lie, 'pince', payer);
  return jsonb_build_object('eco', interne.etat(qui), 'boule', i - 1, 'case', k, 'neuve', neuve, 'bille', b, 'achetees', j.achetees);
end $$;

revoke all on function public.pince(boolean) from public, anon;
grant execute on function public.pince(boolean) to authenticated;
revoke all on all functions in schema interne from public, anon, authenticated;
