// Fabrique maquettes/event-decembre-rendu.js : le rendu des billes du jeu (extrait frais de index.html par outils/extraire-rendu.mjs)
// avec, en plus, les trois thèmes possibles de l'event du 1er décembre (maquettes/event-decembre.glsl, familles 130 à 132). index.html n'est pas touché.
// usage (depuis le dossier du projet) : node maquettes/fabriquer-event-decembre.mjs
import fs from "fs"; import os from "os"; import path from "path"; import {execFileSync} from "child_process";
const OUT = "maquettes/event-decembre-rendu.js";
const tmp = path.join(os.tmpdir(), "tikalo-evdec-extrait.mjs"), base = path.join(os.tmpdir(), "tikalo-evdec-base.js");
const ex = fs.readFileSync("outils/extraire-rendu.mjs", "utf8");
if(!ex.includes(`OUT = "maquettes/tikalo-demo-rendu.js"`)) throw new Error("extraire-rendu.mjs a changé");
fs.writeFileSync(tmp, ex.replace(`OUT = "maquettes/tikalo-demo-rendu.js"`, `OUT = ${JSON.stringify(base)}`));
execFileSync(process.execPath, [tmp], {stdio: "inherit"});
let js = fs.readFileSync(base, "utf8").replace(/\r\n/g, "\n");
const [outils, bloc] = fs.readFileSync("maquettes/event-decembre.glsl", "utf8").replace(/\r\n/g, "\n").split("//@@FAM\n");
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
patch("vec4 fam(vec3 q, out vec3 e){\n", outils.trimEnd() + "\nvec4 fam(vec3 q, out vec3 e){\n");
patch("#elif MODE==48\n  { // super-héros", bloc.trimEnd() + "\n#elif MODE==48\n  { // super-héros");
patch("|| MODE==116\n    const int GSTEPS=64;", "|| MODE==116 || MODE>=130\n    const int GSTEPS=64;");
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
