#elif MODE==65
  { // œil du dragon : un œil de reptile au milieu du verre. La pupille fendue s'ouvre et se ferme, le regard se promène,
    // les paupières clignent une fois par boucle. Les 3 couleurs du coloris : la peau d'écailles et le cercle de l'iris (la 1re),
    // l'iris (la 2e), la couronne de feu autour de la pupille, les éclats de l'iris et le bord des paupières (la 3e)
    float t=mod(uTime,3.9269908), lp=t*1.6;   // lp fait un tour complet (2π) par boucle : tout ce qui bouge en dépend
    float h=q.z; vec2 p=q.xy;
    float lay=exp(-h*h/0.02);
    float bl=pow(max(0.0,cos(lp-2.4)),80.0);   // le clignement : très court
    float op=1.0-bl;
    float ax=clamp(abs(p.x)/0.92,0.0,1.0);
    float lid=0.47*op*pow(1.0-ax*ax,0.75);
    float inE=smoothstep(0.015,-0.015,abs(p.y)-lid)*step(abs(p.x),0.92);
    vec2 c=vec2(0.18*sin(lp),0.06*sin(lp*2.0));
    vec2 ip=p-c; float ir=length(ip); float ia=atan(ip.y,ip.x);
    float iris=smoothstep(0.42,0.39,ir);
    vec3 wob=vec3(cos(lp),sin(lp),0.0)*0.7;
    float fib=noise(vec3(cos(ia)*9.0,sin(ia)*9.0,ir*3.0)+so)*0.55+noise(vec3(cos(ia)*24.0,sin(ia)*24.0,ir*5.0)+so+wob)*0.45;
    float pw=0.045+0.05*(0.5+0.5*sin(lp*2.0+1.0));
    float pup=smoothstep(1.0,0.85,length(vec2(ip.x/pw,ip.y/0.4)));
    vec3 c1g=uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.35);   // la 1re couleur, éclaircie pour briller (elle est souvent très foncée)
    float fl3=smoothstep(0.55,0.75,noise(vec3(cos(ia)*14.0,sin(ia)*14.0,ir*2.0)+so+3.0));   // des éclats de la 3e couleur dans l'iris
    vec3 ic=mix(uC2,uC3,fl3*0.85);
    float pr=length(vec2(ip.x/pw,ip.y/0.4));
    float crown=smoothstep(3.2,1.2,pr);   // la couronne autour de la pupille
    ic=mix(ic,uC3,crown*0.9);
    float limb=smoothstep(0.27,0.39,ir);
    ic=mix(ic,c1g*0.6,limb*0.85);   // le cercle de l'iris, de la 1re couleur
    float ring=exp(-pow((pr-1.15)/0.25,2.0));   // le feu juste au bord de la pupille
    vec3 eyeE=(ic*(0.45+1.3*fib)+mix(uC3,vec3(1.0),0.35)*ring*1.2)*iris*(1.0-pup);
    vec2 sg=p*vec2(7.0,8.5); sg.x+=mod(floor(sg.y),2.0)*0.5; vec2 sf=fract(sg)-0.5;
    float edgeS=smoothstep(0.3,0.5,length(sf*vec2(1.0,1.3)));
    float rim=exp(-pow((abs(p.y)-lid)/0.022,2.0))*step(abs(p.x),0.9)*op;
    vec2 hl=p-c-vec2(-0.16,0.17);
    e=eyeE*6.0*inE*lay + c1g*0.35*(1.0-iris)*inE*lay + mix(uC3,vec3(1.0),0.15)*rim*lay*4.0
     + c1g*edgeS*(1.0-inE)*lay*1.4 + vec3(1.0)*exp(-dot(hl,hl)/0.0018)*inE*lay*7.0;
    vec3 skin=mix(uC1*0.6,uC1*0.18,edgeS);
    float skinA=(1.0-inE)*lay*30.0*smoothstep(0.98,0.9,length(q));
    return vec4(mix(uC1*0.2,skin,clamp(skinA,0.0,1.0)), 0.9+pup*iris*inE*lay*80.0+skinA);
  }
