// Fabrique maquettes/course-lourde-moteur.js : le moteur de la Grande Course recopié de index.html, pour maquette-course-lourde.html
// (G3.PHY : gravité, rebonds, frottements, vitesse max ; vide = la physique d'avant le 7 novembre au soir).
// usage (depuis le dossier du projet) : node maquettes/fabriquer-course-lourde.mjs   (à relancer après chaque changement de index.html)
import fs from "fs";

const L = fs.readFileSync("index.html", "utf8").split(/\r?\n/);
const DEBUT = /^(const|let|var|function|async function|class|\/\*|\/\/|document\.|addEventListener|setInterval|setTimeout|window\.|try\b|if\b|for\b|\(|<\/script>)/;
function decl(nom){
  const re = new RegExp(`^(?:const|let|var|function|async function)\\s+${nom}\\b`);
  const a = L.findIndex(l => re.test(l)); if(a < 0) throw new Error("déclaration introuvable : " + nom);
  let b = a + 1; while(b < L.length && !DEBUT.test(L[b])) b++;
  return L.slice(a, b).join("\n");
}
const NOMS = ["TAU","hash","rng","v3","g3Basis","G3","g3Kit","g3Zigzag","g3ZigStart","g3ZigCam","g3TableCam","g3Log","g3Trace","g3Trough","g3TroughStart","g3TroughEnd","g3Semis","g3Obstacles","g3Fourche","g3Funnel","g3Entonnoirs","g3FunnelCam","g3Trampo","g3ChaseCam","g3Rotor","g3Deco","g3Tour","g3Couloirs","G3_ORDER","G3C","g3World","g3Where","g3Peloton","g3Simulate"];
let code = NOMS.map(decl).join("\n\n");

// (7 novembre 2026) les billes lourdes sont dans le jeu (G3.PHY, G3_LOURD dans index.html) : plus rien à remplacer, la maquette passe G3.PHY elle-même
const out = "// Fichier fabriqué par fabriquer-course-lourde.mjs (copie du moteur de index.html, physique réglable par G3.PHY) : ne pas modifier à la main.\n"
  + "window.COURSE = (() => {\n" + code + "\nreturn {G3C, G3, G3_ORDER, g3Simulate, g3Where, v3, rng, hash};\n})();\n";
fs.writeFileSync("maquettes/course-lourde-moteur.js", out);
console.log("course-lourde-moteur.js :", Math.round(out.length/1024), "Ko");
