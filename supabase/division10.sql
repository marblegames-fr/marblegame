-- 6 octobre 2026 : toute la monnaie est divisée par 10 (pour ne pas finir avec des millions de bonbecs).
-- À lancer UNE fois, juste après serveur.sql / cour.sql / course.sql et la mise en ligne du nouveau index.html.
-- Protégé par interne.migrations : une deuxième exécution ne fait rien.
do $$
begin
  if exists (select 1 from interne.migrations where nom = 'division10') then
    raise notice 'division10 : déjà faite'; return;
  end if;
  insert into interne.migrations (nom) values ('division10');

  -- les portefeuilles (arrondi au-dessus : personne ne perd un bonbec entamé) ; la part de départ suit
  update public.portefeuilles set bonbecs = ceil(bonbecs / 10.0)::int, depart = ceil(depart / 10.0)::int, maj_le = now();
  update public.portefeuilles set depart = bonbecs where depart > bonbecs;

  -- le marché : prix des annonces en cours, offres des enchères en cours (les bonbecs mis de côté sont divisés pareil)
  update public.annonces set prix = greatest(1, round(prix / 10.0))::int, offre = case when offre is null then null else greatest(1, round(offre / 10.0))::int end
    where vendue_le is null and retiree_le is null;
  update public.offres o set montant = greatest(1, round(o.montant / 10.0))::int
    from public.annonces a where a.id = o.annonce and a.vendue_le is null and a.retiree_le is null;

  -- les trocs en attente avec des bonbecs : annulés (plus de bonbecs dans les trocs)
  update public.trocs set statut = 'annule', fini_le = now() where statut = 'attente' and (donne_bonbecs > 0 or demande_bonbecs > 0);

  -- les anciennes mises jamais réglées : fermées sans gain (le jeu ne s'en sert plus)
  update public.mises set gain = 0, reglee_le = now() where reglee_le is null;
end $$;

-- le défaut de la colonne (nouveaux comptes) suit aussi
alter table public.portefeuilles alter column bonbecs set default 100;
