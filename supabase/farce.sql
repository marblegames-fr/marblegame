-- =====================================================================
--  TIKALO : une farce de l'équipe (18 novembre 2026)
--  À installer après messages.sql et atelier.sql (ouvrir_sac ci-dessous = celle de l'atelier + la farce).
--
--  On arme une farce pour un joueur (insert dans interne.farces) : la vedette de son prochain sachet (n'importe lequel)
--  est une fausse mythique. Elle est rangée avec les billes spéciales (secrete = 'farce') : ni troc, ni marché,
--  ni recyclage, ni fusion, ni classement, ni trouvailles, ni annonce des mythiques, ni succès. Rien ne compte.
--  Quelques minutes après (delai), un message arrive : le jeu joue la révélation « FAKE », la bille disparaît
--  (message_lu) et le Sachet Collector d'excuse est versé.
--    insert into interne.farces (joueur) values ('<uuid>');
-- =====================================================================

create table if not exists interne.farces (
  joueur   uuid primary key references auth.users(id) on delete cascade,
  taille   text not null default 'calot',
  decor    int  not null default 64,                 -- l'Œil du Dragon
  delai    interval not null default '3 minutes',    -- le temps d'y croire
  titre    text not null default 'Petite blague…',
  texte    text not null default 'Ta bille mythique était une fausse ! Pour te faire pardonner : un Sachet Collector.',
  bille    uuid,
  faite_le timestamptz,
  le       timestamptz not null default now()
);
revoke all on interne.farces from public, anon, authenticated;

alter table public.messages add column if not exists farce uuid;          -- la fausse bille à faire disparaître
alter table public.messages add column if not exists apres timestamptz;   -- pas montré avant

create or replace function public.messages_a_lire()
returns jsonb language sql stable security definer set search_path = public as $$
  select coalesce(jsonb_agg(jsonb_build_object('id', m.id, 'titre', m.titre, 'texte', m.texte, 'bonbecs', m.bonbecs, 'sac', m.sac)
      || case when m.farce is not null then jsonb_build_object('farce', m.farce,
           'bille', (select interne.bille_json(b) from billes b where b.id = m.farce)) else '{}' end order by m.id), '[]')
  from messages m where m.joueur = interne.moi() and m.lu_le is null and (m.apres is null or m.apres <= now()) $$;

create or replace function public.message_lu(mid bigint)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); m record;
begin
  update messages set lu_le = now() where id = mid and joueur = qui and lu_le is null returning * into m;
  if found then
    perform 1 from portefeuilles where joueur = qui for update;
    if m.farce is not null then
      update billes set detruite_le = now(), detruite_raison = 'farce' where id = m.farce and detruite_le is null;
    end if;
    if m.bonbecs > 0 or m.sac is not null then perform interne.crediter(qui, m.bonbecs, m.sac); end if;
  end if;
  return interne.etat(qui);
end $$;

revoke all on function public.messages_a_lire(), public.message_lu(bigint) from public, anon;
grant execute on function public.messages_a_lire(), public.message_lu(bigint) to authenticated;

-- le sachet (celui de atelier.sql, plus la farce)
CREATE OR REPLACE FUNCTION public.ouvrir_sac(nom text, offert boolean DEFAULT false, evenement boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $$
declare qui uuid := interne.moi(); p portefeuilles; r record; ev record; evc record; evb boolean; stock int; t int; i int; d int; c int;
        tirees int[] := '{}'; shinies int[] := '{}'; billes jsonb := '[]'; force boolean := false; lie boolean := false; ec boolean := false; fa record; b1 jsonb;
begin
  select * into r from interne.sac(nom);
  if r.n is null then raise exception 'sac_inconnu'; end if;
  select * into evc from interne.evenement_en_cours();
  select * into p from portefeuilles where joueur = qui for update;
  if offert then
    if coalesce((p.sacs->>nom)::int,0) < 1 then raise exception 'plus_de_sac'; end if;
    lie := coalesce((p.sacs_lies->>nom)::int,0) > 0;   -- un sachet gagné avec des bonbecs de départ
    update portefeuilles set sacs = jsonb_set(sacs, array[nom], to_jsonb((sacs->>nom)::int - 1)),
      sacs_lies = case when lie then jsonb_set(sacs_lies, array[nom], to_jsonb((sacs_lies->>nom)::int - 1)) else sacs_lies end
      where joueur = qui;
  elsif r.prix = 0 then
    stock := least(10, floor(extract(epoch from now() - p.gratuit_t0) / 600)::int);   -- jusqu'à 10 d'avance (FREE_MAX)
    if stock < 1 then raise exception 'pas_encore'; end if;
    lie := p.gratuits_lies > 0;   -- les sachets gratuits du cadeau de bienvenue
    update portefeuilles set gratuit_t0 = case when stock >= 10 then now() - interval '90 minutes' else gratuit_t0 + interval '10 minutes' end,
      gratuits_lies = greatest(gratuits_lies - 1, 0)
      where joueur = qui;
  else
    lie := interne.payer(qui, r.prix);
  end if;
  select * into fa from interne.farces f where f.joueur = qui and f.faite_le is null for update;
  -- les tailles
  for i in 1..r.n loop
    t := interne.tirer(array(select unnest(r.cotes[i:i][1:6]))) - 1;   -- les chances de la position i
    tirees := tirees || t;
    shinies := shinies || interne.tirer_shiny(r.shiny);
  end loop;
  -- garantie de la cour : un Boulet au plus tard tous les 10 sacs
  if p.pity + 1 >= 10 and not exists (select 1 from unnest(tirees) x where x >= 4) then
    tirees[r.n] := case when random() * (r.cotes[r.n][5] + r.cotes[r.n][6]) < r.cotes[r.n][6] then 5 else 4 end;
    force := true;
  end if;
  update portefeuilles set sacs_ouverts = sacs_ouverts + 1, maj_le = now(),
    pity = case when exists (select 1 from unnest(tirees) x where x >= 4) then 0 else pity + 1 end
    where joueur = qui;
  for i in 1..r.n loop
    d := null; c := null;
    -- pendant l'événement, si le joueur l'a choisi : une bille d'un sac Classique, Premium ou Collector peut être une bille
    -- d'événement (50 %), et la vedette l'est toujours
    if d is null and evc.decor is not null and evenement and interne.taux_evenement(nom) > 0 and (i = r.n or random() < interne.taux_evenement(nom)) then
      d := evc.decor; c := evc.coloris[1 + floor(random()*array_length(evc.coloris,1))::int];
    end if;
    -- (18 novembre 2026) une farce de l'équipe (supabase/farce.sql) : la vedette du prochain sachet est une fausse mythique
    if i = r.n and fa.joueur is not null then
      b1 := interne.nouvelle_bille(qui, fa.taille, decor => fa.decor, src => nom, secrete => 'farce', extra => jsonb_build_object('farce', true));
      update interne.farces set faite_le = now(), bille = (b1->>'id')::uuid where joueur = qui;
      insert into public.messages (joueur, titre, texte, sac, farce, apres)
        values (qui, fa.titre, fa.texte, 'collector', (b1->>'id')::uuid, now() + fa.delai);
      billes := billes || b1;
      continue;
    end if;
    billes := billes || interne.nouvelle_bille(qui, (interne.tailles())[tirees[i]+1], shiny => shinies[i], src => nom, decor => d, coloris => c, liee => lie);
  end loop;
  -- (27 octobre 2026) l'atelier du verrier : un éclat de verre dans 1 sachet sur 25, quel que soit le sachet
  if random() < interne.taux_eclat() then
    update portefeuilles set eclats = eclats + 1 where joueur = qui; ec := true;
  end if;
  return jsonb_build_object('eco', interne.etat(qui), 'billes', billes, 'force', force, 'eclat', ec);
end $$
;
