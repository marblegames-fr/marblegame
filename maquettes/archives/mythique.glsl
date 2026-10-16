#elif MODE==64
  { // phénix : un oiseau de feu bat des ailes au cœur du verre, entouré de flammes qui montent et d'étincelles
    float r=length(q), t=uTime;
    vec2 p=q.xy*1.25; float pz=q.z;
    float flap=sin(t*3.2);
    float body=length(p*vec2(2.6,1.2))-0.2;
    float head=length(p-vec2(0.0,0.3))-0.075;
    float d=min(body,head);
    for(int i=-1;i<=1;i++){ float fi=float(i);   // la queue : trois longues plumes qui ondulent
      vec2 a=vec2(0.0,-0.15), b=vec2(fi*0.22+0.04*sin(t*2.0+fi), -0.64);
      vec2 pa=p-a, ba=b-a; float h=clamp(dot(pa,ba)/dot(ba,ba),0.0,1.0);
      d=min(d, length(pa-ba*h)-0.03*(0.4+h*1.5)); }
    // les ailes : une lame courbée de chaque côté, qui monte et descend
    vec2 w=vec2(abs(p.x),p.y)-vec2(0.05,0.08);
    float an=0.2+0.55*flap; float c=cos(an), s=sin(an); w=vec2(c*w.x+s*w.y, -s*w.x+c*w.y);
    float L=0.64, x=clamp(w.x/L,0.0,1.0);
    float th=0.13*pow(1.0-x,0.7)*(0.72+0.28*abs(sin(x*18.0)))+0.01;   // les plumes au bout de l'aile
    float wing=max(abs(w.y-0.14*x*x*(1.0+0.6*flap))-th, max(-w.x, w.x-L));
    d=min(d,wing);
    float inB=smoothstep(0.02,-0.02,d)*smoothstep(0.09,0.03,abs(pz));
    float fl=noise(vec3(p*9.0,t*2.0)+so);
    vec3 fire=mix(uC2,mix(uC3,vec3(1.0,0.95,0.8),0.5),clamp(smoothstep(0.0,-0.08,d)+0.3*fl,0.0,1.0));
    float f=fbm(vec3(q.x*3.0,q.y*2.2-t*1.4,q.z*3.0)+so);   // les flammes : du feu qui monte sans arrêt
    float flame=smoothstep(0.52,0.85,f)*smoothstep(0.95,0.5,r)*smoothstep(-0.9,0.2,q.y);
    float glow=exp(-max(d,0.0)*9.0)*smoothstep(0.25,0.0,abs(pz));
    e=fire*inB*9.0+mix(uC2,uC3,f)*flame*3.0+uC2*glow*1.8;
    vec3 g=q*14.0+so+vec3(0.0,-t*0.8,0.0); vec3 fc=fract(g)-0.5;
    e+=mix(uC3,vec3(1.0),0.5)*step(0.95,h31(floor(g)))*smoothstep(0.15,0.0,length(fc))*5.0*smoothstep(0.95,0.6,r);
    return vec4(uC1*0.12, 0.6+inB*4.0);
  }
#elif MODE==65
  { // supernova : une étoile qui palpite au cœur du verre et lâche des anneaux de lumière qui s'élargissent jusqu'au bord
    float r=length(q), t=uTime;
    float beat=0.5+0.5*sin(t*3.0);
    vec3 u=q/max(r,1e-4);
    float spikes=pow(noise(u*6.0+so+vec3(t*0.3)),3.0);
    float core=exp(-r*r*(60.0-20.0*beat))*(1.5+beat);
    float rays=spikes*exp(-r*3.5)*1.6;
    float rings=0.0;
    for(int i=0;i<3;i++){ float ph=fract(t*0.28+float(i)/3.0); float R=0.08+ph*0.85;
      float wob=0.03*noise(u*8.0+so+float(i)*5.0);
      rings+=exp(-pow((r-R-wob)/0.035,2.0))*(1.0-ph)*(0.6+0.8*noise(q*10.0+so+float(i)));
    }
    e=mix(uC3,vec3(1.0),0.45)*core*6.0+mix(uC2,uC3,0.5)*rays*4.0+mix(uC2,vec3(1.0),0.3)*rings*4.5;
    vec3 g=q*15.0+so; vec3 id=floor(g), fc=fract(g)-0.5;
    e+=vec3(step(0.96,h31(id))*smoothstep(0.18,0.0,length(fc)))*(3.0+3.0*sin(t*5.0+h31(id+2.0)*40.0));
    e*=smoothstep(0.97,0.88,r);
    return vec4(uC1*0.12, 0.8+rings*1.5);
  }
