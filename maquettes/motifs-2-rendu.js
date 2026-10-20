/* Extrait automatique de index.html du 2026-10-19 (outils/extraire-rendu.mjs) : données, rendu WebGL des billes, icônes, sachets,
   aperçus des jeux, marelle, distributeur, chaudron. Ne pas modifier à la main : relancer l'extraction. */
/* =====================================================================
   DONNÉES DU JEU
   ===================================================================== */
const CGU_VERSION = "2026-10-08";   // version des règles du jeu (legal.html#cgu), gardée dans le compte à l'inscription
const CUR = {one:"bonbec", many:"bonbecs"};         // la monnaie de la cour : des bonbecs !
const FREE_EVERY = 10*60*1000;                        // un sachet gratuit toutes les 10 minutes

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

// Familles de motif (chacune a son propre rendu)
// Fréquence des motifs (poids de tirage). Les noms ne s'affichent plus : la rareté, c'est la taille.
const DECOR_RAR = [
  {name:"Commun",     w:10, c:"#8E8898"},
  {name:"Peu commun", w:5,  c:"#2F8F45"},
  {name:"Rare",       w:3.5,c:"#2E6BE6"},   // (10 octobre 2026, le soir) 2,5 → 3,5 et 0,8 → 1,2 : avec les 13 nouveaux motifs, les rares et les épiques sortaient trop peu
  {name:"Épique",     w:1.2, c:"#8A4AD6"},
  {name:"Légendaire", w:.2, c:"#D97E06"},
  {name:"Mythique",   w:.02, c:"#E0182D"},   // (10 octobre 2026) un seul motif, l'Œil du Dragon (le Vortex jusqu'au 11 octobre) : 10 fois plus rare qu'un légendaire (6 dans supabase/serveur.sql, 5 y étant les événements)
];
// Familles de motif (chacune a son propre rendu). L'ordre ne doit pas changer : il sert d'identifiant.
const FAMILIES = [
  {name:"Œil-de-chat", rar:0, desc:"Des pétales de verre coloré pris au cœur de la bille."},
  {name:"Tourbillon",  rar:0, desc:"De fins filets de couleur qui s'enroulent en spirale sous la surface."},
  {name:"Galaxie",     rar:4, desc:"Une galaxie spirale qui tourne au cœur d'un verre sombre, entourée de nébuleuses et d'étoiles."},
  {name:"Agate",       rar:1, desc:"Une pierre opaque, veinée comme une vraie agate."},
  {name:"Opaline",     rar:0, desc:"Un verre laiteux qui garde la lumière."},
  {name:"Pailletée",   rar:2, desc:"Un verre teinté rempli de paillettes qui scintillent à la lumière."},
  {name:"Oignon",      rar:0, desc:"Une couche colorée étirée juste sous la surface."},
  {name:"Berlingot",   rar:0, desc:"Des rayures de sucre d'orge, opaques et brillantes."},
  {name:"Terre",       rar:2, desc:"La bille des grands-parents : de l'argile cuite, peinte à la main."},
  {name:"Acier",       rar:2, desc:"Une bille de roulement en acier poli, lourde et brillante comme un miroir."},
  {name:"Nacrée",      rar:3, desc:"Un reflet de perle qui change de couleur selon l'angle."},
  {name:"Cristal",     rar:2, desc:"Un verre clair où sont restées prisonnières de petites bulles d'air."},
  {name:"Arlequin",    rar:1, desc:"Des taches de couleur opaques cousues comme un patchwork."},
  {name:"Ruban",       rar:1, desc:"Un large ruban blanc torsadé en plein cœur du verre, rayé de fins filets de couleur."},
  {name:"Millefiori",  rar:1, desc:"Des centaines de petites fleurs de verre, comme à Venise."},
  {name:"Givrée",      rar:2, desc:"Un verre dépoli, doux comme le givre sur une vitre."},
  {name:"Fumée",       rar:2, desc:"Des volutes de fumée prisonnières du verre."},
  {name:"Lave",        rar:3, desc:"Une roche sombre traversée de fissures brûlantes."},
  {name:"Marbre",      rar:2, desc:"Une pierre blanche veinée, comme un escalier de palais."},
  {name:"Tigrée",      rar:2, desc:"Des rayures sauvages de grand fauve."},
  {name:"À pois",      rar:0, desc:"Des pois bien ronds, comme une coccinelle."},
  {name:"Damier",      rar:0, desc:"Des cases bien nettes qui font le tour de la bille, comme un ballon de plage."},
  {name:"Écossais",    rar:1, desc:"Un tartan tissé serré, comme la couverture de pique-nique."},
  {name:"Nid d'abeille", rar:1, desc:"Des alvéoles de cire pleines de miel."},
  {name:"Cible",       rar:0, desc:"Des anneaux bien ronds : vise le centre !"},
  {name:"Pixel",       rar:1, desc:"De gros carrés, comme dans les vieux jeux vidéo."},
  {name:"Globe",       rar:3, desc:"Des océans, des continents et des nuages : un monde entier dans la main."},
  {name:"Planète",     rar:3, desc:"Des bandes de nuages géantes et une tempête qui tourne depuis toujours."},
  {name:"Bois",        rar:1, desc:"Du bois verni, avec ses cernes et son fil."},
  {name:"Écailles",    rar:2, desc:"Des écailles qui brillent, comme un poisson… ou un dragon."},
  {name:"Aurore",      rar:4, desc:"Un verre nuit où dansent des rideaux de lumière."},
  {name:"Craquelée",   rar:2, desc:"Un verre clair fêlé de l'intérieur, qui accroche la lumière."},
  // motifs d'événement : jamais dans les sachets ni dans l'album, on ne les trouve que pendant leur événement
  {name:"Pirate",      rar:4, event:"pirates", desc:"Le drapeau noir des flibustiers : une tête de mort et ses deux os, cerclée d'or comme un coffre au trésor."},
  // nouveaux motifs (après le Pirate : les numéros ne bougent jamais)
  {name:"Vitrail",     rar:1, desc:"Des éclats de verre coloré sertis de plomb, comme les vitraux d'une cathédrale : la lumière passe au travers."},
  {name:"Trou noir",   rar:4, desc:"Un horizon noir d'où rien ne ressort, entouré d'un disque de matière brûlante qui tourne sans fin."},
  // motifs de saison (un par mois, en édition limitée) : seulement dans le passe de saison, jamais dans les sachets ni dans les cases de l'album
  {name:"Givre",         rar:4, season:0,  desc:"Des fougères de glace ont poussé contre la paroi d'un verre glacé."},
  {name:"Confettis",     rar:4, season:1,  desc:"Des confettis et des serpentins qui flottent dans le verre : c'est le carnaval !"},
  {name:"Cerisier",      rar:4, season:2,  desc:"Une petite branche de cerisier en fleurs prise dans le verre, et ses pétales qui volent."},
  {name:"Aquarium",      rar:4, season:3,  desc:"De petits poissons qui tournent en rond dans l'eau, et des bulles qui montent. Poisson d'avril !"},
  {name:"Papillons",     rar:4, season:4,  desc:"Des papillons aux ailes colorées qui volent dans le verre, comme dans un jardin au mois de mai."},
  {name:"Soleil",        rar:4, season:5,  desc:"Une boule de feu au cœur du verre, et ses rayons qui partent tout droit."},
  {name:"Plage",         rar:4, season:6,  desc:"Le sable, la mer, un parasol et le soleil, enfermés dans le verre : les grandes vacances en poche."},
  {name:"Étoiles filantes", rar:4, season:7, desc:"Des traînées de lumière qui filent dans un ciel de nuit d'été. Fais un vœu !"},
  {name:"Crayons",       rar:4, season:8,  desc:"De petits crayons de couleur bien taillés qui flottent dans le verre : c'est la rentrée !"},
  {name:"Citrouille",    rar:4, season:9,  desc:"Une petite citrouille-lanterne qui brille dans un verre de nuit, entourée d'étincelles."},
  {name:"Feuilles mortes", rar:4, season:10, desc:"Des feuilles d'érable rousses, jaunes et rouges qui tombent en tournoyant dans le verre."},
  {name:"Boule à neige", rar:4, season:11, desc:"Un sapin sur un tapis de neige, une étoile au sommet, et des flocons qui flottent tout autour."},
  // la bille des bêta-testeurs : jamais dans les sachets ni dans l'album
  {name:"Bêta",          rar:4, beta:true, desc:"Un β d'or qui brille au cœur d'un verre précieux (une pierre différente pour chaque taille), cerclé d'un anneau d'or : la bille de ceux qui ont testé Tikalo avant tout le monde."},
  // événement de novembre 2026 « Super-héros ! » (numéro 48 : toujours à la fin, les numéros ne bougent jamais)
  {name:"Super-héros",   rar:4, event:"superheros", desc:"Chaque coloris est un héros de la cour, avec son blason derrière les rayons d'une case de bande dessinée : l'écusson de Capitaine Éclair, les ailes de Fulgura, le masque d'Ombre violette, le poing du Titan vert et la flamme de Flamme écarlate."},
  // (7 octobre 2026) nouveaux motifs : un légendaire (49, le Prisme, qui remplace l'Œil de dragon du même jour ; épique depuis le 8 octobre) et deux épiques (50, 51)
  {name:"Prisme",        rar:3, face:true, desc:"Un prisme de cristal au cœur d'un verre profond : un rayon de lumière blanche le traverse et ressort en arc-en-ciel."},
  {name:"Orage",         rar:3, desc:"Un ciel d'orage enfermé dans le verre, traversé d'éclairs qui l'illuminent de l'intérieur."},
  {name:"Méduse",        rar:3, face:true, desc:"Une méduse lumineuse flotte dans un verre d'eau profonde, ses longs filaments qui ondulent sous elle."},
  // (10 octobre 2026) la nouvelle tier list : 12 nouveaux motifs (52 à 63) et le motif mythique (64), toujours à la fin
  {name:"Étoilée",       rar:0, desc:"Des petites étoiles à cinq branches semées sur toute la bille, comme un ciel de pyjama."},
  {name:"Cœurs",         rar:0, desc:"De petits cœurs de toutes les tailles sur un fond clair : la bille qu'on offre à son copain ou sa copine."},
  {name:"Bicolore",      rar:0, face:true, desc:"Deux moitiés de deux couleurs, séparées par une ligne bien nette : simple et efficace, comme un ballon."},
  {name:"Vagues",        rar:0, desc:"Des bandes en vagues bien rondes qui font le tour de la bille, l'une au-dessus de l'autre."},
  {name:"Zigzag",        rar:0, desc:"Des bandes en dents de scie, comme sur un pull d'hiver ou une couronne de papier."},
  {name:"Tricot",        rar:1, desc:"Des mailles de laine tricotées serré, rang par rang, comme un bonnet de mamie."},
  {name:"Nuages",        rar:1, desc:"Un ciel où passent de gros nuages blancs tout ronds : un après-midi de récré au soleil."},
  {name:"Mouchetée",     rar:1, desc:"Un fond clair couvert de petites taches, comme un œuf de caille."},
  {name:"Jean",          rar:2, desc:"La toile de jean, avec sa trame en diagonale un peu délavée et une double couture au fil doré."},
  {name:"Ambre",         rar:3, face:true, desc:"Une résine limpide où une feuille fossile est prise depuis des millions d'années, avec de petites bulles d'air."},
  {name:"Circuit",       rar:1, desc:"Une carte électronique : ses pistes s'allument et la lumière y court d'un point à l'autre."},
  {name:"Feu d'artifice", rar:4, desc:"Des bouquets de lumière qui éclatent dans un verre de nuit, chacun de sa couleur."},
  {name:"Œil du Dragon", rar:5, face:true, myth:true, desc:"Le motif mythique : un œil de dragon te regarde depuis le fond du verre. Son iris brûle, sa pupille fendue s'ouvre et se resserre, il cligne… Sa peau, son iris et le feu de sa pupille prennent les 3 couleurs du coloris."},   // (11 octobre 2026) remplace le Vortex, même numéro 64
];
const FAM_W = FAMILIES.map(f=>f.event || f.season!=null || f.beta ? 0 : DECOR_RAR[f.rar].w);
// motifs hors album : ceux des événements et ceux des saisons
const extraFam = f => !!(FAMILIES[f]?.event || FAMILIES[f]?.season!=null || FAMILIES[f]?.beta);
// les motifs de l'album (sans ceux des événements)
const DECOR_IDS = FAMILIES.map((_,i)=>i).filter(i=>!extraFam(i)), N_DECORS = DECOR_IDS.length;
const SEASON_FAMS = FAMILIES.map((_,i)=>i).filter(i=>FAMILIES[i].season!=null);
const EVENT_FAMS = FAMILIES.map((_,i)=>i).filter(i=>FAMILIES[i].event);
// les motifs rangés par rareté (Commun, Peu commun, Rare, Épique, Légendaire), puis par nom : l'ordre de l'album
const FAM_ORDER = DECOR_IDS.slice().sort((a,b)=>FAMILIES[a].rar-FAMILIES[b].rar || FAMILIES[a].name.localeCompare(FAMILIES[b].name,"fr"));
// La rareté d'une bille, c'est sa taille (les motifs ont seulement des fréquences différentes)
const RARITY = Object.keys(TYPES).map(t=>({name:TYPES[t].label, c:TYPES[t].rc}));
const FMT_TIER = {mini:0, bille:1, chinoise:2, calot:3, boulet:4, mammouth:5};
const BIG = FMT_TIER.boulet;   // "un gros" : Boulet ou Mammouth
const tierOf = s => FMT_TIER[s.type];
const SHINY_COLS = ["#FF6FB5","#FFB547","#6FE3A8","#5AB8FF","#B07BFF"];
const OPAQUE_FAMS = [3,7,8,9,10,12,14,17,18,19,20,21,22,23,24,25,26,27,28,29,33,52,53,54,55,56,57,58,59,60,62];   // les motifs de saison sont tous en verre ; le Pirate aussi depuis le 3 octobre 2026   // les motifs de saison sont tous en verre
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
const SEASON_PAL0 = PALETTES.length;   // 48 : les coloris de saison commencent ici (puis secrètes, événements, bêta)
// Une saison par mois (0 = janvier) : un motif en édition limitée et son coloris, seulement dans le passe (fam : un motif de saison)
const SEASONS = [
  {name:"Givre",            fam:35, pal:["Givre","#3F6FB8","#DCEBFF","#FFFFFF","#EEF5FF"]},
  {name:"Carnaval",         fam:36, pal:["Carnaval","#B8266E","#FFC93F","#3BC4B8","#FFE8F3"]},
  {name:"Printemps",        fam:37, pal:["Printemps","#2F7D3B","#FF9EC4","#FFF2A8","#EAF8E6"]},
  {name:"Poisson d'avril",  fam:38, pal:["Poisson","#1770B0","#FF7A59","#FFE066","#E3F4FF"]},
  {name:"Papillons",        fam:39, pal:["Papillon","#4B3A9E","#FF9F43","#62C8F0","#F3EEFF"]},
  {name:"Plein soleil",     fam:40, pal:["Soleil","#C2410C","#FFC93F","#FFF3BF","#FFF4DC"]},
  {name:"Grandes vacances", fam:41, pal:["Plage","#0B7285","#F2D39B","#FFFFFF","#E0F7F7"]},
  {name:"Étoiles filantes", fam:42, pal:["Nuit d'été","#1B1F4B","#7B6CF6","#FFE08A","#DCDDF7"]},
  {name:"Rentrée",          fam:43, pal:["Rentrée","#1F3A8A","#E8413C","#FFD34E","#E4EAF7"]},
  {name:"Citrouille",       fam:44, pal:["Citrouille","#3A1F4A","#F07C1B","#9BE15D","#FBE6D4"]},
  {name:"Feuilles mortes",  fam:45, pal:["Automne","#6B3A1E","#D9822B","#F2D16B","#F4ECE1"]},
  {name:"Flocon",           fam:46, pal:["Flocon","#9E1030","#FFFFFF","#2F8F45","#FBEAEA"]},
];
SEASONS.forEach(s=>PALETTES.push(s.pal));
const isSeason = s => s.pal>=SEASON_PAL0 && s.pal<SEASON_PAL0+SEASONS.length;
// Billes secrètes : une seule par joueur, cachées un peu partout dans Tikalo
const SECRETS = {
  folle:   {name:"La Folle", type:"calot", family:1, shiny:1, pal:["Folle","#FF2E88","#2EE6FF","#FFE600","#FFE3F2"],
            hint:"La bille du logo n'aime pas qu'on la chatouille… sauf si on insiste vraiment beaucoup."},
  arcade:  {name:"L'Arcade", type:"boulet", family:25, shiny:3, pal:["Arcade","#1A0B3D","#39FF14","#FF00E6","#E0D6FF"],
            hint:"↑ ↑ ↓ ↓ … les vrais joueurs de console connaissent la suite."},
  grenier: {name:"Le Trésor du grenier", type:"mammouth", family:8, shiny:2, pal:["Grenier","#6B4A1E","#E8C27A","#FFF1C9","#F6E7C8"],
            hint:"Les trésors sortent du grenier quand tout le monde dort."},
  gouter:  {name:"La Bille du goûter", type:"calot", family:20, shiny:0, pal:["Goûter","#5A2E14","#F2E6D0","#E94B3C","#F5E6D8"],
            hint:"Pile à la sortie de l'école, quand on a un petit creux…"},
  preau:   {name:"La Secouée", type:"boulet", family:16, shiny:0, pal:["Préau","#2F3A4A","#8FA3BF","#F2F5FA","#E4E9F0"],
            hint:"Certains sachets se méritent : il faut vraiment, vraiment bien les secouer."},
};
Object.values(SECRETS).forEach(X=>{ X.palIdx = PALETTES.length; PALETTES.push(X.pal) });
// Événements : un motif à part et ses coloris à lui, qu'on ne trouve que pendant l'événement
const EVENTS = {
  // dates à l'heure de Paris (mêmes dates dans supabase/serveur.sql : interne.evenement)
  // le Pirate prolongé exceptionnellement jusqu'au 31 octobre (10 octobre 2026, ouverture du jeu) ; les suivants restent sur deux semaines
  pirates: {name:"À l'abordage !", fam:"Pirate", color:"#C8322F",
    start:Date.parse("2026-09-30T00:00:00+02:00"), end:Date.parse("2026-10-31T23:59:59+01:00"),
    desc:"Des billes Pirate jusqu'au 31 octobre : coche la case sur un sachet payant.",
    pals:[["Pavillon noir","#15151B","#D4A537","#F1E9D2","#2A2A30"],
          ["Corsaire","#1B2C5A","#C8322F","#F4EEDC","#22335E"],
          ["Coffre au trésor","#4A2A12","#F2C230","#FFF4D6","#5A3A1E"],
          ["Caraïbes","#0E6E78","#E9D8A6","#FFFFFF","#1A7A84"],
          ["Rhum ambré","#7A3B0C","#1D1410","#F6E3C0","#8A4A18"]]},
  // novembre 2026 : un héros par coloris (des héros de la cour, inventés pour Tikalo). late : coloris rangés après ceux des joueurs (79 à 83)
  superheros: {name:"Super-héros !", fam:"Super-héros", color:"#2E5BFF", late:true,
    start:Date.parse("2026-11-01T00:00:00+01:00"), end:Date.parse("2026-11-15T23:59:59+01:00"),   // (16 octobre 2026) les événements suivent les demi-mois : 1-15 ou 16-fin
    desc:"Deux semaines de billes Super-héros : coche la case sur un sachet payant.",
    pals:[["Capitaine Éclair","#1E4FD8","#E5303A","#FFD23F","#1A3FA8"],
          ["Fulgura","#1A1A22","#FFD23F","#E5303A","#24242C"],
          ["Ombre violette","#2B1450","#8E3FE0","#F1ECFF","#341A5E"],
          ["Titan vert","#0E5E35","#7B2FC0","#9BF26A","#14703F"],
          ["Flamme écarlate","#B5121B","#FF8A1F","#FFF0B0","#C21E24"]]},
};
Object.values(EVENTS).filter(E=>!E.late).forEach(E=>{ E.palIdx = E.pals.map(P=>{ PALETTES.push(P); return PALETTES.length-1 }) });
// La bille Bêta : un cadeau pour ceux qui testent Tikalo avant sa sortie, une de chaque taille, gardée à la remise à zéro du lancement.
// Le serveur la range avec les billes secrètes (secret « beta ») : elle ne s'échange pas, ne se vend pas et ne compte pas au classement.
// Au lancement : open:false ici et interne.beta_ouverte() à false dans supabase/serveur.sql.
// Un verre précieux par taille (Mini → Mammouth), toujours avec le β d'or : coloris 70 à 75, dans l'ordre des tailles (même règle dans serveur.sql).
// (16 octobre 2026) la bêta se ferme toute seule le 1er novembre 2026 à 0 h (Paris) : plus rien à faire le jour J (serveur : interne.beta_ouverte)
const BETA = {fam:47, end:Date.parse("2026-11-01T00:00:00+01:00"), get open(){ return Date.now() < this.end }, ed:"Bêta 2026", pals:[
  ["Rubis","#5E0B1A","#D7263D","#FFC94A","#FFE3E6"],
  ["Émeraude","#06402B","#1FA463","#FFC94A","#DDF7EA"],
  ["Saphir","#0A1F5C","#2F6BEA","#FFC94A","#DFE8FF"],
  ["Améthyste","#2E0E52","#8C3FD9","#FFC94A","#EFE2FF"],
  ["Onyx","#0B0B10","#3A3A48","#FFC94A","#E6E6EC"],
  ["Diamant","#A9D2F0","#F7FCFF","#FFC94A","#FFFFFF"],
].map(P=>PALETTES.push(P)-1)};
BETA.palOf = t => BETA.pals[TK.indexOf(t)];
// Les coloris inventés par les joueurs (2 octobre 2026) : Zède et uwu, puis Poups (3 octobre). Ce sont des coloris normaux (sachets, album, cases),
// mais leurs numéros viennent après tous les autres (76, 77…) : un numéro de coloris ne change jamais, il est enregistré dans chaque bille.
// Même liste dans supabase/serveur.sql (interne.coloris_tirables).
const PLAYER_PALS = [
  ["Zède","#156115","#1DD10D","#000000","#DFF8D8"],
  ["uwu","#C10BA9","#FFFFFF","#F99AEC","#FFFFFF"],
  ["Poups","#FFFFFF","#E48B25","#000000","#CCCCCC"],   // 3 octobre 2026 : base blanche ; 7 octobre : vedette orange et détails noirs (l'orange ne se voyait pas sur la plupart des motifs)
].map(P=>PALETTES.push(P)-1);
// les coloris des événements arrivés après les coloris des joueurs (Super-héros : 79 à 83, mêmes numéros dans supabase/serveur.sql)
Object.values(EVENTS).filter(E=>E.late).forEach(E=>{ E.palIdx = E.pals.map(P=>{ PALETTES.push(P); return PALETTES.length-1 }) });
// (8 octobre 2026) la bille de départ : un Calot choisi au premier lancement, dans l'un des 3 coloris réservés (84 à 86, mêmes numéros dans
// supabase/serveur.sql, bille_gagnee 'depart'). Rangée avec les secrètes (secret « depart ») : ni troc, ni marché, ni Confiserie, ni fusion,
// et ces coloris ne comptent pas dans l'album (personne n'est bloqué parce qu'il n'a pas les 3).
const DEPART = [
  {k:"cartable", name:"Cartable", fam:0, txt:"Rouge vif, comme le premier jour d'école.", pal:["Cartable","#7A1020","#E0352B","#FFD9A0","#FFE3E3"]},
  {k:"craie",    name:"Craie",    fam:1, txt:"Bleu nuit, comme le tableau de la classe.", pal:["Craie","#13204A","#2E4FA8","#F4F4EE","#DDE6FF"]},
  {k:"pelouse",  name:"Pelouse",  fam:3, txt:"Vert pelouse, veiné comme une agate.",       pal:["Pelouse","#1F5A2A","#4FB04A","#F2E3A8","#DFF7E9"]},
];
DEPART.forEach(D=>{ D.palIdx = PALETTES.push(D.pal)-1 });
// (16 octobre 2026) le 52e coloris normal, BCKC : bleu marine, bleu vif en vedette, détails turquoise (maquettes/maquette-nouveau-coloris.html).
// Numéro 87, après tous les autres (un numéro de coloris ne change jamais). Même liste dans supabase/serveur.sql (interne.coloris_tirables)
const PLAYER_PALS_2 = [
  ["BCKC","#00294B","#0090DD","#6FCBDB","#B8E6F0"],
].map(P=>PALETTES.push(P)-1);
const isDepart = s => s?.secret==="depart";
const departSpec = D => ({seed:hash("depart-"+D.k), type:"calot", family:D.fam, pal:D.palIdx, shiny:0});
// les coloris qu'on peut tirer : les 48 d'origine et ceux des joueurs
const BASE_PAL_IDS = [...Array(SEASON_PAL0).keys(), ...PLAYER_PALS, ...PLAYER_PALS_2], BASE_PALS = BASE_PAL_IDS.length, BASE_SET = new Set(BASE_PAL_IDS);
const isBasePal = p => BASE_SET.has(p);
const randPal = r => BASE_PAL_IDS[Math.floor(r*BASE_PALS)];
const isBeta = s => s?.secret==="beta";
const eventOf = s => FAMILIES[s.family]?.event ? EVENTS[FAMILIES[s.family].event] : null;
const eventLive = E => !!E && Date.now()>=E.start && Date.now()<=E.end;
// Billes d'événement (3 octobre 2026) : plus de sachet d'événement en vente. Pendant l'événement, le joueur coche (ou non)
// « billes d'événement » sur les sachets Classique, Premium et Collector : case cochée, chaque bille a 25 % de chances (50 % jusqu'au 11 octobre 2026) d'être une
// bille de l'événement et la vedette (la 5e) l'est toujours ; case décochée, aucune. Le choix est retenu (S.evOpt).
// Mêmes valeurs dans serveur.sql (taux_evenement, ouvrir_sac).
const EV_DROP = {classique:.25, premium:.25, collector:.25};   // (11 octobre 2026) 50 % → 25 % par bille (la collection se finissait trop vite) ; la dernière du sachet reste toujours une bille d'événement
const evOptOn = bagId => !!(S.evOpt && EV_DROP[bagId] && liveEventKey());
// un événement pas encore commencé reste une surprise (Billepedia, album, Confiserie) : seule l'accueil l'annonce, billes floutées, 7 jours avant
const evSoon = E => Date.now() < E.start;
const liveEventKey = () => Object.keys(EVENTS).find(k=>eventLive(EVENTS[k]));
const liveEvents = () => Object.keys(EVENTS).filter(k=>eventLive(EVENTS[k]));
function eventLeft(E){ const ms=Math.max(0,E.end-Date.now()), d=Math.floor(ms/864e5), h=Math.floor(ms/36e5)%24; return d ? `${d} j ${h} h` : `${h} h ${Math.floor(ms/6e4)%60} min` }
const dayMonth = t => new Date(t).toLocaleDateString("fr-FR",{day:"numeric",month:"long"});
// « jusqu'au 14 octobre à 23 h 59 » (heure de Paris)
const untilLabel = t => { const [h,m] = new Date(t).toLocaleTimeString("fr-FR",{hour:"2-digit",minute:"2-digit",timeZone:"Europe/Paris"}).split(":"); return `jusqu'au ${dayMonth(t)} à ${+h} h ${m}` };
const SHINIES = [null,
  {name:"Irisée",    w:75, desc:"Reflets arc-en-ciel à la surface."},
  {name:"Dorée",     w:21, desc:"Des paillettes d'or qui scintillent à la lumière."},
  {name:"Lumineuse", w:4,  desc:"Elle brille, même dans le noir."},
];
// tirage pondéré : r dans [0,1[, w = poids
function pickW(r,w){ const tot=w.reduce((a,b)=>a+b,0); let x=r*tot; for(let i=0;i<w.length;i++){ x-=w[i]; if(x<0) return i } return w.length-1 }
const rollShiny = () => 1+pickW(Math.random(), SHINIES.slice(1).map(x=>x.w));
// 1 sur 2 000 par bille dans le sachet gratuit (et pour les fusions) ; 0,1 % dans le Classique, 0,2 % dans le Premium et les sachets Pirate,
// 0,5 % dans le Collector : une shiny coûte ~60 000 bonbecs dans chaque sachet payant (2 octobre 2026). Une shiny de temps en temps,
// la Dorée reste rare et la Lumineuse le vrai graal. Mêmes valeurs dans serveur.sql (taux_shiny, interne.sac, tirer_shiny).
const SHINY_RATE = .0005;

// Recyclage : ce que rapporte une bille échangée. Proportionnel à sa rareté dans le sachet gratuit
// (chaque taille rapporte donc autant en moyenne), et toujours bien moins que ce qu'elle coûte à trouver.
const RECYCLE = {mini:1, bille:2, chinoise:4, calot:8, boulet:20, mammouth:50};   // 6 octobre 2026 : chaque taille vaut environ le double de la précédente (un Classique revendu rend ~54 % de son prix)
// une shiny (tirée dans un sachet ou une fusion) vaut 10 fois sa taille, plus une prime selon son éclat ; celles du passe, non
const SHINY_RECYCLE_MULT = 10, SHINY_BONUS = [0, 200, 500, 1500];
// (10 octobre 2026) selon la rareté du motif : épique ×2, légendaire ×5, mythique ×20 (même chose dans supabase/serveur.sql, echanger_billes)
const DECOR_RECYCLE_MULT = [1, 1, 1, 2, 5, 20];
// avec un compte, seules les billes tirées par le serveur rapportent (pas les billes de départ ni celles d'une partie sans compte)
const recycleValue = s => srvOn() && !s.srv ? 0 : (s.shiny && !isSeason(s) ? RECYCLE[s.type]*SHINY_RECYCLE_MULT + SHINY_BONUS[s.shiny] : RECYCLE[s.type]) * (DECOR_RECYCLE_MULT[decorRar(s)] || 1);

// Quêtes du jour : (8 octobre 2026) les 4 mêmes chaque jour, dans cet ordre (avant : 4 tirées au hasard parmi 19, trop faciles).
// Les récompenses sont aussi dans supabase/serveur.sql (public.gagner, source 'quete') : à garder pareilles.
// on : les évènements qui la font avancer (questEvent) ; set : sa progression est recalculée (questSet)
const QUESTS_N = 4;
const QUESTS = {
  sachets20: {title:"Ouvre 20 sachets", goal:20, reward:15, icon:"bag", desc:"Gratuits ou payants, tous les sachets comptent.", go:"sacs", on:["open_bag"]},
  jeux6:     {title:"Joue à 6 jeux différents de la cour", goal:6, reward:15, icon:"play", desc:"Ta partie offerte du jour, au Tir, à la Marelle, au Château, à la Tic, à la Roue, au Plinko, au Ticket ou au Distributeur.", go:"jeux", set:true},
  boulets3:  {title:"Trouve 3 Boulets", goal:3, reward:15, icon:"layers", desc:"Dans n'importe quel sachet. Un Mammouth compte aussi.", go:"sacs", on:["find_boulet"]},
  confiserie:{title:"Fais une fusion ou échange une bille", goal:1, reward:5, icon:"candy", desc:"À la Confiserie : une fusion, ou une bille échangée contre des bonbecs.", go:"confiserie|fusion", on:["craft","recycle"]},
};
// go : la page où se fait la quête (« vue|onglet » pour la Confiserie) ; un clic sur la quête y emmène
const questGo = q => { const [v,tab] = (QUESTS[q.id].go||"quetes").split("|"); return `data-action="nav" data-view="${v}"${tab?` data-conftab="${tab}"`:""}` };
const QUEST_BONUS = "premium";   // les 4 quêtes du jour récupérées : un Sachet Premium offert (même chose dans serveur.sql)
const bonusTag = () => `${ic("bag",16)} ${BAG_BY[QUEST_BONUS].name}`;

// Chances de taille position par position (#1, #2… dans l'ordre d'ouverture) : elles montent au fil du sachet, la dernière bille est
// la vedette. Plus le sachet est cher, plus le plancher est haut (pas de Mini dans le Premium, rien sous la Chinoise dans le Collector).
// Mêmes valeurs dans supabase/serveur.sql (interne.sac).
const sizeOdds = a => Object.fromEntries(TK.map((k,i)=>[k,a[i]]));
const FREE_BAG = {id:"gratuit", name:"Sachet gratuit", desc:"3 billes offertes. Un nouveau sachet toutes les 10 minutes, jusqu'à 10 en stock.", price:0, n:3, color:"#C98E4E", tint:"#F6E3C8", shiny:SHINY_RATE,
  slots:[sizeOdds([75,25,0,0,0,0]),sizeOdds([55,35,10,0,0,0]),sizeOdds([30,33,20,12,4,1])]};
