#if MODE>=130
// Maquette du 20 novembre 2026 : un bonbon différent par coloris de l'event « Pluie de bonbons ! » (familles 130 à 134,
// à ranger dans la famille 116 avec un #define BONBON par coloris si on l'intègre, comme les héros)
//  130 : Menthe   — un sapin de Noël en sucre vert, la neige sur ses branches, ses boules et une petite étoile blanche
//  131 : Fraise   — une canne de Noël en sucre d'orge, rayée en spirale
//  132 : Citron   — l'étoile du haut du sapin, taillée en facettes, qui rayonne dans le verre
//  133 : Myrtille — un bonhomme de neige en guimauves empilées, son écharpe et son chapeau
//  134 : Caramel  — un bonhomme en pain d'épices, son glaçage blanc et ses boutons en bonbon
float bbMin(float a, float b, float k){ float h=clamp(0.5+0.5*(b-a)/k,0.0,1.0); return mix(b,a,h)-k*h*(1.0-h); }
float bbCap(vec3 p, vec3 a, vec3 b, float r){ vec3 pa=p-a, ba=b-a; float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0); return length(pa-ba*h)-r; }
float bbEll(vec3 p, vec3 r){ return (length(p/r)-1.0)*min(r.x,min(r.y,r.z)); }
// la bille chinoise se regarde par le dessus : le bonbon y est couché à plat (comme le bonbon du jeu)
vec3 bbP(vec3 q){ return uAsp>1.2 ? vec3(q.x,-q.z,q.y) : q; }
// des grains de sucre collés au bonbon
float bbSucre(vec3 p, float sc){ vec3 g=p*sc+uSeed.xyz*40.0; vec3 f=fract(g)-0.5; return step(0.62,h31(floor(g)))*smoothstep(0.34,0.12,length(f)); }
// la lumière du bonbon (la même que celle du bonbon du jeu)
vec3 bbLum(vec3 c, vec3 n, float sh, float ks){ vec3 L=normalize(vec3(-0.5,0.62,0.6));
  float dif=max(dot(n,L),0.0), sp=pow(max(dot(n,normalize(L+vec3(0.0,0.0,1.0))),0.0),sh);
  return c*(0.35+0.8*dif)+vec3(sp*ks); }
// le verre autour : teinté de la 1re couleur, avec des grains de sucre qui scintillent (de la 3e)
vec4 bbVerre(vec3 q, out vec3 e){ float rr=length(q);
  vec3 glass=mix(uC1,vec3(1.0),0.2)*(0.75+0.2*smoothstep(0.95,0.2,rr));
  vec3 g=q*14.0+uSeed.xyz*40.0; vec3 fc=fract(g)-0.5;
  float sug=step(0.9,h31(floor(g)))*smoothstep(0.12,0.03,length(fc))*smoothstep(0.95,0.8,rr);
  e=mix(uC3,vec3(1.0),0.6)*sug*1.6;
  return vec4(glass, 0.18+sug*20.0); }

#if MODE==130 || MODE==132
// une étoile à 5 branches à plat (rayon r, creux rf), distance signée (d'après Inigo Quilez)
float bbEt5(vec2 p, float r, float rf){ const vec2 k1=vec2(0.809016994375,-0.587785252292); const vec2 k2=vec2(-0.809016994375,-0.587785252292);
  p.x=abs(p.x); p-=2.0*max(dot(k1,p),0.0)*k1; p-=2.0*max(dot(k2,p),0.0)*k2; p.x=abs(p.x); p.y-=r;
  vec2 ba=rf*vec2(-k1.y,k1.x)-vec2(0.0,1.0); float h=clamp(dot(p,ba)/dot(ba,ba),0.0,r);
  return length(p-ba*h)*sign(p.y*ba.x-p.x*ba.y); }
