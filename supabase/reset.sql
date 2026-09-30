-- =====================================================================
--  BILLY : tout remettre à zéro (le jour du lancement)
--  À coller dans Supabase > SQL Editor > New query > Run.
--  ATTENTION : irréversible. Les billes, les bonbecs, les copains, les trocs et le marché
--  de TOUS les joueurs sont effacés.
--
--  Par défaut, les comptes (e-mail, mot de passe, pseudo) sont GARDÉS : chacun se reconnecte
--  et repart de zéro, avec les billes de départ.
--  Pour supprimer aussi les comptes, enlève les deux tirets devant la dernière ligne.
-- =====================================================================

begin;

-- la cour de récré
truncate table public.offres, public.annonces, public.trocs, public.demandes_amis, public.amis restart identity cascade;
-- l'économie
truncate table public.gains, public.mises, public.portefeuilles restart identity;
-- les billes (et leur historique) : les numéros de série repartent de 1
truncate table public.billes_historique, public.billes restart identity cascade;
-- les parties sauvegardées (titres, succès, passe, quêtes…)
truncate table public.sauvegardes;

commit;

-- les testeurs gardent leurs outils ; pour les retirer aussi :
-- truncate table public.testeurs;

-- supprimer aussi tous les comptes (les joueurs devront se réinscrire) :
-- delete from auth.users;