const BAGS = [FREE_BAG,
  {id:"classique", name:"Sachet Classique", desc:"5 billes, avec de meilleures chances que le sachet gratuit. 2 fois plus de chances de shiny.", price:30, n:5, color:"#2A8A74", tint:"#D5EFE7", shiny:SHINY_RATE*2,
   slots:[sizeOdds([70,30,0,0,0,0]),sizeOdds([50,38,12,0,0,0]),sizeOdds([35,40,20,5,0,0]),sizeOdds([20,35,30,13,2,0]),sizeOdds([10,25,30,20,12,3])]},
  {id:"premium", name:"Sachet Premium", desc:"5 billes, dont au moins un Calot ou mieux. 4 fois plus de chances de shiny.", price:60, n:5, guarantee:"calot", color:"#34469C", tint:"#DCE0F6", shiny:SHINY_RATE*4,
   slots:[sizeOdds([0,80,20,0,0,0]),sizeOdds([0,60,35,5,0,0]),sizeOdds([0,40,45,15,0,0]),sizeOdds([0,0,55,38,7,0]),sizeOdds([0,0,0,60,34,6])]},
  {id:"collector", name:"Sachet Collector", desc:"5 billes, dont au moins un Boulet ou plus gros. 10 fois plus de chances de shiny.", price:150, n:5, guarantee:"boulet", color:"#D9A020", tint:"#FBEBC0", shiny:SHINY_RATE*10,
   slots:[sizeOdds([0,0,85,15,0,0]),sizeOdds([0,0,65,35,0,0]),sizeOdds([0,0,40,50,10,0]),sizeOdds([0,0,0,60,38,2]),sizeOdds([0,0,0,0,87,13])]},
];
// par bille en moyenne (pour les chances d'une bille précise), et « au moins une » de chaque taille dans un sachet
BAGS.forEach(b=>{
  b.star = b.slots[b.n-1];
  b.odds = Object.fromEntries(TK.map(k=>[k, +(b.slots.reduce((a,o)=>a+o[k],0)/b.n).toFixed(2)]));
  b.perBag = Object.fromEntries(TK.map(k=>[k, 100*(1-b.slots.reduce((a,o)=>a*(1-o[k]/100),1))]));
});
const BAG_BY = Object.fromEntries(BAGS.map(b=>[b.id,b]));
// les sachets offerts d'un type qui n'existe plus (ex. le Sachet Pirate, retiré) : on les oublie, sinon l'accueil ne s'affiche plus
const knownBags = inv => Object.fromEntries(Object.entries(inv||{}).filter(([id])=>BAG_BY[id]));
// l'étagère des sachets : les sachets d'événement n'y sont que pendant l'événement (ou si on en a un offert)
const shelfBags = () => BAGS.filter(b=>!b.event || (S.bagInv[b.id]||0)>0);   // un sachet d'événement : seulement s'il est offert
const eventSpec = b => b.fam!=null ? {family:b.fam, pal:b.pals[Math.floor(Math.random()*b.pals.length)]} : {};


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
    pal: o.pal ?? randPal(r()),
    shiny: o.shiny ?? 0, at: o.at ?? Date.now(), ...(o.src ? {src:o.src} : {})};
}
const specName = s => s.loan ? "Bille prêtée" : s.secret && SECRETS[s.secret] ? SECRETS[s.secret].name : FAMILIES[s.family].season!=null ? FAMILIES[s.family].name : `${FAMILIES[s.family].name} - ${PALETTES[s.pal][0]}`;   // un motif de saison n'existe qu'en un coloris : son nom suffit
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
  if(s.family===2||s.family===30||s.family===34||s.family===42||s.family===44||s.family===47||s.family===49||s.family===50||s.family===51||s.family===63||s.family===64||[81,82,83,85,86,87,112,113].includes(s.family)) tint = hex01(shade(P[1],-.1)).map(v=>Math.max(.08,v*.8));
  const p = {
    seed:[r(),r(),r(),r()],
    par:[(r()-.5)*5, [3,4,4,5,6][Math.floor(r()*5)], .05+r()*.07, 2+Math.floor(r()*4)],
    // les motifs de saison ont un haut et un bas (la neige au sol, le visage de la citrouille) : posés droits, à peine inclinés
    srot: FAMILIES[s.family]?.season!=null || FAMILIES[s.family]?.beta || FAMILIES[s.family]?.event==="superheros" || FAMILIES[s.family]?.face ? rotAxis(1,0,0,-.22) : rotAxis(r()-.5,r()-.5,r()-.5,r()*TAU),
    c1:hex01(P[1]), c2:hex01(P[2]), c3:hex01(P[3]), tint,
    mode:s.family, opaque:opaque?1:0, porc:0, sulf:0, fig:s.family%4, shiny:s.shiny||0, asp:s.type==="chinoise"?1.45:1,
    // (11 octobre 2026) Super-héros : un blason par héros (coloris 79 à 83), chacun son petit programme (#define HERO)
    hero: FAMILIES[s.family]?.event==="superheros" ? Math.max(0, EVENTS.superheros.palIdx.indexOf(s.pal)) : 0,
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

#if MODE==47 || MODE==48
float sdSeg2(vec2 p, vec2 a, vec2 b){ vec2 pa=p-a, ba=b-a; return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0)); }
float sdBeta(vec2 p){   // la lettre β : une hampe et deux panses
  float d=sdSeg2(p,vec2(-0.2,-0.66),vec2(-0.2,0.27));
  if(p.x>-0.2) d=min(d,min(abs(length(p-vec2(-0.02,0.27))-0.18),abs(length(p-vec2(0.01,-0.1))-0.21)));
  return d;
}
#endif
#if MODE==48
#ifndef HERO
#define HERO 0
#endif
float sdEll(vec2 p, vec2 r){ return (length(p/r)-1.0)*min(r.x,r.y); }   // une ellipse (distance approchée, assez bonne pour un dessin)
float sdRBox(vec2 p, vec2 b, float r){ vec2 d=abs(p)-b+r; return length(max(d,0.0))+min(max(d.x,d.y),0.0)-r; }
float sdDrop(vec2 p, float r, float h){   // une goutte pointue vers le haut : un rond de rayon r, une pointe à la hauteur h
  float y=p.y, w=y<0.0 ? sqrt(max(0.0,r*r-y*y)) : r*pow(max(0.0,1.0-y/h),1.3)*(1.0+0.6*y/h);
  return max(max(abs(p.x)-w,-(y+r)),y-h);
}
float sdFlame(vec2 p, float k){   // une flamme : une grande langue au milieu, deux plus petites sur les côtés, penchées vers l'extérieur
  p/=k; vec2 w=vec2(abs(p.x),p.y);
  float d=sdDrop(p-vec2(0.03*sin(p.y*5.0),-0.3),0.36,1.05);
  vec2 s=w-vec2(0.2,-0.4); s=vec2(0.94*s.x-0.34*s.y,0.34*s.x+0.94*s.y);
  d=min(d,sdDrop(s,0.22,0.62));
  return d*k;
}
#endif
#if MODE==22
vec3 tart(float t){ t=fract(t); vec3 cr=vec3(0.97,0.95,0.88);
  return t<0.36?uC1:(t<0.6?uC1*0.3:(t<0.66?uC2:(t<0.69?cr:(t<0.75?uC2:(t<0.9?uC1*0.3:uC3))))); }
#endif
vec2 sph(vec3 u){ return vec2(atan(u.z,u.x)/6.2831853, asin(clamp(u.y,-1.0,1.0))/3.14159); }   // longitude, latitude (0..1)

float sdCap(vec3 p, vec3 a, vec3 b, float r){ vec3 pa=p-a, ba=b-a; return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0))-r; }

#if MODE>=65
// la bille découpée en 6 faces de cube, pour les motifs en grille. xy : la place sur la face (-1..1, à angles égaux :
// les cases gardent presque la même taille jusqu'au bord), w : le numéro de la face
vec4 cubeF(vec3 u){ vec3 a=abs(u); vec2 p; float f;
  if(a.x>=a.y && a.x>=a.z){ p=vec2(u.z,u.y)/a.x; f=u.x>0.0?0.0:1.0; }
  else if(a.y>=a.z){ p=vec2(u.x,u.z)/a.y; f=u.y>0.0?2.0:3.0; }
  else { p=vec2(u.x,u.y)/a.z; f=u.z>0.0?4.0:5.0; }
  return vec4(atan(p)*1.2732395, 0.0, f); }
#endif
#if MODE==76
float cuivreM(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; float n=fbm(u*2.4+so)+0.35*fbm(u*7.0+so+3.0); return smoothstep(0.66,0.72,n); }   // où la patine a pris
#endif
#if MODE==80
// x : un cristal (1) ou le fer (0) ; y : les lamelles gravées dans le fer ; z : la couleur du cristal
vec3 meteo(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; vec3 g=u*3.2+so; vec3 i0=floor(g), f0=fract(g);
  float d1=9.0, d2=9.0; vec3 cid=vec3(0.0);
  for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
    vec3 pt=o+0.15+0.7*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
    if(d<d1){ d2=d1; d1=d; cid=i0+o; } else if(d<d2) d2=d; }
  float cr=smoothstep(0.05,0.09,d2-d1+0.04*(noise(g*4.0)-0.5))*step(0.5,h31(cid+2.0));
  vec3 a1=normalize(vec3(h31(cid),h31(cid+1.0),h31(cid+4.0))-0.5+0.01), a2=normalize(cross(a1,vec3(0.3,1.0,0.2))), a3=normalize(a1+a2*1.3);
  float l=max(max(smoothstep(0.43,0.49,abs(fract(dot(u,a1)*16.0)-0.5)),smoothstep(0.43,0.49,abs(fract(dot(u,a2)*16.0)-0.5))),smoothstep(0.44,0.49,abs(fract(dot(u,a3)*16.0)-0.5)));
  return vec3(cr, l*0.8+0.2*h31(cid+5.0), h31(cid+7.0)); }
#endif
vec4 fam(vec3 q, out vec3 e){
  e=vec3(0.0);
  float r=length(q); vec3 so=uSeed.xyz*40.0;
  float tw=uPar.x, k=uPar.y, w=uPar.z, nb=uPar.w;
#if MODE==0
  { // oeil-de-chat : des pétales de couleur torsadés, pris au cœur du verre clair
    float ang=atan(q.z,q.x)+q.y*tw;
    float d=abs(sin(ang*k*0.5))*length(q.xz);
    float dens=smoothstep(w,w*0.25,d)*smoothstep(0.93,0.78,r);
    return vec4(pal3(floor(ang/6.2831853*k+0.5)), dens*45.0);
  }
#elif MODE==1
  { // tourbillon : de fins filets de couleur qui s'enroulent en spirale juste sous la surface, le cœur reste clair
    vec3 wq=q+0.08*vec3(fbm(q*2.0+so),fbm(q*2.0+so+5.2),fbm(q*2.0+so+9.7))-0.04;
    float n=nb+4.0;
    float ang=atan(wq.z,wq.x)+wq.y*(tw<0.0?-1.0:1.0)*(4.5+abs(tw));
    float s=ang/6.2831853*n;
    float d=abs(fract(s)-0.5)*6.2831853/n*length(wq.xz);
    float dens=smoothstep(w*0.4,w*0.1,d)*smoothstep(0.52,0.7,r)*smoothstep(0.93,0.84,r);
    return vec4(pal3(floor(s)), dens*60.0);
  }
#elif MODE==2
  { // galaxie : une galaxie spirale (cœur brillant, deux bras qui s'enroulent), des nébuleuses et des étoiles dans le verre sombre
    float r=length(q);
    vec3 nrm=normalize(vec3(sin(so.x)*0.7, 2.0, cos(so.y)*0.7));
    vec3 ua=normalize(cross(nrm,vec3(0.0,0.0,1.0))), va=cross(nrm,ua);
    float h=dot(q,nrm); vec3 ip=q-h*nrm; float rr=length(ip);
    float ang=atan(dot(ip,va),dot(ip,ua));
    float arm=0.5+0.5*cos(2.0*(ang-log(rr+0.04)*2.4)+fbm(q*3.0+so)*1.6);
    arm=pow(arm,2.5)*(0.7+0.6*noise(q*9.0+so));
    float thick=0.05+0.12*exp(-rr*4.0);
    float disk=exp(-(h*h)/(thick*thick))*smoothstep(0.92,0.25,rr);
    float core=exp(-dot(q,q)*30.0);
    vec3 c=mix(mix(vec3(1.0,0.93,0.8),uC3,0.5),uC2,smoothstep(0.08,0.55,rr));
    e=c*disk*arm*7.0+mix(vec3(1.0,0.95,0.85),uC3,0.25)*core*9.0;
    float neb=fbm(q*2.2+so*0.5);
    e+=mix(uC1,uC2,0.3)*smoothstep(0.58,0.82,neb)*(1.0-disk)*smoothstep(0.95,0.45,r)*1.1;
    vec3 g=q*16.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.955,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*9.0*(1.0-disk*0.7);
    return vec4(uC1*0.12, 1.1+disk*arm*3.0);
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
  { // pailletée : un verre clair teinté rempli de paillettes de toutes les tailles qui accrochent la lumière
    vec3 g=q*17.0+so; vec3 id=floor(g), fc=fract(g)-0.5;
    vec3 off=vec3(h31(id+1.7),h31(id+5.3),h31(id+9.1))-0.5;
    float sz=0.05+0.11*h31(id+2.2);
    float fl=step(0.42,h31(id))*smoothstep(sz,sz*0.35,length(fc-off*0.55))*smoothstep(0.93,0.82,length(q));
    float k=h31(id+7.7);
    vec3 col=k<0.4?uC3:(k<0.75?mix(uC2,vec3(1.0),0.45):vec3(1.0,0.95,0.82));
    e=col*fl*(6.0+10.0*h31(id+4.4));   // chaque paillette brille plus ou moins, selon comment elle est tournée
    return vec4(mix(uC1,col,fl), 0.45+fl*70.0);   // le verre prend la couleur du coloris
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
  vec3 c=s<0.3?uC1:(s<0.4?cream:(s<0.7?uC2:(s<0.79?cream:(s<0.91?uC3:cream))));
  return vec4(c, 200.0);
  }
#elif MODE==8
  { // terre cuite peinte
    float n=fbm(q*3.0+so);
    vec3 clay=mix(uC1,vec3(0.72,0.55,0.4),0.5)*(0.8+0.35*n)*(0.9+0.2*noise(q*45.0+so));
    float y=q.y+0.07*sin(atan(q.z,q.x)*3.0+so.x);
    float bOut=smoothstep(0.075,0.045,abs(abs(y)-0.36)), bMid=smoothstep(0.06,0.03,abs(y));
    vec3 c=mix(clay,uC3*0.9,bOut*0.9);
    return vec4(mix(c,uC2*0.9,bMid*0.9), 200.0);
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
    c=mix(c,uC3,smoothstep(0.5,0.68,fbm(q*2.2+so+11.0))*0.75);
    return vec4(mix(c,vec3(0.97,0.95,0.93),0.25+0.2*n), 200.0);
  }
#elif MODE==11
  { // cristal à bulles
    vec3 g=q*6.0+so; vec3 id=floor(g); vec3 fc=fract(g)-0.5;
    float hb=h31(id);
    vec3 off=vec3(h31(id+3.1),h31(id+7.7),h31(id+1.9))-0.5;
    float rb=0.07+0.16*h31(id+1.3);
    float d=length(fc-off*0.35);
    float sh=step(0.5,hb)*smoothstep(0.06,0.0,abs(d-rb))*smoothstep(0.92,0.75,r);
    e=mix(vec3(1.0),uC3,0.6)*sh*1.5;
    // le verre prend vraiment la couleur du coloris : sombre au cœur, plus clair vers la paroi
    vec3 col=mix(uC1,mix(uC2,vec3(1.0),0.2),smoothstep(0.1,0.9,r));
    return vec4(mix(col,uC3,sh), 0.42+sh*22.0);
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
  { // ruban : un large ruban blanc torsadé, rayé de fins filets de couleur sur toute sa longueur
    float a=q.y*(tw<0.0?-1.0:1.0)*(2.0+abs(tw)*0.4)+so.x; float ca=cos(a), sa=sin(a);   // toujours bien torsadé
    vec2 p=vec2(ca*q.x-sa*q.z, sa*q.x+ca*q.z);
    float dens=smoothstep(0.09,0.05,abs(p.y))*smoothstep(0.7,0.62,abs(p.x))*smoothstep(0.93,0.84,r);
    float g=(p.x+0.7)*(3.0+nb*1.2), f=abs(fract(g)-0.5);
    vec3 c=mix(vec3(0.97,0.95,0.9), pal3(floor(g)), smoothstep(0.32,0.2,f));
    return vec4(c, dens*120.0);
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
    float m=fbm(q*1.3+so+23.0);
    vec3 vc=mix(mix(uC1,uC2,smoothstep(0.4,0.47,m)),uC3,smoothstep(0.53,0.6,m));
    return vec4(mix(vc*0.75,mix(vc,vec3(0.95),0.45),smoothstep(0.5,0.9,n)), dens*16.0);
  }
#elif MODE==17
  { // lave : roche sombre et fissures incandescentes
    float n=fbm(q*3.0+so);
    float k2=abs(fbm(q*3.6+so*1.3)-0.5);
    float crack=smoothstep(0.045,0.0,k2);
    // (16 octobre 2026) les 3 couleurs du coloris se voient : la roche prend la 1re, le bord des fissures et leur halo la 2e, le cœur brûlant la 3e
    float core=smoothstep(0.018,0.0,k2), halo=smoothstep(0.11,0.0,k2);
    vec3 rock=mix(vec3(0.05,0.045,0.045), uC1*0.5, 0.35+0.45*n);
    vec3 glow=mix(uC2, mix(uC3,vec3(1.0),0.15), core);
    e=glow*crack*2.2 + uC2*halo*(1.0-crack)*0.35;
    return vec4(mix(mix(rock, uC2*0.6, halo*0.35), glow, crack), 200.0);
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
    vec3 fur=mix(uC2,uC3,smoothstep(-0.15,-0.6,q.y+0.15*fbm(q*3.0+so)));
    return vec4(mix(fur, uC1*0.22, smoothstep(0.35,0.55,s)), 200.0);
  }
#elif MODE==21
  { // damier : cases qui s'enroulent comme sur un ballon de plage
    vec3 u=normalize(q); vec2 s=sph(u); float n=4.0+nb;
    vec2 c=floor(vec2((s.x+s.y*tw*0.04)*n*2.0, s.y*n));
    return vec4(mod(c.x+c.y,2.0)<0.5?uC1:(mod(c.y,2.0)<0.5?uC2:uC3), 200.0);   // toujours les mêmes couleurs pour un même coloris
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
    vec3 wood=mix(vec3(0.78,0.56,0.33),pal3(floor(rr)),0.45);
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
    vec3 col=mix(mix(uC1,uC2,hk*0.7),uC3,step(0.72,hk)*0.85)*(0.45+0.75*t);
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
    // (16 octobre 2026) les 3 couleurs du coloris se voient : le verre prend la 1re, les fêlures la 2e ou la 3e selon les zones
    vec3 cc=mix(uC2, uC3, smoothstep(0.42,0.58,noise(q*2.4+so+5.0)));
    e=mix(cc,vec3(1.0),0.3)*crack*2.4;
    return vec4(mix(mix(uC1,vec3(1.0),0.3), cc, crack*0.7), 0.3+crack*30.0);
  }
#elif MODE==32
  { // pirate (en verre depuis le 3 octobre 2026) : un verre fumé de la couleur du coloris ; au cœur, comme une bille sulfure,
    // la tête de mort et ses os croisés, d'un blanc d'os ; une sangle d'or et ses rivets fait le tour juste sous la surface
    float n=fbm(q*4.0+so), r=length(q);
    vec3 glass=mix(uC1, uC2, 0.25)*(0.55+0.3*n);
    float dens=0.45+0.35*n;
    // la sangle d'or, dans l'épaisseur du verre
    float ga=atan(q.y,q.z);
    float strap=smoothstep(0.075,0.055,abs(q.x))*smoothstep(0.7,0.8,r);
    float rivet=smoothstep(0.04,0.02,length(vec2(q.x,(fract(ga*1.9099)-0.5)*0.5)))*smoothstep(0.72,0.82,r);
    // la figure : une plaque mince au milieu de la bille, face à nous quand la bille est de face
    vec2 p=vec2(q.x, q.y)*1.75;
    float head=length(p-vec2(0.0,0.14))-0.4;
    vec2 jb=abs(p-vec2(0.0,-0.24))-vec2(0.2,0.12); float jaw=length(max(jb,0.0))+min(max(jb.x,jb.y),0.0)-0.04;
    float holes=min(min(length(p-vec2(-0.15,0.12)),length(p-vec2(0.15,0.12)))-0.105, length(p-vec2(0.0,-0.07))-0.045);
    float teeth=max(abs(fract(p.x*10.0+0.5)-0.5)*0.1-0.012, abs(p.y+0.26)-0.08);
    float skull=max(min(head,jaw),-min(holes,teeth));
    vec2 a1=vec2(-0.72,-0.72), b1=vec2(0.72,0.72), a2=vec2(-0.72,0.72), b2=vec2(0.72,-0.72);
    vec2 pa=p-a1, ba=b1-a1; float d1=length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0))-0.1;
    pa=p-a2; ba=b2-a2; float d2=length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0))-0.1;
    vec2 k=abs(p); float knob=min(length(k-vec2(0.86,0.64)),length(k-vec2(0.64,0.86)))-0.13;
    float bones=max(min(min(d1,d2),knob), -(head-0.06));
    float emb=min(skull,bones);
    float fig=smoothstep(0.03,-0.02,emb)*smoothstep(0.13,0.06,abs(q.z));
    vec3 bone=uC3*(0.88+0.15*n);
    if(fig>0.01) return vec4(mix(glass, bone, fig), mix(dens, 90.0, fig));
    if(strap+rivet>0.01) return vec4(mix(uC2, vec3(1.0,0.86,0.45), 0.35+0.4*rivet)*(0.85+0.3*n), mix(dens, 60.0, clamp(strap+rivet,0.0,1.0)));
    return vec4(glass, dens);
  }
#elif MODE==33
  { // vitrail : éclats de verre coloré sertis de plomb ; la lumière passe au travers
    vec3 g=normalize(q)*3.3+so; vec3 i=floor(g), f=fract(g);
    float md=8.0, md2=8.0; vec3 mid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){
      vec3 b=vec3(float(x),float(y),float(z));
      vec3 o=vec3(h31(i+b),h31(i+b+11.3),h31(i+b+27.1));
      vec3 rr=b+o-f; float dd=dot(rr,rr);
      if(dd<md){ md2=md; md=dd; mid=i+b; } else if(dd<md2) md2=dd;
    }
    float edge=sqrt(md2)-sqrt(md), hk=h31(mid+3.0);
    vec3 c=hk<0.3?uC1:(hk<0.58?uC2:(hk<0.84?uC3:mix(uC2,vec3(1.0),0.55)));
    c*=0.8+0.35*h31(mid+9.0);
    float grain=0.9+0.1*noise(q*30.0+so);   // le verre soufflé n'est jamais parfaitement lisse
    float lead=smoothstep(0.075,0.035,edge);
    e=c*grain*0.75*(1.0-lead);
    c=mix(c*grain,vec3(0.06,0.06,0.07)+0.08*noise(q*60.0),lead);
    return vec4(c, 200.0);
  }
#elif MODE==34
  { // trou noir : l'horizon (noir absolu), le disque d'accrétion qui tourne autour, quelques étoiles
    float r=length(q);
    vec3 nrm=normalize(vec3(sin(so.x)*0.9, 2.2, cos(so.y)*0.9));
    vec3 ua=normalize(cross(nrm,vec3(0.0,0.0,1.0))), va=cross(nrm,ua);
    float h=dot(q,nrm); vec3 ip=q-h*nrm; float rr=length(ip);
    float ang=atan(dot(ip,va),dot(ip,ua));
    float thick=0.035+0.06*smoothstep(0.35,0.9,rr);
    float disk=smoothstep(thick,0.0,abs(h))*smoothstep(0.3,0.36,rr)*smoothstep(0.93,0.55,rr);
    float sw=0.35+0.65*(0.5+0.5*sin(ang*2.0-rr*16.0+fbm(q*4.0+so)*5.0));
    vec3 hot=mix(vec3(1.0,0.96,0.86),uC3,smoothstep(0.32,0.46,rr));
    hot=mix(hot,uC2,smoothstep(0.46,0.7,rr)); hot=mix(hot,uC1+0.1,smoothstep(0.7,0.92,rr));
    e=hot*disk*sw*14.0;
    // un voile de lumière qui tourne juste au bord de l'horizon, surtout près du disque
    e+=mix(vec3(1.0,0.95,0.85),uC3,0.4)*smoothstep(0.1,0.0,r-0.29)*smoothstep(0.35,0.0,abs(h))*3.0;
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*6.0*step(0.5,r)*(1.0-disk);
    if(r<0.29) return vec4(vec3(0.0), 1000.0);
    return vec4(uC1*0.06, 0.5+disk*6.0);
  }
#elif MODE==35
  { // givre : des fougères de glace ont poussé contre la paroi d'un verre glacé, avec quelques étincelles
    float sh=smoothstep(0.6,0.78,r)*smoothstep(0.97,0.9,r);
    vec3 pp=q*2.6+so; float rg=0.0, a=0.55;
    for(int i=0;i<4;i++){ rg+=a*(1.0-abs(noise(pp)*2.0-1.0)); pp=pp*2.03+1.7; a*=0.5; }
    float fr=smoothstep(0.8,0.9,rg)*sh;
    vec3 sg=normalize(q)*7.0+so; vec3 sf=fract(sg)-0.5;
    e=mix(uC2,vec3(1.0),0.6)*fr*0.6+vec3(step(0.93,h31(floor(sg)))*smoothstep(0.12,0.0,length(sf)))*3.0*sh;
    return vec4(mix(mix(uC1,uC2,0.35),vec3(1.0),fr), fr*40.0+1.1);
  }
#elif MODE==36
  { // confettis : des petits papiers et des serpentins qui flottent dans le verre, comme un soir de carnaval
    vec3 col=mix(uC1,vec3(1.0),0.75); float dens=0.12;
    vec3 g=q*4.6+so; vec3 id=floor(g), f=fract(g)-0.5;
    if(h31(id)>0.4 && r<0.93){
      vec3 o=(vec3(h31(id+1.1),h31(id+2.3),h31(id+3.7))-0.5)*0.45;
      vec3 n=normalize(vec3(h31(id+4.1),h31(id+5.3),h31(id+6.7))-0.5);
      vec3 u=normalize(cross(n,vec3(0.3,1.0,0.2))), v=cross(n,u);
      vec3 d=f-o; float sq=max(max(abs(dot(d,u))-0.15,abs(dot(d,v))-0.09),abs(dot(d,n))-0.035);
      if(sq<0.0){ float hk=h31(id+9.0); col=hk<0.3?uC2:(hk<0.6?uC3:(hk<0.8?vec3(0.97):mix(uC1,vec3(1.0),0.2))); dens=220.0; }
    }
    for(int i=0;i<2;i++){ float fi=float(i);
      float a=atan(q.z,q.x)+fi*3.1416, ph=a/6.2832*0.55-q.y+fi*0.27+so.x*0.05;
      float k=(fract(ph/0.55)-0.5)*0.55, rr=length(q.xz)-0.5+0.12*fi;
      if(length(vec2(rr,k))<0.035 && abs(q.y)<0.72){ col=fi<0.5?uC3:uC2; dens=220.0; }
    }
    return vec4(col,dens);
  }
#elif MODE==37
  { // cerisier : une petite branche en fleurs prise dans le verre, et des pétales qui volent tout autour
    vec3 col=mix(uC3,vec3(1.0),0.6); float dens=0.18;
    vec3 A=vec3(-0.62,-0.52,0.0), B=vec3(0.0,0.02,0.05), C=vec3(0.55,0.32,-0.05), D=vec3(-0.12,0.5,0.08);
    float tw=min(min(sdCap(q,A,B,0.045),sdCap(q,B,C,0.032)),sdCap(q,B+(C-B)*0.3,D,0.026));
    if(tw<0.0) return vec4(vec3(0.3,0.18,0.12)*(0.8+0.3*noise(q*30.0)),300.0);
    for(int i=0;i<9;i++){ float fi=float(i);
      vec3 P=fi<4.0?mix(A,B,0.35+fi*0.2):(fi<7.0?mix(B,C,0.2+(fi-4.0)*0.3):mix(B+(C-B)*0.3,D,0.5+(fi-7.0)*0.45));
      P+=(vec3(h31(vec3(fi,1.0,so.x)),h31(vec3(fi,2.0,so.y)),h31(vec3(fi,3.0,so.z)))-0.5)*0.16;
      vec3 d=q-P; float ang=atan(d.y,d.x)+fi;
      float fl=length(d)-0.085*(0.75+0.25*abs(cos(ang*2.5)));
      if(fl<0.0){ float rr=length(d); return vec4(rr<0.03?vec3(0.98,0.82,0.3):mix(uC2,vec3(1.0),0.15+0.5*smoothstep(0.02,0.085,rr)),260.0); }
    }
    vec3 g=q*7.0+so; vec3 pf=fract(g)-0.5; float pt=step(0.9,h31(floor(g)))*smoothstep(0.1,0.05,length(pf*vec3(1.0,2.2,1.0)));
    if(pt>0.5 && r<0.92){ col=mix(uC2,vec3(1.0),0.3); dens=160.0; }
    return vec4(col,dens);
  }
#elif MODE==38
  { // aquarium : des petits poissons qui tournent dans une eau bleue, et des bulles qui montent
    vec3 col=mix(uC1,vec3(1.0),0.45); float dens=0.25;
    for(int i=0;i<6;i++){
      float fi=float(i);
      float a0=fi*1.047+so.x*0.05, hy=(h31(vec3(fi,2.0,so.y))-0.5)*0.9, rad=0.36+0.22*h31(vec3(fi,5.0,so.z));
      vec3 c0=vec3(cos(a0)*rad,hy,sin(a0)*rad);
      vec3 t=vec3(-sin(a0),0.0,cos(a0)), side=vec3(cos(a0),0.0,sin(a0));
      vec3 d=(q-c0)/(0.75+0.45*h31(vec3(fi,8.0,1.0)));
      float x=dot(d,t), y=d.y, z=dot(d,side);
      float body=length(vec3(x/0.16,y/0.09,z/0.07))-1.0;
      float tail=max(max(abs(y)-(-x-0.12)*0.9, max(x+0.12,-x-0.26)), abs(z)-0.03);
      if(body<0.0 || tail<0.0){
        vec3 fc=h31(vec3(fi,11.0,3.0))<0.5?uC2:uC3;
        fc=mix(fc,vec3(1.0),smoothstep(0.025,0.0,abs(x+0.01))*step(body,0.0)*0.85);
        fc=mix(fc,vec3(0.03),smoothstep(0.03,0.018,length(vec2(x-0.09,y-0.02))));
        col=fc; dens=150.0;
      }
    }
    vec3 g=q*6.0+so; vec3 bf=fract(g)-0.5; float bl=length(bf);
    float bub=step(0.88,h31(floor(g)))*smoothstep(0.13,0.1,bl)*smoothstep(0.05,0.1,bl);
    e=vec3(0.9,0.97,1.0)*bub*1.6;
    return vec4(col,dens+bub*25.0);
  }
#elif MODE==39
  { // papillons : des papillons aux ailes colorées qui volent dans un verre clair de printemps
    vec3 col=mix(uC3,vec3(1.0),0.7); float dens=0.14;
    for(int i=0;i<5;i++){ float fi=float(i);
      vec3 c=(vec3(h31(vec3(fi,1.0,so.x)),h31(vec3(fi,2.0,so.y)),h31(vec3(fi,3.0,so.z)))-0.5)*vec3(1.0,1.1,0.8);
      if(length(c)>0.55) c*=0.55/length(c);
      float sz=0.2+0.07*h31(vec3(fi,4.0,1.0));
      // chaque papillon regarde à peu près vers nous, un peu penché, les ailes un peu repliées
      float a=(h31(vec3(fi,5.0,2.0))-0.5)*1.4, fold=0.12+0.18*h31(vec3(fi,6.0,3.0));
      vec3 d=(q-c)/sz;
      d.xy=mat2(cos(a),-sin(a),sin(a),cos(a))*d.xy;
      float side=sign(d.x); vec2 w=vec2(abs(d.x),d.y);
      float zz=d.z-w.x*fold;   // les deux ailes se relèvent un peu, en V
      if(abs(zz)>0.3) continue;
      // le corps
      if(length(vec2(d.x*3.2,d.y*0.8))<0.38 && abs(d.z)<0.3) return vec4(vec3(0.12,0.1,0.14),300.0);
      // l'aile du haut (grande) et celle du bas (petite)
      float up=length((w-vec2(0.48,0.32))/vec2(0.52,0.42))-1.0;
      float lo=length((w-vec2(0.36,-0.32))/vec2(0.36,0.3))-1.0;
      float wing=min(up,lo);
      if(wing<0.0){
        float hk=h31(vec3(fi,7.0,4.0));
        vec3 wc=hk<0.34?uC2:(hk<0.67?uC3:mix(uC1,vec3(1.0),0.25));
        wc=mix(wc,wc*1.15+0.1,smoothstep(-0.6,0.0,-length(w-vec2(0.15,0.0))));
        float spot=length(w-(up<lo?vec2(0.62,0.42):vec2(0.42,-0.36)))-0.11;
        wc=mix(wc,vec3(0.98),smoothstep(0.02,-0.02,spot));
        wc=mix(wc,vec3(0.1,0.08,0.12),smoothstep(-0.1,-0.02,wing));   // le bord sombre des ailes
        return vec4(wc,300.0);
      }
    }
    // quelques grains de pollen qui brillent
    vec3 g=q*10.0+so; vec3 fc=fract(g)-0.5; float sp=step(0.95,h31(floor(g)))*smoothstep(0.12,0.05,length(fc));
    e=vec3(1.0,0.95,0.7)*sp*0.8;
    return vec4(col,dens+sp*30.0);
  }
#elif MODE==40
  { // soleil : une boule de feu au cœur du verre, et ses rayons qui partent tout droit
    if(r<0.27){ float gr=fbm(q*9.0+so); e=mix(uC2,vec3(1.0,0.97,0.85),0.55+0.3*gr)*5.0; return vec4(mix(uC2,vec3(1.0),0.5),400.0); }
    float an=atan(q.y,q.x)+0.06*sin(r*12.0+so.x);
    float rays=pow(0.5+0.5*cos(an*12.0),8.0)*smoothstep(0.27,0.33,r)*smoothstep(0.9,0.45,r)*smoothstep(0.35,0.0,abs(q.z));
    float glow=exp(-(r-0.27)*5.0);
    e=mix(uC2,vec3(1.0,0.95,0.75),0.4)*glow*1.4+mix(uC2,uC1,smoothstep(0.3,0.85,r))*rays*5.0;
    return vec4(mix(uC2,uC1,0.4), 0.25+rays*8.0);
  }
#elif MODE==41
  { // plage : le sable au fond, la mer et ses vagues, un parasol rayé et une étoile de mer, comme dans une boule à neige
    float sand=-0.42+0.04*fbm(q*4.0+so);
    if(q.y<sand) return vec4(uC2*(0.82+0.25*noise(q*50.0+so)),300.0);
    vec2 st=vec2(q.x-0.24,q.z-0.12); float star=sdStar(st*9.0)/9.0;
    if(star<0.0 && q.y<sand+0.04) return vec4(vec3(0.95,0.45,0.25),300.0);
    // le parasol
    vec3 P0=vec3(-0.28,sand,-0.05), P1=vec3(-0.28,0.3,-0.05);
    if(sdCap(q,P0,P1,0.016)<0.0) return vec4(vec3(0.95),300.0);
    vec3 pc=q-P1; float rr=length(pc.xz);
    if(pc.y<0.0 && pc.y>-0.13*(1.0-rr/0.32) && rr<0.32 && pc.y>-0.16){
      float ang=atan(pc.z,pc.x); return vec4(fract(ang/6.2832*8.0)<0.5?vec3(0.92,0.22,0.2):vec3(0.98),300.0); }
    // la mer : une eau bleue avec une ligne d'écume
    float wave=-0.05+0.035*sin(q.x*9.0+so.y)+0.02*sin(q.z*13.0);
    if(q.y<wave){ float foam=smoothstep(0.03,0.0,wave-q.y); return vec4(mix(mix(uC1,vec3(0.3,0.85,0.9),0.4),vec3(1.0),foam),2.2+foam*80.0); }
    // le soleil dans le ciel
    if(length(q-vec3(0.35,0.5,-0.25))<0.12){ e=vec3(1.0,0.85,0.35)*2.5; return vec4(vec3(1.0,0.85,0.35),300.0); }
    return vec4(vec3(0.75,0.9,1.0), 0.15);
  }
#elif MODE==42
  { // étoiles filantes : des traînées de lumière qui filent dans un ciel de nuit d'été
    for(int i=0;i<5;i++){
      float fi=float(i);
      vec3 h=normalize(vec3(h31(vec3(fi,1.0,so.x)),h31(vec3(fi,2.0,so.y)),h31(vec3(fi,3.0,so.z)))-0.5)*(0.3+0.45*h31(vec3(fi,4.0,1.0)));
      vec3 v=normalize(cross(h,vec3(0.2,1.0,0.1)+vec3(fi*0.1)));
      vec3 pa=q-h; float t=clamp(dot(pa,-v)/0.8,0.0,1.0); float d=length(pa+v*0.8*t);
      float tr=smoothstep(0.05*(1.0-t)+0.006,0.0,d)*(1.0-t);
      e+=mix(vec3(1.0,0.98,0.9),fi<2.0?uC3:uC2,t)*tr*26.0+vec3(1.0)*smoothstep(0.06,0.0,length(pa))*16.0;
    }
    vec3 g=q*14.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.96,h31(floor(g)))*smoothstep(0.18,0.0,length(fc)))*6.0;
    e+=uC2*smoothstep(0.6,0.85,fbm(q*2.0+so*0.5))*0.6*smoothstep(0.95,0.4,r);
    return vec4(uC1*0.15, 1.0);
  }