// l'étoile en relief : chaque branche a son arête, comme une étoile taillée (10 facettes de chaque côté)
float bbEtoile(vec3 p, float r){ float d2=bbEt5(p.xy,r,0.45); return max(d2, (abs(p.z)-0.012-0.55*max(-d2,0.0))*0.85); }
#endif
#if MODE==130
// les 3 étages du sapin : des cônes aux bords festonnés
float bbEtage(vec3 p, float yb, float yt, float R){ float rr=length(p.xz), a=atan(p.z,p.x);
  float rad=R*(yt-p.y)/(yt-yb)*(1.0+0.07*sin(a*9.0+yb*20.0)*smoothstep(yb+0.12,yb,p.y));
  return max(rr-rad, max(yb-p.y, p.y-yt))*0.7; }
float bbSBranches(vec3 p){ return min(bbEtage(p,-0.26,0.06,0.31), min(bbEtage(p,-0.09,0.22,0.245), bbEtage(p,0.07,0.36,0.175))); }
float bbSTronc(vec3 p){ return max(length(p.xz)-0.06, abs(p.y+0.32)-0.07); }
float bbSEtoile(vec3 p){ return bbEtoile(p-vec3(0.0,0.4,0.0), 0.075); }
// les boules, posées au bout des branches de chaque étage
vec3 bbBoule(int i){ float fi=float(i); float y = i<3 ? -0.2 : (i<6 ? -0.03 : 0.13); float R = i<3 ? 0.31 : (i<6 ? 0.245 : 0.175);
  float yb = i<3 ? -0.26 : (i<6 ? -0.09 : 0.07), yt = i<3 ? 0.06 : (i<6 ? 0.22 : 0.36);
  float a=fi*2.4+0.6; float rad=R*(yt-y)/(yt-yb)+0.01; return vec3(cos(a)*rad, y-0.015, sin(a)*rad); }
float bbSBoules(vec3 p, out float id){ float d=1.0; id=0.0;
  for(int i=0;i<8;i++){ float di=length(p-bbBoule(i))-0.034; if(di<d){ d=di; id=float(i); } } return d; }
float SD(vec3 p){ float id; return min(min(bbSBranches(p), bbSTronc(p)), min(bbSEtoile(p), bbSBoules(p,id))); }
#elif MODE==131
const vec2 CA=vec2(0.12,-0.44), CB=vec2(0.12,0.1), CC=vec2(-0.035,0.1), CE=vec2(-0.19,-0.02); const float CR=0.155, CT=0.074;
float SD(vec3 p){
  float d1=bbCap(p, vec3(CA,0.0), vec3(CB,0.0), CT);
  vec2 t=p.xy-CC; float dT = t.y>=0.0 ? length(vec2(length(t)-CR, p.z))-CT : 1.0;
  float d3=bbCap(p, vec3(CC.x-CR,CC.y,0.0), vec3(CE,0.0), CT);
  return min(d1,min(dT,d3)); }
#elif MODE==132
float SD(vec3 p){ return bbEtoile(p, 0.44); }
#elif MODE==133
// une guimauve : un cylindre aux bords bien arrondis
float bbGuim(vec3 p, float cy, float r, float h){ const float rb=0.05; vec2 d=vec2(length(p.xz)-r+rb, abs(p.y-cy)-h+rb);
  return min(max(d.x,d.y),0.0)+length(max(d,0.0))-rb; }
float bbNCorps(vec3 p){ return bbMin(bbMin(bbGuim(p,-0.28,0.2,0.1), bbGuim(p,-0.07,0.165,0.09), 0.025), bbGuim(p,0.115,0.13,0.085), 0.02); }
float bbNEcharpe(vec3 p){ vec3 t=p-vec3(0.0,0.03,0.0); float d=length(vec2(length(t.xz)-0.14, t.y))-0.032;
  return min(d, bbCap(p, vec3(0.09,0.02,0.11), vec3(0.13,-0.12,0.15), 0.03)); }
float bbNChapeau(vec3 p){ vec2 b=vec2(length(p.xz)-0.145, abs(p.y-0.205)-0.012); vec2 c=vec2(length(p.xz)-0.085, abs(p.y-0.28)-0.075);
  return min(min(max(b.x,b.y),0.0)+length(max(b,0.0)), min(max(c.x,c.y),0.0)+length(max(c,0.0))); }
