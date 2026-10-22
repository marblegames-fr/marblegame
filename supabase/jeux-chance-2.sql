-- Les nouveaux jeux de chance (22 octobre 2026) : les Gobelets, le Tiercé, la Toupie et la Pince remplacent le Tir, le Château et la Tic
-- (maquettes/maquette-jeux-chance-2.html). À installer APRÈS serveur.sql, chance.sql et cour.sql.
-- Comme les autres jeux de chance : une partie offerte par jour, puis 4 achetées à 15 bonbecs (interne.jeu_chance).
-- Tous tirent leurs lots dans la table de la Roue (interne.roue_cases) : au total, les mêmes chances qu'un tour de Roue
-- (sauf le Tiercé : 3 lots différents et rien pour le 4e, un peu moins généreux que la Roue).

-- un lot tiré comme à la Roue : renvoie le numéro de la case (ROUE dans index.html, même ordre)
create or replace function interne.roue_tirage() returns int language plpgsql volatile as $$
declare x numeric; acc numeric := 0; c record;
begin
  x := random() * (select sum(poids) from interne.roue_cases());
  for c in select * from interne.roue_cases() order by k loop
    acc := acc + c.poids; if x < acc then return c.k; end if;
  end loop;
  return 1;
end $$;

-- verser le lot d'une case : bonbecs, sachet, ou un Mammouth (renvoyé, pour la roulette) ; la partie offerte note ses bonbecs dans gains
create or replace function interne.roue_verser(qui uuid, p_k int, lie boolean, jeu text, payer boolean) returns jsonb language plpgsql as $$
declare c record; b jsonb := null;
begin
  select * into c from interne.roue_cases() r where r.k = p_k;
  if lie then perform interne.crediter_lie(qui, c.bonbecs, c.sac); else perform interne.crediter(qui, c.bonbecs, c.sac); end if;
  if not payer and c.bonbecs > 0 then
    update gains set montant = c.bonbecs where joueur = qui and source = 'jeu' and cle = interne.aujourdhui()::text || '|' || jeu;
  end if;
  if c.taille = 'mammouth' then
    b := interne.nouvelle_bille(qui, 'mammouth', shiny => interne.tirer_shiny(interne.taux_shiny() * 10), src => jeu, liee => lie);
  end if;
  return b;
end $$;

