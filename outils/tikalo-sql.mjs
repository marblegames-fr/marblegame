// usage : node ~/tikalo-sql.mjs "requête"   ou   node ~/tikalo-sql.mjs -f fichier.sql
import fs from "fs"; import os from "os";
const T = fs.readFileSync(os.homedir() + "/.tikalo-supabase-token", "utf8").trim();
const q = process.argv[2] === "-f" ? fs.readFileSync(process.argv[3], "utf8") : process.argv[2];
const r = await fetch("https://api.supabase.com/v1/projects/gflnjqxtxqxoybaaaszp/database/query",
  { method: "POST", headers: { Authorization: "Bearer " + T, "Content-Type": "application/json" }, body: JSON.stringify({ query: q }) });
const t = await r.text();
console.log(r.status, t.length > 3000 ? t.slice(0, 3000) + "…" : t);
