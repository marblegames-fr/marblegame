/* Extrait automatique de index.html (données, rendu WebGL des billes, icônes, sacs, dessins des jeux) pour la maquette. Ne pas modifier à la main. */
/* =====================================================================
   DONNÉES DU JEU
   ===================================================================== */
const CUR = {one:"bonbec", many:"bonbecs"};         // la monnaie de la cour : des bonbecs !
const FREE_EVERY = 10*60*1000;                        // un sac gratuit toutes les 10 minutes

// Formats, du plus courant au plus rare (leur couleur = leur rareté)
const TYPES = {
  mini:    {label:"Mini bille", pl:"Mini billes", mm:10, rc:"#7C7A8A", rb:"#ECEAE6", desc:"La plus petite de la cour. Légère et rapide."},
  bille:   {label:"Bille",      pl:"Billes",      mm:16, rc:"#2F8F45", rb:"#DAF2D6", desc:"Le format classique, celui de toutes les parties."},
  chinoise:{label:"Bille chinoise", pl:"Billes chinoises", mm:18, rc:"#0E9C9C", rb:"#D3F2F0", desc:"Un peu ovale, elle roule de travers : impossible de prévoir où elle va s'arrêter."},
  calot:   {label:"Calot",      pl:"Calots",      mm:25, rc:"#2E6BE6", rb:"#DCE7FC", desc:"Le gros format qui impressionne les copains."},
  boulet:  {label:"Boulet",     pl:"Boulets",     mm:35, rc:"#8A4AD6", rb:"#ECDDFB", desc:"Si gros qu'il tient à peine dans la poche."},
  mammouth: {label:"Mammouth",   pl:"Mammouths",   mm:40, rc:"#D97E06", rb:"#FDEAC4", desc:"Le géant de la cour : il faut presque deux mains pour le lancer."},
};
const TK = Object.keys(TYPES);
const TIDX = Object.fromEntries(TK.map((k,i)=>[k,i]));
const scaleOf = t => .5 + .5*(TYPES[t].mm-10)/30;   // taille d'affichage proportionnelle au diamètre

// Familles de décor (chacune a son propre rendu)
// Fréquence des décors (poids de tirage). Les noms ne s'affichent plus : la rareté, c'est la taille.
const DECOR_RAR = [
  {name:"Commun",     w:10, c:"#8E8898"},
  {name:"Peu commun", w:5,  c:"#2F8F45"},
  {name:"Rare",       w:2.5,c:"#2E6BE6"},
  {name:"Épique",     w:.8, c:"#8A4AD6"},
  {name:"Légendaire", w:.2, c:"#D97E06"},
];
// Familles de décor (chacune a son propre rendu). L'ordre ne doit pas changer : il sert d'identifiant.
const FAMILIES = [
  {name:"Œil-de-chat", rar:0, desc:"Des pétales de verre coloré pris au cœur de la bille."},
  {name:"Tourbillon",  rar:1, desc:"Des rubans torsadés qui s'enroulent dans le verre."},
  {name:"Galaxie",     rar:4, desc:"Un verre sombre avec des nébuleuses et des étoiles."},
  {name:"Agate",       rar:2, desc:"Une pierre opaque, veinée comme une vraie agate."},
  {name:"Opaline",     rar:0, desc:"Un verre laiteux qui garde la lumière."},
  {name:"Pailletée",   rar:2, desc:"Un verre teinté rempli de paillettes."},
  {name:"Oignon",      rar:0, desc:"Une couche colorée étirée juste sous la surface."},
  {name:"Berlingot",   rar:1, desc:"Des rayures de sucre d'orge, opaques et brillantes."},
  {name:"Terre",       rar:0, desc:"La bille des grands-parents : de l'argile cuite, peinte à la main."},
  {name:"Acier",       rar:3, desc:"Une bille de roulement en acier poli, lourde et brillante comme un miroir."},
  {name:"Nacrée",      rar:3, desc:"Un reflet de perle qui change de couleur selon l'angle."},
  {name:"Cristal",     rar:0, desc:"Un verre clair où sont restées prisonnières de petites bulles d'air."},
  {name:"Arlequin",    rar:2, desc:"Des taches de couleur opaques cousues comme un patchwork."},
  {name:"Ruban",       rar:1, desc:"Un ruban plat et torsadé en plein cœur du verre."},
  {name:"Millefiori",  rar:2, desc:"Des centaines de petites fleurs de verre, comme à Venise."},
  {name:"Givrée",      rar:0, desc:"Un verre dépoli, doux comme le givre sur une vitre."},
  {name:"Fumée",       rar:1, desc:"Des volutes de fumée prisonnières du verre."},
  {name:"Lave",        rar:3, desc:"Une roche sombre traversée de fissures brûlantes."},
  {name:"Marbre",      rar:1, desc:"Une pierre blanche veinée, comme un escalier de palais."},
  {name:"Tigrée",      rar:2, desc:"Des rayures sauvages de grand fauve."},
  {name:"À pois",      rar:0, desc:"Des pois bien ronds, comme une coccinelle."},
  {name:"Damier",      rar:0, desc:"Des cases bien nettes qui font le tour de la bille, comme un ballon de plage."},
  {name:"Écossais",    rar:1, desc:"Un tartan tissé serré, comme la couverture de pique-nique."},
  {name:"Nid d'abeille", rar:1, desc:"Des alvéoles de cire pleines de miel."},
  {name:"Cible",       rar:0, desc:"Des anneaux bien ronds : vise le centre !"},
  {name:"Pixel",       rar:1, desc:"De gros carrés, comme dans les vieux jeux vidéo."},
  {name:"Globe",       rar:3, desc:"Des océans, des continents et des nuages : un monde entier dans la main."},
  {name:"Planète",     rar:2, desc:"Des bandes de nuages géantes et une tempête qui tourne depuis toujours."},
  {name:"Bois",        rar:0, desc:"Du bois verni, avec ses cernes et son fil."},
  {name:"Écailles",    rar:2, desc:"Des écailles qui brillent, comme un poisson… ou un dragon."},
  {name:"Aurore",      rar:4, desc:"Un verre nuit où dansent des rideaux de lumière."},
  {name:"Craquelée",   rar:1, desc:"Un verre clair fêlé de l'intérieur, qui accroche la lumière."},
];
const FAM_W = FAMILIES.map(f=>DECOR_RAR[f.rar].w);
// La rareté d'une bille, c'est sa taille (les décors ont seulement des fréquences différentes)
const RARITY = Object.keys(TYPES).map(t=>({name:TYPES[t].label, c:TYPES[t].rc}));
const FMT_TIER = {mini:0, bille:1, chinoise:2, calot:3, boulet:4, mammouth:5};
const BIG = FMT_TIER.boulet;   // "un gros" : Boulet ou Mammouth
const tierOf = s => FMT_TIER[s.type];
const SHINY_COLS = ["#FF6FB5","#FFB547","#6FE3A8","#5AB8FF","#B07BFF"];
const OPAQUE_FAMS = [3,7,8,9,10,12,14,17,18,19,20,21,22,23,24,25,26,27,28,29];
const FIGURES = ["étoile","cœur","lune","fleur"];

