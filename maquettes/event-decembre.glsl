#if MODE>=130
// Maquette du 9 novembre 2026 : trois thèmes pour l'event du 1er décembre (familles 130 à 132, à renuméroter si on l'intègre)
//  130 : Ballon — un ballon de foot (12 pentagones, 20 hexagones) au cœur du verre
//  131 : Œil    — un œil, son iris strié et sa pupille, qui nous regarde depuis le verre
//  132 : Bonbon — un bonbon à rayures dans sa papillote de cellophane
// (pour l'event retenu, il faudra un seul de ces blocs)
#if MODE==130
// le ballon : chaque point prend la face du ballon (icosaèdre tronqué) vers laquelle il pointe ; renvoie 1 = pentagone, et l'écart à la couture
float ballon(vec3 n, out float seam){
  const float PH=1.618034;
  float b1=-1.0, b2=-1.0, kind=0.0;
  for(int i=0;i<32;i++){
    vec3 v; float fi=float(i); float d;
    if(i<12){ int a=i/4, s=i-a*4; vec2 sg=vec2(s<2?1.0:-1.0, mod(fi,2.0)<0.5?1.0:-1.0);
      v = a==0 ? vec3(0.0,sg.x,sg.y*PH) : (a==1 ? vec3(sg.x,sg.y*PH,0.0) : vec3(sg.y*PH,0.0,sg.x));
      d=dot(n,normalize(v))/2.32744; }
    else if(i<20){ int j=i-12; v=vec3(mod(float(j),2.0)<0.5?1.0:-1.0, mod(floor(float(j)/2.0),2.0)<0.5?1.0:-1.0, j<4?1.0:-1.0);
      d=dot(n,normalize(v))/2.26728; }
    else { int j=i-20, a=j/4, s=j-a*4; vec2 sg=vec2(s<2?1.0:-1.0, mod(float(j),2.0)<0.5?1.0:-1.0);
      v = a==0 ? vec3(0.0,sg.x*PH,sg.y/PH) : (a==1 ? vec3(sg.x*PH,sg.y/PH,0.0) : vec3(sg.y/PH,0.0,sg.x*PH));
      d=dot(n,normalize(v))/2.26728; }
    if(d>b1){ b2=b1; b1=d; kind=i<12?1.0:0.0; } else if(d>b2) b2=d;
  }
  seam=(b1-b2)*2.3;
  return kind;
}
#endif
#endif
//@@FAM
#elif MODE==130
  { // ballon : un ballon de foot au cœur d'un verre teinté, pentagones de la 2e couleur, hexagones de la 3e, coutures en creux
    float rr=length(q), R=0.5;
    vec3 glass=mix(uC1,vec3(1.0),0.1)*(0.7+0.25*smoothstep(0.95,0.2,rr));
    if(rr<R){
      vec3 n=q/rr; float seam; float pent=ballon(n,seam);
      float s=smoothstep(0.012,0.035,seam);
      vec3 c=mix(uC3,uC2,pent)*(0.92+0.08*noise(n*40.0+so));
      c*=0.35+0.65*s;
      // le cuir est bombé entre les coutures : la lumière glisse dessus
      vec3 L=normalize(vec3(-0.5,0.62,0.6)); float dif=max(dot(n,L),0.0);
      float sp=pow(max(dot(n,normalize(L+vec3(0.0,0.0,1.0))),0.0),40.0)*s;
      return vec4(c*(0.3+0.85*dif)+vec3(sp*0.9), 300.0);
    }
    // de fines bulles d'air dans le verre
    vec3 g=q*11.0+so; vec3 fc=fract(g)-0.5;
    float bub=step(0.93,h31(floor(g)))*smoothstep(0.1,0.05,length(fc))*smoothstep(0.08,0.12,length(fc)+0.05);
    e=vec3(1.0)*bub*0.6;
    return vec4(glass, 0.2+bub*6.0);
  }
