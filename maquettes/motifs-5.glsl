// (6 novembre 2026, 2e partie) encore des Communs (157 à 171), des Peu communs (172 à 186) et des Rares (187 à 198)
// ===================== Communs =====================
#elif MODE==157
  { // dragées : des bonbons plats et brillants, comme des pastilles de chocolat enrobées, éparpillés
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.85);
    for(int i=0;i<3;i++){ vec3 id; float on; vec2 p=scatP(u,2.6,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.15,h31(id)); float k=h31(id+2.0);
      vec3 dc=k<0.3?brt(uC1,0.45):(k<0.6?uC2:(k<0.85?uC3:vec3(0.97)));
      vec2 e2=p/vec2(0.2,0.15); float L=length(e2);
      vec3 cc=dc*(0.72+0.35*(1.0-L*L))+vec3(1.0)*smoothstep(0.35,0.0,length(e2-vec2(-0.35,0.4)))*0.6;
      c=mix(c,c*0.78,step(1.0,L)*step(L,1.18)*on);
      c=mix(c,cc,step(L,1.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==158
  { // ballons : des ballons de baudruche des 3 couleurs, avec leur petit nœud et leur ficelle
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.82);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,1.9,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.8)*p;
      on*=step(0.12,h31(id)); float k=h31(id+2.0); vec3 bc=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3);
      vec2 b=(p-vec2(0.0,0.1))/vec2(0.15,0.19); float L=length(b);
      float str=step(abs(p.x-0.025*sin(p.y*22.0)),0.007)*step(p.y,-0.1)*step(-0.45,p.y);
      float knot=step(abs(p.x),0.035-(-0.09-p.y)*0.6)*step(p.y,-0.08)*step(-0.12,p.y);
      c=mix(c,vec3(0.45),str*on); c=mix(c,bc*0.8,knot*on);
      vec3 cc=bc*(0.7+0.35*(1.0-L*L))+vec3(1.0)*smoothstep(0.3,0.0,length(b-vec2(-0.4,0.45)))*0.7;
      c=mix(c,cc,step(L,1.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==159
  { // étoiles de mer : des étoiles de mer aux bras arrondis, piquées de petits points, sur un fond de sable
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.96,0.92,0.84),0.7)*(0.92+0.1*noise(u*60.0+so));
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.15,h31(id)); float r=length(p), a=atan(p.y,p.x);
      float R=0.25*(0.35+0.65*pow(0.5+0.5*cos(a*5.0),1.6));
      vec3 sc=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      float dots=step(0.6,noise(vec3(p*45.0,id.x)));
      vec3 cc=mix(sc*(0.75+0.35*(1.0-r/max(R,0.01))),mix(uC3,vec3(1.0),0.4),dots*0.8);
      c=mix(c,cc,step(r,R)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==160
  { // croissants : des croissants de lune des deux premières couleurs, et de petits points de la 3e, sur un fond clair
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.2,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.15,h31(id)); float sz=0.16+0.06*h31(id+3.0);
      float cr=step(length(p),sz)*step(sz*0.85,length(p-vec2(sz*0.45,sz*0.2)));
      c=mix(c,h31(id+2.0)<0.5?brt(uC1,0.45):uC2,cr*on); }
    vec3 g=u*12.0+so; c=mix(c,uC3,step(0.82,h31(floor(g)))*smoothstep(0.14,0.1,length(fract(g)-0.5)));
    return vec4(c, 200.0);
  }
#elif MODE==161
  { // dégradé : les 3 couleurs du coloris fondues l'une dans l'autre d'un pôle à l'autre, comme un coucher de soleil
    vec3 u=normalize(q); vec3 ax=normalize(vec3(h31(so)-0.5,1.0,h31(so+1.0)-0.5));
    float t=dot(u,ax)*0.5+0.5+0.04*sin(dot(u,vec3(7.0,3.0,5.0))+so.x);
    vec3 c=t<0.5?mix(brt(uC1,0.45),uC2,smoothstep(0.0,0.5,t)):mix(uC2,uC3,smoothstep(0.5,1.0,t));
    c*=0.96+0.06*noise(u*90.0+so);
    return vec4(c, 200.0);
  }
#elif MODE==162
  { // mondrian : de grands carrés de couleur séparés par des traits noirs, comme un tableau moderne
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy; float fw=cf.w;
    float x1=-0.5+0.35*h31(vec3(fw,1.0,so.x)), x2=0.15+0.5*h31(vec3(fw,2.0,so.x)), y1=-0.55+0.4*h31(vec3(fw,3.0,so.x)), y2=0.1+0.5*h31(vec3(fw,4.0,so.x));
    float ix=p.x<x1?0.0:(p.x<x2?1.0:2.0), iy=p.y<y1?0.0:(p.y<y2?1.0:2.0);
    float k=h31(vec3(ix+fw*3.0,iy,so.y));
    vec3 c=k<0.2?brt(uC1,0.4):(k<0.38?uC2:(k<0.54?uC3:vec3(0.96,0.95,0.92)));
    float ln=min(min(abs(p.x-x1),abs(p.x-x2)),min(abs(p.y-y1),abs(p.y-y2)));
    ln=min(ln,1.0-max(abs(p.x),abs(p.y)));
    return vec4(mix(vec3(0.07),c,smoothstep(0.022,0.032,ln)), 200.0);
  }