float bbNNez(vec3 p){ return bbCap(p, vec3(0.0,0.11,0.12), vec3(0.0,0.1,0.21), 0.016); }
float SD(vec3 p){ return min(min(bbNCorps(p), bbNEcharpe(p)), min(bbNChapeau(p), bbNNez(p))); }
#elif MODE==134
// le bonhomme en pain d'épices, à plat : la tête, le corps, les bras et les jambes
float bbPE2(vec2 p){ vec2 m=vec2(abs(p.x),p.y);
  float d=length(p-vec2(0.0,0.24))-0.115;
  d=bbMin(d, segM(p,vec2(0.0,0.12),vec2(0.0,-0.08))-0.125, 0.04);
  d=bbMin(d, segM(m,vec2(0.05,0.08),vec2(0.25,0.02))-0.062, 0.04);
  d=bbMin(d, segM(m,vec2(0.04,-0.1),vec2(0.14,-0.33))-0.072, 0.04);
  return d; }
const vec3 PB0=vec3(0.0,0.12,0.045), PB1=vec3(0.0,0.03,0.05), PB2=vec3(0.0,-0.06,0.045);
float bbPEBoutons(vec3 p, out float id){ float d0=length(p-PB0)-0.026, d1=length(p-PB1)-0.026, d2=length(p-PB2)-0.026;
  id = d1<min(d0,d2) ? 1.0 : 0.0; return min(d0,min(d1,d2)); }
float bbPECorps(vec3 p){ const float rb=0.028; vec2 w=vec2(bbPE2(p.xy)+rb, abs(p.z)-0.05+rb); return min(max(w.x,w.y),0.0)+length(max(w,0.0))-rb; }
float SD(vec3 p){ float id; return min(bbPECorps(p), bbPEBoutons(p,id)); }
#endif
vec3 bbN(vec3 p){ const vec2 k=vec2(1.0,-1.0); const float h=0.002;
  return normalize(k.xyy*SD(p+k.xyy*h)+k.yyx*SD(p+k.yyx*h)+k.yxy*SD(p+k.yxy*h)+k.xxx*SD(p+k.xxx*h)); }
#endif
//@@FAM
#elif MODE==130
  { // sapin : un sapin de Noël en sucre (2e couleur), la neige sur les bords de ses branches (3e), ses boules rouges et or,
    // une petite étoile blanche en haut, dans un verre teinté de la 1re
    vec3 p=bbP(q)*0.92; p.y+=0.02;
    if(SD(p)<0.0){
      vec3 n=bbN(p); float id; float db=bbSBranches(p), dt=bbSTronc(p), de=bbSEtoile(p), dl=bbSBoules(p,id);
      float m=min(min(db,dt),min(de,dl));
      if(m==dl){ vec3 bc = mod(id,2.0)<0.5 ? vec3(0.86,0.12,0.18) : vec3(0.98,0.74,0.2);
        return vec4(bbLum(bc,n,90.0,1.6), 300.0); }
      if(m==de) return vec4(bbLum(mix(uC3,vec3(1.0),0.5)*1.1,n,60.0,1.2), 300.0);
      if(m==dt) return vec4(bbLum(vec3(0.42,0.25,0.14),n,20.0,0.2), 300.0);
      // les aiguilles : de petites stries ; la neige sur le bord de chaque étage et sur ce qui regarde le ciel
      float a=atan(p.z,p.x); float ai=0.88+0.12*sin(a*40.0+p.y*90.0);
      vec3 c=brt(uC2,0.6)*ai*(0.85+0.25*smoothstep(-0.25,0.35,p.y));
      // la neige : une bande sur le bord de chaque étage, et ce qui regarde le ciel ; le dessous des étages reste dans l'ombre
      float bord=max(smoothstep(-0.215,-0.24,p.y), max(smoothstep(-0.045,-0.07,p.y)*step(-0.09,p.y), smoothstep(0.115,0.09,p.y)*step(0.07,p.y)));
      float nei=clamp(bord*(0.55+0.45*noise(p*30.0+uSeed.xyz*40.0))+smoothstep(0.8,0.97,n.y)*0.8,0.0,1.0)*step(-0.4,n.y);
      c=mix(c, mix(uC3,vec3(1.0),0.4), smoothstep(0.45,0.6,nei));
      if(n.y<-0.4) c=brt(uC2,0.6)*0.45;
      return vec4(bbLum(c,n,30.0,0.4), 300.0);
    }
    return bbVerre(q,e);
  }