#elif MODE==131
  { // œil : un œil au cœur du verre, qui nous regarde ; l'iris passe de la 2e couleur (au bord) à la 3e (autour de la pupille)
    bool couche=uAsp>1.2; vec3 p=couche?vec3(q.x,-q.z,q.y):q;
    float rr=length(p), R=0.52;
    vec3 glass=mix(uC1,vec3(1.0),0.15)*(0.7+0.25*smoothstep(0.95,0.2,rr));
    if(rr<R){
      vec3 n=p/rr; float rho=length(n.xy), ang=atan(n.y,n.x);
      vec3 L=normalize(vec3(-0.5,0.62,0.6)); float dif=max(dot(n,L),0.0);
      vec3 c;
      if(n.z>0.0 && rho<0.5){
        float t=rho/0.5;
        float fib=0.75+0.25*sin(ang*38.0+3.0*noise(vec3(ang*6.0,t*4.0,1.0)+so))+0.2*(noise(vec3(ang*20.0,t*8.0,3.0)+so)-0.5);
        c=mix(uC3, uC2, smoothstep(0.25,0.85,t))*fib;
        c=mix(c, uC3*1.3, smoothstep(0.42,0.3,t)*smoothstep(0.3,0.42,t)*0.6);   // la collerette autour de la pupille
        c*=mix(1.0,0.25,smoothstep(0.82,1.0,t));                                 // le cercle sombre du bord de l'iris
        float pup=smoothstep(0.37,0.33,t);
        c=mix(c, vec3(0.02), pup);
        e=uC3*0.25*(1.0-pup)*smoothstep(0.9,0.3,t);
        dif=0.55+0.45*dif;
      } else {
        // le blanc de l'œil, et quelques petits vaisseaux qui partent du bord
        float v=abs(noise(vec3(ang*7.0, n.z*9.0, 5.0)+so)-0.5);
        float vein=smoothstep(0.03,0.0,v)*smoothstep(0.45,-0.4,n.z);
        c=mix(vec3(0.96,0.94,0.9), vec3(0.85,0.75,0.72), smoothstep(0.3,-0.6,n.z));
        c=mix(c, vec3(0.75,0.12,0.12), vein*0.7);
      }
      // la cornée : un reflet bien net qui donne vie au regard
      float sp=pow(max(dot(n,normalize(L+vec3(0.0,0.0,1.0))),0.0),90.0);
      return vec4(c*(0.3+0.8*dif)+vec3(sp*1.4), 300.0);
    }
    e=mix(uC2,uC3,0.5)*0.25*exp(-(rr-R)*9.0)*step(0.0,p.z+0.2);   // un halo de la couleur de l'iris autour de l'œil
    return vec4(glass, 0.22);
  }
#elif MODE==132
  { // bonbon : un bonbon rayé (2e et 3e couleur) dans sa papillote de cellophane, au cœur d'un verre sucré
    bool couche=uAsp>1.2; vec3 p=couche?vec3(q.x,-q.z,q.y):q;
    p.xy=mat2(0.94,0.34,-0.34,0.94)*p.xy;   // un peu penché
    float rr=length(q);
    vec3 glass=mix(uC1,vec3(1.0),0.2)*(0.75+0.2*smoothstep(0.95,0.2,rr));
    vec3 eb=p/vec3(0.36,0.25,0.23); float body=length(eb);
    vec3 L=normalize(vec3(-0.5,0.62,0.6));
    if(body<1.0){
      vec3 n=normalize(p/vec3(0.13,0.0625,0.053));
      float st=sin((p.x*2.6+atan(p.z,p.y)/6.2832)*6.2832*2.0);
      vec3 c=mix(uC2, uC3, smoothstep(-0.15,0.15,st));
      float dif=max(dot(n,L),0.0), sp=pow(max(dot(n,normalize(L+vec3(0.0,0.0,1.0))),0.0),60.0);
      return vec4(c*(0.35+0.8*dif)+vec3(sp*1.2), 300.0);
    }
    // la papillote : de chaque côté, la cellophane pincée puis évasée en éventail plissé
    float ax=abs(p.x), rz=length(p.yz);
    if(ax>0.3 && ax<0.74){
      float t=(ax-0.38)/0.36;
      float rad = t<0.0 ? 0.06+(-t)*0.9 : 0.045+0.3*pow(clamp(t,0.0,1.0),0.8);
      float a=atan(p.z,p.y), pl=0.5+0.5*sin(a*9.0+ax*14.0);
      rad*=0.85+0.25*pl;
      if(rz<rad && rz>rad-0.035-0.04*step(t,0.0)){
        vec3 cel=mix(uC3, vec3(1.0), 0.55);
        e=cel*(0.35+1.2*pow(pl,6.0))*smoothstep(1.0,0.7,t);
        return vec4(cel*(0.5+0.5*pl), 14.0);
      }
    }
    // du sucre qui scintille dans le verre
    vec3 g=q*14.0+so; vec3 fc=fract(g)-0.5;
    float sug=step(0.9,h31(floor(g)))*smoothstep(0.12,0.03,length(fc))*smoothstep(0.95,0.8,rr)*step(0.55,length(eb));
    e=mix(uC3,vec3(1.0),0.6)*sug*1.6;
    return vec4(glass, 0.18+sug*20.0);
  }
