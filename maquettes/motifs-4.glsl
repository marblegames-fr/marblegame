// (6 novembre 2026) la grande fournée : des motifs tout neufs (117 à 149) et deux nouveaux mythiques animés (155, 156).
// Les 26 propositions du 3 novembre pas encore gardées restent dans motifs-3.glsl (86 à 116), les 5 mythiques du 11 octobre sont renumérotés 150 à 154.
// Chaque motif montre bien les 3 couleurs du coloris ; seuls les mythiques bougent.
// ===================== Communs =====================
#elif MODE==117
  { // arcs-en-ciel : de petits arcs-en-ciel de 3 bandes (une par couleur), avec un nuage à chaque bout, sur un fond clair
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.82);
    for(int i=0;i<2;i++){ vec3 g=u*1.5+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*17.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float on=step(0.1,h31(id))*step(abs(dot(f,u)),0.3);
      p=mrot((h31(id+5.0)-0.5)*1.0)*p; p/=0.42+0.05*h31(id+3.0); p.y+=0.3;
      float L=length(p), arc=step(0.0,p.y)*step(0.52,L)*step(L,1.0);
      float b=(L-0.52)/0.16; vec3 bc=b<1.0?brt(uC1,0.4):(b<2.0?uC2:uC3);
      bc*=mix(0.8,1.0,smoothstep(0.0,0.12,abs(fract(b)-0.5)*2.0-0.0));
      float cl=0.0;
      for(int s=0;s<2;s++){ float sx=s==0?1.0:-1.0;
        cl=max(cl,step(length(p-vec2(0.76*sx,0.0)),0.2)); cl=max(cl,step(length(p-vec2(0.98*sx,-0.04)),0.15)); cl=max(cl,step(length(p-vec2(0.58*sx,-0.05)),0.14)); }
      c=mix(c,bc,arc*on); c=mix(c,vec3(1.0)*(0.92+0.08*step(0.0,p.y)),cl*on); }
    return vec4(c, 200.0);
  }
#elif MODE==118
  { // croisillons : de petites croix bien rangées de deux couleurs, avec un point de la 3e entre elles
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(3.2+nb*0.3)+so.xy;
    vec2 id=floor(p), f=fract(p)-0.5, a=abs(f);
    vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.72);
    float cr=step(min(a.x,a.y),0.075)*step(max(a.x,a.y),0.3);
    vec3 cc=mod(id.x+id.y,2.0)<1.0?brt(uC1,0.35):uC2;
    c=mix(c,cc,cr);
    c=mix(c,uC3*0.85,smoothstep(0.085,0.065,length(a-0.5)));
    return vec4(c, 200.0);
  }
#elif MODE==119
  { // pastèque : de grandes rayures sombres qui ondulent d'un pôle à l'autre, un fond marbré, et la petite trace de la queue
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float s=sin(lon*7.0+1.6*fbm(u*2.5+so)+0.5*sin(u.y*10.0+so.x))+0.45*(noise(u*18.0+so)-0.5);
    float dk=smoothstep(0.22,0.3,s);
    vec3 c=mix(uC2,vec3(0.95),0.12);
    c=mix(c,mix(uC3,vec3(1.0),0.25),smoothstep(0.55,0.68,noise(u*7.0+so))*0.7);
    c=mix(c,uC1*0.75,dk);
    c*=0.92+0.1*noise(u*50.0+so);
    c=mix(c,uC1*0.35,smoothstep(0.13,0.09,length(u.xz))*step(0.0,u.y));
    return vec4(c, 200.0);
  }
#elif MODE==120
  { // mosaïque : de petites tesselles carrées serrées dans leur joint, qui dessinent des cadres de 3 couleurs sur chaque face
    vec3 u=normalize(q); vec4 cf=cubeF(u); float S=8.0+nb; vec2 p=cf.xy*S;
    vec2 id=floor(p), f=fract(p), ed=min(f,1.0-f);
    float jx=h31(vec3(id,cf.w+1.0));
    float gr=smoothstep(0.05,0.11,min(ed.x,ed.y)+0.03*(jx-0.5));
    float ch=max(abs(id.x+0.5),abs(id.y+0.5));
    float m=mod(floor(ch*0.75+so.x),3.0);
    vec3 c=m<1.0?brt(uC1,0.35):(m<2.0?uC2:uC3);
    c*=0.82+0.3*h31(vec3(id,cf.w+7.0));
    return vec4(mix(vec3(0.86,0.84,0.79),c,gr), 200.0);
  }
#elif MODE==121
  { // mikado : des baguettes rayées des 3 couleurs, jetées en vrac les unes sur les autres
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.8);
    for(int i=0;i<30;i++){ float fi=float(i);
      vec3 n=normalize(vec3(h31(so+fi*1.3),h31(so+fi*2.7),h31(so+fi*4.1))-0.5+0.001);
      vec3 cen=normalize(cross(n,normalize(vec3(h31(so+fi*5.9),h31(so+fi*6.3),h31(so+fi*7.7))-0.5+0.001)));
      float d=dot(u,n), al=dot(u,cen);
      if(abs(d)<0.034 && al>0.5){
        vec3 bt=cross(n,cen); float s=atan(dot(u,bt),al);
        float k=h31(so+fi*8.1); vec3 sc=k<0.34?brt(uC1,0.4):(k<0.67?uC2:uC3), oc=k<0.34?uC2:(k<0.67?uC3:brt(uC1,0.4));
        sc=mod(floor((s+2.0)*9.0),4.0)<1.0?oc:sc;
        float tip=smoothstep(0.5,0.53,al);
        sc=mix(vec3(0.95,0.9,0.8),sc,tip);
        c=sc*(0.62+0.38*sqrt(max(0.0,1.0-d*d/0.001156))); } }
    return vec4(c, 200.0);
  }
#elif MODE==122
  { // dé : la bille est un gros dé, une face du cube par côté (de 1 à 6), aux points de la 1re couleur, le 1 de la 2e
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy;
    float n=cf.w<0.5?1.0:(cf.w<1.5?6.0:(cf.w<2.5?2.0:(cf.w<3.5?5.0:(cf.w<4.5?3.0:4.0))));
    float d=9.0;
    if(mod(n,2.0)>0.5) d=min(d,length(p));
    if(n>1.5){ d=min(d,length(p-vec2(0.55,0.55))); d=min(d,length(p+vec2(0.55,0.55))); }
    if(n>3.5){ d=min(d,length(p-vec2(0.55,-0.55))); d=min(d,length(p+vec2(0.55,-0.55))); }
    if(n>5.5){ d=min(d,length(p-vec2(0.55,0.0))); d=min(d,length(p+vec2(0.55,0.0))); }
    float pr=n<1.5?0.32:0.18;
    vec3 body=mix(uC3,vec3(0.98,0.97,0.95),0.55);
    body*=mix(1.0,0.78,smoothstep(0.82,1.0,max(abs(p.x),abs(p.y))));
    vec3 pc=n<1.5?uC2:brt(uC1,0.3)*0.8;
    float pip=smoothstep(pr,pr-0.03,d);
    return vec4(mix(body,pc*(0.6+0.4*smoothstep(0.0,pr,d)),pip), 200.0);
  }
