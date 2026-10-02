-- =====================================================================
--  BILLY : la Grande Course (12 h et 20 h)
--  À installer après serveur.sql (Supabase > SQL Editor > Run). On peut le relancer sans risque.
--
--  - On s'inscrit soi-même, quand on veut dans la journée, avec la bille de son choix (juste pour le look).
--    Deux courses par jour (2 octobre 2026) : 12 h et 20 h (heure de Paris). On s'inscrit pour la prochaine :
--    jusqu'à 11 h 59 celle de midi, jusqu'à 19 h 59 celle du soir, après celle de midi le lendemain.
--  - Au départ, l'ordre d'arrivée est tiré au sort par le serveur : chaque bille a exactement la même chance.
--  - Le site ne montre que la dernière course de midi et la dernière du soir ; les lots pas récupérés d'une course
--    plus ancienne sont versés automatiquement (course_etat).
--    Le tirage se fait au premier appel après 20 h (n'importe quel joueur), une seule fois.
--  - Le jeu ne fait qu'animer la course à partir de la graine et de l'ordre d'arrivée : tout le monde voit la même.
--  - Les lots sont remis à la fin de la course, quand le joueur la regarde (ou la passe) : course_lots().
--    Mêmes valeurs que COURSE_PRIX dans index.html.
-- =====================================================================

create table if not exists public.course_inscrits (
  jour       date not null,
  joueur     uuid not null references auth.users(id) on delete cascade,
  bille      uuid references public.billes(id) on delete set null,
  inscrit_le timestamptz not null default now(),
  primary key (jour, joueur)
);
create table if not exists public.courses (
  jour      date primary key,
  graine    bigint not null,
  tiree_le  timestamptz not null default now(),
  resultats jsonb not null   -- dans l'ordre d'arrivée : [{joueur, pseudo, bille, prix, sac} | {bot, nom, graine}]
);
alter table public.course_inscrits add column if not exists lots_le timestamptz;   -- lots récupérés
alter table public.course_inscrits enable row level security;
alter table public.courses enable row level security;
revoke all on public.course_inscrits, public.courses from anon, authenticated;

-- deux courses par jour : une colonne heure (12 ou 20) ; les lignes d'avant sont des courses de 20 h
alter table public.course_inscrits add column if not exists heure smallint not null default 20;
alter table public.courses add column if not exists heure smallint not null default 20;
do $$ begin
  if (select pg_get_constraintdef(oid) from pg_constraint where conname = 'course_inscrits_pkey') = 'PRIMARY KEY (jour, joueur)' then
    alter table public.course_inscrits drop constraint course_inscrits_pkey;
    alter table public.course_inscrits add primary key (jour, heure, joueur);
  end if;
  if (select pg_get_constraintdef(oid) from pg_constraint where conname = 'courses_pkey') = 'PRIMARY KEY (jour)' then
    alter table public.courses drop constraint courses_pkey;
    alter table public.courses add primary key (jour, heure);
  end if;
end $$;
drop function if exists interne.course_jour(timestamptz);
drop function if exists interne.course_depart(date);
drop function if exists interne.course_tirer(date);
drop function if exists public.course_lots(date);

-- la course pour laquelle on s'inscrit maintenant : midi (avant 11 h 59), le soir (avant 19 h 59), sinon midi le lendemain
create or replace function interne.course_suivante(quand timestamptz default now(), out jour date, out heure int) language sql stable as $$
  select case when t < time '19:59' then d else d + 1 end, case when t < time '11:59' or t >= time '19:59' then 12 else 20 end
  from (select (quand at time zone 'Europe/Paris')::time t, (quand at time zone 'Europe/Paris')::date d) x
$$;
-- l'heure du départ d'une course
create or replace function interne.course_depart(j date, h int) returns timestamptz language sql stable as $$
  select (j + make_time(h, 0, 0)) at time zone 'Europe/Paris'
$$;
-- prix : 1er, 2e, 3e (bonbecs + un sachet), puis la participation (les billes de la cour, ajoutées s'il y a moins de 8 coureurs, ne gagnent rien)
-- Sachets (2 octobre 2026) : Collector au 1er, Premium au 2e, Classique au 3e. Mêmes valeurs que COURSE_PRIX dans index.html.
create or replace function interne.course_prix(rang int, out j int, out sac text) language sql immutable as $$
  select case rang when 1 then 500 when 2 then 300 when 3 then 200 else 50 end,
         case rang when 1 then 'collector' when 2 then 'premium' when 3 then 'classique' end
$$;

-- tirage d'une course (une seule fois) : ordre au hasard
create or replace function interne.course_tirer(j date, h int) returns void language plpgsql security definer set search_path = public as $$
declare g bigint := floor(random()*4294967296)::bigint; res jsonb := '[]'; r record; k int := 0; n int; p record;
        noms text[] := array['Lulu','Noé','Inès','Malo','Zoé','Tom','Léa','Sacha','Jade','Hugo','Mila','Nino'];
begin
  perform pg_advisory_xact_lock(hashtext('course-' || j::text || '-' || h));
  if exists (select 1 from courses where jour = j and heure = h) then return; end if;
  select count(*) into n from course_inscrits where jour = j and heure = h;
  if n = 0 then return; end if;
  -- les coureurs dans un ordre tiré au sort ; des billes de la cour complètent jusqu'à 8
  for r in
    select * from (
      select i.joueur, pr.pseudo, b.donnees || jsonb_build_object('id', b.id) as bille, null::text as nom, null::bigint as gb
        from course_inscrits i join profils pr on pr.id = i.joueur
        left join billes b on b.id = i.bille and b.proprietaire = i.joueur and b.detruite_le is null
        where i.jour = j and i.heure = h
      union all
      select null, null, null, noms[1 + (x % 12)], floor(random()*4294967296)::bigint from generate_series(1, greatest(0, 8 - n)) x
    ) t order by random()
  loop
    k := k + 1;
    if r.joueur is null then
      res := res || jsonb_build_array(jsonb_build_object('bot', true, 'nom', r.nom, 'graine', r.gb));
    else
      select * into p from interne.course_prix(k);
      res := res || jsonb_build_array(jsonb_build_object('joueur', r.joueur, 'pseudo', r.pseudo, 'bille', r.bille, 'prix', p.j, 'sac', p.sac));
    end if;
  end loop;
  insert into courses (jour, heure, graine, resultats) values (j, h, g, res);
end $$;

-- s'inscrire (ou changer de bille) pour la prochaine course
create or replace function public.course_inscrire(bid uuid default null) returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); c record;
begin
  select * into c from interne.course_suivante();
  if bid is not null and not exists (select 1 from billes where id = bid and proprietaire = qui and detruite_le is null) then raise exception 'bille_invalide'; end if;
  insert into course_inscrits (jour, heure, joueur, bille) values (c.jour, c.heure, qui, bid)
    on conflict (jour, heure, joueur) do update set bille = excluded.bille;
  return public.course_etat();
end $$;
create or replace function public.course_desinscrire() returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); c record;
begin
  select * into c from interne.course_suivante();
  delete from course_inscrits where jour = c.jour and heure = c.heure and joueur = qui;
  return public.course_etat();
