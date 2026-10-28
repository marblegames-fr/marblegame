-- (28 octobre 2026) Pseudos : la base refuse les caractères qui pourraient servir à glisser du code dans les pages
-- (< > " ' & ` et les caractères de contrôle). Le jeu n'accepte déjà que lettres, chiffres, espaces, - et _ (index.html),
-- mais un tricheur peut écrire directement dans la base : c'est donc elle qui a le dernier mot.

-- à l'inscription, le pseudo vient des métadonnées du compte : on le nettoie au lieu de faire échouer l'inscription
create or replace function public.creer_profil()
returns trigger language plpgsql security definer set search_path = public as $$
declare p text := left(trim(regexp_replace(coalesce(new.raw_user_meta_data->>'pseudo', ''), '[<>"''&`[:cntrl:]]', '', 'g')), 20);
begin
  if char_length(p) < 3 then p := 'Billeur'; end if;
  -- pseudo déjà pris : on ajoute un petit numéro
  if exists (select 1 from profils where lower(pseudo) = lower(p)) then
    p := left(p, 15) || '_' || floor(random()*9000+1000)::int;
  end if;
  insert into profils (id, pseudo) values (new.id, p);
  return new;
end $$;

alter table public.profils drop constraint if exists profils_pseudo_sur;
alter table public.profils add constraint profils_pseudo_sur check (pseudo !~ '[<>"''&`[:cntrl:]]');
