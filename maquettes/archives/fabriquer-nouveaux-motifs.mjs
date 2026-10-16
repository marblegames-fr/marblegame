// Fabrique maquettes/nouveaux-motifs-rendu.js : le rendu des billes de la maquette (tikalo-demo-rendu.js)
// avec, en plus, les nouveaux motifs à l'essai (maquettes/nouveaux-motifs.glsl, numéros 52 à 63)
// et les propositions de motif mythique (maquettes/mythique.glsl, numéros 64 à 67).
// Le jeu (index.html) n'est pas touché. usage (depuis le dossier du projet) : node maquettes/fabriquer-nouveaux-motifs.mjs
import fs from "fs";
const SRC = "maquettes/tikalo-demo-rendu.js", OUT = "maquettes/nouveaux-motifs-rendu.js";
let js = fs.readFileSync(SRC, "utf8").replace(/\r\n/g, "\n");
const lire = f => fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n").trimEnd() + "\n";
const glsl = lire("maquettes/nouveaux-motifs.glsl") + lire("maquettes/mythique.glsl");
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
// les nouveaux blocs, juste avant le motif par défaut (À pois)
patch("#else\n  { // à pois", glsl + "#else\n  { // à pois");
// Ambre (feuille fine), Feu d'artifice (rayons fins) et les mythiques : plus de pas dans le verre, comme l'Orage et la Méduse
patch("#elif MODE==32 || MODE==48 || MODE==50 || MODE==51", "#elif MODE==32 || MODE==48 || MODE==50 || MODE==51 || MODE==61 || MODE==63 || MODE>=64");
// Feu d'artifice et les mythiques : un verre de nuit, comme la Galaxie
patch("||s.family===51) tint", "||s.family===51||s.family>=63) tint");
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
