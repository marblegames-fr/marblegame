// (6 novembre 2026, 4e partie) encore des Épiques (255 à 275), des Légendaires (276 à 287) et des Mythiques animés (288 à 290), tous dans le verre
// ===================== Épiques =====================
#elif MODE==255
  { // île : une petite île de sable (3e couleur) avec son palmier (2e) au milieu d'une mer de la 1re, sous le soleil
    float r=length(q); q=q*0.85; e=vec3(0.0);
    float wv=-0.22+0.015*sin(q.x*16.0+so.x)+0.012*sin(q.z*20.0);
    float isl=length((q-vec3(0.0,-0.3,0.0))*vec3(1.0,2.2,1.4))-0.28;
    if(isl<0.0) return vec4(mix(uC3,vec3(0.95,0.87,0.65),0.5)*(0.8+0.25*noise(q*40.0)), 400.0);
    if(q.y<wv) return vec4(brt(uC1,0.45)*(0.45+0.35*noise(q*10.0+so))+vec3(0.9)*smoothstep(-0.01,0.0,q.y-wv)*0.6, 400.0);
    vec3 t0=vec3(0.02,-0.2,0.0), t1=vec3(0.07,0.0,0.0), t2=vec3(0.03,0.2,0.0);
    float d=min(sdCap(q,t0,t1,0.025),sdCap(q,t1,t2,0.02));
    if(d<0.0) return vec4(vec3(0.5,0.35,0.2)*(0.8+0.2*step(0.5,fract(q.y*40.0))), 400.0);
    for(int i=0;i<6;i++){ float a=float(i)*1.0472+0.3; vec3 dir=vec3(cos(a),-0.25,sin(a)*0.6);
      vec3 pa=q-t2; float t=clamp(dot(pa,dir)/0.22,0.0,1.0); vec3 pp=t2+dir*0.22*t+vec3(0.0,-0.12*t*t,0.0);
      if(length(q-pp)<0.035*(1.0-t*0.7)) return vec4(uC2*(0.6+0.4*t), 400.0); }
    e=mix(uC3,vec3(1.0,0.9,0.6),0.4)*(exp(-length(q-vec3(-0.35,0.32,-0.2))*10.0)*2.5);
    return vec4(mix(vec3(0.75,0.88,1.0),uC3,0.1), 0.2);
  }
#elif MODE==256
  { // montagne : des sommets enneigés sous la nuit, la roche de la 1re couleur, la neige bleutée de la 2e, une lune de la 3e
    float r=length(q); e=vec3(0.0);
    float h=-0.05+0.42*(1.0-abs(q.x+0.08)*1.6)+0.18*(1.0-abs(q.x-0.32)*3.0)*step(0.0,q.x)+0.06*(fbm(vec3(q.x*6.0,0.0,q.z*6.0)+so)-0.5)-abs(q.z)*0.5;
    if(q.y<max(h,-0.45)){ float snow=smoothstep(h-0.12,h-0.06,q.y)*step(0.0,q.y+0.05*noise(q*20.0));
      vec3 rock=brt(uC1,0.4)*0.35*(0.7+0.5*noise(q*25.0+so));
      return vec4(mix(rock,mix(uC2,vec3(1.0),0.6),snow)*(q.x<-0.08?1.0:0.65), 400.0); }
    vec3 M=vec3(0.35,0.35,-0.2); float dm=length(q.xy-M.xy);
    e+=mix(uC3,vec3(1.0),0.4)*(smoothstep(0.08,0.07,dm)*3.0*exp(-pow((q.z-M.z)/0.06,2.0))+exp(-dm*8.0)*0.3);
    e+=starsE(q,0.5)*step(0.0,q.y);
    return vec4(mix(uC1*0.06,uC2*0.15,smoothstep(0.5,-0.3,q.y)), 0.45);
  }
#elif MODE==257
  { // cerf-volant : un cerf-volant en losange de 4 couleurs (les 3 du coloris et du blanc) dans un ciel de nuages, avec sa queue à nœuds
    float r=length(q); e=vec3(0.0); vec3 p=q-vec3(0.05,0.12,0.0);
    vec2 k=mrot(0.25)*p.xy;
    if(abs(p.z)<0.03 && abs(k.x)/0.2+abs(k.y-0.05*sign(k.y))/(k.y>0.0?0.22:0.34)<1.0){
      float qd=(k.x>0.0?1.0:0.0)+(k.y>0.0?2.0:0.0);
      vec3 c=qd<0.5?brt(uC1,0.45):(qd<1.5?uC2:(qd<2.5?uC3:vec3(0.97)));
      return vec4(c*(abs(k.x)<0.008||abs(k.y)<0.008?0.5:1.0), 400.0); }
    vec2 tl=mrot(0.25)*vec2(0.0,-0.34)+vec2(0.05,0.12);
    for(int i=0;i<6;i++){ float t=float(i)/5.0; vec2 P=tl+vec2(0.08*sin(t*5.0),-0.07*float(i));
      if(length(vec3(q.xy-P,q.z))<0.028) return vec4(mod(float(i),3.0)<1.0?uC2:(mod(float(i),3.0)<2.0?uC3:brt(uC1,0.45)), 400.0); }
    float cloud=smoothstep(0.58,0.72,fbm(q*2.6+so))*smoothstep(0.95,0.75,r);
    return vec4(mix(mix(vec3(0.7,0.85,1.0),uC2,0.1),vec3(1.0),cloud), 0.22+cloud*3.0);
  }
#elif MODE==258
  { // moulin : un moulin à vent sur sa colline (2e couleur), le toit et les ailes de la 1re, la porte et les fenêtres de la 3e
    float r=length(q); vec3 c1=brt(uC1,0.45);
    if(q.y<-0.38+0.1*(1.0-q.x*q.x*3.0)*0.0-0.06*q.x) return vec4(uC2*(0.6+0.3*noise(q*20.0)), 400.0);
    float y=q.y+0.38, rt=0.13-0.05*y/0.5;
    if(y>0.0 && y<0.5 && length(q.xz)<rt){ vec3 c=vec3(0.92,0.9,0.85)*(0.6+0.5*clamp(0.5-q.x*4.0+q.z*2.0,0.0,1.0));
      if(q.z>0.0 && abs(q.x)<0.035 && y<0.1) c=uC3*0.7; if(q.z>0.0 && abs(q.x)<0.02 && abs(y-0.3)<0.03) c=uC3;
      return vec4(c, 400.0); }
    if(y>0.5 && y<0.62 && length(q.xz)<0.09*(1.0-(y-0.5)/0.12)) return vec4(c1*0.7, 400.0);
    vec3 hub=vec3(0.0,0.1,0.12); vec2 b=q.xy-hub.xy;
    if(abs(q.z-0.12)<0.03){ for(int i=0;i<4;i++){ vec2 bb=mrot(float(i)*1.5708+0.4)*b;
      if(bb.x>0.02 && bb.x<0.34 && abs(bb.y-0.03)<0.035) return vec4(mix(c1,vec3(0.9),step(0.5,fract(bb.x*25.0))*0.5), 400.0); } }
    float cloud=smoothstep(0.6,0.72,fbm(q*2.5+so))*smoothstep(0.95,0.75,r);
    return vec4(mix(vec3(0.72,0.86,1.0),vec3(1.0),cloud), 0.2+cloud*3.0);
  }