#elif MODE==43
  { // crayons de couleur : de petits crayons taillés qui flottent dans le verre de la rentrée
    vec3 col=mix(uC1,vec3(1.0),0.75); float dens=0.18;
    for(int i=0;i<6;i++){ float fi=float(i);
      vec3 c=(vec3(h31(vec3(fi,1.0,so.x)),h31(vec3(fi,2.0,so.y)),h31(vec3(fi,3.0,so.z)))-0.5)*0.9;
      vec3 a=normalize(vec3(h31(vec3(fi,4.0,1.0)),h31(vec3(fi,5.0,1.0)),h31(vec3(fi,6.0,1.0)))-0.5);
      vec3 d=q-c; float t=dot(d,a), rad=length(d-a*t);
      float hk=h31(vec3(fi,7.0,2.0));
      vec3 body=hk<0.2?uC1:(hk<0.4?uC2:(hk<0.6?uC3:(hk<0.8?vec3(0.2,0.65,0.3):vec3(0.95,0.5,0.15))));
      if(t>-0.28 && t<0.16 && rad<0.05) return vec4(body*(0.85+0.2*step(0.0,sin(atan(dot(d,cross(a,vec3(0.0,1.0,0.0))),1.0)*6.0))),300.0);
      if(t>=0.16 && t<0.3 && rad<0.05*(0.3-t)/0.14) return vec4(t>0.26?body*0.7:vec3(0.92,0.78,0.58),300.0);
      if(t>-0.34 && t<=-0.28 && rad<0.05) return vec4(t>-0.31?vec3(0.75,0.75,0.78):vec3(0.95,0.6,0.65),300.0);
    }
    vec3 g=q*11.0+so; vec3 fc=fract(g)-0.5; float sp=step(0.95,h31(floor(g)))*smoothstep(0.12,0.05,length(fc));
    e=vec3(1.0)*sp*0.8;
    return vec4(col,dens+sp*30.0);
  }
#elif MODE==44
  { // citrouille : une petite citrouille-lanterne prise dans un verre de nuit, et des étincelles qui flottent
    vec3 p=q-vec3(0.0,-0.08,0.0); p.y/=0.82;
    float ang=atan(p.z,p.x), R=0.43*(1.0-0.05*(0.5-0.5*cos(ang*8.0)));
    float pr=length(p);
    if(pr<R){
      vec2 fp=vec2(p.z>0.0?p.x:-p.x, p.y)/R*1.05; float face=smoothstep(0.1,0.35,abs(p.z)/R);
      vec2 pe=vec2(abs(fp.x)-0.33,fp.y-0.2);
      float eye=max(-(pe.y+0.1), pe.y+1.6*abs(pe.x)-0.12);
      float nose=max(-(fp.y+0.07), fp.y+0.02+1.5*abs(fp.x)-0.05);
      float yt=-0.2+0.6*fp.x*fp.x, yb=-0.44+0.95*fp.x*fp.x;
      float mouth=max(max(yb-fp.y,fp.y-yt),abs(fp.x)-0.5);
      mouth=max(mouth,-max(abs(fp.x)-0.06,(yt-0.09)-fp.y));
      float holes=min(min(eye,nose),mouth);
      if(holes<0.0 && face>0.5){ e=vec3(1.0,0.7,0.2)*4.0; return vec4(vec3(1.0,0.82,0.35),400.0); }
      float rib=0.5+0.5*cos(ang*8.0);
      return vec4(uC2*(0.55+0.5*pow(rib,0.6))*(0.9+0.15*fbm(p*vec3(3.0,9.0,3.0)+so)),400.0);
    }
    if(sdCap(q,vec3(0.0,0.25,0.0),vec3(0.05,0.42,0.02),0.04)<0.0) return vec4(mix(uC3,vec3(0.35,0.25,0.1),0.5),300.0);
    vec3 g=q*8.0+so; vec3 fc=fract(g)-0.5; float sp=step(0.93,h31(floor(g)))*smoothstep(0.1,0.03,length(fc));
    e=vec3(1.0,0.6,0.15)*sp*3.0;
    return vec4(uC1*0.3, 0.6+sp*20.0);
  }
#elif MODE==45
  { // feuilles mortes : des feuilles d'érable rousses, jaunes et rouges qui tombent en tournoyant dans le verre
    vec3 col=mix(uC3,vec3(1.0),0.7); float dens=0.18;
    vec3 g=q*2.6+so; vec3 id=floor(g), f=fract(g)-0.5;
    if(h31(id)>0.35 && r<0.94){
      vec3 o=(vec3(h31(id+1.1),h31(id+2.3),h31(id+3.7))-0.5)*0.25;
      vec3 n=normalize((vec3(h31(id+4.1),h31(id+5.3),h31(id+6.7))-0.5)*vec3(0.9,0.9,0.5)+vec3(0.0,0.0,0.6));
      vec3 u=normalize(cross(n,vec3(0.3,1.0,0.2))), v=cross(n,u);
      vec3 d=f-o; vec2 p=vec2(dot(d,u),dot(d,v))/0.3; float th=atan(p.x,p.y), rr=length(p);
      float R=(0.55+0.38*abs(cos(th*2.5))+0.07*abs(sin(th*12.5)))*(1.0-0.45*smoothstep(2.3,3.1,abs(th)));
      if(abs(dot(d,n))<0.06 && (rr<R || (abs(p.x)<0.05 && p.y<0.0 && p.y>-0.95))){
        float hk=h31(id+14.0); vec3 lc=hk<0.35?uC2:(hk<0.65?uC3:vec3(0.72,0.16,0.07));
        float vn=min(abs(p.x),min(abs(dot(p,vec2(0.81,-0.59))),abs(dot(p,vec2(0.81,0.59)))));
        return vec4(mix(lc*0.65,lc,smoothstep(0.0,0.05,vn))*(0.85+0.25*noise(q*20.0)),260.0);
      }
    }
    return vec4(col,dens);
  }
#elif MODE==46
  { // boule à neige : un sapin sur un tapis de neige, une étoile au sommet, des flocons qui flottent
    if(q.y+0.48+0.05*fbm(q*4.0+so)<0.0) return vec4(vec3(0.97,0.98,1.0),200.0);
    vec2 tp=vec2(length(q.xz),q.y); float tree=1e3;
    for(int i=0;i<3;i++){ float fi=float(i); float base=-0.42+fi*0.19, h=0.34-fi*0.04, w=0.3-fi*0.07;
      tree=min(tree,max(tp.x-w*(1.0-(tp.y-base)/h),max(base-tp.y,tp.y-base-h))); }
    if(max(tp.x-0.05,max(-0.5-tp.y,tp.y+0.42))<0.0) return vec4(vec3(0.35,0.22,0.12),300.0);
    if(tree<0.0) return vec4(mix(uC3*0.75,vec3(1.0),smoothstep(0.55,0.75,noise(q*18.0+so))*0.7),300.0);
    if(max(sdStar(vec2(q.x,q.y-0.31)*11.0)/11.0,abs(q.z)-0.03)<0.0){ e=vec3(1.0,0.85,0.3)*2.0; return vec4(vec3(1.0,0.85,0.3),300.0); }
    vec3 g=q*9.0+so; vec3 fc=fract(g)-0.5; float fl=step(0.86,h31(floor(g)))*smoothstep(0.1,0.04,length(fc));
    e=vec3(1.0)*fl*1.2;
    return vec4(vec3(1.0), 0.12+fl*60.0);
  }
#elif MODE==48
  { // super-héros (événement de novembre 2026) : un verre teinté de la couleur du héros ; au cœur, comme une bille sulfure,
    // son blason, un par héros (HERO, voir plus bas), cerclé d'un liseré ; derrière, les rayons d'une case de bande dessinée
    float n=fbm(q*4.0+so), r=length(q);
    vec3 glass=mix(uC1, uC2, 0.12)*(0.6+0.3*n);
    float dens=0.26+0.2*n;
    // la bille chinoise se regarde par le dessus : le blason y est couché à plat (comme le β de la Bêta)
    bool couche=uAsp>1.2; vec2 p=(couche?vec2(q.x,-q.z):q.xy)*1.7; float bz=couche?q.y:q.z;
    // (11 octobre 2026) chaque héros a son blason : shield = la silhouette, det = ses détails ; body/detc : leurs couleurs
    float shield, det, glow=0.0; vec3 body=uC2, detc=uC3;
#if HERO==1
    // Fulgura, la plus rapide de la cour : des ailes aux pieds, comme le casque ailé du messager des dieux ; au centre, un éclair
    vec2 w=vec2(abs(p.x),p.y);
    shield=length(p)-0.22;
    for(int i=0;i<3;i++){ float fi=float(i), a=0.3+fi*0.5, L=0.72-fi*0.14;
      shield=min(shield, sdSeg2(w,vec2(0.12,-0.05),vec2(0.12,-0.05)+L*vec2(cos(a),sin(a)))-(0.09-fi*0.012)); }
    float bolt=min(min(sdSeg2(p,vec2(0.07,0.15),vec2(-0.04,0.0)), sdSeg2(p,vec2(-0.04,0.0),vec2(0.05,0.0))), sdSeg2(p,vec2(0.05,0.0),vec2(-0.06,-0.16)))-0.035;
    det=max(length(p)-0.17,-bolt);
    for(int i=0;i<3;i++){ float fi=float(i), a=0.3+fi*0.5;   // le trait de chaque plume
      det=min(det, sdSeg2(w,vec2(0.12,-0.05)+0.3*vec2(cos(a),sin(a)),vec2(0.12,-0.05)+(0.68-fi*0.14)*vec2(cos(a),sin(a)))-0.014); }
#elif HERO==2
    // Ombre violette, justicier de la nuit : le loup (le masque des justiciers masqués) et deux yeux qui brillent dans le noir
    vec2 w=vec2(abs(p.x),p.y);
    vec2 m=w-vec2(0.3,0.02); m=vec2(m.x, m.y+0.22*m.x);   // les deux moitiés du loup, un peu relevées vers l'extérieur
    shield=min(sdEll(m,vec2(0.42,0.27)), sdRBox(p-vec2(0.0,0.06),vec2(0.2,0.14),0.08));
    shield=max(shield, -sdEll(p-vec2(0.0,-0.2),vec2(0.12,0.12)));   // l'échancrure du nez
    shield=min(shield, sdSeg2(w,vec2(0.66,0.04),vec2(0.86,-0.28))-0.055);   // les bouts du ruban
    float eye=sdEll(vec2(m.x+0.02,m.y-0.02),vec2(0.19,0.085));
    det=eye; detc=vec3(1.0); glow=smoothstep(0.02,-0.05,eye)*1.5;
#elif HERO==3
    // Titan vert, le colosse en colère : son poing serré, vert, avec un liseré violet
    float f=1e3;
    for(int i=0;i<4;i++){ f=min(f, sdRBox(p-vec2(-0.33+float(i)*0.22,0.2-0.03*abs(float(i)-1.5)),vec2(0.108,0.2),0.1)); }
    float th=sdSeg2(p,vec2(-0.4,-0.08),vec2(0.12,-0.08))-0.115;   // le pouce, replié devant
    float palm=sdRBox(p-vec2(0.0,-0.24),vec2(0.44,0.24),0.14);
    shield=min(min(f,th),palm);
    det=min(abs(f)-0.014, abs(th)-0.014);
    det=max(det,-(th+0.01));   // les doigts passent derrière le pouce
    body=uC3; detc=uC1*0.6;
#elif HERO==4
    // Flamme écarlate, l'enfant de feu : une flamme vive, avec son cœur jaune qui rayonne
    shield=sdFlame(p,1.0);
    float core=sdFlame(p-vec2(0.0,-0.14),0.55);
    det=core; glow=smoothstep(0.03,-0.08,core)*0.8;
#else
    // Capitaine Éclair : l'écusson frappé d'un éclair
    float hw=p.y>-0.12 ? 0.5 : 0.5*clamp((p.y+0.8)/0.68,0.0,1.0);   // l'écusson : le haut droit, le bas en pointe
    shield=max(abs(p.x)-hw, abs(p.y+0.13)-0.67);
    det=min(min(sdSeg2(p,vec2(0.18,0.42),vec2(-0.1,0.0)), sdSeg2(p,vec2(-0.1,0.0),vec2(0.11,0.0))), sdSeg2(p,vec2(0.11,0.0),vec2(-0.15,-0.52)))-0.07;
#endif
    float rim=abs(shield+0.06)-0.03;
#if HERO==3
    rim=abs(shield+0.04)-0.045;
    vec3 rimc=uC2;   // le liseré violet du Titan
#else
    vec3 rimc=uC3;
#endif
    float sh=smoothstep(0.02,-0.02,shield)*smoothstep(0.13,0.06,abs(bz));
    if(sh>0.01){
      vec3 c=body*(0.82+0.25*n);
      c=mix(c, rimc*(0.95+0.1*n), smoothstep(0.015,-0.015,rim));
      c=mix(c, detc*(0.95+0.1*n), smoothstep(0.015,-0.015,det));
      e=detc*glow*sh*1.5;
      return vec4(mix(glass,c,sh), mix(dens,90.0,sh));
    }
    float ang=atan(p.y,p.x), rx=length(p)/1.7;
    float ray=smoothstep(0.55,0.85,abs(sin(ang*8.0)))*smoothstep(0.4,0.6,rx)*smoothstep(0.9,0.72,r)*smoothstep(0.0,-0.15,bz);
    if(ray>0.02) return vec4(mix(glass, uC3, 0.55*ray), mix(dens, 4.0, ray));
    return vec4(glass, dens);
  }
#elif MODE==49
  { // prisme : au cœur d'un verre profond, un prisme de cristal ; un rayon de lumière blanche le traverse
    // et ressort en un éventail arc-en-ciel qui s'ouvre dans le verre et pique le bord de reflets de toutes les couleurs
    float r=length(q);
    float ca=0.85, sa=0.53;   // le prisme est un peu tourné : on voit ses faces
    vec3 pr=vec3(ca*q.x+sa*q.z, q.y, -sa*q.x+ca*q.z);
    vec2 t=pr.xy-vec2(0.0,-0.02);
    float tri=max(abs(t.x)*0.866+t.y*0.5,-t.y)-0.15;
    float slab=abs(pr.z)-0.24;
    float inP=step(max(tri,slab),0.0);
    // ses arêtes : les deux triangles et les trois longues arêtes
    float dv=min(min(length(t-vec2(-0.26,-0.15)),length(t-vec2(0.26,-0.15))),length(t-vec2(0.0,0.3)));
    float edges=exp(-(abs(slab)+max(tri,0.0))*70.0)*step(tri,0.012)+exp(-dv*55.0)*step(slab,0.0);
    // le rayon blanc, de la gauche vers la face d'entrée
    vec2 A=vec2(-1.0,-0.12), B=vec2(-0.13,0.075); vec2 pa=t-A, ba=B-A; float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
    float db=length(vec3(pa-ba*h, pr.z));
    float beam=(exp(-db*60.0)*1.6+exp(-db*14.0)*0.35)*(1.0-inP);
    // l'éventail : il part de la face de sortie, s'ouvre en descendant vers la droite et s'épaissit en avançant
    vec2 E=vec2(0.13,0.075), pe=t-E; float L=length(pe), an=atan(pe.y,pe.x);
    float a0=-0.78, a1=-0.05, hue=clamp((an-a0)/(a1-a0),0.0,1.0);
    float th=0.015+L*0.11;
    float fan=smoothstep(a0-0.04,a0+0.04,an)*smoothstep(a1+0.04,a1-0.04,an)*smoothstep(th,th*0.3,abs(pr.z))*step(0.0,tri)*smoothstep(0.0,0.08,L);
    vec3 rb=0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+0.95-hue*0.8));
    // (16 octobre 2026) l'éventail prend les couleurs du coloris (de la 2e à la 3e), avec un reste d'arc-en-ciel : chaque coloris se reconnaît
    rb=mix(rb, mix(uC2,uC3,hue), 0.5);
    float lines=0.7+0.3*smoothstep(0.3,1.0,sin(hue*46.0));   // de fines raies dans le spectre
    // de la poussière de lumière qui scintille dans l'éventail, et l'arc-en-ciel qui s'écrase sur la paroi
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    float dust=step(0.86,h31(floor(g)))*smoothstep(0.14,0.02,length(fc));
    float wall=smoothstep(0.8,0.92,r);
    // dans le prisme, la lumière se sépare déjà : un dégradé arc-en-ciel vers la face de sortie
    vec3 inside=mix(0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+t.y*1.6+0.2)), uC3, 0.55);
    e=mix(vec3(1.0,0.98,0.93),uC3,0.3)*beam*7.0
     +rb*lines*fan*(6.5/(1.0+L*2.0)+dust*10.0+wall*4.0)
     +mix(uC3,vec3(1.0),0.25)*edges*7.0
     +inP*(mix(uC2,vec3(1.0),0.15)*0.9+inside*smoothstep(-0.1,0.13,t.x)*0.8)
     +uC2*0.35*smoothstep(0.95,0.4,r)*(1.0-inP);   // le verre profond s'éclaire de la 2e couleur
    // quelques éclats blancs dans le verre
    vec3 gs=q*11.0+so+3.0; vec3 fs=fract(gs)-0.5;
    e+=vec3(step(0.975,h31(floor(gs)))*smoothstep(0.1,0.0,length(fs)))*4.0*(1.0-inP);
    if(inP>0.5) return vec4(mix(uC2,vec3(1.0),0.25), 2.5);
    return vec4(uC1*0.34, 0.32);
  }
#elif MODE==50
  { // orage : un ciel d'orage pris dans le verre ; des éclairs ramifiés le traversent et l'illuminent de l'intérieur
    float r=length(q);
    float n=fbm(q*2.6+so), n2=fbm(q*5.5+so+7.0);
    float cloud=smoothstep(0.42,0.72,n+0.25*n2);
    float core=0.0, coreB=0.0, glow=0.0;
    for(int i=0;i<3;i++){ float fi=float(i);
      // un éclair du haut vers le bas, qui zigzague (deux échelles de bruit), et une branche qui part de son milieu
      vec3 a=(vec3(h31(so+fi),h31(so+fi+3.1),h31(so+fi+6.2))-0.5)*vec3(0.8,0.2,0.8)+vec3(0.0,0.62,0.0);
      vec3 b=(vec3(h31(so+fi+9.4),h31(so+fi+12.5),h31(so+fi+15.6))-0.5)*vec3(1.0,0.2,1.0)-vec3(0.0,0.6,0.0);
      vec3 ba=b-a, pa=q-a; float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
      // des coudes au hasard reliés en lignes droites : la forme cassée d'un vrai éclair
      float t7=h*7.0, i7=floor(t7), t19=h*19.0, i19=floor(t19);
      vec3 off=mix(vec3(h31(so+vec3(i7,fi,1.0)),h31(so+vec3(i7,fi,2.0)),h31(so+vec3(i7,fi,3.0))),
                   vec3(h31(so+vec3(i7+1.0,fi,1.0)),h31(so+vec3(i7+1.0,fi,2.0)),h31(so+vec3(i7+1.0,fi,3.0))),t7-i7)-0.5;
      vec3 off2=mix(vec3(h31(so+vec3(i19,fi,4.0)),h31(so+vec3(i19,fi,5.0)),h31(so+vec3(i19,fi,6.0))),
                    vec3(h31(so+vec3(i19+1.0,fi,4.0)),h31(so+vec3(i19+1.0,fi,5.0)),h31(so+vec3(i19+1.0,fi,6.0))),t19-i19)-0.5;
      float d=length(pa-ba*h-(off*0.3+off2*0.04)*sin(h*3.1416));
      vec3 m=a+ba*0.42, c2=m+normalize(vec3(h31(so+fi+20.0)-0.5,-0.7,h31(so+fi+21.0)-0.5))*0.45;
      vec3 bb=c2-m, pb=q-m; float hb=clamp(dot(pb,bb)/dot(bb,bb),0.0,1.0);
      vec3 ob=(vec3(noise(vec3(hb*18.0,fi+7.0,so.z)),noise(vec3(hb*18.0,fi+9.0,so.x)),noise(vec3(hb*18.0,fi+11.0,so.y)))-0.5)*0.12;
      float db=length(pb-bb*hb-ob*sin(hb*3.1416))+0.012*hb;
      float k=i==0?1.0:0.6;
      core+=k*exp(-d*45.0); coreB+=k*0.6*exp(-db*55.0);   // une lueur continue (un trait net se perd entre les pas du rayon)
      glow+=k*(exp(-d*12.0)+0.5*exp(-db*16.0));
    }
    float inside=smoothstep(0.95,0.82,r);
    vec3 boltc=mix(uC2,vec3(1.0),0.7);
    e=(boltc*core*55.0+mix(uC3,vec3(1.0),0.25)*coreB*70.0+mix(uC2,vec3(1.0),0.3)*glow*(1.5+3.0*cloud))*inside;
    vec3 col=mix(uC1*0.14, mix(mix(uC1,uC3,0.85*smoothstep(0.4,0.65,n2)),vec3(0.7),0.3)*0.75, cloud)+uC3*glow*0.15+uC2*glow*0.3;
    return vec4(col, 0.3+cloud*1.6);
  }
#elif MODE==51
  { // méduse : une méduse lumineuse flotte dans un verre d'eau profonde, ses longs filaments qui ondulent sous elle
    float r=length(q);
    vec3 b=q-vec3(0.0,0.12,0.0);
    float bell=length(b*vec3(1.0,1.7,1.0));
    float shell=smoothstep(0.035,0.0,abs(bell-0.42))*step(-0.02,b.y);
    float ang=atan(b.z,b.x);
    float ribs=0.6+0.4*smoothstep(0.6,1.0,abs(sin(ang*8.0)));
    float inner=smoothstep(0.42,0.2,bell)*step(-0.02,b.y);
    float tent=0.0;
    for(int i=0;i<8;i++){ float fi=float(i);
      float a=fi*0.785+so.x*0.1, t=(0.1-q.y)/0.8;
      if(t>0.0 && t<1.0){
        vec2 c=vec2(cos(a),sin(a))*(0.36-0.12*t)+vec2(sin(t*7.0+fi*1.7),cos(t*6.0+fi*2.3))*0.06*t;
        float d=length(q.xz-c);
        tent+=exp(-d*45.0)*(1.0-t)*(0.6+0.4*sin(t*30.0+fi));
      }
    }
    for(int i=0;i<3;i++){ float fi=float(i);   // les bras du centre, plus épais
      float a=fi*2.09+so.y*0.1, t=(0.1-q.y)/0.55;
      if(t>0.0 && t<1.0){ vec2 c=vec2(cos(a),sin(a))*0.07+vec2(sin(t*5.0+fi),cos(t*4.0+fi))*0.08*t;
        tent+=exp(-length(q.xz-c)*35.0)*(1.0-t)*0.8; }
    }
    vec3 g=q*13.0+so; vec3 fc=fract(g)-0.5;
    float pl=step(0.96,h31(floor(g)))*smoothstep(0.12,0.03,length(fc));
    e=(mix(uC2,vec3(1.0),0.3)*shell*ribs*12.0+mix(uC3,uC2,0.3)*inner*2.0+mix(uC2,vec3(1.0),0.4)*tent*9.0+vec3(0.8,0.9,1.0)*pl*1.5)*smoothstep(0.95,0.85,r);
    return vec4(uC1*0.18, 0.3+shell*3.0+inner*0.4);
  }
#elif MODE==47
  { // bêta : un β d'or qui brille au cœur d'un verre rubis, un anneau d'or qui le cercle, et des étincelles
    // la bille chinoise se regarde par le dessus : le β y est couché à plat
    bool couche=uAsp>1.2; vec2 bp=couche?vec2(q.x,-q.z):q.xy; float bz=couche?q.y:q.z;
    float d=sdBeta(bp*1.2)/1.2-0.04;
    if(max(d,abs(bz)-0.055)<0.0){ e=mix(uC3,vec3(1.0,0.97,0.85),0.35)*1.4; return vec4(uC3,500.0); }
    float glow=exp(-max(d,0.0)*16.0)*exp(-abs(bz)*7.0);
    vec3 nrm=normalize(vec3(0.3,1.0,0.45)); float h=dot(q,nrm), rr=length(q-h*nrm);
    float ring=smoothstep(0.035,0.012,length(vec2(rr-0.66,h)));
    vec3 g=q*10.0+so; vec3 fc=fract(g)-0.5; float sp=step(0.91,h31(floor(g)))*smoothstep(0.13,0.03,length(fc))*step(0.3,r);
    float sw=fbm(q*2.6+so);
    e=uC3*glow*2.6+uC3*ring*3.5+vec3(1.0,0.9,0.7)*sp*4.0;
    if(ring>0.5) return vec4(uC3,400.0);
    vec3 col=mix(uC1*0.8,uC2,smoothstep(0.3,0.8,sw));
    return vec4(mix(col,vec3(1.0,0.9,0.7),sp), 0.7+sp*40.0+smoothstep(0.55,0.85,sw)*1.4);
  }
#elif MODE==52
  { // étoilée : de petites étoiles à cinq branches semées sur toute la bille
    vec3 u=normalize(q); vec3 g=u*3.4+so; vec3 id=floor(g), f=fract(g)-0.5;
    vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    float a=h31(id+5.0)*6.2831853; vec2 p=vec2(dot(f,t1),dot(f,t2)); p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
    float sz=0.19+0.11*h31(id+3.0);
    float st=smoothstep(0.015,-0.015,sdStar(p/sz)*sz)*step(0.22,h31(id));
    vec3 sc=h31(id+2.0)<0.6?vec3(0.99,0.95,0.8):uC3;
    return vec4(mix(uC1,sc,st), 200.0);
  }
#elif MODE==53
  { // cœurs : de petits cœurs de toutes les tailles sur un fond clair
    vec3 u=normalize(q); vec3 g=u*2.6+so; vec3 id=floor(g), f=fract(g)-0.5;
    vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    float a=(h31(id+5.0)-0.5)*1.2; vec2 p=vec2(dot(f,t1),dot(f,t2)); p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
    float sz=0.27+0.08*h31(id+3.0);
    float hc=smoothstep(0.015,-0.015,sdHeart(vec2(p.x,-p.y)/sz)*sz)*step(0.12,h31(id));
    vec3 bg=mix(uC3,vec3(0.99,0.97,0.96),0.7);
    vec3 hcol=h31(id+2.0)<0.65?uC1:uC2*0.85;
    return vec4(mix(bg,hcol,hc), 200.0);
  }
#elif MODE==54
  { // bicolore : deux moitiés de deux couleurs, séparées par une ligne nette qui ondule à peine
    vec3 u=normalize(q); float y=u.y+0.05*sin(atan(u.z,u.x)*2.0+so.x);
    vec3 c=y>0.0?uC1:mix(uC3,vec3(0.97,0.96,0.93),0.45);
    c=mix(c,uC2*0.55,smoothstep(0.03,0.012,abs(y)));
    return vec4(c, 200.0);
  }
#elif MODE==55
  { // vagues : des bandes en vagues bien rondes qui font le tour de la bille
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float y=u.y*(4.5+nb)+0.38*sin(lon*(4.0+nb)+so.x);
    float m=mod(floor(y),3.0); vec3 c=m<1.0?uC1:(m<2.0?vec3(0.97,0.96,0.93):uC2);
    c*=mix(0.8,1.0,smoothstep(0.0,0.14,fract(y)));
    return vec4(c, 200.0);
  }
#elif MODE==56
  { // zigzag : des bandes en dents de scie, comme sur un pull d'hiver
    vec3 u=normalize(q); float s=atan(u.z,u.x)/6.2831853*(8.0+nb*2.0);
    float zz=abs(fract(s)-0.5)*2.0;
    float y=u.y*(3.5+nb*0.5)+zz*0.6;
    float m=mod(floor(y),4.0); vec3 c=m<1.0?uC1:(m<2.0?uC3:(m<3.0?uC1:vec3(0.97,0.95,0.9)));
    c*=mix(0.82,1.0,smoothstep(0.0,0.1,fract(y)));
    return vec4(c, 200.0);
  }
#elif MODE==57
  { // tricot : des mailles de laine en V, rang par rang, avec quelques rangs d'une autre couleur
    vec3 u=normalize(q); vec2 s=sph(u); float n=16.0+nb*2.0;
    vec2 p=vec2(s.x*n, s.y*n*0.62); vec2 id=floor(p), f=fract(p)-0.5;
    vec2 g=vec2(abs(f.x)-0.23, f.y+abs(f.x)*0.85-0.1);
    float leg=length(g*vec2(1.9,1.0))-0.3;
    float sh=smoothstep(0.1,-0.06,leg);
    float row=mod(id.y+floor(so.x),7.0);
    vec3 yarn=row<2.0?uC2:(row<3.0?vec3(0.96,0.94,0.9):uC1);
    vec3 c=yarn*(0.4+0.65*sh)*(0.9+0.18*noise(vec3(p*7.0,so.x)));
    return vec4(c, 200.0);
  }
#elif MODE==58
  { // nuages : un ciel de la couleur du coloris où passent de gros nuages blancs bien ronds
    vec3 u=normalize(q); float n=fbm(u*vec3(2.0,3.4,2.0)+so)+0.3*fbm(u*6.0+so+3.0);
    float cl=smoothstep(0.6,0.68,n);
    vec3 sky=mix(uC1,mix(uC1,vec3(1.0),0.5),u.y*0.5+0.5);
    vec3 cloud=mix(vec3(0.78,0.83,0.92),vec3(1.0),smoothstep(0.64,0.86,n));
    return vec4(mix(sky,cloud,cl), 200.0);
  }
#elif MODE==59
  { // mouchetée : un fond clair couvert de petites taches, comme un œuf de caille
    vec3 u=normalize(q); vec3 base=mix(uC3,vec3(0.97,0.95,0.9),0.65)*(0.92+0.1*noise(u*20.0+so));
    float sp=0.0; vec3 sc=uC1;
    for(int i=0;i<2;i++){ float sc2=i==0?5.0:11.0; vec3 g=u*sc2+so+float(i)*7.0; vec3 id=floor(g), f=fract(g)-0.5;
      vec3 off=vec3(h31(id+1.0),h31(id+2.0),h31(id+3.0))-0.5;
      float rr=(i==0?0.26:0.2)*(0.5+h31(id+4.0)); float d=length((f-off*0.5)*vec3(1.0,1.3,1.0))+0.06*noise(g*4.0);
      float m=smoothstep(rr,rr*0.65,d)*step(0.3,h31(id+6.0));
      if(m>sp){ sp=m; sc=h31(id+8.0)<0.6?uC1*0.6:uC2*0.75; } }
    return vec4(mix(base,sc,sp), 200.0);
  }
#elif MODE==60
  { // jean : la toile de jean (sa trame en diagonale, un peu délavée) et une double couture au fil doré
    vec3 u=normalize(q); vec2 s=sph(u);
    float tw2=fract((s.x*2.0+s.y)*55.0);
    float fade=smoothstep(0.45,0.75,fbm(u*2.0+so));
    vec3 den=mix(uC1*0.45,mix(uC1,vec3(0.9),0.25),smoothstep(0.35,0.65,tw2));
    den=mix(den,mix(uC1,vec3(0.92,0.94,0.97),0.6),fade*0.7);
    den*=0.88+0.22*noise(u*70.0+so);
    float y=u.y+0.04*sin(atan(u.z,u.x)*2.0+so.x);
    den=mix(den,den*0.7,smoothstep(0.065,0.04,abs(y)));
    float lon=atan(u.z,u.x)/6.2831853*80.0;
    float stitch=step(0.4,fract(lon))*smoothstep(0.02,0.01,abs(abs(y)-0.085));
    return vec4(mix(den,vec3(0.93,0.64,0.24),stitch), 200.0);
  }
#elif MODE==61
  { // ambre : une résine limpide de la couleur du coloris, plus foncée vers le bord ; au cœur, une feuille fossile
    // bien nette (ses nervures se voient), et quelques petites bulles d'air
    float r=length(q);
    vec3 res=mix(mix(uC1,uC2,0.6),uC1*0.75,smoothstep(0.3,0.95,r));
    vec2 p=q.xy; float ca=0.8, sa=0.6; p=vec2(ca*p.x-sa*p.y, sa*p.x+ca*p.y);
    float lw=0.19*sqrt(max(0.0,1.0-pow(p.y/0.46,2.0)))*(1.0-0.3*p.y);
    float lz=smoothstep(0.04,0.02,abs(q.z));
    float leaf=smoothstep(0.01,-0.01,abs(p.x)-lw)*lz*step(abs(p.y),0.46);
    float stem=smoothstep(0.014,0.007,abs(p.x))*step(p.y,-0.4)*step(-0.68,p.y)*lz;
    float vein=max(smoothstep(0.014,0.004,abs(p.x)), smoothstep(0.06,0.02,abs(fract((p.y-abs(p.x)*1.1)*8.0)-0.5))*step(abs(p.x),lw*0.9));
    vec3 g=q*7.0+so; vec3 id=floor(g), fc=fract(g)-0.5; float rb=0.04+0.05*h31(id+1.3);
    float bub=step(0.7,h31(id))*smoothstep(0.025,0.0,abs(length(fc-(vec3(h31(id+3.1),h31(id+7.7),h31(id+1.9))-0.5)*0.4)-rb))*smoothstep(0.88,0.7,r)*(1.0-lz);
    e=mix(uC2,uC3,0.5)*0.35*smoothstep(0.7,0.0,r)+vec3(1.0,0.95,0.8)*bub*1.2;   // la lumière qui reste prise au cœur
    float lf=max(leaf,stem);
    if(lf>0.01){ vec3 lc=mix(uC1*0.3,vec3(0.26,0.15,0.05),0.6)*(1.0-0.6*vein); e*=0.2; return vec4(lc, 70.0*lf); }
    return vec4(res, 0.55+bub*25.0);
  }
#elif MODE==62
  { // circuit : une carte électronique sombre ; ses pistes s'allument et la lumière y court d'un point à l'autre
    vec3 u=normalize(q); vec2 s=sph(u); float n=9.0+nb*2.0;
    vec2 p=vec2(s.x*n*2.0, s.y*n); vec2 id=floor(p), f=fract(p);
    float hk=h31(vec3(id,so.x)), hk2=h31(vec3(id,so.y+4.0));
    float dH=abs(f.y-0.5)+(hk<0.5?0.0:9.0);
    float dV=abs(f.x-0.5)+(hk2<0.42?0.0:9.0);
    float dd=min(dH,dV);
    float tr=smoothstep(0.08,0.045,dd);
    float pad=smoothstep(0.21,0.16,length(f-0.5))*step(0.7,h31(vec3(id,so.z+9.0)));
    float hole=smoothstep(0.085,0.055,length(f-0.5))*pad;
    float pulse=pow(0.5+0.5*sin((p.x+p.y)*0.9-uTime*2.5+hk*6.0),6.0);
    vec3 board=mix(vec3(0.03,0.06,0.07),uC1*0.25,0.6)*(0.85+0.2*noise(u*40.0+so));
    vec3 lc=mix(uC2,vec3(1.0),0.35);
    e=(lc*(tr*(0.5+2.5*pulse)+pad*1.1)*(1.0-hole)+lc*smoothstep(0.32,0.0,dd)*0.2)*1.4;
    vec3 c=mix(board,mix(uC2,vec3(0.85,0.75,0.4),0.3),max(tr,pad)*(1.0-hole));
    return vec4(c, 200.0);
  }
