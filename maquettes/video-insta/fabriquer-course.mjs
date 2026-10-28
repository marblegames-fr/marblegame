// Recopie la physique de la Grande Course (les circuits et la simulation de index.html) dans course-moteur.js,
// pour la vidéo demo-course.html : la course de la vidéo est calculée exactement comme dans le jeu.
// usage (depuis le dossier du projet) : node maquettes/video-insta/fabriquer-course.mjs   (à relancer si les circuits changent)
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
const out = "// Fichier fabriqué par fabriquer-course.mjs à partir de index.html : ne pas modifier à la main.\n"
  + "window.COURSE = (() => {\n" + NOMS.map(decl).join("\n\n") + "\nreturn {G3C, G3, g3Simulate, g3Where, v3, TAU};\n})();\n";
fs.writeFileSync("maquettes/video-insta/course-moteur.js", out);
console.log("course-moteur.js :", Math.round(out.length/1024), "Ko");