#elif MODE==123
  { // œuf décoré : des bandes peintes comme un œuf de Pâques, avec des zigzags blancs, des points et des losanges
    vec3 u=normalize(q); float lon=atan(u.z,u.x), lat=u.y;
    float y=lat*6.0+3.0+so.x*0.0; float b=floor(y), fy=fract(y);
    float m=mod(b,3.0); vec3 c=m<1.0?brt(uC1,0.4):(m<2.0?uC2:uC3);
    vec3 oc=m<1.0?uC3:(m<2.0?brt(uC1,0.4):uC2);
    float N=18.0, lx=fract(lon/6.2831853*N), zz=abs(lx-0.5)*2.0;
    float cl=sqrt(max(0.0,1.0-lat*lat));
    c=mix(c,vec3(0.98),smoothstep(0.05,0.02,abs(fy-0.8-0.1*(zz-0.5))));
    vec2 dp=vec2((lx-0.5)*0.349*cl,(fy-0.4)/6.0);
    float dots=smoothstep(0.03,0.022,length(dp));
    float dia=smoothstep(0.035,0.028,abs(dp.x)+abs(dp.y));
    c=mix(c,m<1.5?vec3(0.98):oc,m<1.0?dots:(m<2.0?0.0:dia));
    c=mix(c,oc,m>0.5&&m<1.5?dia:0.0);
    c=mix(c,brt(uC1,0.4),smoothstep(0.9,0.92,abs(lat)));
    return vec4(c, 200.0);
  }
// ===================== Peu communs =====================
#elif MODE==124
  { // bouleau : l'écorce blanche du bouleau, ses petits traits sombres en travers, ses cicatrices et un peu de mousse
    vec3 u=normalize(q); float lon=atan(u.z,u.x), lat=u.y;
    vec3 c=mix(vec3(0.95,0.94,0.9),uC3,0.14)*(0.9+0.1*noise(u*30.0+so));
    vec2 g=vec2(lon/6.2831853*30.0, lat*16.0+so.x); vec2 id=floor(g), f=fract(g)-0.5;
    float on=step(0.45,h31(vec3(id,so.z)));
    float w=0.3+0.25*h31(vec3(id,1.0));
    float dash=smoothstep(0.13,0.06,abs(f.y))*smoothstep(w,w-0.08,abs(f.x+0.2*(h31(vec3(id,2.0))-0.5)));
    c=mix(c,brt(uC1,0.2)*0.3,dash*on);
    c=mix(c,brt(uC1,0.2)*0.22,smoothstep(0.66,0.7,fbm(vec3(u.x*2.0,u.y*7.0,u.z*2.0)+so)));
    c=mix(c,mix(uC3,vec3(0.85,0.6,0.4),0.3),smoothstep(0.64,0.68,fbm(vec3(u.x*3.0,u.y*9.0,u.z*3.0)+so+4.0))*0.6);   // l'écorce qui pèle
    c=mix(c,uC2*(0.6+0.5*noise(u*70.0+so)),smoothstep(0.63,0.7,fbm(u*4.0+so+9.0)));
    return vec4(c, 200.0);
  }
#elif MODE==125
  { // léopard : des rosaces de taches sombres, le cœur plus foncé que le pelage, sur un fond doré
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 c=mix(uC3,vec3(0.96,0.86,0.66),0.4)*(0.92+0.1*noise(u*40.0+so));
    for(int i=0;i<2;i++){ vec3 g=u*1.9+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*31.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float on=step(abs(dot(f,u)),0.22)*step(0.12,h31(id));
      float sz=0.22+0.08*h31(id+3.0);
      p+=0.05*vec2(noise(vec3(p*14.0,id.x)),noise(vec3(p*14.0,id.y)))-0.025;
      float L=length(p*vec2(1.0,1.2))/sz, a=atan(p.y,p.x);
      float ring=step(0.6,L)*step(L,1.0)*step(0.32,noise(vec3(cos(a)*3.0,sin(a)*3.0,h31(id)*9.0)));
      c=mix(c,mix(uC2,uC3,0.2)*0.75,step(L,0.6)*on); c=mix(c,brt(uC1,0.2)*0.28,ring*on); }
    vec3 g=u*10.0+so; vec3 f=fract(g)-0.5;   // les petits points entre les rosaces
    c=mix(c,brt(uC1,0.2)*0.28,step(0.82,h31(floor(g)))*smoothstep(0.17,0.12,length(f)));
    return vec4(c, 200.0);
  }
#elif MODE==126
  { // vinyle : un disque de chaque côté, ses sillons qui brillent, son étiquette de couleur et le petit trou au milieu
    vec3 u=normalize(q); float rho=length(u.xy), a=atan(u.y,u.x);
    vec3 vc=mix(vec3(0.04),brt(uC1,0.3)*0.35,0.55);
    float gro=0.5+0.5*sin(rho*320.0+so.x);
    float sheen=pow(abs(cos(a-0.6)),10.0)*0.4+pow(abs(cos(a+0.9)),30.0)*0.15;
    vec3 c=vc*(0.8+0.35*gro)+vec3(sheen)*(0.55+0.45*gro);
    c*=mix(0.55,1.0,smoothstep(0.0,0.012,abs(fract(rho*4.3+0.15)-0.5)-0.004));   // les blancs entre les chansons
    if(rho<0.4){ c=uC2*(0.95+0.05*noise(u*40.0));
      c=mix(c,uC3,step(0.28,rho)*step(rho,0.32));
      c=mix(c,uC3,smoothstep(0.012,0.006,abs(rho-0.13)));
      float tx=step(0.5,noise(vec3(a*7.0,rho*50.0,so.x)))*step(0.17,rho)*step(rho,0.24);
      c=mix(c,brt(uC1,0.2)*0.4,tx*0.7);
      c=mix(c,vec3(0.05),step(rho,0.045)); }
    return vec4(c, 200.0);
  }
#elif MODE==127
  { // osier : des brins tressés dessus-dessous comme un panier, de 3 couleurs
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(4.0+nb*0.4)+so.xy;
    vec2 id=floor(p), f=fract(p);
    bool hz=mod(id.x+id.y,2.0)<1.0;
    float across=hz?f.y:f.x, along=hz?f.x:f.y, row=hz?id.y:id.x;
    float m=mod(row,3.0);
    vec3 sc=hz?(m<2.0?brt(uC1,0.45):uC3):(m<2.0?uC2:uC3);
    float sh=(0.55+0.45*sin(3.14159*across))*(0.72+0.28*sin(3.14159*along));
    float gap=smoothstep(0.02,0.09,across)*smoothstep(0.98,0.91,across);
    vec3 c=mix(brt(uC1,0.2)*0.12,sc*sh,gap);
    c*=0.9+0.14*noise(vec3(hz?p.x*2.0:p.x*24.0,hz?p.y*24.0:p.y*2.0,cf.w*5.0));
    return vec4(c, 200.0);
  }
