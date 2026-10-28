// Fabrique maquettes/mythique-2-rendu.js : le rendu des billes de la maquette (tikalo-demo-rendu.js, avec le Vortex en 64)
// avec, en plus, les nouvelles propositions de motif mythique (maquettes/mythique-2.glsl, numéros 65 à 70).
// Le jeu (index.html) n'est pas touché. usage (depuis le dossier du projet) : node maquettes/fabriquer-mythique-2.mjs
import fs from "fs";
const SRC = "maquettes/tikalo-demo-rendu.js", OUT = "maquettes/mythique-2-rendu.js";
let js = fs.readFileSync(SRC, "utf8").replace(/\r\n/g, "\n");
const glsl = fs.readFileSync("maquettes/mythique-2.glsl", "utf8").replace(/\r\n/g, "\n").trimEnd() + "\n";
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
// les petits outils des nouveaux motifs, juste avant fam()
patch("vec4 fam(vec3 q, out vec3 e){", `#if MODE>=65
mat2 mrot(float a){ float c=cos(a), s=sin(a); return mat2(c,s,-s,c); }
float segM(vec2 p, vec2 a, vec2 b){ vec2 pa=p-a, ba=b-a; return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0)); }
#endif
#if MODE==66
// un sommet de l'hypercube : rotation dans le plan xw (le retournement) et yz, perspective 4D → 3D, puis une inclinaison fixe.
// w : la profondeur en 4D (0 = cube du fond, 1 = cube de devant), pour la couleur
vec4 tesP(vec4 v, float A){
  float c=cos(A), s=sin(A);
  v=vec4(c*v.x-s*v.w, v.y, v.z, s*v.x+c*v.w);
  v=vec4(v.x, c*v.y-s*v.z, s*v.y+c*v.z, v.w);
  float k=1.0/(2.6-v.w);
  vec3 p=v.xyz*k*0.62;
  p=vec3(p.x, 0.94*p.y-0.34*p.z, 0.34*p.y+0.94*p.z);
  p=vec3(0.9*p.x+0.44*p.z, p.y, -0.44*p.x+0.9*p.z);
  return vec4(p, (k-0.278)/0.347);
}
#endif
vec4 fam(vec3 q, out vec3 e){`);
// les nouveaux blocs, juste avant le motif par défaut (À pois)
patch("#else\n  { // à pois", glsl + "#else\n  { // à pois");
// plus de pas dans le verre et un verre de nuit, comme le Vortex
patch("|| MODE==61 || MODE==63 || MODE==64\n", "|| MODE==61 || MODE==63 || MODE>=64\n");
patch("||s.family===64) tint", "||s.family>=64) tint");
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
