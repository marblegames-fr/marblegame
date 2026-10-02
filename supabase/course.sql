-- =====================================================================
--  BILLY : la Grande Course de 20 h
--  À installer après serveur.sql (Supabase > SQL Editor > Run). On peut le relancer sans risque.
--
--  - On s'inscrit soi-même, quand on veut dans la journée, avec la bille de son choix (juste pour le look).
--    Jusqu'à 19 h 59 (heure de Paris) : course du soir même. Après : course du lendemain.
--  - À 20 h, l'ordre d'arrivée est tiré au sort par le serveur : chaque bille a exactement la même chance.
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

-- la course pour laquelle on s'inscrit maintenant : ce soir avant 19 h 59, sinon demain
create or replace function interne.course_jour(quand timestamptz default now()) returns date language sql stable as $$
  select case when (quand at time zone 'Europe/Paris')::time < time '19:59' then (quand at time zone 'Europe/Paris')::date
              else (quand at time zone 'Europe/Paris')::date + 1 end
$$;
-- l'heure du départ d'une course
create or replace function interne.course_depart(j date) returns timestamptz language sql stable as $$
  select (j + time '20:00') at time zone 'Europe/Paris'
$$;
-- prix : 1er, 2e, 3e, puis la participation (les billes de la cour, ajoutées s'il y a moins de 8 coureurs, ne gagnent rien)
create or replace function interne.course_prix(rang int, out j int, out sac text) language sql immutable as $$
  select case rang when 1 then 500 when 2 then 300 when 3 then 200 else 50 end, case rang when 1 then 'premium' end
$$;

-- tirage d'une course (une seule fois) : ordre au hasard, prix versés
create or replace function interne.course_tirer(j date) returns void language plpgsql security definer set search_path = public as $$
declare g bigint := floor(random()*4294967296)::bigint; res jsonb := '[]'; r record; k int := 0; n int; p record;
        noms text[] := array['Lulu','Noé','Inès','Malo','Zoé','Tom','Léa','Sacha','Jade','Hugo','Mila','Nino'];
begin
  perform pg_advisory_xact_lock(hashtext('course-' || j::text));
  if exists (select 1 from courses where jour = j) then return; end if;
  select count(*) into n from course_inscrits where jour = j;
  if n = 0 then return; end if;
  -- les coureurs dans un ordre tiré au sort ; des billes de la cour complètent jusqu'à 8
  for r in
    select * from (
      select i.joueur, pr.pseudo, b.donnees || jsonb_build_object('id', b.id) as bille, null::text as nom, null::bigint as gb
        from course_inscrits i join profils pr on pr.id = i.joueur
        left join billes b on b.id = i.bille and b.proprietaire = i.joueur and b.detruite_le is null
        where i.jour = j
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
  insert into courses (jour, graine, resultats) values (j, g, res);
end $$;

-- s'inscrire (ou changer de bille) pour la prochaine course
create or replace function public.course_inscrire(bid uuid default null) returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j date := interne.course_jour();
begin
  if bid is not null and not exists (select 1 from billes where id = bid and proprietaire = qui and detruite_le is null) then raise exception 'bille_invalide'; end if;
  insert into course_inscrits (jour, joueur, bille) values (j, qui, bid)
    on conflict (jour, joueur) do update set bille = excluded.bille;
  return public.course_etat();
end $$;
create or replace function public.course_desinscrire() returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi();
begin
  delete from course_inscrits where jour = interne.course_jour() and joueur = qui;
  return public.course_etat();
end $$;

-- tout ce que la page a besoin de savoir : la prochaine course, mon inscription, la dernière course courue
create or replace function public.course_etat() returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); j date := interne.course_jour(); d date; c courses; i course_inscrits;
begin
  -- les courses passées pas encore tirées (personne ne s'est connecté depuis 20 h) : on les tire maintenant
  for d in select distinct ci.jour from course_inscrits ci where interne.course_depart(ci.jour) <= now()
             and not exists (select 1 from courses x where x.jour = ci.jour) order by 1 loop
    perform interne.course_tirer(d);
  end loop;
  select * into i from course_inscrits where jour = j and joueur = qui;
  select * into c from courses where tiree_le is not null and interne.course_depart(jour) <= now() order by jour desc limit 1;
  return jsonb_build_object(
    'jour', j, 'depart', floor(extract(epoch from interne.course_depart(j))*1000)::bigint,
    'inscrits', (select count(*) from course_inscrits where jour = j),
    'inscrit', i.joueur is not null, 'bille', i.bille,
    'derniere', case when c.jour is null then null else jsonb_build_object('jour', c.jour, 'graine', c.graine,
      'lots', exists (select 1 from course_inscrits x where x.jour = c.jour and x.joueur = qui and x.lots_le is not null),
      'depart', floor(extract(epoch from interne.course_depart(c.jour))*1000)::bigint, 'resultats', c.resultats) end);
end $$;

-- les lots, remis à la fin de la course (une seule fois)
create or replace function public.course_lots(j date) returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); x jsonb;
begin
  select e into x from courses c, jsonb_array_elements(c.resultats) e where c.jour = j and e->>'joueur' = qui::text;
  if x is null then raise exception 'pas_inscrit'; end if;
  update course_inscrits set lots_le = now() where jour = j and joueur = qui and lots_le is null;
  if not found then raise exception 'deja'; end if;
  perform interne.crediter(qui, (x->>'prix')::int, x->>'sac');
  return interne.etat(qui);
end $$;

do $$ declare f text; begin
  foreach f in array array['course_inscrire(uuid)','course_desinscrire()','course_etat()','course_lots(date)'] loop
    execute format('revoke all on function public.%s from public, anon', f);
    execute format('grant execute on function public.%s to authenticated', f);
  end loop;
end $$;
revoke all on all functions in schema interne from public, anon, authenticated;