#elif MODE==163
  { // pâquerettes : des marguerites aux pétales clairs (3e couleur) et au cœur de la 2e, dans un pré de la 1re
    vec3 u=normalize(q); vec3 c=mix(brt(uC1,0.45)*0.6,brt(uC1,0.45)*0.85,noise(u*8.0+so));
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.2,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.1,h31(id)); float r=length(p), a=atan(p.y,p.x), sz=0.19+0.06*h31(id+3.0);
      float pet=step(r,sz*(0.72+0.28*abs(cos(a*6.0))))*step(0.05,r);
      vec3 pc=mix(uC3,vec3(1.0),0.55)*(0.8+0.25*abs(cos(a*6.0)));
      c=mix(c,pc,pet*on);
      c=mix(c,uC2*(0.8+0.3*step(0.6,noise(vec3(p*60.0,id.x)))),step(r,0.065)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==164
  { // ronds dans l'eau : des cercles qui s'élargissent autour de gouttes tombées dans une eau de la 1re couleur
    vec3 u=normalize(q); vec3 c=brt(uC1,0.45)*(0.6+0.15*noise(u*4.0+so));
    for(int i=0;i<3;i++){ vec3 id; float on; vec2 p=scatP(u,1.6,float(i),id,on);
      on*=step(0.2,h31(id)); float L=length(p), R=0.3+0.15*h31(id+3.0);
      float rg=smoothstep(0.25,0.0,abs(fract(L*22.0-h31(id)*3.0)-0.5)-0.25)*smoothstep(R,R*0.3,L);
      c=mix(c,mod(float(i)+floor(L*22.0),2.0)<1.0?uC2:uC3,rg*on*0.85); }
    return vec4(c, 200.0);
  }
#elif MODE==165
  { // hachures : des traits de stylo serrés, dans trois sens et trois couleurs, qui se croisent par endroits sur un papier blanc
    vec3 u=normalize(q); vec3 c=vec3(0.98,0.97,0.94);
    for(int i=0;i<3;i++){ float fi=float(i);
      vec3 dir=normalize(vec3(h31(so+fi*1.3),h31(so+fi*2.1),h31(so+fi*3.7))-0.5+0.001);
      float l=smoothstep(0.14,0.04,abs(fract(dot(u,dir)*34.0+0.4*noise(u*4.0+fi))-0.5)-0.28);
      float m=smoothstep(0.5,0.56,noise(u*2.4+so+fi*7.0));
      c=mix(c,i==0?brt(uC1,0.4)*0.8:(i==1?uC2:uC3),l*m*0.9); }
    return vec4(c, 200.0);
  }
#elif MODE==166
  { // tampons : des formes tamponnées à l'encre (ronds, carrés, triangles), un peu baveuses, de 3 couleurs
    vec3 u=normalize(q); vec3 c=vec3(0.98,0.97,0.94);
    for(int i=0;i<3;i++){ vec3 id; float on; vec2 p=scatP(u,2.2,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.2,h31(id)); float k=h31(id+4.0), sz=0.15+0.05*h31(id+3.0); vec2 a=abs(p);
      float d=k<0.34?length(p)-sz:(k<0.67?max(a.x,a.y)-sz*0.85:max(a.x*0.866+p.y*0.5,-p.y)-sz*0.5);
      float ink=step(d,0.0)*(0.55+0.45*smoothstep(0.3,0.6,noise(vec3(p*30.0,id.x))));
      float k2=h31(id+2.0); vec3 ic=k2<0.34?brt(uC1,0.4):(k2<0.67?uC2:uC3);
      c=mix(c,ic,ink*on); }
    return vec4(c, 200.0);
  }
#elif MODE==167
  { // brindilles : de petites branches avec leurs feuilles (1re et 2e couleurs) et des baies de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.85);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,1.8,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id)); vec3 lc=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      float stem=step(abs(p.x),0.008)*step(abs(p.y),0.3);
      float lf=0.0, rib=0.0;
      for(int j=0;j<4;j++){ float y0=-0.2+float(j)*0.13, sd=mod(float(j),2.0)<1.0?1.0:-1.0;
        vec2 q2=mrot(0.8*sd)*(p-vec2(0.0,y0)); q2.x*=sd; q2-=vec2(0.09,0.0);
        float w=0.045*(1.0-pow(q2.x/0.09,2.0)); lf=max(lf,step(abs(q2.y),w)*step(abs(q2.x),0.09)); rib=max(rib,step(abs(q2.y),0.005)*step(abs(q2.x),0.08)); }
      float berry=step(length(p-vec2(0.0,0.32)),0.04);
      c=mix(c,lc*0.6,stem*on); c=mix(c,lc*(1.0-0.3*rib),lf*on); c=mix(c,uC3*(0.8+0.4*step(length(p-vec2(-0.012,0.333)),0.012)),berry*on); }
    return vec4(c, 200.0);
  }
