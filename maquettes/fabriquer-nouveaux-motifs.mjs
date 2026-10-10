// Fabrique maquettes/nouveaux-motifs-rendu.js : le rendu des billes de la maquette (tikalo-demo-rendu.js)
// avec, en plus, les nouveaux motifs à l'essai (maquettes/nouveaux-motifs.glsl, numéros 52 et suivants).
// Le jeu (index.html) n'est pas touché. usage (depuis le dossier du projet) : node maquettes/fabriquer-nouveaux-motifs.mjs
import fs from "fs";
const SRC = "maquettes/tikalo-demo-rendu.js", OUT = "maquettes/nouveaux-motifs-rendu.js";
let js = fs.readFileSync(SRC, "utf8").replace(/\r\n/g, "\n");
const glsl = fs.readFileSync("maquettes/nouveaux-motifs.glsl", "utf8").replace(/\r\n/g, "\n").trimEnd() + "\n";
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
// les nouveaux blocs, juste avant le motif par défaut (À pois)
patch("#else\n  { // à pois", glsl + "#else\n  { // à pois");
// Ambre (feuille fine) et Feu d'artifice (rayons fins) : plus de pas dans le verre, comme l'Orage et la Méduse
patch("#elif MODE==32 || MODE==48 || MODE==50 || MODE==51", "#elif MODE==32 || MODE==48 || MODE==50 || MODE==51 || MODE==61 || MODE==63");
// Feu d'artifice : un verre de nuit, comme la Galaxie
patch("||s.family===51) tint", "||s.family===51||s.family===63) tint");
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