#elif MODE==259
  { // igloo : un igloo de blocs de glace sur la banquise, sa porte éclairée, et une aurore de la 2e et de la 3e couleur dans le ciel
    float r=length(q); e=vec3(0.0); vec3 p=q-vec3(0.0,-0.3,0.0);
    if(q.y<-0.3) return vec4(mix(vec3(0.9,0.94,1.0),uC2,0.12)*(0.85+0.15*noise(q*20.0)), 400.0);
    float L=length(p);
    if(L<0.3){ vec3 n=p/L; float lat=asin(n.y), lon=atan(n.z,n.x);
      float row=floor(lat*9.0), joint=min(abs(fract(lat*9.0)-0.5),abs(fract(lon*6.0+row*0.5)-0.5));
      vec3 c=mix(vec3(0.92,0.95,1.0),uC2,0.15)*lit(n)*mix(0.7,1.0,smoothstep(0.0,0.06,joint));
      if(n.z>0.6 && abs(n.x)<0.25 && n.y<0.35){ c=mix(uC3,vec3(1.0,0.8,0.5),0.4)*1.2; e=c; }
      return vec4(c, 400.0); }
    float aur=smoothstep(0.03,0.0,abs(q.y-0.3-0.08*sin(q.x*6.0+so.x)-0.05*fbm(q*4.0)))*0.0+exp(-pow((q.y-0.28-0.08*sin(q.x*5.0+so.x))/0.08,2.0))*step(-0.2,q.y);
    e=mix(uC2,uC3,0.5+0.5*sin(q.x*4.0))*aur*(0.6+0.4*noise(vec3(q.x*20.0,0.0,so.y)))*1.5+starsE(q,0.5);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==260
  { // dirigeable : un ballon dirigeable rayé de la 1re et de la 2e couleur, ses ailerons et sa nacelle de la 3e, entre les nuages
    float r=length(q); vec3 p=q-vec3(0.0,0.08,0.0);
    float eb=length(p/vec3(0.42,0.17,0.17));
    if(eb<1.0){ vec3 n=normalize(p/vec3(0.1764,0.0289,0.0289)); float a=atan(p.z,p.y);
      vec3 c=mod(floor(a*6.0/3.14159+6.0),2.0)<1.0?brt(uC1,0.45):uC2;
      return vec4(c*lit(n), 400.0); }
    vec3 t=p-vec3(-0.38,0.0,0.0);
    if(t.x<0.08 && t.x>-0.08 && ((abs(t.z)<0.02 && abs(t.y)<0.17-abs(t.x)*0.6) || (abs(t.y)<0.02 && abs(t.z)<0.17-abs(t.x)*0.6))) return vec4(uC3, 400.0);
    vec3 g=p-vec3(0.05,-0.22,0.0); if(abs(g.x)<0.09 && abs(g.y)<0.035 && abs(g.z)<0.04) return vec4(uC3*0.8, 400.0);
    float cloud=smoothstep(0.6,0.72,fbm(q*2.3+so))*smoothstep(0.95,0.75,r);
    return vec4(mix(vec3(0.75,0.87,1.0),vec3(1.0),cloud), 0.2+cloud*3.0);
  }
#elif MODE==261
  { // sous-marin : un petit sous-marin de la 3e couleur, ses hublots allumés, dans une eau profonde de la 1re traversée de rayons
    float r=length(q); e=vec3(0.0); vec3 c1=brt(uC1,0.45);
    vec3 p=q-vec3(0.0,-0.02,0.0);
    float d=sdCap(p,vec3(-0.25,0.0,0.0),vec3(0.25,0.0,0.0),0.12);
    d=min(d,max(abs(p.x-0.02)-0.07,max(abs(p.y-0.15)-0.06,abs(p.z)-0.05)));
    if(d<0.0){ vec3 c=mix(uC3,vec3(1.0,0.85,0.3),0.2)*(0.55+0.5*clamp(0.5+p.y*4.0,0.0,1.0));
      for(int i=0;i<3;i++){ vec2 h=vec2(-0.13+0.13*float(i),0.0); if(p.z>0.0 && length(p.xy-h)<0.035){ c=mix(uC2,vec3(1.0),0.5); e=c*2.0; } }
      return vec4(c, 400.0); }
    if(abs(p.x+0.3)<0.015 && length(p.yz)<0.08) return vec4(vec3(0.5), 400.0);
    e+=mix(uC2,vec3(1.0),0.5)*pow(noise(vec3(q.x*5.0+q.y*1.5,q.z*5.0,so.x)),3.0)*smoothstep(-0.6,0.6,q.y)*0.8;
    for(int i=0;i<7;i++){ vec3 P=vec3(0.3+0.02*sin(float(i)*2.0),0.05+float(i)*0.08,0.0); e+=vec3(0.9)*smoothstep(0.015,0.0,abs(length(q-P)-0.015))*2.0; }
    return vec4(mix(c1*0.1,c1*0.35,smoothstep(-0.8,0.8,q.y)), 0.6);
  }
#elif MODE==262
  { // tortue de mer : une tortue nage dans l'eau claire, sa carapace en plaques de la 2e couleur, sa peau de la 3e, l'eau de la 1re
    float r=length(q); e=vec3(0.0); vec3 c1=brt(uC1,0.45);
    vec3 p=q; p.xy=mrot(0.25)*p.xy;
    float sh=length(p/vec3(0.3,0.22,0.12));
    if(sh<1.0){ vec3 cid; float d2; float d1=vorF(p*9.0+so,cid,d2);
      vec3 c=uC2*(0.6+0.45*h31(cid))*mix(0.5,1.0,smoothstep(0.02,0.07,d2-d1));
      return vec4(c*lit(normalize(p/vec3(0.09,0.05,0.0144))), 400.0); }
    vec3 hd=p-vec3(0.33,0.02,0.0); if(length(hd/vec3(0.09,0.06,0.06))<1.0) return vec4(uC3*0.8, 400.0);
    for(int i=0;i<4;i++){ float sx=i<2?1.0:-1.0, sz=mod(float(i),2.0)<1.0?1.0:-1.0;
      vec3 f=p-vec3(0.14*sx,-0.05,0.13*sz); f.xy=mrot(sx*0.6)*f.xy;
      if(length(f/vec3(i<2?0.2:0.1,0.035,0.06))<1.0) return vec4(uC3*0.7, 400.0); }
    e=mix(uC2,vec3(1.0),0.5)*pow(noise(vec3(q.x*5.0+q.y*1.5,q.z*5.0,so.x)),3.0)*smoothstep(-0.5,0.6,q.y)*0.7;
    return vec4(mix(c1*0.2,c1*0.55,smoothstep(-0.8,0.8,q.y)), 0.45);
  }
#elif MODE==263
  { // pieuvre : une pieuvre de la 2e couleur déploie ses huit bras dans l'eau de la 1re, ses ventouses de la 3e
    float r=length(q); e=vec3(0.0); vec3 c1=brt(uC1,0.45);
    vec3 hp=q-vec3(0.0,0.18,0.0); float hd=length(hp/vec3(0.17,0.2,0.16));
    if(hd<1.0){ vec3 c=uC2*lit(normalize(hp)); if(hp.z>0.0 && length(vec2(abs(hp.x)-0.06,hp.y+0.03))<0.03) c=vec3(0.05); return vec4(c, 400.0); }
    for(int i=0;i<8;i++){ float a=float(i)*0.785+0.2; vec3 d=vec3(cos(a),0.0,sin(a)*0.7);
      vec3 P0=vec3(0.0,0.05,0.0), P1=P0+d*0.18+vec3(0.0,-0.12,0.0), P2=P1+d*0.14+vec3(0.0,-0.1,0.0)+vec3(-d.z,0.0,d.x)*0.08, P3=P2+vec3(-d.z,0.08,d.x)*0.12;
      float t0=sdCap(q,P0,P1,0.045), t1=sdCap(q,P1,P2,0.032), t2=sdCap(q,P2,P3,0.018);
      float dd=min(t0,min(t1,t2));
      if(dd<0.0){ float sk=step(0.5,fract(length(q-P0)*30.0))*step(q.y,-0.0+P1.y*0.0+0.06)*step(-0.008,dd)*0.0;
        vec3 c=mix(uC2*0.85,mix(uC3,vec3(1.0),0.3),step(0.6,noise(q*50.0))*0.8);
        return vec4(c, 400.0); } }
    e=vec3(0.8)*step(0.98,h31(floor(q*12.0+so)))*0.8;
    return vec4(mix(c1*0.12,c1*0.4,smoothstep(-0.8,0.8,q.y)), 0.5);
  }
#elif MODE==264
  { // oasis : une mare de la 1re couleur au milieu des dunes de la 3e, deux palmiers de la 2e, sous la lune
    float r=length(q); e=vec3(0.0);
    float dy=-0.25+0.04*sin(q.x*6.0+so.x)+0.03*sin(q.z*7.0);
    float pond=length(q.xz*vec2(1.0,1.6))-0.28;
    if(q.y<dy){ if(pond<0.0 && q.y>dy-0.03) return vec4(brt(uC1,0.45)*0.5+vec3(0.3)*pow(noise(q*15.0),2.0), 400.0);
      return vec4(mix(uC3,vec3(0.9,0.75,0.5),0.4)*(0.55+0.3*smoothstep(-0.35,-0.2,q.y)), 400.0); }
    for(int k=0;k<2;k++){ vec3 B=k==0?vec3(-0.26,-0.25,0.0):vec3(0.3,-0.25,-0.05); vec3 T=B+vec3(k==0?0.06:-0.05,0.38,0.0);
      if(sdCap(q,B,T,0.02)<0.0) return vec4(vec3(0.4,0.28,0.16), 400.0);
      for(int i=0;i<6;i++){ float a=float(i)*1.0472; vec3 dir=vec3(cos(a),-0.2,sin(a)*0.6); vec3 pa=q-T; float t=clamp(dot(pa,dir)/0.18,0.0,1.0);
        if(length(q-(T+dir*0.18*t+vec3(0.0,-0.1*t*t,0.0)))<0.03*(1.0-t*0.7)) return vec4(uC2*0.7, 400.0); } }
    vec3 M=vec3(-0.05,0.38,-0.2); float dm=length(q.xy-M.xy);
    e=mix(uC3,vec3(1.0),0.4)*(smoothstep(0.08,0.07,dm)*3.0*exp(-pow((q.z-M.z)/0.06,2.0))+exp(-dm*8.0)*0.3)+starsE(q,0.5)*step(0.0,q.y);
    return vec4(mix(uC1*0.06,uC3*0.15,smoothstep(0.4,-0.3,q.y)), 0.45);
  }
#elif MODE==265
  { // arc-en-ciel : un arc de lumière en 3 bandes (les 3 couleurs) qui sort d'un nuage et retombe dans un autre, dans un ciel clair
    float r=length(q); e=vec3(0.0); vec3 p=q-vec3(0.0,-0.25,0.0);
    float rho=length(p.xy), t=(rho-0.38)/0.24;
    if(t>0.0 && t<1.0 && p.y>0.0 && abs(p.z)<0.05){ float b=t*3.0; vec3 c=b<1.0?brt(uC1,0.5):(b<2.0?uC2:uC3); e=c*0.6; return vec4(c, 300.0); }
    float cl=9.0; for(int i=0;i<2;i++){ float sx=i==0?-1.0:1.0; cl=min(cl,min(length(q-vec3(0.5*sx,-0.25,0.0))-0.14,min(length(q-vec3(0.38*sx,-0.28,0.05))-0.11,length(q-vec3(0.62*sx,-0.3,-0.03))-0.1))); }
    if(cl+0.02*noise(q*20.0)<0.0) return vec4(vec3(0.97)*(0.8+0.25*clamp(q.y*3.0+1.0,0.0,1.0)), 400.0);
    return vec4(mix(vec3(0.72,0.86,1.0),uC2,0.1), 0.2);
  }
#elif MODE==266
  { // nuage de pluie : un gros nuage tout rond d'où tombent des gouttes de la 2e couleur, sur une flaque de la 3e, dans un ciel de la 1re
    float r=length(q); e=vec3(0.0);
    float cl=min(min(length(q-vec3(0.0,0.2,0.0))-0.2,length(q-vec3(-0.2,0.12,0.0))-0.15),min(length(q-vec3(0.2,0.12,0.02))-0.16,length(q-vec3(0.08,0.3,-0.02))-0.13));
    if(cl+0.02*noise(q*18.0)<0.0) return vec4(vec3(0.85,0.87,0.92)*(0.6+0.45*clamp((q.y-0.05)*3.0,0.0,1.0)), 400.0);
    if(q.y<-0.45 && length(q.xz*vec2(1.0,1.5))<0.35) return vec4(mix(uC3,vec3(1.0),0.3)*(0.7+0.3*noise(q*20.0)), 400.0);
    vec2 g=vec2(q.x*14.0,q.y*4.0+q.x*0.0); vec2 id=floor(g), f=fract(g);
    float rain=step(0.55,h31(vec3(id,floor(q.z*6.0))))*smoothstep(0.08,0.0,abs(f.x-0.5)-0.02)*step(0.6,f.y)*step(q.y,0.0)*step(-0.45,q.y)*step(abs(q.x),0.32);
    e=mix(uC2,vec3(1.0),0.3)*rain*1.5;
    return vec4(mix(brt(uC1,0.45)*0.4,vec3(0.7,0.75,0.85),0.4), 0.25);
  }
#elif MODE==267
  { // ovni : une soucoupe volante de métal, son dôme de la 2e couleur, ses feux de la 3e, et un rayon de lumière qui descend dans la nuit
    float r=length(q); e=vec3(0.0); vec3 p=q-vec3(0.0,0.12,0.0);
    float sc=length(p/vec3(0.36,0.07,0.36));
    if(sc<1.0){ float a=atan(p.z,p.x); vec3 c=vec3(0.6,0.62,0.66)*lit(normalize(p/vec3(0.13,0.005,0.13)))+brt(uC1,0.45)*0.15;
      if(abs(p.y)<0.02 && abs(fract(a/6.2831853*12.0)-0.5)<0.15){ c=uC3; e=uC3*3.0; }
      return vec4(c, 400.0); }
    vec3 dp=p-vec3(0.0,0.05,0.0); if(length(dp)<0.14 && dp.y>0.0){ e=uC2*0.5; return vec4(mix(uC2,vec3(1.0),0.3), 400.0); }
    float beam=step(q.y,0.06)*step(length(q.xz),0.08+(0.06-q.y)*0.35)*step(-0.6,q.y);
    e+=mix(uC3,vec3(1.0),0.5)*beam*0.9;
    if(q.y<-0.5) return vec4(brt(uC1,0.4)*0.2+uC3*0.3*smoothstep(0.35,0.0,length(q.xz)), 400.0);
    e+=starsE(q,0.5);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==268
  { // lanterne : une lanterne de papier de la 2e couleur qui brille dans la nuit, allumée de la 3e, avec son pompon de la 1re
    float r=length(q); e=vec3(0.0); vec3 p=q-vec3(0.0,0.04,0.0);
    float L=length(p/vec3(0.3,0.26,0.3));
    if(L<1.0){ float rib=step(0.85,abs(sin(p.y*40.0))); vec3 c=mix(uC2,vec3(1.0,0.9,0.7),0.25);
      float glow=1.0-L*0.6; e=mix(c,uC3,0.4)*glow*1.5*(1.0-rib*0.5); return vec4(c*(1.0-rib*0.4), 400.0); }
    if(abs(abs(p.y)-0.27)<0.025 && length(p.xz)<0.16) return vec4(brt(uC1,0.45)*0.6, 400.0);
    if(p.y<-0.28 && p.y>-0.46 && length(p.xz)<0.03+(-0.28-p.y)*0.15 && abs(fract(atan(p.z,p.x)*3.0)-0.5)<0.35) return vec4(brt(uC1,0.45), 400.0);
    if(p.y>0.29 && length(p.xz)<0.006) return vec4(vec3(0.3), 400.0);
    e+=mix(uC2,uC3,0.5)*exp(-length(p)*4.0)*0.6+starsE(q,0.6);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==269
  { // bougie : une bougie de la 2e couleur, ses coulures de cire, sa flamme de la 3e et son halo, sur un bougeoir de la 1re
    float r=length(q); e=vec3(0.0);
    float rho=length(q.xz);
    if(q.y<-0.38 && q.y>-0.45 && rho<0.3-(q.y+0.45)*1.2) return vec4(brt(uC1,0.45)*0.7*(0.7+0.3*noise(q*30.0)), 400.0);
    float drip=0.012*step(0.6,noise(vec3(atan(q.z,q.x)*4.0,0.0,so.x)))*smoothstep(0.1,-0.2,q.y);
    if(q.y>-0.38 && q.y<0.08 && rho<0.12+drip){ return vec4(mix(uC2,vec3(1.0),0.2)*(0.6+0.4*clamp(0.5-q.x*4.0,0.0,1.0))+uC3*0.2*smoothstep(-0.1,0.08,q.y), 400.0); }
    if(q.y>0.08 && q.y<0.13 && rho<0.008) return vec4(vec3(0.1), 400.0);
    vec3 fp=q-vec3(0.0,0.2,0.0); float fl=length(fp/vec3(0.04,0.09,0.04));
    e=mix(vec3(1.0,0.97,0.85),uC3,smoothstep(0.2,1.0,fl))*smoothstep(1.0,0.3,fl)*8.0+uC3*exp(-length(fp)*6.0)*0.8;
    e+=starsE(q,0.6);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==270
  { // ampoule : une ampoule dont le filament brille de la 3e couleur, son halo de la 2e, son culot de métal, dans un verre de la 1re
    float r=length(q); e=vec3(0.0); vec3 p=q-vec3(0.0,0.08,0.0);
    float bulb=length(p)-0.26; float neck=length(p.xz)-0.1;
    if(p.y<-0.2 && p.y>-0.4 && length(p.xz)<0.11){ return vec4(vec3(0.7)*(0.6+0.4*step(0.5,fract(p.y*30.0+atan(p.z,p.x)*0.3))), 400.0); }
    e+=vec3(0.9,0.95,1.0)*exp(-abs(bulb)*90.0)*0.6*step(-0.2,p.y);
    float fy=p.y; vec2 fxz=vec2(p.x-0.06*sin(fy*40.0)*step(abs(fy),0.06),p.z);
    float fil=length(vec2(length(vec2(p.x,p.z))-0.05,fy))*0.0+length(vec2(p.x-clamp(p.x,-0.07,0.07),fy-0.02*sin(p.x*60.0)))+abs(p.z)*0.5;
    e+=mix(vec3(1.0,0.95,0.8),uC3,0.4)*exp(-fil*45.0)*30.0;
    e+=uC2*exp(-length(p)*5.0)*0.8;
    return vec4(brt(uC1,0.4)*0.08, 0.45);
  }
#elif MODE==271
  { // perle : une huître entrouverte de la 1re couleur, nacrée dedans, qui garde une grosse perle de la 3e, dans une eau de la 2e
    float r=length(q); e=vec3(0.0);
    vec3 pl=q-vec3(0.0,-0.12,0.0); float pd=length(pl);
    if(pd<0.12){ vec3 n=pl/pd; vec3 c=mix(uC3,vec3(1.0),0.5)*lit(n)+0.15*(0.5+0.5*cos(6.2831*(vec3(0.0,0.33,0.67)+n.y)));
      e=uC3*0.2; return vec4(c, 400.0); }
    vec3 lo=q-vec3(0.0,-0.25,0.0); float lw=length(lo/vec3(0.42,0.1,0.32));
    if(lw<1.0 && lo.y<0.02){ return vec4(lo.y>-0.01?mix(vec3(0.9,0.92,0.95),uC2,0.2):brt(uC1,0.45)*0.6*(0.7+0.4*noise(q*20.0)), 400.0); }
    vec3 up=q-vec3(0.0,-0.18,-0.1); up.yz=mrot(-0.9)*up.yz; float uw=length(up/vec3(0.42,0.1,0.32));
    if(uw<1.0) return vec4(up.y<0.0?mix(vec3(0.92),uC2,0.25):brt(uC1,0.45)*0.55*(0.7+0.4*noise(q*20.0)), 400.0);
    e+=mix(uC2,vec3(1.0),0.5)*pow(noise(vec3(q.x*5.0+q.y*1.5,q.z*5.0,so.x)),3.0)*smoothstep(-0.5,0.6,q.y)*0.6;
    return vec4(mix(uC2*0.2,uC2*0.5,smoothstep(-0.8,0.8,q.y)), 0.45);
  }
#elif MODE==272
  { // hibou : un hibou de la 2e couleur posé sur sa branche, ses grands yeux de la 3e qui brillent, sous la lune
    float r=length(q); e=vec3(0.0);
    if(abs(q.y+0.25)<0.035 && abs(q.z)<0.04 && abs(q.x)<0.5) return vec4(vec3(0.35,0.24,0.15), 400.0);
    vec3 b=q-vec3(0.0,-0.02,0.0); float bd=length(b/vec3(0.17,0.24,0.14));
    vec3 h=q-vec3(0.0,0.2,0.0); float hd=length(h/vec3(0.15,0.12,0.12));
    if(bd<1.0||hd<1.0){ vec3 c=uC2*(bd<1.0?0.75:0.85);
      if(bd<1.0 && b.z>0.0){ c=mix(c,mix(uC2,vec3(1.0),0.5),smoothstep(0.1,0.0,abs(b.x))*0.0+step(length(b.xy/vec2(0.1,0.16)),1.0)*0.5);
        c*=0.85+0.15*step(0.5,fract(b.y*25.0+abs(b.x)*15.0)); }
      vec2 ex=vec2(abs(h.x)-0.06,h.y); if(hd<1.0 && h.z>0.0){ float ed=length(ex);
        if(ed<0.05){ c=ed<0.02?vec3(0.03):mix(uC3,vec3(1.0,0.9,0.4),0.3); e=c*(ed<0.02?0.0:1.5); }
        if(abs(h.x)<0.015 && h.y<-0.02 && h.y>-0.06) c=brt(uC1,0.45); }
      if(hd<1.0 && h.y>0.06 && abs(abs(h.x)-0.1)<0.03) c*=0.7;
      return vec4(c*lit(normalize(bd<1.0?b:h)), 400.0); }
    vec3 M=vec3(0.3,0.36,-0.25); float dm=length(q.xy-M.xy);
    e=mix(uC3,vec3(1.0),0.4)*(smoothstep(0.1,0.09,dm)*3.0*exp(-pow((q.z-M.z)/0.06,2.0))+exp(-dm*8.0)*0.3)+starsE(q,0.55);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==273
  { // chat de nuit : un chat noir assis sur un toit de tuiles de la 1re couleur, devant une grosse lune de la 3e, ses yeux de la 2e
    float r=length(q); e=vec3(0.0);
    float roof=-0.25-abs(q.x)*0.35;
    if(q.y<roof) return vec4(brt(uC1,0.45)*0.45*(0.8+0.3*step(0.5,fract(q.x*12.0+step(0.5,fract(q.y*14.0))*0.5)))*(0.7+0.3*step(0.12,fract(q.y*14.0))), 400.0);
    vec3 c=q-vec3(0.0,-0.12,0.0);
    float body=length(c/vec3(0.13,0.17,0.1)), head=length((q-vec3(0.0,0.1,0.0))/vec3(0.09,0.08,0.08));
    vec2 ea=vec2(abs(q.x),q.y);
    float ear=inTri(ea,vec2(0.02,0.14),vec2(0.09,0.12),vec2(0.07,0.22))*step(abs(q.z),0.04);
    float tail=step(length(vec3(q.x-0.15-0.06*sin((q.y+0.25)*8.0),q.y+0.18,q.z)/vec3(0.025,0.1,0.025)),1.0);
    if(body<1.0||head<1.0||ear>0.5||tail>0.5){ vec3 cc=vec3(0.04);
      if(head<1.0 && q.z>0.0 && length(vec2(abs(q.x)-0.035,q.y-0.11))<0.017){ cc=uC2; e=uC2*2.0; }
      return vec4(cc, 400.0); }
    vec3 M=vec3(0.0,0.08,-0.3); float dm=length(q.xy-M.xy);
    e+=mix(uC3,vec3(1.0),0.3)*(smoothstep(0.3,0.29,dm)*2.5*exp(-pow((q.z-M.z)/0.08,2.0))+exp(-dm*5.0)*0.25)+starsE(q,0.6);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==274
  { // cascade : une chute d'eau de la 2e couleur tombe entre deux falaises de la 1re couverte de végétation de la 3e, dans un bassin plein d'écume
    float r=length(q); e=vec3(0.0);
    float cl=abs(q.x)-0.12-0.04*noise(q*8.0+so)-0.1*smoothstep(0.0,-0.4,q.y);
    if(cl>0.0 && q.z<0.05+0.1*noise(q*5.0)){ float veg=step(0.55,noise(q*14.0+so))*step(0.0,q.y+0.2);
      return vec4(mix(brt(uC1,0.45)*0.45*(0.7+0.5*noise(q*25.0)),uC3*0.7,veg), 400.0); }
    if(q.y<-0.4) { float foam=smoothstep(0.5,0.75,noise(q*18.0+so))*smoothstep(0.3,0.0,abs(q.x)); return vec4(mix(uC2*0.5,vec3(0.95),foam), 400.0); }
    if(abs(q.x)<0.13 && q.z<0.0 && q.z>-0.15){ float st=0.6+0.4*noise(vec3(q.x*40.0,q.y*3.0,so.x)); return vec4(mix(uC2,vec3(1.0),0.5)*st, 300.0); }
    float mist=smoothstep(0.5,0.7,fbm(q*3.0+so))*smoothstep(-0.1,-0.45,q.y);
    return vec4(mix(mix(vec3(0.75,0.88,1.0),uC2,0.1),vec3(1.0),mist), 0.2+mist*2.0);
  }
#elif MODE==275
  { // toupie : une toupie en bois rayée des 3 couleurs qui tourne sur sa pointe, avec son ombre
    float r=length(q); vec3 p=q; p.xy=mrot(0.12)*p.xy; float y=p.y, rho=length(p.xz);
    float prof=y>0.1?0.05*step(y,0.3):(y>-0.05?0.3*(1.0-pow((y-0.1+0.15)/0.3-0.5,2.0)*0.0)*(1.0-smoothstep(0.02,0.1,y)*0.0)-0.0:0.0);
    float R=y>0.12?(y<0.3?0.035:0.0):(y>-0.02?0.3-0.25*smoothstep(0.02,0.12,y):0.3*max(0.0,(y+0.32)/0.3));
    if(rho<R && y>-0.32){ float m=mod(floor((y+0.32)*14.0+atan(p.z,p.x)*0.3),3.0);
      vec3 c=y>0.12?vec3(0.5,0.35,0.2):(m<1.0?brt(uC1,0.45):(m<2.0?uC2:uC3));
      return vec4(c*lit(normalize(vec3(p.x,0.25,p.z))), 400.0); }
    if(q.y<-0.34) return vec4(mix(vec3(0.85,0.82,0.76),vec3(0.4),smoothstep(0.3,0.0,length(q.xz-vec2(0.1,0.0))*1.0)*0.5), 400.0);
    return vec4(mix(vec3(0.95,0.94,0.9),uC3,0.1), 0.18);
  }
// ===================== Légendaires =====================
#elif MODE==276
  { // château : un château de conte, ses murs de la 1re couleur, ses toits pointus de la 2e, ses fenêtres qui brillent de la 3e, sous les étoiles
    float r=length(q); q=q*0.72+vec3(0.0,-0.1,0.0); e=vec3(0.0); vec3 c1=brt(uC1,0.45);
    if(q.y<-0.4) return vec4(c1*0.15, 400.0);
    for(int i=0;i<5;i++){ float fi=float(i); float x=-0.36+0.18*fi; float hh=i==2?0.32:(mod(fi,2.0)<1.0?0.12:0.2); float rr=i==2?0.08:0.06;
      vec3 p=q-vec3(x,-0.4,0.0); float rho=length(p.xz);
      if(p.y<hh && rho<rr){ vec3 c=mix(c1,vec3(0.85),0.3)*lit(normalize(vec3(p.x,0.0,p.z)));
        if(p.z>0.0 && abs(p.x)<0.015 && abs(fract(p.y*8.0)-0.5)<0.2 && p.y>0.05){ c=uC3; e=uC3*2.0; } return vec4(c, 400.0); }
      if(p.y>=hh && p.y<hh+0.16 && rho<rr*1.2*(1.0-(p.y-hh)/0.16)) return vec4(uC2*lit(normalize(vec3(p.x,0.3,p.z))), 400.0); }
    if(q.y<-0.25 && abs(q.x)<0.36 && abs(q.z)<0.05){ vec3 c=c1*0.5; if(q.z>0.0 && abs(q.x)<0.04 && q.y<-0.32){ c=uC3*0.8; e=uC3; } return vec4(c, 400.0); }
    e+=starsE(q,0.4)*step(-0.1,q.y)+mix(uC2,uC3,0.5)*exp(-length(q-vec3(0.0,0.2,-0.4))*3.0)*0.3;
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==277
  { // arbre de vie : un arbre dont les branches brillent de la 3e couleur, ses feuilles de lumière de la 2e qui tombent, ses racines dans un sol de la 1re
    float r=length(q); e=vec3(0.0);
    if(q.y<-0.42) return vec4(brt(uC1,0.45)*0.25, 400.0);
    float d=sdCap(q,vec3(0.0,-0.42,0.0),vec3(0.0,-0.05,0.0),0.05);
    for(int i=0;i<6;i++){ float a=float(i)*1.0472+0.4; vec3 A=vec3(0.0,-0.05+0.03*float(i),0.0), B=A+vec3(cos(a)*0.25,0.18,sin(a)*0.12);
      d=min(d,sdCap(q,A,B,0.022)); vec3 C=B+vec3(cos(a+0.6)*0.1,0.1,sin(a+0.6)*0.06); d=min(d,sdCap(q,B,C,0.012));
      vec3 R=vec3(cos(a)*0.22,-0.45,sin(a)*0.1); d=min(d,sdCap(q,vec3(0.0,-0.36,0.0),R,0.015)); }
    vec3 c3=mix(uC3,vec3(1.0,0.95,0.7),0.3);
    if(d<0.0){ e=c3*2.0; return vec4(mix(vec3(0.3,0.2,0.12),c3,0.4), 400.0); }
    e=c3*exp(-max(d,0.0)*30.0)*2.0;
    vec3 g=q*9.0+so; vec3 fc=fract(g)-0.5; float leaf=step(0.9,h31(floor(g)))*smoothstep(0.18,0.08,length(fc))*smoothstep(0.65,0.2,length(q-vec3(0.0,0.2,0.0)));
    e+=uC2*leaf*4.0+starsE(q,0.6);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==278
  { // astronaute : un petit astronaute flotte dans l'espace, la visière d'or (3e couleur), les bandes de sa combinaison de la 1re, une planète de la 2e
    float r=length(q); e=vec3(0.0); vec3 L=normalize(vec3(-0.5,0.6,0.6));
    vec3 p=q-vec3(-0.05,0.0,0.0); p.xy=mrot(0.35)*p.xy;
    float hd=length(p-vec3(0.0,0.14,0.0))-0.13;
    if(hd<0.0){ vec3 n=normalize(p-vec3(0.0,0.14,0.0)); vec3 c=vec3(0.95)*lit(n);
      if(n.z>0.35 && abs(n.x)<0.75 && n.y<0.6 && n.y>-0.5){ c=mix(vec3(1.0,0.8,0.35),uC3,0.4)*(0.5+0.8*pow(clamp(dot(reflect(-L,n),vec3(0.0,0.0,1.0)),0.0,1.0),4.0)); e=c*0.3; }
      return vec4(c, 400.0); }
    float bd=sdCap(p,vec3(0.0,0.0,0.0),vec3(0.0,-0.12,0.0),0.1);
    bd=min(bd,sdCap(p,vec3(0.08,0.0,0.0),vec3(0.2,0.08,0.02),0.04)); bd=min(bd,sdCap(p,vec3(-0.08,0.0,0.0),vec3(-0.18,-0.1,0.02),0.04));
    bd=min(bd,sdCap(p,vec3(0.05,-0.18,0.0),vec3(0.08,-0.32,0.03),0.045)); bd=min(bd,sdCap(p,vec3(-0.05,-0.18,0.0),vec3(-0.1,-0.3,-0.02),0.045));
    if(bd<0.0){ vec3 c=vec3(0.92)*(0.6+0.4*clamp(0.5-p.x*3.0+p.z*2.0,0.0,1.0)); if(abs(p.y+0.05)<0.02) c=brt(uC1,0.45); return vec4(c, 400.0); }
    if(max(abs(p.x)-0.08,max(abs(p.y+0.03)-0.12,abs(p.z+0.12)-0.05))<0.0) return vec4(vec3(0.7), 400.0);
    vec3 P=vec3(0.4,-0.4,-0.3); float dp=length(q-P);
    if(dp<0.25){ vec3 n=(q-P)/dp; return vec4(mix(uC2,vec3(1.0),0.2*step(0.6,noise(n*5.0)))*lit(n), 1000.0); }
    e+=starsE(q,0.3)*2.0;
    return vec4(uC1*0.05, 0.45);
  }
#elif MODE==279
  { // supernova : une étoile qui explose au fond d'un verre de nuit, son cœur aveuglant et sa coquille de filaments des 3 couleurs
    float r=length(q); e=vec3(0.0); vec3 n=q/max(r,1e-4);
    e+=vec3(1.0)*exp(-r*30.0)*20.0+mix(uC3,vec3(1.0),0.5)*exp(-r*8.0)*2.0;
    float sh=exp(-pow((r-0.42-0.05*fbm(n*4.0+so))/0.05,2.0));
    float fil=pow(1.0-abs(2.0*noise(n*7.0+so)-1.0),6.0);
    float k=noise(n*3.0+so+5.0); vec3 fc=k<0.4?brt(uC1,0.5):(k<0.6?uC2:uC3);
    e+=fc*sh*(0.4+fil*3.0)*2.0;
    e+=uC2*exp(-pow((length(q.xy)-0.6)/0.02,2.0))*exp(-q.z*q.z*40.0)*1.5;
    e+=starsE(q,0.65);
    return vec4(uC1*0.05, 0.4);
  }
#elif MODE==280
  { // pulsar : une étoile minuscule et brûlante lance deux faisceaux de lumière de la 2e couleur, entourée de lignes de champ de la 3e
    float r=length(q); e=vec3(0.0); vec3 ax=normalize(vec3(0.35,1.0,0.2));
    e+=vec3(1.0)*exp(-r*40.0)*25.0+mix(vec3(1.0),uC2,0.4)*exp(-r*10.0)*1.5;
    float h=dot(q,ax); float rho=length(q-ax*h);
    e+=mix(uC2,vec3(1.0),0.3)*exp(-pow(rho/(0.015+abs(h)*0.12),2.0))*smoothstep(0.9,0.0,abs(h))*3.0;
    for(int i=0;i<4;i++){ float a=float(i)*1.5708; vec3 b1=normalize(cross(ax,vec3(0.0,0.0,1.0))), b2=cross(ax,b1);
      vec3 pl=normalize(b1*cos(a)+b2*sin(a)); float x=dot(q,pl), z=dot(q,cross(ax,pl));
      float loopd=abs(length(vec2(x-0.25,h))-0.25)+abs(z)*1.5; e+=mix(uC3,vec3(1.0),0.2)*exp(-loopd*70.0)*1.5; }
    e+=brt(uC1,0.4)*smoothstep(0.6,0.75,fbm(q*2.0+so))*0.3+starsE(q,0.6);
    return vec4(uC1*0.05, 0.4);
  }
#elif MODE==281
  { // cristal de pouvoir : un grand cristal taillé de la 2e couleur flotte et brille, entouré d'éclats de la 3e et d'un anneau d'énergie de la 1re
    float r=length(q); e=vec3(0.0);
    vec3 p=q; p.xz=mrot(0.5)*p.xz;
    float oc=abs(p.x)/0.14+abs(p.z)/0.14+abs(p.y)/0.36;
    if(oc<1.0){ vec3 n=normalize(sign(p)*vec3(1.0/0.14,1.0/0.36,1.0/0.14)); vec3 c=mix(uC2,vec3(1.0),0.3)*(0.5+0.8*lit(n));
      e=uC2*(0.5+0.8*(1.0-oc)); return vec4(c, 400.0); }
    e=uC2*exp(-max(oc-1.0,0.0)*3.0)*0.5;
    for(int i=0;i<6;i++){ float a=float(i)*1.0472+so.x; vec3 S=vec3(cos(a)*0.4,0.12*sin(a*2.0),sin(a)*0.25);
      vec3 sp=q-S; if(abs(sp.x)/0.04+abs(sp.y)/0.07+abs(sp.z)/0.04<1.0){ e=uC3*0.8; return vec4(mix(uC3,vec3(1.0),0.3), 400.0); } }
    vec3 ra=normalize(vec3(0.0,1.0,0.3)); float h=dot(q,ra); float rd=abs(length(q-ra*h)-0.5);
    e+=brt(uC1,0.5)*exp(-(rd*rd+h*h)*900.0)*4.0;
    e+=starsE(q,0.6);
    return vec4(uC1*0.05, 0.4);
  }
#elif MODE==282
  { // couronne : une couronne royale d'or (3e couleur) posée sur un coussin de velours de la 1re, sertie de pierres de la 2e
    float r=length(q); e=vec3(0.0); vec3 gold=mix(vec3(1.0,0.8,0.32),uC3,0.4);
    vec3 cu=q-vec3(0.0,-0.35,0.0); if(length(cu/vec3(0.45,0.12,0.35))<1.0) return vec4(brt(uC1,0.45)*0.55*lit(normalize(cu/vec3(0.2,0.0144,0.12))), 400.0);
    vec3 p=q-vec3(0.0,-0.18,0.0); float rho=length(p.xz), a=atan(p.z,p.x);
    float tri=abs(fract(a/6.2831853*8.0)-0.5)*2.0;
    if(abs(rho-0.24)<0.025 && p.y>0.0 && p.y<0.12+0.14*(1.0-tri)){ vec3 c=gold*(0.6+0.5*clamp(cos(a-2.2),0.0,1.0));
      if(p.y<0.06 && abs(fract(a/6.2831853*8.0+0.5)-0.5)<0.1 && abs(p.y-0.035)<0.02){ c=uC2; e=uC2*0.6; }
      return vec4(c, 400.0); }
    for(int i=0;i<8;i++){ float aa=(float(i)+0.5)*0.785398; vec3 B=vec3(cos(aa)*0.24,0.27,sin(aa)*0.24); if(length(p-B)<0.025){ e=gold*0.5; return vec4(gold, 400.0); } }
    e+=gold*step(0.97,h31(floor(q*20.0+so)))*2.0*step(-0.2,q.y);
    return vec4(uC1*0.05, 0.4);
  }
#elif MODE==283
  { // coffre au trésor : un coffre de bois ouvert, débordant de pièces d'or (3e couleur) et de pierres de la 1re et de la 2e
    float r=length(q); e=vec3(0.0); vec3 gold=mix(vec3(1.0,0.82,0.35),uC3,0.35);
    vec3 b=q-vec3(0.0,-0.25,0.0);
    if(abs(b.x)<0.3 && abs(b.y)<0.12 && abs(b.z)<0.18){ vec3 c=vec3(0.45,0.28,0.14)*(0.8+0.2*step(0.5,fract(b.x*12.0)));
      if(abs(abs(b.x)-0.25)<0.025 || abs(b.y-0.1)<0.02) c=gold*0.7; return vec4(c, 400.0); }
    vec3 l=q-vec3(0.0,0.0,-0.2); l.yz=mrot(-0.4)*l.yz;
    if(abs(l.x)<0.3 && abs(l.y)<0.13 && abs(l.z)<0.03) return vec4(vec3(0.4,0.25,0.12), 400.0);
    float pile=-0.13+0.08*(1.0-length(q.xz/vec2(0.3,0.18)))+0.02*noise(q*30.0);
    if(q.y<pile && abs(q.x)<0.3 && abs(q.z)<0.18){ vec3 g=q*30.0; float k=h31(floor(g));
      vec3 c=k<0.08?brt(uC1,0.5):(k<0.16?uC2:gold*(0.7+0.4*h31(floor(g)+1.0))); e=c*0.6; return vec4(c, 400.0); }
    e+=gold*exp(-length(q-vec3(0.0,-0.1,0.0))*6.0)*0.6+gold*step(0.975,h31(floor(q*18.0+so)))*2.5;
    return vec4(uC1*0.05, 0.4);
  }
#elif MODE==284
  { // œuf de dragon : un œuf couvert d'écailles de la 1re couleur, fendu de lumière de la 3e, posé dans des braises, une fumée de la 2e
    float r=length(q); e=vec3(0.0); vec3 p=q-vec3(0.0,-0.02,0.0); p.y*=0.78;
    float L=length(p);
    if(L<0.27){ vec3 n=p/L; vec3 cid; float d2; float d1=vorF(n*7.0+so,cid,d2);
      vec3 c=brt(uC1,0.45)*0.6*(0.6+0.5*h31(cid))*mix(0.5,1.0,smoothstep(0.02,0.08,d2-d1))*lit(n);
      float crack=smoothstep(0.04,0.0,abs(fbm(n*3.0+so)-0.5))*step(0.4,noise(n*2.0+so));
      vec3 c3=mix(uC3,vec3(1.0,0.8,0.4),0.3); c=mix(c,c3,crack); e=c3*crack*3.0; return vec4(c, 400.0); }
    if(q.y<-0.3){ float em=step(0.6,noise(q*25.0+so)); e=mix(uC3,vec3(1.0,0.4,0.1),0.5)*em*2.0; return vec4(mix(vec3(0.08),uC3*0.6,em), 400.0); }
    float sm=smoothstep(0.55,0.75,fbm(q*3.0+so+vec3(0.0,-2.0,0.0)))*smoothstep(0.1,0.4,q.y)*smoothstep(0.9,0.6,r);
    e+=uC3*exp(-L*6.0)*0.5+starsE(q,0.65)*(1.0-sm);
    return vec4(mix(uC1*0.05,mix(uC2,vec3(0.5),0.4),sm), 0.4+sm*2.5);
  }
#elif MODE==285
  { // lampe magique : une lampe à huile d'or (3e couleur) d'où sort une fumée enchantée de la 2e qui monte en spirale, pleine d'étincelles
    float r=length(q); e=vec3(0.0); vec3 gold=mix(vec3(1.0,0.8,0.35),uC3,0.4);
    vec3 p=q-vec3(-0.05,-0.3,0.0);
    float body=length(p/vec3(0.22,0.09,0.13));
    float spout=sdCap(q,vec3(0.12,-0.3,0.0),vec3(0.32,-0.22,0.0),0.025);
    float handle=abs(length(vec2(length(vec2(p.x+0.25,p.y)),p.z)-0.0)-0.07)+0.0; float hd=abs(length((p.xy-vec2(-0.24,0.0)))-0.07)+abs(p.z)*1.0-0.02;
    if(body<1.0||spout<0.0||hd<0.0||(abs(p.y-0.1)<0.03&&length(p.xz)<0.06)){ vec3 n=normalize(p/vec3(0.0484,0.0081,0.0169));
      vec3 c=gold*(0.35+0.9*pow(clamp(dot(reflect(normalize(vec3(0.5,-0.6,-0.6)),n),vec3(0.0,0.0,1.0)),0.0,1.0),3.0)+0.3*lit(n));
      return vec4(c, 400.0); }
    vec3 s=q-vec3(0.32,-0.2,0.0); float t=clamp(s.y/0.7,0.0,1.0);
    vec2 cen=vec2(-0.25*t+0.08*sin(t*10.0),0.08*cos(t*10.0)); float dd=length(vec2(s.x,s.z)-cen);
    float smk=smoothstep(0.03+0.12*t,0.0,dd)*step(0.0,s.y)*step(s.y,0.75)*(0.5+0.5*fbm(q*6.0+so));
    e=uC2*smk*2.0+gold*step(0.96,h31(floor(q*22.0+so)))*smk*8.0+starsE(q,0.65);
    return vec4(uC1*0.05, 0.4+smk*2.0);
  }
#elif MODE==286
  { // pagode : une pagode à trois toits recourbés de la 1re couleur, ses murs de la 2e, ses lanternes de la 3e, sous la lune
    float r=length(q); e=vec3(0.0); vec3 c1=brt(uC1,0.45);
    if(q.y<-0.45) return vec4(vec3(0.1,0.09,0.08), 400.0);
    for(int i=0;i<3;i++){ float fi=float(i); float y0=-0.45+fi*0.18, w=0.2-fi*0.04;
      vec3 p=q-vec3(0.0,y0,0.0);
      if(p.y>0.0 && p.y<0.12 && abs(p.x)<w && abs(p.z)<w*0.8){ vec3 c=uC2*0.7; if(p.z>0.0 && abs(fract(p.x*10.0)-0.5)<0.2 && p.y<0.09 && p.y>0.03){ c=uC3*0.8; e=uC3; } return vec4(c, 400.0); }
      float rw=w+0.12+0.04*smoothstep(0.0,0.1,abs(p.x)-w);
      if(p.y>0.12 && p.y<0.17+0.05*pow(abs(p.x)/rw,3.0) && abs(p.x)<rw && abs(p.z)<rw*0.8 && p.y<0.12+0.06*(1.0-abs(p.x)/rw)+0.06*pow(abs(p.x)/rw,4.0)) return vec4(c1*0.8, 400.0);
      vec3 lp=p-vec3(rw*0.9,0.09,0.0); e+=uC3*exp(-length(lp)*40.0)*3.0; lp=p-vec3(-rw*0.9,0.09,0.0); e+=uC3*exp(-length(lp)*40.0)*3.0; }
    if(length(q.xz)<0.01 && q.y>0.1 && q.y<0.3) return vec4(c1, 400.0);
    vec3 M=vec3(-0.3,0.35,-0.25); float dm=length(q.xy-M.xy);
    e+=mix(uC3,vec3(1.0),0.4)*(smoothstep(0.09,0.08,dm)*3.0*exp(-pow((q.z-M.z)/0.06,2.0))+exp(-dm*8.0)*0.3)+starsE(q,0.55);
    return vec4(uC1*0.06, 0.45);
  }
#elif MODE==287
  { // boule de cristal : une boule de voyante sur son pied de la 1re couleur ; dedans tourbillonne une brume de la 2e et de la 3e
    float r=length(q); e=vec3(0.0);
    vec3 b=q-vec3(0.0,0.06,0.0); float L=length(b);
    if(q.y<-0.24 && q.y>-0.42 && length(q.xz)<0.2-(q.y+0.24)*(-0.6)){ return vec4(brt(uC1,0.45)*0.6*(0.6+0.4*clamp(0.5-q.x*3.0,0.0,1.0))*(0.85+0.15*step(0.5,fract(q.y*30.0))), 400.0); }
    if(L<0.3){ float a=atan(b.z,b.x)+L*8.0; vec3 w=vec3(cos(a)*L,b.y,sin(a)*L)*3.0+so;
      float m1=smoothstep(0.45,0.75,fbm(w)), m2=smoothstep(0.5,0.8,fbm(w+7.0));
      e=(uC2*m1+uC3*m2)*1.6+mix(uC2,vec3(1.0),0.5)*exp(-L*14.0)*2.0;
      e+=vec3(0.9,0.95,1.0)*exp(-abs(L-0.3)*120.0)*0.8;
      return vec4(mix(uC2,uC3,m2)*0.3, 0.6+(m1+m2)*1.5); }
    e+=mix(uC2,uC3,0.5)*exp(-(L-0.3)*8.0)*0.3+starsE(q,0.6);
    return vec4(uC1*0.05, 0.4);
  }
// ===================== Mythiques (animés, une boucle de MYTH_T secondes : lp fait un tour, 2π) =====================
#elif MODE==288
  { // horloge du temps : une horloge enchantée ; la grande aiguille fait un tour, la petite tourne à l'envers, la trotteuse file, le balancier se balance,
    // des engrenages de la 1re couleur tournent derrière ; le cadran luit de la 2e, les heures et les aiguilles de la 3e
    float t=mod(uTime,3.9269908), lp=t*1.6; e=vec3(0.0);
    float h=q.z; vec2 p=q.xy*1.3; float lay=exp(-h*h/0.006); float rr=length(p), a=atan(p.y,p.x);
    vec3 c1=brt(uC1,0.5), c3=mix(uC3,vec3(1.0),0.3);
    // les engrenages derrière (un peu en retrait)
    float lay2=exp(-(h+0.12)*(h+0.12)/0.006);
    for(int i=0;i<2;i++){ vec2 C=i==0?vec2(-0.32,0.3):vec2(0.34,-0.28); float n=i==0?10.0:8.0; float R=i==0?0.24:0.2;
      vec2 gp=p-C; float ga=atan(gp.y,gp.x)+(i==0?1.0:-1.0)*lp*2.0/n, gl=length(gp);
      float g=gl-R-0.03*smoothstep(-0.3,0.3,cos(ga*n)); float hole=step(gl,R*0.6)*step(R*0.3,gl);
      e+=c1*smoothstep(0.01,-0.01,g)*(1.0-hole*0.8)*lay2*1.2; }
    // le cadran
    if(rr<0.55){ e+=uC2*0.35*lay*(1.0-rr);
      float tick=step(abs(fract(a/6.2831853*12.0+0.5)-0.5),0.04)*step(abs(rr-0.46),0.05);
      float mtick=step(abs(fract(a/6.2831853*60.0+0.5)-0.5),0.08)*step(abs(rr-0.5),0.015);
      e+=c3*(tick*3.0+mtick*1.5)*lay;
      e+=c3*exp(-abs(rr-0.55)*80.0)*2.0*lay; }
    // les aiguilles
    vec2 dm=vec2(sin(lp),cos(lp)), dh=vec2(sin(-lp+1.0),cos(-lp+1.0)), ds=vec2(sin(lp*4.0),cos(lp*4.0));
    e+=c3*exp(-segM(p,vec2(0.0),dm*0.42)*90.0)*3.0*lay;
    e+=c3*exp(-segM(p,vec2(0.0),dh*0.28)*60.0)*3.0*lay;
    e+=uC2*exp(-segM(p,-ds*0.08,ds*0.48)*200.0)*3.0*lay;
    e+=vec3(1.0)*exp(-rr*40.0)*3.0*lay;
    // le balancier sous le cadran
    float sw=0.35*sin(lp); vec2 pd=vec2(sin(sw),-cos(sw)); vec2 bob=vec2(0.0,-0.55)+pd*0.25;
    e+=c1*(exp(-segM(p,vec2(0.0,-0.55),bob)*120.0)*1.5+exp(-max(length(p-bob)-0.06,0.0)*60.0)*3.0)*lay;
    e+=starsE(q,0.7);
    return vec4(uC1*0.05, 0.4);
  }
#elif MODE==289
  { // cœur de cristal : un cœur taillé de la 2e couleur bat au milieu du verre ; à chaque battement il s'illumine de la 3e,
    // lance une onde de lumière, et des éclats de la 1re tournent autour
    float t=mod(uTime,3.9269908), lp=t*1.6; e=vec3(0.0);
    float beat=pow(max(0.0,cos(lp*2.0)),12.0)+0.6*pow(max(0.0,cos(lp*2.0-0.7)),12.0);   // deux battements par boucle, « boum-boum »
    float s=0.33*(1.0+0.08*beat);
    vec3 p=q/s; p=vec3(p.x,p.y-0.05,p.z*1.3);
    float x=p.x, y=p.z, z=p.y;   // la formule du cœur a la pointe vers le bas sur z
    float a3=x*x+2.25*y*y+z*z-1.0; float f=a3*a3*a3-x*x*z*z*z-0.1125*y*y*z*z*z;
    if(f<0.0){ vec3 cid; float d2; float d1=vorF(q*14.0,cid,d2);
      float fl=0.4+0.8*h31(cid); vec3 c=mix(uC2,mix(uC3,vec3(1.0),0.4),beat*0.7)*fl;
      e=mix(uC2,uC3,beat)*(0.4+1.6*beat)+vec3(1.0)*smoothstep(0.02,0.0,d2-d1)*0.6;
      return vec4(c, 400.0); }
    float rr=length(q);
    float wave=fract(lp/3.14159); e+=mix(uC3,vec3(1.0),0.3)*exp(-pow((rr-0.35-wave*0.5)/0.03,2.0))*(1.0-wave)*2.0*exp(-q.z*q.z*20.0);
    e+=mix(uC2,uC3,beat)*exp(-rr*4.0)*(0.3+beat*0.8);
    for(int i=0;i<6;i++){ float aa=float(i)*1.0472+lp; vec3 S=vec3(cos(aa)*0.55,0.1*sin(aa*2.0+float(i)),sin(aa)*0.35);
      e+=brt(uC1,0.5)*exp(-length(q-S)*45.0)*4.0; }
    e+=starsE(q,0.7);
    return vec4(uC1*0.05, 0.4);
  }
#elif MODE==290
  { // koï : deux carpes koï tournent l'une après l'autre dans un bassin, comme le yin et le yang ; l'une de la 2e couleur, l'autre de la 3e,
    // tachées de blanc ; des ronds dans l'eau de la 1re s'élargissent, des feuilles de nénuphar flottent ; un tour par boucle
    float t=mod(uTime,3.9269908), lp=t*1.6; e=vec3(0.0);
    float h=q.z; vec2 p=q.xy*1.2; float lay=exp(-h*h/0.006); float rr=length(p), a=atan(p.y,p.x);
    vec3 c1=brt(uC1,0.45);
    vec3 col=c1*0.25; float den=0.4;
    for(int k=0;k<2;k++){ float H=lp+float(k)*3.14159;
      float s=mod(H-a,6.2831853); float R=0.36+0.02*sin(lp*2.0);
      float bl=1.25; float tt=s/bl;
      float wig=0.03*sin(s*5.0-lp*4.0)*tt;
      float w=0.085*pow(max(0.0,1.0-tt),0.7)*smoothstep(0.0,0.12,s);
      float dd=abs(rr-R-wig);
      vec3 fc=k==0?uC2:uC3;
      if(tt<1.0 && dd<w){ float spot=step(0.55,noise(vec3(s*4.0,(rr-R)*20.0,float(k)*5.0)));
        col=mix(fc,vec3(0.97),spot)*(0.7+0.4*(1.0-dd/max(w,0.001))); den=500.0*lay;
        if(s<0.15 && abs(rr-R-0.03)<0.012) col=vec3(0.05); }
      float tl=tt-1.0; if(tl>0.0 && tl<0.25 && dd<0.02+0.25*tl*(1.0+0.5*sin(lp*4.0))){ col=mix(fc,vec3(1.0),0.4); den=300.0*lay; } }
    for(int i=0;i<3;i++){ float fi=float(i); vec2 C=vec2(cos(fi*2.1+0.5),sin(fi*2.1+0.5))*0.62; float d=length(p-C);
      if(d<0.12 && abs(atan(p.y-C.y,p.x-C.x)-fi)>0.3){ col=mix(c1,vec3(0.3,0.6,0.3),0.5)*0.9; den=400.0*lay; } }
    float rip=exp(-pow(fract(rr*3.0-lp/6.2831853)-0.5,2.0)*200.0)*smoothstep(0.85,0.2,rr);
    e+=mix(c1,vec3(1.0),0.5)*rip*0.8*lay+c1*0.15*lay;
    return vec4(col, den>1.0?den:0.4);
  }
