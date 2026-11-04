// =====================================================================
//  MAQUETTE : des Grandes Courses inédites (4 novembre 2026)
//  Ce fichier est collé DANS le moteur de course (après G3C) par fabriquer-courses-inedites.mjs :
//  il utilise les outils du jeu (v3, g3Basis, g3Trace, g3Trough, g3TroughStart, g3TroughEnd, g3Obstacles…).
//  Rien ici n'est dans le jeu tant que ce n'est pas validé.
// =====================================================================

// Les pièces qui tournent (corps « kinematic ») ne se cognent pas au décor : sans ça le moteur teste à chaque pas
// chaque pale contre chaque morceau de plateau (aucun effet, mais très lent). Groupe 2 pour elles, le décor ne les regarde pas.
const g3Rotor = b => { b.collisionFilterGroup = 2; b.collisionFilterMask = 1; return b };
const g3Deco = b => { if(b) b.collisionFilterMask = -1 & ~2; return b };

// ---------- LA TOUR : des plateaux ronds empilés ----------
// Sur chaque étage, un tourniquet (4 pales) pousse les billes en rond le long du bord. Le fond a une trappe :
// une bille tombe à l'étage du dessous quand sa case passe au-dessus. Où elle atterrit par rapport à la trappe suivante,
// c'est la chance : une bille en tête peut faire presque un tour entier, une bille derrière tomber tout de suite.
function g3Tour(k, r, n, o){
  const NL = o.etages || 6, RO = 5.4, RI = 1.3, RH = 2.9, H = o.h || 4.2, HOLE = o.trou || .95, TL = 4*Math.PI/180, W = o.w || .7;
  const path = [], tl = Math.tan(TL);
  const top = (yk, rr) => yk - (rr - RI)*tl;   // le dessus du fond, penché vers le bord (les billes roulent contre le mur)
  const angAt = a => [Math.cos(a), 0, Math.sin(a)];
  const dAng = (a, b) => { let d = (a - b) % (2*Math.PI); if(d > Math.PI) d -= 2*Math.PI; if(d < -Math.PI) d += 2*Math.PI; return d };
  // la goulotte de départ arrive par la gauche (angle π) au-dessus du premier plateau
  const y0 = 0, LC = 20, pc = .12;
  const P0 = g3Trace([["S", LC]], {pente:pc, from:[-RO - LC + 2.2, y0 + 2.1 + LC*pc, 0]});
  path.push(...g3Trough(k, P0, {WID:3.6, mur:1.4, pente:pc}).path);
  const st = g3TroughStart(k, P0, {WID:3.6}, n, r);
  // les pales tournent dans le sens des angles qui diminuent (w > 0 autour de y) : la trappe suivante est un peu plus loin dans ce sens
  let entree = Math.PI;
  const trappes = [];
  for(let L=0; L<NL; L++){
    const yk = y0 - L*H, C = [0, yk, 0], lot = [];
    const ah = entree - (o.ecart || 2.5) - (r() - .5)*.6;   // la trappe de cet étage
    trappes.push(ah);
    const NS = 36;
    for(let j=0; j<NS; j++){ const a = (j + .5)*2*Math.PI/NS, da = 2*Math.PI/NS;
      [[RI, RH], [RH, RO]].forEach(([r1, r2], ring)=>{
        if(ring===1 && Math.abs(dAng(a, ah)) < HOLE/2) return;   // la trappe : seulement dans l'anneau du bord
        const rad = angAt(a), rc = (r1 + r2)/2, X = v3.norm([rad[0]*Math.cos(TL), -Math.sin(TL), rad[2]*Math.cos(TL)]), Z = [-Math.sin(a), 0, Math.cos(a)], Y = v3.cross(Z, X);
        lot.push({size:[(r2 - r1)/Math.cos(TL) + .1, .3, 2*r2*Math.sin(da/2)*1.1], pos:v3.add(C, [rad[0]*rc, top(yk, rc) - yk - .15, rad[2]*rc]), quat:g3Basis(X, Y, Z), kind:"ramp"}) }) }
    // le mur du bord (en verre, pour voir les billes) et le moyeu au milieu
    const NW = 40;
    for(let j=0; j<NW; j++){ const a = (j + .5)*2*Math.PI/NW, X = angAt(a), Z = [-Math.sin(a), 0, Math.cos(a)];
      // au premier étage, une ouverture au-dessus du mur là où arrive la goulotte : le mur est plus bas de ce côté
      const bas = L===0 && Math.abs(dAng(a, Math.PI)) < .45, hm = L===0 ? (bas ? 1.2 : 3.2) : H + .2;
      lot.push({size:[.25, hm, 2*(RO + .2)*Math.sin(Math.PI/NW)*1.12], pos:v3.add(C, [X[0]*(RO + .14), top(yk, RO) - yk + hm/2 - .3, X[2]*(RO + .14)]), quat:g3Basis(X, [0,1,0], Z), kind:"glass"}) }
    for(let i=0; i<lot.length; i+=20) g3Deco(k.boxes(lot.slice(i, i + 20)));
    g3Deco(k.cyl(RI, 1.4, [0, yk + .6, 0], null, "peg"));
    // le tourniquet : deux barres en croix (4 pales), un peu au-dessus du fond
    const sens = 1, ph = r()*Math.PI;
    const w = sens*W*(1 + (r() - .5)*.12);
    [0, Math.PI/2].forEach(b=>g3Rotor(k.spin([2*(RO - .14), .9, .24], [0, yk + .55, 0], [0, ph + b, 0], [0, w, 0])));
    // le chemin pour le classement en direct : l'arc parcouru de l'entrée jusqu'à la trappe, puis la chute
    let a = entree; const fin = entree - ((entree - ah) % (2*Math.PI) + 2*Math.PI) % (2*Math.PI);
    for(; a > fin; a -= .25){ const p = angAt(a); path.push([p[0]*4.3, top(yk, 4.3) + .5, p[2]*4.3]) }
    const ph2 = angAt(ah); path.push([ph2[0]*4.3, top(yk, 4.3) + .5, ph2[2]*4.3]);
    entree = ah;
  }
  // le bac d'arrivée sous la dernière trappe, large comme la tour
  const yT = y0 - NL*H - .4, S = 2*RO + 4;
  g3Deco(k.box([S, .4, S], [0, yT, 0], [0,0,0], "tray"));
  [[1,0],[-1,0],[0,1],[0,-1]].forEach(([a, b])=>g3Deco(k.box(a ? [.4, 2.4, S] : [S, 2.4, .4], [a*S/2, yT + 1.2, b*S/2], [0,0,0], "glass")));
  const pe = angAt(entree); path.push([pe[0]*4.3, yT + 1, pe[2]*4.3]);
  // la caméra : dehors, du côté de la bille suivie, un peu au-dessus
  const cam = p => { const a = Math.atan2(p[2], p[0]); return [Math.cos(a)*15, p[1] + 6.5, Math.sin(a)*15] };
  return {path, ...st, finishY:yT + 1.2, floorY:yT - 3, trayR:12, cam, look:p => [p[0]*.4, p[1] - 1, p[2]*.4]};
}

