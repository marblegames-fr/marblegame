-- 2 octobre 2026 : les billes Bêta déjà données passent au coloris de leur taille (70 + rang : Rubis → Diamant).
-- À lancer APRÈS la mise en ligne du jeu qui connaît les coloris 71 à 75 (sinon l'ancien jeu ne sait pas les afficher).
update public.billes
   set coloris = 70 + interne.rang(taille),
       donnees = jsonb_set(donnees, '{pal}', to_jsonb(70 + interne.rang(taille)))
 where secrete = 'beta' and decor = 47;