#elif MODE==66
  { // tesseract : un hypercube (un cube en 4 dimensions) tourne dans le verre ; on le voit se retourner comme un gant,
    // le petit cube passant dehors et le grand dedans. Ses arêtes sont des fils de lumière, ses sommets des étoiles
    float t=mod(uTime,3.9269908), lp=t*1.6;
    float A=lp*0.25;   // un quart de tour par boucle : l'hypercube retombe exactement sur lui-même
    float dmin=1e3, dk=0.5, nod=1e3;
    for(int i=0;i<16;i++){
      float fi=float(i);
      vec4 v=vec4(mod(fi,2.0),mod(floor(fi/2.0),2.0),mod(floor(fi/4.0),2.0),floor(fi/8.0))*2.0-1.0;
      vec4 a=tesP(v,A);
      vec3 da=q-a.xyz; nod=min(nod,dot(da,da));
      for(int k=0;k<4;k++){
        vec4 m=k==0?vec4(1.0,0.0,0.0,0.0):(k==1?vec4(0.0,1.0,0.0,0.0):(k==2?vec4(0.0,0.0,1.0,0.0):vec4(0.0,0.0,0.0,1.0)));
        if(dot(v,m)<0.0){   // chaque arête une seule fois : du sommet « moins » vers le sommet « plus »
          vec4 b=tesP(v+2.0*m,A);
          vec3 pa=q-a.xyz, ba=b.xyz-a.xyz; float hh=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
          vec3 dd=pa-ba*hh; float d2=dot(dd,dd);
          if(d2<dmin){ dmin=d2; dk=mix(a.w,b.w,hh); }
        }
      }
    }
    vec3 col=mix(uC2,uC3,smoothstep(0.3,0.75,dk));
    float fl=0.85+0.15*sin(lp*3.0);
    e=mix(col,vec3(1.0),0.35)*exp(-dmin/0.0005)*7.0*fl + col*exp(-sqrt(dmin)*16.0)*0.55
     + mix(uC3,vec3(1.0),0.6)*exp(-nod/0.0012)*10.0;
    float neb=fbm(q*2.0+so);
    e+=uC1*smoothstep(0.55,0.85,neb)*0.6;
    e*=smoothstep(0.98,0.88,length(q));
    return vec4(uC1*0.2,0.7);
  }