#elif MODE==168
  { // coccinelles : de petites bêtes à bon Dieu, la carapace de la 2e ou de la 3e couleur, les points et la tête de la 1re
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.82);
    vec3 dk=brt(uC1,0.2)*0.22;
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id)); vec3 sc=h31(id+2.0)<0.5?uC2:uC3;
      float body=step(length(p/vec2(0.15,0.17)),1.0), head=step(length((p-vec2(0.0,0.17))/vec2(0.08,0.06)),1.0);
      float sp=0.0; for(int j=0;j<3;j++){ float fj=float(j); vec2 s=vec2(0.075,-0.07+fj*0.07);
        sp=max(sp,step(length(vec2(abs(p.x),p.y)-s),0.032)); }
      float line=step(abs(p.x),0.008)*step(p.y,0.15);
      vec3 cc=sc*(0.75+0.35*(1.0-length(p)/0.17))+vec3(1.0)*smoothstep(0.06,0.0,length(p-vec2(-0.06,0.08)))*0.5;
      cc=mix(cc,dk,max(sp,line));
      c=mix(c,dk,head*on); c=mix(c,cc,body*on); }
    return vec4(c, 200.0);
  }
#elif MODE==169
  { // musique : des portées de musique qui font le tour de la bille, et des notes de deux couleurs dessus
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.8);
    float y=u.y*9.0; float grp=floor(y/1.6), fy=fract(y/1.6)*1.6;
    float st=step(fy,1.0)*smoothstep(0.035,0.015,abs(fract(fy*4.0+0.5)-0.5)/4.0);
    c=mix(c,brt(uC1,0.4)*0.6,st*0.8);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.4,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.6)*p;
      on*=step(0.25,h31(id)); vec3 nc=h31(id+2.0)<0.5?uC2:brt(uC1,0.4);
      vec2 hp=mrot(0.45)*(p-vec2(-0.05,-0.12)); float head=step(length(hp/vec2(0.07,0.05)),1.0);
      float stem=step(abs(p.x-0.012),0.012)*step(-0.12,p.y)*step(p.y,0.18);
      float flag=step(0.0,p.x-0.02)*step(p.x-0.02,0.08)*step(abs(p.y-0.15+(p.x-0.02)*1.2),0.03);
      c=mix(c,nc,max(max(head,stem),flag)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==170
  { // éclairs : des petits éclairs de la 2e et de la 3e couleur, au cœur blanc, sur un fond de la 1re
    vec3 u=normalize(q); vec3 c=brt(uC1,0.4)*(0.55+0.15*noise(u*5.0+so));
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.15,h31(id));
      float d=segM(p,vec2(0.06,0.26),vec2(-0.06,0.02)); d=min(d,segM(p,vec2(-0.06,0.02),vec2(0.06,0.03))); d=min(d,segM(p,vec2(0.06,0.03),vec2(-0.05,-0.26)));
      vec3 bc=h31(id+2.0)<0.5?uC2:uC3;
      c=mix(c,bc,smoothstep(0.05,0.04,d)*on); c=mix(c,vec3(1.0),smoothstep(0.018,0.01,d)*on*0.8); }
    return vec4(c, 200.0);
  }
#elif MODE==171
  { // sourires : des petites têtes rondes qui sourient, de la 2e et de la 3e couleur, les yeux et la bouche de la 1re
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93); vec3 dk=brt(uC1,0.3)*0.4;
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.2,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*1.2)*p;
      on*=step(0.12,h31(id)); float L=length(p), R=0.15;
      vec3 fc=h31(id+2.0)<0.5?uC2:uC3;
      float eyes=step(length(vec2(abs(p.x)-0.05,p.y-0.04)),0.022);
      float sm=step(abs(length(p-vec2(0.0,0.02))-0.085),0.014)*step(p.y,-0.02);
      vec3 cc=mix(fc*(0.85+0.2*(1.0-L/R)),dk,max(eyes,sm));
      c=mix(c,dk,step(L,R+0.014)*on); c=mix(c,cc,step(L,R)*on); }
    return vec4(c, 200.0);
  }
// ===================== Peu communs =====================
#elif MODE==172
  { // zèbre : des rayures qui ondulent et se fourchent, de la 1re et de la 2e couleur, sur un fond clair de la 3e
    vec3 u=normalize(q); vec3 ax=normalize(vec3(0.2,1.0,0.1));
    float v=dot(u,ax)*9.0+2.2*fbm(u*1.6+so)+0.6*noise(u*5.0+so);
    float s=step(0.5,fract(v)); float m=mod(floor(v),2.0);
    vec3 c=mix(mix(uC3,vec3(1.0),0.55),m<1.0?brt(uC1,0.3)*0.5:uC2,s);
    return vec4(c, 200.0);
  }
