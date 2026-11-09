-- (9 novembre 2026) l'événement de décembre « Pluie de bonbons ! » : du 1er au 15 décembre 2026 (heure de Paris), décor 116 (Bonbon), coloris 88 à 92.
-- Pas de sachet à lui : on coche la case sur un sachet payant, comme pour les Super-héros. Mêmes valeurs que EVENTS.bonbons dans index.html.
-- Peut s'installer avant la mise en ligne du jeu : l'événement ne commence que le 1er décembre. Même code que dans serveur.sql.
create or replace function interne.decor_rarete() returns int[] language sql immutable as
$$ select array[0,0,4,1,0,2,0,0,2,2,3,2,1,1,1,2,2,3,2,2,0,0,1,1,0,1,3,3,1,2,4,2, 5, 1,4, 5,5,5,5,5,5,5,5,5,5,5,5, 5, 5, 3,3,3, 0,0,0,0,0,1,1,1,2,3,1,4, 6, 0,0,0,0,0,0,0,0,0, 1,1,1,1,1, 2,2,2, 3,3, 4,4, 0,1,2,3,4, 0,0,0,0,0,0,0,0, 1,1,1,1,1,1, 2,2,2,2, 3,3, 4,4,4, 6,6, 5] $$;   -- (6 novembre 2026) 91 à 115, la grande fournée : Pastèque, Mosaïque, Dé, Œuf décoré, Dégradé, Mondrian, Pâquerettes, Éclairs (communs), Vinyle, Foot, Cordage, Relief, Velours côtelé, Guirlande lumineuse (peu communs), Œil-de-tigre, Jade, Néons, Titane (rares), Pissenlit, Engrenages (épiques), Saturne, Diamant, Phare (légendaires), Astrolabe, Plasma (MYTHIQUES, 6) ; (3 novembre 2026) 86 à 90 : Triangles, Camouflage, Météorite, Montgolfière, Atome (un par rareté) ; (20 octobre 2026) 65 à 85 : Tricolore, Sucette, Fleurettes, Losanges, Marinière, Rosace, Agrume, Vichy, Shérif (communs), Girafe, Briques, Puzzle, Labyrinthe, Pop (peu communs), Bulles, Jungle, Ammonite (rares), Lucioles, Tornade (épiques), Comète, Constellation (légendaires) ; 32 : Pirate (événement, 5 = jamais dans les sacs) ; 33 Vitrail ; 34 Trou noir ; 35 à 46 : décors de saison (passe seulement) ; 47 : Bêta ; 48 : Super-héros (événement de novembre 2026) ; 49 Prisme, 50 Orage et 51 Méduse ; 10 octobre 2026 : nouvelle tier list (Opaline, Berlingot → commun ; Agate, Arlequin, Millefiori, Vitrail → peu commun ; Cristal, Givrée, Acier → rare), 52 à 63 nouveaux motifs (Étoilée, Cœurs, Bicolore, Vagues, Zigzag, Tricot, Nuages, Mouchetée, Jean, Ambre, Circuit, Feu d'artifice), 64 Vortex : MYTHIQUE (6)   -- (9 novembre 2026) 116 : Bonbon, décor de l'événement de décembre (5 : jamais tiré)
create or replace function interne.evenement(nom text, out debut timestamptz, out fin timestamptz, out sac text, out decor int, out coloris int[])
language sql immutable as $$
  select v.debut, v.fin, v.sac, v.decor, v.coloris from (values
    -- le Pirate prolongé exceptionnellement jusqu'au 31 octobre (10 octobre 2026) ; les suivants restent sur deux semaines
    -- (16 octobre 2026) calendrier par demi-mois : du 1er au 15, ou du 16 à la fin du mois (une quinzaine peut rester sans événement)
    ('pirates', timestamptz '2026-09-30 00:00:00 Europe/Paris', timestamptz '2026-10-31 23:59:59 Europe/Paris', null, 32, array[65,66,67,68,69]),
    -- novembre 2026 : « Super-héros ! », pas de sachet à lui (on coche la case), décor 48, coloris 79 à 83 (après ceux des joueurs)
    ('superheros', timestamptz '2026-11-01 00:00:00 Europe/Paris', timestamptz '2026-11-15 23:59:59 Europe/Paris', null, 48, array[79,80,81,82,83]),
    -- (9 novembre 2026) décembre 2026 : « Pluie de bonbons ! » (pause du 16 au 30 novembre), décor 116, coloris 88 à 92 (après BCKC)
    ('bonbons', timestamptz '2026-12-01 00:00:00 Europe/Paris', timestamptz '2026-12-15 23:59:59 Europe/Paris', null, 116, array[88,89,90,91,92])
  ) v(nom, debut, fin, sac, decor, coloris) where v.nom = evenement.nom
$$;
create or replace function interne.evenement_en_cours(out nom text, out debut timestamptz, out fin timestamptz, out decor int, out coloris int[])
language sql stable as $$
  select e.nom, v.debut, v.fin, v.decor, v.coloris from unnest(array['pirates','superheros','bonbons']) e(nom), interne.evenement(e.nom) v
  where now() between v.debut and v.fin limit 1
$$;
create or replace function interne.decor_evenement(d int) returns boolean language sql immutable as $$
  select exists (select 1 from unnest(array['pirates','superheros','bonbons']) e(nom), interne.evenement(e.nom) v where v.decor = d)
$$;