#elif MODE==67
  { // sceau arcanique : un cercle magique gravé de lumière. Les runes tournent dans un sens, l'étoile à six branches dans l'autre,
    // le triangle du centre encore plus vite, et des étincelles montent ; tout respire au même rythme
    float t=mod(uTime,3.9269908), lp=t*1.6;
    float h=q.z; vec2 p=q.xy*1.4; float rr=length(p)+1e-4, a=atan(p.y,p.x);   // dessiné plus petit : la loupe du verre le grossit
    float lay=exp(-h*h/0.012);
    float pul=0.75+0.25*sin(lp*2.0);
    float ln=exp(-pow((rr-0.84)/0.018,2.0))+0.8*exp(-pow((rr-0.785)/0.011,2.0))
            +exp(-pow((rr-0.6)/0.015,2.0))+0.8*exp(-pow((rr-0.555)/0.01,2.0))+exp(-pow((rr-0.28)/0.012,2.0));
    // les runes : 36 cases entre les deux cercles, 6 signes qui reviennent 6 fois ; un sixième de tour par boucle
    float cs=(a+lp/6.0)/6.2831853*36.0; float ci=floor(cs);
    vec2 g=vec2((fract(cs)-0.5)*1.85,(rr-0.69)/0.065);
    float gid=mod(ci,6.0);
    float g1=h31(vec3(gid,so.x,1.0)), g2=h31(vec3(gid,so.y,2.0)), g3=h31(vec3(gid,so.z,3.0));
    float x0=(g1-0.5)*0.5;
    float rd=segM(g,vec2(x0,-0.7),vec2(x0,0.7));
    if(g2>0.35) rd=min(rd,segM(g,vec2(-0.5,(g2-0.6)*1.4),vec2(0.5,-(g2-0.6)*1.4)));
    if(g3>0.5) rd=min(rd,abs(length(g-vec2(0.0,(g3-0.75)*1.6))-0.26));
    if(g1<0.5) rd=min(rd,min(segM(g,vec2(-0.45,0.65),vec2(0.0,0.25)),segM(g,vec2(0.0,0.25),vec2(0.45,0.65))));
    float run=exp(-rd*rd/0.02)*step(abs(g.y),1.0);
    // l'étoile à six branches (6 cordes du cercle 0,555) et le triangle du centre (3 cordes du cercle 0,28)
    vec2 ph=mrot(-lp/6.0)*p; float hx=1e3;
    for(int i=0;i<6;i++){ float an=float(i)*1.0471976+0.5235988; hx=min(hx,abs(dot(ph,vec2(cos(an),sin(an)))-0.2775)); }
    hx=exp(-hx*hx/0.00018)*step(rr,0.555);
    vec2 pt=mrot(lp/3.0)*p; float tr=1e3;
    for(int i=0;i<3;i++){ float an=float(i)*2.0943951+1.5707963; tr=min(tr,abs(dot(pt,vec2(cos(an),sin(an)))+0.14)); }
    tr=exp(-tr*tr/0.00014)*step(rr,0.28);
    // six petites lunes sur le grand cercle
    vec2 po=mrot(lp/6.0)*p; float ma=atan(po.y,po.x); float mc=mod(ma+0.5235988,1.0471976)-0.5235988;
    vec2 mp=vec2(cos(mc),sin(mc))*length(po)-vec2(0.812,0.0); float moon=exp(-dot(mp,mp)/0.0006);
    // des étincelles qui montent d'une case par boucle
    vec2 sp=p*9.0+vec2(0.0,-lp/6.2831853); vec2 sid=floor(sp), sfr=fract(sp)-0.5;
    float spark=step(0.86,h31(vec3(sid,so.x)))*exp(-dot(sfr,sfr)/0.006)*smoothstep(1.2,0.4,rr);
    float core=exp(-rr*rr/0.004)*(1.2+pul);
    e=(mix(uC2,vec3(1.0),0.3)*ln*6.0+mix(uC3,vec3(1.0),0.3)*run*8.0+mix(uC2,uC3,0.5)*hx*8.0+mix(uC3,vec3(1.0),0.3)*tr*9.0
      +vec3(1.0)*moon*6.0+mix(uC3,vec3(1.0),0.5)*core*6.0)*lay*pul + mix(uC2,vec3(1.0),0.4)*spark*3.0*exp(-h*h/0.05);
    e+=uC1*smoothstep(0.55,0.85,fbm(q*2.2+so))*0.5 + mix(uC2,uC3,0.5)*exp(-pow((rr-0.69)/0.08,2.0))*lay*0.35;   // une lueur sous l'anneau de runes
    e*=smoothstep(0.98,0.9,length(q));
    return vec4(uC1*0.2,0.9);
  }
