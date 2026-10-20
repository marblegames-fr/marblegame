#elif MODE==65
  { // tricolore : trois bandes égales qui font le tour de la bille, comme un drapeau enroulé
    vec3 u=normalize(q); float y=u.y+0.035*sin(atan(u.z,u.x)*3.0+so.x);
    vec3 c=y>0.33?uC1:(y<-0.33?uC2:uC3);
    float ed=min(abs(y-0.33),abs(y+0.33));
    c*=mix(0.8,1.0,smoothstep(0.004,0.022,ed));
    return vec4(c, 200.0);
  }
#elif MODE==66
  { // sucette : une spirale de sucre en trois couleurs qui part du centre de la bille, comme une sucette de fête foraine
    vec3 u=normalize(q); float th=acos(clamp(u.z,-1.0,1.0)), ph=atan(u.y,u.x);
    float s=ph/6.2831853*4.0+th*(3.6+nb*0.4);
    float m=mod(floor(s),4.0); vec3 c=m<1.0?uC1:(m<2.0?vec3(0.98,0.97,0.95):(m<3.0?uC2:uC3));
    float fs=fract(s); c*=mix(0.82,1.0,smoothstep(0.0,0.12,fs))*mix(1.0,0.92,smoothstep(0.75,1.0,fs));
    c=mix(c,vec3(1.0),0.5*smoothstep(0.28,0.0,th));   // le petit bout blanc au centre
    return vec4(c, 200.0);
  }
#elif MODE==67
  { // fleurettes : de petites fleurs à cinq pétales semées sur un fond clair, avec leur cœur (deux semis décalés : il y en a partout)
    vec3 u=normalize(q); vec3 t1=normalize(cross(u,vec3(0.0,1.0,0.013))), t2=cross(u,t1);
    vec3 bg=mix(uC2,vec3(0.98,0.97,0.94),0.78), c=bg;
    for(int i=0;i<2;i++){ vec3 g=u*2.4+so+float(i)*vec3(0.5,0.37,0.61); vec3 id=floor(g)+float(i)*31.0, f=fract(g)-0.5;
      vec2 p=vec2(dot(f,t1),dot(f,t2)); float L=length(p), a=atan(p.y,p.x)+h31(id+5.0)*6.2831853;
      float on=step(0.15,h31(id))*step(abs(dot(f,u)),0.22), sz=0.17+0.08*h31(id+3.0);
      float pet=sz*(0.5+0.5*pow(abs(cos(a*2.5)),0.6));
      float fl=smoothstep(pet+0.012,pet-0.012,L)*on;
      float ctr=smoothstep(sz*0.3+0.012,sz*0.3-0.012,L)*on;
      vec3 pc=h31(id+2.0)<0.6?uC1:vec3(0.99,0.98,0.97);
      c=mix(c,pc*mix(0.85,1.0,smoothstep(0.0,pet,L)),fl);
      c=mix(c,mix(uC3,vec3(1.0,0.82,0.25),0.45),ctr); }
    return vec4(c, 200.0);
  }
#elif MODE==68
  { // girafe : de grandes taches aux coins arrondis, séparées par des chemins clairs
    vec3 u=normalize(q); vec3 g=u*(1.9+nb*0.15)+so; vec3 i0=floor(g), f0=fract(g);
    float d1=9.0, d2=9.0; vec3 cid=vec3(0.0);
    for(int x=-1;x<=1;x++) for(int y=-1;y<=1;y++) for(int z=-1;z<=1;z++){ vec3 o=vec3(float(x),float(y),float(z));
      vec3 pt=o+0.15+0.7*vec3(h31(i0+o),h31(i0+o+7.1),h31(i0+o+3.3)); float d=length(pt-f0);
      if(d<d1){ d2=d1; d1=d; cid=i0+o; } else if(d<d2) d2=d; }
    float ed=d2-d1+0.07*(noise(g*3.0)-0.5);
    float pat=smoothstep(0.07,0.1,ed);
    vec3 pc=mix(uC1,uC2,0.45*h31(cid+1.0))*(0.8+0.25*smoothstep(0.15,0.5,ed))*(0.92+0.12*noise(g*9.0));
    vec3 cream=mix(uC3,vec3(0.98,0.94,0.84),0.72);
    return vec4(mix(cream,pc,pat), 200.0);
  }
