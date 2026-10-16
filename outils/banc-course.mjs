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
const NOMS = ["TAU","hash","rng","v3","g3Basis","G3","g3Kit","g3Zigzag","g3ZigStart","g3ZigCam","g3TableCam","g3Log","g3Trace","g3Trough","g3TroughStart","g3TroughEnd","g3Semis","g3Obstacles","g3Fourche","g3Funnel","g3Entonnoirs","g3FunnelCam","g3Trampo","g3ChaseCam","G3_ORDER","G3C","g3World","g3Where","g3Peloton","g3Simulate"];
const code = NOMS.map(decl).join("\n\n") + "\nreturn {G3C, G3_ORDER, g3Simulate, g3Where, G3};";

const [quels, nb = "30", lib = "cannon-es.js"] = process.argv.slice(2);
const CANNON = await import(pathToFileURL(path.resolve(lib)).href);
const J = new Function(code)();
if(process.env.PEL != null) J.G3.PEL = +process.env.PEL;   // PEL=0 : sans le peloton (pour comparer)
const ids = quels && quels !== "tous" ? quels.split(",") : Object.keys(J.G3C);

// on compte les pichenettes (et où elles tombent) en écoutant applyImpulse
let kicks = [];
const orig = CANNON.Body.prototype.applyImpulse;
CANNON.Body.prototype.applyImpulse = function(...a){ kicks.push([this.position.x, this.position.y, this.position.z]); return orig.apply(this, a) };

for(const id of ids){
  if(!J.G3C[id]){ console.log(`${id} : circuit inconnu`); continue }
  const res = []; const lieux = new Map(), cales = new Map(); const t0 = Date.now();
  for(let k=0; k<+nb; k++){
    const n = [8, 12, 16, 24][k % 4], seed = (Math.imul(k+1, 2654435761) >>> 0) || 1;
    kicks = [];
    const sim = J.g3Simulate(CANNON, seed, n, id);
    const ok = sim.fin.filter(x => x < 900);
    // le suspense : le classement toutes les demi-secondes (de 6 s jusqu'à l'arrivée du gagnant), comme à l'écran pendant la course
    const tWin = Math.min(...ok), DTs = J.G3.DT; let prev = null, tete = 0, places = 0, teteFin = 0, fige = 0, tFige = 6, cale = 0; const hist = [];
    for(let f = Math.round(6/DTs); f*DTs < tWin; f += Math.round(.5/DTs)){
      const F = sim.frames[Math.min(f, sim.frames.length-1)], t = f*DTs;
      const S = Array.from({length:n}, (_, i)=>J.g3Where(sim.W, F[i*7], F[i*7+1], F[i*7+2]).s);
      const rank = Array.from({length:n}, (_, i)=>({i, done:sim.fin[i] <= t, s:S[i]}))
        .sort((a, b)=> (a.done && b.done) ? sim.fin[a.i]-sim.fin[b.i] : a.done ? -1 : b.done ? 1 : b.s-a.s).map(x=>x.i);
      if(prev){ if(rank[0]!==prev[0]){ tete++; if(t > tWin*.6) teteFin++ } const pos = []; rank.forEach((b, k)=>pos[b] = k); prev.forEach((b, k)=>places += Math.abs(pos[b]-k))
        // figé : le plus long moment sans aucun changement dans les 4 premiers
        if(rank.slice(0, 4).some((b, k)=>b!==prev[k])) tFige = t; fige = Math.max(fige, t - tFige) }
      // calée : une bille pas arrivée qui a avancé de moins de 0,5 en 2 s (compte 0,5 s)
      if(hist.length >= 4) S.forEach((x, i)=>{ if(sim.fin[i] > t && x - hist[hist.length-4][i] < .5){ cale += .5; const key = [F[i*7], F[i*7+1], F[i*7+2]].map(v => Math.round(v/2)*2).join(","); cales.set(key, (cales.get(key)||0) + .5) } });
      hist.push(S); prev = rank;
    }
    res.push({n, win:tWin, last:Math.max(...ok), dnf:n-ok.length, kicks:kicks.length, tete, places:places/2/n, teteFin, fige, cale:cale/n});
    kicks.forEach(p => { const key = p.map(v => Math.round(v/2)*2).join(","); lieux.set(key, (lieux.get(key)||0) + 1) });
  }
  const moy = f => (res.reduce((a, r) => a + f(r), 0) / res.length);
  const top = [...lieux].sort((a, b) => b[1] - a[1]).slice(0, 5).map(([k, v]) => `(${k})×${v}`).join(" ");
  console.log(`${id.padEnd(12)} ${res.length} courses en ${((Date.now()-t0)/1000).toFixed(0)} s · gagnant ${moy(r=>r.win).toFixed(1)} s (min ${Math.min(...res.map(r=>r.win)).toFixed(1)}, max ${Math.max(...res.map(r=>r.win)).toFixed(1)})`
    + ` · dernier ${moy(r=>r.last).toFixed(1)} s (max ${Math.max(...res.map(r=>r.last)).toFixed(1)}) · pas arrivées ${res.reduce((a,r)=>a+r.dnf,0)}`
    + ` · pichenettes ${moy(r=>r.kicks).toFixed(1)}/course (max ${Math.max(...res.map(r=>r.kicks))})`
    + ` · SUSPENSE : ${moy(r=>r.tete).toFixed(1)} changements de tête (dont ${moy(r=>r.teteFin).toFixed(1)} dans les 40 % de la fin), ${moy(r=>r.places).toFixed(1)} places gagnées ou perdues par bille`
    + `, ${moy(r=>r.fige).toFixed(0)} s figé au plus (les 4 premiers), ${moy(r=>r.cale).toFixed(1)} s calée par bille, écart gagnant-dernier ${moy(r=>r.last-r.win).toFixed(0)} s`);
  if(top) console.log(`${"".padEnd(12)} pichenettes surtout vers ${top}`);
  const topC = [...cales].sort((a, b) => b[1] - a[1]).slice(0, 5).map(([k, v]) => `(${k})×${(v/res.length).toFixed(1)} s`).join(" ");
  if(topC) console.log(`${"".padEnd(12)} calées surtout vers ${topC} (par course)`);
}