#elif MODE==68
  { // plasma : une boule plasma, comme au palais de la découverte. Un cœur brûlant au centre lâche des éclairs
    // qui se tordent et cherchent le bord du verre, où ils s'écrasent en petites taches de lumière.
    // Les 3 couleurs du coloris : les éclairs en prennent une chacun, à tour de rôle ; le cœur est de la 3e, son halo de la 2e, la brume du verre de la 1re
    float t=mod(uTime,3.9269908), lp=t*1.6;
    float rr=length(q)+1e-4; vec3 u=q/rr;
    vec3 E=vec3(0.0); float jit=noise(q*16.0+so)-0.5;
    vec3 c1g=uC1/max(max(uC1.r,max(uC1.g,uC1.b)),0.35);
    for(int i=0;i<9;i++){
      float fi=float(i);
      float b=fi*2.3999632+0.45*sin(lp+fi*1.7);
      float z=(fract(fi*0.618+so.x*0.01)-0.5)*1.4+0.25*sin(lp+fi*2.9);
      vec3 wg=vec3(sin(rr*7.0+fi*2.0+lp),cos(rr*9.0+fi*3.0-lp),sin(rr*8.0+fi*5.0+lp*2.0))*0.22*rr;
      vec3 dir=normalize(vec3(cos(b),sin(b),z)+wg+jit*0.12*rr);
      float d=length(u-dir)*rr;
      float wd=0.013+0.02*(1.0-rr);
      float fl=0.7+0.3*sin(lp*2.0+fi*1.7);
      float kc=mod(fi,3.0); vec3 fc=kc<1.0?c1g:(kc<2.0?uC2:uC3);
      vec3 col=mix(mix(fc,vec3(1.0),0.5),fc*1.15,smoothstep(0.12,0.3,rr));   // blanc tout près du cœur, de sa couleur ensuite
      E+=(col*exp(-d*d/(wd*wd))*6.0+fc*exp(-d*d/(wd*wd*6.0))*2.5+fc*exp(-d*12.0)*0.6)*fl*smoothstep(0.08,0.16,rr)*smoothstep(0.97,0.86,rr);
      vec3 ud=u-dir; E+=mix(fc,vec3(1.0),0.3)*exp(-pow((rr-0.86)/0.035,2.0))*exp(-dot(ud,ud)/0.004)*6.0*fl;
    }
    E+=mix(uC3,vec3(1.0),0.45)*exp(-rr*rr/0.01)*9.0 + uC2*exp(-rr*5.0)*1.6 + c1g*smoothstep(0.55,0.95,rr)*0.35;
    e=E;
    return vec4(uC1*0.12,0.5);
  }
#elif MODE==69
  { // ouroboros : le serpent qui se mord la queue. Il fait le tour du verre une fois par boucle, en relief ; ses écailles de la 2e couleur
    // ont un liseré de lumière, son ventre est de la 3e couleur, ses yeux brillent, et au milieu de l'anneau une lueur respire
    float t=mod(uTime,3.9269908), lp=t*1.6;
    vec3 p=q*1.12;   // un peu plus petit : la loupe du verre le grossit
    float ra=length(p.xy)+1e-4, ang=atan(p.y,p.x);
    float H=lp;   // l'angle de la tête
    float s=mod(H-ang,6.2831853);   // 0 à la tête, 2π au bout de la queue (qui entre dans la gueule)
    float Rr=0.55+0.03*sin(s*4.0), zc=0.06*sin(s*3.0);
    float rt=0.15*(1.0-0.8*smoothstep(3.6,6.25,s))*(1.0+0.12*smoothstep(0.6,0.0,s));
    vec2 tc=vec2(ra-Rr,p.z-zc);
    float dT=length(tc)-rt;
    vec3 N=vec3(cos(H),sin(H),0.0), T=vec3(-sin(H),cos(H),0.0);
    vec3 hv=p-0.55*N-0.06*T;   // la tête, un peu en avant : elle avale le bout de la queue
    vec3 hl=vec3(dot(hv,T)/0.26,dot(hv,N)/0.19,hv.z/0.15);
    float dH=(length(hl)-1.0)*0.15;
    float kk=clamp(0.5+0.5*(dH-dT)/0.06,0.0,1.0); float d=mix(dH,dT,kk)-0.06*kk*(1.0-kk);
    // le relief : la normale du corps ou de la tête, éclairée d'en haut à gauche
    vec3 nT=normalize(vec3(tc.x*p.xy/ra,tc.y));
    vec3 gH=T*(hl.x/0.26)+N*(hl.y/0.19)+vec3(0.0,0.0,hl.z/0.15);
    vec3 nn=normalize(mix(normalize(gH),nT,kk));
    vec3 Ld=normalize(vec3(-0.5,0.6,0.75));
    float dif=max(dot(nn,Ld),0.0), spc=pow(max(dot(reflect(-Ld,nn),vec3(0.0,0.0,1.0)),0.0),24.0);
    float phi=atan(tc.y,tc.x);
    vec2 sc=vec2(s*10.0,phi*1.3); sc.x+=mod(floor(sc.y),2.0)*0.5; vec2 sf=fract(sc)-0.5;
    float ed=smoothstep(0.32,0.47,abs(sf.x)+abs(sf.y)*0.8);
    float belly=smoothstep(0.2,-0.5,cos(phi))*kk;
    vec3 body=mix(mix(uC2,uC2*0.35,ed),mix(uC3,vec3(1.0),0.2),belly*0.7);
    body=body*(0.25+0.95*dif)+vec3(1.0)*spc*0.6;
    vec3 e1=0.6*N+0.17*T+vec3(0.0,0.0,0.13);
    vec3 a1=p-e1; float eye=exp(-dot(a1,a1)/0.0009);
    float inS=smoothstep(0.012,-0.012,d);
    float rimS=smoothstep(-0.03,0.0,d)*inS;
    float pul=0.8+0.2*sin(lp*2.0);
    e=mix(uC3,vec3(1.0),0.3)*ed*rimS*2.5 + mix(uC3,vec3(1.0),0.5)*eye*30.0
     + uC2*exp(-max(d,0.0)*14.0)*(1.0-inS)*0.6
     + (mix(uC3,vec3(1.0),0.3)*exp(-dot(p,p)/0.03)*2.5*pul + uC1*smoothstep(0.55,0.85,fbm(q*2.4+so))*0.7)*(1.0-inS);
    return vec4(mix(uC1*0.2,body,inS), 0.8+inS*70.0);
  }
