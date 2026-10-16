// Fichier fabriqué par maquettes/fabriquer-course-fine.mjs (physique fine, pour la maquette) : ne pas modifier à la main.
window.COURSE_FINE = (() => {
const TAU = Math.PI*2;

function hash(s){let h=2166136261;for(let i=0;i<s.length;i++){h^=s.charCodeAt(i);h=Math.imul(h,16777619)}return h>>>0}

function rng(seed){let a=seed>>>0;return()=>{a|=0;a=a+0x6D2B79F5|0;let t=Math.imul(a^a>>>15,1|a);t=t+Math.imul(t^t>>>7,61|t)^t;return((t^t>>>14)>>>0)/4294967296}}

const v3 = {sub:(a,b)=>[a[0]-b[0],a[1]-b[1],a[2]-b[2]], add:(a,b)=>[a[0]+b[0],a[1]+b[1],a[2]+b[2]], mul:(a,k)=>[a[0]*k,a[1]*k,a[2]*k],
  dot:(a,b)=>a[0]*b[0]+a[1]*b[1]+a[2]*b[2], cross:(a,b)=>[a[1]*b[2]-a[2]*b[1], a[2]*b[0]-a[0]*b[2], a[0]*b[1]-a[1]*b[0]],
  norm:a=>{ const l = Math.hypot(...a)||1; return [a[0]/l,a[1]/l,a[2]/l] }};


function g3Basis(X, Y, Z){
  const [m00,m10,m20] = X, [m01,m11,m21] = Y, [m02,m12,m22] = Z, tr = m00+m11+m22; let x, y, z, w;
  if(tr>0){ const s = .5/Math.sqrt(tr+1); w = .25/s; x = (m21-m12)*s; y = (m02-m20)*s; z = (m10-m01)*s }
  else if(m00>m11 && m00>m22){ const s = 2*Math.sqrt(1+m00-m11-m22); w = (m21-m12)/s; x = .25*s; y = (m01+m10)/s; z = (m02+m20)/s }
  else if(m11>m22){ const s = 2*Math.sqrt(1+m11-m00-m22); w = (m02-m20)/s; x = (m01+m10)/s; y = .25*s; z = (m12+m21)/s }
  else { const s = 2*Math.sqrt(1+m22-m00-m11); w = (m10-m01)/s; x = (m02+m20)/s; y = (m12+m21)/s; z = .25*s }
  return [x,y,z,w];
}

const G3 = {R:.42, DT:1/60, MAXT:150};

function g3Kit(CANNON, world, o3={}){
  const M = {piste:new CANNON.Material("piste"), bille:new CANNON.Material("bille"), rebond:new CANNON.Material("rebond")};
  world.addContactMaterial(new CANNON.ContactMaterial(M.piste, M.bille, {friction:.22, restitution:.25}));
  world.addContactMaterial(new CANNON.ContactMaterial(M.bille, M.bille, {friction:.05, restitution:.85}));
  world.addContactMaterial(new CANNON.ContactMaterial(M.rebond, M.bille, {friction:0, restitution:1.1}));
  M.tramp = new CANNON.Material("tramp"); world.addContactMaterial(new CANNON.ContactMaterial(M.tramp, M.bille, {friction:o3.trampF ?? .45, restitution:o3.tramp ?? .8}));   // (14 octobre 2026) les trampolines
  const statics = [], kin = [];
  const put = (shape, info, pos, rot, kind, mat, spin) => {
    const b = new CANNON.Body({mass:0, material:M[mat||"piste"], shape, type:spin ? CANNON.Body.KINEMATIC : CANNON.Body.STATIC});
    b.position.set(...pos);
    if(rot && rot.length===4) b.quaternion.set(...rot); else if(rot) b.quaternion.setFromEuler(...rot);
    if(spin) b.angularVelocity.set(...spin);
    b.aabbNeedsUpdate = true; world.addBody(b);   // (sinon la zone de choc reste à l'origine)
    const d = {kind, ...info, pos, quat:[b.quaternion.x, b.quaternion.y, b.quaternion.z, b.quaternion.w]};
    if(spin){ d.body = b; kin.push(d) } else statics.push(d);
    return b };
  return {M, statics, kin,
    box:(size, pos, rot, kind="ramp", mat) => put(new CANNON.Box(new CANNON.Vec3(size[0]/2, size[1]/2, size[2]/2)), {shape:"box", size}, pos, rot, kind, mat),
    cyl:(r, h, pos, rot, kind="peg", mat) => put(new CANNON.Cylinder(r, r, h, 14), {shape:"cyl", size:[r,h]}, pos, rot, kind, mat),
    // un plot entre deux vitres : pour la physique une petite sphère (la bille ne bouge pas en profondeur), dessiné comme un cylindre
    pin:(r, h, pos, kind="peg", mat) => { const b = new CANNON.Body({mass:0, material:M[mat||"piste"], shape:new CANNON.Sphere(r)}); b.position.set(...pos); b.aabbNeedsUpdate = true; world.addBody(b);
      statics.push({kind, shape:"cyl", size:[r,h], pos, quat:[Math.SQRT1_2,0,0,Math.SQRT1_2]}); return b },
    // (14 octobre 2026) plusieurs boîtes fixes dans un seul corps : les goulottes ont des centaines de morceaux, un corps chacun rendait le calcul très lent
    boxes:(list, mat) => { if(!list.length) return; const b = new CANNON.Body({mass:0, material:M[mat||"piste"]}), O = list[0].pos;
      b.position.set(...O);
      list.forEach(d=>{ const q = new CANNON.Quaternion(...d.quat); b.addShape(new CANNON.Box(new CANNON.Vec3(d.size[0]/2, d.size[1]/2, d.size[2]/2)), new CANNON.Vec3(d.pos[0]-O[0], d.pos[1]-O[1], d.pos[2]-O[2]), q);
        statics.push({kind:d.kind, shape:"box", size:d.size, pos:d.pos, quat:d.quat}) });
      b.aabbNeedsUpdate = true; world.addBody(b); return b },
    // une boule fixe (rochers, boules de billard)
    ball:(r, pos, kind="rock", mat) => put(new CANNON.Sphere(r), {shape:"sph", size:[r]}, pos, null, kind, mat),
    // un muret droit entre deux points, posé sur la piste (N : le dessus de la piste), de hauteur h
    seg:(A, B, N, h, kind="maze", mat) => { const Z = v3.norm(v3.sub(B, A)), X = v3.norm(v3.cross(N, Z)), Y = v3.cross(Z, X), L = Math.hypot(...v3.sub(B, A));
      return put(new CANNON.Box(new CANNON.Vec3(.15, h/2, L/2)), {shape:"box", size:[.3, h, L]}, v3.add(v3.mul(v3.add(A, B), .5), v3.mul(Y, h/2)), g3Basis(X, Y, Z), kind, mat) },
    // du décor seulement (pas de choc)
    look:(shape, size, pos, quat, kind) => statics.push({kind, shape, size, pos, quat:quat||[0,0,0,1]}),
    // (14 octobre 2026) une roue qui tourne autour de l'axe z : nb rayons de longueur R (et un moyeu), dans un seul corps
    wheel:(R, nb, depth, pos, w) => { const b = new CANNON.Body({mass:0, material:M.piste, type:CANNON.Body.KINEMATIC}), parts = [];
      for(let i=0;i<nb;i++){ const a = i*TAU/nb, q = new CANNON.Quaternion(); q.setFromEuler(0, 0, a);
        b.addShape(new CANNON.Box(new CANNON.Vec3(R/2, .15, depth/2)), new CANNON.Vec3(Math.cos(a)*R/2, Math.sin(a)*R/2, 0), q);
        parts.push({shape:"box", size:[R, .3, depth], pos:[Math.cos(a)*R/2, Math.sin(a)*R/2, 0], quat:[q.x, q.y, q.z, q.w]}) }
      b.addShape(new CANNON.Sphere(.7)); parts.push({shape:"cyl", size:[.7, depth], pos:[0,0,0], quat:[Math.SQRT1_2, 0, 0, Math.SQRT1_2], kind:"axle"});
      b.position.set(...pos); b.angularVelocity.set(0, 0, w); b.aabbNeedsUpdate = true; world.addBody(b);
      const d = {kind:"spin", shape:"group", parts, pos, quat:[0,0,0,1], body:b}; kin.push(d); return b },
    spin:(size, pos, rot, w) => put(new CANNON.Box(new CANNON.Vec3(size[0]/2, size[1]/2, size[2]/2)), {shape:"box", size}, pos, rot, "spin", "piste", w)};
}


function g3Zigzag(k, o, deco){
  const {RAMPS, LEN, WID, STEP, ANG, wall=3} = o, ext = 2.6, path = [];
  for(let i=0;i<RAMPS;i++){
    const dir = i%2 ? -1 : 1, y = i*-STEP, rot = -dir*ANG, cx = -dir*ext/2;
    const sY = x => y - Math.tan(ANG)*dir*(x-cx);
    // une trappe (o.holes) : un trou d'un côté de la rampe ; la bille qui passe dessus tombe sur la rampe du dessous et prend un raccourci
    const hole = o.holes && i<RAMPS-1 ? o.holes(i) : null;
    if(!o.noRamp && !hole) k.box([LEN+ext, .4, WID], [cx, y, 0], [0,0,rot]);
    if(hole){ const L = LEN+ext, c = Math.cos(rot), s = Math.sin(rot), HL = 1.5, HW = hole.w || 2;
      const uh = (-dir*LEN/2 + dir*hole.f*LEN - cx)/c, piece = (u0, u1, w, z) => { const u = (u0+u1)/2; k.box([u1-u0, .4, w], [cx + u*c, y + u*s, z], [0,0,rot]) };
      // le trou ne touche pas le mur (une bande de 0,5 reste) : la bille tombe bien entre les murs de la rampe du dessous
      piece(-L/2, uh-HL/2, WID, 0); piece(uh+HL/2, L/2, WID, 0);
      piece(uh-HL/2, uh+HL/2, WID-HW-.5, -hole.side*(HW+.5)/2); piece(uh-HL/2, uh+HL/2, .5, hole.side*(WID/2-.25)) }
    if(i===0) k.box([.4, wall+1, WID+.6], [cx - (LEN+ext)/2*Math.cos(rot) - .2, y + wall/2, 0], [0,0,0], "end");   // derrière la ligne de départ
    k.box([LEN+ext, wall, .3], [cx, y+wall/2-.1, WID/2+.15], [0,0,rot], "wall"); k.box([LEN+ext, wall, .3], [cx, y+wall/2-.1, -WID/2-.15], [0,0,rot], "wall");
    if(i<RAMPS-1){ const xe = dir*(LEN/2+1.4); k.box([.4, STEP+1.6, WID+.6], [xe, y-STEP/2+.6, 0], [0,0,0], "end") }
    path.push([-dir*(LEN/2-1), sY(-dir*(LEN/2-1))+.5, 0], [dir*(LEN/2), sY(dir*LEN/2)+.5, 0]);
    deco && deco(i, {dir, y, rot, cx, sY});
    // des bosses rondes dans les murs, d'un côté puis de l'autre : une bille qui longe le mur est renvoyée vers le milieu
    (o.wallBumps||[]).forEach((f, j)=>{ const x = -dir*LEN/2 + dir*f*LEN, sd = (i+j)%2 ? 1 : -1;
      k.cyl(.5, 1.4, [x, sY(x)+.75, sd*(WID/2+.05)], [0,0,rot], "wall2") });
  }
  const yl = (RAMPS-1)*-STEP, dirL = (RAMPS-1)%2 ? -1 : 1, xf = dirL*(LEN/2+6), yt = yl-STEP;
  k.box([14, .4, WID+4], [xf, yt+.4, 0], [0,0,0], "tray");
  k.box([.4, 3, WID+4], [xf+dirL*7, yt+1.8, 0], [0,0,0], "end"); k.box([.4, 3, WID+4], [xf-dirL*7, yt+1.8, 0], [0,0,0], "end");
  k.box([14, 3, .4], [xf, yt+1.8, WID/2+2], [0,0,0], "wall"); k.box([14, 3, .4], [xf, yt+1.8, -WID/2-2], [0,0,0], "wall");
  path.push([xf, yt+1, 0]);
  return {path, finishY:yt+1.2, floorY:yt-3};
}

function g3ZigStart(k, o, n, r){
  const {LEN, ANG, WID} = o, lanes = WID>=7 ? 5 : 4, rows = Math.ceil(n/lanes), starts = [];
  for(let i=0;i<n;i++){ const row = Math.floor(i/lanes), col = i%lanes, x = -LEN/2 + .8 + row*1.05 + (r()-.5)*.05;
    starts.push([x, -Math.tan(ANG)*(x+1.3) + .2 + G3.R + .03, (col-(lanes-1)/2)*1.2 + (r()-.5)*.05]) }
  const gx = -LEN/2 + .8 + rows*1.05 + .6;
  return {starts, gate:k.box([.3, 2, WID], [gx, -Math.tan(ANG)*(gx+1.3)+1.2, 0], [0,0,0], "gate")};
}

const g3ZigCam = (p, T) => [p[0] - 4*Math.sign(T[0]||1), p[1]+3, p[2]+14];

const g3TableCam = (p, T) => [p[0] - 5*Math.sign(T[0]||1), p[1]+8, p[2]+12];

function g3Log(k, rot, sg, ph, rad, len, pos, kind, mat){
  const Xr = [Math.cos(rot), Math.sin(rot), 0], N = [-Math.sin(rot), Math.cos(rot), 0], d = v3.norm(v3.add(v3.mul(Xr, sg*Math.sin(ph)), [0, 0, Math.cos(ph)]));
  return k.cyl(rad, len, pos, g3Basis(N, d, v3.cross(N, d)), kind, mat);
}


function g3Trace(cmds, o){
  const pas = o.pas || 1, pts = [[...(o.from||[0,0,0])]]; let h = o.cap || 0, [x, y, z] = o.from || [0,0,0];
  pts.parts = [];   // (14 octobre 2026) où commence et finit chaque morceau du tracé (pour poser des obstacles au milieu des lignes droites)
  cmds.forEach(c=>{ pts.parts.push({c, i0:pts.length-1, i1:pts.length-1 + Math.max(1, Math.round((c[0]==="S" ? c[1] : c[1]*c[2]*Math.PI/180)/pas))});
    const droit = c[0]==="S", pente = (droit ? c[2] : c[3]) ?? o.pente, L = droit ? c[1] : c[1]*c[2]*Math.PI/180, nb = Math.max(1, Math.round(L/pas));
    const dh = droit ? 0 : (c[0]==="G" ? -1 : 1)*c[2]*Math.PI/180/nb;
    for(let j=0;j<nb;j++){ const l = L/nb; h += dh/2; x += Math.cos(h)*l; z += Math.sin(h)*l; h += dh/2; y -= pente*l; pts.push([x, y, z]) }
  });
  return pts;
}

function g3Trough(k, P, o){
  const WID = o.WID || 3.2, mur = o.mur || 1.4, path = [], N = P.length, BM = o.bankMax || .42;
  // le relevé de chaque morceau : d'après le virage, puis lissé (sinon le fond se relève d'un coup et fait une marche)
  let bk = [];
  for(let i=0;i<N-1;i++){ const Xa = v3.norm(v3.sub(P[i+1], P[Math.max(0,i-1)])), Xb = v3.norm(v3.sub(P[Math.min(N-1,i+2)], P[i]));
    bk.push(Math.max(-BM, Math.min(BM, (o.relief ?? 6)*v3.cross(Xa, Xb)[1]/Math.max(.5, Math.hypot(...v3.sub(P[i+1], P[i])))))) }
  for(let pass=0; pass<4; pass++) bk = bk.map((b,i)=>{ let s = 0, c = 0; for(let j=-3;j<=3;j++){ const v = bk[i+j]; if(v!=null){ s += v; c++ } } return s/c });
  // (le relevé change d'au plus « vr » par morceau : sur le bord d'une piste large, il ne doit jamais remonter plus que la pente ne descend)
  const vr = Math.min(.05, .45*(o.pente || .1)/(WID/2));
  for(let i=1;i<bk.length;i++) bk[i] = bk[i-1] + Math.max(-vr, Math.min(vr, bk[i]-bk[i-1]));
  for(let i=bk.length-2;i>=0;i--) bk[i] = bk[i+1] + Math.max(-vr, Math.min(vr, bk[i]-bk[i+1]));
  // (14 octobre 2026) o.plat0 : la goulotte part à plat d'un plateau (les fourches) puis se relève sur ses 5 premiers morceaux.
  // Sans ça le détour, qui tourne tout de suite, commençait déjà relevé (0,29) : son bord intérieur faisait une marche de 0,5 qui calait les billes.
  if(o.plat0) for(let i=0;i<Math.min(5, bk.length);i++) bk[i] *= i/5;
  let lot = []; const frames = [];
  for(let i=0;i<N-1;i++){
    const A = P[i], B = P[i+1], X = v3.norm(v3.sub(B, A)), len = Math.hypot(...v3.sub(B, A)), bank = bk[i];
    const Z0 = v3.norm([-X[2], 0, X[0]]), Y0 = v3.norm(v3.cross(Z0, X));
    const Z = v3.add(v3.mul(Z0, Math.cos(bank)), v3.mul(Y0, Math.sin(bank))), Y = v3.sub(v3.mul(Y0, Math.cos(bank)), v3.mul(Z0, Math.sin(bank)));
    const q = g3Basis(X, Y, Z), M = v3.mul(v3.add(A, B), .5), Lp = len*1.08 + .3;
    // (16 octobre 2026) o.trous[i] = côté (1 ou -1 sur Z) : le fond est plus étroit sur ce morceau, une trappe le long du bord
    // (le Volcan : la bille qui tombe atterrit sur le tour du dessous)
    const tr = o.trous?.[i], hw = o.trouW || 1.1;
    if(tr) lot.push({size:[Lp, .35, WID-hw], pos:v3.add(M, v3.mul(Z, -tr*hw/2)), quat:q, kind:o.kind || "ramp"});
    else lot.push({size:[Lp, .35, WID], pos:M, quat:q, kind:o.kind || "ramp"});
    [-1, 1].forEach(sd=>lot.push({size:[Lp, mur, .25], pos:v3.add(M, v3.add(v3.mul(Z, sd*(WID/2+.12)), v3.mul(Y, mur/2-.1))), quat:q, kind:o.murKind || "wall"}));
    if(lot.length>=18 || i===N-2){ k.boxes(lot); lot = [] }   // 6 morceaux de piste par corps
    if(i%2===0) path.push(v3.add(M, v3.mul(Y, .5)));
    frames.push({M:v3.add(M, v3.mul(Y, .175)), X, Y, Z, q, bank});   // le dessus du fond, au milieu du morceau
  }
  return {path, frames};
}

function g3TroughStart(k, P, o, n, r){
  const WID = o.WID || 3.2, lanes = Math.max(2, Math.floor((WID-.3)/.95)), rows = Math.ceil(n/lanes), starts = [];
  const at = s => { const i = Math.min(P.length-2, Math.floor(s)), f = s - i, A = P[i], B = P[i+1]; return v3.add(A, v3.mul(v3.sub(B, A), f)) };
  const X = v3.norm(v3.sub(P[1], P[0])), Z = v3.norm([-X[2], 0, X[0]]), Y = v3.norm(v3.cross(Z, X)), step = Math.hypot(...v3.sub(P[1], P[0])) || 1;
  for(let i=0;i<n;i++){ const row = Math.floor(i/lanes), lane = i%lanes, s = (.9 + row*1.05)/step;
    starts.push(v3.add(v3.add(at(s), v3.mul(Z, (lane-(lanes-1)/2)*.95 + (r()-.5)*.04)), v3.mul(Y, .2+G3.R+.05))) }
  const sg = (.9 + rows*1.05 + .5)/step;
  return {starts, gate:k.box([.3, 2, WID], v3.add(at(sg), v3.mul(Y, 1)), g3Basis(X, Y, v3.cross(X, Y)), "gate")};
}

function g3TroughEnd(k, P, path, o){
  const N = P.length, X = v3.norm(v3.sub(P[N-1], P[N-2])), Xh = v3.norm([X[0], 0, X[2]]), c = v3.add(P[N-1], v3.add(v3.mul(Xh, 5), [0, -2.5, 0]));
  const S = 13, q = g3Basis(Xh, [0,1,0], v3.cross(Xh, [0,1,0]));
  k.box([S, .4, S], c, q, "tray");
  [[1,0],[0,1],[0,-1]].forEach(([a, b])=>{ const p = v3.add(c, v3.add(v3.mul(Xh, a*S/2), v3.mul(v3.cross(Xh, [0,1,0]), b*S/2)));   // (pas de bord du côté où arrive la piste)
    k.box(a ? [.4, 3, S] : [S, 3, .4], v3.add(p, [0, 1.5, 0]), q, a===-1 ? "glass" : "wall") });
  // un bord bas du côté où arrive la piste (une bille qui roulait en arrière dans le bac retombait par là)
  k.box([.4, 1.4, S], v3.add(c, v3.add(v3.mul(Xh, -S/2), [0, .7, 0])), q, "glass");
  path.push(v3.add(c, [0, 1, 0]));
  return {finishY:c[1]+1.2, floorY:c[1]-2, trayR:8};
}

function g3Semis(P, T, r){ const out = [], S = P.parts.filter(x=>x.c[0]==="S").slice(1, -1); let j = Math.floor(r()*T.length);
  S.forEach(x=>{ const t = T[j++ % T.length], m = Math.round((x.i0 + x.i1)/2);
    if(t==="plots") out.push([x.i0 + 3, t], [m, "bosse"], [x.i1 - 3, t]); else out.push([m, t]) });
  return out;
}

function g3Obstacles(k, frames, WID, liste, r){
  liste.forEach(([i, type], j)=>{ const F = frames[Math.max(0, Math.min(frames.length-1, i))]; if(!F) return; const {M, X, Y, Z, q} = F, at = (z, h) => v3.add(M, v3.add(v3.mul(Z, z), v3.mul(Y, h)));
    const sens = j%2 ? 1 : -1;
    if(type==="moulin") k.spin([Math.min(2.6, WID-1.8), .45, .45], at(0, .5), q, v3.mul(Y, sens*(1.1 + .4*r())));   // un passage reste le long des bords
    else if(type==="porte") k.spin([.3, 2.1, WID-.5], at(0, 1.45), q, v3.mul(Z, .9 + .5*r()));
    // (14 octobre 2026) un seul champignon, au milieu : sur les pistes étroites des fourches (3,8), les deux champignons ne laissaient que 0,93
    // le long des murs (une bille fait 0,84) et, la piste étant relevée dans les virages, les billes s'y calaient
    else if(type==="champi") k.cyl(.5, 1, at(0, .5), q, "bump", "rebond");
    else if(type==="champis") [-1, 1].forEach(sd=>k.cyl(.42, 1, at(sd*(WID/2-1.35), .5), q, "bump", "rebond"));
    else if(type==="bosse") k.cyl(.5, 1, at((r()-.5)*.6, .5), q, "bump", "rebond");
    // les deux plots : à mi-chemin entre le milieu et le bord (un passage d'au moins une bille partout ; trop près du bord, une bille s'y coinçait)
    else if(type==="plots") [-1, 1].forEach(sd=>k.cyl(.17, 1.1, at(sd*(WID/2 - .5)/2 + (r()-.5)*.1, .55), q, "peg"));
  });
}

function g3Fourche(k, r, n, o){
  // (14 octobre 2026, le soir) deux fourches à la suite (4 chemins possibles), des pistes plus larges, des obstacles sur les 4 branches.
  // o.obs : pour chaque branche (A1 raccourci, B1 détour, A2, B2), la liste des obstacles (types de g3Obstacles) posés tout du long.
  const WID = 3.8, p = o.pente || .1, LZ = 2.5, path = [], branches = [];
  // la goulotte de départ, jusqu'à la première fourche (en x = 0, y = 0)
  const P0 = g3Trace([["S", 40]], {pente:p, from:[-40, 40*p, 0]});
  path.push(...g3Trough(k, P0, {WID, mur:1.5, kind:o.kind}).path);
  const st = g3TroughStart(k, P0, {WID}, n, r);
  // une section : la fourche en (x0, y0), le raccourci (tout droit) et le détour (une boucle) ; puis l'entonnoir en V et sa sortie,
  // ou, pour la dernière, le bac d'arrivée
  // wIn : la largeur de la goulotte qui arrive (les murs du fond du plateau commencent à son bord)
  const section = (x0, y0, obsA, obsB, derniere, wIn = WID) => {
    const X = v3.norm([1, -p, 0]), Y = v3.norm([p, 1, 0]), q = g3Basis(X, Y, v3.cross(X, Y)), top = (x, z) => [x0 + x, y0 - p*x + .18, z];
    k.box([3.8, .35, 2*(LZ + WID/2) + .4], [x0 + 1.6, y0 - p*1.6, 0], q, o.kind || "ramp");
    // (14 octobre 2026) le séparateur finit DERRIÈRE le mur intérieur de chaque branche (z ±0,42, x 3,6) : avant il finissait en z ±0,6,
    // son coin dépassait de 0,15 dans la piste juste où le mur commence et calait les billes (le « petit rebord » à l'entrée des branches)
    [-1, 1].forEach(sd=>{ k.seg(top(1.3, 0), top(3.6, sd*.42), Y, 1.3, "rail");
      k.box([3.8, 1.5, .25], v3.add(top(1.6, sd*(LZ + WID/2 + .3)), [0, .6, 0]), q, "wall");
      // (14 octobre 2026) avant, ces murs partaient de WID/2 : à la 2e fourche (goulotte d'arrivée de 5,2) ils dépassaient de 0,7 dans la piste
      // et faisaient un rebord qui bloquait les billes du bord de la goulotte
      const zi = wIn/2 + .15, ze = LZ + WID/2 + .4;
      k.box([.25, 1.5, ze - zi], v3.add(top(-.1, sd*(zi + ze)/2), [0, .6, 0]), q, "wall") });
    const PA = g3Trace([["S", 36]], {pente:p, from:[x0 + 3.4, y0 - p*3.4, LZ]});
    const A = g3Trough(k, PA, {WID, mur:1.5, kind:o.kind, plat0:true});
    const PB = g3Trace([["S",3],["G",6,90],["S",8],["D",6,90],["S",10],["D",6,90],["S",8],["G",6,90],["S",2]], {pente:p, from:[x0 + 3.4, y0 - p*3.4, -LZ]});
    const B = g3Trough(k, PB, {WID, mur:1.5, kind:o.kind, plat0:true});
    // les obstacles : sur le raccourci tous les 5 morceaux à partir du 4e ; sur le détour au milieu de ses lignes droites
    obsA = obsA.map(t=>t==="champis" ? "champi" : t); obsB = obsB.map(t=>t==="champis" ? "champi" : t);
    g3Obstacles(k, A.frames, WID, obsA.map((t, j)=>[4 + j*Math.floor((A.frames.length - 8)/Math.max(1, obsA.length - 1)), t]), r);
    const SB = PB.parts.filter(x=>x.c[0]==="S" && x.c[1]>=8);
    g3Obstacles(k, B.frames, WID, obsB.map((t, j)=>[SB[j % SB.length] ? Math.round((SB[j % SB.length].i0 + SB[j % SB.length].i1)/2) : 10, t]), r);
    const yb = Math.min(PA.at(-1)[1], PB.at(-1)[1]) - 2.2, xa = x0 + 32, L = 15;
    path.push(...B.path); branches.push({path:A.path, from:path.length - B.path.length, to:path.length});
    if(derniere){   // le bac d'arrivée, sous les deux branches
      // (assez bas : le détour revient au-dessus de son bord)
      const yt = yb - 2.6, c = [xa + L/2, yt, 0];
      k.box([L + 1, .4, 18], c, [0,0,0], "tray");
      [[-1, 0, .4, 18], [1, 0, .4, 18], [0, -1, L + 1, .4], [0, 1, L + 1, .4]].forEach(([a, b2, sx, sz])=>k.box([sx, 2.2, sz], [c[0] + a*(L/2 + .5), yt + 1.1, b2*9], [0,0,0], a ? "glass" : "wall"));
      path.push([c[0], yt + 1, 0]);
      return {finishY:yt + 1.2, floorY:yt - 3, trayR:10};
    }
    // l'entonnoir en V : deux moitiés qui penchent vers le milieu (z = 0) et descendent vers la sortie
    const a5 = 7*Math.PI/180, a9 = 10*Math.PI/180, Xp = v3.norm([1, -Math.tan(a5), 0]);
    [-1, 1].forEach(sd=>{ const Zh = v3.norm([0, Math.tan(a9), sd]), Yh0 = v3.norm(v3.cross(Zh, Xp)), Yh = Yh0[1] < 0 ? v3.mul(Yh0, -1) : Yh0;
      k.box([L, .35, 8.4], [xa + L/2, yb - Math.tan(a5)*L/2 + 4*Math.tan(a9), sd*4], g3Basis(Xp, Yh, v3.cross(Xp, Yh)), o.kind || "ramp") });
    const yo = yb - Math.tan(a5)*L;
    k.box([.4, 4, 17], [xa - .2, yb + 1.5, 0], [0,0,0], "wall");
    [-1, 1].forEach(sd=>{ k.box([L, 4, .4], [xa + L/2, yb + .8, sd*8.4], [0,0,0], "wall"); k.box([.4, 3, 5.6], [xa + L + .2, yo + 1.5, sd*5.6], [0,0,0], "wall") });
    path.push([xa + 4, yb + .6, 0], [xa + L - 1, yo + .6, 0]);
    return {x:xa + L + .1, y:yo - .6};
  };
  const s1 = section(0, 0, o.obs.A1, o.obs.B1, false);
  // entre les deux fourches : une goulotte large (24 billes sortent de l'entonnoir en même temps)
  const PM = g3Trace([["S", 16]], {pente:p, from:[s1.x, s1.y, 0]});
  path.push(...g3Trough(k, PM, {WID:5.2, mur:1.5, kind:o.kind}).path);
  // la deuxième fourche : son plateau prend la suite, un peu plus bas
  const e = PM.at(-1), end = section(e[0] + .2, e[1] - .25, o.obs.A2, o.obs.B2, true, 5.2);
  return {path, branches, ...st, ...end, cam:g3ChaseCam};
}

function g3Funnel(k, C, RO, RI, pente, kind, o={}){
  const tp = Math.tan(pente), lot = [], ring = (r1, r2, NS) => { for(let j=0;j<NS;j++){ const a = (j+.5)*TAU/NS, rad = [Math.cos(a), 0, Math.sin(a)], rc = (r1+r2)/2;
    const X = v3.norm([rad[0]*Math.cos(pente), Math.sin(pente), rad[2]*Math.cos(pente)]), Z = [-Math.sin(a), 0, Math.cos(a)], Y = v3.cross(Z, X);
    lot.push({size:[(r2-r1)/Math.cos(pente) + .15, .3, 2*r2*Math.sin(Math.PI/NS)*1.18], pos:v3.add(C, [rad[0]*rc, (rc-RI)*tp - .15, rad[2]*rc]), quat:g3Basis(X, Y, Z), kind:o.sol || "funnel"}) } };
  ring(RI, RI + (RO-RI)*.42, 20); ring(RI + (RO-RI)*.42, RO, 40);
  const NW = 40, yb = (RO-RI)*tp;
  for(let j=0;j<NW;j++){ const a = (j+.5)*TAU/NW, Z = [-Math.sin(a), 0, Math.cos(a)], X = [Math.cos(a), 0, Math.sin(a)];
    lot.push({size:[.25, 3.4, 2*(RO+.2)*Math.sin(Math.PI/NW)*1.1], pos:v3.add(C, [X[0]*(RO+.15), yb + 1.5, X[2]*(RO+.15)]), quat:g3Basis(X, [0,1,0], Z), kind:o.bord || "wall"}) }   // un rebord haut : à 24, des billes sautaient par-dessus
  // une nervure (en face de l'arrivée) : une bille qui tourne s'y arrête et redescend le long d'elle jusqu'au trou
  // (sans elle, une bille tournait plus de 40 s avant de tomber)
  { const a = Math.PI/2 + (o.nerv||0), rad = [Math.cos(a), 0, Math.sin(a)], r1 = RI + .5, r2 = RO - .25, rc = (r1+r2)/2;
    const X = v3.norm([rad[0]*Math.cos(pente), Math.sin(pente), rad[2]*Math.cos(pente)]), Z = [-Math.sin(a), 0, Math.cos(a)], Y = v3.cross(Z, X);
    lot.push({size:[(r2-r1)/Math.cos(pente), .55, .22], pos:v3.add(v3.add(C, [rad[0]*rc, (rc-RI)*tp, rad[2]*rc]), v3.mul(Y, .27)), quat:g3Basis(X, Y, Z), kind:"rail"}) }
  for(let i=0;i<lot.length;i+=20) k.boxes(lot.slice(i, i+20));
  // (14 octobre 2026, le soir) des champignons rebondissants sur la soucoupe : une bille qui tourne les percute et repart n'importe où
  for(let j=0;j<(o.champis ?? 3);j++){ const a = Math.PI/2 + (o.nerv||0) + (j+1)*TAU/((o.champis ?? 3)+1), rad = [Math.cos(a), 0, Math.sin(a)], rc = RI + (RO-RI)*(j%2 ? .62 : .4);
    const X = v3.norm([rad[0]*Math.cos(pente), Math.sin(pente), rad[2]*Math.cos(pente)]), Z = [-Math.sin(a), 0, Math.cos(a)], Y = v3.cross(Z, X);
    k.cyl(.42, 1, v3.add(v3.add(C, [rad[0]*rc, (rc-RI)*tp, rad[2]*rc]), v3.mul(Y, .5)), g3Basis(X, Y, Z), "bump", "rebond") }
  return C[1] + yb;
}

function g3Entonnoirs(k, r, n, o){
  const RO = o.RO || 6.5, RI = o.RI || 1.5, pente = o.pente || 22*Math.PI/180, nb = o.nb || 3, p = .1, pc = .065, WID = 3, off = RO - 2.2, path = [], tp = Math.tan(pente);
  // le premier entonnoir : son centre en (0, 0, 0) ; la goulotte arrive sur la ligne z = -off, vers +x, au-dessus du rebord
  let C = [0, 0, 0], st = null;
  for(let f=0; f<nb; f++){
    const top = g3Funnel(k, C, RO, RI, pente, o.kind, {champis:o.champis}), yIn = top + 3.5;
    // la goulotte qui arrive : elle finit au-dessus de l'entonnoir, à côté du centre, en biais (le long du bord)
    const xe = C[0] - 1.2, len = f===0 ? 20 : null;
    if(f===0){ const P = g3Trace([["S", len]], {pente:p, from:[xe - len, yIn + p*len, C[2] - off]});
      path.push(...g3Trough(k, P, {WID, mur:1.4, kind:o.kind}).path); st = g3TroughStart(k, P, {WID}, n, r) }
    path.push([C[0], top + .6, C[2]], [C[0], C[1] + .2, C[2]]);   // dans l'entonnoir : on avance en descendant vers le trou
    // sous le trou : la goulotte vers l'entonnoir suivant (ou vers le bac)
    const y0 = C[1] - 1.4, last = f===nb-1;
    // l'entonnoir suivant : sa goulotte d'arrivée suit la ligne z = C.z (celle-ci), donc son centre est en z = C.z + off
    // la goulotte commence juste derrière le trou (en pente : avant, un petit bac plat sous le trou gardait les billes et bouchait le trou)
    const D = 2*RO + 4, L = D + .8, P = g3Trace([["S", last ? 18 : L]], {pente:last ? p : pc, from:[C[0] - 2, y0 + .2, C[2]]});   // finit avant le centre de l'entonnoir suivant
    k.box([.3, 2.2, WID+.4], [C[0] - 2.15, y0 + .9, C[2]], [0,0,0], "wall");
    const tr = g3Trough(k, P, {WID, mur:1.4, kind:o.kind}).path; path.push(...tr);
    if(last){ const end = g3TroughEnd(k, P, path, {WID}); return {path, ...st, ...end, cam:g3FunnelCam} }
    const yEnd = P.at(-1)[1];
    C = [C[0] + D, yEnd - 3.6 - (RO-RI)*tp, C[2] + off];   // la goulotte arrive au-dessus du rebord (haut de 3,2)
  }
}

const g3FunnelCam = (p, T) => { const h = Math.hypot(T[0], T[2]); return h < .3 ? [p[0], p[1]+10, p[2]-9] : [p[0] - T[0]/h*4 + T[2]/h*11, p[1]+2.5, p[2] - T[2]/h*4 - T[0]/h*11] };

function g3Trampo(k, r, n, o){
  // (14 octobre 2026, le soir) plus une ligne droite : NL étages en zigzag. Sur chaque étage, des trampolines décalés à gauche puis à
  // droite (les billes rebondissent en biais, certaines ratent leur saut), des boules rebondissantes suspendues, et en dessous une piste
  // de secours avec des plots qui mène aussi à l'étage suivant. Au bout d'un étage, tout le monde tombe sur le début du suivant.
  const NL = o.etages || 4, np = o.np || 11, pas = o.pas || 3.3, dy = o.dy || .55, PL = 2.4, PW = 2.7, CW = 5.2, STEP = o.step || 11.5;
  const tilt = 2*Math.PI/180, x0 = 3, xe = x0 + (np-1)*pas, path = [];
  // la goulotte de départ, qui arrive au-dessus du premier trampoline
  const P0 = g3Trace([["S", 16]], {pente:.1, from:[x0 - 18, 3.2 + 1.6, 0]});
  const st = g3TroughStart(k, P0, {WID:3.2}, n, r); path.push(...g3Trough(k, P0, {WID:3.2, mur:1.4}).path);
  for(let L=0; L<NL; L++){
    const dir = L%2 ? -1 : 1, yL = -L*STEP, X = i => dir>0 ? x0 + i*pas : xe - i*pas, Y = i => yL - i*dy;
    const q = [0, 0, Math.sin(-dir*tilt/2), Math.cos(-dir*tilt/2)];
    for(let i=0;i<np;i++){ const z = i===0 ? 0 : (i%2 ? 1 : -1)*(.95 + .25*r());
      // le premier : une rampe bien penchée sur toute la largeur (et, à partir du 2e étage, plus longue vers le mur du bout de l'étage
      // d'avant : tout ce qui tombe de là-haut atterrit dessus) ; (14 octobre 2026, le soir) presque plate, les billes s'y arrêtaient
      if(i===0){ const t0 = 11*Math.PI/180, q0 = [0, 0, Math.sin(-dir*t0/2), Math.cos(-dir*t0/2)], Lr = L>0 ? PL + 3.4 : PL + .6;
        k.box([Lr, .3, CW - .2], [X(0) - dir*(L>0 ? 1.7 : .3), Y(0) + .25, 0], q0, "ramp") }
      else k.box([PL, .3, PW], [X(i), Y(i), z], q, "tramp", "tramp");
      path.push([X(i), Y(i) + 1, 0]);
      // une boule suspendue toutes les deux plateformes, du côté où il n'y a pas de trampoline : une bille qui file le long du bord la percute
      if(i>0 && i%2===0) k.ball(.5, [X(i) + dir*pas*.5, Y(i) + 1.6, -z*1.1], "bump", "rebond") }
    // la piste du dessous (pente vers le bout de l'étage), avec des plots
    const yf = i => Y(i) - 3, ang = Math.atan(dy/pas), lot = [];
    for(let i=0;i<np;i++) lot.push({size:[pas + .25, .3, CW - .1], pos:[X(i), yf(i), 0], quat:[0, 0, Math.sin(-dir*ang/2), Math.cos(-dir*ang/2)], kind:"ramp"});
    k.boxes(lot);
    // des rangées de plots sur toute la largeur, en quinconce (3 puis 2) ; un passage d'au moins une bille partout, bords compris
    for(let i=1;i<np-1;i++) (i%2 ? [-1.5, 0, 1.5] : [-.75, .75]).forEach(zz=>k.cyl(.2, 1, [X(i) + dir*pas*.5, yf(i) - dy*.5 + .62, zz + (r()-.5)*.1], [0, 0, -dir*ang], "peg"));
    // les murs de l'étage, le bout (où l'on tombe sur l'étage suivant) et le début (fermé)
    const xm = (x0 + xe)/2, ym = (Y(0) + yf(np-1))/2;
    // (des murs hauts : les boules suspendues envoient parfois une bille bien au-dessus des trampolines)
    [-1, 1].forEach(sd=>k.box([xe - x0 + 6, STEP + 6, .3], [xm, ym + 3, sd*(CW/2 + .15)], [0, 0, -dir*ang], "wall"));
    // le mur du bout : de haut en bas, jusqu'à l'étage suivant (sinon une bille lancée passait dessous et tombait dans le vide)
    k.box([.3, STEP + 6, CW], [dir>0 ? xe + pas*.5 + 1.4 : x0 - pas*.5 - 1.4, Y(np-1) - STEP/2 + 1.5, 0], [0,0,0], "end");
    if(L>0) k.box([.3, 4, CW], [dir>0 ? x0 - pas*.5 - 1.2 : xe + pas*.5 + 1.2, Y(0) + 1.5, 0], [0,0,0], "end");
  }
  // le bac : sous le bout du dernier étage
  const dirL = (NL-1)%2 ? -1 : 1, yt = -(NL-1)*STEP - (np-1)*dy - 7, xt = dirL>0 ? xe + 4 : x0 - 4;
  k.box([12, .4, 10], [xt, yt, 0], [0,0,0], "tray");
  [[0, 5.2, 12, .4], [0, -5.2, 12, .4], [6*dirL, 0, .4, 10.8], [-6*dirL, 0, .4, 10.8]].forEach(([dx, dz, sx, sz], j)=>k.box([sx, j===3 ? 2 : 6, sz], [xt + dx, yt + (j===3 ? 1 : 3), dz], [0,0,0], j===3 ? "glass" : "wall"));
  path.push([xt, yt + 1, 0]);
  return {path, ...st, finishY:yt + 1.2, floorY:yt - 3, trayR:7, cam:(p, T)=>[p[0] - 4*Math.sign(T[0]||1), p[1] + 5, p[2] + 15]};
}

const g3ChaseCam = (p, T) => { const h = Math.hypot(T[0], T[2]) || 1; return [p[0] - T[0]/h*10, p[1]+8.5, p[2] - T[2]/h*10] };   // (14 octobre 2026) un peu plus loin


const G3_ORDER = ["lacets","plinko","spirale","toboggan","moulins","flipper","ski","labyrinthe","cascade","billard","pinball","fantome",
  "aquatique","bobsleigh","foret","mine","tourbillon","entonnoirs","volcan","roue","nuages","cirque"];

const G3C = {
  // Cinq rampes en zigzag et des plots qui font rebondir les billes dans tous les sens
  lacets:{name:"Le circuit des lacets", desc:"Cinq rampes en zigzag, des plots qui font rebondir les billes dans tous les sens, et l'arrivée dans le grand bac bleu.",
    theme:{bg:"#1B1428", ramp:"#C9955C", tray:"#2E8CFF"},
    build(k, r, n){ const o = {RAMPS:5, LEN:30, WID:6, STEP:8, ANG:12*Math.PI/180, wallBumps:[.12,.27,.42,.57,.72,.88]};
      const z = g3Zigzag(k, o, (i, {dir, sY})=>{
        for(let j=0;j<5;j++){ const x = -dir*(o.LEN/2-6) + dir*j*(o.LEN-12)/4, zs = j%2 ? [-.95,.95] : [-1.75,0,1.75];
          zs.forEach(zz=>k.cyl(.22, 1.4, [x, sY(x)+.7, zz + (r()-.5)*.3])) } });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3ZigCam} }},

  // Un vrai Plinko géant : un seul grand mur de plots entre deux vitres, du haut jusqu'au bac. Le mur est penché vers l'arrière
  // (les billes descendent moins vite qu'en chute libre) ; des champignons au hasard et des bosses dans les murs mélangent le peloton.
  plinko:{name:"Le Grand Plinko", desc:"Un mur géant de plots entre deux vitres : les billes tombent de plot en plot jusqu'en bas. Impossible de savoir qui arrivera la première !",
    theme:{bg:"#120B24", ramp:"#7B4FD6", tray:"#FF4FD8", peg:"#FFD34D", bump:"#39E6FF"}, axis:1, g:.42,
    build(k, r, n){
      const W = 18, GAP = 1.0, D = GAP+.6, ROWS = 40, DY = 1.5, top = 4, path = [[0, top, 0]];
      const yLast = top - 2 - (ROWS-1)*DY, yb = yLast - 3, bottom = yb - 2;
      const H = top - bottom + 6, cy = (top + bottom)/2 + 2;
      k.box([W+1, H, .3], [0, cy, -GAP/2-.15], [0,0,0], "back"); k.box([W+1, H, .3], [0, cy, GAP/2+.15], [0,0,0], "glass");
      k.box([.4, H, D], [-W/2-.2, cy, 0], [0,0,0], "wall2"); k.box([.4, H, D], [W/2+.2, cy, 0], [0,0,0], "wall2");
      k.box([W+1, .3, D], [0, top+3.8, 0], [0,0,0], "glass");   // le couvercle
      for(let row=0; row<ROWS; row++){ const y = top - 2 - row*DY, off = row%2 ? .9 : 0;
        for(let x=-7.2+off; x<7.3; x+=1.8){   // symétrique : 9 plots sur les rangs pairs, 8 sur les impairs
          // de temps en temps, un gros champignon à la place d'un plot : il renvoie les billes bien plus loin
          if(row>2 && r()<.07) k.pin(.5, GAP*.9, [x, y, 0], "bump", "rebond"); else k.pin(.2, GAP*.9, [x + (r()-.5)*.12, y, 0]) }
        // une bosse ronde dans chaque mur, un rang sur deux : personne ne descend tranquillement le long du bord
        if(row%2===1) [-1,1].forEach(s=>k.pin(.5, GAP*.9, [s*(W/2+.05), y, 0], "wall2"));
      }
      k.box([W, .4, D], [0, yb-1.5, 0], [0,0,0], "tray"); path.push([0, yb-1, 0]);
      const cols = 17, starts = [];
      for(let i=0;i<n;i++){ const c = i%cols, rw = Math.floor(i/cols); starts.push([-W/2+.75 + c*(W-1.5)/(cols-1) + (r()-.5)*.04, top + 1 + rw*.95, 0]) }
      return {path, starts, gate:k.box([W, .3, D], [0, top+.4, 0], [0,0,0], "gate"), finishY:yb+1.5, floorY:bottom-2,
        cam:p=>[p[0]*.5, p[1]-1, 23], look:p=>[p[0]*.8, p[1]-3, 0]} }},

  // Une grande spirale qui tourne autour d'une tour : les billes collent au bord en prenant de la vitesse
  // (16 octobre 2026) trop « simple » comme le Volcan : une piste plus large (4,2 au lieu de 2,8) pour doubler, autour d'une tour plus grosse,
  // et des champignons rebondissants entre les pales. Banc : 7 changements de tête (avant 4), 13,5 places par bille (avant 10), deux fois moins de pichenettes
  spirale:{name:"L'Entonnoir", desc:"Une grande spirale autour d'une tour, semée de plots, de champignons qui renvoient les billes et de pales qui tournent : elles retiennent une bille, en laissent filer une autre… Rien n'est joué avant le fond !",
    theme:{bg:"#0E1A2B", ramp:"#3FB6A8", tray:"#FFB547"}, axis:1,
    build(k, r, n){
      const RM = 8, WID = 4.2, TURNS = 2.5, NS = 32, DROP = 12, BANK = 9*Math.PI/180, path = [];
      const dA = TAU/NS, N = TURNS*NS, slope = DROP/(TAU*RM), RO = RM+WID/2, len = 2*RO*Math.sin(dA/2)*1.04;
      const at = a => [RM*Math.cos(a), -a/TAU*DROP, RM*Math.sin(a)];
      for(let j=0;j<N;j++){ const a = (j+.5)*dA, P = at(a), rad = [Math.cos(a),0,Math.sin(a)];
        const X = v3.norm([-Math.sin(a), -slope, Math.cos(a)]);
        // relevée vers l'extérieur : le bord extérieur est plus haut
        let Z = v3.norm(v3.add(v3.mul(rad, Math.cos(BANK)), [0, Math.sin(BANK), 0])); const Y = v3.norm(v3.cross(Z, X)); Z = v3.cross(X, Y);
        const q = g3Basis(X, Y, Z);
        k.box([len, .35, WID], P, q, "ramp");
        const Xw = v3.norm([-Math.sin(a), -slope, Math.cos(a)]), Yw = [0,1,0], Zw = v3.norm(v3.cross(Xw, Yw));
        const qw = g3Basis(Xw, v3.cross(Zw, Xw), Zw);
        k.box([len, 2.2, .25], v3.add(P, v3.add(v3.mul(rad, WID/2+.2), [0, .9, 0])), qw, "wall");
        k.box([len*.82, 2.4, .25], v3.add(P, v3.add(v3.mul(rad, -WID/2-.15), [0, 1.1, 0])), qw, "inner");
        if(j%2===0) path.push(v3.add(P, [0, .5, 0]));
        // les obstacles, après le départ : des plots sur la piste, des bosses rondes en travers,
        // et de temps en temps une pale qui tourne en travers de la piste
        // (up : le dessus de la piste ; Y pointe vers le bas avec cette base)
        const up = Y[1] < 0 ? v3.mul(Y, -1) : Y;
        if(j>6 && j<N-3){
          // une pale tous les quarts de tour (elle retient une bille au hasard, en laisse filer une autre), un plot entre deux
          if(j%14===3) k.spin([.4, .45, WID-.7], v3.add(P, v3.mul(up, .5)), q, v3.mul(up, (j%14<7 ? 1 : -1)*(1.8+.6*r())));
          else if(j%7===6 || j%14===10) k.cyl(.24, 1.2, v3.add(P, v3.add(v3.mul(rad, (j%14<7 ? .3 : -.05)), v3.mul(up, .75))), q);
          else if(j%14===0 || j%14===8) k.cyl(.45, 1, v3.add(P, v3.add(v3.mul(rad, (r()-.5)*1.2), v3.mul(up, .5))), q, "bump", "rebond");
        }
      }
      const yEnd = at(N*dA)[1];
      // la tour au centre, et le grand bac rond en bas
      const tH = -yEnd + 6; k.look("cyl", [RM-WID/2-.1, tH], [0, yEnd + tH/2 - 3, 0], null, "tower");
      const yb = yEnd - 4; k.box([2*RO+6, .4, 2*RO+6], [0, yb, 0], [0,0,0], "tray");
      [[1,0],[-1,0],[0,1],[0,-1]].forEach(([sx,sz])=>k.box(sx ? [.4, 3, 2*RO+6] : [2*RO+6, 3, .4], [sx*(RO+3), yb+1.6, sz*(RO+3)], [0,0,0], "wall"));
      path.push([RM+2, yb+1, 0]);
      // départ : trois files sur le début de la spirale, derrière une barrière
      const starts = [];
      for(let i=0;i<n;i++){ const row = Math.floor(i/3), lane = i%3, a = .25 + row*1.05/RM + (r()-.5)*.01, P = at(a), rr = RM + (lane-1)*.85 + (r()-.5)*.08;
        starts.push([rr*Math.cos(a), P[1] + .2 + G3.R + .05 + .2, rr*Math.sin(a)]) }
      const ag = .25 + Math.ceil(n/3)*1.05/RM + .12, G = at(ag);
      const gate = k.box([.3, 2, WID], v3.add(G, [0, .9, 0]), g3Basis(v3.norm([-Math.sin(ag),0,Math.cos(ag)]), [0,1,0], v3.cross(v3.norm([-Math.sin(ag),0,Math.cos(ag)]), [0,1,0])), "gate");
      return {path, starts, gate, finishY:yb+1, floorY:yb-1, trayR:26,
        cam:p=>{ const a = Math.atan2(p[2], p[0]); return [Math.cos(a)*(RM+12), p[1]+6, Math.sin(a)*(RM+12)] }} }},

  // De longues pentes raides, des tremplins et des marches : ça saute !
  toboggan:{name:"Le Toboggan", desc:"De longues pentes pleines de bosses, de plots et de champignons, et sur chaque rampe une trappe qui fait tomber les chanceuses directement sur la rampe du dessous !",
    theme:{bg:"#1E1410", ramp:"#E8743B", tray:"#2FA35A"},
    build(k, r, n){ const o = {RAMPS:4, LEN:34, WID:6, STEP:9, ANG:11*Math.PI/180, wall:8, holes:i=>({f:.9, side:i%2 ? -1 : 1, w:1.2}), wallBumps:[.19,.36,.53,.7]};
      const z = g3Zigzag(k, o, (i, {dir, sY, rot})=>{
        // deux tremplins par rampe, et des rondins
        // (14 octobre 2026) tremplins moins hauts, et rondins en biais avec un passage au bout (d'un côté puis de l'autre) :
        // posés droits en travers, ils retenaient les billes lentes (une bille arrêtée roule maintenant le long du rondin jusqu'au trou)
        [.35,.7].forEach((f, j)=>{ const x = -dir*o.LEN/2 + dir*f*o.LEN;
          k.cyl(2.2, o.WID, [x, sY(x)+.2-2.2+.18, 0], [Math.PI/2,0,0], "kick") });
        [.18,.52,.86].forEach((f, j)=>{ const x = -dir*o.LEN/2 + dir*f*o.LEN, g = (i+j)%2 ? 1 : -1, PH = 22*Math.PI/180, GAP = 1.4;
          const Xr = [Math.cos(rot), Math.sin(rot), 0], N = [-Math.sin(rot), Math.cos(rot), 0], sg = g*dir;
          const d = v3.norm(v3.add(v3.mul(Xr, sg*Math.sin(PH)), [0, 0, Math.cos(PH)])), len = (o.WID-GAP)/Math.cos(PH);
          k.cyl(.35, len, [x, sY(x), -g*GAP/2], g3Basis(N, d, v3.cross(N, d)), "bump") });
        // des rangées de plots entre les bosses (3 puis 2, en quinconce), et un champignon à ressort au bout de chaque rampe
        [.1,.27,.44,.61,.79].forEach((f, j)=>{ const x = -dir*o.LEN/2 + dir*f*o.LEN;
          (j%2 ? [-.8,.8] : [-1.55,0,1.55]).forEach(zz=>k.cyl(.22, 1.4, [x, sY(x)+.7, zz + (r()-.5)*.1])) });
        { const x = -dir*o.LEN/2 + dir*.94*o.LEN; k.cyl(.45, 1.2, [x, sY(x)+.4, (r()-.5)*2], null, "bump", "rebond") } });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3ZigCam} }},

  // Des pales qui tournent en travers de la piste et repoussent les billes
  moulins:{name:"Les Moulins", desc:"Trois pales qui tournent sur chaque rampe, des rangées de plots, et une trappe-raccourci : les billes sont balayées, retenues, lancées… Il faut passer au bon moment !",
    theme:{bg:"#101A14", ramp:"#9C7A4E", tray:"#5AB8FF", spin:"#FFD34D"},
    build(k, r, n){ const o = {RAMPS:4, LEN:32, WID:7, STEP:9.5, ANG:12.5*Math.PI/180, wall:8.5, holes:i=>({f:.9, side:i%2 ? 1 : -1, w:1.4}), wallBumps:[.3,.47,.62,.78,.95]};
      const z = g3Zigzag(k, o, (i, {dir, sY, rot})=>{
        const nrm = [-Math.sin(rot), Math.cos(rot), 0];
        [i ? .25 : .36,.55,.85].forEach((f, j)=>{ const x = -dir*o.LEN/2 + dir*f*o.LEN, w = ((i+j)%2 ? 1 : -1)*(.8 + .5*r());
          const c = v3.add([x, sY(x), 0], v3.mul(nrm, .55));
          k.spin([4.6, .5, .5], c, [0,0,rot], v3.mul(nrm, w));
          k.cyl(.3, 1.6, v3.add([x, sY(x), 0], v3.mul(nrm, .8)), [0,0,rot], "axle") });
        // entre les pales, des rangées de plots (3 de front)
        [.12,.4,.7].forEach(f=>{ const x = -dir*o.LEN/2 + dir*f*o.LEN; [-2,0,2].forEach(zz=>k.cyl(.22, 1.4, [x, sY(x)+.7, zz + (r()-.5)*.3])) }) });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3ZigCam} }},

  // Un grand escalier de flipper : des marches et des champignons qui renvoient les billes
  flipper:{name:"Le Flipper", desc:"Un grand escalier de flipper : les billes dégringolent les marches et rebondissent sur des champignons à ressort.",
    theme:{bg:"#1A0F22", ramp:"#3A4E9C", tray:"#FF6FB5", bump:"#FF4F7A"},
    build(k, r, n){ const o = {RAMPS:4, LEN:34, WID:8, STEP:9.5, ANG:12*Math.PI/180, noRamp:true, wallBumps:[.265,.395,.525,.655,.85]};
      const z = g3Zigzag(k, o, (i, {dir, y, rot, cx, sY})=>{
        // la rampe en marches : 6 marches, chacune un peu plus bas que la droite de la pente
        const ext = 2.6, L = o.LEN+ext, x0 = cx - dir*L/2, sl = L/6;
        for(let s=0;s<6;s++){ const xc = x0 + dir*(s+.5)*sl; k.box([sl+.3, .4, o.WID], [xc, sY(xc), 0], [0,0,rot*.55], "ramp") }
        // les champignons à ressort, en triangles
        for(let j=0;j<5;j++){ const f = .2 + j*.13, x = -dir*o.LEN/2 + dir*f*o.LEN, zs = j%2 ? [-1.3, 1.3] : [-2.3, 0, 2.3];
          zs.forEach(zz=>k.cyl(.45, 1.2, [x, sY(x)+.4, zz + (r()-.5)*.3], null, "bump", "rebond")) }
});
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3ZigCam} }},
  // ---------- (14 octobre 2026) les nouveaux circuits : midi en plein air, le soir comme une fête foraine ----------
  // Une piste de ski : des portes de slalom (deux piquets rouges) d'un côté puis de l'autre, et des bosses de neige en biais
  ski:{name:"La Piste de ski", desc:"Cinq pistes enneigées, des portes de slalom d'un côté puis de l'autre et des bosses partout : il faut savoir tourner !",
    theme:{bg:"#1C2A40", ramp:"#EEF4FF", tray:"#2E8CFF", peg:"#E8414B", bump:"#CFE0F5"},
    build(k, r, n){ const o = {RAMPS:5, LEN:30, WID:7, STEP:9.5, ANG:12*Math.PI/180, wall:4.5, wallBumps:[.23,.59]};   // (les bosses des murs loin des piquets)
      const z = g3Zigzag(k, o, (i, {dir, sY, rot})=>{ const xf = f => -dir*o.LEN/2 + dir*f*o.LEN;
        [.14,.32,.5,.68,.86].forEach((f, j)=>{ const x = xf(f), zc = ((i+j)%2 ? 1 : -1)*1.5;
          [-.85,.85].forEach(dz=>k.cyl(.12, 1.8, [x, sY(x)+.9, zc+dz], [0,0,rot], "peg")) });
        // (les bosses restent loin des murs : une bille se coinçait entre une bosse et le mur)
        [.23,.41,.59,.77].forEach((f, j)=>{ const x = xf(f), zz = ((i+j)%2 ? -1 : 1)*.9 + (r()-.5)*.4;
          g3Log(k, rot, j%2 ? 1 : -1, 30*Math.PI/180, .32, 1.4, [x, sY(x)-.04, zz], "bump") }) });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3ZigCam} }},

  // Un plateau penché coupé de haies en biais : chaque rangée a deux passages, tirés au sort à chaque course
  labyrinthe:{name:"Le Labyrinthe", desc:"Quatre grands plateaux en bois coupés de haies : à chaque rangée, deux passages seulement, et jamais au même endroit d'une course à l'autre !",
    theme:{bg:"#1A2414", ramp:"#D9B47A", tray:"#5AB8FF", maze:"#5E8C34"},
    build(k, r, n){ const o = {RAMPS:4, LEN:34, WID:9, STEP:8.5, ANG:11*Math.PI/180, wall:3};
      const z = g3Zigzag(k, o, (i, {dir, sY, rot})=>{ const xf = f => -dir*o.LEN/2 + dir*f*o.LEN, N = [-Math.sin(rot), Math.cos(rot), 0], W = o.WID/2 - .05;
        const top = (x, zz) => [x, sY(x)+.2, zz];
        // un muret en biais (25°) : il finit au passage, une bille arrêtée contre lui roule jusqu'au trou
        const seg = (x0, za, zb) => k.seg(top(x0 - dir*Math.abs(zb-za)*.47, za), top(x0, zb), N, 1.2, "maze");
        [.26,.43,.6,.77,.93].forEach((f, j)=>{ if(i===0 && j===0) return;   // pas de haie juste après le départ : le peloton s'y bouchait
          const x0 = xf(f), skip = Math.floor(r()*3), g = [-2.9, 0, 2.9].filter((_,j)=>j!==skip), m = (g[0]+g[1])/2;
          seg(x0, -W, g[0]-.95); seg(x0, m, g[0]+.95); seg(x0, m, g[1]-.95); seg(x0, W, g[1]+.95) }) });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3TableCam} }},

  // Des terrasses de pierre en escalier, sous une nappe d'eau, et des rochers posés çà et là
  cascade:{name:"La Cascade", desc:"Des dizaines de terrasses de pierre sous l'eau : les billes dégringolent de marche en marche et ricochent sur les rochers.",
    theme:{bg:"#0E2230", ramp:"#7FA7B8", tray:"#2FA35A", rock:"#8C949C"},
    build(k, r, n){ const o = {RAMPS:4, LEN:34, WID:7, STEP:9.5, ANG:12*Math.PI/180, noRamp:true, wallBumps:[.33,.66]};
      const z = g3Zigzag(k, o, (i, {dir, y, rot, cx, sY})=>{
        const ext = 2.6, L = o.LEN+ext, x0 = cx - dir*L/2, NS = 10, sl = L/NS;
        for(let s=0;s<NS;s++){ const xc = x0 + dir*(s+.5)*sl; k.box([sl+.3, .4, o.WID], [xc, sY(xc), 0], [0,0,rot*.35], "ramp") }
        // les rochers : sur 4 terrasses au hasard (jamais la première), à gauche ou à droite
        for(let j=0;j<4;j++){ const s = 1 + Math.floor(r()*(NS-3)), xc = x0 + dir*(s+.5)*sl; k.ball(.42, [xc, sY(xc)+.4, (r()<.5 ? -1 : 1)*r()*1.2], "rock") }
        k.look("box", [o.LEN, .05, o.WID-.1], [cx, y+.75, 0], [0, 0, Math.sin(rot/2), Math.cos(rot/2)], "water") });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3ZigCam} }},

  // Un billard en pente : des boules rangées en triangle, des bandes, et une poche-raccourci au bout de chaque tapis
  billard:{name:"Le Billard géant", desc:"Quatre tapis verts en pente, des triangles de boules à contourner, et au bout de chaque tapis une poche qui fait gagner du terrain.",
    theme:{bg:"#10201A", ramp:"#1F7A4A", tray:"#7A4A22", pool:"#F2C230", pool2:"#C8312E"},
    build(k, r, n){ const o = {RAMPS:4, LEN:34, WID:10, STEP:7, ANG:8.5*Math.PI/180, wall:2.2, holes:i=>({f:.88, side:i%2 ? 1 : -1, w:1.6}), wallBumps:[.15,.4,.65]};
      const z = g3Zigzag(k, o, (i, {dir, sY})=>{ const xf = f => -dir*o.LEN/2 + dir*f*o.LEN;
        [.3,.62].forEach((f, t)=>{ const x0 = xf(f), zc = ((i+t)%2 ? 1 : -1)*1.2;
          for(let row=0; row<3; row++) for(let j=0; j<=row; j++){ const x = x0 + dir*row*1.15;
            k.ball(.5, [x, sY(x)+.68, zc + (j - row/2)*1.25], (row+j)%2 ? "pool2" : "pool") } }) });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3TableCam} }},

  // Un flipper à plat, la nuit : des bumpers qui renvoient fort, des couloirs au départ et des lance-billes au bout
  pinball:{name:"Le Pinball néon", desc:"Quatre plateaux de pinball qui brillent dans le noir : des bumpers qui renvoient les billes très loin, des couloirs et des lance-billes.",
    theme:{bg:"#0B0620", ramp:"#2A1E5C", tray:"#FF2E88", bump:"#39E6FF", sling:"#FF2E88", peg:"#FFD34D"},
    build(k, r, n){ const o = {RAMPS:4, LEN:34, WID:9, STEP:8, ANG:10*Math.PI/180, wall:2.5, wallBumps:[.2,.45,.7]};
      const z = g3Zigzag(k, o, (i, {dir, sY, rot})=>{ const xf = f => -dir*o.LEN/2 + dir*f*o.LEN, N = [-Math.sin(rot), Math.cos(rot), 0], W = o.WID/2;
        const top = (x, zz) => [x, sY(x)+.2, zz];
        // les couloirs du départ de chaque plateau
        [-1.6, 1.6].forEach(zz=>k.seg(top(xf(.1), zz), top(xf(.17), zz), N, .7, "rail"));
        // deux triangles de bumpers
        [[.32, -1], [.6, 1]].forEach(([f, sd], t)=>{ const x0 = xf(f), zc = sd*((i%2) ? -1 : 1)*1.3;
          [[0, 0], [2.2, -1.6], [2.2, 1.6]].forEach(([dx, dz])=>{ const x = x0 + dir*dx; k.cyl(.6, 1.2, [x, sY(x)+.6, zc+dz], [0,0,rot], "bump", "rebond") }) });
        // les lance-billes : deux bandes en biais qui renvoient vers le milieu
        [-1, 1].forEach(sd=>k.seg(top(xf(.8), sd*(W-.1)), top(xf(.92), sd*(W-1.9)), N, .8, "sling", "rebond")) });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3TableCam} }},

  // Le train fantôme : des tunnels noirs, des portes qui tournent et des fantômes qui flottent au-dessus de la piste
  fantome:{name:"Le Train fantôme", desc:"Cinq rampes qui plongent dans des tunnels noirs, des portes qui tournent sans arrêt et des fantômes qui flottent… Qui osera sortir la première ?",
    theme:{bg:"#0E0A18", ramp:"#4A3A5E", tray:"#7CE59A", spin:"#E8E8F0", roof:"#241A33", tunnel:"#1A1226", ghost:"#E6F0FF"},
    build(k, r, n){ const o = {RAMPS:5, LEN:30, WID:5.5, STEP:9.5, ANG:12*Math.PI/180, wall:4.5, wallBumps:[.15,.85]};
      const z = g3Zigzag(k, o, (i, {dir, sY, rot})=>{ const xf = f => -dir*o.LEN/2 + dir*f*o.LEN, N = [-Math.sin(rot), Math.cos(rot), 0];
        const q = [0, 0, Math.sin(rot/2), Math.cos(rot/2)], up = (x, h) => v3.add([x, sY(x), 0], v3.mul(N, h));
        // le tunnel : un toit (vrai) et des côtés noirs (du décor)
        const xa = xf(.3), xb = xf(.66), xm = (xa+xb)/2, tl = Math.abs(xb-xa)/Math.cos(rot);
        k.box([tl, .3, o.WID+.8], up(xm, 2.75), [0,0,rot], "roof");
        [-1, 1].forEach(sd=>k.look("box", [tl, 2.6, .2], v3.add(up(xm, 1.45), [0, 0, sd*(o.WID/2+.45)]), q, "tunnel"));
        // les portes qui tournent : elles poussent les billes vers l'avant en passant
        [.2,.5,.82].forEach((f, j)=>{ const x = xf(f); k.spin([.3, 2.2, o.WID-.4], up(x, 1.55), [0,0,rot], [0, 0, dir*(.8+.2*j)]) });
        // les fantômes (du décor)
        for(let j=0;j<2;j++){ const x = xf(.15+r()*.7); k.look("sph", [.55], v3.add(up(x, 3.8+r()*1.2), [0, 0, (r()-.5)*4]), null, "ghost") } });
      return {...z, ...g3ZigStart(k, o, n, r), cam:g3ZigCam} }},
  // ---------- (14 octobre 2026) les goulottes : des pistes qui serpentent, sans rampes en zigzag ----------
  // Un toboggan aquatique : une longue goulotte bleue qui serpente, des virages relevés, et (le soir même, 14 octobre) des obstacles
  // tout du long pour le suspense : tourniquets, portes qui tournent, champignons, plots
  aquatique:{name:"Le Toboggan aquatique", desc:"Une longue piste bleue qui serpente : des virages relevés, des tourniquets qui balaient la piste, des champignons qui renvoient les billes et des plots. Rien n'est joué !",
    theme:{bg:"#0E2A3A", ramp:"#3FB6E8", tray:"#FFD34D", spin:"#FFD34D", bump:"#FF6FB5", peg:"#FFFFFF"}, form:"serpent",
    build(k, r, n){ const o = {WID:4.4, mur:1.6, pente:.14};
      const P = g3Trace([["S",14],["D",7,110],["S",12],["G",7,180],["S",12],["D",6,180],["S",12],["G",7,180],["S",12],["D",6,180],["S",12],["G",8,160],["S",12],["D",6,180],["S",14]], o);
      const {path, frames} = g3Trough(k, P, o), L = g3Semis(P, ["champis","moulin","plots","bosse","moulin","champis"], r);
      g3Obstacles(k, frames, o.WID, L, r);
      return {path, ...g3TroughStart(k, P, o, n, r), ...g3TroughEnd(k, P, path, o), cam:g3ChaseCam} }},

  // Un bobsleigh la nuit : une piste de glace, des virages serrés et très relevés, et des obstacles qui brillent
  bobsleigh:{name:"Le Bobsleigh", desc:"Une piste de glace qui file dans la nuit : des virages très relevés, des champignons lumineux et des plots partout. Une erreur et on perd sa place !",
    theme:{bg:"#0B1430", ramp:"#DCEBFF", tray:"#5AB8FF", spin:"#5AB8FF", bump:"#FF4F7A", peg:"#FFD34D"}, form:"serpent",
    build(k, r, n){ const o = {WID:4, mur:1.8, pente:.15, relief:6, bankMax:.34};
      const P = g3Trace([["S",16],["G",10,90],["S",12],["D",8,150],["S",12],["G",9,150],["S",12],["D",7,140],["S",12],["G",6,180],["S",12],["D",10,120],["S",12],["G",8,130],["S",16]], o);
      const {path, frames} = g3Trough(k, P, o), L = g3Semis(P, ["champis","plots","bosse","champis","plots","bosse"], r);   // (pas de tourniquet : sur cette piste plus étroite, une bille se coinçait à côté)
      g3Obstacles(k, frames, o.WID, L, r);
      return {path, ...g3TroughStart(k, P, o, n, r), ...g3TroughEnd(k, P, path, o), cam:g3ChaseCam} }},

  // ---------- (14 octobre 2026) les chemins qui se séparent ----------
  // La forêt : à la fourche, un raccourci plein de racines (plots) et de souches, ou un grand détour tranquille sous les arbres
  foret:{name:"La Forêt", desc:"Deux fourches : à chacune, les billes partent d'un côté ou de l'autre, entre raccourcis pleins de racines et de troncs qui tournent, et grands détours. Quatre chemins, une seule gagnante !",
    theme:{bg:"#13261A", ramp:"#9B7348", tray:"#7CC46A", peg:"#5E3F22", rock:"#6E5034"}, form:"fourche",
    build(k, r, n){ return g3Fourche(k, r, n, {pente:.09, obs:{A1:["plots","bosse","plots","bosse","plots","champis","plots"], B1:["champis","plots","bosse"],
      A2:["moulin","plots","moulin","bosse","moulin"], B2:["plots","champis","plots"]}}) }},

  // La mine, le soir : le raccourci passe par des portes qui tournent (les wagonnets !), le détour fait le tour de la galerie
  mine:{name:"La Mine", desc:"Une mine éclairée aux lanternes, deux fourches et quatre galeries : des portes qui tournent, des wagonnets qui balaient la voie… Quel chemin sera le bon ?",
    theme:{bg:"#140E0A", ramp:"#6B5440", tray:"#FFB547", spin:"#C9A36B", peg:"#FFB547"}, form:"fourche",
    build(k, r, n){ return g3Fourche(k, r, n, {pente:.09, obs:{A1:["porte","plots","porte","bosse","porte"], B1:["moulin","champis","plots"],
      A2:["moulin","champis","porte","plots","moulin"], B2:["bosse","moulin","bosse"]}}) }},

  // ---------- (14 octobre 2026) les entonnoirs en cascade ----------
  // Le tourbillon, à midi : trois grands entonnoirs d'eau, les billes tournent, tournent… et plongent dans le trou
  tourbillon:{name:"Le Tourbillon", desc:"Trois grands entonnoirs bleus : les billes y entrent en tournant, font des tours et des tours… puis plongent par le trou vers le suivant !",
    theme:{bg:"#0D2733", ramp:"#36C2D8", tray:"#FFD34D"}, form:"entonnoirs", patience:7,
    build(k, r, n){ return g3Entonnoirs(k, r, n, {nb:3, RO:6.5}) }},
  // Les trois entonnoirs, le soir : plus grands, en néon
  entonnoirs:{name:"Les Entonnoirs néon", desc:"Trois entonnoirs géants qui brillent dans la nuit : les billes tourbillonnent les unes contre les autres avant de tomber dans le suivant.",
    theme:{bg:"#120A26", ramp:"#7B4FD6", tray:"#FF4FD8"}, form:"entonnoirs", patience:7,
    build(k, r, n){ return g3Entonnoirs(k, r, n, {nb:3, RO:7.5, RI:1.85, pente:20*Math.PI/180}) }},

  // ---------- (14 octobre 2026) la spirale qui s'élargit ----------
  // Le volcan : une piste de roche qui tourne autour d'un cône, de plus en plus large en descendant, avec des rochers.
  // (16 octobre 2026) trop « simple » (la tête filait seule, personne ne doublait ; banc : 5 places gagnées ou perdues par bille, le plus bas) :
  // un cratère en haut (un entonnoir qui mélange le peloton), une piste plus large (5,4 au lieu de 3,8) pour doubler, moins de pente,
  // un obstacle tous les sixièmes de tour (portes, tourniquets, champignons, plots), deux crevasses qui font sauter un tour aux chanceuses,
  // des rochers des deux côtés. Banc : 12 places par bille, 5 changements de tête, gagnant vers 72 s (avant 51 s)
  volcan:{name:"Le Volcan", desc:"Les billes plongent dans le cratère, tourbillonnent, puis dévalent une large piste de roche autour du volcan : rochers, portes de lave, tourniquets… et des crevasses qui font sauter un tour aux chanceuses. Personne n'est à l'abri jusqu'au lac de lave !",
    theme:{bg:"#2A1410", ramp:"#B39276", tray:"#FF5A1F", rock:"#4A3A34", tower:"#6A4A3E", spin:"#FF5A1F", bump:"#FF8A3D", peg:"#FFD34D"}, form:"spirale",
    build(k, r, n){ const NTR = 2, o = {WID:5.4, mur:1.6, pente:.1}, T = 3, A = T*TAU, R0 = 7, R1 = 14.5, drop = 20, NS = 180;
      // la spirale (dans le sens des aiguilles d'une montre vue d'en haut)
      const at = a => { const R = R0 + (R1-R0)*a/A; return [R*Math.cos(a), -drop*a/A, R*Math.sin(a)] };
      // (16 octobre 2026) le cratère : la goulotte de départ arrive dans un entonnoir en haut du volcan, les billes y tournent
      // et se mélangent, tombent par le trou sur une goulotte qui tourne et rejoint la spirale
      const RO = 6.5, RI = 1.5, pf = 22*Math.PI/180, C = [-2, 0, -5], off = RO - 2.2;
      // (16 octobre 2026, le soir) un cratère de roche : avec le fond à moitié transparent et le rebord en verre, on voyait la spirale à travers
      const top = g3Funnel(k, C, RO, RI, pf, null, {champis:3, sol:"ramp", bord:"tower"}), yIn = top + 3.5, xe = C[0] - 1.2, L0 = 18;
      const P0 = g3Trace([["S", L0]], {pente:.1, from:[xe - L0, yIn + .1*L0, C[2] - off]});
      const S0 = g3Trough(k, P0, {WID:3, mur:1.4}), st = g3TroughStart(k, P0, {WID:3}, n, r);
      // sous le trou : une goulotte étroite qui tourne (rayon 5) et arrive sur la spirale, en (R0, yS, 0) vers +z
      k.box([.3, 2.2, 3.4], [C[0] - 2.15, C[1] - 2.2 + 1.1, C[2]], [0,0,0], "wall");
      [-1, 1].forEach(sd=>k.box([5, 2, .25], [C[0] + .3, C[1] - 1.4, C[2] + sd*1.75], [0,0,0], "wall"));   // une bille qui tombe du trou ne saute pas hors de la goulotte
      const P1 = g3Trace([["S", 6], ["D", 5, 90]], {pente:.1, from:[C[0] - 2, C[1] - 2.2, C[2]]}), S1 = g3Trough(k, P1, {WID:3.2, mur:1.6});
      const yS = P1.at(-1)[1] - .08, P = [];
      for(let i=0;i<=NS;i++){ const q = at(i*A/NS); P.push([q[0], q[1] + yS, q[2]]) }
      const I0 = 0, iA = a => I0 + Math.round(a/A*NS);
      // les crevasses : une trappe contre le bord extérieur à chaque tour (sauf le dernier) ; la bille qui tombe atterrit sur le tour du dessous
      const TR = [1.6, 1.6+TAU+Math.PI*.8].map(iA); o.trous = {}; TR.forEach(i=>{ for(let d=0; d<NTR; d++) o.trous[i+d] = -1 });   // (Z pointe vers l'intérieur)
      const {path, frames} = g3Trough(k, P, o);
      // là où atterrit une bille tombée d'une crevasse (un tour plus bas, un peu plus loin) : de hauts murs de verre des deux côtés,
      // sinon elle rebondissait par-dessus le bord
      const L1 = Math.round(NS/T);
      TR.forEach(t=>{ for(let i=t+L1-2; i<t+L1+9; i++){ const F = frames[i]; if(!F) continue;
        [-1, 1].forEach(sd=>k.box([1.7, 4, .3], v3.add(F.M, v3.add(v3.mul(F.Z, sd*(o.WID/2+.3)), v3.mul(F.Y, 2))), F.q, "end")) } });
      // un obstacle tous les sixièmes de tour environ (pas près des crevasses) : portes qui tournent, tourniquets, champignons, plots
      const OBS = ["champis","plots","moulin","bosse","champis","porte","plots","moulin","champis","bosse","moulin","plots","porte","champis","moulin","bosse","champis","porte","plots","moulin"];
      const pos = OBS.map((t, j)=>[I0 + 22 + Math.round(j*(NS-32)/(OBS.length-1)), t]).filter(([i])=>!TR.some(t=>i>t-6 && i<t+NTR+4));
      g3Obstacles(k, frames, o.WID, pos, r);
      // des rochers entre les obstacles : des petits contre un bord ou l'autre, des gros au milieu ; toujours au moins une bille
      // de passage entre un rocher et le bord, et jamais à moins de 5 morceaux d'un obstacle ou d'une crevasse
      const near = i => pos.some(([p])=>Math.abs(p-i)<5) || TR.some(t=>i>t-5 && i<t+NTR+4);
      for(let j=0;j<30;j++){ const a = (.06 + j*.031)*A + (r()-.5)*.1, i = iA(a); if(near(i)) continue;
        const F = frames[Math.min(frames.length-1, i)], kind = j%3, R = kind===2 ? .55 : .38;
        const off = kind===2 ? (r()-.5)*.4 : (kind ? 1 : -1)*(1.1 + r()*.15);
        k.ball(R, v3.add(v3.add(F.M, v3.mul(F.Z, off)), v3.mul(F.Y, R*.85)), "rock") }
      // le cône du volcan (du décor), au milieu de la spirale
      k.look("cone", [R0-2.6, R1-3.2, drop+2], [0, yS - drop/2 - 2, 0], null, "tower");   // (un peu plus bas : la goulotte sous le cratère passe au-dessus)
      const end = g3TroughEnd(k, P, path, o);
      return {path:[...S0.path, [C[0], top + .6, C[2]], [C[0], C[1] + .2, C[2]], ...S1.path, ...path], ...st, ...end, // dans le cratère, la caméra est au-dessus de son milieu (du côté opposé à la bille) et regarde vers le bord : le rebord de roche ne cache rien
        cam:(p, T)=>{ if(p[1] <= yS + 1) return g3ChaseCam(p, T); const dx = p[0] - C[0], dz = p[2] - C[2], d = Math.hypot(dx, dz) || 1;
          return [C[0] - dx/d*3, top + 10, C[2] - dz/d*3] }} }},

  // ---------- (14 octobre 2026) la grande roue ----------
  // Un mur entre deux vitres, comme le Plinko, mais coupé par deux grandes roues qui tournent en sens contraire :
  // elles attrapent les billes sur leurs rayons, les emmènent et les relâchent un peu plus loin
  roue:{name:"La Grande Roue", desc:"Deux grandes roues illuminées qui tournent en sens contraire : elles attrapent les billes sur leurs rayons, les promènent… et les lâchent n'importe où !",
    theme:{bg:"#120B24", ramp:"#2A1E5C", tray:"#FF4FD8", peg:"#FFD34D", bump:"#39E6FF", spin:"#FF6FB5"}, form:"roue", axis:1, g:.3,
    build(k, r, n){
      const W = 18, GAP = 1.0, D = GAP+.6, top = 4, DY = 1.5, rows = (y0, nb) => { for(let row=0; row<nb; row++){ const y = y0 - row*DY, off = row%2 ? .9 : 0;
          for(let x=-7.2+off; x<7.3; x+=1.8) k.pin(.2, GAP*.9, [x + (r()-.5)*.12, y, 0]);
          if(row%2===1) [-1,1].forEach(s=>k.pin(.5, GAP*.9, [s*(W/2+.05), y, 0], "wall2")) } };
      // des plots en haut, la première roue, des plots, la seconde roue, des plots, le bac
      // (14 octobre 2026, le soir) des roues plus grandes : rayons de 7,5 (un passage de 1,5 reste le long des bords)
      const RR = 7.5;
      rows(top - 2, 11);
      const y1 = top - 2 - 11*DY - RR - 1; k.wheel(RR, 6, GAP*.85, [0, y1, 0], .4);
      rows(y1 - RR - 2, 10);
      const y2 = y1 - RR - 2 - 10*DY - RR - 1; k.wheel(RR, 6, GAP*.85, [0, y2, 0], -.4);
      rows(y2 - RR - 2, 10);
      const yLast = y2 - RR - 2 - 9*DY, yb = yLast - 3, bottom = yb - 2, H = top - bottom + 6, cy = (top + bottom)/2 + 2;
      k.box([W+1, H, .3], [0, cy, -GAP/2-.15], [0,0,0], "back"); k.box([W+1, H, .3], [0, cy, GAP/2+.15], [0,0,0], "glass");
      k.box([.4, H, D], [-W/2-.2, cy, 0], [0,0,0], "wall2"); k.box([.4, H, D], [W/2+.2, cy, 0], [0,0,0], "wall2");
      k.box([W+1, .3, D], [0, top+3.8, 0], [0,0,0], "glass");
      k.box([W, .4, D], [0, yb-1.5, 0], [0,0,0], "tray");
      // les billes au départ : groupées au milieu (8 de front), comme un vrai lâcher
      const cols = 8, starts = [];
      for(let i=0;i<n;i++){ const c = i%cols, rw = Math.floor(i/cols); starts.push([(c - (cols-1)/2)*.95 + (r()-.5)*.04, top + 1 + rw*.95, 0]) }
      return {path:[[0, top, 0], [0, yb-1, 0]], starts, gate:k.box([W, .3, D], [0, top+.4, 0], [0,0,0], "gate"), finishY:yb+1.5, floorY:bottom-2,
        cam:p=>[p[0]*.5, p[1]-1, 23], look:p=>[p[0]*.8, p[1]-3, 0]} }},

  // ---------- (14 octobre 2026) les trampolines ----------
  // Le cirque, le soir : une suite de trampolines rouges sous les projecteurs ; une bille qui rate son saut finit par la piste du dessous
  cirque:{name:"Le Cirque", desc:"Quatre étages de trampolines sous les projecteurs, décalés à gauche et à droite, des boules qui renvoient les billes en l'air… et celles qui ratent leur saut continuent par la piste du dessous !",
    theme:{bg:"#1A0B14", ramp:"#3A2A5E", tray:"#FFD34D", tramp:"#EF3B4F", peg:"#FFD34D"}, form:"trampo", tramp:.62,
    build(k, r, n){ return g3Trampo(k, r, n, {}) }},
  // Les nuages, à midi : des trampolines blancs comme des nuages, en plein ciel
  nuages:{name:"Les Nuages", desc:"Des nuages qui font trampoline en plein ciel, sur quatre étages : les billes sautent de nuage en nuage en zigzag, et gare à celles qui tombent à l'étage du dessous !",
    theme:{bg:"#4A7BC0", ramp:"#9FC3EA", tray:"#FFD34D", tramp:"#FFFFFF", peg:"#FFB547"}, form:"trampo", tramp:.6,
    build(k, r, n){ return g3Trampo(k, r, n, {pas:3.4, dy:.6}) }},
};


