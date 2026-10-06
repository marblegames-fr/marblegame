-- Les jeux de hasard (6 octobre 2026) : la Roue, le Ticket à gratter, le Distributeur de billes, et la Loterie de la semaine.
-- À installer APRÈS serveur.sql (il s'appuie sur interne.payer, interne.crediter, interne.nouvelle_bille, gains…).
-- Règle commune (choix de l'équipe) : une partie offerte par jour, puis 2 achetées au plus (le Plinko suit la même règle dans serveur.sql).
-- Mêmes valeurs dans index.html (CHANCE, ROUE, GRAT).

-- une partie : offerte (gains 'jeu' today|jeu) ou achetée (gains jeu today|n, 2 au plus) ; renvoie « liée » si payée avec des bonbecs de départ
create or replace function interne.jeu_chance(qui uuid, jeu text, payer boolean, prix int, out lie boolean, out achetees int)
language plpgsql as $$
declare today text := interne.aujourdhui()::text;
begin
  lie := false; achetees := null;
  perform 1 from portefeuilles where joueur = qui for update;
  if not payer then
    begin insert into gains (joueur, source, cle, montant) values (qui, 'jeu', today || '|' || jeu, 0);
    exception when unique_violation then raise exception 'deja'; end;
  else
    select count(*) into achetees from gains g where g.joueur = qui and g.source = jeu and g.cle like today || '|%';
    if achetees >= 2 then raise exception 'limite_jeu'; end if;
    lie := interne.payer(qui, prix);
    achetees := achetees + 1;
    insert into gains (joueur, source, cle) values (qui, jeu, today || '|' || achetees);
  end if;
end $$;

-- ---------- La Roue : offerte, ou 15 bonbecs le tour (parts dans interne.roue_cases, serveur.sql) ----------
drop function if exists public.roue();
create or replace function public.roue(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); today text := interne.aujourdhui()::text; c record; b jsonb := null; x numeric; acc numeric := 0; j record;
begin
  select * into j from interne.jeu_chance(qui, 'roue', payer, 15);
  x := random() * (select sum(poids) from interne.roue_cases());
  for c in select * from interne.roue_cases() order by k loop
    acc := acc + c.poids; exit when x < acc;
  end loop;
  if j.lie then perform interne.crediter_lie(qui, c.bonbecs, c.sac); else perform interne.crediter(qui, c.bonbecs, c.sac); end if;
  if not payer and c.bonbecs > 0 then update gains set montant = c.bonbecs where joueur = qui and source = 'jeu' and cle = today || '|roue'; end if;
  if c.taille = 'mammouth' then
    b := interne.nouvelle_bille(qui, 'mammouth', shiny => interne.tirer_shiny(interne.taux_shiny() * 10), src => 'roue', liee => j.lie);
  end if;
  return jsonb_build_object('eco', interne.etat(qui), 'case', c.k, 'bonbecs', c.bonbecs, 'sac', c.sac, 'bille', b, 'achetees', j.achetees);
end $$;

-- ---------- Le Ticket à gratter : offert, ou 15 bonbecs ; 3 dessins pareils = le lot ----------
-- (6 octobre 2026, le soir) mêmes lots et mêmes chances que la Roue (interne.roue_cases), Mammouth compris : on gagne toujours quelque chose
drop function if exists interne.grattage_lots();
create or replace function public.grattage(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); c record; x numeric; acc numeric := 0; j record; b jsonb := null;
begin
  select * into j from interne.jeu_chance(qui, 'grattage', payer, 15);
  x := random() * (select sum(poids) from interne.roue_cases());
  for c in select * from interne.roue_cases() order by k loop
    acc := acc + c.poids; exit when x < acc;
  end loop;
  if j.lie then perform interne.crediter_lie(qui, c.bonbecs, c.sac); else perform interne.crediter(qui, c.bonbecs, c.sac); end if;
  if c.taille = 'mammouth' then
    b := interne.nouvelle_bille(qui, 'mammouth', shiny => interne.tirer_shiny(interne.taux_shiny() * 10), src => 'grattage', liee => j.lie);
  end if;
  return jsonb_build_object('eco', interne.etat(qui), 'case', c.k, 'bonbecs', c.bonbecs, 'sac', c.sac, 'bille', b, 'achetees', j.achetees);
end $$;

-- ---------- Le Distributeur de billes : offert, ou 15 bonbecs ; toujours une bille ----------
-- sa taille comme la vedette du sachet gratuit (Mini 30, Bille 33, Chinoise 20, Calot 12, Boulet 4, Mammouth 1), shiny au taux de base
create or replace function public.distributeur(payer boolean default false)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j record; t text; b jsonb;
begin
  select * into j from interne.jeu_chance(qui, 'distributeur', payer, 15);
  t := (interne.tailles())[interne.tirer(array[30,33,20,12,4,1]::numeric[])];
  b := interne.nouvelle_bille(qui, t, shiny => interne.tirer_shiny(interne.taux_shiny()), src => 'distributeur', liee => j.lie);
  return jsonb_build_object('eco', interne.etat(qui), 'bille', b, 'achetees', j.achetees);
end $$;

-- ---------- La Loterie de la semaine ----------
-- Un ticket gratuit par jour (3 numéros différents de 1 à 20, au hasard). Tirage le dimanche à 20 h (heure de Paris) : 3 numéros.
-- 3 bons : un Mammouth + 100 bonbecs ; 2 bons : un Sachet Premium ; 1 bon : 5 bonbecs. Le tirage et les lots se font « à la demande » :
-- le premier qui ouvre la page après 20 h fait le tirage, et chacun reçoit ses lots en ouvrant la page.
create table if not exists public.loterie_tickets (
  id       bigint generated always as identity primary key,
  joueur   uuid not null references auth.users(id) on delete cascade,
  tirage   date not null,                 -- le dimanche du tirage
  numeros  int[] not null,
  le       timestamptz not null default now(),
  bons     int,                           -- rempli au tirage
  credite  boolean not null default false
);
create index if not exists loterie_tickets_joueur on public.loterie_tickets (joueur, tirage);
create index if not exists loterie_tickets_tirage on public.loterie_tickets (tirage);
create table if not exists public.loterie_tirages (
  tirage   date primary key,
  numeros  int[] not null,
  le       timestamptz not null default now()
);
alter table public.loterie_tickets enable row level security;
alter table public.loterie_tirages enable row level security;

create or replace function interne.loterie_heure(d date) returns timestamptz language sql immutable as
$$ select (d + time '20:00') at time zone 'Europe/Paris' $$;
-- le prochain tirage : ce dimanche à 20 h, ou le suivant s'il est passé
create or replace function interne.loterie_prochain() returns date language sql stable as $$
  select case when interne.loterie_heure(d) > now() then d else d + 7 end
  from (select l::date + (7 - extract(isodow from l)::int) % 7 d from (select now() at time zone 'Europe/Paris' l) x) y
$$;
create or replace function interne.loterie_lot(bons int) returns text language sql immutable as $$
  select case bons when 3 then 'mammouth' when 2 then 'premium' when 1 then 'bonbecs' end
$$;

-- fait les tirages en retard, puis paie les tickets gagnants de ce joueur ; renvoie ce qui vient d'être gagné
create or replace function interne.loterie_regler(qui uuid) returns jsonb language plpgsql as $$
declare d date; t record; out jsonb := '[]'; b jsonb;
begin
  for d in select distinct k.tirage from loterie_tickets k
           where interne.loterie_heure(k.tirage) <= now() and not exists (select 1 from loterie_tirages x where x.tirage = k.tirage) loop
    insert into loterie_tirages (tirage, numeros)
      values (d, array(select g from (select g from generate_series(1, 20) g order by random() limit 3) x order by g)) on conflict (tirage) do nothing;
    update loterie_tickets k set bons = (select count(*) from unnest(k.numeros) n where n = any(x.numeros))
      from loterie_tirages x where x.tirage = d and k.tirage = d and k.bons is null;
  end loop;
  for t in select k.* from loterie_tickets k where k.joueur = qui and k.bons is not null and not k.credite order by k.tirage, k.id for update loop
    update loterie_tickets set credite = true where id = t.id;
    b := null;
    if t.bons = 3 then
      perform interne.crediter(qui, 100, null);
      b := interne.nouvelle_bille(qui, 'mammouth', shiny => interne.tirer_shiny(interne.taux_shiny() * 10), src => 'loterie');
    elsif t.bons = 2 then perform interne.crediter(qui, 0, 'premium');
    elsif t.bons = 1 then perform interne.crediter(qui, 5, null);
    end if;
    if t.bons > 0 then out := out || jsonb_build_object('tirage', t.tirage, 'numeros', t.numeros, 'bons', t.bons, 'lot', interne.loterie_lot(t.bons), 'bille', b); end if;
  end loop;
  return out;
end $$;

create or replace function public.loterie_etat()
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); p date := interne.loterie_prochain(); gagne jsonb; der record;
begin
  perform 1 from portefeuilles where joueur = qui for update;
  gagne := interne.loterie_regler(qui);
  select * into der from loterie_tirages order by tirage desc limit 1;
  return jsonb_build_object(
    'eco', interne.etat(qui),
    'prochain', p, 'heure', floor(extract(epoch from interne.loterie_heure(p))*1000)::bigint,
    'en_jeu', (select count(*) from loterie_tickets where tirage = p),
    'mes', coalesce((select jsonb_agg(k.numeros order by k.id) from loterie_tickets k where k.joueur = qui and k.tirage = p), '[]'),
    'aujourdhui', exists (select 1 from gains g where g.joueur = qui and g.source = 'loterie' and g.cle = interne.aujourdhui()::text),
    'dernier', case when der.tirage is null then null else jsonb_build_object('tirage', der.tirage, 'numeros', der.numeros,
      'mes', coalesce((select jsonb_agg(jsonb_build_object('numeros', k.numeros, 'bons', k.bons) order by k.bons desc, k.id) from loterie_tickets k where k.joueur = qui and k.tirage = der.tirage), '[]'),
      'gagnants', (select count(*) from loterie_tickets k where k.tirage = der.tirage and k.bons >= 2)) end,
    'gagne', gagne);
end $$;

-- le ticket gratuit du jour
create or replace function public.loterie_ticket()
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); nums int[];
begin
  begin insert into gains (joueur, source, cle) values (qui, 'loterie', interne.aujourdhui()::text);
  exception when unique_violation then raise exception 'deja'; end;
  nums := array(select g from (select g from generate_series(1, 20) g order by random() limit 3) x order by g);
  insert into loterie_tickets (joueur, tirage, numeros) values (qui, interne.loterie_prochain(), nums);
  return public.loterie_etat() || jsonb_build_object('nouveau', nums);
end $$;

do $$ declare f text; begin
  foreach f in array array['roue(boolean)','grattage(boolean)','distributeur(boolean)','loterie_etat()','loterie_ticket()'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
