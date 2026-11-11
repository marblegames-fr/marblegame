// Fabrique maquettes/couleurs-rendu.js : le rendu de la maquette « Les 3 couleurs » (11 novembre 2026),
// à partir de tikalo-demo-rendu.js (node outils/extraire-rendu.mjs d'abord), avec les versions « après » de maquettes/couleurs-apres.glsl :
// le motif N du jeu devient 300 + N (Étoilée 352, Vagues 355, Zigzag 356, Tricot 357, Nuages 358, Jean 360, Circuit 362, Plasma A 415),
// et 515 = Plasma B. Les décalages sont des multiples de 4 : la bille garde le même dessin (même graine, même figure).
// Le jeu (index.html) n'est pas touché. usage (depuis le dossier du projet) : node maquettes/fabriquer-couleurs.mjs
import fs from "fs";
const rd = f => fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n");
let js = rd("maquettes/tikalo-demo-rendu.js");
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
patch("#else\n  { // à pois", rd("maquettes/couleurs-apres.glsl").trimEnd() + "\n#else\n  { // à pois");
// le Plasma : plus de pas dans le verre et le verre de nuit, comme le 115
patch("|| MODE==115 || MODE==116\n", "|| MODE==115 || MODE==116 || MODE==415 || MODE==515\n");
patch("s.family===115) tint", "s.family===115||s.family===415||s.family===515) tint");
fs.writeFileSync("maquettes/couleurs-rendu.js", js);
console.log("maquettes/couleurs-rendu.js", (js.length/1024).toFixed(0), "Ko");
