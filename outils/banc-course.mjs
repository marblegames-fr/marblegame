// Banc d'essai de la Grande Course : fait tourner la vraie physique des circuits (celle de index.html) sans navigateur,
// sur beaucoup de courses, et dit pour chaque circuit : temps du gagnant et du dernier, billes jamais arrivées,
// pichenettes (une bille calée plus de 4 s) et l'endroit où elles arrivent le plus.
// usage (depuis le dossier du projet) : node outils/banc-course.mjs [circuit,circuit…] [nombre de courses] [chemin de cannon-es.js]
//   ex. : node outils/banc-course.mjs toboggan 40 ../lib/cannon-es.js
// cannon-es : https://cdn.jsdelivr.net/npm/cannon-es@0.20.0/dist/cannon-es.js (la même version que le site), à télécharger une fois.
import fs from "fs";
import path from "path";
import { pathToFileURL } from "url";

const L = fs.readFileSync("index.html", "utf8").split(/\r?\n/);
const DEBUT = /^(const|let|var|function|async function|class|\/\*|\/\/|document\.|addEventListener|setInterval|setTimeout|window\.|try\b|if\b|for\b|\(|<\/script>)/;
function decl(nom){
  const re = new RegExp(`^(?:const|let|var|function|async function)\\s+${nom}\\b`);
  const a = L.findIndex(l => re.test(l)); if(a < 0) throw new Error("déclaration introuvable : " + nom);
  let b = a + 1; while(b < L.length && !DEBUT.test(L[b])) b++;
  return L.slice(a, b).join("\n");
}
const NOMS = ["TAU","hash","rng","v3","g3Basis","G3","g3Kit","g3Zigzag","g3ZigStart","g3ZigCam","g3TableCam","g3Log","G3_ORDER","G3C","g3World","g3Where","g3Simulate"];
const code = NOMS.map(decl).join("\n\n") + "\nreturn {G3C, G3_ORDER, g3Simulate, g3Where, G3};";

const [quels, nb = "30", lib = "cannon-es.js"] = process.argv.slice(2);
const CANNON = await import(pathToFileURL(path.resolve(lib)).href);
const J = new Function(code)();
const ids = quels && quels !== "tous" ? quels.split(",") : Object.keys(J.G3C);

// on compte les pichenettes (et où elles tombent) en écoutant applyImpulse
let kicks = [];
const orig = CANNON.Body.prototype.applyImpulse;
CANNON.Body.prototype.applyImpulse = function(...a){ kicks.push([this.position.x, this.position.y, this.position.z]); return orig.apply(this, a) };

for(const id of ids){
  if(!J.G3C[id]){ console.log(`${id} : circuit inconnu`); continue }
  const res = []; const lieux = new Map(); const t0 = Date.now();
  for(let k=0; k<+nb; k++){
    const n = [8, 12, 16, 24][k % 4], seed = (Math.imul(k+1, 2654435761) >>> 0) || 1;
    kicks = [];
    const sim = J.g3Simulate(CANNON, seed, n, id);
    const ok = sim.fin.filter(x => x < 900);
    res.push({n, win:Math.min(...ok), last:Math.max(...ok), dnf:n-ok.length, kicks:kicks.length});
    kicks.forEach(p => { const key = p.map(v => Math.round(v/2)*2).join(","); lieux.set(key, (lieux.get(key)||0) + 1) });
  }
  const moy = f => (res.reduce((a, r) => a + f(r), 0) / res.length);
  const top = [...lieux].sort((a, b) => b[1] - a[1]).slice(0, 5).map(([k, v]) => `(${k})×${v}`).join(" ");
  console.log(`${id.padEnd(12)} ${res.length} courses en ${((Date.now()-t0)/1000).toFixed(0)} s · gagnant ${moy(r=>r.win).toFixed(1)} s (min ${Math.min(...res.map(r=>r.win)).toFixed(1)}, max ${Math.max(...res.map(r=>r.win)).toFixed(1)})`
    + ` · dernier ${moy(r=>r.last).toFixed(1)} s (max ${Math.max(...res.map(r=>r.last)).toFixed(1)}) · pas arrivées ${res.reduce((a,r)=>a+r.dnf,0)}`
    + ` · pichenettes ${moy(r=>r.kicks).toFixed(1)}/course (max ${Math.max(...res.map(r=>r.kicks))})`);
  if(top) console.log(`${"".padEnd(12)} pichenettes surtout vers ${top}`);
}
