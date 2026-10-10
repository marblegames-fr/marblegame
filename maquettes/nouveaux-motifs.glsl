#elif MODE==52
  { // étoilée : de petites étoiles à cinq branches semées sur toute la bille
    vec3 u=normalize(q); vec3 g=u*3.4+so; vec3 id=floor(g), f=fract(g)-0.5;
    vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    float a=h31(id+5.0)*6.2831853; vec2 p=vec2(dot(f,t1),dot(f,t2)); p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
    float sz=0.19+0.11*h31(id+3.0);
    float st=smoothstep(0.015,-0.015,sdStar(p/sz)*sz)*step(0.22,h31(id));
    vec3 sc=h31(id+2.0)<0.6?vec3(0.99,0.95,0.8):uC3;
    return vec4(mix(uC1,sc,st), 200.0);
  }
#elif MODE==53
  { // cœurs : de petits cœurs de toutes les tailles sur un fond clair
    vec3 u=normalize(q); vec3 g=u*2.6+so; vec3 id=floor(g), f=fract(g)-0.5;
    vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    float a=(h31(id+5.0)-0.5)*1.2; vec2 p=vec2(dot(f,t1),dot(f,t2)); p=vec2(cos(a)*p.x-sin(a)*p.y, sin(a)*p.x+cos(a)*p.y);
    float sz=0.27+0.08*h31(id+3.0);
    float hc=smoothstep(0.015,-0.015,sdHeart(vec2(p.x,-p.y)/sz)*sz)*step(0.12,h31(id));
    vec3 bg=mix(uC3,vec3(0.99,0.97,0.96),0.7);
    vec3 hcol=h31(id+2.0)<0.65?uC1:uC2*0.85;
    return vec4(mix(bg,hcol,hc), 200.0);
  }
#elif MODE==54
  { // bicolore : deux moitiés de deux couleurs, séparées par une ligne nette qui ondule à peine
    vec3 u=normalize(q); float y=u.y+0.05*sin(atan(u.z,u.x)*2.0+so.x);
    vec3 c=y>0.0?uC1:mix(uC3,vec3(0.97,0.96,0.93),0.45);
    c=mix(c,uC2*0.55,smoothstep(0.03,0.012,abs(y)));
    return vec4(c, 200.0);
  }
#elif MODE==55
  { // vagues : des bandes en vagues bien rondes qui font le tour de la bille
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float y=u.y*(4.5+nb)+0.38*sin(lon*(4.0+nb)+so.x);
    float m=mod(floor(y),3.0); vec3 c=m<1.0?uC1:(m<2.0?vec3(0.97,0.96,0.93):uC2);
    c*=mix(0.8,1.0,smoothstep(0.0,0.14,fract(y)));
    return vec4(c, 200.0);
  }
#elif MODE==56
  { // zigzag : des bandes en dents de scie, comme sur un pull d'hiver
    vec3 u=normalize(q); float s=atan(u.z,u.x)/6.2831853*(8.0+nb*2.0);
    float zz=abs(fract(s)-0.5)*2.0;
    float y=u.y*(3.5+nb*0.5)+zz*0.6;
    float m=mod(floor(y),4.0); vec3 c=m<1.0?uC1:(m<2.0?uC3:(m<3.0?uC1:vec3(0.97,0.95,0.9)));
    c*=mix(0.82,1.0,smoothstep(0.0,0.1,fract(y)));
    return vec4(c, 200.0);
  }
#elif MODE==57
  { // tricot : des mailles de laine en V, rang par rang, avec quelques rangs d'une autre couleur
    vec3 u=normalize(q); vec2 s=sph(u); float n=16.0+nb*2.0;
    vec2 p=vec2(s.x*n, s.y*n*0.62); vec2 id=floor(p), f=fract(p)-0.5;
    vec2 g=vec2(abs(f.x)-0.23, f.y+abs(f.x)*0.85-0.1);
    float leg=length(g*vec2(1.9,1.0))-0.3;
    float sh=smoothstep(0.1,-0.06,leg);
    float row=mod(id.y+floor(so.x),7.0);
    vec3 yarn=row<2.0?uC2:(row<3.0?vec3(0.96,0.94,0.9):uC1);
    vec3 c=yarn*(0.4+0.65*sh)*(0.9+0.18*noise(vec3(p*7.0,so.x)));
    return vec4(c, 200.0);
  }
