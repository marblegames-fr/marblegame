// (16 octobre 2026) La Pichenette : le premier jeu à deux de Tikalo. Le moteur seul (règles, terrains, physique, ordi),
// sans dessin : le même fichier sert à la maquette (maquette-pichenette.html), au banc d'essai (banc-pichenette.mjs)
// et, plus tard, au serveur qui rejouera chaque tir (le résultat d'un tir doit être le même partout).
// La physique est celle des mini-jeux (aStep dans index.html) : pas fixes, 4 sous-pas par image ; pas de Math.random,
// pas de Math.hypot (deux navigateurs pourraient ne pas donner exactement le même chiffre) : seulement + − × ÷ et Math.sqrt.
(function(root){
"use strict";
const AW = 900, AH = 520, AB = 22;
let VMAX = 21;
const R_TIR = 13.2, R_BILLE = 13.2, R_DORE = 17.25;   // comme radOf("bille") et radOf("calot") dans le jeu
const CX = AW/2, CY = AH/2;
const len = (x, y) => Math.sqrt(x*x + y*y);
// le freinage du sol (le même que les mini-jeux) : fric proche de 1 = ça glisse, plus bas = ça freine
function rollFric(sp, fric){ const k = 1-fric, damp = sp>4 ? k*.6 : k*(.2+.4*sp/4); return Math.max(0, 1-damp-.0035/Math.max(sp,1e-6)) }

/* ---------- les règles (chacune se change dans la maquette) ---------- */
const RULES = {
  tirs: 10,            // tirs par joueur
  enchaine: 3,         // tirs d'affilée au plus quand on marque (« qui marque rejoue »)
  ouverture: false,    // le tout premier tir de la partie donne-t-il le droit de rejouer ?
  tac: 2,              // points pour avoir sorti du rond la tireuse adverse (« Tac ! »)
  dore: 3,             // points du Calot doré
  pot: 2,              // (le Pot) points d'une bille tombée dans le pot
  miseEnJeu: true,
  depuisRond: false,   // peut-on tirer depuis le rond ? (non : une tireuse arrêtée dans le rond revient à sa ligne, à ton tour suivant)
  ecart: 10,            // l'espace entre deux billes du rond
  force: 21,           // la vitesse d'une pichenette à fond (les mini-jeux : 21)     // qui commence : la mise en jeu (le plus près du milieu) ; sinon pile ou face
};

/* ---------- les terrains ---------- */
// Tous symétriques gauche-droite : les deux joueurs ont exactement le même terrain devant eux.
// Joueur 0 à gauche (ligne x = 95), joueur 1 à droite (x = 805).
const sym = list => list.flatMap(o => o.x1!=null ? [o, {...o, x1:AW-o.x1, x2:AW-o.x2}] : o.x===CX ? [o] : [o, {...o, x:AW-o.x}]);
const SHAPES = {
  croix: d => [[0,0,1],[d,0],[2*d,0],[3*d,0],[-d,0],[-2*d,0],[-3*d,0],[0,d],[0,2*d],[0,-d],[0,-2*d],[0,3*d],[0,-3*d]],
  anneau: d => [[0,0,1], ...Array.from({length:12}, (_,i)=>[Math.cos(i*Math.PI/6)*d*2.3, Math.sin(i*Math.PI/6)*d*2.3])],
  losange: d => { const o = [[0,0,1]]; for(let i=-2;i<=2;i++) for(let j=-2;j<=2;j++){ if(Math.abs(i)+Math.abs(j)>2 || (!i && !j)) continue; o.push([i*d, j*d]) } return o },
  // 1, 2, 3, 4, 3 billes par rangée ; le Calot doré au milieu de la 3e
  triangle: d => { const o = []; [1, 2, 3, 4, 3].forEach((n, k)=>{ for(let j=0;j<n;j++){ const x = (j-(n-1)/2)*d; o.push([x, (k-2)*d*.87, k===2 && j===1 ? 1 : 0]) } }); return o },
  pot: d => Array.from({length:12}, (_,i)=>[Math.cos(i*Math.PI/6 + Math.PI/12)*d*2.6, Math.sin(i*Math.PI/6 + Math.PI/12)*d*2.6]),
};
const MAPS = {
  cour:{name:"La Cour", desc:"L'asphalte de la cour, un rond à la craie. Le terrain classique : rien ne te cache, rien ne te protège.",
    fric:.94, circle:{x:CX, y:CY, r:185}, shape:"croix", obstacles:[], zones:[], segs:[]},
  preau:{name:"Le Préau", desc:"Le carrelage du préau glisse un peu. Quatre piliers renvoient les billes : les tirs en bande deviennent possibles.",
    // (banc d'essai : plus glissant (0,955), le premier tir éparpillait tout et le second gagnait 2 fois sur 3)
    fric:.945, circle:{x:CX, y:CY, r:180}, shape:"anneau", obstacles:sym([{x:300, y:118, r:24}, {x:300, y:402, r:24}]), zones:[], segs:[]},
  sable:{name:"Le Bac à sable", desc:"Le sable freine tout. Deux bosses entre toi et le rond : passe à côté, ou tire fort.",
    fric:.93, circle:{x:CX, y:CY, r:170}, shape:"losange", obstacles:[], zones:sym([{x:215, y:260, r:62, fric:.86}]), segs:[]},
  marronnier:{name:"Sous le marronnier", desc:"De la terre battue, des racines qui sortent du sol et deux marrons tombés de l'arbre. Il faut viser entre.",
    fric:.935, circle:{x:CX, y:CY, r:180}, shape:"triangle",
    obstacles:[{x:CX, y:78, r:13}, {x:CX, y:AH-78, r:13}], zones:[],
    segs:sym([{x1:250, y1:70, x2:330, y2:175, r:9}, {x1:255, y1:455, x2:325, y2:360, r:9}])},
  pot:{name:"Le Pot", desc:"Un trou au milieu du rond : une bille sortie du rond vaut 1, une bille poussée dans le pot en vaut 2. Ta tireuse dans le pot : Plouf, retour à ta ligne.",
    fric:.94, circle:{x:CX, y:CY, r:185}, shape:"pot", pot:{x:CX, y:CY, r:19}, obstacles:[], zones:[], segs:[]},
};
const LINE_X = [95, AW-95], LINE_Y = [AB+70, AH-AB-70];

/* ---------- une partie ---------- */
function newGame(mapId, rules={}, seed=1){
  const map = MAPS[mapId], R = {...RULES, ...rules}, balls = [];
  const d = 2*R_BILLE + R.ecart;   // (assez pour que le Calot doré, plus gros, ne touche pas ses voisines)
  SHAPES[map.shape](d).forEach(([x, y, dore], i)=>{ const r = dore ? R_DORE : R_BILLE;
    balls.push({id:"p"+i, kind:dore ? "dore" : "pile", x:map.circle.x + x, y:map.circle.y + y, vx:0, vy:0, r, m:r*r*r, alive:true, sunk:false}) });
  [0, 1].forEach(s=>balls.push({id:"t"+s, kind:"tir", side:s, x:LINE_X[s], y:CY, vx:0, vy:0, r:R_TIR, m:R_TIR*R_TIR*R_TIR, alive:false, sunk:false, placed:false}));
  return {mapId, R, seed, balls, score:[0, 0], butin:[[], []], left:[R.tirs, R.tirs], turn:0, chain:0, opening:true, phase:R.miseEnJeu ? "lag" : "play",
    lag:[null, null], log:[], winner:null, moving:false};
}
const clone = G => ({...G, balls:G.balls.map(b=>({...b})), score:[...G.score], butin:G.butin.map(x=>[...x]), left:[...G.left], lag:[...G.lag], log:G.log});
const tireuse = (G, s) => G.balls[G.balls.length - 2 + s];
const inCircle = (map, b) => { const dx = b.x - map.circle.x, dy = b.y - map.circle.y; return dx*dx + dy*dy < map.circle.r*map.circle.r };
const value = (G, b) => b.sunk ? G.R.pot : b.kind==="dore" ? G.R.dore : 1;

/* ---------- la physique : une image (4 sous-pas). Rend la liste de ce qui s'est passé (pour les sons et les effets) ---------- */
function step(map, balls, ev){
  const live = balls.filter(b=>b.alive);
  for(let sub=0; sub<4; sub++){
    for(const b of live){
      b.x += b.vx/4; b.y += b.vy/4;
      const lo = AB + b.r, hiX = AW - AB - b.r, hiY = AH - AB - b.r;
      if(b.x<lo){ b.x = lo; if(b.vx<0){ ev && ev.push({t:"mur", v:-b.vx, x:b.x, y:b.y}); b.vx *= -.68 } } else if(b.x>hiX){ b.x = hiX; if(b.vx>0){ ev && ev.push({t:"mur", v:b.vx, x:b.x, y:b.y}); b.vx *= -.68 } }
      if(b.y<lo){ b.y = lo; if(b.vy<0){ ev && ev.push({t:"mur", v:-b.vy, x:b.x, y:b.y}); b.vy *= -.68 } } else if(b.y>hiY){ b.y = hiY; if(b.vy>0){ ev && ev.push({t:"mur", v:b.vy, x:b.x, y:b.y}); b.vy *= -.68 } }
      for(const p of map.obstacles){ const dx = b.x - p.x, dy = b.y - p.y, d = len(dx, dy);
        if(d < p.r + b.r && d > 0){ const nx = dx/d, ny = dy/d; b.x = p.x + nx*(p.r + b.r); b.y = p.y + ny*(p.r + b.r);
          const vn = b.vx*nx + b.vy*ny; if(vn<0){ b.vx -= 1.5*vn*nx; b.vy -= 1.5*vn*ny; ev && ev.push({t:"obs", v:-vn, x:b.x, y:b.y}) } } }
      for(const s of map.segs){ const ex = s.x2 - s.x1, ey = s.y2 - s.y1, L2 = ex*ex + ey*ey;
        let k = ((b.x - s.x1)*ex + (b.y - s.y1)*ey)/L2; k = k<0 ? 0 : k>1 ? 1 : k;
        const px = s.x1 + ex*k, py = s.y1 + ey*k, dx = b.x - px, dy = b.y - py, d = len(dx, dy);
        if(d < s.r + b.r && d > 0){ const nx = dx/d, ny = dy/d; b.x = px + nx*(s.r + b.r); b.y = py + ny*(s.r + b.r);
          const vn = b.vx*nx + b.vy*ny; if(vn<0){ b.vx -= 1.55*vn*nx; b.vy -= 1.55*vn*ny; ev && ev.push({t:"racine", v:-vn, x:b.x, y:b.y}) } } }
    }
    for(let i=0;i<live.length;i++) for(let j=i+1;j<live.length;j++){
      const a = live[i], c = live[j], dx = c.x - a.x, dy = c.y - a.y, rr = a.r + c.r;
      if(dx > rr || dx < -rr || dy > rr || dy < -rr) continue;
      const d = len(dx, dy);
      if(d < rr && d > 0){ const nx = dx/d, ny = dy/d, ov = rr - d, ia = 1/a.m, ic = 1/c.m;
        a.x -= nx*ov*ia/(ia+ic); a.y -= ny*ov*ia/(ia+ic); c.x += nx*ov*ic/(ia+ic); c.y += ny*ov*ic/(ia+ic);
        const vn = (c.vx - a.vx)*nx + (c.vy - a.vy)*ny;
        if(vn<0){ const J = -1.92*vn/(ia+ic); a.vx -= J*ia*nx; a.vy -= J*ia*ny; c.vx += J*ic*nx; c.vy += J*ic*ny; ev && ev.push({t:"choc", v:-vn, x:a.x + nx*a.r, y:a.y + ny*a.r, a:a.id, b:c.id}) } }
    }
  }
  let any = false;
  for(const b of live){
    let fric = map.fric;
    for(const z of map.zones){ const dx = b.x - z.x, dy = b.y - z.y; if(dx*dx + dy*dy < z.r*z.r){ fric = z.fric; break } }
    let sp = len(b.vx, b.vy); const m = rollFric(sp, fric); b.vx *= m; b.vy *= m; sp *= m;
    if(map.pot){ const hx = map.pot.x - b.x, hy = map.pot.y - b.y, hd = len(hx, hy);
      if(hd < map.pot.r){ if(sp < 9){ b.alive = false; b.sunk = true; b.x = map.pot.x; b.y = map.pot.y; b.vx = b.vy = 0; ev && ev.push({t:"pot", id:b.id, x:b.x, y:b.y}); continue }
        b.vx += hx*.05; b.vy += hy*.05 }
      else if(hd < map.pot.r + 12 && sp < 3){ b.vx += hx*.012; b.vy += hy*.012 }
      sp = len(b.vx, b.vy) }
    if(sp < .03){ b.vx = b.vy = 0 } else any = true;
  }
  return any;
}

/* ---------- un tir ---------- */
// shot = {y, ang, p} : y = la place sur sa ligne (si la tireuse n'est pas encore sur le terrain), ang = la direction, p = la force (0 à 1)
function place(G, shot){
  const t = tireuse(G, G.turn);
  if(!t.placed){ const y = Math.max(LINE_Y[0], Math.min(LINE_Y[1], shot.y ?? CY));
    Object.assign(t, {x:LINE_X[G.turn], y, alive:true, placed:true, sunk:false, vx:0, vy:0}) }
  const p = Math.max(0, Math.min(1, shot.p));
  t.vx = Math.cos(shot.ang)*p*G.R.force; t.vy = Math.sin(shot.ang)*p*G.R.force;
  G.before = G.balls.map(b=>({id:b.id, alive:b.alive, inside:b.alive && inCircle(MAPS[G.mapId], b)}));
  G.moving = true; G.shot = shot;
  return t;
}
// après le tir, une fois tout arrêté : qui marque quoi, qui rejoue, qui joue ensuite
function resolve(G){
  const map = MAPS[G.mapId], me = G.turn, op = 1 - me, out = {pris:[], tac:false, plouf:false, pts:0, rejoue:false, fin:false};
  G.balls.forEach((b, i)=>{ const was = G.before[i];
    if(b.kind==="pile" || b.kind==="dore"){
      if(was.alive && (b.sunk || !inCircle(map, b))){ const v = value(G, b); out.pris.push({id:b.id, kind:b.kind, v, sunk:b.sunk}); out.pts += v; b.alive = false; G.butin[me].push(b.id) } }
    else if(b.side===op){ if(was.inside && (b.sunk || !inCircle(map, b))){ out.tac = true; out.pts += G.R.tac }
      if(b.sunk){ b.placed = false; b.alive = false; b.sunk = false } }
    else if(b.side===me && b.sunk){ out.plouf = true; b.placed = false; b.alive = false; b.sunk = false } });
  G.score[me] += out.pts; G.left[me]--;
  const scored = out.pts > 0, open = G.opening; G.opening = false;
  out.rejoue = scored && (G.R.ouverture || !open) && G.chain + 1 < G.R.enchaine && G.left[me] > 0;
  const pileLeft = G.balls.some(b=>(b.kind==="pile" || b.kind==="dore") && b.alive);
  G.log.push({turn:me, shot:G.shot, ...out});
  if(!pileLeft || (G.left[0]<=0 && G.left[1]<=0)){ out.fin = true; endGame(G) }
  else if(out.rejoue){ G.chain++ }
  else { G.chain = 0; if(G.left[op] > 0) G.turn = op }
  G.moving = false; G.before = null;
  if(!out.fin) out.retour = startTurn(G);
  return out;
}
// au début de chaque tir : une tireuse arrêtée dans le rond revient à sa ligne (on ne tire pas depuis le rond)
function startTurn(G){ const t = tireuse(G, G.turn);
  if(!G.R.depuisRond && t.alive && inCircle(MAPS[G.mapId], t)){ t.alive = false; t.placed = false; return true } return false }
function endGame(G){
  G.phase = G.score[0]===G.score[1] ? "egalite" : "fin";
  G.winner = G.score[0]===G.score[1] ? null : G.score[0] > G.score[1] ? 0 : 1;
  if(G.phase==="egalite"){ G.lag = [null, null] }   // mort subite : une mise en jeu départage
}
// un tir complet d'un coup (le banc d'essai, l'ordi, et plus tard le serveur)
function play(G, shot){ place(G, shot); const map = MAPS[G.mapId]; for(let f=0; f<4000 && step(map, G.balls); f++); return resolve(G) }

/* ---------- la mise en jeu : chacun tire vers le milieu, sur un terrain vide ; le plus près commence ---------- */
function lagBalls(G, s){ return [{id:"lag"+s, kind:"tir", side:s, x:LINE_X[s], y:CY, vx:0, vy:0, r:R_TIR, m:R_TIR**3, alive:true, sunk:false}] }
function lagPlace(G, s, shot){ const b = lagBalls(G, s); b[0].y = Math.max(LINE_Y[0], Math.min(LINE_Y[1], shot.y ?? CY)); const p = Math.max(0, Math.min(1, shot.p));
  b[0].vx = Math.cos(shot.ang)*p*G.R.force; b[0].vy = Math.sin(shot.ang)*p*G.R.force; return b }
const lagDist = (G, b) => b.sunk ? 0 : len(b.x - CX, b.y - CY);
function lagPlay(G, s, shot){ const map = MAPS[G.mapId], b = lagPlace(G, s, shot); for(let f=0; f<4000 && step(map, b); f++); return lagDone(G, s, lagDist(G, b[0])) }
// les deux distances connues : le plus près commence (égalité parfaite : le joueur de droite, qui a joué la mise en jeu en second)
function lagDone(G, s, d){ G.lag[s] = d; if(G.lag[0]==null || G.lag[1]==null) return null;
  const first = G.lag[0] < G.lag[1] ? 0 : 1;
  if(G.phase==="egalite"){ G.winner = first; G.phase = "fin" } else { G.turn = first; G.phase = "play" }
  return first }

/* ---------- l'ordi ---------- */
// il essaie une soixantaine de tirs (vers chaque bille, en la poussant hors du rond), garde le meilleur, et le rate un peu selon son niveau
const LEVELS = {facile:{n:14, ang:.07, p:.18}, moyen:{n:30, ang:.035, p:.1}, fort:{n:60, ang:.014, p:.05}};
function gauss(rnd){ let u = 0; for(let i=0;i<6;i++) u += rnd(); return (u - 3)/1.2 }
function botShot(G, level, rnd){
  const L = LEVELS[level] || LEVELS.moyen, me = G.turn, map = MAPS[G.mapId], t = tireuse(G, me), C = map.circle;
  const starts = t.placed ? [{x:t.x, y:t.y}] : [CY - 120, CY - 60, CY, CY + 60, CY + 120].map(y=>({x:LINE_X[me], y}));
  const targets = G.balls.filter(b=>b.alive && (b.kind==="pile" || b.kind==="dore" || (b.kind==="tir" && b.side!==me && inCircle(map, b))));
  const cand = [];
  for(const s of starts) for(const b of targets){
    let ox = b.x - C.x, oy = b.y - C.y, ol = len(ox, oy);
    if(map.pot && ol > 1){ ox = -ox; oy = -oy }   // au Pot : on pousse vers le trou (2 points)
    if(ol < 1){ ox = b.x - s.x; oy = b.y - s.y; ol = len(ox, oy) }
    ox /= ol || 1; oy /= ol || 1;
    const gx = b.x - ox*(b.r + R_TIR), gy = b.y - oy*(b.r + R_TIR);   // le point où toucher la bille pour la pousser dans le bon sens
    for(const [ax, ay] of [[gx, gy], [b.x, b.y]]){ const ang = Math.atan2(ay - s.y, ax - s.x);
      for(const p of [.6, .8, 1]) cand.push({y:s.y, ang:ang + (rnd() - .5)*.02, p}) } }
  for(let i=0;i<6;i++) cand.push({y:starts[0].y, ang:(me ? Math.PI : 0) + (rnd() - .5)*1.2, p:.5 + rnd()*.5});
  // on en garde n au hasard (l'ordi « facile » réfléchit moins)
  for(let i=cand.length-1;i>0;i--){ const j = Math.floor(rnd()*(i+1)); [cand[i], cand[j]] = [cand[j], cand[i]] }
  let best = null, bs = -1e9;
  for(const c of cand.slice(0, L.n)){
    const H = clone(G); H.log = []; const o = play(H, c), tt = tireuse(H, me);
    let sc = o.pts*10 + (o.rejoue ? 4 : 0) - (o.plouf ? 8 : 0);
    if(tt.alive && inCircle(map, tt)) sc -= 5;   // finir dans le rond, c'est s'exposer à un Tac
    if(sc > bs){ bs = sc; best = c } }
  return {...best, ang:best.ang + gauss(rnd)*L.ang, p:Math.max(.05, Math.min(1, best.p*(1 + gauss(rnd)*L.p)))};
}
function botLag(G, s, level, rnd){ const L = LEVELS[level] || LEVELS.moyen; let best = null, bd = 1e9;
  for(let i=0;i<L.n;i++){ const c = {y:CY + (rnd() - .5)*160, ang:(s ? Math.PI : 0) + (rnd() - .5)*.3, p:.3 + rnd()*.5}, b = lagPlace(G, s, c), map = MAPS[G.mapId];
    for(let f=0; f<4000 && step(map, b); f++); const d = lagDist(G, b[0]); if(d < bd){ bd = d; best = c } }
  return {...best, ang:best.ang + gauss(rnd)*L.ang, p:best.p*(1 + gauss(rnd)*L.p)} }

function rng(seed){ let a = seed>>>0 || 1; return () => { a |= 0; a = a + 0x6D2B79F5 | 0; let t = Math.imul(a ^ a>>>15, 1 | a); t = t + Math.imul(t ^ t>>>7, 61 | t) ^ t; return ((t ^ t>>>14)>>>0)/4294967296 } }

const API = {startTurn, AW, AH, AB, VMAX, CX, CY, R_TIR, LINE_X, LINE_Y, RULES, MAPS, newGame, clone, tireuse, inCircle, step, place, resolve, play,
  lagPlace, lagDist, lagPlay, lagDone, botShot, botLag, rng, rollFric};
if(typeof module!=="undefined" && module.exports) module.exports = API; else root.PICH = API;
})(typeof window!=="undefined" ? window : globalThis);