#elif MODE==69
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
#elif MODE==70
  { // briques : un mur de briques bien rangées, décalées d'un rang à l'autre, avec leur ciment
    vec3 u=normalize(q); float lat=asin(clamp(u.y,-1.0,1.0)); float R=8.0+nb;
    float rf=(lat/3.14159265+0.5)*R, row=floor(rf), fy=fract(rf);
    float lc=((row+0.5)/R-0.5)*3.14159265, nk=max(1.0,floor(R*1.15*cos(lc)+0.5));
    float cf=(atan(u.z,u.x)/6.2831853+0.5)*nk+mod(row,2.0)*0.5+h31(vec3(row,so.x,1.0)), fx=fract(cf);
    vec3 bid=vec3(row,mod(floor(cf),nk),so.y);
    float mx=min(fx,1.0-fx)*6.2831853*max(cos(lat),0.05)/nk, my=min(fy,1.0-fy)*3.14159265/R;
    float mort=smoothstep(0.014,0.03,min(mx,my));
    float hb=h31(bid);
    vec3 br=(hb<0.6?uC1:(hb<0.85?uC2:uC3))*(0.78+0.3*h31(bid+2.0))*(0.88+0.18*noise(u*35.0+so));
    br*=mix(0.85,1.0,smoothstep(0.03,0.07,min(mx,my)));   // l'arête de la brique, un peu plus sombre
    vec3 cem=mix(vec3(0.86,0.84,0.8),uC3,0.3)*(0.9+0.1*noise(u*80.0));
    return vec4(mix(cem,br,mort), 200.0);
  }
#elif MODE==71
  { // puzzle : des pièces de puzzle de trois couleurs, chacune avec ses tenons et ses creux
    vec3 u=normalize(q); vec4 cf=cubeF(u); float N=2.0+floor(nb*0.5);
    vec2 G=(cf.xy*0.5+0.5)*N; vec2 id=min(floor(G),N-1.0), p=G-id;
    vec2 own=id; float dmin=9.0, r=0.17;
    for(int k=0;k<4;k++){
      vec2 n=k==0?vec2(1.0,0.0):(k==1?vec2(-1.0,0.0):(k==2?vec2(0.0,1.0):vec2(0.0,-1.0)));
      vec2 nb2=id+n; float edge=k<2?(n.x>0.0?1.0:0.0):(n.y>0.0?1.0:0.0);
      bool border=nb2.x<0.0||nb2.y<0.0||nb2.x>N-1.0||nb2.y>N-1.0;   // au bord d'une face du cube : pas de tenon
      vec2 em=k<2?vec2(edge,0.5):vec2(0.5,edge);
      float dl=k<2?abs(p.x-edge):abs(p.y-edge);
      if(border){ dmin=min(dmin,dl); continue; }
      vec2 eid=min(id,nb2)+abs(n)*0.5;   // le même identifiant vu des deux pièces
      float sgn=h31(vec3(eid*7.3,cf.w+so.x))<0.5?1.0:-1.0; sgn*=n.x+n.y;   // tiré une fois par bord (vu de la pièce du bas ou de gauche), puis retourné pour l’autre côté ; +1 : le tenon part chez la voisine ; -1 : celui de la voisine entre chez nous
      vec2 c=em+n*sgn*0.13; float Lk=length(p-c);
      vec2 pr=k<2?vec2(edge,p.y):vec2(p.x,edge);
      if(length(pr-c)>r) dmin=min(dmin,dl);
      if(sgn<0.0){ dmin=min(dmin,abs(Lk-r)); if(Lk<r) own=nb2; }
    }
    float par=mod(own.x+own.y*2.0+cf.w,3.0);
    vec3 c=par<1.0?uC1:(par<2.0?uC2:mix(uC3,vec3(0.97,0.95,0.9),0.3));
    c*=mix(0.75,1.0,smoothstep(0.0,0.09,dmin))*(0.95+0.07*noise(u*30.0+so));
    c=mix(c*0.35,c,smoothstep(0.008,0.022,dmin));
    return vec4(c, 200.0);
  }
#elif MODE==72
  { // labyrinthe : des murs en diagonale, au hasard d'une case à l'autre, qui dessinent des couloirs sans fin
    vec3 u=normalize(q); vec4 cf=cubeF(u); float N=4.0+nb;
    vec2 G=(cf.xy*0.5+0.5)*N; vec2 id=min(floor(G),N-1.0), p=G-id;
    float fl=h31(vec3(id*3.1,cf.w*7.0+so.x));
    float d=fl<0.5?abs(p.x-p.y):abs(p.x+p.y-1.0); d*=0.7071;
    float wall=smoothstep(0.1,0.075,d);
    vec3 floorc=mix(uC3,vec3(0.98,0.97,0.94),0.6);
    vec3 wc=mix(uC1,uC2,smoothstep(0.075,0.0,d)*0.45);
    float sh=smoothstep(0.24,0.1,d)*0.18;   // l'ombre du mur sur le sol
    return vec4(mix(floorc*(1.0-sh),wc,wall), 200.0);
  }
#elif MODE==73
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
#elif MODE==74
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
#elif MODE==75
  { // sable : des couches de sable coloré qui ondulent, comme dans une bouteille de sable des vacances
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float h=u.y*(2.6+nb*0.3)+0.45*fbm(u*1.6+so)+0.12*sin(lon*2.0+so.x);
    float b=floor(h*2.0), fh=fract(h*2.0);
    float m=mod(b,4.0); vec3 c=m<1.0?uC1:(m<2.0?vec3(0.96,0.92,0.84):(m<3.0?uC2:uC3));
    c*=0.82+0.3*noise(u*140.0+so)*noise(u*37.0+so);   // le grain du sable
    c*=mix(0.88,1.0,smoothstep(0.0,0.08,fh));
    return vec4(c, 200.0);
  }