#elif MODE==128
  { // vache : de grandes taches de la 1re couleur sur un pelage blanc, des taches plus petites de la 2e et des taches de rousseur de la 3e
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93)*(0.94+0.06*noise(u*30.0+so));
    float n1=fbm(u*1.8+so)+0.15*noise(u*7.0+so), b1=smoothstep(0.6,0.62,n1);
    float n2=fbm(u*2.6+so+13.0)+0.15*noise(u*9.0+so), b2=smoothstep(0.64,0.66,n2)*(1.0-b1);
    float n3=fbm(u*6.0+so+27.0), b3=smoothstep(0.67,0.69,n3)*(1.0-b1)*(1.0-b2);
    c=mix(c,brt(uC1,0.2)*0.4,b1); c=mix(c,uC2,b2); c=mix(c,uC3,b3);
    return vec4(c, 200.0);
  }
#elif MODE==129
  { // trèfles : des trèfles à quatre feuilles semés sur un fond clair, de deux couleurs, avec leur tige
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 c=mix(uC3,vec3(0.98,0.97,0.94),0.72);
    for(int i=0;i<2;i++){ vec3 g=u*1.6+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*23.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float on=step(0.15,h31(id))*step(abs(dot(f,u)),0.28);
      p=mrot(h31(id+5.0)*6.2831853)*p; p/=1.5+0.4*h31(id+3.0);
      float d=9.0;
      for(int j=0;j<4;j++){ float aa=float(j)*1.5707963+0.7853982; vec2 dd=vec2(cos(aa),sin(aa)), pp=p-dd*0.1;
        d=min(d,length(pp)-0.08+0.035*smoothstep(0.03,0.0,abs(dot(pp,vec2(-dd.y,dd.x))))*step(0.0,dot(pp,dd))); }   // chaque feuille en cœur
      float stem=step(abs(p.x-0.03*sin(p.y*14.0)),0.012)*step(p.y,0.0)*step(-0.3,p.y);
      vec3 lc=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      c=mix(c,lc*0.65,stem*on);
      c=mix(c,lc*(0.7+0.35*smoothstep(0.0,0.06,-d)),step(d,0.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==130
  { // cotte de mailles : des anneaux de métal de 3 couleurs passés les uns dans les autres
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(3.0+nb*0.3)+so.xy;
    vec3 c=brt(uC1,0.2)*0.1; float best=-99.0;
    for(int y=-1;y<=1;y++) for(int x=-1;x<=1;x++){
      float j=floor(p.y)+float(y), off=mod(j,2.0)*0.5, i=floor(p.x-off)+float(x);
      vec2 d=p-vec2(i+off+0.5,j+0.5); float L=length(d), ring=abs(L-0.5);
      if(ring<0.09){ float pri=j+0.4*sign(d.x*d.y);
        if(pri>best){ best=pri; float k=mod(i+j*2.0,3.0);
          vec3 rc=k<1.0?brt(uC1,0.5):(k<2.0?uC2:uC3); rc=mix(rc,vec3(0.8),0.25);
          float t=1.0-ring/0.09;
          c=rc*(0.45+0.6*t*(0.6-0.4*d.y/max(L,0.01)))+vec3(1.0)*pow(t,10.0)*0.35; } } }
    return vec4(c, 200.0);
  }
#elif MODE==131
  { // tie-dye : la spirale du tee-shirt teint à la main, en 3 couleurs qui bavent l'une dans l'autre, et ses plis blancs
    vec3 u=normalize(q); float a=atan(u.y,u.x), th=acos(clamp(abs(u.z),0.0,1.0));
    float v=a/6.2831853*3.0+th*2.2+0.25*fbm(u*3.0+so);
    float b=fract(v)*3.0;
    vec3 c=b<1.0?mix(brt(uC1,0.45),uC2,smoothstep(0.75,1.0,b)):(b<2.0?mix(uC2,uC3,smoothstep(1.75,2.0,b)):mix(uC3,brt(uC1,0.45),smoothstep(2.75,3.0,b)));
    float rn=1.0-abs(2.0*noise(vec3(a*3.0,th*9.0,so.x))-1.0);
    c=mix(c,vec3(0.97),smoothstep(0.86,0.97,rn)*0.8);
    c=mix(c,vec3(0.97),smoothstep(0.08,0.0,th)*0.0);
    return vec4(c, 200.0);
  }
#elif MODE==132
  { // zellige : des carreaux émaillés en étoiles à huit branches, de deux couleurs, sur un fond de la 3e, avec leur joint
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.4+nb*0.3)+so.xy;
    vec2 id=floor(p), f=fract(p)-0.5;
    vec2 a=abs(f), b=abs(mrot(0.7853982)*f);
    float d=min(max(a.x,a.y),max(b.x,b.y))-0.3;
    vec3 sc=mod(id.x+id.y,2.0)<1.0?brt(uC1,0.4):uC2;
    vec3 c=d<0.0?sc:uC3;
    c=mix(c,mix(uC3,vec3(1.0),0.3),step(max(max(a.x,a.y),max(b.x,b.y)),0.09));   // le petit cœur
    vec2 cc=0.5-a; float corner=max(abs(cc.x+cc.y)*0.7071,0.0);
    c=mix(c,vec3(0.97,0.96,0.92),step(corner,0.06)*step(0.0,d));   // les petites croix aux coins
    c*=0.9+0.15*noise(vec3(p*3.0,cf.w));
    c=mix(vec3(0.95,0.93,0.88),c,smoothstep(0.004,0.018,abs(d)));
    return vec4(c, 200.0);
  }
// ===================== Rares =====================
#elif MODE==133
  { // lapis : une pierre profonde de la 1re couleur, veinée de la 2e et piquée de paillettes d'or de la 3e
    vec3 u=normalize(q); float n=fbm(u*3.0+so);
    vec3 c=mix(brt(uC1,0.3)*0.4,brt(uC1,0.3)*0.85,n)*(0.85+0.25*noise(u*20.0+so));
    float vein=smoothstep(0.05,0.0,abs(fbm(u*2.2+so+5.0)-0.5))*smoothstep(0.35,0.6,noise(u*3.0+so+2.0));
    c=mix(c,mix(uC2,vec3(0.95),0.4),vein*0.85);
    vec3 g=u*55.0+so; float py=step(0.88,h31(floor(g)))*step(0.45,noise(u*6.0+so+8.0));
    c=mix(c,mix(vec3(1.0,0.82,0.4),uC3,0.4)*(0.8+0.5*h31(floor(g)+1.0)),py);
    return vec4(c, 200.0);
  }
#elif MODE==134
  { // cloisonné : de l'émail de 3 couleurs coulé entre de fins fils d'or, avec des spirales d'or dans certaines cases
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(u*3.0+so,cid,d2);
    float k=h31(cid+4.0); vec3 ec=k<0.34?brt(uC1,0.4):(k<0.67?uC2:uC3);
    ec*=0.65+0.5*smoothstep(0.6,0.0,d1);
    float wire=smoothstep(0.04,0.018,d2-d1);
    float ring=smoothstep(0.022,0.01,abs(d1-0.17))*step(0.5,h31(cid+8.0));
    float dot1=smoothstep(0.05,0.035,d1)*step(0.5,h31(cid+8.0));
    vec3 gold=mix(vec3(0.95,0.75,0.35),vec3(1.0,0.92,0.62),noise(u*40.0+so));
    return vec4(mix(ec,gold,max(max(wire,ring),dot1)), 200.0);
  }
#elif MODE==135
  { // damas : un acier forgé en mille couches qui ondulent (miroir, au rendu), chaque couche teintée d'une des 3 couleurs
    float v=damasV(q); float m=mod(floor(v),3.0), b=fract(v);
    vec3 c=m<1.0?brt(uC1,0.5):(m<2.0?uC2:uC3);
    c=mix(vec3(0.7),c,0.5)*(0.6+0.4*smoothstep(0.0,0.2,b)*smoothstep(1.0,0.8,b));
    return vec4(c, 200.0);
  }
#elif MODE==136
  { // corail : trois coraux branchus (un par couleur du coloris) poussent sur le sable au fond d'un verre d'eau claire, et des bulles montent
    float r=length(q); q=q*0.8+vec3(0.0,-0.08,0.0); e=vec3(0.0);
    if(q.y<-0.5+0.03*noise(q*9.0+so)) return vec4(mix(vec3(0.93,0.86,0.7),uC3,0.2)*(0.85+0.2*noise(q*40.0)), 400.0);
    float best=9.0, bj=0.0;
    for(int j=0;j<3;j++){ float fj=float(j);
      vec3 B=vec3(-0.32+0.32*fj,-0.5,0.05*sin(fj*2.0));
      float d=sdCap(q,B,B+vec3(0.0,0.16,0.0),0.035);
      for(int k=0;k<5;k++){ float fk=float(k), a=-1.0+0.5*fk+0.3*(h31(so+fj*3.0+fk)-0.5);
        vec3 M=B+vec3(0.0,0.14,0.0), T=M+vec3(sin(a)*0.16,cos(a)*0.2+0.05,(h31(so+fj+fk*2.0)-0.5)*0.1);
        d=min(d,sdCap(q,M,T,0.022));
        vec3 T2=T+vec3(sin(a*1.6+0.4)*0.08,0.1,0.0), T3=T+vec3(sin(a*0.5-0.5)*0.08,0.09,0.02);
        d=min(d,sdCap(q,T,T2,0.015)); d=min(d,sdCap(q,T,T3,0.014)); }
      if(d<best){ best=d; bj=fj; } }
    if(best<0.0){ vec3 cc=bj<0.5?brt(uC1,0.45):(bj<1.5?uC2:uC3);
      float pore=step(0.6,noise(q*70.0+so));
      e=cc*0.15; return vec4(cc*(0.7+0.35*smoothstep(-0.5,0.0,q.y))*(1.0-0.2*pore), 400.0); }
    vec3 g=q*11.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(0.9,0.95,1.0)*step(0.97,h31(floor(g)))*smoothstep(0.12,0.06,abs(length(fc)-0.12))*1.5*step(-0.3,q.y);
    return vec4(mix(vec3(0.8,0.92,1.0),uC2,0.12), 0.2);
  }
#elif MODE==137
  { // kintsugi : un bol de céramique (1re couleur, piquée de la 2e) cassé puis réparé, ses fêlures remplies d'or (de la 3e)
    vec3 u=normalize(q); vec3 cid; float d2;
    float d1=vorF(u*1.6+so+0.12*vec3(noise(u*8.0+so),noise(u*8.0+so+3.0),noise(u*8.0+so+6.0)),cid,d2);
    vec3 gl=mix(brt(uC1,0.35)*0.7,uC2*0.8,0.3*smoothstep(0.4,0.8,fbm(u*3.0+so)));
    gl=mix(gl,uC2,step(0.93,h31(floor(u*70.0+so)))*0.7);
    gl*=0.85+0.2*noise(u*10.0+so);
    float seam=smoothstep(0.03,0.014,d2-d1+0.018*(noise(u*30.0+so)-0.5));
    vec3 gold=mix(vec3(1.0,0.8,0.35),uC3,0.3)*(0.9+0.3*noise(u*50.0+so));
    return vec4(mix(gl,gold,seam), 200.0);
  }
#elif MODE==138
  { // fluorite : un cristal fait de cubes emboîtés, couche après couche, de 3 couleurs transparentes
    vec3 qr=q; qr.xz=mrot(0.62)*qr.xz; qr.xy=mrot(0.5)*qr.xy;
    float v=max(abs(qr.x),max(abs(qr.y),abs(qr.z)))+0.025*noise(q*6.0+so);
    float b=v*7.0; float m=mod(floor(b),3.0);
    vec3 c=m<1.0?brt(uC1,0.45):(m<2.0?uC2:uC3);
    float edge=smoothstep(0.06,0.0,abs(fract(b)-0.5)-0.43);
    e=c*0.6*edge;
    return vec4(c, 1.6+6.0*edge);
  }
#elif MODE==139
  { // aquarelle : trois lavis de couleur posés sur un papier épais, qui se mélangent là où ils se touchent, plus foncés au bord
    vec3 u=normalize(q); vec3 c=vec3(0.98,0.97,0.94)*(0.94+0.06*noise(u*80.0+so));
    for(int i=0;i<3;i++){ float fi=float(i); float n=fbm(u*1.7+so+fi*11.0)+0.08*noise(u*12.0+fi);
      float a=smoothstep(0.55,0.57,n), edge=smoothstep(0.07,0.0,n-0.57)*a;
      vec3 pc=i==0?brt(uC1,0.4):(i==1?uC2:uC3);
      c*=mix(vec3(1.0),mix(vec3(1.0),pc,0.6+0.35*edge+0.1*noise(u*6.0+fi)),a); }
    return vec4(c, 200.0);
  }
// ===================== Épiques =====================
#elif MODE==140
  { // pissenlit : une boule de pissenlit dans un verre de soir, ses aigrettes de lumière (3e couleur), des graines qui s'envolent
    float r=length(q); vec3 p=q-vec3(0.0,0.06,0.0); e=vec3(0.0);
    vec3 fc=mix(uC3,vec3(1.0),0.45), c1=brt(uC1,0.45);
    for(int i=0;i<46;i++){ float fi=float(i)+0.5, y=1.0-2.0*fi/46.0, rr=sqrt(1.0-y*y), a=2.39996*fi;
      vec3 d=vec3(cos(a)*rr,y,sin(a)*rr); float on=step(-0.8,y);
      float t=clamp(dot(p,d)/0.34,0.0,1.0), ds=length(p-d*0.34*t);
      e+=fc*on*(exp(-ds*90.0)*4.0*(0.3+t)+exp(-length(p-d*0.34)*45.0)*6.0); }
    for(int i=0;i<5;i++){ float fi=float(i); vec3 P=vec3(0.32+0.09*fi,0.14+0.1*fi,0.12*sin(fi*2.0+so.x));
      e+=fc*exp(-length(q-P)*40.0)*7.0; }
    if(length(p)<0.065) return vec4(c1*0.55, 600.0);
    vec2 sp=vec2(q.x-0.03*sin(q.y*4.0),q.z);
    if(q.y<0.0 && q.y>-0.8 && length(sp)<0.02) return vec4(mix(c1,uC2,0.3)*0.5, 600.0);
    return vec4(mix(uC1*0.08,uC2*0.3,smoothstep(-0.8,0.7,q.y)), 0.45);
  }
#elif MODE==141
  { // voilier : un petit bateau à voiles sur les vagues dans un verre clair : la coque, les voiles (2e et 3e couleurs), la mer (1re)
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6));
    float wv=-0.2+0.025*sin(q.x*14.0+so.x)+0.018*sin(q.z*19.0+q.x*6.0+so.y)+0.02*(fbm(q*5.0+so)-0.5);
    if(q.y<wv){ float crest=smoothstep(-0.015,0.0,q.y-wv);
      vec3 w=mix(brt(uC1,0.45)*0.35,brt(uC1,0.45)*0.75,0.5+0.5*noise(q*12.0+so)); w=mix(w,vec3(0.95),crest*0.8);
      return vec4(w, 400.0); }
    // la coque
    vec3 h=q-vec3(0.0,-0.16,0.0);
    float hw=0.3*(1.0-pow(clamp((h.y+0.09)/0.13,0.0,1.0),2.0)*0.0)-0.12*clamp(-h.y/0.09,0.0,1.0);
    if(h.y>-0.09 && h.y<0.04 && abs(h.x+0.04*h.y)<hw+0.04*h.y && abs(h.z)<0.07*(1.0-pow(abs(h.x)/0.34,4.0))){
      vec3 c=h.y>0.01?vec3(0.95,0.93,0.88):mix(vec3(0.45,0.25,0.12),uC2,0.35);
      return vec4(c*(0.6+0.4*clamp(0.5+h.z*6.0,0.0,1.0)), 400.0); }
    // le mât
    if(length(q.xz-vec2(0.0,0.0))<0.014 && q.y>-0.13 && q.y<0.44) return vec4(vec3(0.4,0.28,0.15), 400.0);
    // les voiles, un peu gonflées
    float bel=0.05*sin(3.14159*clamp((q.y+0.1)/0.52,0.0,1.0));
    float y=q.y;
    if(abs(q.z-bel*smoothstep(0.0,0.2,q.x))<0.03 && y>-0.08 && y<0.42 && q.x>0.02 && q.x<0.28*(1.0-(y+0.08)/0.5)){
      vec3 c=mod(floor((y+0.08)/0.1),2.0)<1.0?uC3:vec3(0.97,0.96,0.92);
      return vec4(c*(0.75+0.3*(q.x/0.28)), 400.0); }
    if(abs(q.z-bel*0.7)<0.03 && y>-0.08 && y<0.38 && q.x<-0.02 && -q.x<0.22*(1.0-(y+0.08)/0.46)) return vec4(uC2*0.95, 400.0);
    if(q.y>0.42 && q.y<0.47 && q.x>0.0 && q.x<0.09 && abs(q.z)<0.03) return vec4(uC2, 400.0);   // le fanion
    float cloud=smoothstep(0.58,0.72,fbm(q*2.6+so))*smoothstep(0.95,0.75,r)*step(0.1,q.y);
    return vec4(mix(mix(vec3(0.72,0.86,1.0),uC3,0.12),vec3(1.0),cloud), 0.22+cloud*3.0);
  }
#elif MODE==142
  { // bonsaï : un petit arbre tordu dans son pot, au cœur d'un verre clair : le tronc, trois nuages de feuilles (2e couleur), des fleurs (3e), le pot (1re)
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6));
    vec3 c1=brt(uC1,0.45);
    // le pot
    vec3 pp=q-vec3(0.0,-0.44,0.0);
    if(abs(pp.y)<0.07 && length(pp.xz*vec2(1.0,1.5))<0.27-0.06*(pp.y+0.07)){ float sh=0.55+0.5*clamp(0.5+pp.x*-1.5+pp.z*1.5,0.0,1.0);
      return vec4(c1*sh*(abs(pp.y-0.055)<0.012?1.25:1.0), 400.0); }
    if(abs(pp.y-0.075)<0.012 && length(pp.xz*vec2(1.0,1.5))<0.24) return vec4(vec3(0.25,0.18,0.12), 400.0);   // la terre
    // le tronc et les branches
    float d=sdCap(q,vec3(0.02,-0.37,0.0),vec3(-0.1,-0.17,0.02),0.045);
    d=min(d,sdCap(q,vec3(-0.1,-0.17,0.02),vec3(0.06,0.0,0.0),0.038));
    d=min(d,sdCap(q,vec3(0.06,0.0,0.0),vec3(0.0,0.17,-0.02),0.03));
    d=min(d,sdCap(q,vec3(-0.1,-0.17,0.02),vec3(-0.25,-0.06,0.0),0.022));
    d=min(d,sdCap(q,vec3(0.06,0.0,0.0),vec3(0.24,0.06,0.02),0.022));
    if(d<0.0) return vec4(vec3(0.38,0.25,0.15)*(0.75+0.3*noise(q*vec3(30.0,8.0,30.0))), 400.0);
    // le feuillage
    float f=9.0;
    f=min(f,length((q-vec3(-0.27,-0.02,0.0))*vec3(1.0,1.6,1.2))-0.13);
    f=min(f,length((q-vec3(0.27,0.1,0.0))*vec3(1.0,1.6,1.2))-0.13);
    f=min(f,length((q-vec3(0.0,0.23,0.0))*vec3(1.0,1.5,1.2))-0.17);
    float leaf=noise(q*22.0+so);
    if(f+0.05*(leaf-0.5)<0.0 && leaf>0.25){ float fl=step(0.94,h31(floor(q*40.0+so)));
      float sh=0.5+0.6*smoothstep(-0.1,0.15,q.y-0.0+0.3*(leaf-0.5));
      vec3 c=mix(uC2*sh*(0.75+0.4*leaf),mix(uC3,vec3(1.0),0.3),fl);
      e=uC3*fl*0.8; return vec4(c, 400.0); }
    return vec4(mix(vec3(0.95,0.93,0.9),uC3,0.12), 0.18);
  }