#elif MODE==173
  { // plumes : des plumes en rangées serrées qui se chevauchent, avec leur tuyau et leurs barbes, une couleur par rang
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*(3.0+nb*0.3)+so.xy;
    vec3 c=brt(uC1,0.3)*0.2;
    for(int j=1;j>=-1;j--){ float row=floor(g.y)+float(j); float x0=mod(row,2.0)*0.5;
      for(int k=-1;k<=1;k++){ float kx=floor(g.x-x0)+float(k); vec2 C=vec2(kx+x0+0.5,row+0.75); vec2 p=g-C;
        float w=0.42*sqrt(max(0.0,1.0-pow((p.y+0.25)/0.9,2.0)));
        if(abs(p.x)<w && p.y<0.6 && p.y>-1.1){ float m=mod(row,3.0); vec3 fc=m<1.0?brt(uC1,0.45):(m<2.0?uC2:uC3);
          float barb=0.8+0.2*sin((p.y*1.0+abs(p.x)*1.4)*60.0);
          float shaft=smoothstep(0.03,0.01,abs(p.x));
          c=mix(fc*barb*(0.65+0.45*(1.0-abs(p.x)/max(w,0.01))),vec3(0.95),shaft*0.7); } } }
    return vec4(c, 200.0);
  }
#elif MODE==174
  { // kilim : les bandes d'un tapis tissé, des losanges en escalier de 3 couleurs et des dents blanches entre les bandes
    vec3 u=normalize(q); float lon=atan(u.z,u.x), lat=u.y;
    float y=lat*4.5+2.0; float b=floor(y), fy=fract(y)-0.5;
    float N=10.0; float lx=fract(lon/6.2831853*N)-0.5;
    vec2 p=vec2(lx*1.6*sqrt(max(0.05,1.0-lat*lat)),fy); p=floor(p*14.0)/14.0;
    float dm=abs(p.x)+abs(p.y);
    float m=mod(b,3.0);
    vec3 bg=m<1.0?uC2:(m<2.0?brt(uC1,0.45):uC3), c1=m<1.0?brt(uC1,0.45):(m<2.0?uC3:uC2), c2=m<1.0?uC3:(m<2.0?uC2:brt(uC1,0.45));
    vec3 c=dm<0.36?(dm<0.2?(dm<0.07?vec3(0.97):c2):c1):bg;
    float teeth=step(0.42,abs(fy))*step(0.5,fract(lon/6.2831853*N*4.0+(fy>0.0?0.5:0.0)));
    c=mix(c,vec3(0.96,0.94,0.88),teeth);
    c*=0.9+0.12*step(0.5,fract(lon*120.0))*step(0.5,fract(lat*90.0));
    return vec4(c, 200.0);
  }
#elif MODE==175
  { // batik : un tissu teint de la 1re couleur, craquelé de fines veines de la 2e, avec des fleurs gardées par la cire, de la 3e
    vec3 u=normalize(q); vec3 c=brt(uC1,0.4)*(0.6+0.2*fbm(u*3.0+so));
    float cr=1.0-abs(2.0*noise(u*7.0+so)-1.0), cr2=1.0-abs(2.0*noise(u*13.0+so+5.0)-1.0);
    c=mix(c,uC2,smoothstep(0.93,0.98,max(cr,cr2*0.98)));
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,1.7,float(i),id,on); on*=step(0.15,h31(id));
      float r=length(p), a=atan(p.y,p.x);
      float fl=step(r,0.26*(0.6+0.4*abs(cos(a*4.0))))*step(0.07,r)*step(abs(r-0.15),0.06+0.0);
      float ring=step(abs(r-0.24),0.012)+step(r,0.045);
      c=mix(c,mix(uC3,vec3(1.0),0.3),max(fl,min(ring,1.0))*on); }
    return vec4(c, 200.0);
  }
#elif MODE==176
  { // cordage : des torons de 3 couleurs enroulés en hélice comme une grosse corde, avec leurs fibres
    vec3 u=normalize(q); float lon=atan(u.z,u.x), lat=asin(clamp(u.y,-1.0,1.0));
    float v=lon/6.2831853*3.0+lat*3.5+so.x; float f=fract(v), m=mod(floor(v),3.0);
    vec3 c=m<1.0?brt(uC1,0.45):(m<2.0?uC2:uC3);
    float sh=0.45+0.6*sin(3.14159*f);
    float fib=0.85+0.15*sin((lon*3.0-lat*9.0)*20.0+f*6.0);
    return vec4(c*sh*fib, 200.0);
  }
#elif MODE==177
  { // tortue : les plaques d'une carapace de tortue, chacune avec ses anneaux de croissance, de 3 couleurs, et le joint sombre
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(u*2.6+so,cid,d2);
    float k=h31(cid+4.0); vec3 pc=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3);
    float ed=d2-d1;
    pc*=0.8+0.25*smoothstep(0.0,0.4,ed)*(0.85+0.15*sin(ed*70.0));
    pc=mix(pc,mix(uC2,vec3(0.2),0.5),0.25*smoothstep(0.6,0.8,noise(u*12.0+so)));
    return vec4(mix(brt(uC1,0.2)*0.15,pc,smoothstep(0.02,0.05,ed)), 200.0);
  }
