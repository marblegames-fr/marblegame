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
const glsl3 = rd("maquettes/motifs-3.glsl"), glsl4 = rd("maquettes/motifs-4.glsl"), glsl5 = rd("maquettes/motifs-5.glsl"), glsl6 = rd("maquettes/motifs-6.glsl"), glsl7 = rd("maquettes/motifs-7.glsl");
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
// des petits dessins semés : la place du point dans le repère de sa case (-0,5..0,5), le numéro de la case (id), et s'il y a de la place (on)
vec2 scatP(vec3 u, float sc, float i, out vec3 id, out float on){ vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
  vec3 g=u*sc*0.72+uSeed.xyz*40.0+i*vec3(0.5,0.37,0.61); id=floor(g)+i*17.0; vec3 f=fract(g)-0.5;
  on=step(abs(dot(f,u)),0.36); return vec2(dot(f,t1),dot(f,t2))*0.8; }
float dot2(vec2 v){ return dot(v,v); }
float heartD(vec2 p){ p.x=abs(p.x); if(p.y+p.x>1.0) return sqrt(dot2(p-vec2(0.25,0.75)))-0.3535534;
  return sqrt(min(dot2(p-vec2(0.0,1.0)),dot2(p-0.5*max(p.x+p.y,0.0))))*sign(p.x-p.y); }   // un cœur, la pointe en bas (0,0), le haut vers y=1
float inTri(vec2 p, vec2 a, vec2 b, vec2 c){ float s1=sign((b.x-a.x)*(p.y-a.y)-(b.y-a.y)*(p.x-a.x)), s2=sign((c.x-b.x)*(p.y-b.y)-(c.y-b.y)*(p.x-b.x)), s3=sign((a.x-c.x)*(p.y-c.y)-(a.y-c.y)*(p.x-c.x));
  return step(2.5,abs(s1+s2+s3)); }   // 1 dans le triangle
#endif
#if MODE>=255
vec3 starsE(vec3 q, float th){ vec3 g=q*15.0+uSeed.xyz*40.0; vec3 fc=fract(g)-0.5; return vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0*step(th,length(q)); }   // des étoiles au bord du verre
float lit(vec3 n){ return 0.4+0.7*clamp(dot(n,normalize(vec3(-0.5,0.6,0.6))),0.0,1.0); }
#endif
// les motifs en métal de la 3e partie : la teinte du métal et où il y en a (a)
#if MODE==241
#define HAS_METAL
vec4 metalF(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; vec3 cid; float d2; float d1=vorF(u*2.2+so,cid,d2);
  float inl=max(step(d1,0.09),smoothstep(0.03,0.015,d2-d1)); float sc=0.5+0.5*sin(dot(u,vec3(30.0,12.0,20.0))+6.0*fbm(u*3.0+so));
  float eng=smoothstep(0.7,0.95,sc); vec3 t=vec3(0.92,0.93,0.96)*(1.0-0.45*eng);
  float niel=smoothstep(0.62,0.64,fbm(u*4.0+so+3.0)); return vec4(t, (1.0-inl)*(1.0-niel)); }
#endif
#if MODE==249
#define HAS_METAL
vec4 metalF(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; vec3 g=u*4.0+so; vec3 id=floor(g), f=fract(g)-0.5;
  float cube=step(max(abs(f.x),max(abs(f.y),abs(f.z))),0.25+0.2*h31(id))*step(0.3,h31(id+1.0));
  float m=max(cube,smoothstep(0.5,0.55,fbm(u*2.5+so)));
  vec3 t=mix(vec3(0.95,0.8,0.45),uC3,0.3)*(0.75+0.35*h31(id+2.0)); return vec4(t, m); }
#endif
#if MODE==252
#define HAS_METAL
vec4 metalF(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; float t=dot(u,normalize(vec3(0.3,1.0,0.2)))*0.5+0.5+0.2*(fbm(u*2.0+so)-0.5);
  vec3 c=t<0.5?mix(brt(uC1,0.5),uC2,smoothstep(0.1,0.5,t)):mix(uC2,uC3,smoothstep(0.5,0.9,t));
  c=mix(vec3(0.8),c,0.75)*(0.9+0.1*sin(dot(u,vec3(3.0,1.0,7.0))*120.0)); return vec4(c, 1.0); }