#elif MODE==63
  { // feu d'artifice : des bouquets de lumière qui éclatent dans un verre de nuit, chacun de sa couleur
    float r=length(q); e=vec3(0.0);
    for(int i=0;i<3;i++){ float fi=float(i);
      vec3 c=(vec3(h31(so+fi*3.1),h31(so+fi*5.7),h31(so+fi*8.3))-0.5)*0.8;
      float R=0.34+0.16*h31(so+fi*2.3);
      vec3 d=q-c; float L=length(d); vec3 dir=d/max(L,1e-4);
      // les rayons : la sphère des directions est découpée en bandes de latitude, et chaque case porte un rayon qui
      // reste tout entier dans sa case (avant, une grille cubique : 9 rayons sur 10 étaient coupés net par le bord de leur case)
      vec3 dd=i==0?dir:(i==1?dir.yzx:dir.zxy);
      float DB=3.14159265/12.0, ph0=fi*2.1+so.x;
      float th=acos(clamp(dd.z,-1.0,1.0)), ph=mod(atan(dd.y,dd.x)+ph0,6.2831853);
      float b=min(floor(th/DB),11.0);
      float nl=(b<0.5||b>10.5)?1.0:floor(24.0*sin((b+0.5)*DB)+0.5), w=6.2831853/nl;
      vec3 id=vec3(b,floor(ph/w),fi*17.0)+so;
      float thr=(b<0.5)?0.0:((b>10.5)?3.14159265:(b+0.5)*DB+(h31(id+1.0)-0.5)*(DB-0.2));
      float sIn=max(sin(min(b,11.0-b)*DB),1e-3);   // le bord le plus étroit de la bande (côté pôle)
      float phr=(floor(ph/w)+0.5)*w+(h31(id+2.0)-0.5)*max(0.0,w-0.2/sIn)-ph0;
      vec3 cd=vec3(sin(thr)*cos(phr),sin(thr)*sin(phr),cos(thr));
      float ang=length(dd-cd);
      float ray=smoothstep(0.06,0.014,ang)*step(0.25,h31(id+4.0));
      float along=smoothstep(0.03,0.14,L)*smoothstep(R,R*0.6,L);
      float tip=smoothstep(0.07,0.0,abs(L-R*0.82))*smoothstep(0.08,0.02,ang)*step(0.25,h31(id+4.0));
      vec3 col=i==0?mix(uC2,vec3(1.0),0.2):(i==1?mix(uC3,vec3(1.0),0.2):vec3(1.0,0.85,0.45));
      e+=col*(ray*along*7.0+tip*14.0)+mix(col,vec3(1.0),0.5)*exp(-L*28.0)*4.0;
    }
    vec3 g=q*16.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.97,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*4.0;
    e*=smoothstep(0.95,0.85,r);
    return vec4(uC1*0.12, 1.2);
  }
#elif MODE==64
  { // (11 octobre 2026, remplace le Vortex) œil du dragon : un œil de reptile au milieu du verre. La pupille fendue s'ouvre et se ferme, le regard se promène,
    // les paupières clignent une fois par boucle. Les 3 couleurs du coloris : la peau d'écailles et le cercle de l'iris (la 1re),
    // l'iris (la 2e), la couronne de feu autour de la pupille, les éclats de l'iris et le bord des paupières (la 3e)
    float t=mod(uTime,3.9269908), lp=t*1.6;   // lp fait un tour complet (2π) par boucle : tout ce qui bouge en dépend
    float h=q.z; vec2 p=q.xy;
    float lay=exp(-h*h/0.02);
    float bl=pow(max(0.0,cos(lp-2.4)),80.0);   // le clignement : très court
    float op=1.0-bl;
    float ax=clamp(abs(p.x)/0.92,0.0,1.0);
    float lid=0.47*op*pow(1.0-ax*ax,0.75);
    float inE=smoothstep(0.015,-0.015,abs(p.y)-lid)*step(abs(p.x),0.92);
    vec2 c=vec2(0.18*sin(lp),0.06*sin(lp*2.0));
    vec2 ip=p-c; float ir=length(ip); float ia=atan(ip.y,ip.x);
    float iris=smoothstep(0.42,0.39,ir);
    vec3 wob=vec3(cos(lp),sin(lp),0.0)*0.7;
    float fib=noise(vec3(cos(ia)*9.0,sin(ia)*9.0,ir*3.0)+so)*0.55+noise(vec3(cos(ia)*24.0,sin(ia)*24.0,ir*5.0)+so+wob)*0.45;
    float pw=0.045+0.05*(0.5+0.5*sin(lp*2.0+1.0));
    float pup=smoothstep(1.0,0.85,length(vec2(ip.x/pw,ip.y/0.4)));
    vec3 c1g=uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.35);   // la 1re couleur, éclaircie pour briller (elle est souvent très foncée)
    float fl3=smoothstep(0.55,0.75,noise(vec3(cos(ia)*14.0,sin(ia)*14.0,ir*2.0)+so+3.0));   // des éclats de la 3e couleur dans l'iris
    vec3 ic=mix(uC2,uC3,fl3*0.85);
    float pr=length(vec2(ip.x/pw,ip.y/0.4));
    float crown=smoothstep(3.2,1.2,pr);   // la couronne autour de la pupille
    ic=mix(ic,uC3,crown*0.9);
    float limb=smoothstep(0.27,0.39,ir);
    ic=mix(ic,c1g*0.6,limb*0.85);   // le cercle de l'iris, de la 1re couleur
    float ring=exp(-pow((pr-1.15)/0.25,2.0));   // le feu juste au bord de la pupille
    vec3 eyeE=(ic*(0.45+1.3*fib)+mix(uC3,vec3(1.0),0.35)*ring*1.2)*iris*(1.0-pup);
    vec2 sg=p*vec2(7.0,8.5); sg.x+=mod(floor(sg.y),2.0)*0.5; vec2 sf=fract(sg)-0.5;
    float edgeS=smoothstep(0.3,0.5,length(sf*vec2(1.0,1.3)));
    float rim=exp(-pow((abs(p.y)-lid)/0.022,2.0))*step(abs(p.x),0.9)*op;
    vec2 hl=p-c-vec2(-0.16,0.17);
    e=eyeE*6.0*inE*lay + c1g*0.35*(1.0-iris)*inE*lay + mix(uC3,vec3(1.0),0.15)*rim*lay*4.0
     + c1g*edgeS*(1.0-inE)*lay*1.4 + vec3(1.0)*exp(-dot(hl,hl)/0.0018)*inE*lay*7.0;
    vec3 skin=mix(uC1*0.6,uC1*0.18,edgeS);
    float skinA=(1.0-inE)*lay*30.0*smoothstep(0.98,0.9,length(q));
    return vec4(mix(uC1*0.2,skin,clamp(skinA,0.0,1.0)), 0.9+pup*iris*inE*lay*80.0+skinA);
  }
#elif MODE==65
  { // tricolore : trois bandes égales qui font le tour de la bille, comme un drapeau enroulé
    vec3 u=normalize(q); float y=u.y+0.035*sin(atan(u.z,u.x)*3.0+so.x);
    vec3 c=y>0.33?uC1:(y<-0.33?uC2:uC3);
    float ed=min(abs(y-0.33),abs(y+0.33));
    c*=mix(0.8,1.0,smoothstep(0.004,0.022,ed));
    return vec4(c, 200.0);
  }
#elif MODE==66
  { // sucette : une spirale de sucre en trois couleurs qui part du centre de la bille, comme une sucette de fête foraine
    vec3 u=normalize(q); float th=acos(clamp(u.z,-1.0,1.0)), ph=atan(u.y,u.x);
    float s=ph/6.2831853*4.0+th*(3.6+nb*0.4);
    float m=mod(floor(s),4.0); vec3 c=m<1.0?uC1:(m<2.0?vec3(0.98,0.97,0.95):(m<3.0?uC2:uC3));
    float fs=fract(s); c*=mix(0.82,1.0,smoothstep(0.0,0.12,fs))*mix(1.0,0.92,smoothstep(0.75,1.0,fs));
    c=mix(c,vec3(1.0),0.5*smoothstep(0.28,0.0,th));   // le petit bout blanc au centre
    return vec4(c, 200.0);
  }
#elif MODE==67
  { // fleurettes : de petites fleurs à cinq pétales semées sur un fond clair, avec leur cœur (deux semis décalés : il y en a partout)
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 bg=mix(uC2,vec3(0.98,0.97,0.94),0.78), c=bg;
    for(int i=0;i<2;i++){ vec3 g=u*2.4+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*31.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float L=length(p), a=atan(p.y,p.x)+h31(id+5.0)*6.2831853;
      float on=step(0.15,h31(id))*step(abs(dot(f,u)),0.22), sz=0.17+0.08*h31(id+3.0);
      float pet=sz*(0.5+0.5*pow(abs(cos(a*2.5)),0.6));
      float fl=smoothstep(pet+0.012,pet-0.012,L)*on;
      float ctr=smoothstep(sz*0.3+0.012,sz*0.3-0.012,L)*on;
      vec3 pc=h31(id+2.0)<0.6?uC1:vec3(0.99,0.98,0.97);
      c=mix(c,pc*mix(0.85,1.0,smoothstep(0.0,pet,L)),fl);
      c=mix(c,mix(uC3,vec3(1.0,0.82,0.25),0.45),ctr); }
    return vec4(c, 200.0);
  }
#elif MODE==68
  { // girafe : de grandes taches aux coins arrondis, séparées par des chemins clairs
    vec3 u=normalize(q); vec3 g=u*(1.9+nb*0.15)+so; vec3 i0=floor(g), f0=fract(g);
    float d1=9.0, d2=9.0; vec3 cid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
      vec3 pt=o+0.15+0.7*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
      if(d<d1){ d2=d1; d1=d; cid=i0+o; } else if(d<d2) d2=d; }
    float ed=d2-d1+0.07*(noise(g*3.0)-0.5);
    float pat=smoothstep(0.07,0.1,ed);
    vec3 pc=mix(uC1,uC2,0.45*h31(cid+1.0))*(0.8+0.25*smoothstep(0.15,0.5,ed))*(0.92+0.12*noise(g*9.0));
    vec3 cream=mix(uC3,vec3(0.98,0.94,0.84),0.72);
    return vec4(mix(cream,pc,pat), 200.0);
  }
#elif MODE==69
  { // camouflage : des taches de trois couleurs qui se chevauchent, comme une tenue d'explorateur
    vec3 u=normalize(q);
    float n1=fbm(u*2.1+so), n2=fbm(u*2.5+so+11.0), n3=fbm(u*3.1+so+23.0);
    vec3 c=mix(uC2,uC3,0.3);
    c=mix(c,uC1,smoothstep(0.49,0.51,n1));
    c=mix(c,uC1*0.35,smoothstep(0.55,0.57,n2));
    c=mix(c,mix(uC3,vec3(0.92,0.88,0.75),0.55),smoothstep(0.6,0.62,n3));
    c*=0.93+0.1*noise(u*45.0+so);
    return vec4(c, 200.0);
  }
#elif MODE==70
  { // briques : un mur de briques bien rangées, décalées d'un rang à l'autre, avec leur ciment
    vec3 u=normalize(q); float lat=asin(clamp(u.y,-1.0,1.0)); float R=8.0+nb;
    float rf=(lat/3.14159265+0.5)*R, row=floor(rf), fy=fract(rf);
    float lc=((row+0.5)/R-0.5)*3.14159265, nk=max(1.0,floor(R*1.15*cos(lc)+0.5));
    float cf=(atan(u.z,u.x)/6.2831853+0.5)*nk+mod(row,2.0)*0.5+h31(vec3(row,so.x,1.0)), fx=fract(cf);
    vec3 bid=vec3(row,mod(floor(cf),nk),so.y);
    float mx=min(fx,1.0-fx)*6.2831853*max(cos(lat),0.05)/nk, my=min(fy,1.0-fy)*3.14159265/R;
    float mort=smoothstep(0.014,0.03,min(mx,my));
    float hb=h31(bid);
    vec3 br=(hb<0.6?uC1:(hb<0.85?uC2:uC3))*(0.78+0.3*h31(bid+2.0))*(0.88+0.18*noise(u*35.0+so));
    br*=mix(0.85,1.0,smoothstep(0.03,0.07,min(mx,my)));   // l'arête de la brique, un peu plus sombre
    vec3 cem=mix(vec3(0.86,0.84,0.8),uC3,0.3)*(0.9+0.1*noise(u*80.0));
    return vec4(mix(cem,br,mort), 200.0);
  }
#elif MODE==71
  { // puzzle : des pièces de puzzle de trois couleurs, chacune avec ses tenons et ses creux
    vec3 u=normalize(q); vec4 cf=cubeF(u); float N=2.0+floor(nb*0.5);
    vec2 G=(cf.xy*0.5+0.5)*N; vec2 id=min(floor(G),N-1.0), p=G-id;
    vec2 own=id; float dmin=9.0, r=0.17;
    for(int k=0;k<4;k++){
      vec2 n=k==0?vec2(1.0,0.0):(k==1?vec2(-1.0,0.0):(k==2?vec2(0.0,1.0):vec2(0.0,-1.0)));
      vec2 nb2=id+n; float edge=k<2?(n.x>0.0?1.0:0.0):(n.y>0.0?1.0:0.0);
      bool border=nb2.x<0.0||nb2.y<0.0||nb2.x>N-1.0||nb2.y>N-1.0;   // au bord d'une face du cube : pas de tenon
      vec2 em=k<2?vec2(edge,0.5):vec2(0.5,edge);
      float dl=k<2?abs(p.x-edge):abs(p.y-edge);
      if(border){ dmin=min(dmin,dl); continue; }
      vec2 eid=min(id,nb2)+abs(n)*0.5;   // le même identifiant vu des deux pièces
      float sgn=h31(vec3(eid*7.3,cf.w+so.x))<0.5?1.0:-1.0; sgn*=n.x+n.y;   // tiré une fois par bord (vu de la pièce du bas ou de gauche), puis retourné pour l’autre côté ; +1 : le tenon part chez la voisine ; -1 : celui de la voisine entre chez nous
      vec2 c=em+n*sgn*0.13; float Lk=length(p-c);
      vec2 pr=k<2?vec2(edge,p.y):vec2(p.x,edge);
      if(length(pr-c)>r) dmin=min(dmin,dl);
      if(sgn<0.0){ dmin=min(dmin,abs(Lk-r)); if(Lk<r) own=nb2; }
    }
    float par=mod(own.x+own.y*2.0+cf.w,3.0);
    vec3 c=par<1.0?uC1:(par<2.0?uC2:mix(uC3,vec3(0.97,0.95,0.9),0.3));
    c*=mix(0.75,1.0,smoothstep(0.0,0.09,dmin))*(0.95+0.07*noise(u*30.0+so));
    c=mix(c*0.35,c,smoothstep(0.008,0.022,dmin));
    return vec4(c, 200.0);
  }
#elif MODE==72
  { // labyrinthe : des murs en diagonale, au hasard d'une case à l'autre, qui dessinent des couloirs sans fin
    vec3 u=normalize(q); vec4 cf=cubeF(u); float N=4.0+nb;
    vec2 G=(cf.xy*0.5+0.5)*N; vec2 id=min(floor(G),N-1.0), p=G-id;
    float fl=h31(vec3(id*3.1,cf.w*7.0+so.x));
    float d=fl<0.5?abs(p.x-p.y):abs(p.x+p.y-1.0); d*=0.7071;
    float wall=smoothstep(0.1,0.075,d);
    vec3 floorc=mix(uC3,vec3(0.98,0.97,0.94),0.6);
    vec3 wc=mix(uC1,uC2,smoothstep(0.075,0.0,d)*0.45);
    float sh=smoothstep(0.24,0.1,d)*0.18;   // l'ombre du mur sur le sol
    return vec4(mix(floorc*(1.0-sh),wc,wall), 200.0);
  }
#elif MODE==73
  { // pied-de-poule : le motif des manteaux chics, tissé en deux couleurs
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 pp=cf.xy*(1.6+nb*0.25)+so.xy;
    vec2 t=floor(pp*8.0);
    bool top=mod(t.x+t.y,4.0)<2.0;
    bool dk=top?mod(t.x,8.0)<4.0:mod(t.y,8.0)<4.0;
    vec3 c=dk?uC1*0.85:mix(uC3,vec3(0.97,0.95,0.9),0.55);
    vec2 ov=abs(fract(pp+0.5)-0.5); c=mix(c,uC2,smoothstep(0.03,0.015,min(ov.x,ov.y)));   // le fin carreau d'une 3e couleur par-dessus (« Prince de Galles »)
    vec2 ft=fract(pp*8.0); c*=0.9+0.12*smoothstep(0.0,0.5,top?ft.y:ft.x)*smoothstep(1.0,0.5,top?ft.y:ft.x);
    return vec4(c, 200.0);
  }
#elif MODE==74
  { // terrazzo : des éclats de pierre de toutes les couleurs pris dans un ciment clair, comme le sol d'une vieille école
    vec3 u=normalize(q); vec3 g=u*(5.0+nb*0.5)+so; vec3 i0=floor(g), f0=fract(g);
    float d1=9.0, d2=9.0; vec3 cid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
      vec3 pt=o+0.1+0.8*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
      if(d<d1){ d2=d1; d1=d; cid=i0+o; } else if(d<d2) d2=d; }
    float hc=h31(cid+4.0), sz=0.08+0.22*h31(cid+9.0);
    float chip=smoothstep(sz,sz+0.03,d2-d1)*step(0.35,hc);   // seulement une partie des cases : de vrais éclats, pas un pavage
    vec3 cc=hc<0.55?uC1:(hc<0.75?uC2:(hc<0.9?uC3:vec3(0.15,0.14,0.16)));
    vec3 cem=mix(vec3(0.95,0.93,0.89),uC3,0.08);
    vec3 gs=u*60.0+so; float sp=step(0.93,h31(floor(gs)));   // les tout petits grains du ciment
    cem=mix(cem,mix(uC1,vec3(0.3),0.4),sp*0.8);
    return vec4(mix(cem,cc*(0.9+0.12*noise(g*6.0)),chip), 200.0);
  }
#elif MODE==75
  { // sable : des couches de sable coloré qui ondulent, comme dans une bouteille de sable des vacances
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float h=u.y*(2.6+nb*0.3)+0.45*fbm(u*1.6+so)+0.12*sin(lon*2.0+so.x);
    float b=floor(h*2.0), fh=fract(h*2.0);
    float m=mod(b,4.0); vec3 c=m<1.0?uC1:(m<2.0?vec3(0.96,0.92,0.84):(m<3.0?uC2:uC3));
    c*=0.82+0.3*noise(u*140.0+so)*noise(u*37.0+so);   // le grain du sable
    c*=mix(0.88,1.0,smoothstep(0.0,0.08,fh));
    return vec4(c, 200.0);
  }
#elif MODE==76
  { // cuivre : du cuivre poli (miroir, au rendu) mangé par endroits par une patine vert-de-gris, avec des taches plus sombres
    vec3 u=normalize(q); float m=cuivreM(q);
    vec3 pat=mix(vec3(0.3,0.66,0.55),uC2,0.4)*(0.75+0.35*noise(u*28.0+so));
    pat=mix(pat,uC1*0.7,smoothstep(0.55,0.75,noise(u*11.0+so+4.0))*0.6);
    vec3 cu=mix(vec3(0.85,0.47,0.27),uC3,0.2);
    return vec4(mix(cu,pat,m), 200.0);
  }
#elif MODE==77
  { // paon : des yeux de plume de paon sur un fond de barbes qui chatoient
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    float fb=fbm(u*3.0+so);
    vec3 c=mix(mix(uC2,vec3(0.15,0.45,0.3),0.35)*0.55,mix(uC3,vec3(0.85,0.7,0.3),0.4),0.45+0.18*sin(dot(u,vec3(90.0,37.0,61.0))+fb*14.0));
    for(int i=0;i<2;i++){ vec3 g=u*1.5+so+float(i)*vec3(0.5,0.41,0.63); vec3 id=floor(g)+float(i)*29.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float a=h31(id+5.0)*6.2831853; p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
      float on=step(abs(dot(f,u)),0.24)*step(0.2,h31(id));
      float d=length(vec2(p.x,(p.y+0.04)*0.82))/0.36;
      vec3 eye=mix(uC2,vec3(0.2,0.6,0.35),0.35)*1.15;
      eye=mix(eye,mix(uC3,vec3(0.95,0.75,0.3),0.45),smoothstep(0.72,0.66,d));
      eye=mix(eye,mix(uC1,vec3(0.1,0.3,0.85),0.45),smoothstep(0.54,0.48,d));
      eye=mix(eye,uC1*0.25,smoothstep(0.33,0.27,length(vec2(p.x,(p.y+0.02)*0.95))/0.36));
      c=mix(c,eye,on*smoothstep(1.02,0.96,d)); }
    return vec4(c, 200.0);
  }
#elif MODE==78
  { // bulles : un verre teinté rempli de grosses bulles de savon, leur fine paroi aux reflets de couleur
    float r=length(q); vec3 g=q*3.2+so; vec3 id=floor(g), fc=fract(g)-0.5;
    vec3 off=(vec3(h31(id+3.1),h31(id+7.7),h31(id+1.9))-0.5)*0.3; float rb=0.14+0.17*h31(id+1.3);
    float d=length(fc-off);
    float sh=step(0.3,h31(id))*smoothstep(0.035,0.0,abs(d-rb))*smoothstep(0.93,0.75,r);
    float k=fract((fc.y-off.y)*2.5+h31(id)*3.0)*3.0;
    vec3 film=k<1.0?mix(uC2,uC3,k):(k<2.0?mix(uC3,vec3(1.0),k-1.0):mix(vec3(1.0),uC2,k-2.0));
    film=mix(film,0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+k*0.4)),0.3);
    e=film*sh*4.5;
    return vec4(mix(uC1,film,sh), 0.32+sh*22.0);
  }
#elif MODE==79
  { // jungle : de grandes feuilles qui se chevauchent, avec leurs nervures, dans les 3 couleurs du coloris
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 c=uC1*0.25;
    for(int i=0;i<4;i++){ vec3 g=u*1.45+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*17.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float a=h31(id+5.0)*6.2831853; p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
      float on=step(abs(dot(f,u)),0.3)*step(0.12,h31(id));
      float lw=0.27*sqrt(max(0.0,1.0-pow(p.y/0.45,2.0)))*(1.0-0.35*p.y);
      float leaf=smoothstep(0.01,-0.01,abs(p.x)-lw)*step(abs(p.y),0.45)*on;
      float vein=max(smoothstep(0.016,0.006,abs(p.x)), smoothstep(0.07,0.025,abs(fract((p.y-abs(p.x)*1.2)*7.0)-0.5))*step(abs(p.x),lw*0.85));
      float k=h31(id+2.0); vec3 lc=k<0.4?uC1:(k<0.75?uC2:uC3);
      lc=mix(lc,vec3(0.15,0.45,0.2),0.2)*(0.65+0.45*smoothstep(lw,0.0,abs(p.x)))*(1.0+0.35*vein);
      c=mix(c*0.8,lc,leaf); }   // une feuille du dessus fait de l'ombre à celle d'en dessous
    return vec4(c, 200.0);
  }
#elif MODE==80
  { // météorite : une pallasite, du fer d'étoile filante (miroir, au rendu) gravé de fines lamelles, avec des cristaux colorés pris dedans
    vec3 m=meteo(q);
    vec3 cr=m.z<0.33?uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.4)*0.8:(m.z<0.66?uC2:uC3);
    return vec4(mix(vec3(0.72-0.3*m.y),cr,m.x), 200.0);
  }
#elif MODE==81
  { // lune : la pleine lune au cœur d'un verre de nuit, ses mers et ses cratères, et un halo autour
    float r=length(q); vec3 Lm=normalize(vec3(-0.55,0.35,0.75));
    float R=0.42;
    if(r<R){ vec3 nm=q/r;
      float mar=smoothstep(0.52,0.6,fbm(nm*1.6+so));
      vec3 g=nm*3.4+so; vec3 id=floor(g), fc=fract(g)-0.5; vec3 off=(vec3(h31(id+1.0),h31(id+2.0),h31(id+3.0))-0.5)*0.5;
      float rc=0.1+0.14*h31(id+4.0), dc=length(fc-off), onc=step(0.35,h31(id));
      float cfl=smoothstep(rc,rc*0.75,dc)*onc, rim=smoothstep(0.035,0.0,abs(dc-rc))*onc;
      vec3 g2=nm*9.0+so; vec3 fc2=fract(g2)-0.5; float sm=step(0.6,h31(floor(g2)))*smoothstep(0.17,0.08,length(fc2));
      vec3 mc=mix(mix(vec3(0.88,0.87,0.84),uC3,0.25),mix(uC2,vec3(0.4),0.5),mar*0.6)*(1.0-0.22*cfl-0.12*sm)*(1.0+0.25*rim)*(0.92+0.12*noise(nm*20.0+so));
      float sh=0.25+0.85*smoothstep(-0.25,0.6,dot(nm,Lm));
      e=mc*sh*0.9; return vec4(mc*sh, 1000.0); }
    e=mix(uC3,vec3(0.9,0.92,1.0),0.4)*exp(-(r-R)*9.0)*0.9;
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*6.0*step(0.55,r);
    return vec4(uC1*0.12, 0.45);
  }
#elif MODE==82
  { // lucioles : une nuit d'été dans le verre, des herbes hautes en ombre chinoise et des lucioles qui brillent
    float r=length(q); e=vec3(0.0);
    vec3 g=q*5.0+so; vec3 id=floor(g), fc=fract(g)-0.5; vec3 off=(vec3(h31(id+1.0),h31(id+2.0),h31(id+3.0))-0.5)*0.6;
    float L=length(fc-off); float on=step(0.55,h31(id))*smoothstep(0.9,0.6,r)*step(-0.35,q.y);
    vec3 fcol=mix(vec3(0.8,1.0,0.3),uC3,0.45);
    e+=fcol*on*(exp(-L*28.0)*14.0+exp(-L*8.0)*1.6);
    float gr=0.0;   // les herbes : des brins pointus qui montent du bas, sur deux rangs
    for(int i=0;i<2;i++){ float fi=float(i); float x=(i==0?q.x:q.z+0.3*q.x)*9.0+so.x+fi*3.7; float bi=floor(x), bx=fract(x)-0.5;
      float hgt=-0.5+0.45*h31(vec3(bi,fi,so.y)); float lean=(h31(vec3(bi,fi,4.0))-0.5)*0.5;
      float w=0.42*clamp((hgt-q.y)/(hgt+0.95),0.0,1.0);
      gr=max(gr,step(abs(bx-lean*(q.y+0.95)),w)*step(q.y,hgt)); }
    e+=mix(uC2,vec3(0.4,0.5,1.0),0.3)*0.7*smoothstep(-0.6,0.9,q.y)*smoothstep(0.98,0.6,r);   // le ciel encore un peu clair en haut
    if(gr>0.5) return vec4(mix(uC1,vec3(0.02,0.06,0.03),0.75), 300.0);
    return vec4(uC1*0.14, 0.45);
  }
#elif MODE==83
  { // tornade : un entonnoir de vent enroulé en spirale (une bande par couleur du coloris), qui descend d'un nuage d'orage
    // de la 1re couleur jusqu'au sol, où il soulève un tourbillon de poussière lumineuse de la 3e ; des débris tournent autour
    float r=length(q), y=q.y; float t=clamp((y+0.72)/1.32,0.0,1.0);
    vec2 c=vec2(0.12*sin(y*2.6+so.x),0.06*cos(y*2.2+so.y))*(1.0-t)*(1.0-t);   // la pointe ondule un peu
    vec2 pxz=q.xz-c; float rho=length(pxz), ang=atan(pxz.y,pxz.x);
    float R=0.03+0.29*pow(t,1.6);
    float inY=smoothstep(-0.74,-0.68,y)*smoothstep(0.62,0.52,y);
    float th=0.04+0.06*t;
    float wall=smoothstep(th,th*0.35,abs(rho-R))*inY;
    // les bandes : elles s'enroulent autour de l'entonnoir en montant
    float s=ang/6.2831853*3.0+y*7.0+0.3*fbm(q*3.0+so);
    float m=mod(floor(s),3.0), fs=fract(s);
    vec3 band=m<1.0?uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.45):(m<2.0?uC2:uC3);
    float streak=0.75+0.35*noise(vec3(ang*6.0,y*30.0,so.z));   // les filets de vent
    band*=streak*mix(0.7,1.0,smoothstep(0.0,0.12,fs)*smoothstep(1.0,0.88,fs));
    float side=0.6+0.5*clamp(dot(normalize(vec3(pxz.x,0.0,pxz.y)+vec3(0.0001)),normalize(vec3(-0.6,0.0,0.8))),0.0,1.0);   // éclairé d'un côté
    // le nuage d'orage, en haut, de la 1re couleur
    float cn=fbm(q*2.8+so);
    float cloud=smoothstep(0.42,0.6,y+0.3*cn)*smoothstep(0.98,0.8,r);
    vec3 cc=mix(uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.45)*0.35,mix(uC1,vec3(0.85),0.55),smoothstep(0.4,0.75,cn));
    // la poussière au sol, de la 3e couleur, qui tourne en anneau
    float dust=exp(-abs(y+0.7)*10.0)*smoothstep(0.55,0.1,abs(rho-0.22))*(0.5+0.5*fbm(q*6.0+so+2.0))*smoothstep(0.95,0.75,r);
    vec3 g=q*12.0+so; vec3 fg=fract(g)-0.5;
    float chips=step(0.88,h31(floor(g)))*smoothstep(0.18,0.08,length(fg))*smoothstep(0.14,0.0,abs(rho-R*1.25-0.03))*inY;
    e=mix(uC3,vec3(1.0),0.25)*dust*5.0+band*wall*0.35+mix(uC2,vec3(1.0),0.4)*exp(-max(y-0.45,0.0)*8.0)*smoothstep(0.55,0.4,y)*exp(-rho*6.0)*0.25;
    vec3 col=mix(uC1*0.12,mix(uC2,vec3(0.6),0.5)*0.35,smoothstep(-0.8,0.6,y));   // le ciel, plus clair vers le haut
    col=mix(col,cc,cloud);
    col=mix(col,band*side,clamp(wall*1.6,0.0,1.0));
    col=mix(col,mix(uC3,vec3(0.2),0.4),chips);
    return vec4(col, 0.35+wall*7.0+cloud*6.0+chips*60.0+dust*1.5);
  }
#elif MODE==84
  { // engrenages : trois roues dentées qui s'engrènent au cœur du verre, une de chaque couleur (on les voit tourner en grand)
    float T=0.0; float d=9.0, k=0.0;
    for(int i=0;i<3;i++){
      vec2 C=i==0?vec2(-0.17,0.06):(i==1?vec2(0.31,0.2):vec2(0.11,-0.36));
      float Rg=i==0?0.3:(i==1?0.17:0.13), n=i==0?12.0:(i==1?7.0:5.0), z=i==0?0.0:(i==1?0.03:-0.03), ns=i==0?5.0:4.0;
      float rot=i==0?T:(i==1?-T*12.0/7.0+0.25:-T*12.0/5.0+0.3);
      vec2 p=q.xy-C; float a=atan(p.y,p.x)+rot, L=length(p);
      float g=L-Rg-0.045*smoothstep(-0.25,0.25,cos(a*n));
      bool hole=L<Rg*0.17 || (L>Rg*0.32 && L<Rg*0.7 && abs(fract(a*ns/6.2831853)-0.5)<0.33);
      if(hole) g=max(g,0.01);
      g=max(g,abs(q.z-z)-0.045);
      if(g<d){ d=g; k=float(i); }
    }
    vec3 gc=k<0.5?mix(vec3(0.98,0.76,0.32),uC3,0.4):(k<1.5?mix(vec3(0.9,0.7,0.35),uC2,0.55):mix(vec3(0.8,0.6,0.3),uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.4),0.55));
    vec3 g3=q*13.0+so; vec3 fc=fract(g3)-0.5;
    e=vec3(step(0.975,h31(floor(g3)))*smoothstep(0.2,0.0,length(fc)))*2.5;   // de la poussière dorée qui brille
    if(d<0.0){ float edge=smoothstep(0.0,0.02,-d); e+=gc*0.35; return vec4(gc*(0.6+0.5*edge), 400.0); }
    return vec4(mix(uC1,uC2,0.3)*0.5, 0.4);
  }
#elif MODE==85
  { // comète : une comète file dans un verre de nuit, son cœur éblouissant et ses deux queues (une droite, une courbe)
    float r=length(q); vec3 N=vec3(0.3,0.25,0.0); vec3 d=q-N; float L=length(d);
    e=mix(vec3(1.0),uC3,0.25)*(exp(-L*50.0)*40.0+exp(-L*13.0)*3.5);
    vec3 A=normalize(vec3(-1.0,-0.62,0.05));
    float al=dot(d,A), pe=length(d-A*al);
    float ion=step(0.0,al)*exp(-pe/(0.01+max(al,0.0)*0.035))*exp(-al*1.3)*(0.65+0.35*noise(vec3(al*18.0,pe*50.0,so.x)));
    vec3 B=normalize(vec3(-0.85,-0.85,0.0)), Bn=normalize(vec3(0.7,-0.7,0.0));
    float s=dot(d,B); vec3 cc=B*s+Bn*s*s*0.45; float dd=length(d-cc);
    float dust=step(0.0,s)*exp(-dd/(0.015+max(s,0.0)*0.13))*exp(-s*1.1)*(0.55+0.45*fbm(q*6.0+so));
    e+=mix(uC2,vec3(0.55,0.75,1.0),0.35)*ion*16.0+mix(uC3,vec3(1.0,0.88,0.65),0.35)*dust*9.0;
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.968,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*6.0*step(0.5,r);
    return vec4(uC1*0.1, 0.45);
  }
#elif MODE==86
  { // atome : un noyau de petites boules au centre et trois orbites de lumière, chacune avec son électron (qui tourne, en grand)
    float r=length(q); e=vec3(0.0);
    vec3 ocol=mix(uC2,vec3(1.0),0.35);
    for(int i=0;i<3;i++){ float fa=float(i)*1.0471976+0.3;
      vec2 xy=vec2(cos(fa)*q.x+sin(fa)*q.y, -sin(fa)*q.x+cos(fa)*q.y); float h=q.z+0.12*xy.y;
      float a=0.72, b=0.24; float th=atan(xy.y/b, xy.x/a); vec2 P=vec2(a*cos(th), b*sin(th));
      float d=length(vec3(xy-P, h));
      e+=ocol*(exp(-d*80.0)*5.0+exp(-d*18.0)*0.35);
      float te=float(i)*2.1+so.x; vec2 Pe=vec2(a*cos(te), b*sin(te));
      float de=length(vec3(xy-Pe, h));
      e+=mix(uC3,vec3(1.0),0.3)*(exp(-de*60.0)*30.0+exp(-de*14.0)*2.0);
    }
    float dn=9.0, kk=0.0; vec3 cb=vec3(0.0);
    for(int i=0;i<7;i++){ float fi=float(i); vec3 c=(vec3(h31(so+fi*1.3),h31(so+fi*2.9),h31(so+fi*4.1))-0.5)*0.16;
      float dd=length(q-c)-0.07; if(dd<dn){ dn=dd; kk=fi; cb=c; } }
    e+=mix(uC2,uC3,0.5)*exp(-max(dn,0.0)*12.0)*1.2;
    if(dn<0.0){ vec3 nc=mod(kk,3.0)<1.0?uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.4):(mod(kk,3.0)<2.0?uC2:uC3);
      float sh=0.5+0.6*clamp(dot(normalize(q-cb),normalize(vec3(-0.5,0.6,0.6))),0.0,1.0);
      e+=nc*0.5; return vec4(nc*sh, 600.0); }
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.975,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0*step(0.6,r);
    return vec4(uC1*0.1, 0.45);
  }