#elif MODE==178
  { // grillage : un grillage en losanges de la 3e couleur devant un fond de deux couleurs
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=mrot(0.7853982)*cf.xy*(4.5+nb*0.4)+so.xy;
    vec3 c=mix(brt(uC1,0.45)*0.7,uC2*0.8,smoothstep(0.4,0.6,fbm(u*2.0+so)));
    vec2 f=abs(fract(p)-0.5);
    float wa=smoothstep(0.06,0.035,f.x), wb=smoothstep(0.06,0.035,f.y);
    vec2 id=floor(p+0.5); bool over=mod(id.x+id.y,2.0)<1.0;
    vec3 wc=mix(uC3,vec3(1.0),0.3);
    float w=over?max(wa,wb*(1.0-wa)):max(wb,wa*(1.0-wb));
    float sh=over?(wa>0.0?1.0-f.x*8.0:1.0-f.y*8.0):(wb>0.0?1.0-f.y*8.0:1.0-f.x*8.0);
    c=mix(c*0.85,c,smoothstep(0.03,0.09,min(f.x,f.y)+0.02));
    return vec4(mix(c,wc*(0.6+0.5*clamp(sh,0.0,1.0)),w), 200.0);
  }
#elif MODE==179
  { // pavés : des pavés posés en éventail, comme dans une vieille rue, chacun d'une pierre teintée d'une des 3 couleurs
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*(2.0+nb*0.25)+so.xy;
    vec2 id=floor(g), f=fract(g); vec2 pp=f-vec2(0.5,0.0);
    pp*=0.5; float r=length(pp), a=atan(pp.x,pp.y);
    float ri=floor(r*6.0), ai=floor(a*(2.0+ri*1.6)/1.5708);
    vec2 sc=vec2(fract(r*6.0), fract(a*(2.0+ri*1.6)/1.5708));
    float k=h31(vec3(id+vec2(ri*7.0,ai*3.0),cf.w));
    vec3 c=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3); c=mix(c,vec3(0.55),0.35)*(0.8+0.3*h31(vec3(id,ri+ai*5.0)));
    float jt=min(min(sc.x,1.0-sc.x),min(sc.y,1.0-sc.y)*(0.6+r));
    c*=0.6+0.4*smoothstep(0.0,0.15,jt);
    return vec4(mix(vec3(0.3,0.28,0.26),c,smoothstep(0.04,0.1,jt)*step(r,1.0)), 200.0);
  }
#elif MODE==180
  { // tuiles : un toit de tuiles arrondies qui se recouvrent rang par rang, de 3 couleurs
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*vec2(4.0,5.0)*(1.0+nb*0.08)+so.xy;
    float row=floor(g.y), off=mod(row,2.0)*0.5; float kx=floor(g.x-off); vec2 f=vec2(fract(g.x-off),fract(g.y));
    float bot=0.5-sqrt(max(0.0,0.25-pow(f.x-0.5,2.0)))*0.6;
    vec3 c;
    if(f.y>bot*0.6){ float k=h31(vec3(kx,row,cf.w+so.z)); c=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3);
      c*=0.6+0.5*f.y; c*=0.85+0.2*sin(f.x*3.14159); }
    else { float k=h31(vec3(floor(g.x-mod(row-1.0,2.0)*0.5),row-1.0,cf.w+so.z)); c=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3); c*=0.45; }
    return vec4(c, 200.0);
  }
#elif MODE==181
  { // éponge : une éponge pleine de trous, claire de la 3e couleur, avec des zones de la 2e et des trous sombres de la 1re
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(u*7.0+so,cid,d2);
    vec3 c=mix(uC3,vec3(1.0),0.3)*(0.85+0.2*noise(u*30.0+so));
    c=mix(c,uC2,smoothstep(0.5,0.56,fbm(u*2.0+so)));
    float hole=smoothstep(0.32*(0.5+h31(cid)),0.22*(0.5+h31(cid)),d1)*step(0.35,h31(cid+3.0));
    vec3 cid2; float e2; float d3=vorF(u*15.0+so+3.0,cid2,e2); hole=max(hole,smoothstep(0.2,0.12,d3)*step(0.5,h31(cid2))*0.8);
    return vec4(mix(c,brt(uC1,0.3)*0.35,hole), 200.0);
  }
#elif MODE==182
  { // vermicelles : un glaçage brillant de la 2e couleur couvert de petits vermicelles de sucre de la 1re, de la 3e et blancs
    vec3 u=normalize(q); vec3 c=uC2*(0.9+0.1*noise(u*6.0+so));
    for(int i=0;i<3;i++){ vec3 id; float on; vec2 p=scatP(u,5.5,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.2,h31(id)); float d=segM(p,vec2(-0.14,0.0),vec2(0.14,0.0));
      float k=h31(id+2.0); vec3 sc=k<0.4?brt(uC1,0.45):(k<0.8?uC3:vec3(0.98));
      float m=smoothstep(0.06,0.045,d)*on;
      c=mix(c,sc*(0.8+0.3*smoothstep(0.05,0.0,d)),m); }
    return vec4(c, 200.0);
  }
