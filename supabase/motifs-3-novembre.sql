-- (3 novembre 2026) 5 nouveaux motifs (86 à 90) : Triangles (commun), Camouflage (peu commun), Météorite (rare), Montgolfière (épique), Atome (légendaire).
-- À installer APRÈS la mise en ligne du jeu (une page ancienne ne connaît pas les motifs 86 à 90). Même fonction que dans serveur.sql ;
-- interne.tirer_decor partage déjà la part de chaque rareté entre ses motifs (poids_n0), rien d'autre à changer.
create or replace function interne.decor_rarete() returns int[] language sql immutable as
$$ select array[0,0,4,1,0,2,0,0,2,2,3,2,1,1,1,2,2,3,2,2,0,0,1,1,0,1,3,3,1,2,4,2, 5, 1,4, 5,5,5,5,5,5,5,5,5,5,5,5, 5, 5, 3,3,3, 0,0,0,0,0,1,1,1,2,3,1,4, 6, 0,0,0,0,0,0,0,0,0, 1,1,1,1,1, 2,2,2, 3,3, 4,4, 0,1,2,3,4] $$;