#elif MODE==58
  { // nuages : un ciel de la couleur du coloris où passent de gros nuages blancs bien ronds
    vec3 u=normalize(q); float n=fbm(u*vec3(2.0,3.4,2.0)+so)+0.3*fbm(u*6.0+so+3.0);
    float cl=smoothstep(0.6,0.68,n);
    vec3 sky=mix(uC1,mix(uC1,vec3(1.0),0.5),u.y*0.5+0.5);
    vec3 cloud=mix(vec3(0.78,0.83,0.92),vec3(1.0),smoothstep(0.64,0.86,n));
    return vec4(mix(sky,cloud,cl), 200.0);
  }
#elif MODE==59
  { // mouchetée : un fond clair couvert de petites taches, comme un œuf de caille
    vec3 u=normalize(q); vec3 base=mix(uC3,vec3(0.97,0.95,0.9),0.65)*(0.92+0.1*noise(u*20.0+so));
    float sp=0.0; vec3 sc=uC1;
    for(int i=0;i<2;i++){ float sc2=i==0?5.0:11.0; vec3 g=u*sc2+so+float(i)*7.0; vec3 id=floor(g), f=fract(g)-0.5;
      vec3 off=vec3(h31(id+1.0),h31(id+2.0),h31(id+3.0))-0.5;
      float rr=(i==0?0.26:0.2)*(0.5+h31(id+4.0)); float d=length((f-off*0.5)*vec3(1.0,1.3,1.0))+0.06*noise(g*4.0);
      float m=smoothstep(rr,rr*0.65,d)*step(0.3,h31(id+6.0));
      if(m>sp){ sp=m; sc=h31(id+8.0)<0.6?uC1*0.6:uC2*0.75; } }
    return vec4(mix(base,sc,sp), 200.0);
  }
#elif MODE==60
  { // jean : la toile de jean (sa trame en diagonale, un peu délavée) et une double couture au fil doré
    vec3 u=normalize(q); vec2 s=sph(u);
    float tw2=fract((s.x*2.0+s.y)*55.0);
    float fade=smoothstep(0.45,0.75,fbm(u*2.0+so));
    vec3 den=mix(uC1*0.45,mix(uC1,vec3(0.9),0.25),smoothstep(0.35,0.65,tw2));
    den=mix(den,mix(uC1,vec3(0.92,0.94,0.97),0.6),fade*0.7);
    den*=0.88+0.22*noise(u*70.0+so);
    float y=u.y+0.04*sin(atan(u.z,u.x)*2.0+so.x);
    den=mix(den,den*0.7,smoothstep(0.065,0.04,abs(y)));
    float lon=atan(u.z,u.x)/6.2831853*80.0;
    float stitch=step(0.4,fract(lon))*smoothstep(0.02,0.01,abs(abs(y)-0.085));
    return vec4(mix(den,vec3(0.93,0.64,0.24),stitch), 200.0);
  }
#elif MODE==61
  { // géode : une pierre grise toute simple, coupée d'un côté ; dans la coupe, une croûte d'agate
    // et des cristaux pointés vers le creux du milieu, qui étincellent
    vec3 u=normalize(q); float h=u.z;
    vec3 rock=mix(vec3(0.4,0.37,0.35),vec3(0.62,0.58,0.54),fbm(u*6.0+so))*(0.8+0.3*noise(u*30.0+so));
    if(h<0.4) return vec4(rock, 200.0);
    vec2 p=u.xy/0.9165; float rr=length(p);
    if(rr>0.84) return vec4(mix(vec3(0.95,0.94,0.92),uC3,0.3)*(0.82+0.18*sin(rr*130.0)), 200.0);
    vec2 g=vec2(atan(p.y,p.x)/6.2831853*30.0, rr*7.0)+so.xy; vec2 id=floor(g), f=fract(g);
    float hk=h31(vec3(id,so.z));
    float facet=(0.5+0.5*sin(f.x*3.1416))*(0.65+0.35*hk)*(0.75+0.25*f.y);
    vec3 cr=mix(uC1,uC2,hk)*(0.45+0.75*facet); cr=mix(cr,vec3(1.0),smoothstep(0.8,1.0,facet)*0.5);
    float cav=smoothstep(0.3,0.1,rr);
    cr=mix(cr,uC1*0.22,cav);
    e=mix(uC2,vec3(1.0),0.6)*step(0.92,h31(vec3(id,so.x+3.0)))*smoothstep(0.6,1.0,facet)*(1.0-cav)*1.6;
    return vec4(cr, 200.0);
  }
