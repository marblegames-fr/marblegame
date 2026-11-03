// (3 novembre 2026) les 28 propositions du 20 octobre qui n'avaient pas été gardées, renumérotées 86 à 113 (65 à 85 sont maintenant les motifs du jeu)
#elif MODE==86
  { // triangles : un pavage de triangles, chacun d'une des 3 couleurs (ou blanc), séparés par un fin joint
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.0+nb*0.3)+so.xy;
    vec2 s=vec2(p.x+p.y*0.57735, p.y*1.1547); vec2 id=floor(s), f=fract(s); float up=step(1.0,f.x+f.y);
    float k=h31(vec3(id,up+cf.w*3.0+so.z));
    vec3 c=k<0.3?uC1:(k<0.6?uC2:(k<0.85?uC3:vec3(0.97,0.96,0.93)));
    float ed=min(min(f.x,f.y),abs(1.0-f.x-f.y)*0.7071);
    c*=mix(0.6,1.0,smoothstep(0.015,0.04,ed));
    return vec4(c, 200.0);
  }
#elif MODE==87
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
#elif MODE==88
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
#elif MODE==89
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
#elif MODE==90
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
#elif MODE==91
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
#elif MODE==92
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
#elif MODE==93
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
#elif MODE==94
  { // sable : des couches de sable coloré qui ondulent, comme dans une bouteille de sable des vacances
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float h=u.y*(2.6+nb*0.3)+0.45*fbm(u*1.6+so)+0.12*sin(lon*2.0+so.x);
    float b=floor(h*2.0), fh=fract(h*2.0);
    float m=mod(b,4.0); vec3 c=m<1.0?uC1:(m<2.0?vec3(0.96,0.92,0.84):(m<3.0?uC2:uC3));
    c*=0.82+0.3*noise(u*140.0+so)*noise(u*37.0+so);   // le grain du sable
    c*=mix(0.88,1.0,smoothstep(0.0,0.08,fh));
    return vec4(c, 200.0);
  }
#elif MODE==95
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
#elif MODE==96
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
#elif MODE==97
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
#elif MODE==98
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
#elif MODE==99
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
#elif MODE==100
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
#elif MODE==101
  { // cuivre : du cuivre poli (miroir, au rendu) mangé par endroits par une patine vert-de-gris, avec des taches plus sombres
    vec3 u=normalize(q); float m=cuivreM(q);
    vec3 pat=mix(vec3(0.3,0.66,0.55),uC2,0.4)*(0.75+0.35*noise(u*28.0+so));
    pat=mix(pat,uC1*0.7,smoothstep(0.55,0.75,noise(u*11.0+so+4.0))*0.6);
    vec3 cu=mix(vec3(0.85,0.47,0.27),uC3,0.2);
    return vec4(mix(cu,pat,m), 200.0);
  }
#elif MODE==102
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
#elif MODE==103
  { // météorite : une pallasite, du fer d'étoile filante (miroir, au rendu) gravé de fines lamelles, avec des cristaux colorés pris dedans
    vec3 m=meteo(q);
    vec3 cr=m.z<0.33?uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.4)*0.8:(m.z<0.66?uC2:uC3);
    return vec4(mix(vec3(0.72-0.3*m.y),cr,m.x), 200.0);
  }
#elif MODE==104
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
#elif MODE==105
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
#elif MODE==106
  { // encre : trois gouttes d'encre qui se déploient en volutes dans un verre d'eau claire
    float r=length(q);
    vec3 w=q+0.25*vec3(fbm(q*2.0+so),fbm(q*2.0+so+3.0),fbm(q*2.0+so+6.0));
    float a=smoothstep(0.55,0.75,fbm(w*2.2+so)), b=smoothstep(0.58,0.78,fbm(w*2.4+so+20.0)), c=smoothstep(0.6,0.8,fbm(w*2.6+so+40.0));
    float inside=smoothstep(0.93,0.8,r);
    float s=a+b+c; vec3 col=(uC1*a+uC2*b+uC3*c)/max(s,1e-3);
    e=(uC2*b+uC3*c)*0.15*inside;
    return vec4(s>0.01?col:vec3(0.92,0.96,1.0), 0.12+s*3.5*inside);
  }
#elif MODE==107
  { // holographique : une carte à collectionner holographique, ses arcs de couleur bougent quand on la tourne
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(7.0+nb);
    vec2 f=fract(p)-0.5; float sp=smoothstep(0.03,0.0,abs(sdStar(f*2.4))/2.4)*step(0.6,h31(vec3(floor(p),cf.w)));
    vec3 c=mix(uC1,uC2,0.5+0.5*sin(dot(u,vec3(3.0,5.0,2.0))+so.x));
    return vec4(mix(c,uC3,sp), 200.0);
  }