#elif MODE==143
  { // nébuleuse : des nuages de gaz des 3 couleurs qui s'allument au fond d'un verre de nuit, traversés de poussière sombre, et de jeunes étoiles
    float r=length(q); vec3 w=q*1.8+so; w+=0.5*vec3(fbm(w),fbm(w+3.0),fbm(w+6.0));
    float a=smoothstep(0.45,0.8,fbm(w*1.3)), b=smoothstep(0.5,0.8,fbm(w*1.6+10.0)), c=smoothstep(0.52,0.85,fbm(w*2.0+20.0));
    float ins=smoothstep(0.9,0.55,r);
    float dk=smoothstep(0.58,0.72,fbm(w*2.5+30.0));
    e=(brt(uC1,0.4)*a*0.7+uC2*b*0.9+mix(uC3,vec3(1.0),0.2)*c*1.3)*ins*1.6*(1.0-0.85*dk);
    for(int i=0;i<6;i++){ float fi=float(i); vec3 P=(vec3(h31(so+fi*1.3),h31(so+fi*2.9),h31(so+fi*4.1))-0.5)*0.7;
      float d=length(q-P); e+=mix(vec3(1.0),uC3,0.3)*(exp(-d*90.0)*18.0+exp(-d*20.0)*0.6); }
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0;
    return vec4(uC1*0.06, 0.4+dk*1.5*ins);
  }