#elif MODE==62
  { // ambre : une résine de la couleur du coloris, avec une feuille fossile couchée au cœur et de petites bulles d'air
    float r=length(q); float n=fbm(q*3.0+so);
    vec3 res=mix(mix(uC1,uC2,0.55),uC3,0.25+0.4*n);
    vec2 p=q.xy; float ca=0.8, sa=0.6; p=vec2(ca*p.x-sa*p.y, sa*p.x+ca*p.y);
    float lw=0.18*sqrt(max(0.0,1.0-pow(p.y/0.46,2.0)))*(1.0-0.3*p.y);
    float lz=smoothstep(0.045,0.025,abs(q.z));
    float leaf=smoothstep(0.01,-0.01,abs(p.x)-lw)*lz*step(abs(p.y),0.46);
    float stem=smoothstep(0.014,0.007,abs(p.x))*step(p.y,-0.4)*step(-0.68,p.y)*lz;
    float vein=max(smoothstep(0.014,0.004,abs(p.x)), smoothstep(0.06,0.02,abs(fract((p.y-abs(p.x)*1.1)*8.0)-0.5))*step(abs(p.x),lw*0.9));
    vec3 g=q*7.0+so; vec3 id=floor(g), fc=fract(g)-0.5; float rb=0.05+0.07*h31(id+1.3);
    float bub=step(0.62,h31(id))*smoothstep(0.03,0.0,abs(length(fc-(vec3(h31(id+3.1),h31(id+7.7),h31(id+1.9))-0.5)*0.4)-rb))*smoothstep(0.9,0.7,r);
    e=mix(uC2,uC3,0.5)*n*0.9+vec3(1.0,0.95,0.8)*bub*1.5;
    float lf=max(leaf,stem);
    if(lf>0.01){ vec3 lc=mix(uC1*0.3,vec3(0.24,0.14,0.05),0.6)*(1.0-0.55*vein); e*=0.3; return vec4(lc, 70.0*lf); }
    return vec4(res, 2.4+bub*20.0);
  }
#elif MODE==63
  { // circuit : une carte électronique sombre ; ses pistes s'allument et la lumière y court d'un point à l'autre
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
    vec3 board=mix(vec3(0.03,0.06,0.07),uC1*0.25,0.6)*(0.85+0.2*noise(u*40.0+so));
    vec3 lc=mix(uC2,vec3(1.0),0.35);
    e=(lc*(tr*(0.5+2.5*pulse)+pad*1.1)*(1.0-hole)+lc*smoothstep(0.32,0.0,dd)*0.2)*1.4;
    vec3 c=mix(board,mix(uC2,vec3(0.85,0.75,0.4),0.3),max(tr,pad)*(1.0-hole));
    return vec4(c, 200.0);
  }
#elif MODE==64
  { // feu d'artifice : des bouquets de lumière qui éclatent dans un verre de nuit, chacun de sa couleur
    float r=length(q); e=vec3(0.0);
    for(int i=0;i<3;i++){ float fi=float(i);
      vec3 c=(vec3(h31(so+fi*3.1),h31(so+fi*5.7),h31(so+fi*8.3))-0.5)*0.8;
      float R=0.34+0.16*h31(so+fi*2.3);
      vec3 d=q-c; float L=length(d); vec3 dir=d/max(L,1e-4);
      vec3 g=dir*5.0+fi*13.0+so; vec3 id=floor(g);
      vec3 cd=normalize(id+0.5+(vec3(h31(id+1.0),h31(id+2.0),h31(id+3.0))-0.5)*0.7-fi*13.0-so);
      float ang=length(dir-cd);
      float ray=smoothstep(0.06,0.014,ang)*step(0.25,h31(id+4.0));
      float along=smoothstep(0.03,0.14,L)*smoothstep(R,R*0.6,L);
      float tip=smoothstep(0.07,0.0,abs(L-R*0.82))*smoothstep(0.08,0.02,ang)*step(0.25,h31(id+4.0));
      vec3 col=i==0?mix(uC2,vec3(1.0),0.2):(i==1?mix(uC3,vec3(1.0),0.2):vec3(1.0,0.85,0.45));
      e+=col*(ray*along*7.0+tip*14.0)+mix(col,vec3(1.0),0.5)*exp(-L*28.0)*4.0;
    }
    vec3 g=q*16.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.97,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*4.0;
    e*=smoothstep(0.95,0.85,r);
    return vec4(uC1*0.12, 1.2);
  }