const PALETTES = [
  ["Azur","#1E5BD8","#6FB6FF","#F2C94C","#DDEBFF"],["Grenat","#8E1B2E","#D8443C","#F4B183","#FFE3E3"],
  ["Émeraude","#0E7A4C","#39C17E","#E9F5C9","#DFF7E9"],["Ambre","#C46A12","#F2A93B","#FFE2A8","#FFF0D6"],
  ["Lagon","#0B8FA3","#35D0C9","#F7F3E3","#D8F6F6"],["Féerie","#6B3FD8","#2FD3A5","#FF8FD1","#EEE6FF"],
  ["Volcan","#3A0D06","#E2461C","#FFB02E","#FFE0CF"],["Nuit","#0F1640","#5A6BE6","#C9D2FF","#D6DBF5"],
  ["Menthe","#1F9E7A","#9BF0CF","#FFFFFF","#E6FFF6"],["Corail","#E2574C","#FF9E80","#FFE0CC","#FFE9E2"],
  ["Lavande","#7A5BC8","#C6B2F5","#FFFFFF","#F0EAFF"],["Miel","#B7791F","#F6C453","#FFF3C4","#FFF6DA"],
  ["Cerise","#B0103A","#FF4F7B","#FFD1DC","#FFE4EA"],["Glacier","#4FA7D8","#CDEFFF","#FFFFFF","#EAF8FF"],
  ["Forêt","#1C4D22","#5DA843","#C7E08A","#E3F2DA"],["Sable","#B08A5A","#E6CFA4","#7A5A38","#F7EEDD"],
  ["Prune","#4A1A4F","#9C3FA0","#F0B8E8","#F4E3F5"],["Citron","#C9A800","#F9E24B","#FFFBD1","#FFFBE0"],
  ["Réglisse","#121212","#C81E2E","#F2F2F2","#E8E8E8"],["Rubis","#9B0F1F","#FF3348","#FFC2C8","#FFE0E3"],
  ["Saphir","#0B2E8A","#2A62FF","#9FC0FF","#DCE6FF"],["Opale","#B9AEE0","#7FD6DE","#F6C8E0","#F7F5FF"],
  ["Cuivre","#7A3B12","#D07A3C","#F5C79E","#FBE7D6"],["Brume","#6A7A8C","#B8C6D6","#F0F4F8","#EEF2F6"],
  // 24 coloris ajoutés en septembre 2026 : pastels, fluo, tons terreux, noir et blanc, duos inattendus
  ["Barbe à papa","#F28DC0","#8FD3F4","#FFFFFF","#FFE6F3"],["Néon","#0E0E1A","#39FF88","#FF3FD0","#E6FFF1"],
  ["Kaki","#4B5320","#8A9A5B","#D8C89A","#EEF0DE"],["Terracotta","#A0482C","#D9825B","#F1D3B8","#F8E6DA"],
  ["Moutarde","#B38600","#E0B22E","#4A3B1F","#FFF3CC"],["Or rose","#B76E79","#E8B4B8","#FCE8E0","#FBEDEC"],
  ["Encre","#111111","#FFFFFF","#7A7A7A","#F2F2F2"],["Pop","#FFD500","#FF2E93","#00B8F0","#FFF8CC"],
  ["Tropical","#FF7A00","#00A6A6","#B8E63A","#FFF0DC"],["Sorbet","#FF9E7A","#9BE8C8","#FFF1B8","#FFF1EA"],
  ["Paon","#0B5E6B","#1B8F5A","#2E3A9E","#DDF3F0"],["Pétrole","#0F4C5C","#E3B23C","#F4E9CD","#DDEFF2"],
  ["Framboise","#C2185B","#7B1FA2","#F8BBD0","#FCE4EC"],["Chocolat menthe","#4E2A1E","#7FD8B6","#F5F0E6","#E9F7F1"],
  ["Crépuscule","#3D1E6D","#FF7B54","#FFD56B","#F6E4F0"],["Tournesol","#F5B700","#5C3A1E","#7BAE3F","#FFF4CC"],
  ["Béton","#6E6E6E","#A9A9A9","#D8D2C4","#EEEEEA"],["Denim","#274B7A","#6E8FB8","#E08A3C","#E6ECF4"],
  ["Kiwi","#6A8D1E","#B7D63F","#3B2A1A","#F1F7DE"],["Ciel d'orage","#2E3440","#8FA3B8","#F2C14E","#E5EAF0"],
  ["Sucre d'orge","#E63946","#FFFFFF","#F4A3A8","#FFE8EA"],["Lilas","#B39DDB","#FFF176","#7E57C2","#F3EEFB"],
  ["Toucan","#1A1A1A","#FF7F11","#FFD23F","#FFF1DC"],["Sauge","#7D8F69","#B5C4A1","#E8E2D0","#EEF2E8"],
];
const BASE_PALS = PALETTES.length;   // coloris qu'on peut tirer dans les sacs
// Une saison par mois (0 = janvier) : un coloris exclusif et un décor vedette, seulement dans le passe
const SEASONS = [
  {name:"Givre",            fam:11, pal:["Givre","#3F6FB8","#DCEBFF","#FFFFFF","#EEF5FF"]},
  {name:"Carnaval",         fam:12, pal:["Carnaval","#B8266E","#FFC93F","#3BC4B8","#FFE8F3"]},
  {name:"Printemps",        fam:0,  pal:["Printemps","#2F7D3B","#FF9EC4","#FFF2A8","#EAF8E6"]},
  {name:"Poisson d'avril",  fam:13, pal:["Poisson","#1770B0","#FF7A59","#FFE066","#E3F4FF"]},
  {name:"Muguet",           fam:10, pal:["Muguet","#2E6B45","#F4F7EE","#B9E3A8","#EEF8EA"]},
  {name:"Plein soleil",     fam:1,  pal:["Soleil","#C2410C","#FFC93F","#FFF3BF","#FFF4DC"]},
  {name:"Grandes vacances", fam:4,  pal:["Plage","#0B7285","#F2D39B","#FFFFFF","#E0F7F7"]},
  {name:"Étoiles filantes", fam:2,  pal:["Nuit d'été","#1B1F4B","#7B6CF6","#FFE08A","#DCDDF7"]},
  {name:"Rentrée",          fam:7,  pal:["Rentrée","#1F3A8A","#E8413C","#FFD34E","#E4EAF7"]},
  {name:"Citrouille",       fam:5,  pal:["Citrouille","#3A1F4A","#F07C1B","#9BE15D","#FBE6D4"]},
  {name:"Feuilles mortes",  fam:3,  pal:["Automne","#6B3A1E","#D9822B","#F2D16B","#F4ECE1"]},
  {name:"Flocon",           fam:15, pal:["Flocon","#9E1030","#FFFFFF","#2F8F45","#FBEAEA"]},
];
SEASONS.forEach(s=>PALETTES.push(s.pal));
const isSeason = s => s.pal>=BASE_PALS && s.pal<BASE_PALS+SEASONS.length;
// Billes secrètes : une seule par joueur, cachées un peu partout dans Tikalo
const SECRETS = {
  folle:   {name:"La Folle", type:"calot", family:1, shiny:1, pal:["Folle","#FF2E88","#2EE6FF","#FFE600","#FFE3F2"],
            hint:"La bille du logo n'aime pas qu'on la chatouille… sauf si on insiste vraiment, vraiment beaucoup."},
  arcade:  {name:"L'Arcade", type:"boulet", family:25, shiny:3, pal:["Arcade","#1A0B3D","#39FF14","#FF00E6","#E0D6FF"],
            hint:"↑ ↑ ↓ ↓ … les vrais joueurs de console connaissent la suite."},
  grenier: {name:"Le Trésor du grenier", type:"mammouth", family:8, shiny:2, pal:["Grenier","#6B4A1E","#E8C27A","#FFF1C9","#F6E7C8"],
            hint:"Les trésors sortent du grenier quand tout le monde dort."},
  gouter:  {name:"La Bille du goûter", type:"calot", family:20, shiny:0, pal:["Goûter","#5A2E14","#F2E6D0","#E94B3C","#F5E6D8"],
            hint:"Pile à la sortie de l'école, quand on a un petit creux…"},
  preau:   {name:"La Secouée", type:"boulet", family:16, shiny:0, pal:["Préau","#2F3A4A","#8FA3BF","#F2F5FA","#E4E9F0"],
            hint:"Certains sacs se méritent : il faut vraiment, vraiment bien les secouer."},
};
Object.values(SECRETS).forEach(X=>{ X.palIdx = PALETTES.length; PALETTES.push(X.pal) });
const SHINIES = [null,
  {name:"Irisée",    w:70, desc:"Reflets arc-en-ciel à la surface."},
  {name:"Dorée",     w:25, desc:"Des paillettes d'or qui scintillent à la lumière."},
  {name:"Lumineuse", w:5,  desc:"Elle brille, même dans le noir."},
];
// tirage pondéré : r dans [0,1[, w = poids
function pickW(r,w){ const tot=w.reduce((a,b)=>a+b,0); let x=r*tot; for(let i=0;i<w.length;i++){ x-=w[i]; if(x<0) return i } return w.length-1 }
const rollShiny = () => 1+pickW(Math.random(), SHINIES.slice(1).map(x=>x.w));
const SHINY_RATE = .0001;  // 0,01 % par bille : le graal ultime (0,05 % dans le Sac Collector)

// Recyclage : ce que rapporte une bille détruite
const RECYCLE = {mini:5, bille:10, chinoise:25, calot:50, boulet:150, mammouth:400};
const SHINY_RECYCLE_MULT = 20;
const recycleValue = s => RECYCLE[s.type]*(s.shiny?SHINY_RECYCLE_MULT:1);

// Quêtes du jour : 3 tirées chaque jour dans cette liste
const QUESTS = {
  open_bag:      {title:"Ouvre 2 sacs", goal:2, reward:80, icon:"bag", desc:"Gratuits ou payants, tous les sacs comptent."},
  open_free:     {title:"Ouvre 2 sacs gratuits", goal:2, reward:100, icon:"clock", desc:"Un nouveau sac gratuit arrive toutes les 10 minutes."},
  hole:          {title:"Réussis 3 trous au Tir", goal:3, reward:90, icon:"target", desc:"N'importe quel trou du parcours."},
  par:           {title:"Fais un trou au par ou mieux", goal:1, reward:70, icon:"target", desc:"Trois étoiles sur un trou du Tir."},
  twoshots:      {title:"Mets ta bille dans le trou en 2 coups", goal:1, reward:90, icon:"target", desc:"Ou moins ! Le trou 1 est un bon candidat."},
  find_bille:    {title:"Trouve 2 Billes ou plus grosses", goal:2, reward:90, icon:"layers", desc:"Bille, Bille chinoise, Calot, Boulet ou Mammouth : les Mini billes ne comptent pas."},
  find_calot:    {title:"Trouve un Calot ou mieux", goal:1, reward:120, icon:"layers", desc:"Calot, Boulet ou Mammouth."},
  new_slot:      {title:"Commence une nouvelle case", goal:1, reward:100, icon:"book", desc:"Une taille et un décor que tu n'avais pas encore dans l'album."},
  new_color:     {title:"Trouve 3 nouvelles billes", goal:3, reward:100, icon:"star", desc:"Des billes que tu n'avais pas encore : nouvelle case ou nouveau coloris."},
  open_paid:     {title:"Ouvre un sac payant", goal:1, reward:120, icon:"bag", desc:"Classique, Premium ou Collector, acheté ou offert."},
  craft:         {title:"Réussis une fusion", goal:1, reward:120, icon:"flask", desc:"10 billes d'une même taille à la Confiserie."},
  shake:         {title:"Secoue bien les sacs", goal:20, reward:60, icon:"bag", desc:"Secoue les sacs avant de les ouvrir : 20 secousses en tout."},
  recycle:       {title:"Échange 3 billes à la Confiserie", goal:3, reward:60, icon:"candy", desc:"Depuis la fiche d'une bille ou avec le bouton des doubles."},
};
const QUEST_BONUS = 150;

const FREE_BAG = {id:"gratuit", name:"Sac gratuit", desc:"3 billes offertes. Un nouveau sac toutes les 10 minutes, jusqu'à 5 en stock.", price:0, n:3, color:"#C98E4E", tint:"#F6E3C8", shiny:SHINY_RATE,
  odds:{mini:50,bille:33,chinoise:9,calot:5.8,boulet:1.8,mammouth:.4}};
const BAGS = [FREE_BAG,
  {id:"classique", name:"Sac Classique", desc:"5 billes, avec de meilleures chances que le sac gratuit.", price:300, n:5, color:"#2A8A74", tint:"#D5EFE7", shiny:SHINY_RATE,
   odds:{mini:40,bille:34,chinoise:12,calot:9.5,boulet:3.5,mammouth:1}},
  {id:"premium", name:"Sac Premium", desc:"5 billes, dont au moins un Calot ou mieux.", price:900, n:5, guarantee:"calot", color:"#34469C", tint:"#DCE0F6", shiny:SHINY_RATE,
   odds:{mini:26,bille:34,chinoise:16,calot:16,boulet:6.5,mammouth:1.5}},
  {id:"collector", name:"Sac Collector", desc:"5 billes, dont au moins un Boulet ou plus gros. 5 fois plus de chances de shiny.", price:2200, n:5, guarantee:"boulet", color:"#D9A020", tint:"#FBEBC0", shiny:SHINY_RATE*5,
   odds:{mini:14,bille:28,chinoise:20,calot:23,boulet:11,mammouth:4}},
];
const BAG_BY = Object.fromEntries(BAGS.map(b=>[b.id,b]));

/* =====================================================================
   OUTILS
   ===================================================================== */