#elif MODE==144
  { // champignons : trois champignons lumineux sur un tapis de mousse, dans un verre de nuit, et des spores qui flottent
    float r=length(q); q=q*0.62+vec3(0.0,-0.12,0.0); vec3 L=normalize(vec3(-0.5,0.6,0.6)); e=vec3(0.0);
    float gy=-0.36+0.04*noise(q*5.0+so);
    if(q.y<gy) return vec4(mix(brt(uC1,0.3)*0.2,vec3(0.08,0.12,0.06),0.5)*(0.7+0.5*noise(q*30.0+so)), 400.0);
    for(int i=0;i<3;i++){ float fi=float(i);
      vec3 B=i==0?vec3(-0.2,-0.36,0.06):(i==1?vec3(0.06,-0.37,-0.03):vec3(0.27,-0.35,0.08));
      float H=i==0?0.24:(i==1?0.36:0.16), R=i==0?0.15:(i==1?0.2:0.1);
      vec3 cc=i==1?uC3:uC2; cc=mix(cc,vec3(1.0),0.15);
      vec3 p=q-B; p.x-=0.04*sin(p.y*6.0+fi);
      if(length(p.xz)<0.025+0.01*(1.0-p.y/H) && p.y>0.0 && p.y<H) { e=cc*0.15; return vec4(vec3(0.9,0.88,0.82)*(0.7+0.3*clamp(p.x*20.0+0.5,0.0,1.0)), 400.0); }
      vec3 cp=p-vec3(0.0,H,0.0); float ce=length(vec3(cp.x/R,cp.y/(R*0.62),cp.z/R));
      if(ce<1.0 && cp.y>-0.012){ float sp=step(0.75,noise(normalize(cp)*9.0+fi*5.0));
        vec3 c=mix(cc,mix(cc,vec3(1.0),0.7),sp);
        e=c*(0.6+0.8*smoothstep(0.5,0.0,cp.y/(R*0.62))); return vec4(c, 400.0); }
      e+=cc*exp(-length(cp*vec3(1.0,2.5,1.0))*8.0)*0.5;   // la lueur sous le chapeau
    }
    for(int i=0;i<12;i++){ float fi=float(i); vec3 P=vec3((h31(so+fi*1.7)-0.5)*1.0,-0.25+0.75*h31(so+fi*3.3),(h31(so+fi*5.1)-0.5)*0.6);
      e+=(mod(fi,2.0)<1.0?uC2:uC3)*exp(-length(q-P)*60.0)*3.0; }
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==145
  { // feu de camp : des bûches croisées au milieu d'un cercle de pierres, des flammes des 3 couleurs et des étincelles qui montent dans la nuit
    float r=length(q); q=q*0.62+vec3(0.0,-0.14,0.0); e=vec3(0.0);
    vec3 c1=brt(uC1,0.5), c3=mix(uC3,vec3(1.0,0.9,0.6),0.3);
    if(q.y<-0.48) return vec4(vec3(0.1,0.08,0.06)*(0.7+0.5*noise(q*20.0)), 400.0);
    // les pierres
    for(int i=0;i<9;i++){ float a=float(i)*0.6981317; vec3 C=vec3(cos(a)*0.32,-0.46,sin(a)*0.2);
      if(length((q-C)*vec3(1.0,1.4,1.0))<0.06){ return vec4(vec3(0.35,0.33,0.3)*(0.6+0.4*clamp(0.5-(q.x-C.x)*8.0,0.0,1.0))+c3*0.1, 400.0); } }
    // les bûches
    float d=sdCap(q,vec3(-0.25,-0.44,-0.1),vec3(0.18,-0.34,0.08),0.045);
    d=min(d,sdCap(q,vec3(0.24,-0.44,-0.08),vec3(-0.16,-0.33,0.1),0.045));
    d=min(d,sdCap(q,vec3(0.02,-0.45,0.22),vec3(0.0,-0.34,-0.2),0.04));
    if(d<0.0){ float glow=smoothstep(-0.35,-0.3,q.y); e=c3*glow*0.6; return vec4(vec3(0.3,0.18,0.1)*(0.7+0.3*noise(q*vec3(40.0,8.0,40.0)))+c3*glow*0.3, 400.0); }
    // les flammes
    float fy=(q.y+0.36)/0.55, wdt=0.2*pow(max(0.0,1.0-fy),0.8)*step(0.0,fy);
    float fl=smoothstep(1.0,0.2,length(q.xz*vec2(1.0,1.3))/max(wdt,0.001)+0.6*(fbm(q*6.0+so)-0.5))*step(fy,1.0);
    vec3 fc=fy<0.3?mix(vec3(1.0,0.97,0.9),c3,fy/0.3):(fy<0.65?mix(c3,uC2,(fy-0.3)/0.35):mix(uC2,c1,(fy-0.65)/0.35));
    e+=fc*fl*14.0*(1.0-0.5*fy);
    e+=c3*exp(-length(q-vec3(0.0,-0.3,0.0))*5.0)*0.5;
    for(int i=0;i<14;i++){ float fi=float(i); float t=h31(so+fi*2.3);
      vec3 P=vec3((h31(so+fi*1.1)-0.5)*0.3*(0.4+t),-0.15+0.75*t,(h31(so+fi*3.7)-0.5)*0.2);
      e+=c3*exp(-length(q-P)*80.0)*5.0*(1.0-t*0.6); }
    vec3 g=q*15.0+so; vec3 fc2=fract(g)-0.5;
    e+=vec3(step(0.975,h31(floor(g)))*smoothstep(0.2,0.0,length(fc2)))*4.0*step(0.2,q.y);
    return vec4(uC1*0.06, 0.45);
  }
// ===================== Légendaires =====================
#elif MODE==146
  { // saturne : la planète aux anneaux dans un verre de nuit : ses bandes (2e et 3e couleurs), ses anneaux (3e et 1re) et leur ombre, deux lunes
    float r=length(q); vec3 L=normalize(vec3(-0.6,0.45,0.65)); e=vec3(0.0);
    vec3 n=normalize(vec3(0.18,0.92,0.38)), c1=brt(uC1,0.45);
    float R=0.27;
    if(r<R){ vec3 nm=q/r; float lat=dot(nm,n)+0.03*noise(nm*6.0+so);
      float bd=sin(lat*26.0+so.x)*0.5+0.5;
      vec3 c=mix(uC2,mix(uC3,vec3(1.0),0.3),bd); c=mix(c,c1,smoothstep(0.7,0.95,sin(lat*9.0+1.0))*0.6);
      float sh=0.12+0.95*clamp(dot(nm,L),0.0,1.0);
      e=c*sh*0.5; return vec4(c*sh, 1000.0); }
    float h=dot(q,n), rr=length(q-n*h);
    if(rr>0.34 && rr<0.66){ float t=(rr-0.34)/0.32;
      float gap=smoothstep(0.0,0.02,abs(t-0.62)-0.03)*smoothstep(0.0,0.02,abs(t-0.25)-0.01);
      vec3 rc=mix(mix(uC3,vec3(1.0),0.2),c1,smoothstep(0.3,0.9,t)); rc*=0.75+0.25*sin(t*60.0+so.x);
      float tt=dot(-q,L); float sh=(tt>0.0 && length(q+L*tt)<R)?0.15:1.0;
      e+=rc*exp(-pow(h/0.018,2.0))*gap*sh*2.2; }
    for(int i=0;i<2;i++){ vec3 P=i==0?vec3(0.55,0.32,0.1):vec3(-0.5,-0.4,0.15);
      float d=length(q-P); if(d<0.035) return vec4(mix(uC2,vec3(0.8),0.5)*(0.3+0.8*clamp(dot((q-P)/d,L),0.0,1.0)), 1000.0); }
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0*step(0.55,r);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==147
  { // pyramides : trois pyramides sous la lune, dans le désert la nuit : la pierre (1re couleur) éclairée de la 3e, les dunes (2e)
    float r=length(q); q=q*0.66+vec3(0.0,-0.1,0.0); e=vec3(0.0);
    vec3 c1=brt(uC1,0.5), lc=mix(uC3,vec3(1.0),0.3);
    float dy=-0.3+0.04*sin(q.x*6.0+so.x)+0.03*sin(q.z*8.0+q.x*3.0)+0.02*noise(q*8.0);
    if(q.y<dy) return vec4(mix(uC2,vec3(0.9,0.8,0.6),0.3)*(0.45+0.3*smoothstep(-0.35,-0.25,q.y)+0.15*noise(q*30.0)), 400.0);
    for(int i=0;i<3;i++){ vec3 C=i==0?vec3(-0.05,-0.33,-0.05):(i==1?vec3(0.33,-0.32,0.1):vec3(-0.38,-0.32,0.15));
      float S=i==0?0.34:(i==1?0.2:0.16), H=S*1.15;
      vec3 p=q-C; float k=1.0-p.y/H;
      if(p.y>0.0 && p.y<H && max(abs(p.x),abs(p.z))<S*k){
        float lit=abs(p.x)>abs(p.z)?(p.x<0.0?1.0:0.35):(p.z>0.0?0.7:0.25);
        vec3 c=c1*(0.35+0.25*lit)+lc*0.45*lit;
        c*=0.85+0.15*step(0.5,fract(p.y*55.0));
        return vec4(c, 400.0); } }
    // la lune
    vec3 M=vec3(0.32,0.38,-0.25); float dm=length(q.xy-M.xy);
    e+=lc*(smoothstep(0.1,0.09,dm)*3.0*exp(-pow((q.z-M.z)/0.06,2.0))+exp(-dm*9.0)*0.35);
    vec3 g=q*15.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.97,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0*step(-0.1,q.y);
    return vec4(mix(uC1*0.06,uC2*0.18,smoothstep(0.3,-0.3,q.y)), 0.45);
  }
#elif MODE==148
  { // baleine : une baleine passe dans un verre d'eau profonde, sous les rayons de lumière : son dos (2e couleur), son ventre rayé (3e), l'eau (1re)
    float r=length(q); vec3 L=normalize(vec3(-0.3,0.9,0.4)); e=vec3(0.0);
    vec3 c1=brt(uC1,0.45);
    vec3 p=q-vec3(0.02,-0.02,0.0); p.y-=0.25*p.x*p.x-0.04;
    vec3 rad=vec3(0.4,0.13,0.13)*vec3(1.0,1.0-0.45*smoothstep(0.0,-0.4,p.x),1.0-0.45*smoothstep(0.0,-0.4,p.x));
    float eb=length(p/rad);
    // la queue
    vec3 tq=p-vec3(-0.44,0.0,0.0); float tail=step(abs(tq.z),0.04)*step(tq.x,0.04)*step(-0.05-0.5*abs(tq.y),tq.x)*step(abs(tq.y),0.03+1.3*max(-tq.x,0.0));
    // la nageoire
    vec3 fq=p-vec3(0.12,-0.1,0.1); float fin=step(length(vec3(fq.x+fq.y*0.5,fq.y,fq.z)/vec3(0.09,0.03,0.03)),1.0);
    if(eb<1.0 || tail>0.5 || fin>0.5){
      vec3 nn=normalize(p/(rad*rad)); float sh=0.35+0.75*clamp(dot(nn,L),0.0,1.0);
      float belly=smoothstep(0.0,-0.5,nn.y);
      vec3 c=mix(mix(uC2,vec3(0.2),0.35),mix(uC3,vec3(1.0),0.35)*(0.8+0.2*step(0.5,fract(p.y*55.0))),belly*step(-0.3,p.x));
      if(length(p.xy-vec2(0.28,-0.02))<0.014 && p.z>0.0) c=vec3(0.03);
      return vec4(c*sh, 400.0); }
    // les rayons de lumière, les bulles
    float ray=pow(noise(vec3(q.x*5.0+q.y*1.5,q.z*5.0,so.x)),3.0)*smoothstep(-0.6,0.6,q.y);
    e+=mix(uC3,vec3(1.0),0.5)*ray*0.9;
    for(int i=0;i<8;i++){ float fi=float(i); vec3 P=vec3(0.24+0.03*sin(fi*2.0),0.1+fi*0.07,0.0);
      e+=vec3(0.85,0.95,1.0)*smoothstep(0.02,0.0,abs(length(q-P)-0.012-0.004*fi))*2.0; }
    vec3 g=q*13.0+so; vec3 fc=fract(g)-0.5;
    e+=uC3*step(0.98,h31(floor(g)))*smoothstep(0.2,0.0,length(fc))*1.5;
    return vec4(mix(c1*0.08,c1*0.3,smoothstep(-0.8,0.8,q.y)), 0.6);
  }
#elif MODE==149
  { // diamant : un diamant taillé en brillant flotte dans un écrin de velours (1re couleur) ; ses facettes lancent des feux des 3 couleurs
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.7,0.6)); e=vec3(0.0);
    vec3 p=q; p.yz=mrot(-0.45)*p.yz; p.xz=mrot(0.3+so.x*0.0)*p.xz;
    float a=atan(p.z,p.x), seg=floor(a/0.7853982+0.5), a0=seg*0.7853982;
    vec2 dr=vec2(cos(a0),sin(a0));
    float rr=dot(p.xz,dr);
    float table=p.y-0.1, crown=rr*0.7+p.y*0.72-0.27, girdle=length(p.xz)-0.34, pav=rr*0.76-p.y*0.66-0.24;
    float a1=floor(a/0.7853982)*0.7853982+0.3927; vec2 dr2=vec2(cos(a1),sin(a1)); float star=dot(p.xz,dr2)*0.45+p.y*0.9-0.205;
    float dd=max(max(max(table,crown),max(girdle,pav)),star);
    if(dd<0.0){ float id=0.0;
      if(dd==table) id=0.0; else if(dd==crown) id=1.0+seg; else if(dd==star) id=20.0+seg; else id=40.0+seg;
      float k=h31(vec3(id,1.0,so.y)); vec3 fc=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3);
      float br=pow(h31(vec3(id,2.0,so.y)),2.0);
      vec3 c=mix(vec3(0.9,0.93,1.0),fc,0.55)*(0.35+1.1*br);
      e=c*0.5+vec3(1.0)*smoothstep(0.004,0.0,-dd)*1.5;
      return vec4(c, 1000.0); }
    for(int i=0;i<5;i++){ float fi=float(i); vec3 P=vec3((h31(so+fi*1.3)-0.5)*1.0,(h31(so+fi*2.9)-0.5)*1.0,0.2);
      vec2 dq=abs(q.xy-P.xy); float gl=exp(-dq.x*90.0)*exp(-dq.y*7.0)+exp(-dq.y*90.0)*exp(-dq.x*7.0);
      e+=mix(vec3(1.0),uC3,0.3)*gl*exp(-pow((q.z-P.z)/0.1,2.0))*3.0*step(0.45,length(P.xy)); }
    float vel=0.7+0.3*noise(q*25.0+so);
    return vec4(brt(uC1,0.3)*0.12*vel, 0.45);
  }
