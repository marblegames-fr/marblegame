-- =====================================================================
--  TIKALO : le mode invité (26 octobre 2026, maquettes/maquette-invite.html)
--  Un visiteur peut jouer tout de suite : Supabase lui crée un compte « anonyme » (auth.users.is_anonymous),
--  avec un vrai identifiant. Ses billes, ses bonbecs et sa sauvegarde sont dans la base comme pour tout le monde.
--  Quand il crée son compte, on ajoute un e-mail à ce même compte : il garde tout (même identifiant).
--
--  Un compte invité est « scellé » : rien n'en sort et rien n'y entre venant d'un autre joueur.
--  Pas de copains, de troc, de marché, d'enchères, de Grande Course, de Loterie, et aucune bille ne change
--  de propriétaire si l'un des deux est invité. Créer plusieurs invités ne sert donc à rien.
--  La garde est posée sur les tables (déclencheurs) : elle vaut pour toutes les fonctions qui y écrivent,
--  d'aujourd'hui et de demain. Les invités ne sont pas classés (public.classement, interne.semaine_pts dans cour.sql).
--  Le script peut être relancé sans danger.
-- =====================================================================

-- ce joueur est-il un invité (compte sans e-mail) ?
create or replace function interne.est_invite(qui uuid) returns boolean language sql stable security definer set search_path = public as $$
  select coalesce((select u.is_anonymous from auth.users u where u.id = qui), false) $$;
revoke all on function interne.est_invite(uuid) from public, anon, authenticated;

-- la garde : refuse l'écriture si l'un des joueurs concernés est un invité (code « invite », traduit dans index.html)
create or replace function interne.garde_invite() returns trigger language plpgsql security definer set search_path = public as $$
declare a uuid; b uuid;
begin
  if tg_table_name = 'demandes_amis' then a := new.de; b := new.vers;
  elsif tg_table_name = 'amis' then a := new.joueur; b := new.ami;
  elsif tg_table_name = 'trocs' then a := new.de; b := new.vers;
  elsif tg_table_name = 'annonces' then a := new.vendeur; b := coalesce(new.acheteur, new.encherisseur);
  elsif tg_table_name = 'offres' then a := new.joueur;
  elsif tg_table_name in ('course_inscrits', 'loterie_tickets') then a := new.joueur;
  elsif tg_table_name = 'billes' then
    if new.proprietaire is not distinct from old.proprietaire then return new; end if;
    a := old.proprietaire; b := new.proprietaire;
  end if;
  if interne.est_invite(a) or (b is not null and interne.est_invite(b)) then raise exception 'invite'; end if;
  return new;
end $$;

drop trigger if exists garde_invite on public.demandes_amis;
create trigger garde_invite before insert on public.demandes_amis for each row execute function interne.garde_invite();
drop trigger if exists garde_invite on public.amis;
create trigger garde_invite before insert on public.amis for each row execute function interne.garde_invite();
drop trigger if exists garde_invite on public.trocs;
create trigger garde_invite before insert on public.trocs for each row execute function interne.garde_invite();
drop trigger if exists garde_invite on public.annonces;
create trigger garde_invite before insert or update of acheteur, encherisseur on public.annonces for each row execute function interne.garde_invite();
drop trigger if exists garde_invite on public.offres;
create trigger garde_invite before insert on public.offres for each row execute function interne.garde_invite();
drop trigger if exists garde_invite on public.course_inscrits;
create trigger garde_invite before insert on public.course_inscrits for each row execute function interne.garde_invite();
drop trigger if exists garde_invite on public.loterie_tickets;
create trigger garde_invite before insert on public.loterie_tickets for each row execute function interne.garde_invite();
drop trigger if exists garde_invite on public.billes;
create trigger garde_invite before update of proprietaire on public.billes for each row execute function interne.garde_invite();

-- l'invité a confirmé son e-mail (il n'est plus anonyme) : un sachet de bienvenue, par un mot de l'équipe (supabase/messages.sql).
-- is_anonymous ne repasse jamais à vrai : une seule fois par compte.
create or replace function interne.invite_devenu_compte() returns trigger language plpgsql security definer set search_path = public as $$
begin
  if old.is_anonymous and not new.is_anonymous then
    insert into public.messages (joueur, titre, texte, sac) values (new.id, 'Bienvenue dans la cour !',
      'Ta partie est sauvegardée : tu peux jouer sur tous tes appareils, ajouter tes copains, troquer, vendre au marché et grimper au classement. Voici un sachet pour fêter ça !',
      'classique');
  end if;
  return new;
end $$;
drop trigger if exists invite_devenu_compte on auth.users;
create trigger invite_devenu_compte after update of is_anonymous on auth.users for each row execute function interne.invite_devenu_compte();

-- le compteur de fréquentation : nouvelle étape « invite » (le visiteur a cliqué sur « Jouer tout de suite »)
create or replace function public.compter(etape text, source text)
returns void language plpgsql security definer set search_path = public as $$
declare e text := compter.etape; s text := compter.source;   -- mêmes noms que les colonnes : on les recopie
begin
  if e not in ('arrivee','visite','invite','inscription','envoye','compte','depart','sachet') then return; end if;
  if s is null or s not in ('insta','autre') then s := 'autre'; end if;
  insert into frequentation as f (jour, etape, source, n) values ((now() at time zone 'Europe/Paris')::date, e, s, 1)
    on conflict on constraint frequentation_pkey do update set n = f.n + 1;
end $$;
