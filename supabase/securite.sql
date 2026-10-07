-- Ménage des droits (7 octobre 2026). Peut être relancé sans risque.
-- La Loterie et les notifications ne se lisent et ne s'écrivent que par les fonctions du serveur (RLS sans règle) :
-- on retire aussi les droits par défaut que Supabase donne aux tables neuves.
revoke all on public.loterie_tickets, public.loterie_tirages from anon, authenticated;
revoke insert, update, delete, truncate, references, trigger on public.pings from anon, authenticated;
-- les anciennes mises (Course et Tic, fermées depuis le 6 octobre 2026, plus aucune en attente)
revoke execute on function public.miser(text, integer), public.regler_mise(bigint, integer) from anon, authenticated, public;
-- des fonctions de déclencheur : jamais appelées directement
revoke execute on function public.creer_profil(), public.noter_trouvaille() from anon, authenticated, public;

-- Les joueurs ne créent plus de billes eux-mêmes : seules les fonctions du serveur en créent (7 octobre 2026).
-- À lancer seulement après la mise en ligne du site qui n'en envoie plus (l'ancien afficherait des erreurs).
drop policy if exists billes_ajouter on public.billes;
revoke insert on public.billes from anon, authenticated;
-- Les billes créées jusque-là par l'appareil deviennent de vraies billes (phase de test : remise à zéro au lancement).
update public.billes set origine = 'serveur' where origine = 'appareil' and detruite_le is null;