// ===================== Mythiques (animés, une boucle de MYTH_T secondes : lp fait un tour, 2π) =====================
#elif MODE==155
  { // astrolabe : une sphère armillaire tourne dans le verre : trois anneaux d'or (de la 3e couleur) gradués qui pivotent chacun sur son axe,
    // un petit soleil (2e couleur) au centre qui respire, une planète qui fait le tour de l'écliptique et des signes du zodiaque (1re couleur)
    float t=mod(uTime,3.9269908), lp=t*1.6; e=vec3(0.0);
    float r=length(q); vec3 L=normalize(vec3(-0.5,0.6,0.6));
    vec3 gold=mix(vec3(1.0,0.82,0.42),uC3,0.45), c1=brt(uC1,0.45);
    float best=9.0; vec3 bn=vec3(0.0); float bid=0.0, ba=0.0;
    for(int i=0;i<3;i++){ float fi=float(i);
      vec3 ax=i==0?vec3(sin(lp),0.0,cos(lp)):(i==1?normalize(vec3(0.0,cos(lp*-1.0+0.6),sin(lp*-1.0+0.6))):normalize(vec3(0.4,0.92,0.2)));
      float R=i==0?0.62:(i==1?0.5:0.4);
      float h=dot(q,ax); vec3 pr=q-ax*h; float rho=length(pr);
      float d=length(vec2(rho-R,h*1.0))-0.028;
      if(d<best){ best=d; bid=fi; bn=normalize(vec3(0.0)+(pr/max(rho,1e-4))*(rho-R)+ax*h+1e-5);
        vec3 b1=normalize(cross(ax,vec3(0.3,0.7,0.1))); ba=atan(dot(pr,cross(ax,b1)),dot(pr,b1))-(i==2?lp*2.0:0.0); } }
    if(best<0.0){ float tick=step(0.75,fract(ba/6.2831853*36.0))*step(0.5,0.5);
      float sh=0.35+0.8*clamp(dot(bn,L),0.0,1.0);
      vec3 c=gold*sh+vec3(1.0)*pow(clamp(dot(reflect(-L,bn),vec3(0.0,0.0,1.0)),0.0,1.0),20.0)*0.8;
      c=mix(c,bid>1.5?c1:gold*0.4,tick*0.85);
      if(bid>1.5){ float zs=step(0.85,fract(ba/6.2831853*12.0)); e=c1*zs*2.0; }
      return vec4(c, 600.0); }
    // la planète sur l'écliptique (l'anneau du milieu), qui fait deux tours par boucle
    vec3 ax3=normalize(vec3(0.4,0.92,0.2)), b1=normalize(cross(ax3,vec3(0.3,0.7,0.1))), b2=cross(ax3,b1);
    vec3 PL=(b1*cos(lp*2.0+1.0)+b2*sin(lp*2.0+1.0))*0.4;
    float dp=length(q-PL); if(dp<0.05) return vec4(c1*(0.3+0.9*clamp(dot((q-PL)/dp,L),0.0,1.0)), 800.0);
    // le soleil du centre
    float pulse=0.8+0.2*sin(lp*3.0);
    float ds=length(q); if(ds<0.11){ e=mix(vec3(1.0),uC2,0.4)*4.0*pulse; return vec4(mix(vec3(1.0),uC2,0.5), 800.0); }
    float ang=atan(q.y,q.x);
    e+=uC2*exp(-(ds-0.11)*10.0)*1.2*pulse*(0.75+0.25*sin(ang*12.0+lp*2.0));
    e+=c1*exp(-abs(r-0.62)*25.0)*0.15;
    vec3 g=q*14.0+so; vec3 fc=fract(g)-0.5;
    e+=vec3(step(0.972,h31(floor(g)))*smoothstep(0.2,0.0,length(fc)))*5.0*step(0.66,r);
    return vec4(uC1*0.08, 0.4);
  }
