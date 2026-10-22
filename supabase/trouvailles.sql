-- (20 octobre 2026) les trouvailles rares des copains avec le numéro d'édition de la bille (« Première mondiale » sur les cartes de la cour).
-- Même fonction que dans cour.sql. Sans danger pour les pages déjà ouvertes (un champ en plus).
create or replace function public.fil_amis() returns jsonb language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid();
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  return coalesce((select jsonb_agg(x.j) from (
    select jsonb_build_object('who', interne.pseudo(h.vers), 'at', floor(extract(epoch from h.le)*1000)::bigint, 's', interne.bille_json(b) || case when b.edition is null then '{}'::jsonb else jsonb_build_object('edn', b.edition) end) j   -- (20 octobre 2026) + le numéro d'édition (« Première mondiale » sur les cartes des trouvailles)
    from billes_historique h join billes b on b.id = h.bille
    where h.motif = 'trouvee' and h.vers in (select ami from amis where joueur = moi)
      -- (16 octobre 2026) Mammouths seulement (rang 5) : les Boulets communs remplissaient les 300 places et poussaient dehors les légendaires
      and b.secrete is null   -- (22 octobre 2026) jamais une bille secrète (bêta, départ, secrets de la cour)
      and h.le > now() - interval '72 hours' and (interne.rang(b.taille) = 5 or b.shiny > 0
        or (interne.decor_rarete())[b.decor+1] in (4, 6) or ((interne.decor_rarete())[b.decor+1] = 3 and interne.rang(b.taille) >= 3))
    order by h.le desc limit 300) x), '[]');   -- (14 octobre 2026) toutes celles des 72 dernières heures (300 au plus) : la cour les montre par pages, les plus belles d'abord
end $$;