#elif MODE==183
  { // python : la peau d'un serpent, ses petites écailles en losange et ses grandes taches sombres cerclées de la 2e couleur
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=mrot(0.7853982)*cf.xy*(11.0+nb);
    vec2 f=abs(fract(p)-0.5); float sc=smoothstep(0.0,0.12,min(f.x,f.y));
    float n=fbm(u*2.4+so)+0.1*noise(u*9.0+so);
    vec3 c=mix(uC3,vec3(0.92,0.86,0.7),0.4);
    c=mix(c,uC2,smoothstep(0.5,0.52,n));
    c=mix(c,brt(uC1,0.2)*0.3,smoothstep(0.56,0.58,n));
    c*=0.75+0.3*sc;
    return vec4(c, 200.0);
  }
#elif MODE==184
  { // relief : une carte de randonnée, ses courbes de niveau, ses vallées de la 1re couleur et ses sommets de la 3e
    vec3 u=normalize(q); float h=fbm(u*1.8+so)+0.3*fbm(u*4.0+so+5.0);
    float v=h*12.0; float b=floor(v)/12.0;
    vec3 c=b<0.55?mix(mix(brt(uC1,0.45),vec3(1.0),0.25),uC2,smoothstep(0.3,0.55,b)):mix(uC2,mix(uC3,vec3(1.0),0.3),smoothstep(0.55,0.85,b));
    c=mix(c,c*0.55,smoothstep(0.08,0.0,abs(fract(v)-0.5)-0.42));
    c=mix(c,c*0.4,smoothstep(0.1,0.0,abs(fract(v/5.0)-0.5)*5.0-2.4));
    return vec4(c, 200.0);
  }
#elif MODE==185
  { // point de croix : une broderie de petites croix en 3 couleurs, qui dessinent des losanges sur une toile claire
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*14.0; vec2 id=floor(g), f=fract(g)-0.5;
    vec2 m=mod(id,8.0)-3.5; float dm=abs(m.x)+abs(m.y);
    float k=dm<1.5?2.0:(dm<3.0?1.0:(dm>5.5?0.0:-1.0));
    vec3 c=mix(vec3(0.95,0.93,0.88),uC3,0.08)*(0.9+0.1*step(0.5,fract(g.x*2.0))*step(0.5,fract(g.y*2.0)));
    if(k>-0.5){ vec3 sc=k<0.5?brt(uC1,0.45):(k<1.5?uC2:uC3);
      float x=min(abs(f.x-f.y),abs(f.x+f.y))*0.7071;
      float st=smoothstep(0.12,0.07,x)*step(max(abs(f.x),abs(f.y)),0.42);
      c=mix(c,sc*(0.75+0.3*smoothstep(0.1,0.0,x)),st); }
    return vec4(c, 200.0);
  }
#elif MODE==186
  { // moiré : deux séries de cercles fins qui se croisent et dessinent des vagues mouvantes, de la 1re et de la 2e couleur sur la 3e
    vec3 u=normalize(q); vec3 a1=normalize(vec3(0.3,1.0,0.1)), a2=normalize(vec3(0.5,0.9,-0.3)+0.2*(vec3(h31(so),h31(so+1.0),h31(so+2.0))-0.5));
    float l1=smoothstep(0.3,0.1,abs(fract(acos(dot(u,a1))*15.0)-0.5)), l2=smoothstep(0.3,0.1,abs(fract(acos(dot(u,a2))*15.0)-0.5));
    vec3 c=mix(uC3,vec3(1.0),0.4);
    c=mix(c,brt(uC1,0.4),l1*0.85); c=mix(c,uC2,l2*0.75);
    return vec4(c, 200.0);
  }
// ===================== Rares =====================
#elif MODE==187
  { // œil-de-tigre : une pierre en bandes soyeuses, faite de fibres, dont l'éclat glisse quand on la tourne
    float v=tigreV(q); float m=mod(floor(v),3.0);
    vec3 c=m<1.0?brt(uC1,0.4)*0.55:(m<2.0?uC2*0.8:uC3);
    return vec4(c, 200.0);
  }
#elif MODE==188
  { // turquoise : une pierre de la 2e couleur, parcourue d'une toile de veines sombres de la 1re, avec des taches de la 3e
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(u*3.0+so+0.2*vec3(noise(u*6.0),noise(u*6.0+3.0),noise(u*6.0+5.0)),cid,d2);
    vec3 c=mix(uC2,mix(uC2,vec3(1.0),0.35),noise(u*5.0+so))*(0.9+0.15*noise(u*25.0+so));
    c=mix(c,uC3,smoothstep(0.66,0.7,noise(u*6.0+so+9.0))*0.8);
    float vein=smoothstep(0.035,0.01,d2-d1+0.02*(noise(u*20.0+so)-0.5));
    return vec4(mix(c,brt(uC1,0.2)*0.25,vein), 200.0);
  }
