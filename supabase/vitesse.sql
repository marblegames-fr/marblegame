-- (21 octobre 2026) Vitesse du serveur : le chargement du site attend le classement, la semaine et la cour.
-- Rien ne change dans les résultats, seulement le chemin pour les trouver.

-- 1) « une bille reçue ne compte que si c'est le premier exemplaire de ce modèle » (interne.semaine_pts) :
--    sans cet index, chaque troc ou achat de la semaine relisait tout l'historique du joueur (classement de la semaine : ~0,9 s par appel)
create index if not exists billes_modele on public.billes (taille, decor, coloris);

-- 2) la carte d'un joueur (classements, amis, fil) retrouvait sa bille avec b.id::text = … : l'index des billes ne servait pas,
--    toute la table était relue, deux fois par carte (~17 ms la carte, 50 cartes par classement)
create or replace function interne.en_uuid(t text) returns uuid language sql immutable as $$
  -- (minuscules seulement, comme b.id::text : une valeur qui ne correspondait pas avant ne correspond pas non plus maintenant)
  select case when t ~ '^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$' then t::uuid end
$$;

create or replace function interne.carte(qui uuid)
 returns jsonb language sql stable as $function$
  select jsonb_build_object('id', qui, 'pseudo', interne.pseudo(qui),
    'titre', s.donnees->>'title',
    'champion', (select count(*) from public.palmares p where p.joueur = qui and p.rang = 1),   -- fois 1er de la semaine
    'active', coalesce(
      (select interne.bille_json(b) from public.billes b where b.id = interne.en_uuid(s.donnees->>'avatar') and b.proprietaire = qui and b.detruite_le is null),
      (select interne.bille_json(b) from public.billes b where b.id = interne.en_uuid(s.donnees->>'active') and b.proprietaire = qui and b.detruite_le is null)))
  from (select qui) x left join public.sauvegardes s on s.joueur = qui
$function$;

-- 3) toutes les minutes, le jeu retéléchargeait toute la boîte du joueur (jusqu'à 4 000 billes, plus d'un Mo) pour voir si quelque chose
--    avait changé, et les autres appels (ouvrir un sachet…) attendaient derrière. Maintenant il demande d'abord cette empreinte :
--    elle change dès qu'une bille arrive, part, ou change ; la boîte n'est retéléchargée que dans ce cas.
--    (xmin : le numéro de la dernière écriture de la ligne, il change à chaque modification ; relire les données coûtait ~90 ms pour 4 000 billes)
create or replace function public.billes_empreinte()
returns text language sql stable security definer set search_path = public as $$
  select md5(coalesce(string_agg(b.id::text || ':' || b.xmin::text, ',' order by b.id), ''))
  from billes b where b.proprietaire = auth.uid() and b.detruite_le is null
$$;
revoke all on function public.billes_empreinte() from public, anon;
grant execute on function public.billes_empreinte() to authenticated;
