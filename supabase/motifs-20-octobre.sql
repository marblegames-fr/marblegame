-- (20 octobre 2026) 21 nouveaux motifs (65 à 85) et le tirage « chaque rareté garde sa part ».
-- À installer APRÈS la mise en ligne du jeu (une page ancienne ne connaît pas les motifs 65 à 85). Mêmes fonctions que dans serveur.sql.
create or replace function interne.decor_rarete() returns int[] language sql immutable as
$$ select array[0,0,4,1,0,2,0,0,2,2,3,2,1,1,1,2,2,3,2,2,0,0,1,1,0,1,3,3,1,2,4,2, 5, 1,4, 5,5,5,5,5,5,5,5,5,5,5,5, 5, 5, 3,3,3, 0,0,0,0,0,1,1,1,2,3,1,4, 6, 0,0,0,0,0,0,0,0,0, 1,1,1,1,1, 2,2,2, 3,3, 4,4] $$;   -- (20 octobre 2026) 65 à 85 : Tricolore, Sucette, Fleurettes, Losanges, Marinière, Rosace, Agrume, Vichy, Shérif (communs), Girafe, Briques, Puzzle, Labyrinthe, Pop (peu communs), Bulles, Jungle, Ammonite (rares), Lucioles, Tornade (épiques), Comète, Constellation (légendaires) ; 32 : Pirate (événement, 5 = jamais dans les sacs) ; 33 Vitrail ; 34 Trou noir ; 35 à 46 : décors de saison (passe seulement) ; 47 : Bêta ; 48 : Super-héros (événement de novembre 2026) ; 49 Prisme, 50 Orage et 51 Méduse ; 10 octobre 2026 : nouvelle tier list (Opaline, Berlingot → commun ; Agate, Arlequin, Millefiori, Vitrail → peu commun ; Cristal, Givrée, Acier → rare), 52 à 63 nouveaux motifs (Étoilée, Cœurs, Bicolore, Vagues, Zigzag, Tricot, Nuages, Mouchetée, Jean, Ambre, Circuit, Feu d'artifice), 64 Vortex : MYTHIQUE (6)
-- (20 octobre 2026) chaque rareté garde la part des billes qu'elle avait avec la tier list du 10 octobre : poids_n0() motifs
-- à poids_rarete() chacun. Quand on ajoute des motifs à une rareté, ils se partagent cette part (même calcul que FAM_W dans index.html)
create or replace function interne.poids_n0() returns numeric[] language sql immutable as
$$ select array[13,13,11,8,4,0,1]::numeric[] $$;
create or replace function interne.tirer_decor() returns int language plpgsql volatile as $$
declare r int[] := interne.decor_rarete(); w numeric[] := interne.poids_rarete(); n0 numeric[] := interne.poids_n0();
  n numeric[] := array[0,0,0,0,0,0,0]::numeric[]; p numeric[] := '{}'; i int;
begin
  for i in 1..array_length(r,1) loop n[r[i]+1] := n[r[i]+1] + 1; end loop;
  for i in 1..array_length(r,1) loop p := p || case when n0[r[i]+1] = 0 then 0 else w[r[i]+1] * n0[r[i]+1] / n[r[i]+1] end; end loop;
  return interne.tirer(p) - 1;
end $$;
