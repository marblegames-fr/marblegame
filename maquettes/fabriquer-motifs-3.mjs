// Fabrique maquettes/motifs-3-rendu.js : le rendu des billes de la maquette (tikalo-demo-rendu.js)
// avec, en plus, les propositions de la maquette « Motifs en plus 2 » (maquettes/motifs-3.glsl, numéros 86 à 116).
// Le jeu (index.html) n'est pas touché. usage (depuis le dossier du projet) : node maquettes/fabriquer-motifs-3.mjs
import fs from "fs";
const SRC = "maquettes/tikalo-demo-rendu.js", OUT = "maquettes/motifs-3-rendu.js";
let js = fs.readFileSync(SRC, "utf8").replace(/\r\n/g, "\n");
const glsl = fs.readFileSync("maquettes/motifs-3.glsl", "utf8").replace(/\r\n/g, "\n").trimEnd() + "\n";
const patch = (a, b) => { if(js.split(a).length !== 2) throw new Error("repère introuvable ou en double : " + a.slice(0, 60)); js = js.replace(a, b) };
// cubeF sert aussi aux nouveaux motifs en grille
patch("#if MODE==68 || MODE==72 || MODE==76 || MODE==77 || MODE==78\n", "#if MODE==68 || MODE==72 || MODE==76 || MODE==77 || MODE==78 || MODE>=86\n");
// les petits outils du Cuivre (101) et de la Météorite (103), juste avant fam()
patch("vec4 fam(vec3 q, out vec3 e){", `#if MODE==101
float cuivreM(vec3 q){ vec3 u=normalize(q), so=uSeed.xyz*40.0; float n=fbm(u*2.4+so)+0.35*fbm(u*7.0+so+3.0); return smoothstep(0.66,0.72,n); }   // où la patine a pris
#endif
#if MODE==103
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
vec4 fam(vec3 q, out vec3 e){`);
// le rendu à la surface des motifs en métal (Cuivre, Météorite) et de l'Holographique, juste avant le reflet de nacre
patch("#elif MODE==10\n    vec3 nac", `#elif MODE==101
    { float m=cuivreM(qs); vec3 cu=mix(vec3(0.97,0.56,0.33),uC3,0.2);
      vec3 met=chrome(rv)*cu*(0.92+0.1*noise(qo*35.0))*(0.7+0.3*n.z)+spec*1.4*cu;
      col=mix(met,base*(0.4+0.65*dif)+refl*F*0.1+spec*0.15,m); }
#elif MODE==103
    { vec3 m=meteo(qs);
      vec3 met=chrome(rv)*vec3(0.82-0.4*m.y)*mix(vec3(1.0),uC2,0.12)*(0.7+0.3*n.z)+spec*1.3;
      col=mix(met,base*(0.5+0.6*dif)+base*0.25+refl*F*0.5+spec*0.9,m.x); }
#elif MODE==107
    { float k=fract((1.0-n.z)*1.6+qs.x*0.8+qs.y*0.5)*3.0;   // l'arc de couleurs glisse avec l'angle : les 3 couleurs du coloris, et un peu d'arc-en-ciel
      vec3 hc=k<1.0?mix(uC1,uC2,k):(k<2.0?mix(uC2,uC3,k-1.0):mix(uC3,uC1,k-2.0));
      hc=mix(hc,0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+k*0.5)),0.3);
      col=mix(col,hc*(0.6+0.55*dif)+base*0.25+refl*F*0.5+spec*1.2,0.7); }
#elif MODE==10
    vec3 nac`);
// les nouveaux blocs, juste avant le motif par défaut (À pois)
patch("#else\n  { // à pois", glsl + "#else\n  { // à pois");
// plus de pas dans le verre pour les motifs « en scène »
patch("|| MODE==84 || MODE==85\n    const int GSTEPS=64;", "|| MODE==84 || MODE==85 || MODE>=104\n    const int GSTEPS=64;");
// verre de nuit : Lune, Fusée, Atome, Éclipse, Volcan, Phare, Sablier
patch("||s.family===85) tint", "||s.family===85||[108,111,112,113,114,115,116].includes(s.family)) tint");
fs.writeFileSync(OUT, js);
console.log(OUT + " : " + Math.round(js.length / 1024) + " Ko");