#elif MODE==87
  { // constellation : les étoiles d'une vraie constellation (la Grande Ourse, Cassiopée ou Orion) reliées par des traits de lumière
    float r=length(q); e=vec3(0.0);
    vec2 P0,P1,P2,P3,P4,P5,P6,X0,X1; float nc=7.0; float hc=h31(so+0.7);
    if(hc<0.34){   // la Grande Ourse (la casserole)
      P0=vec2(-0.66,0.3); P1=vec2(-0.42,0.25); P2=vec2(-0.2,0.15); P3=vec2(0.0,0.06); P4=vec2(0.06,-0.2); P5=vec2(0.4,-0.18); P6=vec2(0.44,0.08); X0=P6; X1=P3;
    } else if(hc<0.67){   // Cassiopée (le W)
      P0=vec2(-0.6,0.12); P1=vec2(-0.3,-0.2); P2=vec2(0.0,0.02); P3=vec2(0.28,-0.24); P4=vec2(0.58,0.08); P5=P4; P6=P4; nc=5.0; X0=P4; X1=P4;
    } else {   // Orion : les épaules, la ceinture, les pieds
      P0=vec2(-0.3,-0.55); P1=vec2(-0.12,-0.04); P2=vec2(-0.28,0.48); P3=vec2(0.3,0.42); P4=vec2(0.14,0.04); P5=vec2(0.32,-0.5); P6=vec2(0.01,0.0); X0=P1; X1=P4; nc=6.0;
    }
    float zp=0.25; float dl=9.0, ds=9.0;
    for(int i=0;i<7;i++){ float fi=float(i);
      vec2 A=i==0?P0:(i==1?P1:(i==2?P2:(i==3?P3:(i==4?P4:(i==5?P5:P6)))));
      vec2 B=i==0?P1:(i==1?P2:(i==2?P3:(i==3?P4:(i==4?P5:P6))));
      ds=min(ds,length(q-vec3(A,zp)));
      if(fi<nc-1.0){ vec3 a=vec3(A,zp), b=vec3(B,zp), pa=q-a, ba=b-a; dl=min(dl,length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0))); }
    }
    { vec3 a=vec3(X0,zp), b=vec3(X1,zp), pa=q-a, ba=b-a; if(dot(ba,ba)>1e-4) dl=min(dl,length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0))); }
    vec3 lc=mix(uC2,vec3(0.8,0.9,1.0),0.4), sc=mix(uC3,vec3(1.0),0.45);
    e+=lc*(exp(-dl*110.0)*3.5+exp(-dl*25.0)*0.25);
    e+=sc*(exp(-ds*70.0)*40.0+exp(-ds*16.0)*2.5);
    // la Voie lactée en fond, et beaucoup de petites étoiles
    float mw=smoothstep(0.45,0.0,abs(q.y-0.55*q.x+0.1+0.15*fbm(q*2.0+so)))*fbm(q*5.0+so+3.0);
    e+=mix(uC2,uC3,0.5)*mw*0.8*smoothstep(0.95,0.6,r);
    vec3 g=q*17.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.965,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0;
    return vec4(uC1*0.1, 0.45);
  }
#elif MODE==88
  { // losanges : le motif des chaussettes écossaises, des losanges de deux couleurs et de fins traits d'une 3e
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(1.3+nb*0.2)+so.xy;
    float a=p.x+p.y, b=p.x-p.y; vec3 c=mod(floor(a)+floor(b),2.0)<1.0?uC1:uC2;
    float la=abs(fract(a)-0.5), lb=abs(fract(b)-0.5);
    float dash=step(0.5,fract((a+b)*3.0));
    c=mix(c,uC3,smoothstep(0.055,0.03,min(la,lb))*dash);
    return vec4(c, 200.0);
  }
#elif MODE==89
  { // marinière : de fines rayures bien droites, avec une rayure d'une autre couleur de temps en temps et un liseré
    vec3 u=normalize(q); float y=u.y*(10.0+nb)+so.x;
    float fy=fract(y), m=mod(floor(y),5.0);
    vec3 c=fy<0.42?(m<0.5?uC2:uC1):vec3(0.97,0.96,0.93);
    c=mix(c,uC3,smoothstep(0.035,0.015,abs(fy-0.71)));
    c*=mix(0.88,1.0,smoothstep(0.0,0.05,min(abs(fy),abs(fy-0.42))));
    return vec4(c, 200.0);
  }
#elif MODE==90
  { // triangles : un pavage de triangles, chacun d'une des 3 couleurs (ou blanc), séparés par un fin joint
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.0+nb*0.3)+so.xy;
    vec2 s=vec2(p.x+p.y*0.57735, p.y*1.1547); vec2 id=floor(s), f=fract(s); float up=step(1.0,f.x+f.y);
    float k=h31(vec3(id,up+cf.w*3.0+so.z));
    vec3 c=k<0.3?uC1:(k<0.6?uC2:(k<0.85?uC3:vec3(0.97,0.96,0.93)));
    float ed=min(min(f.x,f.y),abs(1.0-f.x-f.y)*0.7071);
    c*=mix(0.6,1.0,smoothstep(0.015,0.04,ed));
    return vec4(c, 200.0);
  }
#elif MODE==91
  { // cahier : la page d'un cahier d'écolier, ses lignes (les fines et les grosses), ses colonnes et la marge
    vec3 u=normalize(q); vec4 cf=cubeF(u); float hy=cf.y*(9.0+nb)+so.x;
    float dy=abs(fract(hy+0.5)-0.5), main=step(mod(floor(hy+0.5),4.0),0.5);
    vec3 c=mix(vec3(0.99,0.98,0.95),uC3,0.12);
    c=mix(c,mix(uC2,vec3(1.0),0.55),smoothstep(0.08,0.03,dy)*(1.0-main));
    c=mix(c,uC2*0.85,smoothstep(0.1,0.04,dy)*main);
    float vx=cf.x*(9.0+nb)*0.25+so.y, dx=abs(fract(vx+0.5)-0.5)*4.0;
    c=mix(c,uC2*0.85,smoothstep(0.1,0.04,dx));
    c=mix(c,uC1,smoothstep(0.03,0.015,abs(cf.x+0.62))*step(mod(cf.w,2.0),0.5));   // la marge, sur une face sur deux
    return vec4(c, 200.0);
  }
#elif MODE==92
  { // rosace : des couronnes de pétales autour du centre, une couleur par couronne
    vec3 u=normalize(q); float th=acos(clamp(abs(u.z),0.0,1.0)), ph=atan(u.y,u.x);
    float rf=th*(2.4+nb*0.3), ri=floor(rf), fr=fract(rf);
    float n=4.0+ri*5.0; float pa=abs(fract(ph/6.2831853*n+ri*0.5)-0.5)*2.0;
    float w=sin(fr*3.14159)*0.92;
    float pet=smoothstep(0.04,-0.02,pa-w);
    float m=mod(ri,3.0); vec3 pc=m<1.0?uC1:(m<2.0?uC2:uC3);
    vec3 c=mix(vec3(0.97,0.95,0.9),pc*(0.78+0.3*(1.0-pa)),pet);
    c=mix(c,uC3,smoothstep(0.17,0.15,th));
    return vec4(c, 200.0);
  }
#elif MODE==93
  { // agrume : une tranche d'orange (ou de citron, selon le coloris) de chaque côté, et la peau tout autour
    vec3 u=normalize(q); float th=acos(clamp(abs(u.z),0.0,1.0)), ph=atan(u.y,u.x);
    vec3 peel=uC1*(0.85+0.2*noise(u*45.0+so));
    vec3 c=peel;
    if(th<1.05){
      float seg=abs(fract(ph/6.2831853*10.0+so.x)-0.5);
      vec3 flesh=mix(uC2,uC3,0.3+0.5*noise(vec3(ph*20.0,th*30.0,so.y)))*(0.85+0.2*smoothstep(0.5,1.0,noise(vec3(ph*40.0,th*60.0,so.z))));
      c=flesh;
      c=mix(c,vec3(0.98,0.96,0.88),smoothstep(0.035,0.015,seg*th*2.0+0.0)*step(0.08,th));   // les fines peaux entre les quartiers
      c=mix(c,vec3(0.98,0.96,0.88),smoothstep(0.1,0.06,th));
      c=mix(c,vec3(0.98,0.96,0.88),smoothstep(0.9,0.95,th));   // le blanc sous la peau
    }
    return vec4(c, 200.0);
  }
#elif MODE==94
  { // vichy : le carreau des nappes de pique-nique, en 3 couleurs, avec la trame du tissu
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.2+nb*0.3)+so.xy;
    float sx=step(fract(p.x),0.5), sy=step(fract(p.y),0.5);
    vec3 c=sx*sy>0.5?uC1:(sx+sy>0.5?uC2:mix(uC3,vec3(1.0),0.55));
    c*=0.92+0.1*step(0.5,fract((p.x+p.y)*28.0));
    return vec4(c, 200.0);
  }
#elif MODE==95
  { // spirales : de petites spirales (des coquilles d'escargot) semées sur un fond clair
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.65);
    for(int i=0;i<2;i++){ vec3 g=u*1.8+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*23.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float L=length(p), a=atan(p.y,p.x)+h31(id+5.0)*6.2831853;
      float on=step(0.2,h31(id))*step(abs(dot(f,u)),0.22), sz=0.22+0.07*h31(id+3.0);
      float sp=fract(L/sz*3.0-a/6.2831853);
      float line=smoothstep(0.32,0.2,abs(sp-0.5))*step(L,sz)*on;
      c=mix(c,h31(id+2.0)<0.55?uC1:uC2,line); }
    return vec4(c, 200.0);
  }
#elif MODE==96
  { // gouttes : des gouttes de pluie de deux couleurs, chacune avec son reflet, sur un fond clair
    vec3 u=normalize(q); vec3 t1=normalize(cross(vec3(0.0,1.0,0.013),u)), t2=cross(u,t1);
    vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.7);
    for(int i=0;i<2;i++){ vec3 g=u*2.0+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*19.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float on=step(0.25,h31(id))*step(abs(dot(f,u)),0.22), sz=0.14+0.05*h31(id+3.0);
      p/=sz; float L=length(p);
      float drop=p.y<0.0?step(L,1.0):step(abs(p.x),pow(max(0.0,1.0-p.y/1.9),1.3)*(1.0+0.5*p.y));
      drop*=step(p.y,1.9)*on;
      vec3 dc=h31(id+2.0)<0.55?uC1:uC2;
      dc=mix(dc,vec3(1.0),smoothstep(0.3,0.15,length(p-vec2(-0.35,-0.1)))*0.7);   // le reflet
      c=mix(c,dc,drop); }
    return vec4(c, 200.0);
  }
#elif MODE==97
  { // éventails : des rangées d'éventails ronds qui se chevauchent, cerclés de couleurs, comme les vagues japonaises
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.2+nb*0.3)+so.xy;
    vec3 c=uC1; p=cf.xy*(1.3+nb*0.2)+so.xy;
    for(int j=1;j>=-1;j--){ float row=floor(p.y*2.0)+float(j); float x0=mod(row,2.0)*0.5;
      float kx=floor(p.x-x0+0.5); vec2 C=vec2(kx+x0,row*0.5); float L=length(p-C);
      if(L<0.5){ float ri=floor(L*8.0); float k=h31(vec3(kx,row,cf.w+so.x));
        vec3 pc=k<0.34?uC1:(k<0.67?uC2:uC3);
        c=mod(ri,2.0)<1.0?pc:mix(pc,vec3(0.98,0.97,0.94),0.75);
        c*=mix(0.55,1.0,smoothstep(0.5,0.47,L)); } }
    return vec4(c, 200.0);
  }
#elif MODE==98
  { // shérif : une grande étoile au milieu, cerclée d'anneaux, de chaque côté : l'insigne du shérif de la cour
    vec3 u=normalize(q); float th=acos(clamp(abs(u.z),0.0,1.0));
    vec3 c=uC2;
    c=th<1.02?uC1:c; c=th<0.86?vec3(0.97,0.96,0.93):c; c=th<0.7?uC1:c; c=th<0.56?uC2:c;
    float st=sdStar(u.xy*1.8);
    c=mix(c,mix(uC3,vec3(1.0),0.1),smoothstep(0.02,-0.02,st));
    c*=mix(0.7,1.0,smoothstep(0.0,0.03,abs(st)));
    float rr=min(min(abs(th-1.02),abs(th-0.86)),min(abs(th-0.7),abs(th-0.56)));
    c*=mix(0.75,1.0,smoothstep(0.0,0.012,rr));
    return vec4(c, 200.0);
  }
#elif MODE==99
  { // foot : le ballon de foot, ses 12 pentagones et ses 20 hexagones bien cousus
    vec3 u=normalize(q); float d1=-2.0, d2=-2.0, pent=0.0;
    float ph=1.618034, ip=0.618034;
    for(int k=0;k<3;k++) for(int s1=0;s1<2;s1++) for(int s2=0;s2<2;s2++){
      float a=s1==0?1.0:-1.0, b=s2==0?1.0:-1.0;
      vec3 v=vec3(0.0,a,b*ph); v=k==0?v:(k==1?v.zxy:v.yzx);   // les sommets de l'icosaèdre : les pentagones
      float d=dot(u,normalize(v)); if(d>d1){ d2=d1; d1=d; pent=1.0; } else if(d>d2) d2=d;
      vec3 w=vec3(0.0,a*ph,b*ip); w=k==0?w:(k==1?w.zxy:w.yzx);   // ceux du dodécaèdre : les hexagones
      d=dot(u,normalize(w)); if(d>d1){ d2=d1; d1=d; pent=0.0; } else if(d>d2) d2=d; }
    for(int s=0;s<8;s++){ vec3 v=vec3(mod(float(s),2.0)<1.0?1.0:-1.0, mod(floor(float(s)/2.0),2.0)<1.0?1.0:-1.0, s<4?1.0:-1.0);
      float d=dot(u,normalize(v)); if(d>d1){ d2=d1; d1=d; pent=0.0; } else if(d>d2) d2=d; }
    vec3 c=pent>0.5?uC1:mix(uC3,vec3(0.97,0.96,0.93),0.55);
    float seam=d1-d2;
    c*=mix(0.8,1.0,smoothstep(0.0,0.03,seam));
    c=mix(uC2,c,smoothstep(0.004,0.01,seam));
    return vec4(c, 200.0);
  }
#elif MODE==100
  { // origami : du papier plié en mille facettes, chacune prend la lumière à sa façon
    vec3 u=normalize(q); vec3 g=u*(2.6+nb*0.3)+so; vec3 i0=floor(g), f0=fract(g);
    float d1=9.0, d2=9.0; vec3 cid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
      vec3 pt=o+0.1+0.8*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
      if(d<d1){ d2=d1; d1=d; cid=i0+o; } else if(d<d2) d2=d; }
    float k=h31(cid+4.0); vec3 c=k<0.4?uC1:(k<0.75?uC2:uC3);
    c*=0.62+0.5*h31(cid+9.0);   // chaque facette, plus ou moins éclairée
    c=mix(c*0.8,c,smoothstep(0.0,0.025,d2-d1));
    return vec4(c, 200.0);
  }
#elif MODE==101
  { // bonbecs : des bonbons dans leur papier tortillé, rayés, éparpillés sur la bille
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 c=vec3(0.97,0.95,0.91);
    for(int i=0;i<2;i++){ vec3 g=u*1.5+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*13.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float a=h31(id+5.0)*6.2831853; p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
      float on=step(0.15,h31(id))*step(abs(dot(f,u)),0.22); p/=1.55;
      float body=step(length(p*vec2(1.0,1.55)),0.15);
      float ax=abs(p.x), wrap=step(0.12,ax)*step(ax,0.29)*step(abs(p.y),(ax-0.1)*0.85);
      float k=h31(id+2.0); vec3 bc=k<0.34?uC1:(k<0.67?uC2:uC3), sc=k<0.34?uC3:(k<0.67?uC1:uC2);
      vec3 cc=mix(bc,sc,step(0.5,fract((p.x+p.y)*16.0))*0.85);
      cc*=0.75+0.35*smoothstep(0.15,0.0,length(p*vec2(1.0,1.55)-vec2(-0.03,0.03)));
      vec3 wc=mix(bc,vec3(1.0),0.45)*(0.8+0.2*step(0.5,fract(atan(p.y,ax-0.11)*5.0)));   // les plis du papier
      c=mix(c,wc,wrap*on); c=mix(c,cc,body*on); }
    return vec4(c, 200.0);
  }
#elif MODE==102
  { // pop : des points de trame de BD, gros et petits, en deux couleurs sur un fond d'une 3e
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec3 c=mix(uC3,vec3(1.0),0.5);
    for(int i=0;i<2;i++){ float an=float(i)*0.65; vec2 p=cf.xy*(5.0+nb); p=vec2(cos(an)*p.x-sin(an)*p.y, sin(an)*p.x+cos(an)*p.y);
      vec2 f=fract(p)-0.5; float v=smoothstep(0.38,0.68,fbm(u*1.7+so+float(i)*9.0));
      float rad=0.5*sqrt(v); float dt=smoothstep(rad,rad-0.07,length(f));
      c=mix(c,i==0?uC1:uC2,dt*(i==1?0.9:1.0)); }
    return vec4(c, 200.0);
  }
#elif MODE==103
  { // galets : des cailloux de rivière bien ronds et polis, serrés les uns contre les autres
    vec3 u=normalize(q); vec3 g=u*(3.4+nb*0.3)+so; vec3 i0=floor(g), f0=fract(g);
    float d1=9.0, d2=9.0; vec3 cid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
      vec3 pt=o+0.15+0.7*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
      if(d<d1){ d2=d1; d1=d; cid=i0+o; } else if(d<d2) d2=d; }
    float ed=d2-d1, k=h31(cid+4.0);
    vec3 st=(k<0.34?uC1:(k<0.67?uC2:uC3));
    st=mix(st,vec3(0.6,0.58,0.55),0.3)*(0.85+0.2*noise(g*7.0));
    st*=0.55+0.6*smoothstep(0.0,0.35,ed);   // bombé : plus clair au milieu
    return vec4(mix(uC1*0.18,st,smoothstep(0.03,0.08,ed)), 200.0);
  }
#elif MODE==104
  { // pâte à modeler : trois boudins de pâte de couleur roulés ensemble, marbrés en volutes
    vec3 u=normalize(q);
    vec3 w=u*1.6+so; w+=2.2*vec3(fbm(w),fbm(w+5.2),fbm(w+9.7));
    float v=dot(w,vec3(0.8,1.6,0.5))*2.2;
    float m=mod(floor(v),3.0), fv=fract(v);
    vec3 c=m<1.0?uC1:(m<2.0?uC2:uC3);
    vec3 c2=m<1.0?uC2:(m<2.0?uC3:uC1);
    c=mix(c,c2,smoothstep(0.85,1.0,fv));
    c*=0.92+0.1*noise(u*60.0+so);   // la trace des doigts
    return vec4(c, 200.0);
  }
#elif MODE==105
  { // tableau noir : l'ardoise de la classe, pleine de gribouillis à la craie de couleur
    vec3 u=normalize(q);
    vec3 c=mix(uC1*0.35,vec3(0.07,0.14,0.1),0.55)*(0.85+0.25*fbm(u*3.0+so));   // l'ardoise, avec des traces d'éponge
    float lines=0.0; vec3 lcol=vec3(0.0);
    for(int i=0;i<3;i++){ float fi=float(i);
      float n=fbm(u*(1.6+fi*0.5)+so+fi*7.0)*(2.6+fi*0.6);
      float l=smoothstep(0.075,0.035,0.5-abs(fract(n)-0.5))*step(0.45,noise(u*2.5+so+fi*3.0));
      vec3 cc=i==0?vec3(0.96):(i==1?mix(uC2,vec3(1.0),0.3):mix(uC3,vec3(1.0),0.3));
      lcol=mix(lcol,cc,l); lines=max(lines,l); }
    lines*=0.7+0.3*step(0.35,noise(u*160.0+so));   // la craie accroche mal : un trait un peu poudreux
    return vec4(mix(c,lcol,lines), 200.0);
  }
#elif MODE==106
  { // opale : une pierre laiteuse où s'allument des éclats de couleur selon l'endroit où on regarde
    float r=length(q); vec3 g=q*3.6+so; vec3 i0=floor(g), f0=fract(g);
    float d1=9.0; vec3 cid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
      vec3 pt=o+0.15+0.7*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
      if(d<d1){ d1=d; cid=i0+o; } }
    float k=h31(cid+4.0); vec3 fc=k<0.34?uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.4):(k<0.67?uC2:uC3);
    fc=mix(fc,0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+k*2.0)),0.25);
    float fl=smoothstep(0.45,0.85,noise(q*8.0+cid*3.0))*smoothstep(0.92,0.55,r);
    e=fc*fl*4.0;
    return vec4(mix(vec3(0.9,0.9,0.94),uC1,0.35), 0.9);
  }
#elif MODE==107
  { // malachite : une pierre aux bandes rondes serrées, du plus foncé au plus clair, en 3 couleurs
    vec3 u=normalize(q); vec3 g=u*1.7+so; vec3 i0=floor(g), f0=fract(g);
    float d1=9.0;
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
      vec3 pt=o+0.15+0.7*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); d1=min(d1,length(pt-f0)); }
    float v=d1*9.0+0.8*fbm(u*4.0+so);
    float m=mod(floor(v),3.0), b=fract(v);
    vec3 c=m<1.0?uC1:(m<2.0?uC2:uC3);
    c*=0.7+0.4*smoothstep(0.0,0.6,b);
    c*=0.94+0.06*sin(v*70.0);   // les fines fibres de la pierre
    return vec4(c, 200.0);
  }
#elif MODE==108
  { // encre : trois gouttes d'encre qui se déploient en volutes dans un verre d'eau claire
    float r=length(q);
    vec3 w=q+0.25*vec3(fbm(q*2.0+so),fbm(q*2.0+so+3.0),fbm(q*2.0+so+6.0));
    float a=smoothstep(0.55,0.75,fbm(w*2.2+so)), b=smoothstep(0.58,0.78,fbm(w*2.4+so+20.0)), c=smoothstep(0.6,0.8,fbm(w*2.6+so+40.0));
    float inside=smoothstep(0.93,0.8,r);
    float s=a+b+c; vec3 col=(uC1*a+uC2*b+uC3*c)/max(s,1e-3);
    e=(uC2*b+uC3*c)*0.15*inside;
    return vec4(s>0.01?col:vec3(0.92,0.96,1.0), 0.12+s*3.5*inside);
  }
#elif MODE==109
  { // ammonite : un coquillage fossile enroulé en spirale, de chaque côté, pris dans la pierre
    vec3 u=normalize(q); float th=acos(clamp(abs(u.z),0.0,1.0)), ph=atan(u.y,u.x)*(u.z>0.0?1.0:-1.0);
    vec3 c=mix(uC1,vec3(0.55,0.52,0.48),0.55)*(0.8+0.3*noise(u*30.0+so));
    float R=1.05;
    if(th<R){ float kk=0.3; float s=log(max(th,1e-3)/R)/(kk*6.2831853)+ph/6.2831853; float w=fract(s);
      float sep=abs(fract(ph/6.2831853*16.0+0.12*sin(w*18.0))-0.5);
      vec3 sh=mix(uC3,uC2,w)*(0.6+0.55*sin(w*3.14159));
      sh=mix(uC1*0.5,sh,smoothstep(0.0,0.06,w)*smoothstep(1.0,0.94,w));
      sh=mix(uC1*0.6,sh,smoothstep(0.015,0.04,sep*th*3.0));
      c=mix(c,sh,smoothstep(R,R-0.03,th)); }
    return vec4(c, 200.0);
  }
#elif MODE==110
  { // holographique : une carte à collectionner holographique, ses arcs de couleur bougent quand on la tourne
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(7.0+nb);
    vec2 f=fract(p)-0.5; float sp=smoothstep(0.03,0.0,abs(sdStar(f*2.4))/2.4)*step(0.6,h31(vec3(floor(p),cf.w)));
    vec3 c=mix(uC1,uC2,0.5+0.5*sin(dot(u,vec3(3.0,5.0,2.0))+so.x));
    return vec4(mix(c,uC3,sp), 200.0);
  }
#elif MODE==111
  { // montgolfière : un ballon à fuseaux de 3 couleurs dans un ciel de nuages, avec sa nacelle et la flamme du brûleur
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6));
    vec3 p=q-vec3(0.0,0.1,0.0); float y=p.y, rho=length(p.xz);
    float rr=y>0.0?0.33*sqrt(max(0.0,1.0-pow(y/0.36,2.0))):0.33*pow(max(0.0,1.0-pow(-y/0.4,1.4)),0.9)+0.04*step(-0.4,y);
    float env=step(rho,rr)*step(-0.4,y)*step(y,0.36);
    vec3 cl=vec3(0.0);
    if(env>0.5){ float ga=atan(p.z,p.x)/6.2831853*12.0; float m=mod(floor(ga),3.0);
      vec3 gc=m<1.0?uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.5):(m<2.0?uC2:uC3);
      vec3 nn=normalize(vec3(p.x,p.y*0.6,p.z)); float sh=0.45+0.7*clamp(dot(nn,L),0.0,1.0);
      gc*=mix(0.75,1.0,smoothstep(0.0,0.06,abs(fract(ga)-0.5)*2.0*0.5+0.0));
      return vec4(gc*sh, 400.0); }
    // la nacelle et ses cordes
    vec3 bq=q-vec3(0.0,-0.43,0.0);
    if(max(max(abs(bq.x),abs(bq.z))-0.065,abs(bq.y)-0.05)<0.0) return vec4(vec3(0.45,0.28,0.12)*(0.8+0.3*step(0.5,fract(bq.y*30.0))), 400.0);
    vec2 cxz=abs(q.xz)-vec2(0.05); if(length(cxz)<0.008 && q.y>-0.39 && q.y<-0.3) return vec4(vec3(0.25,0.18,0.1), 400.0);
    e=mix(uC3,vec3(1.0,0.75,0.3),0.5)*exp(-length(q-vec3(0.0,-0.33,0.0))*30.0)*4.0;   // la flamme
    float cloud=smoothstep(0.58,0.72,fbm(q*2.6+so))*smoothstep(0.95,0.75,r);
    return vec4(mix(mix(vec3(0.7,0.85,1.0),uC2,0.15),vec3(1.0),cloud), 0.25+cloud*3.0);
  }
#elif MODE==112
  { // fusée : une petite fusée qui décolle dans un verre de nuit, sa flamme et sa fumée derrière elle
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6));
    float ca=cos(0.4), sa=sin(0.4); vec2 pr=vec2(ca*q.x-sa*q.y, sa*q.x+ca*q.y); float y=pr.y; float rho=length(vec2(pr.x,q.z));
    float body=step(-0.25,y)*step(y,0.28)*step(rho,0.12);
    float nose=step(0.28,y)*step(y,0.5)*step(rho,0.12*(1.0-pow((y-0.28)/0.22,1.6)));
    float fins=step(-0.33,y)*step(y,-0.08)*step(rho,0.12+0.13*clamp((-0.08-y)/0.25,0.0,1.0))*step(min(abs(pr.x),abs(q.z)),0.016);
    vec3 nn=normalize(vec3(pr.x,0.0,q.z)+vec3(0.0,0.001,0.0)); float sh=0.45+0.7*clamp(dot(vec3(ca*nn.x+sa*nn.y,-sa*nn.x+ca*nn.y,nn.z),L),0.0,1.0);
    if(body+nose+fins>0.5){
      vec3 c=vec3(0.95,0.94,0.92);
      c=mix(c,uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.5),step(abs(y+0.05),0.035));
      c=nose>0.5||fins>0.5?uC2:c;
      float win=length(vec2(pr.x,y-0.12));
      if(q.z>0.0 && win<0.055){ c=win<0.04?mix(uC3,vec3(1.0),0.3):uC1*0.6; e=c*0.6; }
      return vec4(c*sh, 400.0); }
    float fy=-0.27-y; float fl=step(0.0,fy)*smoothstep(0.09*(1.0-fy/0.45),0.0,rho)*step(fy,0.45);
    float flick=0.85+0.15*sin(fy*30.0+so.x);
    e=mix(vec3(1.0,0.95,0.8),uC3,smoothstep(0.0,0.3,fy))*fl*8.0*flick;
    float smoke=smoothstep(0.55,0.75,fbm(q*3.0+so))*smoothstep(-0.3,-0.75,y)*smoothstep(0.95,0.8,r);
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*6.0*step(0.55,r);
    return vec4(mix(uC1*0.1,vec3(0.6),smoke), 0.45+smoke*2.0);
  }
#elif MODE==113
  { // éclipse : la Lune passe devant le Soleil ; il ne reste qu'un disque noir entouré de sa couronne de feu
    float r=length(q); vec3 dir=q/max(r,1e-4);
    float R=0.3;
    if(r<R) return vec4(vec3(0.0), 1000.0);
    float ang=atan(dir.y,dir.x);
    float str=0.55+0.45*noise(vec3(ang*7.0,dir.z*7.0,so.x))+0.35*pow(noise(vec3(ang*22.0,dir.z*22.0,so.y)),3.0);
    float r2=length(q.xy); float cor=exp(-max(r2-R,0.0)*(13.0/(str*str)))*smoothstep(R*0.98,R*1.02,r2)*smoothstep(0.75,0.6,r);
    e=mix(mix(vec3(1.0),uC3,0.3),uC2,smoothstep(0.0,0.25,r2-R))*cor*2.2;
    vec2 dr=vec2(cos(0.8),sin(0.8))*R*1.02;   // la bague de diamant : le dernier rayon de soleil
    e+=mix(vec3(1.0),uC3,0.2)*exp(-length(q-vec3(dr,0.08))*35.0)*14.0;
    float prom=smoothstep(0.05,0.0,r-R-0.015*sin(ang*9.0+so.x)*step(0.6,noise(vec3(ang*4.0,so.z,1.0))))*step(R,r);
    e+=uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.4)*prom*5.0;   // les protubérances, de la 1re couleur
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*6.0*step(0.6,r);
    return vec4(uC1*0.08, 0.45);
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

// pièce reflétée par le métal : ciel doux, sol, horizon adouci, et une grande lampe floue (plus de fenêtre rectangulaire : 3 octobre 2026)
vec3 chrome(vec3 r){
  vec3 sky=mix(vec3(0.62,0.66,0.72),vec3(0.98,0.99,1.0),smoothstep(0.05,0.9,r.y));
  vec3 flo=mix(vec3(0.46,0.42,0.38),vec3(0.24,0.22,0.21),smoothstep(-0.05,-0.9,r.y));
  vec3 c=mix(flo,sky,smoothstep(-0.22,0.22,r.y));
  c*=1.0-0.25*smoothstep(0.1,0.0,abs(r.y+0.12));
  vec2 w=vec2(r.x+0.42,r.y-0.5);
  float front=smoothstep(-0.1,0.35,r.z);
  c+=(exp(-dot(w,w)*7.0)*0.75+exp(-dot(w,w)*40.0)*0.35)*front;   // la lampe : un halo rond, plus clair au centre
  c+=exp(-pow(r.x-0.6,2.0)*14.0-pow(r.y-0.1,2.0)*3.0)*front*0.18;   // une lumière douce de l'autre côté
  return c;
}
vec3 env(vec3 r, float soft){   // soft : 0 = reflet net à la surface, 1 = vu à travers le verre (flou)
  vec3 sky=mix(vec3(0.96,0.93,0.87),vec3(1.0,0.99,0.96),clamp(r.y,0.0,1.0));
  vec3 flo=mix(vec3(0.6,0.48,0.36),vec3(0.86,0.78,0.66),clamp(r.y+1.0,0.0,1.0));
  vec3 c=mix(flo,sky,smoothstep(-0.08,0.08,r.y));
  vec2 w=vec2(r.x+0.42,r.y-0.5);
  // la lampe qui se reflète : un halo rond et flou (plus de fenêtre rectangulaire), discret : le point de lumière fait le reflet
  c+=exp(-dot(w,w)*(9.0-5.0*soft))*smoothstep(-0.1,0.35,r.z)*(0.32-0.16*soft);
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
    // même sens de rotation que les billes rondes (le signe de r.z était inversé : elle tournait à l'envers sous la souris)
    // (6 octobre 2026) sans atan : sur les cartes NVIDIA (Direct3D), atan(-0.0, 1.0) donnait un demi-tour et la pépite s'affichait à l'envers
    vec3 r=uRot*vec3(1.0,0.0,0.0); vec2 yw=vec2(r.x,-r.z); float yl=length(yw); YW=yl>1e-5 ? yw/yl : vec2(1.0,0.0);
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
  vec3 refl=env(rv,0.0);
  float sp=max(dot(rv,L),0.0);
  // reflet : un point net et un halo doux (plus de tache blanche écrasée quand on agrandit la bille)
  float spec=pow(sp,320.0)*1.7+pow(sp,48.0)*0.2+pow(sp,10.0)*0.05;
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
#elif MODE==76
    { float m=cuivreM(qs); vec3 cu=mix(vec3(0.97,0.56,0.33),uC3,0.2);
      vec3 met=chrome(rv)*cu*(0.92+0.1*noise(qo*35.0))*(0.7+0.3*n.z)+spec*1.4*cu;
      col=mix(met,base*(0.4+0.65*dif)+refl*F*0.1+spec*0.15,m); }
#elif MODE==80
    { vec3 m=meteo(qs);
      vec3 met=chrome(rv)*vec3(0.82-0.4*m.y)*mix(vec3(1.0),uC2,0.12)*(0.7+0.3*n.z)+spec*1.3;
      col=mix(met,base*(0.5+0.6*dif)+base*0.25+refl*F*0.5+spec*0.9,m.x); }
#elif MODE==110
    { float k=fract((1.0-n.z)*1.6+qs.x*0.8+qs.y*0.5)*3.0;   // l'arc de couleurs glisse avec l'angle : les 3 couleurs du coloris, et un peu d'arc-en-ciel
      vec3 hc=k<1.0?mix(uC1,uC2,k):(k<2.0?mix(uC2,uC3,k-1.0):mix(uC3,uC1,k-2.0));
      hc=mix(hc,0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+k*0.5)),0.3);
      col=mix(col,hc*(0.6+0.55*dif)+base*0.25+refl*F*0.5+spec*1.2,0.7); }
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
    // le Pirate a une figure fine au cœur du verre : plus de pas pour qu'elle reste nette (les autres motifs gardent 30 pas)
#if MODE==49
    const int GSTEPS=96;   // le Prisme : des faces nettes, sans grain (pas réguliers)
    float jit=0.5;