#elif MODE==131
  { // canne : une canne de Noël en sucre d'orge, blanche (3e couleur) rayée en spirale de la 2e, avec un fin liseré pâle (vers la 1re)
    vec3 p=bbP(q); p.xy=mat2(0.95,0.31,-0.31,0.95)*p.xy;
    if(SD(p)<0.0){
      vec3 n=bbN(p);
      float d1=bbCap(p, vec3(CA,0.0), vec3(CB,0.0), CT); vec2 t=p.xy-CC;
      float dT = t.y>=0.0 ? length(vec2(length(t)-CR, p.z))-CT : 1.0;
      float s, th, L0=CB.y-CA.y;
      if(d1<=dT && d1<1.0 && p.y<CB.y+0.01){ s=p.y-CA.y; th=atan(p.z, p.x-CA.x); }
      else if(t.y>=0.0){ float ph=atan(t.y,t.x); s=L0+ph*CR; th=atan(p.z, length(t)-CR); }
      else { s=L0+3.14159*CR+(CC.y-p.y); th=atan(p.z, -(p.x-CE.x)); }
      float v=fract(s*4.2-th/6.2832);
      vec3 c=uC3;
      c=mix(c, uC2, smoothstep(0.02,0.0,abs(v-0.18)-0.13));                 // la grosse rayure
      c=mix(c, mix(uC1,uC2,0.45), smoothstep(0.012,0.0,abs(v-0.58)-0.035)); // le liseré
      c=mix(c, uC2, smoothstep(0.012,0.0,abs(v-0.72)-0.03));                // la fine rayure
      return vec4(bbLum(c,n,80.0,1.3), 300.0);
    }
    return bbVerre(q,e);
  }
#elif MODE==132
  { // étoile : l'étoile du haut du sapin (2e couleur), taillée en facettes, qui rayonne dans le verre en rayons de la 3e
    vec3 p=bbP(q); p.xy=mat2(0.98,0.2,-0.2,0.98)*p.xy; p.xz=mat2(0.96,0.28,-0.28,0.96)*p.xz;
    if(SD(p)<0.0){
      vec3 n=bbN(p);
      vec3 c=brt(uC2,0.85);
      return vec4(bbLum(c,n,70.0,1.5)+c*0.12, 300.0);
    }
    // les rayons de lumière : de fins traits de la 3e couleur qui partent de l'étoile, dans le plan de l'étoile
    vec4 v=bbVerre(q,e);
    float rr=length(p.xy), an=atan(p.y,p.x);
    float ray=pow(abs(cos(an*5.0+0.0)),24.0)+0.6*pow(abs(cos(an*5.0+1.5708)),60.0);
    float pl=smoothstep(0.06,0.0,abs(p.z));
    e+=mix(uC3,uC2,0.3)*ray*pl*smoothstep(0.92,0.45,rr)*smoothstep(0.4,0.5,rr)*3.0;
    e+=mix(uC2,uC3,0.5)*pl*smoothstep(0.75,0.42,rr)*0.6;   // un halo autour
    return v;
  }
