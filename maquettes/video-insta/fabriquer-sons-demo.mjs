// Fabrique maquettes/video-insta/tikalo-demo-sons.js à partir de index.html : les vrais sons enregistrés (sachet secoué, rebonds de bille)
// et la boîte à musique de l'ouverture (« Égrené », les signatures des shiny), pour les vidéos demo-asmr.html et demo-defi.html.
// Lancer depuis le dossier du projet : node maquettes/video-insta/fabriquer-sons-demo.mjs
import fs from "node:fs";
const src = fs.readFileSync("index.html", "utf8").split("\n");
const find = (re, from = 0) => { for(let i = from; i < src.length; i++) if(re.test(src[i])) return i; throw new Error("introuvable : " + re) };

const wav = ["HIT_SLICES", "HIT_WAV", "SHAKE_SLICES", "SHAKE_WAV"].map(n => src[find(new RegExp(`^const ${n} *=`))]);
const mb0 = find(/^\s*const MB = \(\(\)=>\{/), a = find(/^const NOTE = st =>/, mb0), b = find(/^\s{4}return \{/, a);
const body = src.slice(a, b).join("\n");

const out = `/* Extrait automatique de index.html du ${new Date().toISOString().slice(0,10)} (maquettes/video-insta/fabriquer-sons-demo.mjs). Ne pas modifier à la main : relancer. */
${wav.join("\n")}
// la boîte à musique du jeu (ouverture « Égrené », shiny, mythique) branchée sur un AudioContext donné
function makeMB(ctx, master){
  const noiseBuf = ctx.createBuffer(1, ctx.sampleRate*2, ctx.sampleRate); { const d = noiseBuf.getChannelData(0); for(let i=0;i<d.length;i++) d[i] = Math.random()*2-1 }
  let revIn = null, last = null;
${body}
  return {bus, egrene, shinyIri, shinyGold, shinyLum, EG, ORCH, mbox, chime, glock, boom, riser, swell, cymbal, thud, choir, harp, sparkle, strings, NOTE,
    myth(d, t){ boom(d, t, .7); cymbal(d, t, .13, 3.4); [-12,-5,4].forEach((n,i)=>choir(d, t, NOTE(n), .055-.01*i, 3.2)); strings(d, t, NOTE(-24), .035, 3);
      [0,7,12,16,19,24,28,31,36].forEach((n,i)=>chime(d, t+.15+i*.06, NOTE(n), .045, 2.2)); sparkle(d, t+.7, 30, .05, .026, mbox, 1800, 3400) }};
}
`;
fs.writeFileSync("maquettes/video-insta/tikalo-demo-sons.js", out);
console.log("maquettes/video-insta/tikalo-demo-sons.js :", (out.length/1024).toFixed(0), "Ko");
