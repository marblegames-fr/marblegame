-- (28 octobre 2026) La Toupie est retirée : trop proche de la Roue.
-- À partir du 29 octobre 2026 (heure de Paris) : plus de partie de Toupie, et les 3 jeux du jour sont tirés parmi 8 jeux, sans elle.
-- Le 28 elle reste jouable jusqu'à minuit (elle fait partie des 3 jeux du jour). Même date que TOUPIE_FIN dans index.html.

create or replace function interne.jeux_du_jour(j date) returns text[] language plpgsql immutable as $$
declare tous text[]; n int;
        x bigint := ((j - date '2026-01-01') * 7919 + 12345) % 65521; a text; b text; c text; r text[];
begin
  if j < date '2026-10-23' then
    tous := array['gobelets','marelle','tierce','toupie','roue','pachinko','grattage','distributeur'];
    x := (x * x + 7) % 65521; x := (x * x + 7) % 65521; a := tous[1 + x % 4];
    r := array_remove(tous, a);  x := (x * x + 7) % 65521; b := r[1 + x % 7];
    r := array_remove(r, b);     x := (x * x + 7) % 65521; c := r[1 + x % 6];
  else
    if j < date '2026-10-29' then
      tous := array['gobelets','marelle','tierce','toupie','pince','roue','pachinko','grattage','distributeur'];
    else
      tous := array['gobelets','marelle','tierce','pince','roue','pachinko','grattage','distributeur'];
    end if;
    n := array_length(tous, 1);
    x := (x * x + 7) % 65521; x := (x * x + 7) % 65521; a := tous[1 + x % n];
    r := array_remove(tous, a);  x := (x * x + 7) % 65521; b := r[1 + x % (n-1)];
    r := array_remove(r, b);     x := (x * x + 7) % 65521; c := r[1 + x % (n-2)];
  end if;
  return array[a, b, c];
end $$;

create or replace function public.toupie(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j record; k int; b jsonb;
begin
  if interne.aujourdhui() >= date '2026-10-29' then raise exception 'jeu_retire'; end if;
  select * into j from interne.jeu_chance(qui, 'toupie', payer, 15);
  k := interne.roue_tirage();
  b := interne.roue_verser(qui, k, j.lie, 'toupie', payer);
  return jsonb_build_object('eco', interne.etat(qui), 'case', k, 'bille', b, 'achetees', j.achetees);
end $$;

revoke all on function public.toupie(boolean) from public, anon;
grant execute on function public.toupie(boolean) to authenticated;
revoke all on all functions in schema interne from public, anon, authenticated;
