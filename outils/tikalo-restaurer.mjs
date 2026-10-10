// Remettre un export de Tikalo (fait par ~/tikalo-backup.mjs) dans la base Supabase.
//
//   node ~/tikalo-restaurer.mjs verifier  [dossier]   lecture seule : compare l'export à la base (tables, colonnes, comptes)
//   node ~/tikalo-restaurer.mjs copie     [dossier]   charge l'export dans le schéma « restauration », sans toucher au jeu
//   node ~/tikalo-restaurer.mjs remplacer [dossier] --oui
//        1) charge l'export dans « restauration », 2) fait un export de sécurité de l'état actuel (tikalo-backup.mjs),
//        3) remplace toutes les tables du jeu par la copie EN UNE SEULE TRANSACTION : tout passe, ou rien ne change.
//   node ~/tikalo-restaurer.mjs nettoyer                supprime le schéma « restauration »
//   [dossier] : un dossier de sauvegardes-donnees (par défaut : le plus récent), ex. 2026-10-10-09-56
//   --essai (avec remplacer) : fait tout le remplacement puis l'ANNULE (ROLLBACK) : pour tester sans rien changer.
//
// Ce que ça ne remet PAS : les comptes (auth.users, gérés par Supabase, mots de passe compris). Les lignes d'un joueur
// dont le compte n'existe plus sont signalées et laissées de côté. Les tables de secours (interne.secours_…) non plus.
import fs from "fs"; import os from "os"; import path from "path"; import { execFileSync } from "child_process";
const ROOT = path.join(os.homedir(), "OneDrive", "Documents", "Marble Games", "sauvegardes-donnees");
const T = fs.readFileSync(os.homedir() + "/.tikalo-supabase-token", "utf8").trim();
const [mode, ...rest] = process.argv.slice(2);
const oui = rest.includes("--oui"), essai = rest.includes("--essai");
const dirArg = rest.find(a => !a.startsWith("--"));
const SCH = "restauration", LOT = 400;