#elif MODE==70
  { // kaléidoscope infini : une rosace à six branches dans laquelle on plonge sans fin ; les anneaux de pétales naissent au bord
    // et s'enfoncent vers le centre, chacun d'une couleur du coloris
    float t=mod(uTime,3.9269908), lp=t*1.6;
    float h=q.z; vec2 p=q.xy*1.3; float rr=length(p)+1e-4, a=atan(p.y,p.x);
    float lay=exp(-h*h/0.004);   // une couche très fine : sinon le verre étire la rosace en traînées
    float u=log(rr)*1.7-lp/6.2831853*3.0;   // trois anneaux par boucle : les couleurs retombent juste
    float cu=floor(u), fu=fract(u);
    float sg=a/6.2831853*6.0+mod(cu,2.0)*0.5; float fs=abs(fract(sg)-0.5)*2.0;
    vec2 L=vec2((fu-0.5)*1.6,fs*1.04);
    float d1=length(L*vec2(1.0,1.25))-0.55;
    float dg=abs(L.x)+abs(L.y-1.0)-0.35;
    vec3 col=pal3(mod(cu,3.0)), col2=pal3(mod(cu+1.0,3.0));
    vec3 E=col*smoothstep(0.02,-0.04,d1)*(0.6+0.8*smoothstep(-0.5,0.0,d1)) + mix(col,vec3(1.0),0.5)*exp(-d1*d1/0.0025)*3.5
          +mix(col2,vec3(1.0),0.2)*smoothstep(0.02,-0.03,dg)*1.2 + mix(col2,vec3(1.0),0.5)*exp(-dg*dg/0.0015)*2.5;
    E*=smoothstep(0.02,0.12,rr)*smoothstep(0.98,0.82,rr);   // une rosace ronde, avec une marge de verre sombre autour
    E+=mix(uC3,vec3(1.0),0.6)*exp(-rr*rr/0.003)*6.0;
    e=E*lay*5.0;
    return vec4(uC1*0.2,0.9);
  }
