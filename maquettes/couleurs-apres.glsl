#elif MODE==352
  { // étoilée (après) : le fond de la 1re couleur, les étoiles de la 2e, de la 3e et quelques-unes crème
    vec3 u=normalize(q); vec3 g=u*3.4+so; vec3 id=floor(g), f=fract(g)-0.5;
    vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    float a=h31(id+5.0)*6.2831853; vec2 p=vec2(dot(f,t1),dot(f,t2)); p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
    float sz=0.19+0.11*h31(id+3.0);
    float st=smoothstep(0.015,-0.015,sdStar(p/sz)*sz)*step(0.22,h31(id));
    float k=h31(id+2.0); vec3 sc=k<0.42?brt(uC2,0.55):(k<0.84?uC3:vec3(0.99,0.95,0.8));
    return vec4(mix(uC1,sc,st), 200.0);
  }
#elif MODE==355
  { // vagues (après) : les bandes prennent les 3 couleurs, la crème en fin filet entre elles
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float y=u.y*(4.5+nb)+0.38*sin(lon*(4.0+nb)+so.x);
    float m=mod(floor(y),3.0); vec3 c=m<1.0?uC1:(m<2.0?uC3:uC2);
    c*=mix(0.8,1.0,smoothstep(0.0,0.14,fract(y)));
    c=mix(c,vec3(0.97,0.96,0.93),smoothstep(0.93,0.97,fract(y)));
    return vec4(c, 200.0);
  }
#elif MODE==356
  { // zigzag (après) : 1re, 3e, 2e couleur et un rang crème
    vec3 u=normalize(q); float s=atan(u.z,u.x)/6.2831853*(8.0+nb*2.0);
    float zz=abs(fract(s)-0.5)*2.0;
    float y=u.y*(3.5+nb*0.5)+zz*0.6;
    float m=mod(floor(y),4.0); vec3 c=m<1.0?uC1:(m<2.0?uC3:(m<3.0?uC2:vec3(0.97,0.95,0.9)));
    c*=mix(0.82,1.0,smoothstep(0.0,0.1,fract(y)));
    return vec4(c, 200.0);
  }
#elif MODE==357
  { // tricot (après) : des rangs des 3 couleurs (et un rang crème), comme un pull jacquard
    vec3 u=normalize(q); vec2 s=sph(u); float n=16.0+nb*2.0;
    vec2 p=vec2(s.x*n, s.y*n*0.62); vec2 id=floor(p), f=fract(p)-0.5;
    vec2 g=vec2(abs(f.x)-0.23, f.y+abs(f.x)*0.85-0.1);
    float leg=length(g*vec2(1.9,1.0))-0.3;
    float sh=smoothstep(0.1,-0.06,leg);
    float row=mod(id.y+floor(so.x),8.0);
    vec3 yarn=row<3.0?uC1:(row<5.0?uC2:(row<7.0?uC3:vec3(0.96,0.94,0.9)));
    vec3 c=yarn*(0.4+0.65*sh)*(0.9+0.18*noise(vec3(p*7.0,so.x)));
    return vec4(c, 200.0);
  }
#elif MODE==358
  { // nuages (après) : un ciel qui passe de la 1re couleur (en bas) à la 2e (en haut), des nuages teintés de la 3e
    vec3 u=normalize(q); float n=fbm(u*vec3(2.0,3.4,2.0)+so)+0.3*fbm(u*6.0+so+3.0);
    float cl=smoothstep(0.6,0.68,n);
    vec3 sky=mix(uC1,brt(uC2,0.5),smoothstep(-0.7,0.8,u.y));
    vec3 cloud=mix(mix(uC3,vec3(1.0),0.35)*0.82,vec3(1.0),smoothstep(0.64,0.86,n));
    return vec4(mix(sky,cloud,cl), 200.0);
  }
#elif MODE==360
  { // jean (après) : la toile de la 1re couleur, délavée vers la 2e, la double couture au fil de la 3e
    vec3 u=normalize(q); vec2 s=sph(u);
    float tw2=fract((s.x*2.0+s.y)*55.0);
    float fade=smoothstep(0.45,0.75,fbm(u*2.0+so));
    vec3 den=mix(uC1*0.45,mix(uC1,vec3(0.9),0.25),smoothstep(0.35,0.65,tw2));
    den=mix(den,mix(uC2,vec3(0.92,0.94,0.97),0.35),fade*0.7);
    den*=0.88+0.22*noise(u*70.0+so);
    float y=u.y+0.04*sin(atan(u.z,u.x)*2.0+so.x);
    den=mix(den,den*0.7,smoothstep(0.065,0.04,abs(y)));
    float lon=atan(u.z,u.x)/6.2831853*80.0;
    float stitch=step(0.4,fract(lon))*smoothstep(0.02,0.01,abs(abs(y)-0.085));
    return vec4(mix(den,mix(brt(uC3,0.6),vec3(0.93,0.64,0.24),0.2),stitch), 200.0);
  }
