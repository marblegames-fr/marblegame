-- =====================================================================
--  TIKALO : tout remettre à zéro (le jour du lancement)
--  À coller dans Supabase > SQL Editor > New query > Run.
--  ATTENTION : irréversible. Les billes, les bonbecs, les copains, les trocs et le marché
--  de TOUS les joueurs sont effacés.
--
--  Par défaut, les comptes (e-mail, mot de passe, pseudo) sont GARDÉS : chacun se reconnecte
--  et repart de zéro, avec les billes de départ… et ses billes Bêta, qui restent (promis aux testeurs).
--  Pour supprimer aussi les comptes, enlève les deux tirets devant la dernière ligne.
-- =====================================================================

begin;

-- la cour de récré
truncate table public.offres, public.annonces, public.trocs, public.demandes_amis, public.amis restart identity cascade;
-- la Grande Course de 20 h
truncate table public.course_inscrits, public.courses;
-- l'économie
truncate table public.gains, public.mises, public.portefeuilles restart identity;
-- la loterie du dimanche et les notifications en attente
truncate table public.loterie_tickets, public.loterie_tirages, public.pings restart identity;
-- les billes (et leur historique), SAUF les billes Bêta données par le serveur pendant la bêta
delete from public.billes_historique h using public.billes b
  where h.bille = b.id and not coalesce(b.secrete = 'beta' and b.origine = 'serveur' and b.detruite_le is null, false);
delete from public.billes where not coalesce(secrete = 'beta' and origine = 'serveur' and detruite_le is null, false);
-- les parties sauvegardées (titres, succès, passe, quêtes…)
truncate table public.sauvegardes;
-- nouveau numéro de remise (supabase/remise.sql) : les pages restées ouvertes ne peuvent plus renvoyer l'ancienne partie,
-- elles se rechargent toutes seules à zéro
insert into public.remise (id, numero) values (1, floor(extract(epoch from clock_timestamp())*1000)::bigint)
  on conflict (id) do update set numero = excluded.numero;

commit;

-- les testeurs gardent leurs outils ; pour les retirer aussi :
-- truncate table public.testeurs;

-- supprimer aussi tous les comptes (les joueurs devront se réinscrire, ET ILS PERDRONT LEURS BILLES BÊTA) :
-- delete from auth.users;
