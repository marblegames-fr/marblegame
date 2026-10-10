-- =====================================================================
--  BILLEO : chaque « Signaler un bug » arrive aussi par mail (10 octobre 2026)
--  À installer après signalements.sql.
--
--  Après chaque nouveau signalement, la base envoie un mail à marblegamesfr@gmail.com par Resend
--  (https://resend.com), avec pg_net (l'envoi part après l'enregistrement : s'il rate, le signalement
--  est quand même gardé et reste lisible dans Paramètres).
--  La clé Resend est rangée dans le coffre de Supabase (Vault), sous le nom « resend_key » :
--    select vault.create_secret('re_xxx', 'resend_key');            -- la première fois
--    select vault.update_secret((select id from vault.secrets where name = 'resend_key'), 're_xxx');   -- pour la changer
--  Sans clé, rien n'est envoyé (et rien ne casse).
--  Sans domaine à nous, Resend n'envoie qu'à l'adresse du compte Resend (marblegamesfr@gmail.com), depuis onboarding@resend.dev.
-- =====================================================================

create extension if not exists pg_net with schema extensions;

create or replace function interne.signalement_mail() returns trigger
language plpgsql security definer set search_path = public as $$
declare cle text; cat text; d jsonb := coalesce(new.details, '{}'); corps text;
begin
  select s.decrypted_secret into cle from vault.decrypted_secrets s where s.name = 'resend_key' limit 1;
  if cle is null or cle = '' then return new; end if;
  cat := case new.categorie when 'bug' then 'Bug' when 'affichage' then 'Affichage' when 'idee' then 'Idée' else 'Autre' end;
  corps := '<div style="font-family:Arial,sans-serif;font-size:15px;color:#222">'
    || '<p style="margin:0 0 6px;color:#888;font-size:13px">' || cat || ' · signalement n° ' || new.id || ' · '
    || to_char(new.le at time zone 'Europe/Paris', 'DD/MM/YYYY à HH24"h"MI') || '</p>'
    || '<p style="margin:0 0 14px"><b>' || coalesce(replace(replace(new.pseudo, '<', '&lt;'), '>', '&gt;'), 'Joueur inconnu') || '</b> a écrit :</p>'
    || '<div style="white-space:pre-wrap;padding:12px 14px;border-left:4px solid #FFC93F;background:#FFF8E1">'
    || replace(replace(replace(new.texte, '&', '&amp;'), '<', '&lt;'), '>', '&gt;') || '</div>'
    || '<p style="margin:16px 0 4px;color:#888;font-size:13px">Détails envoyés par le jeu :</p>'
    || '<pre style="font-size:12px;white-space:pre-wrap;background:#f4f4f4;padding:10px;border-radius:6px">'
    || replace(replace(replace(jsonb_pretty(d), '&', '&amp;'), '<', '&lt;'), '>', '&gt;') || '</pre>'
    || '<p style="color:#888;font-size:12px">Tous les signalements : Paramètres du jeu (compte admin).</p></div>';
  perform net.http_post(
    url := 'https://api.resend.com/emails',
    headers := jsonb_build_object('Authorization', 'Bearer ' || cle, 'Content-Type', 'application/json'),
    body := jsonb_build_object(
      'from', 'Billeo <onboarding@resend.dev>',
      'to', jsonb_build_array('marblegamesfr@gmail.com'),
      'subject', '[Billeo] ' || cat || ' de ' || coalesce(new.pseudo, '?') || ' : ' || left(regexp_replace(new.texte, '\s+', ' ', 'g'), 60),
      'html', corps));
  return new;
exception when others then
  return new;   -- jamais d'erreur pour le joueur à cause du mail
end $$;
revoke all on function interne.signalement_mail() from public, anon, authenticated;

drop trigger if exists signalement_mail on public.signalements;
create trigger signalement_mail after insert on public.signalements
  for each row execute function interne.signalement_mail();