// l'API de Supabase limite le nombre de requêtes : une petite pause entre chaque, et on réessaie si elle demande de ralentir (429)
const pause = ms => new Promise(r => setTimeout(r, ms));
async function sql(q){
  for(let essai = 1; ; essai++){
    await pause(350);
    const r = await fetch("https://api.supabase.com/v1/projects/gflnjqxtxqxoybaaaszp/database/query",
      { method:"POST", headers:{ Authorization:"Bearer " + T, "Content-Type":"application/json" }, body: JSON.stringify({ query:q }) });
    const t = await r.text();
    if(r.status === 429 && essai < 8){ process.stdout.write(`  (Supabase demande de ralentir : pause de ${15*essai} s)
`); await pause(15000*essai); continue }
    if(!r.ok) throw new Error(`HTTP ${r.status} : ${t.includes("BILAN_ESSAI") ? t : t.slice(0, 400)}`); return JSON.parse(t);
  }
}
const lit = s => "$tk$" + s + "$tk$";   // une chaîne SQL sans échappement (le JSON ne contient jamais $tk$)
const id = s => '"' + s.replace(/"/g, '""') + '"';

function dossier(){
  const all = fs.readdirSync(ROOT).filter(f => /^\d{4}-\d\d-\d\d-\d\d-\d\d$/.test(f)).sort();
  const d = dirArg || all.at(-1); if(!d || !fs.existsSync(path.join(ROOT, d))) throw new Error("Export introuvable : " + (d || "(aucun)"));
  return path.join(ROOT, d);
}
// les tables de l'export (hors copies de secours), dans un ordre qui respecte les liens entre tables
const ORDRE = ["public.profils","public.portefeuilles","public.sauvegardes","public.testeurs","public.billes","public.billes_historique","public.gains",
  "public.amis","public.demandes_amis","public.trocs","public.annonces","public.offres","public.courses","public.course_inscrits","public.mises",
  "public.loterie_tirages","public.loterie_tickets","public.remise","public.pings","public.signalements"];
function tablesDe(dir){
  const f = fs.readdirSync(dir).filter(n => n.endsWith(".jsonl") && !n.startsWith("interne.secours_")).map(n => n.slice(0, -6));
  return [...ORDRE.filter(t => f.includes(t)), ...f.filter(t => !ORDRE.includes(t)).sort()];
}
const lignes = (dir, t) => fs.readFileSync(path.join(dir, t + ".jsonl"), "utf8").split("\n").filter(Boolean).map(l => JSON.parse(l));
async function colonnes(){
  const r = await sql(`select table_schema||'.'||table_name t, json_agg(column_name order by ordinal_position) c from information_schema.columns
    where table_schema in ('public','interne') group by 1`);
  return Object.fromEntries(r.map(x => [x.t, x.c]));
}
const COL_JOUEUR = ["joueur","proprietaire","de","vers","ami","vendeur","acheteur","id"];   // colonnes qui pointent vers un compte

async function verifier(dir){
  const live = await colonnes(), comptes = new Set((await sql("select id from auth.users")).map(x => x.id));
  const fk = await sql(`select c.conrelid::regclass::text t, a.attname col from pg_constraint c join pg_attribute a on a.attrelid=c.conrelid and a.attnum = any(c.conkey)
    where c.contype='f' and c.confrelid='auth.users'::regclass`);
  const vers = {}; fk.forEach(x => { const t = x.t.includes(".") ? x.t : "public." + x.t; (vers[t] ||= []).push(x.col) });
  console.log(`Export : ${path.basename(dir)}   ·   comptes dans la base : ${comptes.size}`);
  let soucis = 0;
  for(const t of tablesDe(dir)){
    const L = lignes(dir, t), cols = live[t];
    if(!cols){ console.log(`  ${t.padEnd(28)} ${String(L.length).padStart(6)} lignes   ⚠ cette table n'existe plus dans la base : ignorée`); soucis++; continue }
    const exp = L[0] ? Object.keys(L[0]) : [], manque = exp.filter(c => !cols.includes(c)), nouv = cols.filter(c => L[0] && !(c in L[0]));
    const orphe = (vers[t] || []).reduce((n, c) => n + L.filter(r => r[c] && !comptes.has(r[c])).length, 0);
    const notes = [manque.length ? `colonnes disparues : ${manque.join(", ")}` : "", nouv.length ? `colonnes nouvelles (valeur par défaut) : ${nouv.join(", ")}` : "",
      orphe ? `${orphe} ligne(s) d'un compte supprimé (laissées de côté)` : ""].filter(Boolean);
    if(notes.length) soucis++;
    console.log(`  ${t.padEnd(28)} ${String(L.length).padStart(6)} lignes   ${notes.length ? "⚠ " + notes.join(" · ") : "ok"}`);
  }
  console.log(soucis ? `\n${soucis} table(s) avec une remarque (rien de bloquant si ce sont des colonnes nouvelles).` : "\nTout correspond.");
  return { live, comptes, vers };
}

async function copie(dir){
  const { live, comptes, vers } = await verifier(dir);
  console.log(`\nChargement dans le schéma « ${SCH} »…`);
  await sql(`drop schema if exists ${SCH} cascade; create schema ${SCH}; revoke all on schema ${SCH} from public, anon, authenticated;`);
  const bilan = [];
  for(const t of tablesDe(dir)){
    if(!live[t]) continue;
    const [s, n] = t.split("."), dst = `${SCH}.${id(s + "_" + n)}`;
    await sql(`create table ${dst} (like ${s}.${id(n)} including defaults)`);
    // un joueur dont le compte n'existe plus : ses lignes restent dans l'export, mais ne reviennent pas dans la base
    const L = lignes(dir, t).filter(r => !(vers[t] || []).some(c => r[c] && !comptes.has(r[c])));
    for(let i = 0; i < L.length; i += LOT){
      const lot = JSON.stringify(L.slice(i, i + LOT));
      await sql(`insert into ${dst} select * from jsonb_populate_recordset(null::${dst}, ${lit(lot)}::jsonb)`);
    }
    const [{ n: c }] = await sql(`select count(*)::int n from ${dst}`);
    bilan.push([t, L.length, c]); process.stdout.write(`  ${t.padEnd(28)} ${String(c).padStart(6)} / ${L.length}\n`);
  }
  const ko = bilan.filter(([, a, b]) => a !== b);
  console.log(ko.length ? `\n⚠ ${ko.length} table(s) incomplète(s) dans la copie.` : `\nCopie complète : ${bilan.reduce((a, x) => a + x[2], 0)} lignes dans « ${SCH} ».`);
  if(ko.length) throw new Error("copie incomplète");
  return bilan.map(([t]) => t);
}

async function remplacer(dir){
  if(!oui && !essai) throw new Error("Ajoute --oui pour vraiment remplacer les données du jeu (ou --essai pour tester sans rien changer).");
  const tables = await copie(dir), live = await colonnes();
  if(!essai){
    console.log("\nExport de sécurité de l'état actuel avant de remplacer…");
    execFileSync(process.execPath, [path.join(os.homedir(), "tikalo-backup.mjs")], { stdio:"inherit" });
  }
  // une seule requête, une seule transaction : on vide dans l'ordre inverse des liens, on remplit dans l'ordre,
  // les déclencheurs du jeu (notifications, mails, numérotation…) coupés pendant l'opération, les compteurs remis à niveau
  const q = ["begin;", "set local statement_timeout = '5min';"];
  for(const t of tables){ const [s, n] = t.split("."); q.push(`alter table ${s}.${id(n)} disable trigger user;`) }
  for(const t of [...tables].reverse()){ const [s, n] = t.split("."); q.push(`delete from ${s}.${id(n)};`) }
  for(const t of tables){
    const [s, n] = t.split("."), src = `${SCH}.${id(s + "_" + n)}`;
    const cols = live[t].filter(c => live[`${SCH}.${s}_${n}`]?.includes(c) ?? true).map(id).join(", ");
    q.push(`insert into ${s}.${id(n)} (${cols}) overriding system value select ${cols} from ${src};`);
  }
  for(const t of tables){ const [s, n] = t.split("."); q.push(`alter table ${s}.${id(n)} enable trigger user;`) }
  const ident = await sql(`select table_schema||'.'||table_name t, column_name c from information_schema.columns where table_schema in ('public','interne') and is_identity='YES'`);
  for(const { t, c } of ident) if(tables.includes(t)){ const [s, n] = t.split(".");
    q.push(`select setval(pg_get_serial_sequence('${s}.${id(n)}', '${c}'), greatest(coalesce((select max(${id(c)}) from ${s}.${id(n)}), 0), 1));`) }
  const compte = tables.map(t => { const [s, n] = t.split("."); return `select '${t}' t, count(*)::int n from ${s}.${id(n)}` }).join(" union all ");
  // essai : on lit les chiffres À L'INTÉRIEUR de la transaction, puis une erreur volontaire l'annule entièrement
  if(essai) q.push(`do $$ begin raise exception 'BILAN_ESSAI:%', (select json_object_agg(t, n) from (${compte}) x); end $$;`);
  else q.push("commit;");
  console.log(essai ? "\nEssai du remplacement (sera annulé)…" : "\nRemplacement des données du jeu…");
  if(essai){
    let dedans = null;
    try{ await sql(q.join("\n")) }catch(e){
      const m = e.message.match(/BILAN_ESSAI:(.*?\})/); if(!m) throw e;
      dedans = JSON.parse(m[1].replace(/\\"/g, '"')) }
    const att = Object.fromEntries((await sql(tables.map(t => { const [s, n] = t.split("."); return `select '${t}' t, count(*)::int n from ${SCH}.${id(s + "_" + n)}` }).join(" union all "))).map(x => [x.t, x.n]));
    console.log("Pendant la transaction (avant annulation), comparé à la copie de l'export :");
    let ok = true;
    for(const t of tables){ const bon = dedans?.[t] === att[t]; ok &&= bon; console.log(`  ${t.padEnd(28)} ${String(dedans?.[t]).padStart(6)} / ${String(att[t]).padStart(6)}  ${bon ? "ok" : "⚠"}`) }
    console.log(ok ? "Le remplacement remettrait exactement le contenu de l'export." : "⚠ Écarts : ne pas utiliser le remplacement sans vérifier.");
  } else await sql(q.join("\n"));
  const apres = Object.fromEntries((await sql(compte)).map(x => [x.t, x.n]));
  console.log(essai ? "Essai réussi : la transaction est passée, puis a été annulée. Données du jeu inchangées :" : "Remplacement terminé. Données du jeu maintenant :");
  for(const t of tables) console.log(`  ${t.padEnd(28)} ${String(apres[t]).padStart(6)}`);
}

try{
  if(mode === "verifier") await verifier(dossier());
  else if(mode === "copie") await copie(dossier());
  else if(mode === "remplacer") await remplacer(dossier());
  else if(mode === "nettoyer"){ await sql(`drop schema if exists ${SCH} cascade`); console.log(`Schéma « ${SCH} » supprimé.`) }
  else console.log("usage : node ~/tikalo-restaurer.mjs verifier|copie|remplacer|nettoyer [dossier] [--oui|--essai]");
}catch(e){ console.error("ÉCHEC : " + e.message); process.exit(1) }