#elif MODE==133
  { // bonhomme de neige : trois guimauves empilées, poudrées (3e couleur), l'écharpe rayée et le chapeau (2e), un nez de carotte,
    // dans un verre teinté de la 1re
    vec3 p=bbP(q); p.xz=mat2(0.995,-0.1,0.1,0.995)*p.xz; p.y+=0.02;
    if(SD(p)<0.0){
      vec3 n=bbN(p); float dc=bbNCorps(p), de=bbNEcharpe(p), dh=bbNChapeau(p), dn=bbNNez(p);
      float m=min(min(dc,de),min(dh,dn));
      if(m==dn) return vec4(bbLum(vec3(1.0,0.5,0.12),n,30.0,0.4), 300.0);
      if(m==dh){ vec3 c=brt(uC2,0.6)*0.45; c=mix(c, brt(uC2,0.6), step(abs(p.y-0.235),0.018)*step(0.17,p.y));   // le ruban du chapeau
        return vec4(bbLum(c,n,40.0,0.6), 300.0); }
      if(m==de){ float st=step(0.5,fract((p.y+atan(p.z,p.x)*0.05)*28.0));
        vec3 c=mix(brt(uC2,0.6), mix(uC3,vec3(1.0),0.3), st*0.85);
        return vec4(bbLum(c,n,12.0,0.15)*(0.92+0.08*noise(p*120.0)), 300.0); }
      // la guimauve, mate et poudrée ; les yeux et les boutons en chocolat
      vec3 c=mix(uC3,vec3(1.0),0.35)*(0.93+0.07*noise(p*90.0+uSeed.xyz*40.0));
      vec2 ey=vec2(abs(p.x)-0.048, p.y-0.145); if(p.z>0.04 && length(ey)<0.02) c=vec3(0.16,0.1,0.08);
      if(p.z>0.1 && abs(p.x)<0.022 && (abs(p.y+0.04)<0.022 || abs(p.y+0.11)<0.022 || abs(p.y+0.24)<0.022)) c=vec3(0.18,0.11,0.08);
      return vec4(bbLum(c,n,8.0,0.12)+c*0.12, 300.0);
    }
    return bbVerre(q,e);
  }
#elif MODE==134
  { // pain d'épices : un bonhomme en pain d'épices doré (2e couleur), son glaçage blanc (3e), ses boutons en bonbon rouge et vert
    vec3 p=bbP(q)*0.95; p.xy=mat2(0.97,0.24,-0.24,0.97)*p.xy; p.xz=mat2(0.96,0.28,-0.28,0.96)*p.xz;
    if(SD(p)<0.0){
      vec3 n=bbN(p); float id; float db=bbPEBoutons(p,id), dc=bbPECorps(p);
      if(db<dc){ vec3 bc = id>0.5 ? vec3(0.15,0.62,0.3) : vec3(0.86,0.12,0.18); return vec4(bbLum(bc,n,90.0,1.6), 300.0); }
      float d2=bbPE2(p.xy);
      vec3 c=brt(uC2,0.72)*(0.85+0.2*noise(p*40.0+uSeed.xyz*40.0));
      c*=0.75+0.25*smoothstep(0.0,-0.05,d2);   // le bord plus cuit
      // le glaçage, sur le devant : les yeux, le sourire, des vagues au bout des bras et des jambes
      float ice=0.0; vec2 m=vec2(abs(p.x),p.y);
      ice=max(ice, step(length(m-vec2(0.042,0.265)),0.017));
      vec2 sm=p.xy-vec2(0.0,0.255); float sr=length(sm);
      ice=max(ice, step(abs(sr-0.055),0.008)*step(sm.y,-0.02));
      vec2 ar=m-vec2(0.2,0.035); float al=dot(ar,normalize(vec2(-0.29,-1.0)));
      ice=max(ice, step(abs(dot(ar,normalize(vec2(1.0,-0.29)))+0.012*sin(al*90.0)),0.009)*step(abs(al),0.06));
      vec2 lg=m-vec2(0.115,-0.27); float ll=dot(lg,normalize(vec2(0.92,-0.4)));
      ice=max(ice, step(abs(dot(lg,normalize(vec2(0.4,0.92)))+0.012*sin(ll*90.0)),0.009)*step(abs(ll),0.07));
      ice*=step(0.02,p.z);
      c=mix(c, mix(uC3,vec3(1.0),0.5)*1.1, ice);
      return vec4(bbLum(c,n,20.0+40.0*ice,0.2+0.6*ice), 300.0);
    }
    return bbVerre(q,e);
  }