#elif MODE==32 || MODE==48 || MODE==50 || MODE==51 || MODE==61 || MODE==63 || MODE==64 || MODE>=78
    const int GSTEPS=64;
    float jit=fract(sin(dot(gl_FragCoord.xy,vec2(12.9898,78.233)))*43758.5453);   // pas décalés d'un pixel à l'autre : pas de stries
#else
    const int GSTEPS=30;
    float jit=0.5;
#endif
    float dt=tEx/float(GSTEPS);
    vec3 acc=vec3(0.0); float T=1.0;
    for(int i=0;i<GSTEPS;i++){
      vec3 p=P+d*(float(i)+jit)*dt;
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
    vec3 bg=env(d2,1.0)*pow(max(uTint,vec3(0.02)),vec3(tEx*1.2));
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
    // irisée : un vernis arc-en-ciel en dégradé lisse, comme une bulle de savon. Les couleurs suivent une diagonale de la bille
    // (qui tourne avec elle) et glissent avec l'angle de vue : le bord change de couleur quand la bille bouge.
    vec3 ax=normalize(vec3(0.55,0.8,0.25)+(uSeed.xyz-0.5)*0.7);
    float hue=dot(qo,ax)*0.45+(1.0-n.z)*0.55+uSeed.w+0.04*sin(dot(qo,ax.zxy)*3.0);
    vec3 rb=0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+hue));
    rb=mix(rb,vec3(1.0),0.18);                      // des tons pastel, lumineux
    // le coloris reste lisible au centre : l'arc-en-ciel se pose surtout sur le pourtour
    float rim=smoothstep(0.25,0.95,1.0-n.z);
    col=mix(col,col*0.6+rb*0.5,0.1+0.45*rim);
    col+=rb*(F*1.4+0.02);
    col+=rb*pow(max(dot(reflect(d0,n),L),0.0),6.0)*0.25;   // un reflet coloré autour du point de lumière
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
    // lumineuse : elle s'éclaire de l'intérieur, dans la couleur de son coloris (sans taches), et respire doucement
    float pulse=0.85+0.15*sin(uTime*1.6);
    col+=uC2*0.18*pulse;                                                     // une lueur intérieure, de sa couleur
    col+=mix(uC2,vec3(1.0),0.25)*0.5*pow(1.0-n.z,2.2)*pulse;                 // le bord rayonne (le grand halo est fait autour, en CSS)   // le bord rayonne (le grand halo est fait autour, en CSS : le motif reste lisible)
  }
  col*=mix(0.8,1.0,smoothstep(0.0,0.35,n.z));
  // les blancs s'arrondissent au lieu d'être coupés net (sinon un anneau dur autour des reflets)
  vec3 hi=max(col-0.82,0.0); col=min(col,0.82)+0.18*(1.0-exp(-hi/0.18));
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
  use(mode,opaque,hero=0){
    const gl=this.gl, key=mode*2+opaque+hero*1000;
    let p=this.progs.get(key);
    if(!p){
      const sh=(t,src)=>{const o=gl.createShader(t);gl.shaderSource(o,src);gl.compileShader(o);if(!gl.getShaderParameter(o,gl.COMPILE_STATUS))throw new Error(gl.getShaderInfoLog(o));return o};
      const pr=gl.createProgram();
      gl.attachShader(pr,sh(gl.VERTEX_SHADER,"attribute vec2 p;void main(){gl_Position=vec4(p,0.0,1.0);}"));
      gl.attachShader(pr,sh(gl.FRAGMENT_SHADER,`#define MODE ${mode}
#define OPAQUE ${opaque}
#define HERO ${hero}
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
  draw(s,size,rot=I3,time){   // time : le moment de l'animation (sinon l'heure), pour les images du motif mythique
    const gl=this.gl,P=specParams(s),u=this.use(P.mode,P.opaque,P.hero);
    if(this.cv.width!==size||this.cv.height!==size){this.cv.width=this.cv.height=size}   // (10 octobre 2026) la hauteur aussi : un canevas neuf fait 300 × 150, une première bille en 300 px sortait écrasée
    gl.viewport(0,0,size,size); gl.clearColor(0,0,0,0); gl.clear(gl.COLOR_BUFFER_BIT);
    gl.uniform2f(u.uRes,size,size); gl.uniform4fv(u.uSeed,P.seed); gl.uniform4fv(u.uPar,P.par);
    gl.uniform1f(u.uPorc,P.porc);
    gl.uniform1f(u.uShiny,P.shiny); gl.uniform1f(u.uSulf,P.sulf); gl.uniform1f(u.uFig,P.fig); gl.uniform1f(u.uR,.9); gl.uniform1f(u.uTime,time ?? (performance.now()/1000)%600); gl.uniform1f(u.uAsp,P.asp);
    gl.uniform3fv(u.uC1,P.c1); gl.uniform3fv(u.uC2,P.c2); gl.uniform3fv(u.uC3,P.c3); gl.uniform3fv(u.uTint,P.tint);
    gl.uniformMatrix3fv(u.uRot,false,rot); gl.uniformMatrix3fv(u.uSRot,false,P.srot);
    gl.drawArrays(gl.TRIANGLE_STRIP,0,4);
  }
}
// l'agrandissement des très grands écrans (--vz) : les canvas en tiennent compte pour rester nets
const uiZoom = () => parseFloat(getComputedStyle(document.documentElement).getPropertyValue("--vz"))||1;
const pxRatio = () => (window.devicePixelRatio||1)*uiZoom();
// Les jeux sont redessinés à chaque image : sur un écran 4K (densité × zoom de l'interface), on plafonne la taille du canevas,
// sinon chaque image coûte 4 à 6 fois plus de pixels pour une différence invisible. GAME_PX : largeur maxi d'un terrain (900 unités),
// SCREEN_PX : nombre maxi de pixels d'un canevas plein écran (Grande Course, pluie de billes).
const GAME_PX = 1600, SCREEN_PX = 2.4e6;
const gamePx = cssW => Math.min(Math.round(cssW*pxRatio()), GAME_PX);
const screenDpr = (w, h, d=Math.min(2, devicePixelRatio||1)) => d*Math.min(1, Math.sqrt(SCREEN_PX/Math.max(1, w*h*d*d)));
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
const urlKey = (s,size) => `${s.seed}|${s.type}|${s.family}|${s.pal}|${s.shiny}@${size}`;
function marbleURL(s,size=160){
  const k=urlKey(s,size);
  if(urlCache.has(k)) return urlCache.get(k);
  let u;
  try{ mainGL.draw(s,size); u=mainGL.cv.toDataURL("image/png") }catch(e){ u=draw2D(s,size).toDataURL("image/png") }
  // (5 octobre 2026) une adresse blob: courte plutôt que l'image entière en base64 : le HTML des grandes grilles reste léger
  try{ const bin=atob(u.slice(u.indexOf(",")+1)), a=new Uint8Array(bin.length); for(let i=0;i<bin.length;i++) a[i]=bin.charCodeAt(i);
    u=URL.createObjectURL(new Blob([a],{type:"image/png"})) }catch(e){}
  urlCache.set(k,u); return u;
}
// (11 octobre 2026) la même chose sans bloquer la page : le dessin est copié tout de suite dans un petit canevas à lui
// (le canevas WebGL peut redessiner une autre bille aussitôt), et le PNG est fabriqué en arrière-plan par le navigateur
const urlPend = new Map();
function snapBlobURL(draw, size){
  // (11 octobre 2026) OffscreenCanvas quand il existe : son PNG est fabriqué tout de suite, à côté, alors que toBlob attend que la page soit au repos
  if(typeof OffscreenCanvas==="function") try{ draw(); const c = new OffscreenCanvas(size, size); c.getContext("2d").drawImage(mainGL.cv, 0, 0);
    return c.convertToBlob({type:"image/png"}).then(b=>b ? URL.createObjectURL(b) : null).catch(()=>null) }catch(e){}
  return new Promise(res=>{ try{ draw(); const c = document.createElement("canvas"); c.width = c.height = size; c.getContext("2d").drawImage(mainGL.cv, 0, 0);
    c.toBlob(b=>res(b ? URL.createObjectURL(b) : null), "image/png") }catch(e){ res(null) } });
}
function marbleURLAsync(s,size){
  const k=urlKey(s,size);
  if(urlCache.has(k)) return Promise.resolve(urlCache.get(k));
  if(!mainGL) return Promise.resolve(marbleURL(s,size));
  if(!urlPend.has(k)) urlPend.set(k, snapBlobURL(()=>mainGL.draw(s,size), size).then(u=>{ urlPend.delete(k);
    if(urlCache.has(k)){ if(u) URL.revokeObjectURL(u); return urlCache.get(k) }   // dessinée entre-temps par marbleURL
    if(!u) return marbleURL(s,size);
    urlCache.set(k,u); return u }));
  return urlPend.get(k);
}
// b) les billes pas encore dessinées le sont seulement quand elles arrivent à l'écran, quelques-unes par image (la page reste fluide)
const LAZY_PX = "data:image/gif;base64,R0lGODlhAQABAAAAACH5BAEKAAEALAAAAAABAAEAAAICTAEAOw==";
const lazyTodo = new Map(); let lazyN = 0, lazyQ = [], lazyBusy = false, lazyTok = 0;
// (un jeton plutôt que l'identifiant de requestAnimationFrame : ailleurs, un cancelAnimationFrame d'un vieil identifiant pouvait l'annuler par erreur)
function lazyRun(){
  if(lazyBusy || !lazyQ.length) return;
  lazyBusy = true; const tok = ++lazyTok;
  const step = () => { if(tok!==lazyTok) return; lazyTok++; lazyBusy = false; const t0 = performance.now();
    while(lazyQ.length && performance.now()-t0 < 12){ const im = lazyQ.shift(), j = lazyTodo.get(im.dataset.mq); lazyTodo.delete(im.dataset.mq);
      if(j && im.isConnected){ im.removeAttribute("data-mq");
        marbleURLAsync(j.s, j.size).then(u=>{ if(u && im.getAttribute("src")===LAZY_PX) im.src = u }) } }   // (le motif mythique a peut-être déjà mis sa propre image)
    lazyRun() };
  requestAnimationFrame(step); setTimeout(step, 120);
}
// les images en attente qui sont à l'écran (ou presque) : on les regarde après chaque changement de la page et à chaque défilement
// (un simple balayage plutôt qu'IntersectionObserver, qui ratait des images avec le zoom de la page)
let lazyScanTok = 0;
function lazyScan(){
  const H = innerHeight, W = innerWidth;
  document.querySelectorAll("img[data-mq]:not([data-mqq])").forEach(im=>{ const r = im.getBoundingClientRect();
    if(r.width && r.bottom>-400 && r.top<H+400 && r.right>-200 && r.left<W+200){ im.setAttribute("data-mqq",""); lazyQ.push(im) } });
  lazyRun();
}
const lazySoon = () => { const tok = ++lazyScanTok; setTimeout(()=>{ if(tok===lazyScanTok) lazyScan() }, 60) };
setInterval(()=>{ if(lazyTodo.size) lazyScan() }, 1000);   // filet de sécurité
new MutationObserver(lazySoon).observe(document.documentElement, {childList:true, subtree:true});
addEventListener("scroll", lazySoon, {passive:true, capture:true});
addEventListener("resize", lazySoon);
function lazySrc(s,size){
  const k = urlKey(s,size);
  if(urlCache.has(k)) return `src="${marbleURL(s,size)}"`;
  const id = "m"+(++lazyN); lazyTodo.set(id, {s:{...s}, size}); if(lazyTodo.size>4000) lazyTodo.delete(lazyTodo.keys().next().value);
  return `src="${LAZY_PX}" data-mq="${id}"`;
}
// les Lumineuses rayonnent : lueur CSS qui suit la forme ronde de la bille
const lumAttr = s => s.shiny===3 ? ` data-lum style="--lc:${PALETTES[s.pal][2]}"` : s.shiny===2 ? " data-gold" : "";
function mImg(s,size=160,px,alt){
  const w = Math.round(px ?? size/2), lum = s.shiny===3, my = isMyth(s) && size<=360 ? urlKey(s,size) : "";
  if(my) mythReg.set(my, {s:{seed:s.seed, type:s.type, family:s.family, pal:s.pal, shiny:s.shiny||0}, size});
  // hauteur automatique : si la case est plus étroite que prévu, la bille rétrécit sans devenir ovale
  return `<img ${lazySrc(s,size)}${my?` data-myth="${my}"`:""} alt="${alt===undefined?esc(specName(s)):alt}" width="${w}" height="${w}"${lum?" data-lum":s.shiny===2?" data-gold":""} style="width:${w}px;height:auto;aspect-ratio:1${lum?`;--lc:${PALETTES[s.pal][2]}`:""}">`;
}
// (10 octobre 2026) le motif mythique (l'Œil du Dragon, le Vortex avant le 11 octobre) : il bouge partout où on le voit. Les petites images sont une boucle
// de MYTH_N images (MYTH_T secondes, la même boucle que dans son shader), dessinées à la demande puis gardées (96 images : 24 par seconde depuis le 11 octobre 2026)
const isMyth = s => !!FAMILIES[s?.family]?.myth;
const MYTH_T = 2*Math.PI/1.6, MYTH_N = 96, MYTH_COLS = ["#FF2E44","#FF8A3D","#FFFFFF","#B0122A","#FFD1D6"];
const mythReg = new Map(), mythFrames = new Map();
const mythURL = (s, size, j) => snapBlobURL(()=>mainGL.draw(s, size, I3, j*MYTH_T/MYTH_N), size);   // (11 octobre 2026) PNG en arrière-plan
// (11 octobre 2026) plus de saccades : avant, les images se fabriquaient au fil de l'animation (2 par tour pour tout l'écran),
// et l'œil sautait d'une image à l'autre pendant de longues secondes. Maintenant on fabrique la boucle entière d'abord
// (plusieurs images par tour, dans le temps qui reste), l'image fixe reste affichée pendant ce temps, puis l'œil s'anime d'un coup, fluide.
// Les images sont fabriquées à la taille où on les voit (une petite bille de 30 px n'a pas besoin de 120 px), et décodées d'avance.
setInterval(()=>{
  if(document.hidden || !mainGL || matchMedia("(prefers-reduced-motion: reduce)").matches) return;
  const imgs = document.querySelectorAll("img[data-myth]"); if(!imgs.length) return;
  const now = performance.now(), want = Math.floor((now/1000 % MYTH_T)/MYTH_T*MYTH_N), t0 = now;
  imgs.forEach(im=>{
    const r = im.getBoundingClientRect(); if(!r.width || r.bottom<0 || r.top>innerHeight) return;
    const k = im.dataset.myth, R = mythReg.get(k); if(!R) return;
    let F = mythFrames.get(k);
    // F.u[j] : l'adresse de l'image (prête et décodée), 1 pendant qu'elle se fabrique, 0 si elle a raté (on réessaiera)
    if(!F){ F = {u:[], keep:[], ok:0, sz:Math.min(R.size, Math.max(48, Math.ceil(r.width*pxRatio()/8)*8))}; mythFrames.set(k, F) }
    F.seen = now;
    // tant que la boucle n'est pas complète : on en fabrique autant que possible en ~10 ms (partagées entre les billes à l'écran)
    for(let j=0; j<MYTH_N && F.ok<MYTH_N && performance.now()-t0<10; j++){
      if(F.u[j]) continue; const w = j; F.u[w] = 1;
      mythURL(R.s, F.sz, w).then(u=>{ if(!u){ F.u[w] = 0; return }
        const pre = new Image(); pre.src = u; F.keep[w] = pre;   // décodée d'avance : pas d'à-coup quand elle s'affiche
        (pre.decode ? pre.decode() : Promise.resolve()).catch(()=>{}).then(()=>{ F.u[w] = u; F.ok++ }) });
    }
    if(F.ok<MYTH_N) return;   // pas encore toute la boucle : l'image fixe reste
    if(im.getAttribute("src")!==F.u[want]){ im.removeAttribute("data-mq"); im.src = F.u[want] }
  });
  // on ne garde pas en mémoire les boucles des billes qu'on ne voit plus depuis une minute
  if(mythFrames.size>12) mythFrames.forEach((F,k)=>{ if(now-F.seen>60000){ F.u.forEach(u=>typeof u==="string" && URL.revokeObjectURL(u)); mythFrames.delete(k) } });
}, 1000/24);   // 24 images par seconde : le clignement, très court, ne saute plus
// l'apparition d'une bille mythique, où qu'elle sorte (sachet, mini-jeu, fusion) : un éclair rouge, le grand tourbillon, des gerbes rouges
function mythFX(x, y){
  Sound.mythBoom?.();
  if(FX.reduce()) return;
  const f = document.createElement("div"); f.className = "ov-flash myth"; document.body.appendChild(f); setTimeout(()=>f.remove(), 900);
  const v = document.createElement("div"); v.className = "myth-vortex"; document.body.appendChild(v); setTimeout(()=>v.remove(), 4500);
  [0,140,280,420].forEach((d,j)=>setTimeout(()=>FX.ring(x, y, MYTH_COLS[j%3]), d));
  FX.burst(x, y, MYTH_COLS, 180, 1.8); setTimeout(()=>FX.burst(x, y, MYTH_COLS, 120, 1.3), 650);
  FX.fireworks(MYTH_COLS, 12);
}
// bille "fantôme" pour les emplacements vides
// La bille d'exemple : partout où on illustre une bille qui n'est pas dans ta boîte, c'est un Œil-de-chat Azur
// (et quand un motif précis est demandé, ce motif en Azur) : jamais de motif ni de coloris au hasard.
const EX_PAL = PALETTES.findIndex(P=>P[0]==="Azur"), EX_FAM = 0;
const exSpec = (type, family=EX_FAM, key="") => ({seed:hash("exemple"+type+family+key), type, family, pal:EX_PAL, shiny:0});
const ghost = (type,family) => ({seed:hash(type+family), type, family, pal:EX_PAL, shiny:0});


const ICON = {
  home:'<path d="M3 11l9-7 9 7v9a1 1 0 0 1-1 1h-5v-6h-6v6H4a1 1 0 0 1-1-1z"/>',
  bag:'<path d="M9 7.5h6"/><path d="M8.5 7.5 7 4h10l-1.5 3.5"/><path d="M8.5 7.5C5.5 10 4 13 4 16a4 4 0 0 0 4 4h8a4 4 0 0 0 4-4c0-3-1.5-6-4.5-8.5"/><circle cx="12" cy="14.5" r="2"/>',
  layers:'<path d="M12 3l9 5-9 5-9-5 9-5z"/><path d="M3 12.5l9 5 9-5"/><path d="M3 16.5l9 5 9-5"/>',
  pad:'<path d="M6.5 8h11A4.5 4.5 0 0 1 22 12.5v.5a4 4 0 0 1-7.2 2.4L14 14.5h-4l-.8.9A4 4 0 0 1 2 13v-.5A4.5 4.5 0 0 1 6.5 8z"/><path d="M7 10.5v3M5.5 12h3"/><circle cx="16" cy="11.5" r=".6" fill="currentColor"/><circle cx="18" cy="13.5" r=".6" fill="currentColor"/>',
  swap:'<path d="M4 8h15l-3.5-3.5"/><path d="M20 16H5l3.5 3.5"/>',
  bell:'<path d="M6 8a6 6 0 0 1 12 0c0 7 3 9 3 9H3s3-2 3-9"/><path d="M10.3 21a1.94 1.94 0 0 0 3.4 0"/>',
  bug:'<rect x="8" y="6" width="8" height="14" rx="4"/><path d="M9.5 6.5 8 4M14.5 6.5 16 4M12 11v9M8 11H4M16 11h4M8 16H4.5M16 16h3.5M8.5 19.5 6 21.5M15.5 19.5 18 21.5"/>',
  book:'<path d="M12 6.5C10 5 7 4.5 3.5 5v14c3.5-.5 6.5 0 8.5 1.5 2-1.5 5-2 8.5-1.5V5C17 4.5 14 5 12 6.5z"/><path d="M12 6.5v14"/>',
  cal:'<rect x="3.5" y="5" width="17" height="15.5" rx="2"/><path d="M3.5 10h17M8 3v4M16 3v4"/><path d="M8 14h.01M12 14h.01M16 14h.01M8 17h.01M12 17h.01"/>',
  locker:'<rect x="5" y="3" width="14" height="18" rx="2"/><path d="M9 7h2M9 10h2M15 12v2.5M5 17h14"/>',
  chart:'<path d="M3 20.5h18"/><path d="M6.5 17V11M11.5 17V6M16.5 17v-4"/>',
  trophy:'<path d="M8 4h8v5a4 4 0 0 1-8 0z"/><path d="M8 6H5a3 3 0 0 0 3.2 4M16 6h3a3 3 0 0 1-3.2 4"/><path d="M12 13v3.5M8.5 20.5h7M10 16.5h4v4h-4z"/>',
  gear:'<circle cx="12" cy="12" r="3"/><path d="M12 2.5v2.5M12 19v2.5M4.6 4.6l1.8 1.8M17.6 17.6l1.8 1.8M2.5 12H5M19 12h2.5M4.6 19.4l1.8-1.8M17.6 6.4l1.8-1.8"/>',
  target:'<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="4.5"/><circle cx="12" cy="12" r="1" fill="currentColor"/>',
  arrow:'<path d="M5 12h14M13 6l6 6-6 6"/>',
  chev:'<path d="M9 6l6 6-6 6"/>',
  chevl:'<path d="M15 6l-6 6 6 6"/>',
  chevll:'<path d="M12 6l-6 6 6 6M19 6l-6 6 6 6"/>',
  chevrr:'<path d="M5 6l6 6-6 6M12 6l6 6-6 6"/>',
  play:'<path d="M8 5.5v13l10-6.5z"/>',
  clock:'<circle cx="12" cy="12" r="8.5"/><path d="M12 7.5V12l3 2"/>',
  recycle:'<path d="M7 19H4.5a1.5 1.5 0 0 1-1.3-2.2L6 12"/><path d="M11 19h8.5a1.5 1.5 0 0 0 1.3-2.2L18.5 13"/><path d="M14.5 5.3 13.3 3.2a1.5 1.5 0 0 0-2.6 0L8.5 7"/><path d="M9 16l2 3-2 3M3.5 9.5 6 12l3-1M17 6l-2.5-.7L14 8"/>',
  quest:'<path d="M6 3h9l3 3v15H6z"/><path d="M9 10h6M9 14h6M9 18h3"/>',
  check:'<path d="M5 12.5l4.5 4.5L19 7.5"/>',
  candy:'<circle cx="12" cy="12" r="5"/><path d="M7.4 10.2 3 7.5v9l4.4-2.7M16.6 10.2 21 7.5v9l-4.4-2.7"/><path d="M10 8.5c1.5 1 3 4 4 7"/>',
  flag:'<path d="M5 21V4"/><path d="M5 4h12l-2.5 4L17 12H5"/>',
  marelle:'<path d="M9 21h6v-5H9zM6 16h6v-5H6zM12 16h6v-5h-6zM9 11h6V7H9z"/><path d="M9 7a3 3 0 0 1 6 0"/>',
  pot:'<ellipse cx="12" cy="16" rx="8.5" ry="3.8"/><ellipse cx="12" cy="16" rx="4" ry="1.6"/><circle cx="7" cy="7.5" r="2.4"/><circle cx="15.5" cy="6" r="2"/>',
  castle:'<circle cx="12" cy="6" r="2.2"/><circle cx="9.5" cy="10.3" r="2.2"/><circle cx="14.5" cy="10.3" r="2.2"/><circle cx="7" cy="14.6" r="2.2"/><circle cx="12" cy="14.6" r="2.2"/><circle cx="17" cy="14.6" r="2.2"/><path d="M3 20.5h18"/>',
  wheel:'<circle cx="12" cy="12" r="8.5"/><circle cx="12" cy="12" r="2"/><path d="M12 3.5v6.5M12 14v6.5M3.5 12H10M14 12h6.5M6 6l4.6 4.6M13.4 13.4L18 18M18 6l-4.6 4.6M10.6 13.4L6 18"/>',
  pachi:'<circle cx="6" cy="5" r="1.2" fill="currentColor"/><circle cx="12" cy="5" r="1.2" fill="currentColor"/><circle cx="18" cy="5" r="1.2" fill="currentColor"/><circle cx="9" cy="10" r="1.2" fill="currentColor"/><circle cx="15" cy="10" r="1.2" fill="currentColor"/><circle cx="12" cy="14.5" r="2.4"/><path d="M3 21h18M7 21v-3M12 21v-3M17 21v-3"/>',
  tic:'<circle cx="7.5" cy="15.5" r="4"/><circle cx="17" cy="8" r="3.5"/><path d="M11 12.5l2.6-2"/><path d="M14 16l1.5 1.5M16.5 13.5l2 .5M12.5 18.5l.5 2"/>',
  users:'<circle cx="9" cy="8.5" r="3.5"/><path d="M2.5 20a6.5 6.5 0 0 1 13 0"/><circle cx="17" cy="9.5" r="2.8"/><path d="M16 14.2a5.5 5.5 0 0 1 6 5.8"/>',
  cour:'<path d="M4 21V10l8-6 8 6v11"/><path d="M9 21v-6h6v6"/><circle cx="7" cy="18.5" r="1"/><circle cx="17" cy="18.5" r="1"/>',
  drop:'<path d="M12 3.5c3.2 4.2 5.8 7.3 5.8 10.4a5.8 5.8 0 0 1-11.6 0c0-3.1 2.6-6.2 5.8-10.4z"/>',
  search:'<circle cx="11" cy="11" r="6.5"/><path d="M16 16l4.5 4.5"/>',
  ticket:'<path d="M3 7.5A1.5 1.5 0 0 1 4.5 6h15A1.5 1.5 0 0 1 21 7.5V10a2 2 0 0 0 0 4v2.5a1.5 1.5 0 0 1-1.5 1.5h-15A1.5 1.5 0 0 1 3 16.5V14a2 2 0 0 0 0-4z"/><path d="M15 6v2.5M15 11v2M15 15.5V18"/>',
  lock:'<rect x="5" y="11" width="14" height="9" rx="2"/><path d="M8 11V8a4 4 0 0 1 8 0v3"/>',
  flask:'<path d="M9.5 3h5M10.5 3v5.5L5 18.2A1.8 1.8 0 0 0 6.6 21h10.8a1.8 1.8 0 0 0 1.6-2.8L13.5 8.5V3"/><path d="M7.5 14.5h9"/>',
  user:'<circle cx="12" cy="8" r="4"/><path d="M4.5 20.5a7.5 7.5 0 0 1 15 0"/>',
  plus:'<path d="M12 5v14M5 12h14"/>',
  copy:'<rect x="8.5" y="8.5" width="11.5" height="11.5" rx="2"/><path d="M15.5 8.5V5.5A1.5 1.5 0 0 0 14 4H5.5A1.5 1.5 0 0 0 4 5.5V14a1.5 1.5 0 0 0 1.5 1.5h3"/>',
  shield:'<path d="M12 3l7.5 3v5.5c0 4.6-3.2 8.3-7.5 9.5-4.3-1.2-7.5-4.9-7.5-9.5V6z"/><path d="M8.5 12l2.5 2.5 4.5-5"/>',
  gift:'<rect x="3.5" y="8" width="17" height="4" rx="1"/><path d="M5 12v8h14v-8M12 8v12M12 8C10.5 4 7 4 7 6s3 2 5 2c2 0 5 0 5-2s-3.5-2-5 2"/>',
  star:'<path d="M12 3.5l2.6 5.4 5.9.8-4.3 4.1 1 5.8L12 16.8l-5.2 2.8 1-5.8-4.3-4.1 5.9-.8z"/>',
  gavel:'<path d="M13.2 3.6l7.2 7.2M11.4 5.4l7.2 7.2M12.3 4.5L8 8.8l7.2 7.2 4.3-4.3"/><path d="M11.6 12.4L4 20"/><path d="M13 21h8"/>',
};
const ic = (k,s=22,sw=2) => `<svg width="${s}" height="${s}" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round" aria-hidden="true">${ICON[k]}</svg>`;
const COIN = `<svg class="coin" viewBox="0 0 24 24" aria-hidden="true"><path d="M6.6 12 1.6 8.1l.9 3.9-.9 3.9z" fill="#FF9FD0" stroke="#D9468F" stroke-width="1" stroke-linejoin="round"/><path d="M17.4 12l5-3.9-.9 3.9.9 3.9z" fill="#FF9FD0" stroke="#D9468F" stroke-width="1" stroke-linejoin="round"/><circle cx="12" cy="12" r="6.3" fill="#FF5FA8" stroke="#D9468F" stroke-width="1.2"/><path d="M8.3 9.6c2.2.8 5 3.9 7 6.2M10 6.6c1.9 1.2 4.7 4.6 6 7.1" stroke="#fff" stroke-width="1.4" opacity=".8" fill="none" stroke-linecap="round"/><circle cx="9.8" cy="9.4" r="1.2" fill="#fff" opacity=".7"/></svg>`;
const STAR = on => `<svg viewBox="0 0 24 24" aria-hidden="true"><path d="M12 2.5l2.9 6 6.6.8-4.9 4.5 1.3 6.5L12 17.1l-5.9 3.2 1.3-6.5L2.5 9.3l6.6-.8z" fill="${on?"#FFC93F":"#E6DCCB"}" stroke="${on?"#E0A417":"#D6C8B0"}" stroke-width="1.2" stroke-linejoin="round"/></svg>`;

let uid=0;
// Chaque sachet a sa matière : toile de jute, coton, velours, satin doré
const BAG_LOOK = {
  gratuit:  {tex:"jute",   cord:"#7A5A32", cordW:4.5, bead:"#E9D3A6", patch:"square", paper:"#F4E6C8"},
  classique:{tex:"coton",  cord:"#F4E3C2", cordW:5,   bead:"#B9824A", patch:"round",  paper:"#FFF6E2"},
  premium:  {tex:"velours",cord:"#E8B53A", cordW:5,   bead:"#FFD86B", patch:"round",  paper:"#FFF6E2", ring:"#E8B53A"},
  collector:{tex:"satin",  cord:"#B8322A", cordW:5.5, bead:"#FFD86B", patch:"star",   paper:"#FFF3C4", tassel:true, sparks:true},
};
// petite bille en verre dessinée en SVG (dans le goulot du sachet, ou par terre à côté)
function dotMarble(x,y,r,col,id,cls=""){
  return `<g class="${cls}"><circle cx="${x}" cy="${y}" r="${r}" fill="url(#${id}-m${col.slice(1)})"/>
  <path d="M${x-r*.7} ${y+r*.1}C${x-r*.2} ${y-r*.6},${x+r*.2} ${y+r*.6},${x+r*.7} ${y-r*.1}" stroke="${shade(col,.55)}" stroke-width="${r*.32}" fill="none" stroke-linecap="round" opacity=".85"/>
  <ellipse cx="${x-r*.35}" cy="${y-r*.4}" rx="${r*.3}" ry="${r*.2}" fill="#fff" opacity=".8"/></g>`;
}
const DOT_COLS = ["#E0533D","#3C8DDE","#F2C230","#38B37A"];
// bagSVG(sac, {loose:true} pour quelques billes posées par terre à côté)
// Les sachets (5 octobre 2026), de vrais emballages de billes, chacun différent :
// Gratuit = sachet en papier kraft à fenêtre (3 billes), Classique = filet de billes à carte en carton (5 billes),
// Premium = bocal de confiserie au couvercle doré (5 billes dedans, le couvercle se soulève à l'ouverture), Collector = coffret en acajou aux coins dorés (le couvercle s'entrouvre à l'ouverture).
const SAC_MC = ["#E0533D","#3C8DDE","#F2C230","#38B37A","#9B5DE5","#F28AB2"];
function sacMarble(id,x,y,r,col,k){
  return `<g><circle cx="${x}" cy="${y}" r="${r}" fill="url(#${id}-g${k})"/>
  <path d="M${x-r*.75} ${y+r*.15}C${x-r*.25} ${y-r*.7},${x+r*.25} ${y+r*.7},${x+r*.75} ${y-r*.15}" stroke="${shade(col,.55)}" stroke-width="${r*.3}" fill="none" stroke-linecap="round" opacity=".85"/>
  <ellipse cx="${x-r*.35}" cy="${y-r*.42}" rx="${r*.3}" ry="${r*.2}" fill="#fff" opacity=".85"/></g>`;
}
const MC = SAC_MC;
const mDefs = id => SAC_MC.map((c,k)=>`<radialGradient id="${id}-g${k}" cx="36%" cy="32%" r="72%"><stop offset="0" stop-color="${shade(c,.5)}"/><stop offset=".55" stop-color="${c}"/><stop offset="1" stop-color="${shade(c,-.5)}"/></radialGradient>`).join("");
const shadowEl = (id,cx=100,cy=228,rx=70) => `<ellipse cx="${cx}" cy="${cy}" rx="${rx}" ry="9" fill="url(#${id}-sh)"/>`;
const shDef = id => `<radialGradient id="${id}-sh"><stop offset="0" stop-color="#000" stop-opacity=".45"/><stop offset="1" stop-color="#000" stop-opacity="0"/></radialGradient>`;
// deux billes posées par terre à côté du sachet (page Sachets, accueil)
const bagLoose = (id,o) => o.loose ? `<ellipse cx="-4" cy="232" rx="12" ry="3" fill="rgba(40,25,10,.25)"/><ellipse cx="207" cy="233" rx="10" ry="2.6" fill="rgba(40,25,10,.25)"/>
  <g class="loose l1">${sacMarble(id,-4,221,11,SAC_MC[1],1)}</g><g class="loose l2">${sacMarble(id,207,224,9,SAC_MC[3],3)}</g>` : "";
function bagTag(id,x,y,rot,txt,col,sub){
  return `<g transform="rotate(${rot} ${x} ${y})">
    <path d="M${x-30} ${y}L${x+24} ${y}L${x+34} ${y+11}L${x+24} ${y+22}L${x-30} ${y+22}Z" fill="rgba(0,0,0,.25)" transform="translate(2 3)"/>
    <path d="M${x-30} ${y}L${x+24} ${y}L${x+34} ${y+11}L${x+24} ${y+22}L${x-30} ${y+22}Z" fill="#F6EBD3" stroke="#C9B48C" stroke-width="1"/>
    <circle cx="${x+25}" cy="${y+11}" r="2.6" fill="#8B7650"/>
    <text x="${x-3}" y="${y+(sub?11:15)}" text-anchor="middle" font-family="Caveat" font-weight="700" font-size="${sub?14:17}" fill="${col}">${txt}</text>
    ${sub?`<text x="${x-3}" y="${y+19}" text-anchor="middle" font-family="Nunito" font-weight="900" font-size="6" fill="#8B7650" letter-spacing=".6">${sub}</text>`:""}
  </g>`;
}
function bagFree(b,o){
  const id="b"+(++uid), c=b.color||"#C98E4E";
  return `<svg viewBox="${o.loose?"-26 0 252 240":"0 0 200 240"}" aria-hidden="true"><defs>${mDefs(id)}${shDef(id)}
    <linearGradient id="${id}-p" x1="0" x2="1"><stop offset="0" stop-color="${shade(c,-.25)}"/><stop offset=".3" stop-color="${shade(c,.12)}"/><stop offset=".7" stop-color="${c}"/><stop offset="1" stop-color="${shade(c,-.35)}"/></linearGradient>
    <linearGradient id="${id}-gl" x1="0" y1="0" x2="1" y2="1"><stop offset=".2" stop-color="#fff" stop-opacity=".0"/><stop offset=".35" stop-color="#fff" stop-opacity=".45"/><stop offset=".45" stop-color="#fff" stop-opacity="0"/></linearGradient>
    <pattern id="${id}-f" width="9" height="7" patternUnits="userSpaceOnUse"><path d="M1 2l3 .6M5 5l3-.5" stroke="#5a3a1a" stroke-opacity=".18" stroke-width=".7"/></pattern>
    <clipPath id="${id}-w"><rect x="70" y="128" width="60" height="62" rx="22"/></clipPath></defs>
    ${shadowEl(id,100,226,66)}
    <path d="M52 70L148 70L156 214Q100 222 44 214Z" fill="url(#${id}-p)"/>
    <path d="M52 70L148 70L156 214Q100 222 44 214Z" fill="url(#${id}-f)"/>
    <path d="M66 70L62 216M134 70L138 216" stroke="#000" stroke-opacity=".12" stroke-width="2"/>
    <path d="M44 214Q100 222 156 214L154 200Q100 208 46 200Z" fill="#000" opacity=".12"/>
    <!-- la fenêtre transparente : on voit les billes -->
    <rect x="70" y="128" width="60" height="62" rx="22" fill="#2a1d12"/>
    <g clip-path="url(#${id}-w)"><g class="bag-peek">${sacMarble(id,87,176,14,MC[1],1)}${sacMarble(id,114,176,14,MC[0],0)}${sacMarble(id,100,152,14,MC[2],2)}</g>
      <rect x="70" y="128" width="60" height="62" fill="url(#${id}-gl)"/></g>
    <rect x="70" y="128" width="60" height="62" rx="22" fill="none" stroke="${shade(c,-.45)}" stroke-width="2"/>
    <!-- le haut replié deux fois -->
    <path d="M50 52L150 52L149 74L51 74Z" fill="${shade(c,-.15)}"/>
    <path d="M50 52L150 52L150 60L50 60Z" fill="${shade(c,.1)}"/>
    <path d="M50 74L150 74" stroke="#000" stroke-opacity=".3" stroke-width="2"/>
    <path d="M49 40L151 40L150 54L50 54Z" fill="${shade(c,-.05)}"/><path d="M49 40L151 40" stroke="${shade(c,.3)}" stroke-width="2"/>
    <!-- la gommette -->
    <g transform="rotate(-8 100 58)"><circle cx="101.5" cy="60" r="15" fill="rgba(0,0,0,.25)"/><circle cx="100" cy="58" r="15" fill="#E5484D"/><circle cx="100" cy="58" r="11.5" fill="none" stroke="#fff" stroke-width="1.4" stroke-dasharray="2.6 2"/>
      <text x="100" y="65" text-anchor="middle" font-family="Lilita One" font-size="19" fill="#fff">B</text></g>
    <text x="100" y="112" text-anchor="middle" font-family="Caveat" font-weight="700" font-size="22" fill="${shade(c,-.55)}" opacity=".8">offert !</text>
    ${bagLoose(id,o)}
  </svg>`;
}
function bagNet(b,o){
  const id="b"+(++uid), net=b.id==="classique"?"#2FA35A":(b.color||"#2FA35A");
  const body="M60 74C44 98 38 140 46 182C54 214 146 214 154 182C162 140 156 98 140 74Z";
  return `<svg viewBox="${o.loose?"-26 0 252 240":"0 0 200 240"}" aria-hidden="true"><defs>${mDefs(id)}${shDef(id)}
    <clipPath id="${id}-c"><path d="${body}"/></clipPath>
    <pattern id="${id}-n" width="12" height="12" patternUnits="userSpaceOnUse" patternTransform="rotate(45)"><path d="M0 0h12M0 0v12" stroke="${net}" stroke-width="2.2"/><path d="M0 1h12M1 0v12" stroke="${shade(net,.45)}" stroke-width=".7" opacity=".7"/></pattern></defs>
    ${shadowEl(id,100,224,62)}
    <g clip-path="url(#${id}-c)">
      <path d="${body}" fill="rgba(20,40,25,.35)"/>
      <g class="bag-peek">${sacMarble(id,70,188,18,MC[0],0)}${sacMarble(id,104,193,19,MC[1],1)}${sacMarble(id,137,186,18,MC[2],2)}${sacMarble(id,87,158,17,MC[3],3)}${sacMarble(id,121,158,17,MC[4],4)}</g>
      <rect x="20" y="60" width="160" height="170" fill="url(#${id}-n)"/>
      <rect x="20" y="60" width="160" height="170" fill="url(#${id}-n)" opacity=".5" transform="translate(3 2)"/>
    </g>
    <path d="${body}" fill="none" stroke="${shade(net,-.25)}" stroke-width="2"/>
    <!-- le filet froncé sous la carte -->
    <path d="M62 76C70 70 80 66 86 60M138 76C130 70 120 66 114 60M100 60V78" stroke="${net}" stroke-width="2.4" fill="none"/>
    <path d="M78 74C84 68 90 64 94 60M122 74C116 68 110 64 106 60" stroke="${net}" stroke-width="1.6" fill="none"/>
    <!-- la carte en carton pliée et agrafée -->
    <path d="M56 24L144 24L146 64L54 64Z" fill="rgba(0,0,0,.3)" transform="translate(2 3)"/>
    <path d="M56 24L144 24L146 64L54 64Z" fill="#F4E6C8"/>
    <path d="M56 24L144 24L144 34L56 34Z" fill="${net}"/>
    <path d="M54 64L146 64" stroke="#C9B48C" stroke-width="2"/>
    <ellipse cx="100" cy="29" rx="9" ry="3.4" fill="#16130F"/>
    <text x="100" y="53" text-anchor="middle" font-family="Lilita One" font-size="17" fill="#24253D">Tikalo</text>
    <text x="100" y="61" text-anchor="middle" font-family="Nunito" font-weight="900" font-size="6.5" fill="${shade(net,-.3)}" letter-spacing="1">CLASSIQUE · 5 BILLES</text>
    <path d="M66 58l6 0M128 58l6 0" stroke="#9aa0a6" stroke-width="2.2" stroke-linecap="round"/>
    ${bagLoose(id,o)}
  </svg>`;
}
function bagVelvet(b,o){
  const id="b"+(++uid), c=b.color||"#34469C", nm=(b.name||"Premium").replace("Sachet ","");
  const body="M66 92C36 104 20 146 26 184C32 214 168 214 174 184C180 146 164 104 134 92Z";
  const top=[[48,40],[58,52],[64,34],[74,50],[82,30],[92,48],[100,28],[108,48],[118,30],[126,50],[136,34],[142,52],[152,40]];
  const neck=x=>82+(x-48)/104*36;
  const collar=`M66 92C60 76 52 60 48 40L${top.slice(1,-1).map(p=>p.join(" ")).join(" L")} L152 40C148 60 140 76 134 92Z`;
  const pleats=top.slice(0,-1).map((p,k)=>{const q=top[k+1];return `<path d="M${p[0]} ${p[1]}L${q[0]} ${q[1]}L${neck(q[0])} 92L${neck(p[0])} 92Z" fill="${k%2?"rgba(0,0,0,.32)":"rgba(255,255,255,.12)"}"/>`}).join("");
  return `<svg viewBox="${o.loose?"-26 0 252 240":"0 0 200 240"}" aria-hidden="true"><defs>${mDefs(id)}${shDef(id)}
    <radialGradient id="${id}-v" cx="30%" cy="38%" r="85%"><stop offset="0" stop-color="${shade(c,.45)}"/><stop offset=".35" stop-color="${c}"/><stop offset=".8" stop-color="${shade(c,-.55)}"/><stop offset="1" stop-color="${shade(c,-.75)}"/></radialGradient>
    <radialGradient id="${id}-bp" cx="35%" cy="30%" r="70%"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".6" stop-color="#fff" stop-opacity="0"/><stop offset="1" stop-color="#000" stop-opacity=".3"/></radialGradient>
    <linearGradient id="${id}-cl" x1="0" x2="1"><stop offset="0" stop-color="${shade(c,.25)}"/><stop offset=".5" stop-color="${c}"/><stop offset="1" stop-color="${shade(c,-.5)}"/></linearGradient>
    <clipPath id="${id}-c"><path d="${body}"/></clipPath></defs>
    ${shadowEl(id,100,222,80)}
    
    <path d="${body}" fill="url(#${id}-v)"/>
    <g clip-path="url(#${id}-c)">
      
      <path d="M44 150C52 122 72 108 96 106" stroke="#fff" stroke-opacity=".18" stroke-width="18" fill="none" stroke-linecap="round"/>
      <path d="M86 96C74 128 66 160 64 196M114 96C124 128 132 160 136 196" stroke="#000" stroke-opacity=".18" stroke-width="5" fill="none" stroke-linecap="round"/>
      <path d="M150 120C166 144 168 172 160 196" stroke="#000" stroke-opacity=".25" stroke-width="16" fill="none" stroke-linecap="round"/>
    </g>
    <path d="${collar}" fill="url(#${id}-cl)"/>${pleats}
    <path d="${collar}" fill="none" stroke="${shade(c,-.6)}" stroke-width="1.5" stroke-linejoin="round"/>
    <path d="M66 88Q100 102 134 88L134 98Q100 112 66 98Z" fill="rgba(0,0,0,.35)"/>
    <path d="M64 91Q100 106 136 91" stroke="#9E7A1C" stroke-width="6" fill="none" stroke-linecap="round"/>
    <path d="M64 91Q100 106 136 91" stroke="#F2C94C" stroke-width="3.6" stroke-dasharray="2 2.6" fill="none" stroke-linecap="round"/>
    <circle cx="116" cy="100" r="6.5" fill="#E8B53A" stroke="#9E7A1C" stroke-width="1.4"/>
    <path d="M116 104C118 116 124 124 130 130" stroke="#C9A24A" stroke-width="1.6" fill="none"/>
    ${bagTag(id,146,128,14,nm,shade(c,-.1),(b.n||5)+" BILLES")}
    ${bagLoose(id,o)}
  </svg>`;
}
function bagJar(b,o){
  const id="b"+(++uid), c=b.color||"#34469C", nm=(b.name||"Premium").replace("Sachet ","");
  const jar="M60 70L140 70Q146 70 146 78L146 86Q166 96 166 122L166 196Q166 212 150 212L50 212Q34 212 34 196L34 122Q34 96 54 86L54 78Q54 70 60 70Z";
  return `<svg viewBox="${o.loose?"-26 0 252 240":"0 0 200 240"}" aria-hidden="true"><defs>${mDefs(id)}${shDef(id)}
    <linearGradient id="${id}-g" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#8A5E0C"/><stop offset=".3" stop-color="#FFE38A"/><stop offset=".55" stop-color="#E8B53A"/><stop offset="1" stop-color="#7A4F08"/></linearGradient>
    <linearGradient id="${id}-gl" x1="0" x2="1"><stop offset="0" stop-color="#fff" stop-opacity=".22"/><stop offset=".12" stop-color="#fff" stop-opacity=".55"/><stop offset=".2" stop-color="#fff" stop-opacity=".05"/><stop offset=".8" stop-color="#fff" stop-opacity=".05"/><stop offset=".9" stop-color="#fff" stop-opacity=".3"/><stop offset="1" stop-color="#fff" stop-opacity=".12"/></linearGradient>
    <clipPath id="${id}-c"><path d="${jar}"/></clipPath></defs>
    ${shadowEl(id,100,220,74)}
    <path d="${jar}" fill="rgba(190,215,240,.14)"/>
    <g clip-path="url(#${id}-c)"><g class="bag-peek">${sacMarble(id,58,193,17,MC[0],0)}${sacMarble(id,92,195,17,MC[1],1)}${sacMarble(id,126,194,17,MC[2],2)}${sacMarble(id,75,164,16,MC[3],3)}${sacMarble(id,109,165,16,MC[4],4)}</g>
      <path d="${jar}" fill="url(#${id}-gl)"/></g>
    <path d="${jar}" fill="none" stroke="rgba(220,240,255,.75)" stroke-width="2.5"/>
    <path d="M42 118Q42 100 58 92" stroke="#fff" stroke-opacity=".7" stroke-width="3" fill="none" stroke-linecap="round"/>
    <ellipse cx="100" cy="72" rx="44" ry="6" fill="#FFD86B" class="bag-glow"/>
    <g class="bag-lid"><rect x="50" y="48" width="100" height="26" rx="6" fill="url(#${id}-g)" stroke="#6A4306" stroke-width="1.2"/>
    <path d="M58 52v18M66 52v18M74 52v18M82 52v18M90 52v18M98 52v18M106 52v18M114 52v18M122 52v18M130 52v18M138 52v18" stroke="#6A4306" stroke-opacity=".35" stroke-width="1.2"/>
    <ellipse cx="100" cy="48" rx="50" ry="6" fill="#FFE38A" stroke="#6A4306" stroke-width="1"/></g>
    <path d="M54 80L146 80L146 90L54 90Z" fill="${c}"/><path d="M54 82L146 82" stroke="#fff" stroke-opacity=".35" stroke-width="1.2"/>
    <path d="M100 86C90 78 78 78 76 86C76 94 90 94 100 88ZM100 86C110 78 122 78 124 86C124 94 110 94 100 88Z" fill="${c}" stroke="${shade(c,-.45)}" stroke-width="1"/>
    <circle cx="100" cy="87" r="5" fill="${shade(c,-.2)}"/>
    <g transform="rotate(-3 100 132)"><rect x="56" y="112" width="88" height="40" rx="6" fill="#FFF6DE" stroke="#D9A020" stroke-width="2"/>
      <rect x="60" y="116" width="80" height="32" rx="4" fill="none" stroke="#D9A020" stroke-width=".8" stroke-dasharray="3 2"/>
      <text x="100" y="132" text-anchor="middle" font-family="Caveat" font-weight="700" font-size="19" fill="${shade(c,-.1)}">${nm}</text>
      <text x="100" y="143" text-anchor="middle" font-family="Nunito" font-weight="900" font-size="6.5" fill="#8A5E0C" letter-spacing="1.2">TIKALO · ${b.n||5} BILLES</text></g>
    ${bagLoose(id,o)}
  </svg>`;
}
function bagBox(b,o){
  const id="b"+(++uid);
  const spark=(x,y,s)=>`<path class="bag-spark" d="M${x} ${y-s}Q${x} ${y} ${x+s} ${y}Q${x} ${y} ${x} ${y+s}Q${x} ${y} ${x-s} ${y}Q${x} ${y} ${x} ${y-s}z" fill="#FFE9A8"/>`;
  return `<svg viewBox="${o.loose?"-26 0 252 240":"0 0 200 240"}" aria-hidden="true"><defs>${mDefs(id)}${shDef(id)}
    <linearGradient id="${id}-wf" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#8A4A26"/><stop offset=".5" stop-color="#6A3418"/><stop offset="1" stop-color="#4A220E"/></linearGradient>
    <linearGradient id="${id}-wt" x1="0" y1="0" x2="1" y2="0"><stop offset="0" stop-color="#7A3E1E"/><stop offset=".5" stop-color="#A2602F"/><stop offset="1" stop-color="#6A3418"/></linearGradient>
    <pattern id="${id}-gr" width="60" height="8" patternUnits="userSpaceOnUse"><path d="M0 3Q15 1 30 3T60 3M0 6.5Q20 5 40 6.5T60 6" stroke="#2a1206" stroke-opacity=".25" stroke-width=".8" fill="none"/></pattern>
    <linearGradient id="${id}-g" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#FFF1B0"/><stop offset=".45" stop-color="#E8B53A"/><stop offset="1" stop-color="#8A5E0C"/></linearGradient>
    <radialGradient id="${id}-vel" cx="50%" cy="40%" r="70%"><stop offset="0" stop-color="#B0202E"/><stop offset="1" stop-color="#5a0a14"/></radialGradient>
    <linearGradient id="${id}-gl" x1="0" y1="0" x2="1" y2="1"><stop offset=".15" stop-color="#fff" stop-opacity="0"/><stop offset=".3" stop-color="#fff" stop-opacity=".5"/><stop offset=".4" stop-color="#fff" stop-opacity="0"/><stop offset=".7" stop-color="#fff" stop-opacity="0"/><stop offset=".78" stop-color="#fff" stop-opacity=".28"/><stop offset=".85" stop-color="#fff" stop-opacity="0"/></linearGradient></defs>
    ${shadowEl(id,100,212,88)}
    <path d="M18 124L182 124L182 196Q100 202 18 196Z" fill="url(#${id}-wf)"/>
    <path d="M18 124L182 124L182 196Q100 202 18 196Z" fill="url(#${id}-gr)"/>
    <path d="M18 160L182 160" stroke="#2a1206" stroke-opacity=".5" stroke-width="1.5"/><path d="M18 162L182 162" stroke="#C9864A" stroke-opacity=".35" stroke-width="1"/>
    <path d="M40 80L160 80L182 124L18 124Z" fill="#3a0a10"/><path d="M46 84L154 84L174 122L26 122Z" fill="#FFD86B" opacity=".9" class="bag-glow"/>
    <g class="bag-lid"><path d="M40 80L160 80L182 124L18 124Z" fill="url(#${id}-wt)"/>
    <path d="M40 80L160 80L182 124L18 124Z" fill="url(#${id}-gr)" opacity=".8"/>
    <path d="M52 87L148 87L164 118L36 118Z" fill="none" stroke="url(#${id}-g)" stroke-width="2.2"/>
    <path d="M58 91L142 91L155 114L45 114Z" fill="none" stroke="#E8B53A" stroke-opacity=".55" stroke-width="1" stroke-dasharray="3 2"/>
    <ellipse cx="100" cy="102.5" rx="17" ry="8.5" fill="url(#${id}-g)" stroke="#8A5E0C" stroke-width="1"/>
    <path d="M100 96.5l1.8 3.6 4 .5-2.9 2.7.7 3.9-3.6-1.9-3.6 1.9.7-3.9-2.9-2.7 4-.5z" fill="#8A5E0C"/>
    <path d="M40 80L160 80L182 124L18 124Z" fill="url(#${id}-gl)" opacity=".5"/>
    <path d="M40 80L160 80L182 124L18 124Z" fill="none" stroke="#2a1206" stroke-width="1.6"/></g>
    <path d="M18 124h14v10h-4v-6h-10ZM182 124h-14v10h4v-6h10ZM18 196v-14h6v10h8v4.5Q24 196.5 18 196ZM182 196v-14h-6v10h-8v4.5Q176 196.5 182 196Z" fill="url(#${id}-g)"/>
    <path d="M86 132L114 132L114 158Q100 166 86 158Z" fill="rgba(0,0,0,.35)" transform="translate(1.5 2)"/>
    <path d="M86 132L114 132L114 158Q100 166 86 158Z" fill="url(#${id}-g)" stroke="#8A5E0C" stroke-width="1"/>
    <text x="100" y="152" text-anchor="middle" font-family="Lilita One" font-size="17" fill="#7A4F08">B</text>
    <rect x="66" y="172" width="68" height="14" rx="2" fill="url(#${id}-g)" stroke="#8A5E0C" stroke-width=".8"/>
    <text x="100" y="182.5" text-anchor="middle" font-family="Nunito" font-weight="900" font-size="8" fill="#6A4306" letter-spacing="1.6">COLLECTOR</text>
    ${spark(26,70,7)}${spark(176,64,6)}${spark(190,150,5)}${spark(10,150,4)}
    ${bagLoose(id,o)}
  </svg>`;
}
function bagSVG(b, o={}){
  if(typeof b==="string") b = BAGS.find(x=>x.color===b) || {id:"classique", color:b};
  const draw = {gratuit:bagFree, classique:bagNet, premium:bagJar, collector:bagBox}[b.id] || bagVelvet;
  return draw(b, o);
}

const cbClamp = (v,a,b) => Math.max(a, Math.min(b, v));


function cbShade(hex, amt){ const n = parseInt(hex.slice(1),16), f = v => cbClamp(v+amt,0,255); return `rgb(${f(n>>16)},${f((n>>8)&255)},${f(n&255)})` }

const ROUE = [
  {w:.2,    roue:true,       lbl:"Mammouth",  c:"#E5484D", c2:"#9E1C2C"},
  {w:17.9,  j:5,             lbl:"5",         c:"#FF7EB6", c2:"#C9407F"},
  {w:10,    sac:"classique", lbl:"Classique", c:"#2FA889", c2:"#1C6B57"},
  {w:12.5,  j:10,            lbl:"10",        c:"#FFC23F", c2:"#C98A12"},
  {w:6,     j:40,            lbl:"40",        c:"#8C7CFF", c2:"#5240C9"},
  {w:17.9,  j:5,             lbl:"5",         c:"#FF7EB6", c2:"#C9407F"},
  {w:4,     sac:"premium",   lbl:"Premium",   c:"#4A5FD0", c2:"#28358A"},
  {w:16,    j:20,            lbl:"20",        c:"#2EC4DE", c2:"#16879C"},
  {w:12.5,  j:10,            lbl:"10",        c:"#FFC23F", c2:"#C98A12"},
  {w:2,     j:100,           lbl:"100",       c:"#FF8A3D", c2:"#C4531A"},
  {w:1,     sac:"collector", lbl:"Collector", c:"#F2C14E", c2:"#A87A12"},
];

const ROUE_SEG = 360/ROUE.length, ROUE_DUR = 6200;

const artM = (id, x, y, r, c, glow) => `<defs><radialGradient id="${id}" cx=".35" cy=".3" r=".75"><stop offset="0" stop-color="#fff"/><stop offset=".18" stop-color="${cbShade(c,60)}"/><stop offset=".6" stop-color="${c}"/><stop offset="1" stop-color="${cbShade(c,-70)}"/></radialGradient></defs>
  ${glow?`<circle cx="${x}" cy="${y}" r="${r*2.2}" fill="${c}" opacity=".25"/>`:""}<ellipse cx="${x+r*.25}" cy="${y+r*.85}" rx="${r*.95}" ry="${r*.38}" fill="#000" opacity=".28"/><circle cx="${x}" cy="${y}" r="${r}" fill="url(#${id})"/><ellipse cx="${x-r*.35}" cy="${y-r*.42}" rx="${r*.28}" ry="${r*.18}" fill="#fff" opacity=".75" transform="rotate(-30 ${x-r*.35} ${y-r*.42})"/>`;

const artDirt = (id, seed) => { const r = rng(seed); let g = "";
  for(let i=0;i<70;i++) g += `<circle cx="${(r()*320).toFixed(1)}" cy="${(r()*100).toFixed(1)}" r="${(.5+r()*1.4).toFixed(1)}" fill="${r()<.5?"#7A5530":"#E8C9A0"}" opacity="${(.25+r()*.4).toFixed(2)}"/>`;
  for(let i=0;i<6;i++){ const x = r()*320, y = r()<.5 ? 4+r()*8 : 88+r()*8; g += `<path d="M${x} ${y}l-3 -7M${x} ${y}l1 -8M${x} ${y}l4 -6" stroke="#5E8C3A" stroke-width="1.4" stroke-linecap="round"/>` }
  return `<defs><radialGradient id="${id}" cx=".45" cy=".35" r=".9"><stop offset="0" stop-color="#D2A472"/><stop offset=".6" stop-color="#B8895A"/><stop offset="1" stop-color="#8A6038"/></radialGradient></defs><rect width="320" height="100" fill="url(#${id})"/>${g}` };

const ART_SVG = inner => `<svg viewBox="0 0 320 100" preserveAspectRatio="xMidYMid slice" aria-hidden="true">${inner}</svg>`;

function artPot(){
  const pebble = (x,y,r) => `<ellipse cx="${x+1.5}" cy="${y+2.5}" rx="${r}" ry="${r*.75}" fill="#000" opacity=".25"/><ellipse cx="${x}" cy="${y}" rx="${r}" ry="${r*.82}" fill="url(#apPb)"/>`;
  return ART_SVG(`${artDirt("apD", 11)}<defs><radialGradient id="apPb" cx=".35" cy=".3"><stop offset="0" stop-color="#E4E0D8"/><stop offset="1" stop-color="#7D776D"/></radialGradient>
    <radialGradient id="apH" cx=".5" cy=".42"><stop offset="0" stop-color="#050302"/><stop offset=".7" stop-color="#24160A"/><stop offset="1" stop-color="#5A3A1E"/></radialGradient></defs>
    <path d="M58 4v92" stroke="#fff" stroke-width="3" stroke-dasharray="8 7" stroke-linecap="round" opacity=".85"/>
    <ellipse cx="214" cy="52" rx="30" ry="21" fill="#6B4524" opacity=".45"/><ellipse cx="214" cy="51" rx="21" ry="15" fill="url(#apH)"/><ellipse cx="214" cy="58" rx="19" ry="6" fill="#E8C9A0" opacity=".25"/>
    <circle cx="214" cy="51" r="34" fill="none" stroke="#fff" stroke-width="1.6" stroke-dasharray="2 5" opacity=".5"/>
    ${pebble(178,30,6)}${pebble(250,70,7)}${pebble(244,28,5)}${pebble(150,78,6)}${pebble(286,48,5)}
    <path d="M86 58Q150 34 196 46" stroke="#fff" stroke-width="2.2" stroke-dasharray="3 6" fill="none" stroke-linecap="round"/>
    ${artM("apM1", 74, 60, 9, "#2E8CFF")}${artM("apM2", 209, 49, 6, "#E5484D")}`);
}

function artChateau(){
  const cols = ["#E5484D","#FFC93F","#2FA35A","#7B6CF6","#FF8A3D","#22B8CF"]; let balls = "", k = 0;
  for(let i=0;i<4;i++) for(let j=0;j<=i;j++){ balls += artM("acB"+k, 196+i*13.5, 50+(j-i/2)*15, 7, cols[k%cols.length]); k++ }
  return ART_SVG(`${artDirt("acD", 23)}<path d="M96 4v92" stroke="#fff" stroke-width="3" stroke-dasharray="8 7" opacity=".8" stroke-linecap="round"/>
    <path d="M213 4C255 6 272 28 270 52S248 98 210 97 152 78 154 50 176 3 213 4Z" fill="none" stroke="#fff" stroke-width="3" opacity=".85"/>
    <path d="M78 64Q130 52 184 51" stroke="#fff" stroke-width="2.2" stroke-dasharray="3 6" fill="none" stroke-linecap="round"/>
    <path d="M188 40l-8 -6M186 51h-10M188 62l-8 6" stroke="#FFE14D" stroke-width="2.4" stroke-linecap="round"/>
    ${balls}${artM("acM", 64, 66, 10, "#2E8CFF")}`);
}

function artTic(){
  const rock = (x,y,rx,ry) => `<ellipse cx="${x+3}" cy="${y+5}" rx="${rx}" ry="${ry*.8}" fill="#000" opacity=".25"/><ellipse cx="${x}" cy="${y}" rx="${rx}" ry="${ry}" fill="url(#atR)"/><ellipse cx="${x-rx*.3}" cy="${y-ry*.4}" rx="${rx*.35}" ry="${ry*.2}" fill="#fff" opacity=".25"/>`;
  return ART_SVG(`${artDirt("atD", 37)}<defs><radialGradient id="atR" cx=".35" cy=".3"><stop offset="0" stop-color="#B7B1A6"/><stop offset="1" stop-color="#5E584F"/></radialGradient></defs>
    ${rock(150,30,20,14)}${rock(112,82,14,10)}
    <path d="M86 70Q120 20 178 22Q205 24 214 46" stroke="#fff" stroke-width="2.2" stroke-dasharray="3 6" fill="none" stroke-linecap="round"/>
    <path d="M232 50l11-12 2 13 15-6-8 12 14 6-15 3 5 13-12-8-6 13-3-14-14 3 9-11z" fill="#FFE14D" stroke="#7A4A10" stroke-width="1.5" stroke-linejoin="round"/>
    ${artM("atM1", 72, 74, 10, "#2E8CFF")}${artM("atM2", 220, 54, 9, "#E5484D")}
    <text x="282" y="86" text-anchor="middle" font-family="Lilita One, sans-serif" font-size="22" fill="#FFE14D" stroke="#3A2614" stroke-width="1.2" transform="rotate(-8 282 86)">TIC !</text>`);
}

function artTir(){
  const r = rng(5); let felt = ""; for(let i=0;i<60;i++) felt += `<circle cx="${(10+r()*300).toFixed(1)}" cy="${(8+r()*84).toFixed(1)}" r=".8" fill="#fff" opacity=".1"/>`;
  return ART_SVG(`<defs><linearGradient id="arW" x2="0" y2="1"><stop offset="0" stop-color="#B07A44"/><stop offset="1" stop-color="#6B4322"/></linearGradient>
      <radialGradient id="arF" cx=".5" cy=".4" r=".8"><stop offset="0" stop-color="#55B85F"/><stop offset="1" stop-color="#2E7A38"/></radialGradient>
      <linearGradient id="arWa" x2="0" y2="1"><stop offset="0" stop-color="#6CC6F0"/><stop offset="1" stop-color="#2D7FC0"/></linearGradient>
      <radialGradient id="arBp" cx=".35" cy=".3"><stop offset="0" stop-color="#FF9A8A"/><stop offset="1" stop-color="#B8222A"/></radialGradient></defs>
    <rect width="320" height="100" fill="url(#arW)"/><rect x="7" y="6" width="306" height="88" rx="6" fill="url(#arF)"/>${felt}
    <rect x="9" y="8" width="302" height="5" fill="#000" opacity=".15"/>
    <rect x="96" y="6" width="16" height="56" fill="#A8713F"/><rect x="96" y="6" width="16" height="4" fill="#C68C54"/><rect x="100" y="62" width="16" height="4" fill="#000" opacity=".2"/>
    <rect x="196" y="40" width="16" height="54" fill="#A8713F"/><rect x="196" y="40" width="16" height="4" fill="#C68C54"/>
    <rect x="128" y="64" width="50" height="22" rx="10" fill="#E8D3A0"/><rect x="140" y="12" width="44" height="22" rx="10" fill="url(#arWa)"/><path d="M146 22q5-3 10 0t10 0t10 0" stroke="#fff" stroke-width="1.4" fill="none" opacity=".6"/>
    <circle cx="240" cy="28" r="9" fill="url(#arBp)"/><circle cx="240" cy="28" r="5.5" fill="none" stroke="#fff" stroke-width="1.6"/>
    <circle cx="284" cy="64" r="8" fill="#0E1A0C"/><circle cx="284" cy="64" r="10" fill="none" stroke="#fff" stroke-width="1.2" opacity=".35"/>
    <path d="M284 64V30" stroke="#EDEDED" stroke-width="2"/><path d="M284 30q10 1 16 5q-7 4-16 6z" fill="#E5484D"/>
    <path d="M44 72Q74 92 92 72Q120 40 150 50Q200 66 230 76Q262 82 278 66" stroke="#fff" stroke-width="2" stroke-dasharray="3 6" fill="none" stroke-linecap="round"/>
    ${artM("arM", 36, 70, 8, "#2E8CFF")}`);
}

function artCasse(){
  const r = rng(9); let stars = ""; for(let i=0;i<40;i++) stars += `<circle cx="${(r()*320).toFixed(1)}" cy="${(r()*100).toFixed(1)}" r="${(.3+r()*.9).toFixed(1)}" fill="#fff" opacity="${(.2+r()*.5).toFixed(2)}"/>`;
  const cols = ["#E5484D","#FF9F1C","#FFC93F","#2FA35A","#22B8CF"]; let bricks = "";
  for(let y=0;y<4;y++) for(let x=0;x<11;x++){ if(y===3 && (x===3||x===4||x===8)) continue; const X = 12+x*27.2, Y = 8+y*12, c = cols[y];
    bricks += `<rect x="${X}" y="${Y}" width="24" height="9.5" rx="2.5" fill="${c}"/><rect x="${X+2}" y="${Y+1.2}" width="20" height="2.6" rx="1.3" fill="#fff" opacity=".35"/><rect x="${X}" y="${Y+7}" width="24" height="2.5" rx="1" fill="#000" opacity=".2"/>` }
  return ART_SVG(`<defs><linearGradient id="akB" x2="0" y2="1"><stop offset="0" stop-color="#26306A"/><stop offset="1" stop-color="#0B0F26"/></linearGradient>
      <linearGradient id="akR" x2="0" y2="1"><stop offset="0" stop-color="#FFE38A"/><stop offset="1" stop-color="#D99A1A"/></linearGradient></defs>
    <rect width="320" height="100" fill="url(#akB)"/>${stars}${bricks}
    <g fill="#FFC93F"><rect x="98" y="46" width="4" height="4" transform="rotate(20 100 48)"/><rect x="112" y="50" width="3" height="3"/><rect x="106" y="56" width="3" height="3" transform="rotate(40 107 57)"/></g>
    <path d="M150 82Q130 66 108 52" stroke="#9ED8FF" stroke-width="5" opacity=".25" stroke-linecap="round" fill="none"/>
    <rect x="122" y="88" width="64" height="8" rx="4" fill="url(#akR)"/><path d="M130 92v4M138 92v4M146 90v6M154 92v4M162 92v4M170 92v4M178 90v6" stroke="#7A4A10" stroke-width="1" opacity=".6"/>
    ${artM("akM", 154, 80, 7, "#2E8CFF", true)}`);
}

function artPachinko(){
  let pegs = ""; for(let rr=0;rr<5;rr++) for(let i=0;i<=rr+5;i++){ const x = 160+(i-(rr+5)/2)*21, y = 14+rr*13; pegs += `<circle cx="${x}" cy="${y}" r="2.6" fill="url(#apgP)"/>` }
  const slots = ["#E5484D","#E8743B","#7B6CF6","#C98E4E","#8E8898","#4A3F5C","#8E8898","#C98E4E","#2A8A74","#34469C","#D9A020"];
  let bulbs = ""; for(let x=10;x<=310;x+=14) bulbs += `<circle cx="${x}" cy="3.5" r="1.6" fill="${(x/14|0)%3?"#FFE9A8":"#FF4FD8"}"/>`;
  return ART_SVG(`<defs><radialGradient id="apgB" cx=".5" cy=".3" r=".9"><stop offset="0" stop-color="#5A2590"/><stop offset=".6" stop-color="#24103F"/><stop offset="1" stop-color="#0C0518"/></radialGradient>
      <radialGradient id="apgP" cx=".35" cy=".3"><stop offset="0" stop-color="#FFF8DA"/><stop offset=".4" stop-color="#F0C35A"/><stop offset="1" stop-color="#7A5418"/></radialGradient>
      <filter id="apgN" x="-20%" y="-50%" width="140%" height="200%"><feGaussianBlur stdDeviation="2.2"/></filter></defs>
    <rect width="320" height="100" fill="url(#apgB)"/>
    <g opacity=".12" fill="#FF8FE0"><path d="M160 0L60 100h30zM160 0L230 100h30zM160 0L140 100h20z"/></g>
    ${bulbs}${pegs}
    <text x="52" y="38" text-anchor="middle" font-family="Lilita One, sans-serif" font-size="17" fill="#FF4FD8" filter="url(#apgN)">PLINKO</text>
    <text x="52" y="38" text-anchor="middle" font-family="Lilita One, sans-serif" font-size="17" fill="#FFD6F5">PLINKO</text>
    <text x="270" y="38" text-anchor="middle" font-family="Lilita One, sans-serif" font-size="14" fill="#39E6FF" filter="url(#apgN)">JACKPOT</text>
    <text x="270" y="38" text-anchor="middle" font-family="Lilita One, sans-serif" font-size="14" fill="#D6FBFF">JACKPOT</text>
    ${slots.map((c,i)=>`<rect x="${49+i*20.4}" y="78" width="17" height="22" rx="3" fill="${c}"/><rect x="${51+i*20.4}" y="80" width="13" height="3.5" rx="1.5" fill="#fff" opacity=".3"/>`).join("")}
    <g fill="#9ED8FF"><circle cx="156" cy="40" r="4" opacity=".12"/><circle cx="160" cy="46" r="5" opacity=".18"/><circle cx="157" cy="53" r="6" opacity=".25"/></g>
    ${artM("apgM", 152, 60, 7, "#2E8CFF", true)}`);
}

function artRoue(){
  const h = ROUE_SEG/2, R = 118;
  const segs = ROUE.map((c,i)=>{ const a = i*ROUE_SEG - 90, p0 = (a-h)*Math.PI/180, p1 = (a+h)*Math.PI/180;
    return `<path d="M160 128L${(160+R*Math.cos(p0)).toFixed(1)} ${(128+R*Math.sin(p0)).toFixed(1)}A${R} ${R} 0 0 1 ${(160+R*Math.cos(p1)).toFixed(1)} ${(128+R*Math.sin(p1)).toFixed(1)}Z" fill="${c.c}" stroke="rgba(255,255,255,.55)" stroke-width="1"/>` }).join("");
  let bulbs = ""; for(let i=0;i<26;i++){ const a = (-180 + i*180/25)*Math.PI/180; bulbs += `<circle cx="${(160+126*Math.cos(a)).toFixed(1)}" cy="${(128+126*Math.sin(a)).toFixed(1)}" r="2.2" fill="${i%2?"#FFE9A8":"#FF4FD8"}"/>` }
  return ART_SVG(`<defs><radialGradient id="arqB" cx=".5" cy=".9" r=".9"><stop offset="0" stop-color="#6B1F7F"/><stop offset="1" stop-color="#1A0A2A"/></radialGradient></defs>
    <rect width="320" height="100" fill="url(#arqB)"/>${segs}<circle cx="160" cy="128" r="${R}" fill="none" stroke="#E9B23A" stroke-width="6"/>${bulbs}
    <circle cx="160" cy="128" r="22" fill="#E9B23A" stroke="#7A4C08" stroke-width="2"/>
    <path d="M160 26 L151 6 Q160 0 169 6 Z" fill="#E5484D" stroke="#5A0E18" stroke-width="1.5"/>`);
}

function artGrattage(){
  return ART_SVG(`<defs><linearGradient id="agrB" x1="0" x2="1"><stop offset="0" stop-color="#FFE6F2"/><stop offset="1" stop-color="#FFD7A8"/></linearGradient><linearGradient id="agrF" x1="0" x2="1"><stop offset="0" stop-color="#C9CDD6"/><stop offset=".5" stop-color="#F4F5F8"/><stop offset="1" stop-color="#B4B8C3"/></linearGradient></defs>
    <rect width="320" height="100" fill="#3B1D4A"/><rect x="60" y="10" width="200" height="82" rx="10" fill="url(#agrB)" stroke="#2B2233" stroke-width="2.5"/>
    ${[0,1,2].map(i=>`<rect x="${78+i*58}" y="30" width="48" height="48" rx="8" fill="${i===1?"#FFB547":"url(#agrF)"}" stroke="#2B2233" stroke-width="1.5"/>`).join("")}
    <text x="160" y="25" text-anchor="middle" font-family="Lilita One" font-size="13" fill="#2B2233">Gratte et gagne !</text>
    <text x="160" y="61" text-anchor="middle" font-family="Lilita One" font-size="18" fill="#fff">20</text>
    <path d="M200 74 l26 -26" stroke="#FFE14D" stroke-width="5" stroke-linecap="round"/>`);
}

function artDistributeur(){
  const cols = ["#FF5FA8","#FFC93F","#2EC4DE","#7CE59A","#8C7CFF","#FF8A3D"]; let b = ""; const r = rng(3);
  for(let i=0;i<16;i++){ const a = r()*Math.PI*2, d = Math.sqrt(r())*30; b += `<circle cx="${(160+Math.cos(a)*d).toFixed(1)}" cy="${(46+Math.sin(a)*d*.85).toFixed(1)}" r="6" fill="${cols[i%6]}"/>` }
  return ART_SVG(`<rect width="320" height="100" fill="#1E3A5A"/>${b}<circle cx="160" cy="46" r="38" fill="rgba(255,255,255,.18)" stroke="rgba(255,255,255,.7)" stroke-width="2"/>
    <path d="M130 82 H190 L196 100 H124 Z" fill="#E5484D"/><circle cx="210" cy="92" r="7" fill="#C9CDD6"/>`);
}

function artMarelle(){
  const c = (x,y,w,h) => `<rect x="${x}" y="${y}" width="${w}" height="${h}"/>`, t = (x,y,n) => `<text x="${x}" y="${y}">${n}</text>`;
  return ART_SVG(`<rect width="320" height="100" fill="#3A3F4D"/><rect width="320" height="100" fill="#2C3140" opacity=".5"/>
    <g transform="translate(160 50) scale(.74) translate(-158 -50)"><g fill="none" stroke="#F4F1EA" stroke-width="2.6" stroke-linejoin="round" opacity=".92">${c(24,34,38,32)}${c(62,34,38,32)}${c(100,34,38,32)}${c(138,16,38,34)}${c(138,50,38,34)}${c(176,34,38,32)}${c(214,16,38,34)}${c(214,50,38,34)}
      <path d="M252 16 A44 34 0 0 1 252 84 Z" stroke="#FFE14D"/></g>
    <g font-family="Caveat" font-weight="700" font-size="20" fill="#F4F1EA" text-anchor="middle">${t(43,57,1)}${t(81,57,2)}${t(119,57,3)}${t(157,40,4)}${t(157,74,5)}${t(195,57,6)}${t(233,40,7)}${t(233,74,8)}<text x="272" y="56" fill="#FFE14D" font-size="18">Ciel</text></g>
    <ellipse cx="121" cy="66" rx="9" ry="3" fill="#000" opacity=".4"/><circle cx="121" cy="58" r="8" fill="#3E7BFA"/><circle cx="118" cy="55" r="2.6" fill="#fff" opacity=".8"/>
    <path d="M290 12 l4 -6 M300 22 l7 -3 M296 90 l6 4" stroke="#FFE14D" stroke-width="2.4" stroke-linecap="round"/></g>`);
}


function artLoterie(){
  const n = [7,13,18], c = ["#E5484D","#FFC93F","#2EC4DE"];
  return ART_SVG(`<rect width="320" height="100" fill="#1B4D3A"/>${n.map((x,i)=>`<circle cx="${110+i*50}" cy="50" r="20" fill="${c[i]}"/><circle cx="${110+i*50}" cy="50" r="12" fill="#fff"/><text x="${110+i*50}" y="55" text-anchor="middle" font-family="Lilita One" font-size="14" fill="#2B2233">${x}</text>`).join("")}`);
}

const MAR_CASES = [
  {n:"1",    lbl:"5",         u:[-75,75],   v:[40,165]},
  {n:"2",    lbl:"10",        u:[-75,75],   v:[165,290]},
  {n:"3",    lbl:"20",        u:[-75,75],   v:[290,415]},
  {n:"4",    lbl:"Classique", u:[-150,0],   v:[415,540]},
  {n:"5",    lbl:"40",        u:[0,150],    v:[415,540]},
  {n:"6",    lbl:"Premium",   u:[-75,75],   v:[540,665]},
  {n:"7",    lbl:"100",       u:[-150,0],   v:[665,790]},
  {n:"8",    lbl:"Collector", u:[0,150],    v:[665,790]},
  {n:"Ciel", lbl:"Mammouth",  u:[-150,150], v:[790,915], ciel:true},
];

const MAR_W = 600, MAR_H = 640, MAR_D = 2000, MAR_K = 1.32, MAR_A = -1047, MAR_B = 1672, MAR_R = 19;   // MAR_R : le rayon de la bille, au sol

const marS = v => MAR_D/(v+MAR_D);

const marP = (u, v, h=0) => { const s = marS(v); return [300 + u*s*MAR_K, MAR_A + MAR_B*s - h*s*MAR_K] };

const MAR_FY = s => MAR_B*s*s/MAR_D;   // l'écrasement du sol : combien de pixels fait une unité de profondeur, à cette distance

const marFlat = (x, y, s) => `translate(${f1(x)} ${f1(y)}) scale(${(s*MAR_K).toFixed(3)} ${MAR_FY(s).toFixed(3)})`;   // écrire « couché » sur le sol

const marLot = c => ROUE.find(x=>x.lbl===c.lbl);

const marCaseOfK = k => MAR_CASES.find(c=>c.lbl===ROUE[k].lbl);

const f1 = n => n.toFixed(1);

function marShape(c){
  if(c.ciel){ let d = ""; for(let i=0;i<=24;i++){ const a = i/24*Math.PI, [x,y] = marP(150*Math.cos(a), 790 + 125*Math.sin(a)); d += `${i?"L":"M"}${f1(x)} ${f1(y)}` } return d+"Z" }
  const [a,b] = c.u, [p,q] = c.v, pts = [marP(a,p), marP(b,p), marP(b,q), marP(a,q)];
  return pts.map(([x,y],i)=>`${i?"L":"M"}${f1(x)} ${f1(y)}`).join("")+"Z";
}

const marMid = c => [(c.u[0]+c.u[1])/2, c.ciel ? 838 : (c.v[0]+c.v[1])/2];

function marLabel(c){
  const [u,v] = marMid(c), [x,y] = marP(u,v), s = marS(v);
  return `<g transform="${marFlat(x, y, s)}"><g class="mrl-lbl" data-n="${c.n}">
    <text x="${c.ciel?0:-50}" y="${c.ciel?-58:-27}" font-size="${c.ciel?46:36}" fill="${c.ciel?"#FFE14D":"#F4F1EA"}" class="mrl-num">${c.n}</text></g></g>`;
}

function marPrize(c){
  const L = marLot(c), [u,v] = marMid(c), [x,y] = marP(u,v), s = marS(v), col = L.c;
  const txt = (tx, ty, size, t, fill="#FFFFFF") => `<text x="${tx}" y="${ty}" font-size="${size}" fill="${fill}" class="mrl-lot">${t}</text>`;
  let lot;
  if(L.roue) lot = `<ellipse cx="0" cy="-13" rx="36" ry="30" fill="#FFE14D" opacity=".22"/><image href="${marbleURL(exSpec("mammouth"),128)}" x="-27" y="-40" width="54" height="54"/>${txt(0, 30, 26, "Mammouth", "#FFE14D")}`;
  else if(L.sac) lot = bagSVG(BAG_BY[L.sac]).replace("<svg", `<svg x="-22" y="-26" width="44" height="53"`) + txt(0, 50, 25, esc(L.lbl), col);
  else lot = `<g transform="translate(-30 18)"><path d="M-25 -11 L-11 0 L-25 11 Z M25 -11 L11 0 L25 11 Z" fill="${col}" stroke="#20232C" stroke-width="2.5" stroke-linejoin="round"/>
      <ellipse rx="15" ry="12" fill="${col}" stroke="#20232C" stroke-width="2.5"/><path d="M-6 -8 L2 8 M3 -9 L9 5" stroke="#fff" stroke-width="3" stroke-linecap="round" opacity=".8"/></g>${txt(20, 36, 50, L.j)}`;
  return `<g transform="${marFlat(x, y, s)}"><g class="mrl-prize" data-n="${c.n}">${lot}</g></g>`;
}

function marDecor(WY){
  const at = (u, v, inner, k=1) => { const [x,y] = marP(u,v), s = marS(v)*k; return `<g transform="${marFlat(x, y, s)}">${inner}</g>` };
  // sur le mur : deux fenêtres de classe éclairées, du lierre qui retombe
  const win = x => `<g transform="translate(${x} ${f1(WY*.16)})"><rect width="64" height="${f1(WY*.58)}" rx="3" fill="#2A1E16"/><rect x="4" y="4" width="56" height="${f1(WY*.58-8)}" fill="#FFD98A" opacity=".85"/>
      <path d="M32 4 V${f1(WY*.58-4)} M4 ${f1(WY*.29)} H60" stroke="#2A1E16" stroke-width="3"/><rect x="4" y="4" width="56" height="${f1(WY*.58-8)}" fill="url(#mrl-glass)"/></g>`;
  const ivy = (x, n) => { let d = ""; for(let i=0;i<n;i++){ const yy = 6+i*9, xx = x + Math.sin(i*1.7)*6; d += `<ellipse cx="${f1(xx)}" cy="${yy}" rx="7" ry="4.5" transform="rotate(${(i*47)%80-40} ${f1(xx)} ${yy})" fill="${i%2?"#3E7A3A":"#4F9446"}"/>` } return d };
  const wall = `<defs><linearGradient id="mrl-glass" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#fff" stop-opacity=".45"/><stop offset=".4" stop-color="#fff" stop-opacity="0"/></linearGradient>
      <radialGradient id="mrl-tree" cx=".5" cy=".5" r=".5"><stop offset="0" stop-color="#0B0E16" stop-opacity=".5"/><stop offset=".7" stop-color="#0B0E16" stop-opacity=".28"/><stop offset="1" stop-color="#0B0E16" stop-opacity="0"/></radialGradient>
      <radialGradient id="mrl-bm" cx=".35" cy=".35" r=".7"><stop offset="0" stop-color="#fff" stop-opacity=".9"/><stop offset=".3" stop-color="#fff" stop-opacity="0"/></radialGradient></defs>
    ${win(150)}${win(386)}<g>${ivy(24, 6)}${ivy(560, 5)}${ivy(300, 3)}</g>`;
  // l'ombre d'un arbre, avec des trous de lumière
  const tree = at(-250, 700, `<ellipse rx="190" ry="150" fill="url(#mrl-tree)"/><ellipse cx="-40" cy="-30" rx="16" ry="11" fill="#FFE9B8" opacity=".08"/><ellipse cx="50" cy="20" rx="12" ry="9" fill="#FFE9B8" opacity=".07"/>`);
  // des bacs à fleurs au pied du mur
  const pot = u => at(u, 1010, `<rect x="-46" y="-14" width="92" height="30" rx="4" fill="#8A5A3A" stroke="#5A3622" stroke-width="3"/>
      ${[-30,-12,6,24,38].map((x,i)=>`<circle cx="${x}" cy="-18" r="${11+i%2*3}" fill="${i%2?"#4F9446":"#3E7A3A"}"/>`).join("")}${[-22,2,30].map((x,i)=>`<circle cx="${x}" cy="-26" r="4.5" fill="${["#FF8FB8","#FFE14D","#FF6B5A"][i]}"/>`).join("")}`, 1);
  // un cartable rouge posé par terre, des bouts de craie, une bouche d'égout, des billes qui traînent
  const bag = at(205, 120, `<g transform="rotate(-14)"><rect x="-38" y="-30" width="76" height="58" rx="10" fill="#C8353B" stroke="#7A1C22" stroke-width="3"/>
      <path d="M-38 -6 H38 V-22 Q38 -30 30 -30 H-30 Q-38 -30 -38 -22 Z" fill="#E0484E" stroke="#7A1C22" stroke-width="3"/><rect x="-8" y="-12" width="16" height="12" rx="2" fill="#FFC93F" stroke="#7A1C22" stroke-width="2"/>
      <path d="M-24 28 q-6 18 10 20 M24 28 q6 18 -10 20" fill="none" stroke="#7A1C22" stroke-width="5" stroke-linecap="round"/></g>`);
  const chalks = at(-170, 40, ["#FF8FB8","#FFE14D","#9FD8FF","#F4F1EA"].map((c,i)=>`<rect x="${-30+i*18}" y="${i%2*8-6}" width="30" height="9" rx="4" transform="rotate(${[-20,15,-35,8][i]} ${-15+i*18} 0)" fill="${c}" stroke="rgba(0,0,0,.25)" stroke-width="1.5"/>`).join("") + `<path d="M-40 18 q20 -6 40 2" stroke="#FFE14D" stroke-width="3" fill="none" opacity=".5"/>`);
  const grate = at(238, 520, `<ellipse rx="40" ry="40" fill="#2A2E38" stroke="#555B68" stroke-width="5"/>${[-24,-12,0,12,24].map(x=>`<rect x="${x-3}" y="-30" width="6" height="60" rx="2" fill="#1A1D25"/>`).join("")}`);
  const marbles = [[-232,250,"#4C8DF6"],[-205,275,"#FF6B5A"],[222,300,"#3DBE7A"],[252,880,"#B07CF0"]].map(([u,v,c])=>at(u, v, `<ellipse cx="2" cy="10" rx="13" ry="5" fill="#000" opacity=".25"/><circle r="12" fill="${c}"/><circle r="12" fill="url(#mrl-bm)"/>`)).join("");
  return wall + tree + pot(-210) + pot(210) + grate + bag + chalks + marbles;
}

function marBoard(){
  const cols = [...new Set(MAR_CASES.map(c=>marLot(c).c))];
  const pat = cols.map((c,i)=>`<pattern id="mrl-h${i}" width="9" height="9" patternUnits="userSpaceOnUse" patternTransform="rotate(-32)"><path d="M0 2 H9 M0 6.5 H9" stroke="${c}" stroke-width="2.2" opacity=".9"/></pattern>`).join("");
  const hatch = c => `url(#mrl-h${cols.indexOf(marLot(c).c)})`;
  // les feuilles mortes et les petits dessins à la craie, toujours au même endroit
  const r = rng(11); let leaves = "";
  for(let i=0;i<14;i++){ const u = (r()-.5)*560, v = r()*1100-40; if(Math.abs(u)<175 && v>20 && v<930) continue;
    const [x,y] = marP(u,v), s = marS(v), a = r()*360, c = ["#C9772E","#E0A13A","#9E4B22","#B8862F"][i%4];
    leaves += `<path transform="translate(${f1(x)} ${f1(y)}) rotate(${a.toFixed(0)}) scale(${(s*1.1).toFixed(2)} ${(s*.75).toFixed(2)})" d="M-9 0 Q0 -7 9 0 Q0 7 -9 0Z M-9 0 H11" fill="${c}" stroke="rgba(60,30,10,.5)" stroke-width="1"/>` }
  const doodle = (u, v, d, col="#F4F1EA", sw=4) => { const [x,y] = marP(u,v), s = marS(v); return `<path transform="${marFlat(x, y, s)}" d="${d}" fill="none" stroke="${col}" stroke-width="${sw}" stroke-linecap="round" stroke-linejoin="round"/>` };
  const [tx, ty] = marP(0, 6), [lx0, ly] = marP(-120, 26), [lx1] = marP(120, 26), WY = f1(marP(0,1050)[1]);
  return `<svg class="mrl-svg" viewBox="0 0 ${MAR_W} ${MAR_H}" aria-hidden="true">
    <defs>${pat}
      <filter id="mrl-chalk" x="-5%" y="-5%" width="110%" height="110%"><feTurbulence type="fractalNoise" baseFrequency="1.1" numOctaves="2" seed="4" result="n"/>
        <feDisplacementMap in="SourceGraphic" in2="n" scale="3.4" result="d"/><feColorMatrix in="n" values="0 0 0 0 0  0 0 0 0 0  0 0 0 0 0  0 0 0 -2.2 1.75" result="m"/><feComposite in="d" in2="m" operator="in"/></filter>
      <filter id="mrl-grain"><feTurbulence type="fractalNoise" baseFrequency=".95" numOctaves="3" stitchTiles="stitch"/><feColorMatrix values="0 0 0 0 1  0 0 0 0 1  0 0 0 0 1  0 0 0 .9 -.32"/></filter>
      <linearGradient id="mrl-sol" x1="0" y1="0" x2="0" y2="1"><stop offset="0" stop-color="#2C3140"/><stop offset=".25" stop-color="#3A3F4D"/><stop offset="1" stop-color="#4A4E58"/></linearGradient>
      <radialGradient id="mrl-lamp" cx=".5" cy=".55" r=".65"><stop offset="0" stop-color="#FFE9B8" stop-opacity=".2"/><stop offset=".55" stop-color="#FFE9B8" stop-opacity=".05"/><stop offset="1" stop-color="#000" stop-opacity=".45"/></radialGradient>
      <pattern id="mrl-brick" width="56" height="26" patternUnits="userSpaceOnUse"><rect width="56" height="26" fill="#7A3F31"/><path d="M0 12.5 H56 M0 25.5 H56 M27 0 V12.5 M0 13 V25.5 M55.5 13 V25.5" stroke="#4E2820" stroke-width="2.4"/>
        <rect x="2" y="2" width="22" height="8" fill="#8E4A3A" opacity=".55"/><rect x="31" y="15" width="20" height="8" fill="#6A372B" opacity=".6"/></pattern>
    </defs>
    <rect width="${MAR_W}" height="${MAR_H}" fill="url(#mrl-sol)"/>
    <rect width="${MAR_W}" height="${MAR_H}" filter="url(#mrl-grain)" opacity=".5"/>
    <path d="M${f1(marP(-290,-40)[0])} ${f1(marP(-290,-40)[1])} L${f1(marP(-290,1050)[0])} ${f1(marP(-290,1050)[1])} M${f1(marP(290,-40)[0])} ${f1(marP(290,-40)[1])} L${f1(marP(290,1050)[0])} ${f1(marP(290,1050)[1])}" stroke="#E9C64A" stroke-width="5" opacity=".3" stroke-dasharray="40 18"/>
    <g class="mrl-wall"><rect x="0" y="0" width="${MAR_W}" height="${WY}" fill="url(#mrl-brick)"/>
      <rect x="0" y="${WY-7}" width="${MAR_W}" height="7" fill="#5A2E24"/>
      <rect x="0" y="0" width="${MAR_W}" height="${WY}" fill="url(#mrl-lamp)" opacity=".8"/>
      <g filter="url(#mrl-chalk)" fill="none" stroke="#F4F1EA" stroke-width="3.5" stroke-linecap="round" opacity=".75">
        <path d="M60 22 q7 -12 14 0 q7 -12 14 0 q-14 17 -14 17 q0 0 -14 -17z" stroke="#FF8FB8" stroke-width="3"/>
        <text x="470" y="34" font-family="Caveat" font-weight="700" font-size="26" fill="#F4F1EA" stroke="none" transform="rotate(-4 470 34)">Tikalo !</text></g></g>
    ${marDecor(WY)}
    ${leaves}
    <g filter="url(#mrl-chalk)" opacity=".55">
      ${doodle(-200, 150, "M-26 0 a26 20 0 1 0 52 0 a26 20 0 1 0 -52 0 M-10 -4 v2 M10 -4 v2 M-12 8 q12 10 24 0", "#FFE14D")}
      ${doodle(205, 380, "M-30 -20 v40 M-10 -20 v40 M-44 -6 h44 M-44 8 h44 M-34 -14 l8 8 M-26 -14 l-8 8 M-6 2 a5 5 0 1 0 0.1 0", "#9FD8FF", 3.5)}
      ${doodle(-212, 600, "M0 -24 L7 -8 L24 -8 L10 3 L15 20 L0 10 L-15 20 L-10 3 L-24 -8 L-7 -8 Z", "#FF8FB8")}
      ${doodle(200, 820, "M-30 0 C-20 -24 20 -24 30 0 M-26 6 h52", "#B7F0A0")}
    </g>
    <g class="mrl-fills">${MAR_CASES.map(c=>`<path d="${marShape(c)}" fill="${hatch(c)}" class="mrl-fill" data-n="${c.n}"/>`).join("")}</g>
    <g filter="url(#mrl-chalk)">
      <g fill="none" stroke="#F4F1EA" stroke-width="4.5" stroke-linejoin="round" stroke-linecap="round">${MAR_CASES.map(c=>`<path d="${marShape(c)}"/>`).join("")}</g>
      ${(()=>{ let d = ""; for(let i=0;i<11;i++){ const a = Math.PI*(.06+.88*i/10), p = (r)=>marP(r*Math.cos(a), 790 + r*.83*Math.sin(a)), [x0,y0] = p(166), [x1,y1] = p(192); d += `M${f1(x0)} ${f1(y0)}L${f1(x1)} ${f1(y1)}` }
        return `<path d="${d}" stroke="#FFE14D" stroke-width="4" stroke-linecap="round" opacity=".85"/>` })()}
      <g font-family="Caveat" font-weight="700" text-anchor="middle">${MAR_CASES.map(marLabel).join("")}</g>
      <path d="M${f1(lx0)} ${f1(ly)} L${f1(lx1)} ${f1(ly)}" stroke="#F4F1EA" stroke-width="4" stroke-dasharray="14 10" stroke-linecap="round" opacity=".8"/>
      <g transform="${marFlat(tx, ty, marS(6))}"><text x="0" y="12" font-family="Caveat" font-weight="700" font-size="40" fill="#F4F1EA" text-anchor="middle" opacity=".85">TERRE</text></g>
    </g>
    <g class="mrl-prizes">${MAR_CASES.map(marPrize).join("")}</g>
    <g filter="url(#mrl-chalk)"><path id="mrl-hi" class="mrl-hi" d="" pathLength="100" fill="none" stroke="#FFE14D" stroke-width="8" stroke-linejoin="round" stroke-linecap="round"/></g>
  </svg>`;
}

const DS_COLS = TK.map(t=>TYPES[t].rc), DS_SH = [null, "#C78BFF", "#FFC93F", "#BFEFFF"];

function distMachine(){
  // (9 octobre 2026) les billes du globe en version cartoon : couleurs de bonbon, contour foncé, un reflet blanc et parfois une virgule claire
  const r = rng(7), CART = ["#FF5FA8","#FFC93F","#2EC4DE","#7CE59A","#8C7CFF","#FF8A3D","#FF6B6B","#4FC3F7","#F7E04A","#C77DFF"]; let balls = "", n = 0;
  for(let row=0, y=242; y>58; row++, y-=19){ const half = Math.sqrt(Math.max(0, 104*104-(y-150)*(y-150)))-10;
    for(let x=150-half+(row%2)*10; x<=150+half; x+=21){ const sz = 9+r()*4, c = CART[(n*7+row)%CART.length], cx = x+(r()-.5)*4, cy = y+(r()-.5)*3, a = r()*360|0, f = v => v.toFixed(1); n++;
      balls += `<g class="ds-mb"><circle cx="${f(cx)}" cy="${f(cy)}" r="${f(sz)}" fill="${shade(c,-.28)}" stroke="${shade(c,-.6)}" stroke-width="1.6"/>
        <circle cx="${f(cx-sz*.12)}" cy="${f(cy-sz*.12)}" r="${f(sz*.78)}" fill="${c}"/>
        ${n%3 ? `<path d="M${f(cx-sz*.55)} ${f(cy+sz*.15)} Q${f(cx)} ${f(cy-sz*.5)} ${f(cx+sz*.55)} ${f(cy+sz*.1)}" stroke="${shade(c,.55)}" stroke-width="${f(sz*.22)}" stroke-linecap="round" fill="none" transform="rotate(${a} ${f(cx)} ${f(cy)})"/>` : ""}
        <ellipse cx="${f(cx-sz*.38)}" cy="${f(cy-sz*.42)}" rx="${f(sz*.3)}" ry="${f(sz*.18)}" fill="#fff" opacity=".9" transform="rotate(-35 ${f(cx-sz*.38)} ${f(cy-sz*.42)})"/>
        <circle cx="${f(cx+sz*.35)}" cy="${f(cy+sz*.38)}" r="${f(sz*.09)}" fill="#fff" opacity=".6"/></g>` } }
  let lights = ""; for(let i=0;i<11;i++) lights += `<circle class="ds-lt" cx="${84+i*13.2}" cy="286" r="3.6" style="--d:${(i*.05).toFixed(2)}s"/>`;
  for(let i=0;i<8;i++) lights += `<circle class="ds-lt" cx="${74-i*1.6}" cy="${300+i*15}" r="3.2" style="--d:${(.55+i*.05).toFixed(2)}s"/><circle class="ds-lt" cx="${226+i*1.6}" cy="${300+i*15}" r="3.2" style="--d:${(.55+i*.05).toFixed(2)}s"/>`;
  return `<svg viewBox="0 0 300 440" aria-hidden="true"><defs>
    <radialGradient id="dsG" cx=".32" cy=".26" r=".9"><stop offset="0" stop-color="#fff" stop-opacity=".55"/><stop offset=".35" stop-color="#EAF6FF" stop-opacity=".08"/><stop offset=".85" stop-color="#9CC4E8" stop-opacity=".14"/><stop offset="1" stop-color="#6E9CC8" stop-opacity=".5"/></radialGradient>
    <linearGradient id="dsR" x1="0" x2="1"><stop offset="0" stop-color="#8E1220"/><stop offset=".3" stop-color="#E5484D"/><stop offset=".55" stop-color="#FF7A7E"/><stop offset=".75" stop-color="#D23A42"/><stop offset="1" stop-color="#7E0F1C"/></linearGradient>
    <linearGradient id="dsM" x1="0" x2="1"><stop offset="0" stop-color="#7D818B"/><stop offset=".45" stop-color="#fff"/><stop offset=".6" stop-color="#C9CDD6"/><stop offset="1" stop-color="#6C707A"/></linearGradient>
    <linearGradient id="dsW" x1="0" y1="0" x2="1" y2="1"><stop offset="0" stop-color="#2A0A12"/><stop offset="1" stop-color="#4A0F1C"/></linearGradient>
    <clipPath id="dsC"><circle cx="150" cy="150" r="108"/></clipPath><clipPath id="dsWC"><rect x="92" y="330" width="86" height="56" rx="10"/></clipPath></defs>
    <ellipse cx="150" cy="432" rx="118" ry="9" fill="rgba(40,10,20,.35)"/>
    <rect x="134" y="12" width="32" height="14" rx="5" fill="url(#dsM)"/><path d="M82 46 Q150 18 218 46 L213 54 H87 Z" fill="url(#dsR)" stroke="#5A0E18" stroke-width="2"/>
    <circle cx="150" cy="150" r="110" fill="rgba(200,230,255,.1)"/>
    <g clip-path="url(#dsC)">${balls}</g>
    <circle cx="150" cy="150" r="110" fill="url(#dsG)" stroke="rgba(255,255,255,.8)" stroke-width="3.5"/>
    <path d="M78 92 Q98 58 136 48" stroke="#fff" stroke-width="8" stroke-linecap="round" fill="none" opacity=".55"/><circle cx="204" cy="206" r="7" fill="#fff" opacity=".3"/>
    <rect x="74" y="256" width="152" height="18" rx="6" fill="url(#dsM)" stroke="#55595F" stroke-width="1.5"/>
    <path d="M80 274 H220 L236 420 H64 Z" fill="url(#dsR)" stroke="#5A0E18" stroke-width="2.5" stroke-linejoin="round"/>
    <path d="M88 280 H104 L98 414 H74 Z" fill="#fff" opacity=".12"/>
    ${lights}
    <rect x="104" y="294" width="92" height="28" rx="9" fill="#5A0E18"/><text x="150" y="315" text-anchor="middle" font-family="Lilita One" font-size="19" fill="#FFE9A8" letter-spacing="1.5">TIKALO</text>
    <rect x="92" y="330" width="86" height="56" rx="10" fill="url(#dsW)" stroke="#2A050B" stroke-width="2"/>
    <g clip-path="url(#dsWC)"><path d="M96 344 L166 356 M174 362 L100 376" stroke="#C9CDD6" stroke-width="3" stroke-linecap="round" opacity=".8"/>
      <circle id="ds-mini" cx="-50" cy="-50" r="9" fill="#B9B6C6" stroke="#fff" stroke-width="1.5"/></g>
    <rect x="94" y="332" width="18" height="52" rx="6" fill="#fff" opacity=".1"/>
    <circle class="ds-ring2" cx="208" cy="360" r="38" fill="none" stroke="#FFE14D" stroke-width="3" stroke-dasharray="7 7"/>
    <g class="ds-crank" id="ds-crank" style="transform-origin:208px 360px"><circle cx="208" cy="360" r="19" fill="url(#dsM)" stroke="#55595F" stroke-width="2"/><circle cx="208" cy="360" r="7" fill="#C9CDD6" stroke="#55595F"/><rect x="205" y="334" width="6" height="28" rx="3" fill="#55595F"/><circle cx="208" cy="334" r="8" fill="#FFC93F" stroke="#9E7A1C" stroke-width="2"/></g>
    <circle class="ds-grab" id="ds-grab" cx="208" cy="360" r="44" fill="transparent"/>
    <path d="M110 392 H190 V414 Q150 422 110 414 Z" fill="#1A0408" stroke="#2A050B" stroke-width="2"/><path class="ds-flap" id="ds-flap" d="M112 392 H188 V400 H112 Z" fill="url(#dsM)" opacity=".92"/>
  </svg>`;
}

const CZ_SH = [null, "#C78BFF", "#FFC93F", "#EAFBFF"];

function czPot(){
  let bub = ""; for(let i=0;i<9;i++) bub += `<circle class="cz-bub" cx="${62+i*15}" cy="62" r="${3+(i*7)%5}" style="--d:${(i*.23).toFixed(2)}s;--x:${((i%3)-1)*4}px"/>`;
  return `<svg class="cz-pot" viewBox="0 0 240 210" aria-hidden="true"><defs>
      <radialGradient id="czL" cx=".5" cy=".4" r=".7"><stop offset="0" stop-color="#fff" stop-opacity=".55"/><stop offset=".45" stop-color="var(--lq)"/><stop offset="1" stop-color="var(--lq)"/></radialGradient>
      <linearGradient id="czI" x1="0" x2="1"><stop offset="0" stop-color="#1A1A22"/><stop offset=".35" stop-color="#4A4A58"/><stop offset=".55" stop-color="#2E2E38"/><stop offset="1" stop-color="#121218"/></linearGradient></defs>
    <g class="cz-fire"><path d="M80 196 Q86 170 98 182 Q102 156 118 176 Q124 150 138 178 Q146 160 152 184 Q162 172 162 196 Z" fill="#FF8A1F"/><path d="M96 198 Q102 182 110 190 Q116 172 126 188 Q134 176 142 198 Z" fill="#FFE14D"/></g>
    <path d="M70 186 l-10 18 M170 186 l10 18" stroke="#1A1A22" stroke-width="8" stroke-linecap="round"/>
    <path d="M36 70 Q30 180 120 186 Q210 180 204 70 Z" fill="url(#czI)" stroke="#0C0C12" stroke-width="3"/>
    <path d="M52 92 Q54 150 92 168" stroke="#fff" stroke-width="6" stroke-linecap="round" fill="none" opacity=".12"/>
    <ellipse class="cz-liq" cx="120" cy="66" rx="80" ry="17" fill="url(#czL)"/>
    <g class="cz-bubs">${bub}</g>
    <ellipse cx="120" cy="64" rx="90" ry="20" fill="none" stroke="#3A3A46" stroke-width="10"/>
    <ellipse cx="120" cy="62" rx="90" ry="20" fill="none" stroke="#5A5A6A" stroke-width="3" opacity=".7"/>
  </svg>`;
}

const LOGO_SPEC = {seed:hash("vitrine"+TK[1]), type:TK[1], family:0, pal:0, shiny:0};   // la bille du logo et de l'onglet