#elif MODE==156
  { // kraken : six tentacules s'enroulent autour d'un gouffre au fond du verre et ondulent sans fin ; ventouses de lumière (3e couleur),
    // tentacules de la 1re et de la 2e couleur, gueule qui luit au centre ; ils tournent d'un tiers de tour par boucle
    float t=mod(uTime,3.9269908), lp=t*1.6; e=vec3(0.0);
    float h=q.z; vec2 p=q.xy*1.15; float rr=length(p)+1e-4, a=atan(p.y,p.x);
    float lay=exp(-h*h/0.006);
    vec3 c1=brt(uC1,0.45), c3=mix(uC3,vec3(1.0),0.25);
    float lr=log(rr);
    float best=9.0; float bk=0.0, bs=0.0, bw=1.0;
    for(int i=0;i<6;i++){ float fi=float(i);
      float a0=fi*1.0471976+lp/3.0;
      float curl=2.2+0.5*sin(lp+fi*3.14159);   // les bras pairs et impairs ondulent à contretemps : au bout d'une boucle, chaque bras a pris la place de celui d'après-après
      float th=a0-curl*lr+0.25*sin(lr*3.0-lp+fi*3.14159);   // la spirale du bras, qui ondule
      float da=mod(a-th+3.14159,6.2831853)-3.14159;
      float wdt=0.17*smoothstep(0.9,0.12,rr)*smoothstep(0.03,0.12,rr)+0.004;
      float d=abs(da)*rr/wdt;
      if(d<best){ best=d; bk=fi; bs=da; bw=wdt; } }
    vec3 col=c1*0.05; float den=0.5;
    if(best<1.0){ float side=bs>0.0?1.0:-1.0;
      vec3 tc=mod(bk,2.0)<1.0?c1:uC2;
      float sh=0.45+0.6*sqrt(1.0-best*best)*(0.7+0.3*side);
      float sk=fract(lr*7.0+mod(bk,2.0)*0.3);
      float suck=step(0.25,best)*step(best,0.85)*step(0.0,-bs)*smoothstep(0.32,0.2,abs(sk-0.5));
      col=mix(tc*sh,c3,suck); e+=c3*suck*3.0*lay+tc*0.1*lay; den=600.0*lay; }
    // la gueule au centre
    e+=c3*exp(-rr*14.0)*3.0*lay*(0.8+0.2*sin(lp*2.0)) + uC2*exp(-rr*5.0)*0.6*lay;
    float teeth=smoothstep(0.02,0.0,abs(rr-0.075))*step(0.5,fract(a/6.2831853*14.0+lp/6.2831853*2.0));
    e+=c3*teeth*4.0*lay;
    // l'eau noire, des bulles qui montent d'une case par boucle
    for(int i=0;i<10;i++){ float fi=float(i); float y=fract(h31(so+fi*1.9)+lp/6.2831853);
      vec3 P=vec3((h31(so+fi*3.1)-0.5)*1.1,-0.65+1.3*y,(h31(so+fi*4.7)-0.5)*0.5);
      e+=mix(uC2,vec3(1.0),0.4)*smoothstep(0.012,0.0,abs(length(q-P)-0.022))*2.0*sin(3.14159*y); }
    return vec4(col, den>1.0?den:0.4);
  }
