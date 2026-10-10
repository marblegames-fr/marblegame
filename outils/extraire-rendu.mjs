// Fabrique maquettes/tikalo-demo-rendu.js à partir de index.html : les données du jeu, le rendu WebGL des billes,
// les icônes et les sachets, et les dessins dont la vidéo promo a besoin (aperçus des jeux, marelle, distributeur, chaudron).
// usage (depuis le dossier du projet) : node outils/extraire-rendu.mjs
// À relancer quand le rendu des billes, les motifs, les coloris ou les dessins des jeux changent.
import fs from "fs";
const SRC = "index.html", OUT = "maquettes/tikalo-demo-rendu.js";
const L = fs.readFileSync(SRC, "utf8").split(/\r?\n/);
const titre = t => L.findIndex((l, i) => l.startsWith("/* ====") && (L[i + 1] || "").trim().startsWith(t));
// une section entière : de son titre jusqu'au titre de section suivant
function section(t){
  const a = titre(t); if(a < 0) throw new Error("section introuvable : " + t);
  let b = a + 1; while(b < L.length && !(L[b].startsWith("/* ====") && b > a + 2)) b++;
  return L.slice(a, b).join("\n");
}
// une déclaration de premier niveau, par son nom : jusqu'à la prochaine ligne qui commence une autre instruction en colonne 0
const DEBUT = /^(const|let|var|function|async function|class|\/\*|\/\/|document\.|addEventListener|setInterval|setTimeout|window\.|try\b|if\b|for\b|\(|<\/script>)/;
function decl(nom){
  const re = new RegExp(`^(?:const|let|var|function|async function)\\s+${nom.replace(/\$/g, "\\$")}\\b`);
  const a = L.findIndex(l => re.test(l)); if(a < 0) throw new Error("déclaration introuvable : " + nom);
  let b = a + 1; while(b < L.length && !DEBUT.test(L[b])) b++;
  return L.slice(a, b).join("\n");
}
const morceaux = [
  section("DONNÉES DU JEU"), section("OUTILS"), section("BILLES : génération"),
  // icônes et sachets (de ICON jusqu'à bagSVG compris)
  (() => { const a = L.findIndex(l => /^const ICON = \{/.test(l)), b0 = L.findIndex(l => /^function bagSVG\(/.test(l));
    let b = b0 + 1; while(b < L.length && L[b] !== "}") b++; return L.slice(a, b + 1).join("\n") })(),
  // les aperçus des jeux et ce qu'ils utilisent
  ...["cbClamp","cbShade","ROUE","ROUE_SEG","artM","artDirt","ART_SVG","artPot","artChateau","artTic","artTir","artCasse","artPachinko","artRoue",
      "artGrattage","artDistributeur","artMarelle","artLoterie"].map(decl),
  // la marelle en perspective, le distributeur, le chaudron de la fusion
  ...["MAR_CASES","MAR_W","marS","marP","MAR_FY","marFlat","marLot","marCaseOfK","f1","marShape","marMid","marLabel","marPrize","marDecor","marBoard",
      "DS_COLS","distMachine","CZ_SH","czPot","LOGO_SPEC"].map(decl),
];
const date = new Date().toISOString().slice(0, 10);
fs.writeFileSync(OUT, `/* Extrait automatique de index.html du ${date} (outils/extraire-rendu.mjs) : données, rendu WebGL des billes, icônes, sachets,\n   aperçus des jeux, marelle, distributeur, chaudron. Ne pas modifier à la main : relancer l'extraction. */\n` + morceaux.join("\n\n") + "\n");
console.log(`${OUT} : ${morceaux.length} morceaux, ${(fs.statSync(OUT).size / 1024).toFixed(0)} Ko`);