// ---------- LES COULOIRS : une grande piste à 4 couloirs ----------
// Des murets séparent les couloirs, avec des passages pour changer de couloir. Dans chaque couloir, des portes tournantes
// (une barre qui tourne à plat, presque aussi large que le couloir) : on passe quand elle est dans l'axe, sinon on attend
// ou on est renvoyé en arrière. Des champignons font sauter les billes d'un couloir à l'autre.
function g3Couloirs(k, r, n, o){
  const NC = o.nc || 3, LW = o.lw || 3.4, WID = NC*LW, p = o.pente || .1, LEN = o.len || 100, path = [];
  const P = g3Trace([["S", 14 + LEN]], {pente:p, from:[-14, (14 + LEN)*p, 0]});
  const T = g3Trough(k, P, {WID, mur:1.4, pente:p});
  path.push(...T.path);
  const st = g3TroughStart(k, P, {WID}, n, r);
  const F = T.frames, at = (i, z, h) => { const f = F[Math.max(0, Math.min(F.length - 1, Math.round(i)))]; return v3.add(f.M, v3.add(v3.mul(f.Z, z), v3.mul(f.Y, h))) };
  const i0 = 18, i1 = F.length - 4;   // les couloirs commencent après la grille de départ et finissent avant le bac
  // les murets : 3, avec des passages de 2,4 (décalés au hasard d'un muret à l'autre)
  for(let d=1; d<NC; d++){ const z = -WID/2 + d*LW; let i = i0;
    while(i < i1){ const lon = 7 + Math.floor(r()*6), j = Math.min(i1, i + lon);
      k.seg(at(i, z, 0), at(j, z, 0), F[Math.round((i + j)/2)].Y, .8, "rail");
      // les bouts arrondis : une bille qui arrive pile sur le bout d'un muret plat s'y arrêtait net
      [i, j].forEach(e=>k.cyl(.2, .8, at(e, z, .4), F[Math.round(e)].q, "rail"));
      i = j + 2.4 + r()*.8 } }
  // les portes et les champignons, couloir par couloir, décalés
  for(let c=0; c<NC; c++){ const zc = -WID/2 + (c + .5)*LW;
    for(let i = i0 + 14 + c*4 + r()*4; i < i1 - 6; i += 15 + r()*6){
      const f = F[Math.round(i)];
      if(r() < .5) g3Rotor(k.spin([.3, 2.1, LW - .5], at(i, zc, 1.45), f.q, v3.mul(f.Z, 1.2 + .6*r())));
      else k.cyl(.35, 1, at(i, zc, .5), f.q, "bump", "rebond");
    } }
  const end = g3TroughEnd(k, P, path, {});
  return {path, ...st, ...end, cam:g3ChaseCam};
}

Object.assign(G3C, {
  tour:{name:"La Tour", desc:"Huit plateaux empilés : sur chacun, un tourniquet pousse les billes en rond jusqu'à la trappe. Celle qui tombe au bon moment dégringole d'un coup, celle qui la rate fait un tour de plus !",
    theme:{bg:"#1B1030", ramp:"#C9955C", tray:"#FFD34D", spin:"#FF5FA2", peg:"#FFD34D"}, form:"tour", peloton:0, patience:12,
    build(k, r, n){ return g3Tour(k, r, n, {etages:8, w:.75}) }},
  couloirs:{name:"Les Couloirs", desc:"Une grande piste à trois couloirs : des portes qui tournent, des passages pour changer de couloir et des champignons qui font sauter d'un couloir à l'autre. Quel couloir sera le bon ?",
    theme:{bg:"#0F2230", ramp:"#3FA7D6", tray:"#FFD34D", spin:"#FFD34D", bump:"#FF6FB5", peg:"#FFFFFF"}, form:"couloirs",
    build(k, r, n){ return g3Couloirs(k, r, n, {pente:.1, len:135}) }},
});