#elif MODE==108
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
#elif MODE==109
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
#elif MODE==110
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
#elif MODE==111
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
#elif MODE==112
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
#elif MODE==114
  { // volcan : un cône de roche sombre (1re couleur) qui crache sa lave (3e couleur) dans un verre de nuit, panache de cendres (2e couleur)
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6)); e=vec3(0.0);
    vec3 lc=mix(uC3/max(max(uC3.r,max(uC3.g,uC3.b)),0.5),vec3(1.0,0.85,0.5),0.2);
    vec3 p=q-vec3(0.0,-0.58,0.0); float rho=length(p.xz), y=p.y, H=0.5;
    float rr=mix(0.66,0.1,clamp(y/H,0.0,1.0))+0.035*(fbm(q*7.0+so)-0.5);
    if(y>-0.3 && y<H && rho<rr){
      float a=atan(p.z,p.x);
      float riv=smoothstep(0.9,0.97,abs(sin(a*3.0+so.x+2.5*fbm(q*3.0+so))))*smoothstep(H,H*0.2,y)*step(0.0,y);
      float crat=smoothstep(H-0.07,H,y)*smoothstep(0.1,0.05,rho-0.0);
      vec3 rock=mix(vec3(0.1,0.08,0.07),uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.4)*0.5,0.6)*(0.8+0.4*noise(q*30.0+so));
      vec3 nn=normalize(vec3(p.x,rho*0.9,p.z)); float sh=0.4+0.75*clamp(dot(nn,L),0.0,1.0);
      float lav=max(riv,crat);
      e=lc*lav*3.5+lc*0.25*smoothstep(0.0,H,y)*(1.0-lav);
      return vec4(mix(rock*sh,lc,lav), 400.0); }
    // les gerbes de lave au-dessus du cratère
    vec3 top=vec3(0.0,-0.58+H,0.0);
    for(int i=0;i<18;i++){ float fi=float(i);
      float ang=h31(so+fi*1.7)*6.2831, sp=0.08+0.35*h31(so+fi*3.1), t=0.15+0.85*h31(so+fi*5.3);
      vec3 b=top+vec3(cos(ang)*sp*t, 0.8*t-0.55*t*t*(0.5+sp*1.5), sin(ang)*sp*t*0.7);
      float d=length(q-b); float rad=0.018+0.018*h31(so+fi*7.9);
      e+=lc*(exp(-max(d-rad,0.0)*70.0)*6.0+exp(-d*14.0)*0.35);
    }
    e+=lc*(exp(-length(q-top)*12.0)*3.0+exp(-length(q-top)*4.0)*0.6);   // la lueur du cratère
    // le panache de cendres, teinté de la 2e couleur
    float ash=smoothstep(0.5,0.78,fbm(q*2.8+so+vec3(0.0,-1.0,0.0)))*smoothstep(-0.05,0.3,q.y)*smoothstep(0.95,0.7,r);
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0*step(0.6,r)*(1.0-ash);
    return vec4(mix(uC1*0.08,mix(uC2,vec3(0.25),0.45),ash), 0.45+ash*3.0);
  }