end $$;

-- une course pour la page : ses résultats et si mes lots sont déjà récupérés
create or replace function interne.course_json(c courses, qui uuid) returns jsonb language sql stable as $$
  select jsonb_build_object('jour', c.jour, 'heure', c.heure, 'graine', c.graine,
    'lots', exists (select 1 from course_inscrits x where x.jour = c.jour and x.heure = c.heure and x.joueur = qui and x.lots_le is not null),
    'depart', floor(extract(epoch from interne.course_depart(c.jour, c.heure))*1000)::bigint, 'resultats', c.resultats)
$$;

-- tout ce que la page a besoin de savoir : la prochaine course, mon inscription, la dernière course de midi et celle du soir
create or replace function public.course_etat() returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); n record; d record; c courses; c12 courses; c20 courses; i course_inscrits; x jsonb;
begin
  select * into n from interne.course_suivante();
  -- les courses passées pas encore tirées (personne ne s'est connecté depuis le départ) : on les tire maintenant
  for d in select distinct ci.jour, ci.heure from course_inscrits ci where interne.course_depart(ci.jour, ci.heure) <= now()
             and not exists (select 1 from courses y where y.jour = ci.jour and y.heure = ci.heure) order by 1, 2 loop
    perform interne.course_tirer(d.jour, d.heure);
  end loop;
  select * into c12 from courses where heure = 12 and interne.course_depart(jour, heure) <= now() order by jour desc limit 1;
  select * into c20 from courses where heure = 20 and interne.course_depart(jour, heure) <= now() order by jour desc limit 1;
  -- une course plus ancienne n'est plus visible sur le site : mes lots pas encore récupérés sont versés tout de suite
  for c in select y.* from courses y join course_inscrits ci on ci.jour = y.jour and ci.heure = y.heure and ci.joueur = qui and ci.lots_le is null
            where not (y.jour = c12.jour and y.heure = 12) is true and not (y.jour = c20.jour and y.heure = 20) is true
              and interne.course_depart(y.jour, y.heure) <= now() loop
    select e into x from jsonb_array_elements(c.resultats) e where e->>'joueur' = qui::text;
    update course_inscrits set lots_le = now() where jour = c.jour and heure = c.heure and joueur = qui;
    if x is not null then perform interne.crediter(qui, (x->>'prix')::int, x->>'sac'); end if;
  end loop;
  select * into i from course_inscrits where jour = n.jour and heure = n.heure and joueur = qui;
  return jsonb_build_object(
    'jour', n.jour, 'heure', n.heure, 'depart', floor(extract(epoch from interne.course_depart(n.jour, n.heure))*1000)::bigint,
    'inscrits', (select count(*) from course_inscrits where jour = n.jour and heure = n.heure),
    'inscrit', i.joueur is not null, 'bille', i.bille,
    -- les inscrits de la prochaine course (pseudo et bille choisie), dans l'ordre d'inscription
    'participants', (select coalesce(jsonb_agg(jsonb_build_object('pseudo', pr.pseudo, 'moi', ci.joueur = qui, 'bille', b.donnees) order by ci.inscrit_le), '[]'::jsonb)
      from course_inscrits ci join profils pr on pr.id = ci.joueur
      left join billes b on b.id = ci.bille and b.proprietaire = ci.joueur and b.detruite_le is null
      where ci.jour = n.jour and ci.heure = n.heure),
    -- la plus récente des deux, et les deux rediffusions (midi, soir)
    'derniere', case when c12.jour is null and c20.jour is null then null
      when c20.jour is null or (c12.jour is not null and interne.course_depart(c12.jour, 12) > interne.course_depart(c20.jour, 20)) then interne.course_json(c12, qui)
      else interne.course_json(c20, qui) end,
    'rediffs', jsonb_build_object('12', case when c12.jour is null then null else interne.course_json(c12, qui) end,
                                  '20', case when c20.jour is null then null else interne.course_json(c20, qui) end));
end $$;

-- les lots, remis à la fin de la course (une seule fois)
create or replace function public.course_lots(j date, h int default 20) returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); x jsonb;
begin
  select e into x from courses c, jsonb_array_elements(c.resultats) e where c.jour = j and c.heure = h and e->>'joueur' = qui::text;
  if x is null then raise exception 'pas_inscrit'; end if;
  update course_inscrits set lots_le = now() where jour = j and heure = h and joueur = qui and lots_le is null;
  if not found then raise exception 'deja'; end if;
  perform interne.crediter(qui, (x->>'prix')::int, x->>'sac');
  return interne.etat(qui);
end $$;

do $$ declare f text; begin
  foreach f in array array['course_inscrire(uuid)','course_desinscrire()','course_etat()','course_lots(date,int)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