function g3World(CANNON, seed, n, cid="lacets"){
  const r = rng(seed), C = G3C[cid] || G3C.lacets;
  const world = new CANNON.World({gravity: new CANNON.Vec3(0, -9.81*(C.g||1), 0)});   // g : un mur penché (Plinko) fait descendre moins vite
  world.allowSleep = false; world.broadphase = new CANNON.SAPBroadphase(world); world.solver.iterations = 14;
  if(C.axis!=null) world.broadphase.axisIndex = C.axis;
  const k = g3Kit(CANNON, world, {tramp:C.tramp, trampF:C.trampF}), T = C.build(k, r, n);
  const balls = T.starts.map(p=>{ const b = new CANNON.Body({mass:1, material:k.M.bille, shape:new CANNON.Sphere(G3.R), linearDamping:.02, angularDamping:.01});
    b.position.set(...p); world.addBody(b); return b });
  // le chemin : longueurs cumulées, pour savoir où en est chaque bille
  const P = T.path, cum = [0]; for(let i=1;i<P.length;i++) cum.push(cum[i-1] + Math.hypot(...v3.sub(P[i], P[i-1])));
  // (14 octobre 2026) les branches (chemins qui se séparent) : leurs longueurs ramenées à celles du chemin principal entre la fourche et le retour
  const segs = [{P, cum}];
  (T.branches||[]).forEach(B=>{ const c = [0]; for(let i=1;i<B.path.length;i++) c.push(c[i-1] + Math.hypot(...v3.sub(B.path[i], B.path[i-1])));
    const s0 = cum[B.from], s1 = cum[B.to], tot = c.at(-1) || 1; segs.push({P:B.path, cum:c.map(x=>s0 + (s1-s0)*x/tot)}) });
  const statics = k.statics.filter(s=>s.kind!=="gate");
  return {world, balls, statics, kin:k.kin, gate:T.gate, finishY:T.finishY, end:P[P.length-1], trayR:T.trayR||10, floorY:T.floorY, path:P, cum, segs, cam:T.cam, look:T.look, C, id:cid in G3C ? cid : "lacets"};
}

