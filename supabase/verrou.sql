-- (16 octobre 2026) Le verrou : une bille verrouillée ne peut être ni vendue, ni mise aux enchères, ni troquée,
-- ni échangée à la Confiserie, ni fusionnée. Le joueur la verrouille (et la déverrouille) depuis sa fiche, dans « Mes billes ».
-- La colonne verrouillee fait foi ; donnees.lock la recopie pour le jeu (cloud.js lit donnees).
-- Les contrôles sont dans interne.bille_libre (troc, vente, enchères : cour.sql), billes_echangeables (cour.sql),
-- echanger_billes, fusionner, fusion_evenement (serveur.sql) et detruire_billes (schema.sql).

alter table public.billes add column if not exists verrouillee boolean not null default false;

-- verrouiller (v = true) ou déverrouiller (v = false) ses billes ; une bille en vente ou aux enchères doit d'abord être retirée
create or replace function public.verrouiller(ids uuid[], v boolean) returns int language plpgsql security definer set search_path = public as $$
declare moi uuid := auth.uid(); n int;
begin
  if moi is null then raise exception 'connexion_requise'; end if;
  if cardinality(ids) > 500 then raise exception 'trop_de_billes'; end if;
  if v and exists (select 1 from unnest(ids) x where interne.en_vente(x)) then raise exception 'en_vente'; end if;
  update billes b set verrouillee = v, donnees = case when v then b.donnees || '{"lock":true}'::jsonb else b.donnees - 'lock' end
    where b.id = any(ids) and b.proprietaire = moi and b.detruite_le is null;
  get diagnostics n = row_count;
  return n;
end $$;
revoke all on function public.verrouiller(uuid[], boolean) from public, anon;
grant execute on function public.verrouiller(uuid[], boolean) to authenticated;