const TAU = Math.PI*2;
function hash(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return h>>>0}
function rng(seed){let a=seed>>>0;return()=>{a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}
const randU32 = () => (Math.random()*4294967296)>>>0;
function hexRgb(h){h=h.replace("#","");return [parseInt(h.slice(0,2),16),parseInt(h.slice(2,4),16),parseInt(h.slice(4,6),16)]}
const hex01 = h => hexRgb(h).map(v=>v/255);
function shade(h,a){const c=hexRgb(h).map(v=>Math.round(a>0?v+(255-v)*a:v*(1+a)));return "#"+c.map(v=>v.toString(16).padStart(2,"0")).join("")}
function rgba(h,a){const [r,g,b]=hexRgb(h);return `rgba(${r},${g},${b},${a})`}
function esc(s){return String(s).replace(/[&<>"]/g,c=>({"&":"&amp;","<":"&lt;",">":"&gt;",'"':"&quot;"}[c]))}
const fmt = n => Math.round(n).toLocaleString("fr-FR").replace(/ | /g," ");
const pct = n => String(n).replace(".",",")+" %";
function rotAxis(ax,ay,az,a){const l=Math.hypot(ax,ay,az)||1;ax/=l;ay/=l;az/=l;const c=Math.cos(a),s=Math.sin(a),t=1-c;
  return [t*ax*ax+c,t*ax*ay-s*az,t*ax*az+s*ay, t*ax*ay+s*az,t*ay*ay+c,t*ay*az-s*ax, t*ax*az-s*ay,t*ay*az+s*ax,t*az*az+c]}
function mul3(A,B){const C=new Array(9);for(let i=0;i<3;i++)for(let j=0;j<3;j++)C[i*3+j]=A[i*3]*B[j]+A[i*3+1]*B[3+j]+A[i*3+2]*B[6+j];return C}
function ortho3(M){const a=[M[0],M[1],M[2]],b=[M[3],M[4],M[5]];const n=v=>{const l=Math.hypot(...v);return v.map(x=>x/l)};
  const A=n(a);const d=A[0]*b[0]+A[1]*b[1]+A[2]*b[2];const B=n([b[0]-d*A[0],b[1]-d*A[1],b[2]-d*A[2]]);
  const C=[A[1]*B[2]-A[2]*B[1],A[2]*B[0]-A[0]*B[2],A[0]*B[1]-A[1]*B[0]];return [...A,...B,...C]}
const I3 = [1,0,0,0,1,0,0,0,1];

/* =====================================================================
   BILLES : génération procédurale (chaque bille est unique)
   ===================================================================== */
// identifiant unique de chaque bille (UUID) : c'est lui qui la suit d'un joueur à l'autre, la base refuse les doublons
const newId = () => crypto.randomUUID ? crypto.randomUUID() : ([1e7]+-1e3+-4e3+-8e3+-1e11).replace(/[018]/g, c=>(c^crypto.getRandomValues(new Uint8Array(1))[0]&15>>c/4).toString(16));
const isUUID = id => /^[0-9a-f]{8}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{4}-[0-9a-f]{12}$/i.test(id||"");
function makeSpec(type, o={}){
  const seed = o.seed ?? randU32();
  const r = rng(seed);
  return {id: newId(), seed, type,
    family: o.family ?? pickW(r(), FAM_W),
    pal: o.pal ?? Math.floor(r()*BASE_PALS),
    shiny: o.shiny ?? 0, at: o.at ?? Date.now()};
}
const specName = s => s.secret && SECRETS[s.secret] ? SECRETS[s.secret].name : `${FAMILIES[s.family].name} ${PALETTES[s.pal][0]}`;
const serial = s => { const h=(s.seed>>>0).toString(16).toUpperCase().padStart(8,"0"); return h.slice(0,4)+"-"+h.slice(4) };
const slotKey = s => s.type+"|"+s.family;

const paramCache = new Map();
function specParams(s){
  const key = `${s.seed}|${s.type}|${s.family}|${s.pal}|${s.shiny}`;
  if(paramCache.has(key)) return paramCache.get(key);
  const r = rng((s.seed ^ 0x9E3779B9)>>>0);
  const P = PALETTES[s.pal];
  let tint = hex01(P[4]);
  const opaque = OPAQUE_FAMS.includes(s.family);
  if(s.family===2||s.family===30) tint = hex01(shade(P[1],-.1)).map(v=>Math.max(.08,v*.8));
  const p = {
    seed:[r(),r(),r(),r()],
    par:[(r()-.5)*5, [3,4,4,5,6][Math.floor(r()*5)], .05+r()*.07, 2+Math.floor(r()*4)],
    srot: rotAxis(r()-.5,r()-.5,r()-.5,r()*TAU),
    c1:hex01(P[1]), c2:hex01(P[2]), c3:hex01(P[3]), tint,
    mode:s.family, opaque:opaque?1:0, porc:0, sulf:0, fig:s.family%4, shiny:s.shiny||0, asp:s.type==="chinoise"?1.45:1,
  };
  paramCache.set(key,p); return p;
}

/* ---------- rendu WebGL : verre, réfraction, reflets ---------- */
const FS = `
precision highp float;
uniform vec2 uRes; uniform vec4 uSeed; uniform vec4 uPar;
uniform float uPorc, uShiny, uSulf, uFig, uR, uAsp;
uniform vec3 uC1, uC2, uC3, uTint;
uniform mat3 uRot, uSRot;
uniform float uTime;

float h31(vec3 p){ p=fract(p*0.3183099+0.1); p*=17.0; return fract(p.x*p.y*p.z*(p.x+p.y+p.z)); }
float noise(vec3 x){ vec3 i=floor(x), f=fract(x); f=f*f*(3.0-2.0*f);
  return mix(mix(mix(h31(i),h31(i+vec3(1,0,0)),f.x),mix(h31(i+vec3(0,1,0)),h31(i+vec3(1,1,0)),f.x),f.y),
             mix(mix(h31(i+vec3(0,0,1)),h31(i+vec3(1,0,1)),f.x),mix(h31(i+vec3(0,1,1)),h31(i+vec3(1,1,1)),f.x),f.y),f.z); }
float fbm(vec3 p){ float a=0.5, s=0.0; for(int i=0;i<4;i++){ s+=a*noise(p); p=p*2.03+vec3(1.7,9.2,3.1); a*=0.5; } return s; }
vec3 pal3(float k){ k=mod(k,3.0); return k<1.0?uC1:(k<2.0?uC2:uC3); }

float sdStar(vec2 p){ const vec2 k1=vec2(0.809016994,-0.587785252); const vec2 k2=vec2(-0.809016994,-0.587785252);
  float r=0.85, rf=0.45; p.x=abs(p.x); p-=2.0*max(dot(k1,p),0.0)*k1; p-=2.0*max(dot(k2,p),0.0)*k2; p.x=abs(p.x); p.y-=r;
  vec2 ba=rf*vec2(-k1.y,k1.x)-vec2(0,1); float h=clamp(dot(p,ba)/dot(ba,ba),0.0,r); return length(p-ba*h)*sign(p.y*ba.x-p.x*ba.y); }
float sdHeart(vec2 p){ p.x=abs(p.x); p.y+=0.55;
  if(p.y+p.x>1.0) return sqrt(dot(p-vec2(0.25,0.75),p-vec2(0.25,0.75)))-0.35355;
  vec2 a=p-vec2(0.0,1.0); vec2 b=p-0.5*max(p.x+p.y,0.0); return sqrt(min(dot(a,a),dot(b,b)))*sign(p.x-p.y); }
float fig(vec2 p){ int f=int(uFig+0.5);
  if(f==0) return sdStar(p);
  if(f==1) return sdHeart(p*1.1)/1.1;
  if(f==2) return max(length(p)-0.75, -(length(p-vec2(0.34,0.2))-0.62));
  float d=min(min(length(p-vec2(0.0,0.4)),length(p-vec2(0.0,-0.4))),min(length(p-vec2(0.4,0.0)),length(p-vec2(-0.4,0.0))))-0.3;
  return min(d,length(p)-0.25); }

#if MODE==22
vec3 tart(float t){ t=fract(t); vec3 cr=vec3(0.97,0.95,0.88);
  return t<0.36?uC1:(t<0.6?uC1*0.3:(t<0.66?uC2:(t<0.69?cr:(t<0.75?uC2:(t<0.9?uC1*0.3:uC3))))); }
#endif
vec2 sph(vec3 u){ return vec2(atan(u.z,u.x)/6.2831853, asin(clamp(u.y,-1.0,1.0))/3.14159); }   // longitude, latitude (0..1)

vec4 fam(vec3 q, out vec3 e){
  e=vec3(0.0);
  float r=length(q); vec3 so=uSeed.xyz*40.0;
  float tw=uPar.x, k=uPar.y, w=uPar.z, nb=uPar.w;
#if MODE==0
  { // oeil-de-chat
    float ang=atan(q.z,q.x)+q.y*tw;
    float d=abs(sin(ang*k*0.5))*length(q.xz);
    float dens=smoothstep(w,w*0.25,d)*smoothstep(0.93,0.78,r);
    return vec4(pal3(floor(ang/6.2831853*k+0.5)), dens*45.0);
  }
#elif MODE==1
  { // tourbillon
    vec3 wq=q+0.45*vec3(fbm(q*1.7+so),fbm(q*1.7+so+5.2),fbm(q*1.7+so+9.7))-0.22;
    float ang=atan(wq.z,wq.x)+wq.y*tw*1.3;
    float b=sin(ang*nb);
    float dens=smoothstep(1.0-w*3.2,1.0,abs(b))*smoothstep(0.93,0.62,r)*smoothstep(0.12,0.3,r);
    return vec4(pal3(floor(ang*nb/3.14159)), dens*32.0);
  }
#elif MODE==2
  { // galaxie
    float n=fbm(q*2.2+so), n2=fbm(q*4.0-so);
    vec3 c=mix(uC1,uC2,smoothstep(0.35,0.7,n)); c=mix(c,uC3,smoothstep(0.55,0.8,n2));
    e=c*(pow(smoothstep(0.25,0.8,n),1.6)*4.5+0.25)*smoothstep(0.97,0.4,r);
    vec3 g=q*16.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.955,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*9.0;
    return vec4(uC1*0.25, 1.6);
  }
#elif MODE==3
  { // agate
    float f=fbm(q*1.3+so)*3.5+q.y*1.2; float t=fract(f*1.5);
    vec3 c=mix(uC1,uC2,smoothstep(0.2,0.5,t)); c=mix(c,uC3,smoothstep(0.72,0.85,t)*0.9);
    c=mix(c,vec3(1.0),smoothstep(0.93,0.99,t)*0.55);
    return vec4(c, 200.0);
  }
#elif MODE==4
  { // opaline
    float n=fbm(q*2.0+so);
    vec3 c=mix(uC3,uC1,smoothstep(0.3,0.7,n));
    c=mix(c,uC2,smoothstep(0.55,0.75,fbm(q*3.0+so+3.0)));
    e=c*0.35;
    return vec4(c, 3.5);
  }
#elif MODE==5
  { // pailletee
    vec3 g=q*22.0+so; vec3 fc=fract(g)-0.5;
    float fl=step(0.86,h31(floor(g)))*smoothstep(0.22,0.05,length(fc));
    float sw=smoothstep(0.55,0.7,fbm(q*2.0+so));
    e=uC3*fl*6.0*smoothstep(0.95,0.7,r);
    return vec4(mix(uC1,uC2,sw), 0.8+fl*40.0+sw*1.5);
  }
#elif MODE==6
  { // oignon
    float st=sin(atan(q.z,q.x)*nb*2.0+fbm(q*3.0+so)*5.0+q.y*tw);
    vec3 c=st>0.3?uC2:(st<-0.4?uC3:uC1);
    float shell=smoothstep(0.6,0.76,r)*smoothstep(0.95,0.88,r);
    return vec4(c, shell*60.0+0.3);
  }
#elif MODE==7
  { // berlingot
  float ang=atan(q.z,q.x)+q.y*tw;
  float s=fract(ang/6.2831853*nb);
  vec3 cream=vec3(0.98,0.96,0.93);
  vec3 c=s<0.33?uC1:(s<0.5?cream:(s<0.83?uC2:cream));
  return vec4(c, 200.0);
  }
#elif MODE==8
  { // terre cuite peinte
    float n=fbm(q*3.0+so);
    vec3 clay=mix(uC1,vec3(0.72,0.55,0.4),0.5)*(0.8+0.35*n)*(0.9+0.2*noise(q*45.0+so));
    float y=q.y+0.07*sin(atan(q.z,q.x)*3.0+so.x);
    float band=max(smoothstep(0.075,0.045,abs(abs(y)-0.36)),smoothstep(0.06,0.03,abs(y)));
    return vec4(mix(clay,uC3*0.9,band*0.9), 200.0);
  }
#elif MODE==9
  { // acier
    return vec4(mix(vec3(0.8),uC2,0.18), 200.0);
  }
#elif MODE==10
  { // nacrée : couches de nacre aux couleurs du coloris (les coloris sombres donnent des perles noires)
    float n=fbm(q*2.5+so);
    float lay=0.5+0.5*sin(fbm(q*1.8+so*0.7)*14.0);
    vec3 c=mix(uC1,uC2,0.35+0.4*lay);
    return vec4(mix(c,vec3(0.97,0.95,0.93),0.3+0.2*n), 200.0);
  }
#elif MODE==11
  { // cristal à bulles
    vec3 g=q*6.0+so; vec3 id=floor(g); vec3 fc=fract(g)-0.5;
    float hb=h31(id);
    vec3 off=vec3(h31(id+3.1),h31(id+7.7),h31(id+1.9))-0.5;
    float rb=0.07+0.16*h31(id+1.3);
    float d=length(fc-off*0.35);
    float sh=step(0.5,hb)*smoothstep(0.06,0.0,abs(d-rb))*smoothstep(0.92,0.75,r);
    e=vec3(1.0)*sh*1.5;
    return vec4(mix(uC2,vec3(1.0),0.6), 0.25+sh*22.0);
  }
#elif MODE==12
  { // arlequin
    vec3 g=q*3.0+so; vec3 i=floor(g), f=fract(g);
    float md=8.0, md2=8.0; vec3 mid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){
      vec3 b=vec3(float(x),float(y),float(z));
      vec3 o=vec3(h31(i+b),h31(i+b+11.3),h31(i+b+27.1));
      vec3 rr=b+o-f; float dd=dot(rr,rr);
      if(dd<md){ md2=md; md=dd; mid=i+b; } else if(dd<md2) md2=dd;
    }
    float hk=h31(mid+5.0);
    vec3 c=hk<0.25?vec3(0.97,0.95,0.9):pal3(floor(hk*3.0));
    c*=mix(0.55,1.0,smoothstep(0.0,0.08,sqrt(md2)-sqrt(md)));
    return vec4(c, 200.0);
  }
#elif MODE==13
  { // ruban
    float a=q.y*tw*1.5+so.x; float ca=cos(a), sa=sin(a);
    vec2 p=vec2(ca*q.x-sa*q.z, sa*q.x+ca*q.z);
    float dens=smoothstep(w*1.1,w*0.4,abs(p.y))*smoothstep(0.62,0.5,abs(p.x))*smoothstep(0.93,0.8,r);
    return vec4(pal3(floor((p.x+0.62)*nb*1.3)), dens*55.0);
  }
#elif MODE==14
  { // millefiori : des fleurs de verre sur un fond sombre
    vec3 g=q*2.7+so; vec3 id=floor(g); vec3 f=fract(g)-0.5;
    float d=length(f), a=atan(f.y,f.x);
    float pet=0.4+0.09*cos(a*(5.0+floor(h31(id)*3.0)));
    float flower=smoothstep(pet,pet-0.04,d), heart=smoothstep(0.13,0.1,d);
    vec3 c=mix(uC1*0.35, pal3(floor(h31(id+4.0)*3.0)), flower);
    c=mix(c, vec3(1.0,0.95,0.7), heart);
    return vec4(c, 200.0);
  }
#elif MODE==15
  { // givrée : verre laiteux, un peu teinté
    float n=fbm(q*3.0+so);
    return vec4(mix(uC2,vec3(0.96,0.97,1.0),0.3+0.25*n), 2.2+3.0*n);
  }
#elif MODE==16
  { // fumée : volutes dans le verre
    float n=fbm(q*2.4+so+1.5*vec3(fbm(q*1.4+so),fbm(q*1.4+so+3.0),fbm(q*1.4+so+6.0)));
    float dens=smoothstep(0.42,0.72,n)*smoothstep(0.93,0.55,r);
    return vec4(mix(uC1*0.5,vec3(0.9),smoothstep(0.5,0.9,n)), dens*16.0);
  }
#elif MODE==17
  { // lave : roche sombre et fissures incandescentes
    float n=fbm(q*3.0+so);
    float k2=abs(fbm(q*3.6+so*1.3)-0.5);
    float crack=smoothstep(0.045,0.0,k2);
    vec3 glow=mix(uC2,vec3(1.0,0.85,0.4),crack*0.6);
    e=glow*crack*2.2;
    return vec4(mix(vec3(0.07,0.06,0.06)+uC1*0.12*n, glow, crack), 200.0);
  }
#elif MODE==18
  { // marbre : pierre claire et veines
    float v=abs(sin((q.x+q.y*0.7)*5.0+fbm(q*2.6+so)*7.0));
    vec3 c=mix(vec3(0.95,0.94,0.91),uC3,0.12);
    c=mix(c, uC1*0.75, pow(1.0-v,10.0));
    c=mix(c, uC2, pow(1.0-abs(sin((q.z-q.y)*9.0+fbm(q*4.0-so)*5.0)),22.0)*0.6);
    return vec4(c, 200.0);
  }
#elif MODE==19
  { // tigrée : rayures de fauve
    float s=sin(q.y*nb*3.2+fbm(q*2.4+so)*5.5+q.x*1.6);
    return vec4(mix(uC2, uC1*0.22, smoothstep(0.35,0.55,s)), 200.0);
  }
#elif MODE==21
  { // damier : cases qui s'enroulent comme sur un ballon de plage
    vec3 u=normalize(q); vec2 s=sph(u); float n=4.0+nb;
    vec2 c=floor(vec2((s.x+s.y*tw*0.04)*n*2.0, s.y*n));
    return vec4(mod(c.x+c.y,2.0)<0.5?uC1:uC3, 200.0);   // toujours les mêmes couleurs pour un même coloris
  }
#elif MODE==22
  { // écossais : deux trames qui se croisent, avec le petit sergé du tissu
    vec3 u=normalize(q); float x=(u.x+u.z*0.3)*1.5+so.x, y=u.y*1.5+so.y;
    vec3 ch=tart(x), cv=tart(y);
    float tw2=step(0.5,fract((x+y)*22.0));   // sergé : un fil sur deux passe dessus
    return vec4(mix(ch,cv,tw2*0.6+0.2), 200.0);
  }
#elif MODE==23
  { // nid d'abeille : alvéoles de cire, certaines pleines de miel
    vec3 u=normalize(q); vec2 s=sph(u);
    vec2 p=vec2(s.x*(8.0+nb*2.0), s.y*(5.0+nb)*1.1547);
    vec2 h=vec2(1.0,1.7320508); vec2 a=mod(p,h)-h*0.5, b=mod(p-h*0.5,h)-h*0.5;
    vec2 g=dot(a,a)<dot(b,b)?a:b; vec2 id=p-g;
    float d=max(dot(abs(g),vec2(0.5,0.8660254)),abs(g.x));
    float hk=h31(vec3(id,so.x));
    vec3 honey=mix(uC1,uC2,hk*0.5)*(0.7+0.8*(0.5-d))*(hk<0.3?0.6:1.0);
    vec3 wax=mix(vec3(0.98,0.93,0.75),uC3,0.3);
    return vec4(mix(honey,wax,smoothstep(0.4,0.45,d)), 200.0);
  }
#elif MODE==24
  { // cible : anneaux autour d'un axe (une cible de chaque côté)
    vec3 u=normalize(q); vec3 ax=normalize(uSeed.xyz-0.5+vec3(0.001));
    float t=acos(clamp(abs(dot(u,ax)),0.0,1.0))/1.5708*(3.0+nb);
    float m=mod(floor(t),4.0);
    vec3 col=m<1.0?uC1:(m<2.0?vec3(0.97,0.95,0.9):(m<3.0?uC2:uC3));
    float f=fract(t); col*=mix(0.7,1.0,smoothstep(0.0,0.05,f)*smoothstep(1.0,0.95,f));
    return vec4(col, 200.0);
  }
#elif MODE==25
  { // pixel : gros carrés en couleurs franches
    vec3 u=normalize(q); vec2 s=sph(u); float n=6.0+nb*2.0;
    vec2 p=vec2(s.x*n*2.0, s.y*n); vec2 c=floor(p)+0.5;
    float lo=c.x/(n*2.0)*6.2831853, la=c.y/n*3.14159;
    float v=fbm(vec3(cos(la)*cos(lo),sin(la),cos(la)*sin(lo))*1.9+so);
    vec3 col=v<0.4?uC1*0.45:(v<0.48?uC1:(v<0.56?uC2:(v<0.63?uC3:vec3(0.97,0.95,0.9))));
    vec2 f=fract(p); col*=mix(0.8,1.0,step(0.07,f.x)*step(0.07,f.y));
    return vec4(col, 200.0);
  }
#elif MODE==26
  { // globe : océans, continents, banquise et nuages
    vec3 u=normalize(q); float n=fbm(u*1.5+so)+0.25*fbm(u*5.0+so);
    float land=smoothstep(0.575,0.595,n);
    vec3 sea=mix(uC1*0.45,uC1*0.9,smoothstep(0.4,0.575,n));
    vec3 gr=mix(mix(uC2,vec3(0.55,0.7,0.3),0.35),uC2*0.55,smoothstep(0.62,0.75,n)); gr=mix(gr,mix(uC3,vec3(0.9),0.4),smoothstep(0.75,0.85,n));
    vec3 col=mix(sea,gr,land);
    col=mix(col,vec3(0.97),smoothstep(0.91,0.95,abs(u.y)+0.05*noise(u*8.0+so)));
    col=mix(col,vec3(1.0),smoothstep(0.66,0.8,fbm(u*vec3(2.5,6.0,2.5)-so))*0.5);
    return vec4(col, 200.0);
  }
#elif MODE==27
  { // planète : bandes de nuages et grande tempête
    vec3 u=normalize(q);
    float y=u.y*(2.0+nb)+fbm(u*vec3(2.0,9.0,2.0)+so)*1.2;
    float k2=mod(floor(y),3.0), fy=fract(y);
    vec3 cream=vec3(0.96,0.9,0.8);
    vec3 col=k2<1.0?mix(uC1,cream,0.35):(k2<2.0?uC2:mix(uC3,cream,0.2));
    col*=0.85+0.25*smoothstep(0.0,0.5,fy)*smoothstep(1.0,0.5,fy);
    vec3 sp=normalize(uSeed.xyz-0.5+vec3(0.0,0.0,0.001)); sp.y*=0.5; sp=normalize(sp);
    vec3 dv=u-sp; float d=length(vec3(dv.x,dv.y*2.2,dv.z));
    float sw=sin(d*45.0-atan(dv.y*2.2,dv.x+dv.z)*2.0);
    col=mix(col, mix(vec3(0.95,0.85,0.75),uC2*0.5,0.5+0.5*sw), smoothstep(0.36,0.28,d));
    return vec4(col, 200.0);
  }
#elif MODE==28
  { // bois : cernes et fil du bois, verni
    vec3 u=normalize(q);
    float rr=length(u.yz-vec2((uSeed.x-0.5)*0.8,1.2+uSeed.y*0.6))*(2.2+nb*0.7)+fbm(u*vec3(1.0,3.0,3.0)+so)*1.2;
    vec3 wood=mix(vec3(0.78,0.56,0.33),uC1,0.3);
    float ring=fract(rr);
    vec3 col=mix(wood,wood*0.5,smoothstep(0.6,0.92,ring)*smoothstep(1.0,0.95,ring));
    col*=0.8+0.3*noise(vec3(u.x*3.0,u.y*45.0,u.z*45.0)+so);
    return vec4(col, 200.0);
  }
#elif MODE==29
  { // écailles : chaque écaille recouvre celle du dessous, bord foncé, reflets irisés
    vec3 u=normalize(q); vec2 sp=sph(u); float n=6.0+nb;
    vec2 p=vec2(sp.x*n, sp.y*n*1.3); float r0=floor(p.y);
    float found=0.0, t=1.0, hk=0.0;
    for(int j=0;j<2;j++) for(int k=-1;k<=1;k++){
      float rr=r0+float(j), off=0.5*mod(rr,2.0);
      float cx=floor(p.x-off)+off+0.5+float(k);
      float d=length(vec2(p.x-cx,(p.y-rr)*1.1));
      if(found<0.5 && d<0.75){ found=1.0; t=d/0.75; hk=h31(vec3(cx,rr,so.x)); }
    }
    vec3 col=mix(uC1,uC2,hk*0.7)*(0.45+0.75*t);
    col=mix(col,uC1*0.2,smoothstep(0.86,0.98,t));
    col+=(0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+hk+t*0.7)))*0.16;
    return vec4(col, 200.0);
  }
#elif MODE==30
  { // aurore : verre nuit, rideaux de lumière et quelques étoiles
    float r=length(q);
    vec3 wq=q+0.15*vec3(fbm(q*2.0+so),0.0,fbm(q*2.0+so+4.0));
    float sheet=abs(fract(wq.x*nb*0.8+sin(wq.z*3.0+so.x)*0.4)-0.5);
    float h=smoothstep(-0.6,-0.15,q.y)*smoothstep(0.75,0.1,q.y);
    float rays=0.55+0.45*noise(vec3(wq.x*30.0,q.y*2.0,wq.z*30.0)+so);
    vec3 c=mix(uC2,uC3,smoothstep(-0.3,0.5,q.y));
    e=(c+0.25)*smoothstep(0.2,0.0,sheet)*h*rays*7.0*smoothstep(0.95,0.6,r);
    vec3 g=q*16.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.965,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*7.0;
    return vec4(uC1*0.2, 1.4);
  }
#elif MODE==31
  { // craquelée : fêlures en nappes à l'intérieur du verre
    vec3 g=q*2.2+so; vec3 i=floor(g), f=fract(g);
    float md=8.0, md2=8.0;
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){
      vec3 b=vec3(float(x),float(y),float(z));
      vec3 rr=b+vec3(h31(i+b),h31(i+b+11.3),h31(i+b+27.1))-f; float dd=dot(rr,rr);
      if(dd<md){ md2=md; md=dd; } else if(dd<md2) md2=dd;
    }
    float crack=smoothstep(0.035,0.0,sqrt(md2)-sqrt(md))*smoothstep(0.93,0.7,length(q));
    e=mix(vec3(1.0),uC3,0.3)*crack*2.0;
    return vec4(mix(uC2,vec3(1.0),0.5), 0.2+crack*30.0);
  }
#else
  { // à pois
    vec3 g=q*2.6+so; vec3 id=floor(g); vec3 f=fract(g)-0.5;
    float dot1=smoothstep(0.38,0.35,length(f))*step(0.2,h31(id));
    vec3 pc=h31(id+2.0)<0.55?vec3(0.97,0.96,0.93):uC3;
    return vec4(mix(uC1, pc, dot1), 200.0);
  }
#endif
}

vec4 pattern(vec3 q, vec3 qs, out vec3 e){
  vec4 c=fam(qs,e);
  if(uSulf>0.5){
    float d=fig(q.xy*1.8)/1.8;
    if(max(d,abs(q.z)-0.06)<0.0){ e=vec3(0.0); return vec4(0.93,0.93,0.96,400.0); }
    c.a*=0.05; e*=0.2;
  }
  if(uShiny>1.5 && uShiny<2.5){
    vec3 g=qs*17.0+uSeed.yzx*50.0; vec3 fc=fract(g)-0.5;
    float fl=step(0.66,h31(floor(g)))*smoothstep(0.3,0.06,length(fc))*smoothstep(0.97,0.8,length(q));
    e+=vec3(1.0,0.78,0.3)*fl*11.0; c.a+=fl*30.0; c.rgb=mix(c.rgb,vec3(1.0,0.8,0.35),fl);
  }
  if(uShiny>2.5){ e+=c.rgb*min(c.a,25.0)*0.09+uC2*0.25; }
  return c;
}

// pièce reflétée par le métal : ciel doux, sol, horizon adouci, fenêtre et lampe
vec3 chrome(vec3 r){
  vec3 sky=mix(vec3(0.62,0.66,0.72),vec3(0.98,0.99,1.0),smoothstep(0.05,0.9,r.y));
  vec3 flo=mix(vec3(0.46,0.42,0.38),vec3(0.24,0.22,0.21),smoothstep(-0.05,-0.9,r.y));
  vec3 c=mix(flo,sky,smoothstep(-0.22,0.22,r.y));
  c*=1.0-0.25*smoothstep(0.1,0.0,abs(r.y+0.12));
  c+=smoothstep(0.3,0.2,abs(r.x+0.42))*smoothstep(0.24,0.14,abs(r.y-0.5))*step(0.0,r.z)*1.1;
  c+=smoothstep(0.1,0.04,abs(r.x-0.6))*smoothstep(0.35,0.25,abs(r.y-0.15))*step(0.0,r.z)*0.5;
  return c;
}
vec3 env(vec3 r){
  vec3 sky=mix(vec3(0.96,0.93,0.87),vec3(1.0,0.99,0.96),clamp(r.y,0.0,1.0));
  vec3 flo=mix(vec3(0.6,0.48,0.36),vec3(0.86,0.78,0.66),clamp(r.y+1.0,0.0,1.0));
  vec3 c=mix(flo,sky,smoothstep(-0.08,0.08,r.y));
  vec2 w=vec2(r.x+0.42,r.y-0.5);
  c+=smoothstep(0.3,0.2,abs(w.x))*smoothstep(0.24,0.14,abs(w.y))*step(0.0,r.z)*1.4;
  return c;
}

// Bille chinoise : une vraie pépite de verre en volume, avec un dôme sur le dessus et un dessous presque plat.
// Elle est un peu inclinée vers nous (on voit le dessus) et tourne à plat sur elle-même ; le motif est posé sur sa surface.
const float CTT=0.62, CTB=0.26;   // hauteur du dôme / du dessous (1.0 = bille ronde)
const float TC=0.819, TS=0.574;   // inclinaison de 35°
vec2 YW=vec2(1.0,0.0);            // rotation à plat de la pépite (réglée dans main)
bool pep(){ return uAsp>1.01; }
// le dôme penche vers nous : l'œil (+z) se trouve du côté du dessus de la pépite (y>0)
vec3 toO(vec3 v){ vec3 t=vec3(v.x, TC*v.y+TS*v.z, -TS*v.y+TC*v.z); return vec3(YW.x*t.x+YW.y*t.z, t.y, -YW.y*t.x+YW.x*t.z); }
vec3 fromO(vec3 o){ vec3 t=vec3(YW.x*o.x-YW.y*o.z, o.y, YW.y*o.x+YW.x*o.z); return vec3(t.x, TC*t.y-TS*t.z, TS*t.y+TC*t.z); }
float ctOf(float y){ return y>=0.0 ? CTT : CTB; }
vec3 toU(vec3 v){ if(!pep()) return uRot*v; vec3 o=toO(v); return vec3(o.x,o.y/ctOf(o.y),o.z); }   // vue -> repère de la bille (sphère unité)
vec3 normalV(vec3 p){ if(!pep()) return normalize(p); vec3 o=toO(p); float c=ctOf(o.y); return normalize(fromO(vec3(o.x,o.y/(c*c),o.z))); }
// entrée (far=false) ou sortie (far=true) d'un rayon sur une moitié de la pépite ; ed : distance approchée au bord
float halfHit(vec3 o, vec3 d, float c, float sg, bool far, out float ed){
  vec3 o2=vec3(o.x,o.y/c,o.z), d2=vec3(d.x,d.y/c,d.z);
  float a=dot(d2,d2), b=dot(o2,d2), disc=b*b-a*(dot(o2,o2)-1.0);
  ed=disc/(2.0*a);
  if(disc<0.0) return 1e9;
  float t=(-b+(far?1.0:-1.0)*sqrt(disc))/a;
  return (o.y+d.y*t)*sg>=-1e-4 ? t : 1e9;
}

void main(){
  vec2 uv=((gl_FragCoord.xy/uRes)*2.0-1.0)/uR;
  float rad=length(uv);
  float px=2.0/(uRes.x*uR);
  float edge; vec3 n, P;
  if(pep()){
    // lancer de rayon sur la pépite (dôme + dessous plat)
    vec3 r=uRot*vec3(1.0,0.0,0.0); float an=atan(r.z,r.x); YW=vec2(cos(an),sin(an));
    vec3 O=vec3(uv,3.0), D=vec3(0.0,0.0,-1.0), oO=toO(O), dO=toO(D);
    float eT, eB, tT=halfHit(oO,dO,CTT,1.0,false,eT), tB=halfHit(oO,dO,CTB,-1.0,false,eB);
    float ev = tT<1e8 ? eT : (tB<1e8 ? eB : (eT<0.0 ? eT : eB));
    edge=smoothstep(-px*0.4,px*1.2,ev);
    float t=min(tT,tB); if(t>1e8) t=3.0;
    P=O+D*t; n=normalV(P);
  } else {
    edge=1.0-smoothstep(1.0-px*1.5,1.0+px*0.5,rad);
    if(rad>1.0) uv=uv/rad*0.999;
    n=vec3(uv,sqrt(max(0.0,1.0-dot(uv,uv)))); P=n;
  }
  vec3 d0=vec3(0.0,0.0,-1.0);
  vec3 L=normalize(vec3(-0.55,0.65,0.6));
  vec3 rv=reflect(d0,n);
  float F=0.04+0.96*pow(1.0-n.z,5.0);
  vec3 refl=env(rv);
  float sp=max(dot(rv,L),0.0);
  float spec=pow(sp,180.0)*2.5+pow(sp,16.0)*0.12;
  vec3 col;
  vec3 qo=toU(P);   // point de la surface dans le repère de la bille : les effets shiny tournent avec elle
#if OPAQUE
  {
    vec3 q=toU(P); vec3 e;
    vec3 qs=uSRot*q;
    vec4 pc=pattern(q, uPorc>0.5 ? qs*0.8 : qs, e);
    vec3 base=pc.rgb;
    if(uPorc>0.5){
      vec3 porc=vec3(0.97,0.95,0.91);
      base=mix(porc,pc.rgb,clamp(pc.a/15.0,0.0,1.0));
      base=mix(base,clamp(e,0.0,1.0),clamp(length(e)*0.6,0.0,1.0));
    }
    float dif=max(dot(n,L),0.0);
    col=base*(0.36+0.74*dif)+e*0.4;
    col=mix(col,refl,F*0.85+0.05);
    col+=spec*0.85;
#if MODE==8
    col=base*(0.42+0.7*dif)+refl*F*0.15+spec*0.08;   // terre : mate
#elif MODE==9
    // acier : miroir teinté par le coloris, avec de fines stries de polissage qui tournent avec la bille
    float brush=0.9+0.1*noise(vec3(qo.x*3.0,qo.y*80.0,qo.z*3.0)+uSeed.xyz*10.0);
    col=chrome(rv)*mix(vec3(0.95),uC2,0.35)*brush*(0.72+0.28*n.z)+spec*1.6;
#elif MODE==10
    vec3 nac=0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+(1.0-n.z)*0.9+fbm(qs*2.0)*0.8));
    col=mix(col,col*0.75+nac*0.3,0.32)+nac*F*0.35;      // reflets de nacre
#endif
  }
#else
  {
    vec3 d=refract(d0,n,1.0/1.5);
    float tEx=-2.0*dot(n,d);   // longueur traversée dans le verre
    if(pep()){ float e1; vec3 oP=toO(P), dP=toO(d);
      tEx=min(halfHit(oP,dP,CTT,1.0,true,e1), halfHit(oP,dP,CTB,-1.0,true,e1)); if(tEx>1e8) tEx=0.3; }
    float dt=tEx/30.0;
    vec3 acc=vec3(0.0); float T=1.0;
    for(int i=0;i<30;i++){
      vec3 p=P+d*(float(i)+0.5)*dt;
      vec3 q=toU(p); vec3 e;
      vec4 pc=pattern(q, uSRot*q, e);
      float a=1.0-exp(-pc.a*dt);
      float lit=0.55+0.45*clamp(dot(normalize(p+vec3(0.0001)),L)*0.5+0.5,0.0,1.0);
      acc+=T*(a*pc.rgb*lit+e*dt);
      T*=1.0-a;
      if(T<0.01) break;
    }
    vec3 pe=P+d*tEx, ne=normalV(pe);
    vec3 d2=refract(d,-ne,1.5);
    if(dot(d2,d2)<0.01) d2=reflect(d,-ne);
    vec3 bg=env(d2)*pow(max(uTint,vec3(0.02)),vec3(tEx*1.2));
    bg+=uTint*smoothstep(0.55,0.0,length(uv-vec2(0.36,-0.42)))*0.35;
    col=acc+T*bg;
    col=mix(col,refl,F);
    col+=spec;
#if MODE==15
    col=mix(col,vec3(0.93,0.95,1.0)*(0.75+0.25*n.z),0.3);   // givrée : surface dépolie
#endif
  }
#endif
  if(uShiny>0.5 && uShiny<1.5){
    // irisée : film d'huile en volutes, dessiné sur la bille (et qui glisse un peu avec l'angle, comme un vrai reflet)
    float th=fbm(qo*1.7+uSeed.xyz*20.0)*2.4+qo.y*0.5+uSeed.w;
    vec3 iri=0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+th+(1.0-n.z)*0.5));
    // le film couvre toute la bille (plus épais par endroits) : on voit l'arc-en-ciel partout, le décor reste lisible dessous
    float film=0.2+0.4*smoothstep(0.28,0.78,fbm(qo*2.6-uSeed.zxy*12.0));
    col=mix(col,col*0.55+iri*0.6,film);
    col+=iri*(F*1.7+0.07);
  }
  if(uShiny>1.5 && uShiny<2.5){
    // dorée : de petites paillettes d'or posées sur la surface, chacune inclinée un peu différemment ;
    // elles s'allument quand elles attrapent la lumière et scintillent chacune à son rythme
    vec3 gg=qo*38.0+uSeed.zxy*30.0; vec3 gid=floor(gg), gf=fract(gg)-0.5;
    float hk=h31(gid);
    float on=step(0.68,hk)*smoothstep(0.36,0.16,length(gf));
    vec3 fn=normalize(n+(vec3(h31(gid+1.3),h31(gid+2.7),h31(gid+4.1))-0.5)*1.3);
    float gl=pow(max(dot(reflect(d0,fn),L),0.0),28.0);
    gl*=0.25+0.75*pow(0.5+0.5*sin(uTime*2.6+hk*60.0),3.0);
    vec3 goldc=mix(vec3(0.72,0.47,0.13),vec3(1.0,0.86,0.45),fract(hk*7.0));
    col=mix(col, goldc*(0.5+0.5*max(dot(fn,L),0.0))+vec3(1.0,0.95,0.78)*gl*2.4, on*0.95);
    col+=vec3(1.0,0.78,0.3)*F*0.45;
  }
  if(uShiny>2.5){
    // lumineuse : points phosphorescents pris dans la surface
    float st=pow(max(0.0,noise(qo*13.0+uSeed.xyz*40.0)-0.5)*2.0,4.0);
    col+=mix(uC2,vec3(1.0),0.55)*st*2.6;
    col+=mix(uC2,vec3(1.0),0.35)*pow(1.0-n.z,2.2)*0.75;   // le bord rayonne
  }
  col*=mix(0.8,1.0,smoothstep(0.0,0.35,n.z));
  col=clamp(col,0.0,1.0);
  vec4 outc=vec4(col*edge,edge);
  gl_FragColor=outc;
}`;

class MarbleGL{
  constructor(cv){
    this.cv=cv;
    const gl=cv.getContext("webgl",{preserveDrawingBuffer:true,premultipliedAlpha:true,alpha:true,antialias:false});
    if(!gl) throw new Error("webgl indisponible");
    this.gl=gl;
    this.progs=new Map(); this.cur=null;
    const b=gl.createBuffer(); gl.bindBuffer(gl.ARRAY_BUFFER,b);
    gl.bufferData(gl.ARRAY_BUFFER,new Float32Array([-1,-1,1,-1,-1,1,1,1]),gl.STATIC_DRAW);
  }
  // un petit programme par famille × (verre|opaque), compilé à la demande :
  // un seul gros shader met plusieurs minutes à compiler sous Windows (ANGLE/D3D) et fige le navigateur
  use(mode,opaque){
    const gl=this.gl, key=mode*2+opaque;
    let p=this.progs.get(key);
    if(!p){
      const sh=(t,src)=>{const o=gl.createShader(t);gl.shaderSource(o,src);gl.compileShader(o);if(!gl.getShaderParameter(o,gl.COMPILE_STATUS))throw new Error(gl.getShaderInfoLog(o));return o};
      const pr=gl.createProgram();
      gl.attachShader(pr,sh(gl.VERTEX_SHADER,"attribute vec2 p;void main(){gl_Position=vec4(p,0.0,1.0);}"));
      gl.attachShader(pr,sh(gl.FRAGMENT_SHADER,`#define MODE ${mode}
#define OPAQUE ${opaque}
`+FS));
      gl.linkProgram(pr);
      if(!gl.getProgramParameter(pr,gl.LINK_STATUS)) throw new Error(gl.getProgramInfoLog(pr));
      p={pr, loc:gl.getAttribLocation(pr,"p"), u:{}};
      ["uRes","uSeed","uPar","uPorc","uShiny","uSulf","uFig","uR","uAsp","uC1","uC2","uC3","uTint","uRot","uSRot","uTime"].forEach(n=>p.u[n]=gl.getUniformLocation(pr,n));
      this.progs.set(key,p);
    }
    if(this.cur!==p){ gl.useProgram(p.pr); gl.enableVertexAttribArray(p.loc); gl.vertexAttribPointer(p.loc,2,gl.FLOAT,false,0,0); this.cur=p }
    return p.u;
  }
  draw(s,size,rot=I3){
    const gl=this.gl,P=specParams(s),u=this.use(P.mode,P.opaque);
    if(this.cv.width!==size){this.cv.width=this.cv.height=size}
    gl.viewport(0,0,size,size); gl.clearColor(0,0,0,0); gl.clear(gl.COLOR_BUFFER_BIT);
    gl.uniform2f(u.uRes,size,size); gl.uniform4fv(u.uSeed,P.seed); gl.uniform4fv(u.uPar,P.par);
    gl.uniform1f(u.uPorc,P.porc);
    gl.uniform1f(u.uShiny,P.shiny); gl.uniform1f(u.uSulf,P.sulf); gl.uniform1f(u.uFig,P.fig); gl.uniform1f(u.uR,.9); gl.uniform1f(u.uTime,(performance.now()/1000)%600); gl.uniform1f(u.uAsp,P.asp);
    gl.uniform3fv(u.uC1,P.c1); gl.uniform3fv(u.uC2,P.c2); gl.uniform3fv(u.uC3,P.c3); gl.uniform3fv(u.uTint,P.tint);
    gl.uniformMatrix3fv(u.uRot,false,rot); gl.uniformMatrix3fv(u.uSRot,false,P.srot);
    gl.drawArrays(gl.TRIANGLE_STRIP,0,4);
  }
}
function makeGL(cv){ try{ return new MarbleGL(cv) }catch(e){ console.warn("Rendu WebGL indisponible :",e.message); return null } }
const mainGL = makeGL(document.createElement("canvas"));

// Rendu de secours sans WebGL
function draw2D(s,size){
  const c=document.createElement("canvas"); c.width=c.height=size; const x=c.getContext("2d");
  const P=PALETTES[s.pal], R=size/2*.9, m=size/2;
  const g=x.createRadialGradient(m*.8,m*.7,R*.1,m,m,R); g.addColorStop(0,P[3]); g.addColorStop(.5,P[2]); g.addColorStop(1,P[1]);
  x.fillStyle=g; x.beginPath(); x.arc(m,m,R,0,TAU); x.fill();
  x.fillStyle="rgba(255,255,255,.75)"; x.beginPath(); x.ellipse(m*.75,m*.62,R*.22,R*.13,-.6,0,TAU); x.fill();
  return c;
}
const urlCache = new Map();
function marbleURL(s,size=160){
  const k=`${s.seed}|${s.type}|${s.family}|${s.pal}|${s.shiny}@${size}`;
  if(urlCache.has(k)) return urlCache.get(k);
  let u;
  try{ mainGL.draw(s,size); u=mainGL.cv.toDataURL("image/png") }catch(e){ u=draw2D(s,size).toDataURL("image/png") }
  urlCache.set(k,u); return u;
}
// les Lumineuses rayonnent : lueur CSS qui suit la forme ronde de la bille
const lumAttr = s => s.shiny===3 ? ` data-lum style="--lc:${PALETTES[s.pal][2]}"` : "";
function mImg(s,size=160,px,alt){
  const w = Math.round(px ?? size/2), lum = s.shiny===3;
  // hauteur automatique : si la case est plus étroite que prévu, la bille rétrécit sans devenir ovale
  return `<img src="${marbleURL(s,size)}" alt="${alt===undefined?esc(specName(s)):alt}" width="${w}" height="${w}"${lum?" data-lum":""} style="width:${w}px;height:auto;aspect-ratio:1${lum?`;--lc:${PALETTES[s.pal][2]}`:""}">`;
}
// bille "fantôme" pour les emplacements vides
const ghost = (type,family) => ({seed:hash(type+family), type, family, pal:23, shiny:0});

const ICON = {
  home:'<path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/>',
  bag:'<path d="M9 7.5h6"/><path d="M8.5 7.5 7 4h10l-1.5 3.5"/><path d="M8.5 7.5C5.5 10 4 13 4 16a4 4 0 0 0 4 4h8a4 4 0 0 0 4-4c0-3-1.5-6-4.5-8.5"/><circle cx="12" cy="14.5" r="2"/>',
  layers:'<path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 12.5l9 5 9-5"/><path d="M3 16.5l9 5 9-5"/>',
  pad:'<path d="M6.5 8h11A4.5 4.5 0 0 1 22 12.5v.5a4 4 0 0 1-7.2 2.4L14 14.5h-4l-.8.9A4 4 0 0 1 2 13v-.5A4.5 4.5 0 0 1 6.5 8z"/><path d="M7 10.5v3M5.5 12h3"/><circle cx="16" cy="11.5" r=".6" fill="currentColor"/><circle cx="18" cy="13.5" r=".6" fill="currentColor"/>',
  swap:'<path d="M4 8h15l-3.5-3.5"/><path d="M20 16H5l3.5 3.5"/>',
  book:'<path d="M12 6.5C10 5 7 4.5 3.5 5v14c3.5-.5 6.5 0 8.5 1.5 2-1.5 5-2 8.5-1.5V5C17 4.5 14 5 12 6.5z"/><path d="M12 6.5v14"/>',
  cal:'<rect x="3.5" y="5" width="17" height="15.5" rx="2"/><path d="M3.5 10h17M8 3v4M16 3v4"/><path d="M8 14h.01M12 14h.01M16 14h.01M8 17h.01M12 17h.01"/>',
  locker:'<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 7h2M9 10h2M15 12v2.5M5 17h14"/>',
  trophy:'<path d="M8 4h8v5a4 4 0 0 1-8 0z"/><path d="M8 6H5a3 3 0 0 0 3.2 4M16 6h3a3 3 0 0 1-3.2 4"/><path d="M12 13v3.5M8.5 20.5h7M10 16.5h4v4h-4z"/>',
  gear:'<circle cx="12" cy="12" r="3"/><path d="M12 2.5v2.5M12 19v2.5M4.6 4.6l1.8 1.8M17.6 17.6l1.8 1.8M2.5 12H5M19 12h2.5M4.6 19.4l1.8-1.8M17.6 6.4l1.8-1.8"/>',
  target:'<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1" fill="currentColor"/>',
  arrow:'<path d="M5 12h14M13 6l6 6-6 6"/>',
  chev:'<path d="M9 6l6 6-6 6"/>',
  chevl:'<path d="M15 6l-6 6 6 6"/>',
  play:'<path d="M8 5.5v13l10-6.5z"/>',
  clock:'<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  recycle:'<path d="M7 19H4.5a1.5 1.5 0 0 1-1.3-2.2L6 12"/><path d="M11 19h8.5a1.5 1.5 0 0 0 1.3-2.2L18.5 13"/><path d="M14.5 5.3 13.3 3.2a1.5 1.5 0 0 0-2.6 0L8.5 7"/><path d="M9 16l2 3-2 3M3.5 9.5 6 12l3-1M17 6l-2.5-.7L14 8"/>',
  quest:'<path d="M6 3h9l3 3v15H6z"/><path d="M9 10h6M9 14h6M9 18h3"/>',
  check:'<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  candy:'<circle cx="12" cy="12" r="5"/><path d="M7.4 10.2 3 7.5v9l4.4-2.7M16.6 10.2 21 7.5v9l-4.4-2.7"/><path d="M10 8.5c1.5 1 3 4 4 7"/>',
  flag:'<path d="M5 21V4"/><path d="M5 4h12l-2.5 4L17 12H5"/>',
  pot:'<ellipse cx="12" cy="16" rx="8.5" ry="3.8"/><ellipse cx="12" cy="16" rx="4" ry="1.6"/><circle cx="7" cy="7.5" r="2.4"/><circle cx="15.5" cy="6" r="2"/>',
  castle:'<circle cx="12" cy="6" r="2.2"/><circle cx="9.5" cy="10.3" r="2.2"/><circle cx="14.5" cy="10.3" r="2.2"/><circle cx="7" cy="14.6" r="2.2"/><circle cx="12" cy="14.6" r="2.2"/><circle cx="17" cy="14.6" r="2.2"/><path d="M3 20.5h18"/>',
  tic:'<circle cx="7.5" cy="15.5" r="4"/><circle cx="17" cy="8" r="3.5"/><path d="M11 12.5l2.6-2"/><path d="M14 16l1.5 1.5M16.5 13.5l2 .5M12.5 18.5l.5 2"/>',
  users:'<circle cx="9" cy="8.5" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><circle cx="17" cy="9.5" r="2.8"/><path d="M16 14.2a5.5 5.5 0 0 1 6 5.8"/>',
  cour:'<path d="M4 21V10l8-6 8 6v11"/><path d="M9 21v-6h6v6"/><circle cx="7" cy="18.5" r="1"/><circle cx="17" cy="18.5" r="1"/>',
  search:'<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>',
  ticket:'<path d="M3 7.5A1.5 1.5 0 0 1 4.5 6h15A1.5 1.5 0 0 1 21 7.5V10a2 2 0 0 0 0 4v2.5a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 16.5V14a2 2 0 0 0 0-4z"/><path d="M15 6v2.5M15 11v2M15 15.5V18"/>',
  lock:'<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  flask:'<path d="M9.5 3h5M10.5 3v5.5L5 18.2A1.8 1.8 0 0 0 6.6 21h10.8a1.8 1.8 0 0 0 1.6-2.8L13.5 8.5V3"/><path d="M7.5 14.5h9"/>',
  user:'<circle cx="12" cy="8" r="4"/><path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  shield:'<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8.3-7.5 9.5-4.3-1.2-7.5-4.9-7.5-9.5V6z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
  gift:'<rect x="3.5" y="8" width="17" height="4" rx="1"/><path d="M5 12v8h14v-8M12 8v12M12 8C10.5 4 7 4 7 6s3 2 5 2c2 0 5 0 5-2s-3.5-2-5 2"/>',
  star:'<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z"/>',
};
const ic = (k,s=22,sw=2) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON[k]}</svg>`;
const COIN = `<svg class="coin" viewBox="0 0 24 24" aria-hidden="true"><path d="M6.6 12 1.6 8.1l.9 3.9-.9 3.9z" fill="#FF9FD0" stroke="#D9468F" stroke-width="1" stroke-linejoin="round"/><path d="M17.4 12l5-3.9-.9 3.9.9 3.9z" fill="#FF9FD0" stroke="#D9468F" stroke-width="1" stroke-linejoin="round"/><circle cx="12" cy="12" r="6.3" fill="#FF5FA8" stroke="#D9468F" stroke-width="1.2"/><path d="M8.3 9.6c2.2.8 5 3.9 7 6.2M10 6.6c1.9 1.2 4.7 4.6 6 7.1" stroke="#fff" stroke-width="1.4" opacity=".8" fill="none" stroke-linecap="round"/><circle cx="9.8" cy="9.4" r="1.2" fill="#fff" opacity=".7"/></svg>`;
const STAR = on => `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5l2.9 6 6.6.8-4.9 4.5 1.3 6.5L12 17.1l-5.9 3.2 1.3-6.5L2.5 9.3l6.6-.8z" fill="${on?"#FFC93F":"#E6DCCB"}" stroke="${on?"#E0A417":"#D6C8B0"}" stroke-width="1.2" stroke-linejoin="round"/></svg>`;

let uid=0;
// Chaque sac a sa matière : toile de jute, coton, velours, satin doré
const BAG_LOOK = {
  gratuit:  {tex:"jute",   cord:"#7A5A32", cordW:4.5, bead:"#E9D3A6", patch:"square", paper:"#F4E6C8"},
  classique:{tex:"coton",  cord:"#F4E3C2", cordW:5,   bead:"#B9824A", patch:"round",  paper:"#FFF6E2"},
  premium:  {tex:"velours",cord:"#E8B53A", cordW:5,   bead:"#FFD86B", patch:"round",  paper:"#FFF6E2", ring:"#E8B53A"},
  collector:{tex:"satin",  cord:"#B8322A", cordW:5.5, bead:"#FFD86B", patch:"star",   paper:"#FFF3C4", tassel:true, sparks:true},
};
// petite bille en verre dessinée en SVG (dans le goulot du sac, ou par terre à côté)
function dotMarble(x,y,r,col,id,cls=""){
  return `<g class="${cls}"><circle cx="${x}" cy="${y}" r="${r}" fill="url(#${id}-m${col.slice(1)})"/>
  <path d="M${x-r*.7} ${y+r*.1}C${x-r*.2} ${y-r*.6},${x+r*.2} ${y+r*.6},${x+r*.7} ${y-r*.1}" stroke="${shade(col,.55)}" stroke-width="${r*.32}" fill="none" stroke-linecap="round" opacity=".85"/>
  <ellipse cx="${x-r*.35}" cy="${y-r*.4}" rx="${r*.3}" ry="${r*.2}" fill="#fff" opacity=".8"/></g>`;
}
const DOT_COLS = ["#E0533D","#3C8DDE","#F2C230","#38B37A"];
// bagSVG(sac, {loose:true} pour quelques billes posées par terre à côté)
function bagSVG(b, o={}){
  if(typeof b==="string") b = BAGS.find(x=>x.color===b) || {id:"classique", color:b};
  const L = BAG_LOOK[b.id] || BAG_LOOK.classique, c = b.color;
  const id="bg"+(++uid), d=shade(c,-.38), dd=shade(c,-.6), l=shade(c,.35);
  const body = "M76 88C44 104 22 150 30 186C38 214 162 214 170 186C178 150 156 104 124 88Z";
  const lip = "M74 88C64 70 56 52 53 38Q63 47 72 39Q80 50 89 41Q96 51 104 42Q112 51 120 41Q128 50 136 39Q142 47 147 38C144 52 136 70 126 88Z";
  const tex = {
    jute:`<pattern id="${id}-t" width="6" height="6" patternUnits="userSpaceOnUse" patternTransform="rotate(-6)"><path d="M0 1.5h6M0 4.5h6" stroke="${dd}" stroke-opacity=".22" stroke-width="1.3"/><path d="M1.5 0v6M4.5 0v6" stroke="#fff" stroke-opacity=".12" stroke-width="1.1"/></pattern>`,
    coton:`<pattern id="${id}-t" width="7" height="7" patternUnits="userSpaceOnUse" patternTransform="rotate(35)"><path d="M0 3.5h7" stroke="${dd}" stroke-opacity=".12" stroke-width="2"/></pattern>`,
    velours:`<radialGradient id="${id}-t" cx="42%" cy="46%" r="62%"><stop offset=".55" stop-color="${dd}" stop-opacity="0"/><stop offset="1" stop-color="${dd}" stop-opacity=".75"/></radialGradient>`,
    satin:`<linearGradient id="${id}-t" x1="0" y1="0" x2="1" y2=".35"><stop offset=".18" stop-color="#fff" stop-opacity="0"/><stop offset=".3" stop-color="#fff" stop-opacity=".55"/><stop offset=".4" stop-color="#fff" stop-opacity="0"/><stop offset=".62" stop-color="#fff" stop-opacity="0"/><stop offset=".7" stop-color="#fff" stop-opacity=".3"/><stop offset=".78" stop-color="#fff" stop-opacity="0"/></linearGradient>`,
  }[L.tex];
  const mgrads = DOT_COLS.map(m=>`<radialGradient id="${id}-m${m.slice(1)}" cx="38%" cy="34%" r="70%"><stop offset="0" stop-color="${shade(m,.45)}"/><stop offset=".55" stop-color="${m}"/><stop offset="1" stop-color="${shade(m,-.45)}"/></radialGradient>`).join("");
  const patch = L.patch==="square"
    ? `<g transform="rotate(-5 100 150)"><rect x="78" y="128" width="44" height="44" rx="6" fill="${L.paper}"/><rect x="82" y="132" width="36" height="36" rx="4" fill="none" stroke="${d}" stroke-width="1.6" stroke-dasharray="4 3"/></g>`
    : L.patch==="star"
    ? `<path d="M100 122l8.2 16.6 18.3 2.7-13.2 12.9 3.1 18.2L100 163.8l-16.4 8.6 3.1-18.2-13.2-12.9 18.3-2.7z" fill="${L.paper}" stroke="${d}" stroke-width="2.5" stroke-linejoin="round"/>`
    : `<circle cx="100" cy="150" r="22" fill="${L.paper}" stroke="${d}" stroke-width="3"/>${L.ring?`<circle cx="100" cy="150" r="17.5" fill="none" stroke="${L.ring}" stroke-width="1.6" stroke-dasharray="3 2.4"/>`:""}`;
  const end = (x,y) => L.tassel
    ? `<path d="M${x} ${y}l-5 16h10z" fill="${L.cord}"/><path d="M${x-3} ${y+4}v11M${x} ${y+4}v12M${x+3} ${y+4}v11" stroke="${shade(L.cord,-.35)}" stroke-width="1"/><circle cx="${x}" cy="${y}" r="4" fill="${L.bead}"/>`
    : `<circle cx="${x}" cy="${y}" r="5" fill="${L.bead}" stroke="${shade(L.bead,-.4)}" stroke-width="1.4"/>`;
  const spark = (x,y,s) => `<path class="bag-spark" d="M${x} ${y-s}Q${x} ${y} ${x+s} ${y}Q${x} ${y} ${x} ${y+s}Q${x} ${y} ${x-s} ${y}Q${x} ${y} ${x} ${y-s}z" fill="#fff"/>`;
  return `<svg viewBox="${o.loose?"-26 0 252 230":"0 0 200 230"}" aria-hidden="true">
  <defs><radialGradient id="${id}" cx="36%" cy="40%" r="75%"><stop offset="0" stop-color="${l}"/><stop offset=".55" stop-color="${c}"/><stop offset="1" stop-color="${d}"/></radialGradient>
  <radialGradient id="${id}-b" cx="38%" cy="32%" r="62%"><stop offset="0" stop-color="#fff" stop-opacity=".38"/><stop offset=".5" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="${dd}" stop-opacity=".3"/></radialGradient>
  <clipPath id="${id}-c"><path d="${body}"/></clipPath>${tex}${mgrads}</defs>
  <ellipse cx="100" cy="212" rx="74" ry="9" fill="rgba(40,25,10,.22)"/>
  ${o.loose?`<ellipse cx="-4" cy="219" rx="12" ry="3" fill="rgba(40,25,10,.2)"/><ellipse cx="207" cy="220" rx="10" ry="2.6" fill="rgba(40,25,10,.2)"/>`:""}
  <ellipse cx="100" cy="40" rx="45" ry="10" fill="${dd}"/>
  <g class="bag-peek">${dotMarble(82,36,12,DOT_COLS[0],id)}${dotMarble(122,37,11,DOT_COLS[2],id)}${dotMarble(102,30,13,DOT_COLS[1],id)}</g>
  <path d="${body}" fill="url(#${id})"/>
  <g clip-path="url(#${id}-c)">
    <rect x="0" y="80" width="200" height="140" fill="url(#${id}-t)"/>
    <g class="bag-bumps"><circle cx="66" cy="190" r="16" fill="url(#${id}-b)"/><circle cx="102" cy="200" r="15" fill="url(#${id}-b)"/><circle cx="138" cy="188" r="15" fill="url(#${id}-b)"/></g>
    <path d="M84 96C70 122 64 150 70 178M116 96C132 124 138 150 132 180M100 98C98 118 100 128 97 136" stroke="${dd}" stroke-opacity=".28" stroke-width="3" fill="none" stroke-linecap="round"/>
    <path d="M60 116C47 140 45 166 54 190" stroke="#fff" stroke-opacity="${L.tex==="velours"?.18:.3}" stroke-width="7" fill="none" stroke-linecap="round"/>
    <path d="M36 196C60 212 140 212 164 196" stroke="${dd}" stroke-opacity=".35" stroke-width="1.6" stroke-dasharray="5 4" fill="none"/>
  </g>
  <path d="${lip}" fill="${c}"/>
  <path d="${lip}" fill="url(#${id}-t)" stroke="${d}" stroke-width="2.5" stroke-linejoin="round"/>
  <path d="M68 50C72 62 76 72 82 84M100 52V84M132 50C128 62 124 72 118 84" stroke="${dd}" stroke-opacity=".3" stroke-width="2" fill="none" stroke-linecap="round"/>
  <path d="M70 82Q100 94 130 82L129 95Q100 106 71 95Z" fill="${d}"/>
  <path d="M69 87Q100 100 131 87" stroke="${L.cord}" stroke-width="${L.cordW}" fill="none" stroke-linecap="round"/>
  <path d="M71 94Q100 106 129 94" stroke="${shade(L.cord,-.2)}" stroke-width="${L.cordW-1}" fill="none" stroke-linecap="round"/>
  <path d="M113 99C121 108 116 116 123 122M113 99C106 109 110 117 103 124" stroke="${L.cord}" stroke-width="${L.cordW-1}" fill="none" stroke-linecap="round"/>
  <ellipse cx="113" cy="99" rx="7" ry="5.5" fill="${L.cord}" stroke="${shade(L.cord,-.3)}" stroke-width="1.5"/>
  ${end(123,124)}${end(103,126)}
  ${patch}
  <text x="100" y="${L.patch==="star"?159:161}" text-anchor="middle" font-family="Lilita One, sans-serif" font-size="${L.patch==="star"?21:26}" fill="${d}">B</text>
  ${L.sparks?spark(38,72,7)+spark(170,118,6)+spark(160,58,5)+spark(44,168,4):""}
  ${o.loose?dotMarble(-4,208,11,DOT_COLS[1],id,"loose l1")+dotMarble(207,211,9,DOT_COLS[3],id,"loose l2"):""}
</svg>`;
}

const SERIES = [
  {id:"trousse", name:"La trousse d'écolier", desc:"Les motifs du cahier de classe.", items:[{fam:"Damier"},{fam:"Écossais"},{fam:"Pixel"},{fam:"Cible"}], rew:{j:300, bag:"classique"}},
  {id:"bonbons", name:"La boulangerie du coin", desc:"Des billes qui donnent faim.", items:[{fam:"Berlingot"},{fam:"Millefiori"},{fam:"À pois"},{fam:"Nid d'abeille"},{pal:"Barbe à papa"},{pal:"Chocolat menthe"}], rew:{j:500, bag:"premium"}},
  {id:"nature", name:"Au fond du jardin", desc:"Ce qu'on trouve en rentrant de l'école.", items:[{fam:"Bois"},{fam:"Écailles"},{fam:"Tigrée"},{fam:"Œil-de-chat"},{pal:"Forêt"},{pal:"Sauge"}], rew:{j:500, bag:"premium"}},
  {id:"arcenciel", name:"L'arc-en-ciel", desc:"Une bille de chaque couleur, peu importe le décor.", items:["Cerise","Ambre","Citron","Émeraude","Azur","Saphir","Lavande"].map(pal=>({pal})), rew:{j:600, bag:"premium"}},
  {id:"noiretblanc", name:"Noir et blanc", desc:"Pour les amateurs de contrastes.", items:[{pal:"Encre"},{pal:"Réglisse"},{pal:"Béton"},{pal:"Brume"},{pal:"Ciel d'orage"}], rew:{j:400, bag:"classique"}},
  {id:"pierres", name:"Les pierres précieuses", desc:"Des pierres dans les coloris des joyaux.", items:[{fam:"Agate",pal:"Rubis"},{fam:"Marbre",pal:"Saphir"},{fam:"Cristal",pal:"Émeraude"},{fam:"Nacrée",pal:"Opale"}], rew:{j:2500, bag:"collector", title:"Joaillier"}},
  {id:"feuglace", name:"Le feu et la glace", desc:"Du plus chaud au plus froid.", items:[{fam:"Lave"},{fam:"Givrée"},{pal:"Volcan"},{pal:"Glacier"}], rew:{j:700, bag:"premium"}},
  {id:"cosmos", name:"Le système solaire", desc:"Les décors venus d'ailleurs.", items:[{fam:"Globe"},{fam:"Planète"},{fam:"Galaxie"},{fam:"Aurore"}], rew:{j:3000, bag:"collector", title:"Astronome"}},
  {id:"grands", name:"Les grands formats", desc:"De la plus petite à la plus grosse, dans un même décor.", items:TK.map(type=>({type})), same:"family", rew:{j:4000, bag:"collector", title:"Toutes tailles"}},
];
function artPot(){ return `<svg viewBox="0 0 240 130" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="240" height="130" fill="#B8895A"/><circle cx="60" cy="30" r="1.5" fill="#8C6440"/><circle cx="200" cy="100" r="2" fill="#8C6440"/><circle cx="120" cy="110" r="1.5" fill="#D9B48A"/>
  <path d="M40 10v110" stroke="#fff" stroke-width="3" stroke-dasharray="7 6" opacity=".8"/><ellipse cx="165" cy="68" rx="20" ry="13" fill="#3A2614"/><ellipse cx="165" cy="66" rx="20" ry="12" fill="#1E130A"/>
  <circle cx="56" cy="70" r="8" fill="#2E8CFF" stroke="#fff" stroke-width="1.5"/><circle cx="130" cy="44" r="7" fill="#E5484D"/><circle cx="196" cy="88" r="7" fill="#FFC93F"/><path d="M66 68Q110 60 146 66" stroke="#fff" stroke-width="2" stroke-dasharray="3 5" fill="none"/></svg>` }
function artChateau(){ const dots=[]; for(let i=0;i<4;i++) for(let j=0;j<=i;j++) dots.push(`<circle cx="${142+i*13}" cy="${65+(j-i/2)*15}" r="7" fill="${["#E5484D","#FFC93F","#2FA35A","#7B6CF6"][(i+j)%4]}" stroke="rgba(0,0,0,.2)"/>`);
  return `<svg viewBox="0 0 240 130" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="240" height="130" fill="#B8895A"/><circle cx="162" cy="65" r="50" fill="none" stroke="#fff" stroke-width="3" opacity=".85"/>${dots.join("")}
  <circle cx="44" cy="80" r="9" fill="#2E8CFF" stroke="#fff" stroke-width="1.5"/><path d="M56 77Q95 70 128 67" stroke="#fff" stroke-width="2" stroke-dasharray="3 5" fill="none"/></svg>` }
function artTic(){ return `<svg viewBox="0 0 240 130" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="240" height="130" fill="#B8895A"/><circle cx="170" cy="30" r="2" fill="#8C6440"/><circle cx="40" cy="110" r="1.6" fill="#8C6440"/>
  <circle cx="70" cy="82" r="11" fill="#2E8CFF" stroke="#fff" stroke-width="1.5"/><circle cx="168" cy="54" r="10" fill="#E5484D" stroke="#fff" stroke-width="1.5"/><path d="M83 78Q125 62 154 57" stroke="#fff" stroke-width="2" stroke-dasharray="3 5" fill="none"/>
  <text x="178" y="92" font-family="Lilita One, sans-serif" font-size="24" fill="#FFE14D" stroke="#3A2614" stroke-width="1">TIC !</text></svg>` }
function artTir(){ return `<svg viewBox="0 0 240 130" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="240" height="130" fill="#8B5A2B"/><rect x="8" y="8" width="224" height="114" rx="4" fill="#3E9A4A"/><rect x="60" y="8" width="18" height="76" fill="#A8713F"/><rect x="140" y="46" width="18" height="76" fill="#A8713F"/>
  <circle cx="205" cy="36" r="7" fill="#12220F"/><path d="M205 36V12" stroke="#fff" stroke-width="2"/><path d="M205 12l13 5-13 5z" fill="#E5484D"/><circle cx="30" cy="100" r="7" fill="#2E8CFF" stroke="#fff" stroke-width="1.5"/><path d="M40 95Q100 128 118 28" stroke="#fff" stroke-width="2" stroke-dasharray="3 5" fill="none"/></svg>` }
function artCourse(){ return `<svg viewBox="0 0 240 130" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="240" height="130" fill="#EBD3A0"/>
  <path d="M-5 105C60 105 60 40 120 40S180 100 245 60" stroke="#C9A56A" stroke-width="30" fill="none" stroke-linecap="round"/><path d="M-5 105C60 105 60 40 120 40S180 100 245 60" stroke="#D9BC80" stroke-width="22" fill="none" stroke-linecap="round"/>
  <circle cx="40" cy="103" r="7" fill="#2E8CFF" stroke="#fff" stroke-width="1.5"/><circle cx="92" cy="58" r="6.5" fill="#E5484D"/><circle cx="140" cy="45" r="6.5" fill="#FFC93F"/>
  <path d="M205 20v42" stroke="#5A3A20" stroke-width="2.5"/><path d="M205 20h24v14h-24z" fill="#fff"/><path d="M205 20h6v7h-6zM217 20h6v7h-6zM211 27h6v7h-6zM223 27h6v7h-6z" fill="#24253D"/></svg>` }
function artCasse(){
  const cols = ["#E5484D","#FF9F1C","#FFC93F","#2FA35A"], out = [];
  for(let r=0;r<4;r++) for(let c=0;c<8;c++) if(!(r===3 && (c===2||c===5))) out.push(`<rect x="${14+c*27.5}" y="${14+r*14}" width="24" height="11" rx="2.5" fill="${cols[r]}"/>`);
  return `<svg viewBox="0 0 240 130" preserveAspectRatio="xMidYMid slice" aria-hidden="true"><rect width="240" height="130" fill="#1B2350"/>${out.join("")}
  <path d="M104 86Q120 72 150 64" stroke="#fff" stroke-width="2" stroke-dasharray="3 5" fill="none" opacity=".7"/><circle cx="96" cy="92" r="7" fill="#2E8CFF" stroke="#fff" stroke-width="1.5"/>
  <rect x="62" y="110" width="64" height="9" rx="4.5" fill="#FFC93F"/><path d="M70 115v4M78 115v4M86 113v6M94 115v4M102 115v4M110 115v4M118 113v6" stroke="rgba(0,0,0,.3)"/></svg>`;
}