function g3Where(W, x, y, z){
  let best = 1e9, s = 0, T = [1,0,0];
  for(const {P, cum} of (W.segs || [{P:W.path, cum:W.cum}])){ const main = P===W.path;
    for(let i=1;i<P.length;i++){ const a = P[i-1], d = v3.sub(P[i], a), L2 = v3.dot(d,d)||1, t = Math.max(0, Math.min(1, v3.dot(v3.sub([x,y,z], a), d)/L2));
      const q = v3.add(a, v3.mul(d, t)), e = Math.hypot(x-q[0], (y-q[1])*1.6, z-q[2]);
      if(e<best){ best = e; s = cum[i-1] + t*(main ? Math.sqrt(L2) : cum[i]-cum[i-1]); T = v3.norm(d) } } }   // (le chemin principal : exactement le calcul d'avant)
  return {s, T};
}

function g3Simulate(CANNON, seed, n, cid){
  const {DT, MAXT} = G3, W = g3World(CANNON, seed, n, cid), frames = [], kf = [], fin = new Array(n).fill(null);
  // les chocs (pour le son) : image -> [force bille contre bille, force contre le décor, bille concernée]
  const hits = new Map(); let curF = 0;
  W.balls.forEach((b,i)=>b.addEventListener("collide", e=>{ const o = e.body, ball = o.mass>0; if(ball && W.balls.indexOf(o)<i) return;
    const v = Math.abs(e.contact.getImpactVelocityAlongNormal()); if(v<.4) return;
    const h = hits.get(curF) || [0,0,i]; if(ball){ if(v>h[0]){ h[0] = v; h[2] = i } } else if(v>h[1]){ h[1] = v; if(!h[0]) h[2] = i } hits.set(curF, h) }));
  let t = 0;
  for(let f=0; f<MAXT/DT; f++){
    curF = f;
    if(t>=3 && W.gate.world) W.world.removeBody(W.gate);   // 3 s de feux, puis la barrière tombe
    W.world.step(DT/2); W.world.step(DT/2); t += DT;
    // une bille qui n'avance plus sur le circuit depuis 4 s (calée, ou coincée dans un tas où elle tremble sur place)
    // reçoit une pichenette dans le sens de la piste, de plus en plus forte si ça ne suffit pas
    if(f%30===0) W.balls.forEach((b,i)=>{ if(fin[i]!=null || t<4) return; const {s, T} = g3Where(W, b.position.x, b.position.y, b.position.z);
      if(b.best==null || s > b.best+.5){ b.best = s; b.bestT = t; b.kicks = 0; return }
      // (14 octobre 2026) patience : plus longue dans les entonnoirs, où une bille qui tourne n'est pas bloquée
      if(t-b.bestT>(W.C.patience||4)){ b.bestT = t; b.kicks = (b.kicks||0)+1; const side = i%2 ? 1 : -1, p = Math.min(2.5, 1+.5*(b.kicks-1));   // plafonnée : une bille ne doit jamais sauter hors de la piste
        // dans le sens de la piste, et sur le côté (sur une piste qui descend tout droit, comme le Plinko, c'est le côté qui débloque)
        const L = Math.hypot(T[0], T[2]) > .3 ? v3.norm([T[2], 0, -T[0]]) : [1, 0, 0];
        b.applyImpulse(new CANNON.Vec3(T[0]*1.2*p + side*L[0]*.8*p, .5, T[2]*1.2*p + side*L[2]*.8*p)) } });
    const fr = new Float32Array(n*7); W.balls.forEach((b,i)=>fr.set([b.position.x,b.position.y,b.position.z,b.quaternion.x,b.quaternion.y,b.quaternion.z,b.quaternion.w], i*7)); frames.push(fr);
    if(W.kin.length){ const kq = new Float32Array(W.kin.length*4); W.kin.forEach((d,i)=>kq.set([d.body.quaternion.x,d.body.quaternion.y,d.body.quaternion.z,d.body.quaternion.w], i*4)); kf.push(kq) }
    // arrivée : sous la ligne, et dans le bac (une bille tombée hors de la piste n'arrive jamais)
    W.balls.forEach((b,i)=>{ if(fin[i]==null && b.position.y < W.finishY && Math.hypot(b.position.x-W.end[0], b.position.z-W.end[2]) < W.trayR) fin[i] = t });
    if(fin.every(x=>x!=null) && t>Math.max(...fin)+2) break;
  }
  fin.forEach((x,i)=>{ if(x==null) fin[i] = 900+i });
  return {W, frames, kf, fin, hits};
}
return {G3C, G3, g3Simulate, g3Where, v3, TAU};
})();
