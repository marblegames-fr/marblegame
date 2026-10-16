// (16 octobre 2026) Banc d'essai de la Pichenette : des parties ordi contre ordi (même niveau des deux côtés) sur chaque terrain,
// pour voir si celui qui commence est avantagé, avec ou sans les règles qui l'en empêchent.
// node maquettes/banc-pichenette.mjs [parties par terrain] → écrit maquettes/pichenette-banc.json (lu par la maquette)
import {createRequire} from "module";
import {writeFileSync} from "fs";
const require = createRequire(import.meta.url), P = require("./pichenette-moteur.js");
const N = +process.argv[2] || 150;
const VARIANTES = {
  libre:{nom:"Sans règle spéciale", desc:"l'ouverture rejoue, on rejoue tant qu'on marque", r:{ouverture:true, enchaine:99}},
  propose:{nom:"Règles proposées", desc:"l'ouverture ne rejoue pas, 3 tirs d'affilée au plus", r:{ouverture:false, enchaine:3}},
};
const out = {date:new Date().toISOString().slice(0, 10), parties:N, niveau:"moyen", res:{}};
for(const [vk, V] of Object.entries(VARIANTES)){
  out.res[vk] = {nom:V.nom, desc:V.desc, cartes:{}};
  for(const id of Object.keys(P.MAPS)){
    let first = 0, egal = 0, tirs = 0, ecart = 0, t0 = Date.now();
    for(let g=0; g<N; g++){
      const r = P.rng(5000 + g*7919), G = P.newGame(id, V.r, g);
      // qui commence : tiré au sort ici (on mesure l'avantage de commencer, pas l'adresse à la mise en jeu)
      G.phase = "play"; G.turn = g%2; const f = G.turn; let k = 0;
      while(G.phase==="play" && k<80){ P.play(G, P.botShot(G, "moyen", r)); k++ }
      if(G.phase==="egalite") egal++; else if(G.winner===f) first++;
      tirs += k; ecart += Math.abs(G.score[0] - G.score[1]) }
    out.res[vk].cartes[id] = {commence:Math.round(first/N*100), egalite:Math.round(egal/N*100), second:Math.round((N-first-egal)/N*100), tirs:+(tirs/N).toFixed(1), ecart:+(ecart/N).toFixed(1)};
    console.log(V.nom.padEnd(22), id.padEnd(11), JSON.stringify(out.res[vk].cartes[id]), `${((Date.now()-t0)/1000).toFixed(0)} s`);
  }
}
writeFileSync(new URL("./pichenette-banc.json", import.meta.url), JSON.stringify(out, null, 1));
console.log("écrit : maquettes/pichenette-banc.json");
