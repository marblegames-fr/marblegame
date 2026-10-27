-- L'atelier du verrier (27 octobre 2026, maquettes/maquette-atelier.html et maquette-eclat.html)
-- Des éclats de verre tombent dans 1 sachet sur 25 (n'importe lequel) ; à l'atelier, on les fond pour fabriquer une bille au choix :
-- une taille et un motif (commun à légendaire, jamais le mythique ni les motifs d'événement, de saison ou bêta), le coloris au hasard.
-- Prix : la taille × la rareté du motif (mêmes valeurs qu'ATELIER_BASE et ATELIER_MULT dans index.html).
-- La bille fabriquée compte au classement général comme une autre, mais pas au classement de la semaine (comme la fusion).

alter table public.portefeuilles add column if not exists eclats int not null default 0 check (eclats >= 0);

create or replace function interne.taux_eclat() returns numeric language sql immutable as $$ select 0.04 $$;   -- ECLAT_TAUX dans index.html
-- le prix d'une bille : la taille (mini 2, bille 3, chinoise 4, calot 5, boulet 7, mammouth 10) × la rareté du motif (1 ; 1,5 ; 2,5 ; 4 ; 9)
create or replace function interne.prix_atelier(taille text, rar int) returns int language sql immutable as $$
  select round((array[2,3,4,5,7,10])[interne.rang(taille)+1] * (array[1,1.5,2.5,4,9])[rar+1])::int
$$;

-- l'état du portefeuille : avec les éclats
create or replace function interne.etat(qui uuid)
 RETURNS jsonb
 LANGUAGE sql
 STABLE
AS $function$
  select jsonb_build_object('bonbecs', p.bonbecs, 'depart', least(p.depart, p.bonbecs), 'sacs', p.sacs,
    'gratuit_t0', floor(extract(epoch from p.gratuit_t0)*1000)::bigint, 'pity', p.pity, 'sacs_ouverts', p.sacs_ouverts,
    'serie', p.serie, 'serie_jour', p.serie_jour, 'eclats', p.eclats, 'testeur', exists (select 1 from public.testeurs t where t.joueur = qui))
  from public.portefeuilles p where p.joueur = qui
$function$;

-- l'ouverture d'un sachet : peut-être un éclat
create or replace function public.ouvrir_sac(nom text, offert boolean DEFAULT false, evenement boolean DEFAULT false)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare qui uuid := interne.moi(); p portefeuilles; r record; ev record; evc record; evb boolean; stock int; t int; i int; d int; c int;
        tirees int[] := '{}'; shinies int[] := '{}'; billes jsonb := '[]'; force boolean := false; lie boolean := false; ec boolean := false;
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
    billes := billes || interne.nouvelle_bille(qui, (interne.tailles())[tirees[i]+1], shiny => shinies[i], src => nom, decor => d, coloris => c, liee => lie);
  end loop;
  -- (27 octobre 2026) l'atelier du verrier : un éclat de verre dans 1 sachet sur 25, quel que soit le sachet
  if random() < interne.taux_eclat() then
    update portefeuilles set eclats = eclats + 1 where joueur = qui; ec := true;
  end if;
  return jsonb_build_object('eco', interne.etat(qui), 'billes', billes, 'force', force, 'eclat', ec);
end $function$;

-- le classement de la semaine : sans les billes de l'atelier
create or replace function interne.semaine_pts(d date)
 RETURNS TABLE(joueur uuid, pts integer, billes integer, nouvelles integer)
 LANGUAGE sql
 STABLE
AS $function$
  with wk0 as (   -- les billes arrivées dans la semaine : tirées (« trouvee »), ou (14 octobre 2026) reçues par troc ou achetées au marché
    select h.id hid, h.vers j, h.motif, h.le, b.taille, b.decor, b.coloris, b.shiny,
      round((interne.pts_taille())[interne.rang(b.taille)+1] * (interne.mult_decor())[(interne.decor_rarete())[b.decor+1]+1])::int v
    from public.billes_historique h join public.billes b on b.id = h.bille
    where h.motif in ('trouvee', 'echange', 'vente') and h.le >= interne.semaine_t(d) and h.le < interne.semaine_t(d + 7)
      and b.origine = 'serveur' and b.secrete is null and coalesce(b.donnees->>'src', '') not in ('test', 'fusion', 'atelier')   -- (27 octobre 2026) ni les billes de l'atelier du verrier
      and coalesce((interne.decor_rarete())[b.decor+1], 5) <> 5
      and h.vers not in (select t.joueur from public.testeurs t)
      and not interne.est_invite(h.vers)),   -- (26 octobre 2026) les invités ne sont pas classés (supabase/invite.sql)
  -- une bille reçue ou achetée ne compte que si c'est le premier exemplaire de ce modèle (taille, motif, coloris, shiny) arrivé chez le joueur
  wk as (select * from wk0 w where w.motif = 'trouvee' or not exists (
      select 1 from public.billes_historique h2 join public.billes b2 on b2.id = h2.bille
      where h2.vers = w.j and h2.motif in ('trouvee', 'echange', 'vente') and (h2.le, h2.id) < (w.le, w.hid)
        and b2.taille = w.taille and b2.decor = w.decor and b2.coloris = w.coloris and coalesce(b2.shiny, 0) = coalesce(w.shiny, 0))),
  -- la première bille de chaque case (taille + décor) arrivée chez le joueur, tirée ou reçue : c'est elle qui a rempli la case
  prem as (select distinct on (h.vers, b.taille, b.decor) h.id
    from public.billes_historique h join public.billes b on b.id = h.bille
    where h.motif in ('trouvee', 'echange', 'vente') and h.vers in (select distinct wk.j from wk)
      and b.origine = 'serveur' and b.secrete is null and coalesce(b.donnees->>'src', '') <> 'test'
    order by h.vers, b.taille, b.decor, h.le, h.id)
  -- (14 octobre 2026) le total est divisé par 10 : on compte aussi les doubles, sans ça la semaine affichait plus de points que le classement général
  select wk.j, round(sum(wk.v * case when p.id is null then 1 else 2 end
      + case when wk.shiny > 0 and interne.coloris_normal(wk.coloris) then (interne.pts_shiny())[wk.shiny] else 0 end) / 10.0)::int,
    count(*)::int, count(p.id)::int
  from wk left join prem p on p.id = wk.hid group by wk.j
$function$;

-- fabriquer une bille à l'atelier
create or replace function public.fabriquer(taille text, decor int)
returns jsonb language plpgsql security definer set search_path = public as $$
declare qui uuid := interne.moi(); rar int; prix int; p portefeuilles; b jsonb;
begin
  if not (taille = any(interne.tailles())) then raise exception 'taille_inconnue'; end if;
  rar := (interne.decor_rarete())[decor+1];
  if rar is null or rar not between 0 and 4 then raise exception 'motif_interdit'; end if;   -- 5 : événement, saison, bêta ; 6 : le mythique
  prix := interne.prix_atelier(taille, rar);
  select * into p from portefeuilles where joueur = qui for update;
  if p.eclats < prix then raise exception 'pas_assez_eclats'; end if;
  update portefeuilles set eclats = eclats - prix, maj_le = now() where joueur = qui;
  b := interne.nouvelle_bille(qui, taille, decor => decor, src => 'atelier');   -- le coloris : au hasard parmi les coloris normaux
  return jsonb_build_object('eco', interne.etat(qui), 'bille', b, 'prix', prix);
end $$;
revoke all on function public.fabriquer(text,int) from public, anon;
grant execute on function public.fabriquer(text,int) to authenticated;
revoke all on function interne.taux_eclat(), interne.prix_atelier(text,int) from public, anon, authenticated;