#endif
#if MODE==187
const vec3 TIGRE_AX=vec3(0.28,0.92,0.27);
float tigreV(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; return dot(u,TIGRE_AX)*11.0+2.5*fbm(u*1.5+so); }
#endif
#if MODE==189
vec2 orM(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; vec3 cid; float d2; float d1=vorF(u*4.5+so,cid,d2);
  float m=step(0.42,h31(cid))*smoothstep(0.42,0.5,noise(u*3.0+so)+0.25)*smoothstep(0.01,0.03,d2-d1+0.02*(noise(u*40.0+so)-0.5));
  return vec2(m, step(0.85,h31(cid+3.0))); }
#endif
#if MODE==192
float mercM(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; return smoothstep(0.6,0.62,fbm(u*2.2+so)+0.12*noise(u*8.0+so)); }
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
#elif MODE==187
    { float v=tigreV(qs); vec3 fib=normalize(cross(TIGRE_AX,normalize(qs)));
      float shim=pow(1.0-abs(dot(normalize(rv),fib)),6.0)*(0.6+0.4*sin(fract(v)*3.14159));
      col=base*(0.45+0.6*dif)+base*1.3*shim+mix(base,vec3(1.0),0.5)*shim*0.4+spec*0.6+refl*F*0.2; }
#elif MODE==189
    { vec2 m=orM(qs); vec3 gt=m.y>0.5?mix(vec3(0.85,0.86,0.9),uC2,0.4):mix(vec3(1.0,0.78,0.36),uC3,0.25);
      vec3 met=chrome(rv)*gt*(0.75+0.3*noise(qo*30.0))*(0.7+0.3*n.z)+spec*1.4*gt;
      col=mix(base*(0.4+0.65*dif)+refl*F*0.3+spec*0.8,met,m.x); }
#elif MODE==192
    { float m=mercM(qs); vec3 met=chrome(rv)*mix(vec3(0.92),uC2,0.15)*(0.7+0.3*n.z)+spec*1.6;
      col=mix(base*(0.4+0.65*dif)+refl*F*0.2+spec*0.5,met,m); }
#elif MODE==240
    { vec3 cid; float d2; float d1=vorF(normalize(qs)*3.0+uSeed.xyz*40.0,cid,d2); vec3 fd=normalize(vec3(h31(cid),h31(cid+1.0),h31(cid+2.0))-0.5+0.001);
      float fl=pow(max(0.0,dot(normalize(rv),fd)),5.0); float k=h31(cid+4.0); vec3 fc=k<0.34?brt(uC1,0.5):(k<0.67?uC2:uC3);
      col=base*(0.4+0.6*dif)+fc*fl*1.8+spec*0.7+refl*F*0.25; }
#elif defined(HAS_METAL)
    { vec4 mt=metalF(qs); vec3 met=chrome(rv)*mt.rgb*(0.75+0.25*noise(qo*30.0))*(0.7+0.3*n.z)+spec*1.4*mt.rgb;
      col=mix(base*(0.4+0.65*dif)+refl*F*0.25+spec*0.6,met,mt.a); }
#elif MODE==10
    vec3 nac`);
// les nouveaux blocs, juste avant le motif par défaut (À pois)
patch("#else\n  { // à pois", glsl3 + glsl4 + glsl5 + glsl6 + glsl7 + myth2 + "#else\n  { // à pois");
// plus de pas dans le verre pour les motifs « en scène »
patch("|| MODE==84 || MODE==85\n    const int GSTEPS=64;", "|| MODE==84 || MODE==85 || MODE>=104\n    const int GSTEPS=64;");
// verre de nuit
const NUIT = [108,111,112,113,114,115,116, 140,143,144,145,146,147,148,149, 150,151,152,153,154,155,156, 198, 256,259,264,267,268,269,270,272,273, 276,277,278,279,280,281,282,283,284,285,286,287,288,289,290];
patch("||s.family===85) tint", `||s.family===85||${JSON.stringify(NUIT)}.includes(s.family)) tint`);
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
