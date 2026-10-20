// Fabrique maquettes/motifs-2-rendu.js : le rendu des billes de la maquette (tikalo-demo-rendu.js)
// avec, en plus, les propositions de nouveaux motifs Commun et Peu commun (maquettes/motifs-2.glsl, numéros 65 à 75).
// Le jeu (index.html) n'est pas touché. usage (depuis le dossier du projet) : node maquettes/fabriquer-motifs-2.mjs
import fs from "fs";
const SRC = "maquettes/tikalo-demo-rendu.js", OUT = "maquettes/motifs-2-rendu.js";
let js = fs.readFileSync(SRC, "utf8").replace(/\r\n/g, "\n");
const glsl = fs.readFileSync("maquettes/motifs-2.glsl", "utf8").replace(/\r\n/g, "\n").trimEnd() + "\n";
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
// un petit outil des nouveaux motifs, juste avant fam() : la bille découpée en 6 faces de cube (pour les grilles : puzzle, labyrinthe)
patch("vec4 fam(vec3 q, out vec3 e){", `#if MODE==71 || MODE==72 || MODE==73
// xy : la place sur la face (-1..1, à angles égaux : les cases gardent presque la même taille jusqu'au bord), w : le numéro de la face
vec4 cubeF(vec3 u){ vec3 a=abs(u); vec2 p; float f;
  if(a.x>=a.y && a.x>=a.z){ p=vec2(u.z,u.y)/a.x; f=u.x>0.0?0.0:1.0; }
  else if(a.y>=a.z){ p=vec2(u.x,u.z)/a.y; f=u.y>0.0?2.0:3.0; }
  else { p=vec2(u.x,u.y)/a.z; f=u.z>0.0?4.0:5.0; }
  return vec4(atan(p)*1.2732395, 0.0, f); }
#endif
vec4 fam(vec3 q, out vec3 e){`);
// les nouveaux blocs, juste avant le motif par défaut (À pois)
patch("#else\n  { // à pois", glsl + "#else\n  { // à pois");
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
