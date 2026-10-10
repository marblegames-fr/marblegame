// Export des données de Tikalo (Supabase) vers le PC : un dossier daté par export, les 30 derniers sont gardés.
// usage : node ~/tikalo-backup.mjs        (lancé chaque jour par la tâche planifiée « Tikalo - export Supabase »)
// Contenu : toutes les tables des schémas public et interne (une ligne JSON par ligne de table),
// plus la liste des comptes (id, e-mail, dates) SANS les mots de passe.
import fs from "fs"; import os from "os"; import path from "path";
const DEST = path.join(os.homedir(), "OneDrive", "Documents", "Marble Games", "sauvegardes-donnees");   // dans le dossier du projet, ignoré par git (.gitignore)
const KEEP = 30, PAGE = 2000;
const T = fs.readFileSync(os.homedir() + "/.tikalo-supabase-token", "utf8").trim();
const LOG = path.join(DEST, "journal.txt");
fs.mkdirSync(DEST, { recursive: true });
const log = m => { const l = `${new Date().toISOString()}  ${m}\n`; fs.appendFileSync(LOG, l); process.stdout.write(l) };

async function sql(q){
  const r = await fetch("https://api.supabase.com/v1/projects/gflnjqxtxqxoybaaaszp/database/query",
    { method: "POST", headers: { Authorization: "Bearer " + T, "Content-Type": "application/json" }, body: JSON.stringify({ query: q }) });
  const t = await r.text();
  if(!r.ok) throw new Error(`HTTP ${r.status} : ${t.slice(0, 300)}${r.status === 401 ? "  (le jeton d'accès Supabase a sans doute expiré : en créer un nouveau)" : ""}`);
  return JSON.parse(t);
}

try{
  const stamp = new Date().toISOString().slice(0, 16).replace(/[:T]/g, "-");
  const dir = path.join(DEST, stamp), tmp = dir + ".en-cours";
  fs.mkdirSync(tmp, { recursive: true });
  const tables = await sql(`select table_schema s, table_name t from information_schema.tables
    where table_schema in ('public','interne') and table_type = 'BASE TABLE' order by 1, 2`);
  const resume = {};
  for(const { s, t } of tables){
    const out = fs.createWriteStream(path.join(tmp, `${s}.${t}.jsonl`));
    let n = 0;
    for(let off = 0; ; off += PAGE){
      const rows = await sql(`select to_jsonb(x) j from "${s}"."${t}" x order by ctid limit ${PAGE} offset ${off}`);
      for(const r of rows) out.write(JSON.stringify(r.j) + "\n");
      n += rows.length; if(rows.length < PAGE) break;
    }
    await new Promise(r => out.end(r));
    resume[`${s}.${t}`] = n;
  }
  const comptes = await sql(`select id, email, created_at, last_sign_in_at, email_confirmed_at, raw_user_meta_data from auth.users order by created_at`);
  fs.writeFileSync(path.join(tmp, "auth.comptes.json"), JSON.stringify(comptes, null, 1));
  resume["auth.comptes (sans mots de passe)"] = comptes.length;
  fs.writeFileSync(path.join(tmp, "resume.json"), JSON.stringify({ date: new Date().toISOString(), lignes: resume }, null, 1));
  fs.renameSync(tmp, dir);
  // on ne garde que les KEEP derniers exports
  const old = fs.readdirSync(DEST).filter(f => /^\d{4}-\d\d-\d\d-\d\d-\d\d$/.test(f)).sort().slice(0, -KEEP);
  for(const f of old) fs.rmSync(path.join(DEST, f), { recursive: true, force: true });
  log(`OK  ${stamp}  ${Object.values(resume).reduce((a, b) => a + b, 0)} lignes, ${tables.length} tables${old.length ? `, ${old.length} ancien(s) export(s) supprimé(s)` : ""}`);
}catch(e){
  log("ÉCHEC  " + e.message);
  process.exit(1);
}
