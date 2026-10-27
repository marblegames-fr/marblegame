-- (27 octobre 2026) Le classement de la semaine sur les fiches : combien de fois 1er et combien de podiums.
-- La fiche d'un joueur (profil_joueur) avait déjà 'champion' (interne.carte) : on ajoute 'podiums_semaine'.
-- Mes statistiques (cour_stats) : 'semaine_victoires' et 'semaine_podiums'.
-- Tout le palmarès compte (public.palmares n'est jamais vidé), pas seulement les semaines affichées dans l'onglet Palmarès.

CREATE OR REPLACE FUNCTION public.profil_joueur(qui uuid)
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare moi uuid := auth.uid(); vit jsonb;
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  if not exists (select 1 from portefeuilles where joueur = qui) then raise exception 'inconnu'; end if;
  select s.donnees->'vitrine' into vit from sauvegardes s where s.joueur = qui;
  return interne.carte(qui) || jsonb_build_object(
    'ami', qui = moi or interne.sont_amis(moi, qui), 'moi', qui = moi,
    'podiums_semaine', (select count(*) from palmares p where p.joueur = qui and p.rang <= 3),   -- (27 octobre 2026) podiums du classement de la semaine
    'depuis', (select floor(extract(epoch from p.cree_le)*1000)::bigint from profils p where p.id = qui),
    -- la vitrine, dans l'ordre choisi par le joueur
    'vitrine', coalesce((select jsonb_agg(interne.bille_json(b) order by v.pos) from jsonb_array_elements_text(coalesce(vit, '[]')) with ordinality v(id, pos)
                 join billes b on b.id::text = v.id and b.proprietaire = qui and b.detruite_le is null), '[]'),
    -- sa plus belle bille : la shiny la plus rare, puis la plus grosse, puis le décor le plus rare
    'top', (select interne.bille_json(b) from billes b where b.proprietaire = qui and b.detruite_le is null and coalesce(b.donnees->>'src', '') <> 'test'
              and b.secrete is null   -- (7 octobre 2026) jamais une bille secrète (ni la Bêta)
              and (interne.decor_rarete())[b.decor+1] <> 5 and interne.coloris_normal(b.coloris)   -- (9 octobre 2026) ni une bille d'événement ni du passe de saison, comme pour l'album
              order by b.shiny desc, interne.rang(b.taille) desc, (interne.decor_rarete())[b.decor+1] desc, b.numero limit 1),
    'billes', (select count(*) from billes b where b.proprietaire = qui and b.detruite_le is null),
    -- l'album : les billes différentes (taille, décor, coloris) et les cases (taille, décor), hors événements, saisons et secrètes
    'album', (select count(distinct (b.taille, b.decor, b.coloris)) from billes b where b.proprietaire = qui and b.detruite_le is null
                and interne.coloris_normal(b.coloris) and (interne.decor_rarete())[b.decor+1] <> 5),
    'cases', (select count(distinct (b.taille, b.decor)) from billes b where b.proprietaire = qui and b.detruite_le is null and (interne.decor_rarete())[b.decor+1] <> 5),
    'completes', (select count(*) from (select 1 from billes b where b.proprietaire = qui and b.detruite_le is null and interne.coloris_normal(b.coloris)
                and (interne.decor_rarete())[b.decor+1] <> 5 group by b.taille, b.decor having count(distinct b.coloris) >= interne.nb_coloris()) x),
    'tailles', (select coalesce(jsonb_object_agg(t, n), '{}') from (select b.taille t, count(*) n from billes b where b.proprietaire = qui and b.detruite_le is null group by b.taille) x),
    'shinies', (select jsonb_build_array(count(*) filter (where b.shiny = 1), count(*) filter (where b.shiny = 2), count(*) filter (where b.shiny = 3))
                from billes b where b.proprietaire = qui and b.detruite_le is null),
    'shiny', (select count(*) from billes b where b.proprietaire = qui and b.detruite_le is null and b.shiny > 0),
    -- les collections d'événement : les billes différentes (taille, coloris) de chaque décor d'événement
    'evenements', (select coalesce(jsonb_object_agg(d, n), '{}') from (select b.decor d, count(distinct (b.taille, b.coloris)) n from billes b
                where b.proprietaire = qui and b.detruite_le is null and interne.decor_evenement(b.decor) group by b.decor) x),
    'trouvailles', coalesce((select jsonb_agg(x.j order by x.le desc) from (select interne.bille_json(b) || jsonb_build_object('le', floor(extract(epoch from b.obtenue_le)*1000)::bigint) j, b.obtenue_le le
                 -- (14 octobre 2026) la même règle que les trouvailles rares de la cour : Mammouths, shiny, motifs légendaires et mythiques,
                 -- épiques à partir du Calot ; jamais une bille secrète, d'événement ou de saison, ni de test
                 from billes b where b.proprietaire = qui and b.detruite_le is null and b.secrete is null and coalesce(b.donnees->>'src', '') <> 'test'
                   and (interne.decor_rarete())[b.decor+1] <> 5 and (interne.rang(b.taille) = 5 or b.shiny > 0
                     or (interne.decor_rarete())[b.decor+1] in (4, 6) or ((interne.decor_rarete())[b.decor+1] = 3 and interne.rang(b.taille) >= 3))
                 order by b.obtenue_le desc limit 6) x), '[]')
  );
end $function$
;

CREATE OR REPLACE FUNCTION public.cour_stats()
 RETURNS jsonb
 LANGUAGE plpgsql
 SECURITY DEFINER
 SET search_path TO 'public'
AS $function$
declare moi uuid := auth.uid(); g jsonb; mon int;
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  -- parties jouées par jeu : la partie offerte (source 'jeu', clé « jour|jeu ») + les parties achetées (source = le jeu ; 'plinko' pour le Plinko)
  select coalesce(jsonb_object_agg(k, n), '{}') into g from (
    select case when source = 'jeu' then split_part(cle, '|', 2) when source = 'plinko' then 'pachinko' else source end k, count(*) n
    from gains where joueur = moi and (source in ('jeu', 'plinko', 'roue', 'grattage', 'distributeur', 'marelle', 'gobelets', 'tierce', 'toupie', 'pince'))
    group by 1) x;
  select s.total into mon from interne.scores() s where s.joueur = moi;
  return jsonb_build_object(
    'trocs',    (select count(*) from trocs t where (t.de = moi or t.vers = moi) and t.statut = 'accepte'),
    'vendues',  (select count(*) from annonces a where a.vendeur = moi and a.vendue_le is not null),
    'achetees', (select count(*) from annonces a where a.acheteur = moi and not a.enchere),
    'encheres', (select count(*) from annonces a where a.acheteur = moi and a.enchere),
    'copains',  (select count(*) from amis where joueur = moi),
    'semaine_victoires', (select count(*) from palmares where joueur = moi and rang = 1),   -- (27 octobre 2026) le classement de la semaine
    'semaine_podiums',   (select count(*) from palmares where joueur = moi and rang <= 3),
    'gagne_marche', (select coalesce(sum(prix), 0) from annonces a where a.vendeur = moi and a.vendue_le is not null),
    'parties',  g,
    'quetes',   (select count(*) from gains where joueur = moi and source = 'quete'),
    'bonus_quetes', (select count(*) from gains where joueur = moi and source = 'quetes-bonus'),
    'jeux_bonus',   (select count(*) from gains where joueur = moi and source = 'jeux-bonus'),
    'succes',   (select count(*) from gains where joueur = moi and source = 'succes'),
    'sachets',  (select sacs_ouverts from portefeuilles where joueur = moi),
    'recyclees', (select count(*) from billes where proprietaire = moi and detruite_raison = 'recyclee'),
    'course_inscrit', (select count(*) from course_inscrits where joueur = moi),
    'course_podiums', (select count(*) from courses c, jsonb_array_elements(c.resultats) with ordinality e(v, pos) where e.v->>'joueur' = moi::text and e.pos <= 3),
    'course_victoires', (select count(*) from courses c where c.resultats->0->>'joueur' = moi::text),
    'loterie_tickets', (select count(*) from loterie_tickets where joueur = moi),
    'loterie_gagnants', (select count(*) from loterie_tickets where joueur = moi and bons >= 1),
    'loterie_meilleur', (select coalesce(max(bons), 0) from loterie_tickets where joueur = moi),
    -- la place au classement de tous les joueurs (comme public.classement : les comptes de test ne sont pas classés)
    'rang', case when moi in (select joueur from testeurs) or moi not in (select joueur from portefeuilles) then null
                 else 1 + (select count(*) from portefeuilles p left join interne.scores() s on s.joueur = p.joueur
                           where coalesce(s.total, 0) > coalesce(mon, 0) and p.joueur not in (select joueur from testeurs)) end,
    'classes', (select count(*) from portefeuilles p where p.joueur not in (select joueur from testeurs)));
end $function$
;
