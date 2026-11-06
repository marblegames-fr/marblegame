// Fabrique maquettes/motifs-4-rendu.js : le rendu des billes de la maquette « La grande fournée » (6 novembre 2026),
// à partir de tikalo-demo-rendu.js, avec :
//   - les propositions du 3 novembre (maquettes/motifs-3.glsl, numéros 86 à 116 ; 86, 91, 103, 110 et 112 sont devenus les motifs 86 à 90 du jeu),
//   - les nouveaux motifs (maquettes/motifs-4.glsl, numéros 117 à 149) et deux nouveaux mythiques (155, 156),
//   - les 5 mythiques du 11 octobre pas gardés (maquettes/mythique-2.glsl, 66 à 70 là-bas, renumérotés 150 à 154 ici).
// Le jeu (index.html) n'est pas touché. usage (depuis le dossier du projet) : node maquettes/fabriquer-motifs-4.mjs
import fs from "fs";
const SRC = "maquettes/tikalo-demo-rendu.js", OUT = "maquettes/motifs-4-rendu.js";
const rd = f => fs.readFileSync(f, "utf8").replace(/\r\n/g, "\n").trimEnd() + "\n";
let js = rd(SRC);
const glsl3 = rd("maquettes/motifs-3.glsl"), glsl4 = rd("maquettes/motifs-4.glsl");
// les mythiques du 11 octobre : on garde les blocs 66 à 70 (le 65, l'Œil du Dragon, est déjà le 64 du jeu)
const MY = {66:150, 67:151, 68:152, 69:153, 70:154};
const myth2 = rd("maquettes/mythique-2.glsl").split(/(?=^#elif MODE==)/m)
  .map(b=>{ const m = b.match(/^#elif MODE==(\d+)/); return m && MY[m[1]] ? b.replace(/^#elif MODE==\d+/, "#elif MODE=="+MY[m[1]]) : "" }).join("");
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
// cubeF sert aussi aux nouveaux motifs en grille
patch("#if MODE==68 || MODE==72 || MODE==76 || MODE==77 || MODE==78\n", "#if MODE==68 || MODE==72 || MODE==76 || MODE==77 || MODE==78 || MODE>=86\n");
// les petits outils, juste avant fam()
patch("vec4 fam(vec3 q, out vec3 e){", `#if MODE==101
float cuivreM(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; float n=fbm(u*2.4+so)+0.35*fbm(u*7.0+so+3.0); return smoothstep(0.66,0.72,n); }   // où la patine a pris
#endif
#if MODE==103
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
#if MODE>=117
mat2 mrot(float a){ float c=cos(a), s=sin(a); return mat2(c,s,-s,c); }
float segM(vec2 p, vec2 a, vec2 b){ vec2 pa=p-a, ba=b-a; return length(pa-ba*clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0)); }
vec3 brt(vec3 c, float m){ return c/max(max(c.r,max(c.g,c.b)),m); }   // une couleur du coloris éclaircie (la 1re est souvent presque noire)
// des cellules : la distance au point le plus proche (rendue), au 2e (d2) et le numéro de la cellule (cid)
float vorF(vec3 g, out vec3 cid, out float d2){ vec3 i0=floor(g), f0=fract(g); float d1=9.0; d2=9.0; cid=vec3(0.0);
  for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
    vec3 pt=o+0.15+0.7*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
    if(d<d1){ d2=d1; d1=d; cid=i0+o; } else if(d<d2) d2=d; }
  return d1; }
#endif
#if MODE==135
float damasV(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; vec3 w=u*1.3+so; w+=1.1*vec3(fbm(w),fbm(w+4.0),fbm(w+8.0)); return dot(w,vec3(0.3,1.0,0.2))*6.0; }   // les couches de l'acier damassé
#endif
#if MODE==150
vec4 tesP(vec4 v, float A){
  float c=cos(A), s=sin(A);
  v=vec4(c*v.x-s*v.w, v.y, v.z, s*v.x+c*v.w);
  v=vec4(v.x, c*v.y-s*v.z, s*v.y+c*v.z, v.w);
  float k=1.0/(2.6-v.w);
  vec3 p=v.xyz*k*0.62;
  p=vec3(p.x, 0.94*p.y-0.34*p.z, 0.34*p.y+0.94*p.z);
  p=vec3(0.9*p.x+0.44*p.z, p.y, -0.44*p.x+0.9*p.z);
  return vec4(p, (k-0.278)/0.347);
}
#endif
vec4 fam(vec3 q, out vec3 e){`);
// le rendu à la surface des motifs en métal (Cuivre, Météorite, Damas) et de l'Holographique, juste avant le reflet de nacre
patch("#elif MODE==10\n    vec3 nac", `#elif MODE==101
    { float m=cuivreM(qs); vec3 cu=mix(vec3(0.97,0.56,0.33),uC3,0.2);
      vec3 met=chrome(rv)*cu*(0.92+0.1*noise(qo*35.0))*(0.7+0.3*n.z)+spec*1.4*cu;
      col=mix(met,base*(0.4+0.65*dif)+refl*F*0.1+spec*0.15,m); }
#elif MODE==103
    { vec3 m=meteo(qs);
      vec3 met=chrome(rv)*vec3(0.82-0.4*m.y)*mix(vec3(1.0),uC2,0.12)*(0.7+0.3*n.z)+spec*1.3;
      col=mix(met,base*(0.5+0.6*dif)+base*0.25+refl*F*0.5+spec*0.9,m.x); }
#elif MODE==107
    { float k=fract((1.0-n.z)*1.6+qs.x*0.8+qs.y*0.5)*3.0;
      vec3 hc=k<1.0?mix(uC1,uC2,k):(k<2.0?mix(uC2,uC3,k-1.0):mix(uC3,uC1,k-2.0));
      hc=mix(hc,0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+k*0.5)),0.3);
      col=mix(col,hc*(0.6+0.55*dif)+base*0.25+refl*F*0.5+spec*1.2,0.7); }
#elif MODE==135
    { float v=damasV(qs); float m=mod(floor(v),3.0), b=fract(v);
      vec3 tc=m<1.0?brt(uC1,0.5):(m<2.0?uC2:uC3); tc=mix(vec3(0.85),tc,0.5);
      float ln=smoothstep(0.0,0.18,b)*smoothstep(1.0,0.82,b);
      col=chrome(rv)*tc*(0.5+0.5*ln)*(0.7+0.3*n.z)+spec*1.3*tc; }
#elif MODE==10
    vec3 nac`);
// les nouveaux blocs, juste avant le motif par défaut (À pois)
patch("#else\n  { // à pois", glsl3 + glsl4 + myth2 + "#else\n  { // à pois");
// plus de pas dans le verre pour les motifs « en scène »
patch("|| MODE==84 || MODE==85\n    const int GSTEPS=64;", "|| MODE==84 || MODE==85 || MODE>=104\n    const int GSTEPS=64;");
// verre de nuit
const NUIT = [108,111,112,113,114,115,116, 140,143,144,145,146,147,148,149, 150,151,152,153,154,155,156];
patch("||s.family===85) tint", `||s.family===85||${JSON.stringify(NUIT)}.includes(s.family)) tint`);
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