#elif MODE==66
  { // vortex : un tourbillon de lumière qui tourne vraiment sur lui-même et aspire des étincelles vers son œil noir.
    // Les 3 couleurs du coloris : le verre et ses volutes (la 1re), et les bras du tourbillon, chacun de sa couleur
    // (la 2e, la 3e, et la 1re éclaircie) : deux coloris proches ne donnent pas le même vortex.
    float r=length(q), t=uTime;
    // le tourbillon nous fait face (la bille est posée « de face ») : la spirale est dessinée dans une couche épaisse du verre
    float h=q.z; vec2 ip=q.xy; float rr=length(ip)+1e-4; float ang=atan(ip.y,ip.x);
    float sw=ang+log(rr)*2.8-t*1.6;   // la spirale tourne
    float s3=sw*3.0/6.2831853+fbm(q*3.0+so)*0.25;
    float arm=pow(0.5+0.5*cos(s3*6.2831853),2.0);
    float k=mod(floor(s3+0.5),3.0);
    vec3 ac=k<1.0?uC2:(k<2.0?uC3:mix(uC1,vec3(1.0),0.4));
    float thick=0.16+0.12*rr;
    float disk=exp(-h*h/(thick*thick))*smoothstep(0.92,0.3,rr)*smoothstep(0.04,0.14,rr);
    vec2 pp=vec2((ang-t*1.6)*12.0/6.2831853, log(rr)*4.0+t*1.5); vec2 id=floor(pp), f=fract(pp)-0.5;
    float hk=h31(vec3(id,so.x));
    float sp=step(0.65,hk)*smoothstep(0.32,0.06,length(f))*exp(-h*h/(thick*thick*0.5))*smoothstep(0.95,0.5,rr);
    vec3 spc=hk<0.8?mix(uC3,vec3(1.0),0.5):mix(uC2,vec3(1.0),0.5);
    float eye=exp(-pow((rr-0.09)/0.025,2.0))*exp(-h*h*80.0);
    float neb=fbm(q*2.2+so+vec3(0.0,0.0,t*0.1));   // les volutes du verre, de la 1re couleur
    e=ac*disk*(0.12+arm)*5.5+spc*sp*9.0+mix(uC3,vec3(1.0),0.5)*eye*12.0
     +mix(uC1,vec3(1.0),0.15)*smoothstep(0.5,0.8,neb)*(1.0-disk)*0.9;
    float hole=smoothstep(0.09,0.06,length(q));
    e*=(1.0-hole)*smoothstep(0.97,0.88,r);
    return vec4(uC1*0.2, 0.9+hole*80.0+disk*arm*2.0);
  }
#elif MODE==67
  { // cœur battant : un cœur de cristal qui bat (boum-boum) au milieu du verre ; à chaque battement, une onde de lumière part de lui
    float r=length(q), t=uTime;
    float ph=fract(t*0.9);
    float beat=exp(-pow((ph-0.05)*14.0,2.0))+0.7*exp(-pow((ph-0.22)*14.0,2.0));
    float sc=1.0+0.13*beat;
    vec2 p=q.xy/sc*1.9;
    float d2=sdHeart(p)/1.9*sc;
    float depth=0.2*sqrt(clamp(-d2/0.22,0.0,1.0));
    float inH=step(d2,0.0)*smoothstep(depth+0.01,depth-0.01,abs(q.z));
    vec3 g=q*9.0+so; float fac=h31(floor(g));   // des facettes taillées
    vec3 hc=mix(uC2*0.85,uC3,fac*0.5)*(0.8+0.45*beat);
    float rim=exp(-abs(d2)*40.0)*smoothstep(0.25,0.0,abs(q.z));
    float wave=exp(-pow((d2-ph*0.75)/0.03,2.0))*(1.0-ph)*smoothstep(0.35,0.0,abs(q.z));
    e=hc*inH*(1.6+2.4*beat)+mix(uC2,vec3(1.0),0.5)*rim*(2.5+4.5*beat)+mix(uC2,uC3,0.5)*wave*6.0+vec3(1.0)*step(0.93,fac)*inH*3.0*beat;
    vec3 gs=q*14.0+so; vec3 fs=fract(gs)-0.5;
    e+=mix(uC3,vec3(1.0),0.5)*step(0.97,h31(floor(gs)))*smoothstep(0.15,0.0,length(fs))*(2.0+4.0*beat);
    e*=smoothstep(0.97,0.88,r);
    if(inH>0.5) return vec4(hc, 12.0);
    return vec4(uC1*0.12, 0.5);
  }
