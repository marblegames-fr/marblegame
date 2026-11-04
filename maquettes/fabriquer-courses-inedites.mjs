// Fabrique maquettes/courses-inedites-moteur.js : le moteur de la Grande Course recopié de index.html (comme pour la vidéo)
// + les circuits de la maquette (maquettes/courses-inedites.js), pour maquette-courses-inedites.html.
// usage (depuis le dossier du projet) : node maquettes/fabriquer-courses-inedites.mjs   (à relancer après chaque changement)
import fs from "fs";

const L = fs.readFileSync("index.html", "utf8").split(/\r?\n/);
const DEBUT = /^(const|let|var|function|async function|class|\/\*|\/\/|document\.|addEventListener|setInterval|setTimeout|window\.|try\b|if\b|for\b|\(|<\/script>)/;
function decl(nom){
  const re = new RegExp(`^(?:const|let|var|function|async function)\\s+${nom}\\b`);
  const a = L.findIndex(l => re.test(l)); if(a < 0) throw new Error("déclaration introuvable : " + nom);
  let b = a + 1; while(b < L.length && !DEBUT.test(L[b])) b++;
  return L.slice(a, b).join("\n");
}
// les mêmes morceaux que outils/banc-course.mjs
const NOMS = ["TAU","hash","rng","v3","g3Basis","G3","g3Kit","g3Zigzag","g3ZigStart","g3ZigCam","g3TableCam","g3Log","g3Trace","g3Trough","g3TroughStart","g3TroughEnd","g3Semis","g3Obstacles","g3Fourche","g3Funnel","g3Entonnoirs","g3FunnelCam","g3Trampo","g3ChaseCam","G3_ORDER","G3C","g3World","g3Where","g3Peloton","g3Simulate"];
const extra = fs.readFileSync("maquettes/courses-inedites.js", "utf8");
const out = "// Fichier fabriqué par fabriquer-courses-inedites.mjs (index.html + courses-inedites.js) : ne pas modifier à la main.\n"
  + "window.COURSE = (() => {\n" + NOMS.map(decl).join("\n\n") + "\n" + extra + "\nreturn {G3C, G3, g3Simulate, g3Where, v3, rng, hash};\n})();\n";
fs.writeFileSync("maquettes/courses-inedites-moteur.js", out);
console.log("courses-inedites-moteur.js :", Math.round(out.length/1024), "Ko");