-- ---------- Les Gobelets : 3 lots tous différents (tirés comme à la Roue), un sous chaque gobelet ; le joueur en gagne un (1 chance sur 3) ----------
-- (22 octobre 2026, le soir) tous différents, comme au Tiercé : un peu plus généreux que la Roue (≈ 23 bonbecs en moyenne au lieu de 19, Mammouth 0,28 %)
-- La page montre les 3 lots, mélange les gobelets (le vrai mélange est caché dans un nuage de fumée) et met le lot gagné
-- sous le gobelet touché : savoir lequel est gagné d'avance n'aide en rien, le choix du gobelet ne change pas le lot.
create or replace function public.gobelets(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j record; l int[] := '{}'; sig text[] := '{}'; kk int; s text; g int; b jsonb; n int := 0;
begin
  select * into j from interne.jeu_chance(qui, 'gobelets', payer, 15);
  while coalesce(array_length(l, 1), 0) < 3 and n < 200 loop
    n := n + 1; kk := interne.roue_tirage();
    select coalesce(r.bonbecs, 0) || '|' || coalesce(r.sac, '') || '|' || coalesce(r.taille, '') into s from interne.roue_cases() r where r.k = kk;
    if not (s = any(sig)) then l := l || kk; sig := sig || s; end if;
  end loop;
  g := floor(random() * 3)::int;
  b := interne.roue_verser(qui, l[g+1], j.lie, 'gobelets', payer);
  return jsonb_build_object('eco', interne.etat(qui), 'lots', to_jsonb(l), 'gagne', g, 'case', l[g+1], 'bille', b, 'achetees', j.achetees);
end $$;

-- ---------- Le Tiercé : 3 lots tous différents (tirés comme à la Roue) sur le podium, rien pour le 4e ; la place : 1 chance sur 4 ----------
-- La page range les 3 lots du plus rare (1er) au moins rare (3e) ; gagne = l'indice du lot gagné dans « lots », 3 = 4e place (rien).
-- Un lot pris au hasard parmi les 3 revient au même qu'une place tirée au hasard (1 chance sur 4 pour chaque place).
create or replace function public.tierce(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j record; l int[] := '{}'; sig text[] := '{}'; kk int; s text; g int; b jsonb := null; n int := 0;
begin
  select * into j from interne.jeu_chance(qui, 'tierce', payer, 15);
  while coalesce(array_length(l, 1), 0) < 3 and n < 200 loop
    n := n + 1; kk := interne.roue_tirage();
    select coalesce(r.bonbecs, 0) || '|' || coalesce(r.sac, '') || '|' || coalesce(r.taille, '') into s from interne.roue_cases() r where r.k = kk;
    if not (s = any(sig)) then l := l || kk; sig := sig || s; end if;
  end loop;
  g := floor(random() * 4)::int;
  if g < 3 then b := interne.roue_verser(qui, l[g+1], j.lie, 'tierce', payer); end if;
  return jsonb_build_object('eco', interne.etat(qui), 'lots', to_jsonb(l), 'gagne', g, 'case', case when g < 3 then l[g+1] end, 'bille', b, 'achetees', j.achetees);
end $$;

-- ---------- La Toupie : un lot tiré comme à la Roue ; la toupie est lancée pour finir dans sa zone ----------
create or replace function public.toupie(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j record; k int; b jsonb;
begin
  select * into j from interne.jeu_chance(qui, 'toupie', payer, 15);
  k := interne.roue_tirage();
  b := interne.roue_verser(qui, k, j.lie, 'toupie', payer);
  return jsonb_build_object('eco', interne.etat(qui), 'case', k, 'bille', b, 'achetees', j.achetees);
end $$;

-- ---------- La Pince : une machine de 24 boules transparentes, chacune tirée comme à la Roue ----------
-- Chaque joueur a sa machine (on voit ce qu'il y a dans chaque boule). La machine choisit une boule au hasard (1 chance sur 24) :
-- la pince l'attrape à coup sûr, et une boule neuve (tirée comme à la Roue) la remplace.
create table if not exists public.pince_machines (
  joueur  uuid primary key references auth.users(id) on delete cascade,
  boules  int[] not null,
  maj     timestamptz not null default now()
);
alter table public.pince_machines enable row level security;

create or replace function interne.pince_remplir(qui uuid) returns int[] language plpgsql as $$
declare m int[];
begin
  select boules into m from pince_machines where joueur = qui for update;
  if m is null or coalesce(array_length(m, 1), 0) <> 24 then
    select array_agg(interne.roue_tirage()) into m from generate_series(1, 24);
    insert into pince_machines (joueur, boules) values (qui, m) on conflict (joueur) do update set boules = excluded.boules, maj = now();
  end if;
  return m;
end $$;

create or replace function public.pince_etat()
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi();
begin
  return jsonb_build_object('boules', to_jsonb(interne.pince_remplir(qui)));
end $$;

create or replace function public.pince(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j record; m int[]; i int; k int; neuve int; b jsonb;
begin
  select * into j from interne.jeu_chance(qui, 'pince', payer, 15);
  m := interne.pince_remplir(qui);
  i := 1 + floor(random() * 24)::int; k := m[i];
  neuve := interne.roue_tirage(); m[i] := neuve;
  update pince_machines set boules = m, maj = now() where joueur = qui;
  b := interne.roue_verser(qui, k, j.lie, 'pince', payer);
  return jsonb_build_object('eco', interne.etat(qui), 'boule', i - 1, 'case', k, 'neuve', neuve, 'bille', b, 'achetees', j.achetees);
end $$;

-- ---------- Les 3 jeux du jour (serveur.sql) ----------
-- Jusqu'au 22 octobre 2026 : 8 jeux, toujours un jeu d'adresse en premier. Le 22 octobre au soir, les Gobelets, le Tiercé et la Toupie
-- prennent la place du Tir, du Château et de la Tic, à la même position (les jeux du jour tirés ce jour-là ne changent pas de place).
-- À partir du 23 octobre 2026 : 9 jeux (avec la Pince), tous au même rang. Même calcul que jeuxDuJour dans index.html.
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
    tous := array['gobelets','marelle','tierce','toupie','pince','roue','pachinko','grattage','distributeur']; n := 9;
    x := (x * x + 7) % 65521; x := (x * x + 7) % 65521; a := tous[1 + x % n];
    r := array_remove(tous, a);  x := (x * x + 7) % 65521; b := r[1 + x % (n-1)];
    r := array_remove(r, b);     x := (x * x + 7) % 65521; c := r[1 + x % (n-2)];
  end if;
  return array[a, b, c];
end $$;

-- Mes statistiques : les parties des nouveaux jeux sont comptées dans public.cour_stats (cour.sql)

-- les droits, comme les autres jeux de chance
do $$
declare f text;
begin
  foreach f in array array['gobelets(boolean)','tierce(boolean)','toupie(boolean)','pince(boolean)','pince_etat()'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