#elif MODE==189
  { // feuille d'or : des éclats de feuille d'or (miroir, au rendu) posés sur une laque profonde de la 1re couleur, quelques-uns teintés de la 2e
    vec3 u=normalize(q); vec3 c=brt(uC1,0.3)*(0.35+0.2*noise(u*4.0+so));
    vec2 m=orM(q);
    return vec4(mix(c,m.y>0.5?mix(vec3(0.85,0.85,0.9),uC2,0.4):mix(vec3(1.0,0.8,0.35),uC3,0.25),m.x), 200.0);
  }
#elif MODE==190
  { // perlée : des perles rondes bien rangées, chacune avec son reflet de nacre, de 3 couleurs
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*(5.0+nb*0.4)+so.xy;
    float row=floor(g.y), off=mod(row,2.0)*0.5; vec2 id=vec2(floor(g.x-off),row), f=vec2(fract(g.x-off),fract(g.y))-0.5;
    float L=length(f)/0.47;
    float k=h31(vec3(id,cf.w)); vec3 pc=k<0.34?brt(uC1,0.5):(k<0.67?uC2:uC3); pc=mix(pc,vec3(0.95),0.25);
    vec3 nc=pc*(0.6+0.45*sqrt(max(0.0,1.0-L*L)))+vec3(1.0)*smoothstep(0.35,0.0,length(f-vec2(-0.13,0.15)))*0.7;
    nc+=0.12*(0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+L*1.5)))*L;   // l'irisé de la nacre au bord
    return vec4(mix(brt(uC1,0.2)*0.15,nc,step(L,1.0)), 200.0);
  }
#elif MODE==191
  { // pétillante : un verre teinté de la 2e couleur où montent des colonnes de toutes petites bulles, avec des éclats de la 3e
    float r=length(q); e=vec3(0.0);
    for(int i=0;i<9;i++){ float fi=float(i); vec2 C=(vec2(h31(so+fi*1.3),h31(so+fi*2.7))-0.5)*1.1;
      float dx=length(q.xz-C+0.02*sin(q.y*12.0+fi)); float y=fract(q.y*7.0+fi*0.37);
      float b=smoothstep(0.025,0.01,abs(length(vec2(dx,(y-0.5)/7.0))-0.018));
      e+=mix(vec3(1.0),uC3,0.4)*b*5.0*smoothstep(0.9,0.7,r); }
    vec3 g=q*20.0+so; vec3 fc=fract(g)-0.5;
    e+=uC3*step(0.985,h31(floor(g)))*smoothstep(0.2,0.0,length(fc))*2.0;
    float bot=smoothstep(-0.4,-0.9,q.y);
    return vec4(mix(uC2,brt(uC1,0.45),bot*0.7), 0.5+bot*2.0);
  }
#elif MODE==192
  { // mercure : des gouttes de métal liquide (miroir, au rendu) roulent sur un fond de la 1re couleur piqué de la 3e
    vec3 u=normalize(q); vec3 c=brt(uC1,0.35)*(0.5+0.2*noise(u*5.0+so));
    c=mix(c,uC3,step(0.9,h31(floor(u*50.0+so)))*0.8);
    float m=mercM(q);
    return vec4(mix(c,mix(vec3(0.8),uC2,0.2),m), 200.0);
  }
#elif MODE==193
  { // jade : une pierre translucide de la 2e couleur, voilée de nuages plus clairs et veinée de la 1re et de la 3e
    float r=length(q); vec3 w=q*2.0+so; w+=0.4*vec3(fbm(w),fbm(w+3.0),fbm(w+6.0));
    float cl=fbm(w*1.4), v1=smoothstep(0.04,0.0,abs(fbm(w*1.1+10.0)-0.5)), v3=smoothstep(0.035,0.0,abs(fbm(w*1.3+20.0)-0.5));
    vec3 c=mix(uC2*0.7,mix(uC2,vec3(1.0),0.4),cl);
    c=mix(c,brt(uC1,0.4)*0.6,v1*0.9); c=mix(c,uC3,v3*0.9);
    e=uC2*0.05;
    return vec4(c, 2.2+cl*2.0+(v1+v3)*6.0);
  }
#elif MODE==194
  { // strass : des pierres taillées serrées dans leur serti d'argent, de 3 couleurs, qui lancent des éclats
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*(4.0+nb*0.3)+so.xy;
    vec2 id=floor(g), f=fract(g)-0.5; float L=length(f), a=atan(f.y,f.x);
    float k=h31(vec3(id,cf.w)); vec3 sc=k<0.34?brt(uC1,0.5):(k<0.67?uC2:uC3);
    float fa=floor(a/0.7853982+0.5), ring=step(0.18,L);
    float br=h31(vec3(id+fa*3.0,cf.w+ring*7.0));
    vec3 gc=sc*(0.45+0.9*br)+vec3(1.0)*pow(br,8.0)*0.8;
    gc=mix(gc,mix(sc,vec3(1.0),0.5),step(L,0.12));   // la table
    vec3 set=vec3(0.75,0.76,0.8)*(0.6+0.4*sin(L*20.0));
    return vec4(mix(set,gc,step(L,0.38)), 200.0);
  }