#elif MODE==115
  { // phare : une tour rayée (1re couleur et blanc) sur son rocher, la mer (2e couleur), et deux faisceaux de lumière (3e couleur) dans la nuit
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6)); e=vec3(0.0);
    vec3 c1=uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.45), lc=mix(uC3,vec3(1.0,0.97,0.85),0.35);
    // la mer
    float wv=-0.5+0.025*sin(q.x*13.0+so.x)+0.02*sin(q.z*17.0+q.x*5.0+so.y)+0.03*(fbm(q*5.0+so)-0.5);
    if(q.y<wv){ float crest=smoothstep(-0.012,0.0,q.y-wv);
      vec3 w=mix(uC2*0.18,uC2*0.55,0.5+0.5*noise(q*12.0+so)); w=mix(w,vec3(0.9),crest*0.7);
      w+=lc*0.5*exp(-abs(q.x)*6.0)*smoothstep(-0.75,-0.5,q.y)*(0.6+0.4*noise(q*30.0+so));   // le reflet du phare
      return vec4(w, 400.0); }
    // le rocher
    float rk=length((q-vec3(0.0,-0.5,0.0))*vec3(1.0,1.6,1.4))-0.2-0.03*fbm(q*9.0+so);
    if(rk<0.0) return vec4(vec3(0.16,0.14,0.13)*(0.7+0.5*noise(q*25.0+so)), 400.0);
    // la tour
    float y=q.y, rho=length(q.xz), rt=mix(0.1,0.07,clamp((y+0.36)/0.6,0.0,1.0));
    vec3 nn=normalize(vec3(q.x,0.0,q.z)+1e-4); float sh=0.45+0.7*clamp(dot(nn,L),0.0,1.0);
    if(y>-0.4 && y<0.24 && rho<rt){ vec3 c=mod(floor((y+0.36)/0.1),2.0)<1.0?vec3(0.95,0.94,0.9):c1;
      if(q.z>0.0 && abs(q.x)<0.018 && abs(fract((y+0.36)/0.2)-0.5)<0.12) c=vec3(0.15);   // les petites fenêtres
      return vec4(c*sh, 400.0); }
    if(y>0.24 && y<0.265 && rho<0.11) return vec4(vec3(0.12)*sh+c1*0.2, 400.0);   // la galerie
    if(y>0.265 && y<0.36 && rho<0.065){ e=lc*3.0; return vec4(lc, 400.0); }   // la lanterne
    if(y>0.36 && y<0.45 && rho<0.075*(1.0-(y-0.36)/0.09)) return vec4(c1*0.5*sh, 400.0);   // le toit
    // les deux faisceaux
    vec3 Lc=vec3(0.0,0.31,0.0); float ba=0.55+0.6*h31(so+0.4);
    vec3 dir=normalize(vec3(cos(ba),0.06,sin(ba)));
    for(int k=0;k<2;k++){ vec3 d=k==0?dir:vec3(-dir.x,dir.y,-dir.z); vec3 pa=q-Lc; float t=dot(pa,d);
      float w=0.03+t*0.26; float pr=length(pa-d*t);
      e+=lc*step(0.0,t)*exp(-pow(pr/w,2.0))*exp(-t*0.8)*4.0; }
    e+=lc*exp(-length(q-Lc)*14.0)*1.2;
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0*step(0.55,r)*step(-0.3,q.y);
    return vec4(uC1*0.08, 0.45);
  }
#elif MODE==116
  { // sablier : un cadre de bois verni (1re couleur), le sable qui coule (2e couleur), et des grains qui scintillent (3e couleur)
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6)); e=vec3(0.0);
    vec3 c1=uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.45);
    vec3 wood=mix(vec3(0.55,0.33,0.15),c1,0.55);
    float y=q.y, rho=length(q.xz);
    // les deux plateaux et les trois montants
    if(abs(abs(y)-0.49)<0.035 && rho<0.38){ float sh=abs(y)>0.505?(y>0.0?1.05:0.55):0.8;
      return vec4(wood*sh*(0.92+0.08*sin(q.x*40.0+fbm(q*8.0)*4.0)), 400.0); }
    for(int i=0;i<3;i++){ float a=float(i)*2.0944+0.5; vec2 c=vec2(cos(a),sin(a))*0.33;
      float d=length(q.xz-c); if(d<0.025 && abs(y)<0.47){ vec3 nn=normalize(vec3(q.x-c.x,0.0,q.z-c.y)); return vec4(wood*(0.5+0.6*clamp(dot(nn,L),0.0,1.0))*(1.0+0.15*sin(y*80.0)), 400.0); } }
    // le verre : deux bulbes reliés par un col étroit
    float ay=abs(y), rg=0.018+0.26*pow(clamp(ay/0.44,0.0,1.0),0.55)*smoothstep(0.47,0.36,ay)+0.06*smoothstep(0.36,0.45,ay);
    vec3 sc=mix(uC2,vec3(1.0,0.9,0.7),0.12), sp=mix(uC3,vec3(1.0),0.35);
    float gr=step(0.93,h31(floor(q*140.0+so)));
    if(rho<rg && ay<0.45){
      vec3 nn=normalize(vec3(q.x,0.35,q.z)+1e-4); float sh=0.5+0.6*clamp(dot(nn,L),0.0,1.0);
      // en haut : le sable qui reste, creusé en entonnoir
      float st=0.22-0.1*(1.0-rho/max(rg,1e-3));
      if(y>0.04 && y<st){ e=sp*gr*1.5; return vec4(mix(sc*sh,sp,gr*0.6), 400.0); }
      // en bas : le petit tas
      float sb=-0.3+0.1*(1.0-rho/max(rg,1e-3));
      if(y<sb){ e=sp*gr*1.5; return vec4(mix(sc*sh,sp,gr*0.6), 400.0); }
      // le filet de sable
      if(y<0.06 && rho<0.012){ e=sc*0.3; return vec4(sc, 400.0); }
    }
    e+=vec3(0.9,0.95,1.0)*exp(-abs(rho-rg)*160.0)*0.25*step(ay,0.45);   // la paroi du verre qui accroche la lumière
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=sp*step(0.975,h31(floor(g)))*smoothstep(0.2,0.0,length(fc))*3.0*step(0.6,r);   // de la poussière d'or autour
    return vec4(uC1*0.08, 0.45);
  }
