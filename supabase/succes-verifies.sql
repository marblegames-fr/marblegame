-- (6 novembre 2026) gagner('succes', …) : seulement les vrais succès du jeu, à leur montant et avec leur sachet
-- (6 novembre 2026) le tarif de chaque succès (CHALLENGES dans index.html) : montant maximum et sachet ; null = ce succès n'existe pas.
-- Avant, n'importe quelle clé passait jusqu'à 1000 bonbecs (un ami l'a trouvé en appelant gagner('succes', 'demo…', 1000) depuis la console).
-- Les « fam-N » se déduisent de la rareté du motif (FAM_REW, FAM_SIZES dans index.html ; le mythique a son propre succès, myth1) :
-- un nouveau motif ajouté dans interne.decor_rarete() a donc son succès sans rien changer ici.
-- Un nouveau succès dans index.html => l'ajouter dans la liste ci-dessous.
create or replace function interne.succes_tarif(cle text) returns jsonb language plpgsql stable as $f$
declare r int; j int;
begin
  if cle ~ '^fam-[0-9]{1,3}$' then
    r := (interne.decor_rarete())[split_part(cle, '-', 2)::int + 1];
    if r is null or r not between 0 and 4 then return null; end if;
    j := (array[45,75,55,85,50])[r + 1];
    return jsonb_build_object('j', j, 'sac', case when j >= 70 then 'premium' else 'classique' end);
  end if;
  return '{"first-chinoise":{"j":10},"first-calot":{"j":20},"first-boulet":{"j":30,"sac":"classique"},"first-mammouth":{"j":50,"sac":"premium"},"first-vitrine":{"j":10},"first-hole":{"j":10},"first-craft":{"j":15},"half":{"j":60,"sac":"premium"},"full":{"j":300,"sac":"collector"},"t-caid":{"j":70},"pal10":{"j":40},"pal24":{"j":90},"allpals":{"j":50},"case1":{"j":150,"sac":"premium"},"case5":{"j":400,"sac":"collector"},"big5":{"j":40,"sac":"premium"},"mam3":{"j":80},"epic1":{"j":30},"leg1":{"j":50},"myth1":{"j":500,"sac":"collector"},"legmam":{"j":500},"mythmam":{"j":1000,"sac":"collector"},"shiny1":{"j":100},"shiny3":{"j":300},"secrets":{"j":300},"t-golf":{"j":40},"t-parcours":{"j":200,"sac":"premium"},"t-marelle":{"j":50},"t-castle":{"j":50},"t-tic":{"j":60},"t-race":{"j":60},"t-roue":{"j":50},"t-plinko":{"j":50},"t-ticket":{"j":50},"t-distrib":{"j":50},"t-jdj":{"j":80,"sac":"premium"},"t-roi":{"j":80},"t-gobelets":{"j":50},"t-tierce":{"j":50},"t-toupie":{"j":50},"t-pince":{"j":50},"streak7":{"j":50},"streak28":{"j":200,"sac":"premium"},"bags50":{"j":50,"sac":"premium"},"bags250":{"j":150,"sac":"premium"},"craft10":{"j":80},"q50":{"j":80},"t-chouchou":{"j":50},"found-25":{"j":20},"found-50":{"j":30},"found-100":{"j":50,"sac":"classique"},"found-250":{"j":80,"sac":"premium"},"found-500":{"j":120,"sac":"premium"},"found-1000":{"j":200,"sac":"premium"},"found-2000":{"j":350,"sac":"premium"},"found-3000":{"j":500,"sac":"collector"},"found-4000":{"j":800,"sac":"collector"},"fmt-mini":{"j":40,"sac":"premium"},"fmt-bille":{"j":50,"sac":"premium"},"fmt-chinoise":{"j":70,"sac":"premium"},"fmt-calot":{"j":90,"sac":"premium"},"fmt-boulet":{"j":120,"sac":"premium"},"fmt-mammouth":{"j":250,"sac":"collector"}}'::jsonb -> cle;
end $f$;

-- on remplace seulement la branche « succes » de la fonction installée (le reste de public.gagner ne bouge pas)
do $d$
declare d text; n text;
begin
  d := pg_get_functiondef('public.gagner(text,text,int,text)'::regprocedure);
  if position('succes_tarif' in d) > 0 then return; end if;   -- déjà installé
  n := regexp_replace(d, 'when ''succes'' then\s*if montant > 1000 then raise exception ''montant_invalide''; end if;',
    'when ''succes'' then   -- (6 novembre 2026) seulement les vrais succès (interne.succes_tarif)' || chr(10) ||
    '      ev_t := interne.succes_tarif(cle);' || chr(10) ||
    '      if ev_t is null or montant > (ev_t->>''j'')::int or (sac is not null and sac is distinct from ev_t->>''sac'') then raise exception ''montant_invalide''; end if;');
  if n = d then raise exception 'branche succes introuvable'; end if;
  n := replace(n, 'nq int; ev record;', 'nq int; ev record; ev_t jsonb;');
  execute n;
end $d$;