#elif MODE==362
  { // circuit (après) : la carte de la 1re couleur (sombre), les pistes de la 2e, les pastilles de la 3e
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
    vec3 board=mix(vec3(0.03,0.06,0.07),uC1*0.45,0.7)*(0.85+0.2*noise(u*40.0+so));
    vec3 lc=mix(uC2,vec3(1.0),0.2), pc=mix(uC3,vec3(1.0),0.15);
    e=(lc*(tr*(0.5+2.5*pulse))*(1.0-pad)+pc*pad*1.1*(1.0-hole)+lc*smoothstep(0.32,0.0,dd)*0.2)*1.2;
    vec3 c=mix(board,mix(uC2,vec3(0.85,0.75,0.4),0.2),tr*(1.0-pad));
    c=mix(c,pc,pad*(1.0-hole));
    return vec4(c, 200.0);
  }
#elif MODE==415 || MODE==515
  { // plasma (après) : la même boule plasma, mais la lumière ne « brûle » plus les couleurs.
    // A (415) : moins de lumière (les éclairs gardent leur teinte au lieu de partir au jaune-blanc), la 1re couleur moins éclaircie.
    // B (515) : pareil, et chaque couleur est poussée un peu loin des deux autres (plus saturée), pour les coloris d'une seule teinte (Miel, Citron, Glacier…)
    float t=mod(uTime,3.9269908), lp=t*1.6;
    float rr=length(q)+1e-4; vec3 u=q/rr;
    vec3 E=vec3(0.0); float jit=noise(q*16.0+so)-0.5;
    vec3 k1=brt(uC1,0.45), k2=uC2, k3=uC3;
#if MODE==515
    { vec3 L=vec3(0.299,0.587,0.114); float l1=dot(k1,L), l2=dot(k2,L), l3=dot(k3,L);
      k1=clamp(mix(vec3(l1),k1,1.7),0.0,1.0); k2=clamp(mix(vec3(l2),k2,1.5),0.0,1.0); k3=clamp(mix(vec3(l3),k3,1.9),0.0,1.0)*0.9; }
#endif
    for(int i=0;i<9;i++){
      float fi=float(i);
      float b=fi*2.3999632+0.45*sin(lp+fi*1.7);
      float z=(fract(fi*0.618+so.x*0.01)-0.5)*1.4+0.25*sin(lp+fi*2.9);
      vec3 wg=vec3(sin(rr*7.0+fi*2.0+lp),cos(rr*9.0+fi*3.0-lp),sin(rr*8.0+fi*5.0+lp*2.0))*0.22*rr;
      vec3 dir=normalize(vec3(cos(b),sin(b),z)+wg+jit*0.12*rr);
      float d=length(u-dir)*rr;
      float wd=0.013+0.02*(1.0-rr);
      float fl=0.7+0.3*sin(lp*2.0+fi*1.7);
      float kc=mod(fi,3.0); vec3 fc=kc<1.0?k1:(kc<2.0?k2:k3);
      vec3 col=mix(mix(fc,vec3(1.0),0.5),fc*1.15,smoothstep(0.12,0.3,rr));
      vec3 a=col*exp(-d*d/(wd*wd))*6.0+fc*exp(-d*d/(wd*wd*6.0))*2.5+fc*exp(-d*12.0)*0.6;
      { float m=max(a.r,max(a.g,a.b)); a*=min(m,3.0)/max(m,1e-4); }   // trop fort : on baisse tout l'éclair d'un coup (sa teinte ne bouge pas) au lieu de laisser chaque canal partir au blanc
      E+=a*fl*smoothstep(0.08,0.16,rr)*smoothstep(0.97,0.86,rr);
      vec3 ud=u-dir; E+=mix(fc,vec3(1.0),0.25)*exp(-pow((rr-0.86)/0.035,2.0))*exp(-dot(ud,ud)/0.004)*4.0*fl;
    }
    E+=mix(k3,vec3(1.0),0.45)*exp(-rr*rr/0.01)*9.0 + k2*exp(-rr*5.0)*1.2 + k1*smoothstep(0.55,0.95,rr)*0.35;
    { float m=max(E.r,max(E.g,E.b)); E*=min(m,3.2)/max(m,1e-4); }   // la somme aussi, sans changer sa teinte
    e=E;
    return vec4(uC1*0.12,0.5);
  }