#elif MODE==195
  { // marqueterie : des cubes en trompe-l'œil faits de trois bois teintés des 3 couleurs, avec le fil du bois
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*(2.6+nb*0.3)+so.xy;
    vec2 s=vec2(g.x*1.1547, g.y+g.x*0.57735); vec2 id=floor(s), f=fract(s);
    float t=f.x>f.y?1.0:0.0;
    vec2 hs=vec2(id.x, id.y); float k=mod(hs.x+hs.y*2.0+t,3.0);
    vec3 wc=k<1.0?brt(uC1,0.45):(k<2.0?uC2:uC3);
    wc=mix(wc,vec3(0.6,0.42,0.25),0.3);
    float grain=0.85+0.15*sin((k<1.0?g.x:(k<2.0?g.y:g.x+g.y))*40.0+fbm(vec3(g*3.0,k))*6.0);
    float ed=min(min(f.x,f.y),min(1.0-f.x,min(1.0-f.y,abs(f.x-f.y))));
    return vec4(mix(vec3(0.2,0.14,0.1),wc*grain*(k<1.0?1.05:(k<2.0?0.8:0.6)),smoothstep(0.01,0.03,ed)), 200.0);
  }
#elif MODE==196
  { // porcelaine : une porcelaine blanche peinte au pinceau de fleurs et de volutes de la 1re couleur, des cœurs de la 2e et des filets de la 3e
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.97,0.99);
    vec3 pc=brt(uC1,0.4)*0.85;
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,1.8,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.15,h31(id)); float r=length(p), a=atan(p.y,p.x);
      float pet=step(r,0.2*(0.55+0.45*abs(cos(a*2.5))))*step(0.05,r);
      float shade=0.55+0.45*smoothstep(0.2,0.05,r);
      float vol=smoothstep(0.012,0.0,abs(fract(r*5.0-a/6.2831853)-0.5)-0.47)*step(0.22,r)*step(r,0.42);
      c=mix(c,mix(vec3(0.97),pc,shade),pet*on); c=mix(c,pc,vol*on*0.8);
      c=mix(c,uC2,step(r,0.05)*on); }
    c=mix(c,uC3,smoothstep(0.012,0.004,abs(abs(u.y)-0.82)));
    c=mix(c,uC3,smoothstep(0.008,0.002,abs(abs(u.y)-0.76)));
    return vec4(c, 200.0);
  }
#elif MODE==197
  { // pierre de lune : une pierre laiteuse de la 1re couleur où flotte un voile de lumière de la 2e et de la 3e
    float r=length(q); vec3 w=q*2.2+so;
    float veil=exp(-pow((q.z-0.15*sin(q.x*3.0+so.x))/0.12,2.0))*smoothstep(0.8,0.3,length(q.xy));
    float n=fbm(w);
    e=mix(uC2,uC3,smoothstep(0.3,0.7,n))*veil*(0.5+n)*6.0;
    return vec4(mix(mix(brt(uC1,0.4),vec3(0.95),0.65),vec3(1.0),n*0.3), 0.7+n*0.8);
  }
#elif MODE==198
  { // néons : des tubes de lumière en forme de cœur, d'étoile et d'éclair flottent dans un verre de nuit, un par couleur
    float h=q.z; vec2 p=q.xy*1.05; float lay=exp(-h*h/0.006); e=vec3(0.0);
    vec2 a=p-vec2(-0.32,0.25); float d1=abs(length(a)-0.2);   // un anneau
    vec2 b=p-vec2(0.3,0.22); vec2 b2=vec2(abs(b.x),b.y); float d2=abs(length(b2-vec2(0.09,0.03))-0.1)*step(-0.01,b.y)+step(b.y,-0.01)*segM(b2,vec2(0.0,-0.2),vec2(0.17,-0.04));   // un cœur
    d2=min(d2,abs(length(b2-vec2(0.09,0.03))-0.1)+step(-0.01,-b.y)*0.0);
    vec2 c=p-vec2(0.0,-0.3); float d3=segM(c,vec2(-0.3,0.05),vec2(-0.12,-0.08)); d3=min(d3,segM(c,vec2(-0.12,-0.08),vec2(0.05,0.08))); d3=min(d3,segM(c,vec2(0.05,0.08),vec2(0.3,-0.06)));   // un zigzag
    vec3 c1=brt(uC1,0.5);
    e+=lay*(c1*(exp(-d1*120.0)*6.0+exp(-d1*18.0)*0.5)+uC2*(exp(-d2*120.0)*6.0+exp(-d2*18.0)*0.5)+uC3*(exp(-d3*120.0)*6.0+exp(-d3*18.0)*0.5));
    e+=lay*vec3(1.0)*(exp(-d1*400.0)+exp(-d2*400.0)+exp(-d3*400.0))*2.0;
    return vec4(c1*0.05, 0.4);
  }
