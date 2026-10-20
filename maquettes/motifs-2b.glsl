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
  { // tornade : un entonnoir de vent qui tourne sous un nuage d'orage, avec des débris pris dedans
    float r=length(q), y=q.y; float t=clamp((y+0.75)/1.4,0.0,1.0);
    vec2 c=vec2(0.1*sin(y*3.0+so.x),0.08*cos(y*2.5+so.y))*(1.0-t);   // la pointe se balade
    vec2 pxz=q.xz-c; float rho=length(pxz), ang=atan(pxz.y,pxz.x);
    float R=0.04+0.38*pow(t,1.7);
    float sw=0.5+0.5*sin(ang*4.0-y*16.0+fbm(q*4.0+so)*4.0-uTime*3.0);
    float inY=step(y,0.6)*step(-0.78,y);
    float wall=smoothstep(0.04+0.09*t,0.0,abs(rho-R))*inY;
    float cloud=smoothstep(0.42,0.62,y+0.22*fbm(q*3.0+so))*smoothstep(0.96,0.8,r);
    vec3 g=q*12.0+so; vec3 fg=fract(g)-0.5;
    float chips=step(0.9,h31(floor(g)))*smoothstep(0.2,0.1,length(fg))*smoothstep(0.12,0.0,abs(rho-R*1.15))*inY;
    vec3 tc=mix(vec3(0.78,0.78,0.8),uC2,0.4)*(0.55+0.55*sw);
    e=mix(uC3,vec3(1.0),0.4)*exp(-abs(y+0.78)*9.0)*smoothstep(0.55,0.0,rho)*1.4;   // la poussière qui brille au sol
    e+=mix(uC2,vec3(1.0),0.5)*1.0*exp(-abs(rho-R)*25.0)*inY*sw;
    vec3 col=uC1*0.22;
    col=mix(col,mix(uC1*0.5,vec3(0.45),0.4),cloud);
    col=mix(col,tc,clamp(wall*1.5,0.0,1.0));
    col=mix(col,uC1*0.3,chips);
    return vec4(col, 0.4+wall*(1.5+3.0*sw)+cloud*2.5+chips*60.0);
  }
#elif MODE==84
  { // engrenages : trois roues dentées qui s'engrènent au cœur du verre, une de chaque couleur (on les voit tourner en grand)
    float T=uTime*0.5; float d=9.0, k=0.0;
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
      float te=uTime*1.6+float(i)*2.1+so.x; vec2 Pe=vec2(a*cos(te), b*sin(te));
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
    float flick=0.75+0.25*sin(uTime*20.0+fy*30.0);
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
