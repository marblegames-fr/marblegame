// (6 novembre 2026, 3e partie) encore des Communs (199 à 222), des Peu communs (223 à 239) et des Rares (240 à 254)
// ===================== Communs =====================
#elif MODE==199
  { // cartes : les quatre couleurs du jeu de cartes, cœur et carreau de la 2e couleur, pique et trèfle de la 1re, sur un fond de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.75);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.2,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.9)*p;
      on*=step(0.12,h31(id)); float k=floor(h31(id+2.0)*4.0), d;
      if(k<0.5) d=heartD(p*vec2(1.0,-1.0)/0.3+vec2(0.0,0.55));
      else if(k<1.5) d=abs(p.x)/0.13+abs(p.y)/0.19-1.0;
      else if(k<2.5){ d=heartD(p/0.3+vec2(0.0,0.45)); d=min(d,max(abs(p.x)-0.02*(1.0+(-p.y-0.1)*8.0),abs(p.y+0.17)-0.06)/0.3); }
      else { d=min(min(length(p-vec2(0.0,0.07)),length(p-vec2(-0.07,-0.03))),length(p-vec2(0.07,-0.03)))-0.065; d=min(d,max(abs(p.x)-0.02*(1.0+(-p.y-0.05)*8.0),abs(p.y+0.13)-0.08)); }
      c=mix(c,k<1.5?uC2:brt(uC1,0.3)*0.5,step(d,0.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==200
  { // ancres : des ancres de marin de la 1re et de la 2e couleur, sur un fond clair rayé de la 3e
    vec3 u=normalize(q); vec3 c=mix(vec3(0.97,0.96,0.93),uC3,0.18*step(0.5,fract(u.y*7.0)));
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*1.0)*p;
      on*=step(0.12,h31(id));
      float d=segM(p,vec2(0.0,0.18),vec2(0.0,-0.2)); d=min(d,segM(p,vec2(-0.09,0.11),vec2(0.09,0.11)));
      d=min(d,abs(length(p-vec2(0.0,0.23))-0.04));
      d=min(d,abs(length(p-vec2(0.0,-0.02))-0.17)+step(-0.08,p.y));
      d=min(d,min(segM(p,vec2(-0.17,-0.03),vec2(-0.2,-0.08)),segM(p,vec2(0.17,-0.03),vec2(0.2,-0.08))));
      c=mix(c,h31(id+2.0)<0.5?brt(uC1,0.4)*0.75:uC2,smoothstep(0.028,0.02,d)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==201
  { // couronnes : de petites couronnes d'or (3e couleur), sertie de pierres de la 1re et de la 2e couleur
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93); vec3 gold=mix(vec3(1.0,0.8,0.32),uC3,0.45);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.8)*p;
      on*=step(0.12,h31(id)); float s=(p.x+0.17)/0.34*3.0, tri=abs(fract(s)-0.5)*2.0;
      float body=step(abs(p.x),0.17)*step(-0.12,p.y)*step(p.y,0.13-0.15*tri);
      float balls=0.0; for(int j=0;j<3;j++){ balls=max(balls,step(length(p-vec2(-0.113+0.113*float(j),0.15)),0.028)); }
      float band=step(-0.12,p.y)*step(p.y,-0.05);
      float gem=step(length(vec2(fract(p.x/0.085+0.5)-0.5,(p.y+0.085)/0.085)),0.3)*band*step(abs(p.x),0.16);
      vec3 cc=gold*(0.75+0.35*smoothstep(-0.12,0.1,p.y)); cc=mix(cc,gold*0.7,band*0.5);
      cc=mix(cc,mod(floor(p.x/0.085+0.5),2.0)<1.0?brt(uC1,0.45):uC2,gem);
      c=mix(c,cc,max(body,balls)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==202
  { // clés : de vieilles clés à anneau, de 3 couleurs, semées sur un fond clair
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id));
      float d=abs(length(p-vec2(0.0,0.14))-0.07)-0.022;
      d=min(d,segM(p,vec2(0.0,0.07),vec2(0.0,-0.22))-0.02);
      d=min(d,max(abs(p.x-0.045)-0.035,abs(p.y+0.19)-0.022)); d=min(d,max(abs(p.x-0.035)-0.025,abs(p.y+0.12)-0.018));
      float k=h31(id+2.0); vec3 kc=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3);
      c=mix(c,kc*(0.8+0.3*smoothstep(0.0,-0.02,d)),step(d,0.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==203
  { // flèches : des flèches d'archer aux plumes colorées, qui filent dans tous les sens
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.82);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id));
      float shaft=step(segM(p,vec2(-0.22,0.0),vec2(0.12,0.0)),0.012);
      float head=step(0.08,p.x)*step(p.x,0.25)*step(abs(p.y),(0.25-p.x)*0.55);
      float fl=step(-0.25,p.x)*step(p.x,-0.13)*step(abs(p.y),0.06-(p.x+0.25)*0.3)*step(0.012,abs(p.y));
      float k=h31(id+2.0); vec3 fc=k<0.5?uC2:brt(uC1,0.45);
      c=mix(c,vec3(0.45,0.3,0.18),shaft*on); c=mix(c,vec3(0.55),head*on); c=mix(c,fc,fl*on); }
    return vec4(c, 200.0);
  }
#elif MODE==204
  { // soleils : de petits soleils rayonnants, le cœur de la 3e couleur, les rayons de la 2e, sur un ciel de la 1re
    vec3 u=normalize(q); vec3 c=mix(brt(uC1,0.45),vec3(1.0),0.15);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.15,h31(id)); float r=length(p), a=atan(p.y,p.x);
      float ray=step(0.11,r)*step(r,0.21)*step(abs(fract(a/6.2831853*10.0)-0.5),0.22*(0.21-r)/0.1);
      c=mix(c,uC2,ray*on); c=mix(c,mix(uC3,vec3(1.0),0.25)*(0.85+0.2*(1.0-r/0.1)),step(r,0.1)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==205
  { // cerises : des paires de cerises de la 2e couleur, leurs queues de la 1re et une feuille de la 3e
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*1.4)*p;
      on*=step(0.12,h31(id)); vec2 a=vec2(-0.08,-0.1), b=vec2(0.08,-0.12), t=vec2(0.02,0.17);
      float st=min(segM(p,a+vec2(0.02,0.06),t),segM(p,b+vec2(-0.01,0.06),t));
      float leaf=step(length((mrot(0.6)*(p-vec2(0.08,0.17)))/vec2(0.07,0.03)),1.0);
      c=mix(c,brt(uC1,0.4)*0.7,smoothstep(0.014,0.008,st)*on); c=mix(c,uC3,leaf*on);
      for(int j=0;j<2;j++){ vec2 C=j==0?a:b; float L=length(p-C)/0.075;
        c=mix(c,uC2*(0.7+0.35*(1.0-L*L))+vec3(1.0)*smoothstep(0.3,0.0,length((p-C)/0.075-vec2(-0.35,0.35)))*0.6,step(L,1.0)*on); } }
    return vec4(c, 200.0);
  }
#elif MODE==206
  { // pommes : des pommes de la 1re et de la 2e couleur, avec leur queue et une feuille de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.82);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.8)*p;
      on*=step(0.12,h31(id));
      float d=min(length(p-vec2(-0.05,-0.01)),length(p-vec2(0.05,-0.01)))-0.12;
      d=max(d,-(length(p-vec2(0.0,0.16))-0.045));
      vec3 ac=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      float st=step(segM(p,vec2(0.0,0.08),vec2(0.02,0.18)),0.012);
      float leaf=step(length((mrot(-0.5)*(p-vec2(0.07,0.16)))/vec2(0.065,0.03)),1.0);
      c=mix(c,vec3(0.35,0.22,0.12),st*on); c=mix(c,uC3*0.85,leaf*on);
      c=mix(c,ac*(0.75+0.3*smoothstep(0.0,-0.12,d))+vec3(1.0)*smoothstep(0.05,0.0,length(p-vec2(-0.07,0.05)))*0.5,step(d,0.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==207
  { // poissons : de petits poissons rayés qui nagent dans tous les sens, de 3 couleurs, sur une eau claire
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.94,0.97,1.0),0.8);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id)); float k=h31(id+2.0); vec3 fc=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3), sc=k<0.34?uC2:(k<0.67?uC3:brt(uC1,0.45));
      float body=step(length((p-vec2(0.03,0.0))/vec2(0.15,0.085)),1.0);
      float tail=step(-0.21,p.x)*step(p.x,-0.1)*step(abs(p.y),(-0.1-p.x)*1.1);
      float strp=step(0.5,fract((p.x+0.1)*14.0))*step(abs(p.x),0.08);
      vec3 cc=mix(fc,sc,strp);
      cc=mix(cc,vec3(0.05),step(length(p-vec2(0.11,0.02)),0.016));
      c=mix(c,sc,tail*on); c=mix(c,cc,body*on); }
    return vec4(c, 200.0);
  }
#elif MODE==208
  { // oiseaux : de petits oiseaux tout ronds, de la 1re et de la 2e couleur, le bec et l'aile de la 3e
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.97,0.95);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.8)*p;
      if(h31(id+6.0)<0.5) p.x=-p.x; on*=step(0.12,h31(id));
      vec3 bc=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      float body=step(length((p-vec2(0.0,-0.02))/vec2(0.13,0.1)),1.0), head=step(length(p-vec2(0.1,0.07)),0.065);
      float beak=step(0.15,p.x)*step(p.x,0.21)*step(abs(p.y-0.07),(0.21-p.x)*0.5);
      float tail=step(-0.22,p.x)*step(p.x,-0.1)*step(abs(p.y-0.04-(-0.1-p.x)*0.6),0.03);
      float wing=step(length((mrot(0.3)*(p-vec2(-0.02,-0.01)))/vec2(0.08,0.045)),1.0);
      c=mix(c,bc*0.8,tail*on); c=mix(c,bc,max(body,head)*on); c=mix(c,uC3,max(beak,wing)*on);
      c=mix(c,vec3(0.05),step(length(p-vec2(0.12,0.09)),0.013)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==209
  { // pattes : des traces de pattes de chat, de la 1re et de la 2e couleur, qui se promènent sur un fond de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.7);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.3,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id)); vec3 pc=h31(id+2.0)<0.5?brt(uC1,0.4)*0.8:uC2;
      float d=length((p-vec2(0.0,-0.05))/vec2(0.085,0.07))-1.0;
      float t=min(min(length(p-vec2(-0.095,0.05)),length(p-vec2(-0.035,0.105))),min(length(p-vec2(0.035,0.105)),length(p-vec2(0.095,0.05))))-0.034;
      c=mix(c,pc,step(min(d,t/0.07),0.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==210
  { // chats : des têtes de chat aux oreilles pointues, de la 1re et de la 2e couleur, les yeux de la 3e
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.9)*p;
      on*=step(0.12,h31(id)); vec3 hc=h31(id+2.0)<0.5?brt(uC1,0.3)*0.6:uC2;
      float head=step(length(p/vec2(0.15,0.12)),1.0);
      vec2 e2=vec2(abs(p.x),p.y);
      float ear=inTri(e2,vec2(0.05,0.08),vec2(0.15,0.06),vec2(0.13,0.2));
      float eye=step(length((e2-vec2(0.06,0.02))/vec2(0.03,0.04)),1.0), pup=step(abs(e2.x-0.06),0.007)*eye;
      float nose=inTri(p,vec2(-0.02,-0.03),vec2(0.02,-0.03),vec2(0.0,-0.055));
      vec3 cc=mix(hc,uC3,eye); cc=mix(cc,vec3(0.05),pup); cc=mix(cc,mix(uC2,vec3(1.0,0.7,0.75),0.5),nose);
      c=mix(c,cc,max(head,ear)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==211
  { // fraises : des fraises de la 2e couleur, leurs petits grains de la 3e et leur collerette de feuilles de la 1re
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.93);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.9)*p;
      on*=step(0.12,h31(id));
      float wdt=0.13*(0.35+0.65*smoothstep(-0.2,0.07,p.y));
      float body=step(length(vec2(p.x/wdt,(p.y+0.02)/0.16)),1.0);
      vec2 sg=fract(vec2(p.x*20.0+0.5*floor(p.y*20.0),p.y*20.0))-0.5; float seed=step(length(sg*vec2(1.0,0.7)),0.18);
      vec3 cc=mix(uC2*(0.75+0.3*(1.0-abs(p.x)/0.13)),mix(uC3,vec3(1.0),0.3),seed);
      float lv=step(sdStar(mrot(0.3)*(p-vec2(0.0,0.13))*4.5)/4.5,0.0);
      c=mix(c,cc,body*on); c=mix(c,brt(uC1,0.45)*0.8,lv*on); }
    return vec4(c, 200.0);
  }
#elif MODE==212
  { // glands : des glands de chêne, le fruit de la 2e couleur et le chapeau quadrillé de la 1re, avec une feuille de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.85);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.1,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*1.2)*p;
      on*=step(0.12,h31(id));
      float nut=step(length((p-vec2(0.0,-0.05))/vec2(0.08,0.11)),1.0)*step(p.y,0.04);
      float cap=step(length((p-vec2(0.0,0.04))/vec2(0.1,0.06)),1.0)*step(0.03,p.y);
      float st=step(segM(p,vec2(0.0,0.09),vec2(0.02,0.14)),0.012);
      float hatch=step(0.5,fract((p.x+p.y)*35.0))*0.25;
      c=mix(c,uC2*(0.75+0.35*(1.0-abs(p.x)/0.08)),nut*on); c=mix(c,brt(uC1,0.4)*(0.65-hatch),max(cap,st)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==213
  { // biais : des rayures en biais de toutes les largeurs, des 3 couleurs et du blanc, comme une cravate d'écolier
    vec3 u=normalize(q); vec3 dir=normalize(vec3(0.7,0.7,0.2)+0.2*(vec3(h31(so),h31(so+1.0),h31(so+2.0))-0.5));
    float v=dot(u,dir)*10.0; float b=floor(v), f=fract(v); float m=mod(b,5.0);
    vec3 c=m<1.0?brt(uC1,0.45):(m<2.0?vec3(0.97):(m<3.0?uC2:(m<4.0?uC3:vec3(0.97))));
    c=mix(c,m<2.5?uC3:brt(uC1,0.45),step(abs(f-0.5),0.06)*step(0.5,mod(b,2.0)));
    return vec4(c, 200.0);
  }
#elif MODE==214
  { // hexagones : des carreaux à six côtés de 3 couleurs et blancs, bien serrés, avec leur joint
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(3.5+nb*0.3)+so.xy;
    vec2 R=vec2(1.0,1.7320508), H=R*0.5; vec2 a=mod(p,R)-H, b=mod(p-H,R)-H; vec2 gv=dot(a,a)<dot(b,b)?a:b; vec2 id=p-gv;
    float hd=max(dot(abs(gv),vec2(0.5,0.8660254)),abs(gv.x));
    float k=h31(vec3(floor(id*2.0+0.5),cf.w)); vec3 c=k<0.3?brt(uC1,0.45):(k<0.6?uC2:(k<0.85?uC3:vec3(0.97)));
    c*=0.88+0.15*smoothstep(0.5,0.1,hd);
    return vec4(mix(vec3(0.95,0.94,0.9),c,smoothstep(0.47,0.44,hd)), 200.0);
  }
#elif MODE==215
  { // arcs : des carrés coupés de quarts et de demi-cercles de 3 couleurs, comme une affiche des années 20
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.5+nb*0.25)+so.xy; vec2 id=floor(p), f=fract(p);
    float k=h31(vec3(id,cf.w)), o=floor(h31(vec3(id,cf.w+3.0))*4.0);
    vec2 cn=o<1.0?vec2(0.0):(o<2.0?vec2(1.0,0.0):(o<3.0?vec2(1.0):vec2(0.0,1.0)));
    float inC=k<0.6?step(length(f-cn),1.0):step(length(f-vec2(0.5,cn.y)),0.5);
    float k2=h31(vec3(id,cf.w+7.0)); vec3 a=k2<0.34?brt(uC1,0.45):(k2<0.67?uC2:uC3), b=k2<0.34?uC3:(k2<0.67?brt(uC1,0.45):uC2);
    vec3 c=mix(b,a,inC); if(h31(vec3(id,cf.w+9.0))<0.15) c=vec3(0.96,0.95,0.91);
    vec2 ed=min(f,1.0-f); c*=mix(0.85,1.0,smoothstep(0.0,0.03,min(ed.x,ed.y)));
    return vec4(c, 200.0);
  }
#elif MODE==216
  { // pyjama : de fines rayures doubles de la 1re et de la 2e couleur, avec de petits pois de la 3e entre elles
    vec3 u=normalize(q); float lon=atan(u.z,u.x); float x=lon/6.2831853*24.0; float f=fract(x)-0.5;
    vec3 c=vec3(0.97,0.96,0.93);
    c=mix(c,mod(floor(x),2.0)<1.0?brt(uC1,0.45):uC2,step(abs(abs(f)-0.12),0.035));
    vec2 d=vec2(abs(f+0.5)<0.5?0.0:0.0,0.0);
    float y=u.y*9.0; vec2 dp=vec2(fract(x+0.5)-0.5,(fract(y+0.5*mod(floor(x+0.5),2.0))-0.5)*1.4);
    c=mix(c,uC3,step(length(dp),0.12)*step(0.3,abs(f)));
    return vec4(c, 200.0);
  }
#elif MODE==217
  { // bayadère : plein de rayures de toutes les largeurs et de toutes les teintes du coloris, séparées d'un trait sombre
    vec3 u=normalize(q); float y=u.y*5.0+so.x; float b=floor(y*3.0), f=fract(y*3.0);
    float k=h31(vec3(b,so.y,1.0)), t=h31(vec3(b,so.y,2.0));
    vec3 c=k<0.33?mix(brt(uC1,0.45),uC2,t):(k<0.66?mix(uC2,uC3,t):mix(uC3,vec3(0.97),t*0.7));
    c*=mix(0.45,1.0,smoothstep(0.0,0.05,f)*smoothstep(1.0,0.95,f));
    c*=0.92+0.1*step(0.5,fract(atan(u.z,u.x)*60.0));
    return vec4(c, 200.0);
  }
#elif MODE==218
  { // boussoles : des roses des vents à quatre pointes, le nord de la 2e couleur, cerclées de la 1re, sur un fond de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.96,0.92),0.75);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*1.0)*p;
      on*=step(0.15,h31(id)); float r=length(p);
      float ring=step(abs(r-0.19),0.012)+step(abs(r-0.165),0.005);
      float s1=abs(p.x)/0.05+abs(p.y)/0.2, s2=abs(p.x)/0.2+abs(p.y)/0.05, s3=abs(dot(p,vec2(0.7071)))/0.035+abs(dot(p,vec2(-0.7071,0.7071)))/0.12, s4=abs(dot(p,vec2(-0.7071,0.7071)))/0.035+abs(dot(p,vec2(0.7071)))/0.12;
      vec3 cc=c; cc=mix(cc,uC3*0.6,step(min(s3,s4),1.0));
      cc=mix(cc,brt(uC1,0.4)*(p.x>0.0?0.6:0.9),step(min(s1,s2),1.0));
      cc=mix(cc,uC2,step(s1,1.0)*step(0.0,p.y));
      cc=mix(cc,brt(uC1,0.4)*0.7,min(ring,1.0));
      c=mix(c,cc,step(r,0.2)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==219
  { // cactus : de petits cactus de la 2e couleur à deux bras, piqués d'épines, une fleur de la 3e, dans un pot de la 1re
    vec3 u=normalize(q); vec3 c=mix(vec3(0.97,0.92,0.82),uC3,0.12);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.6)*p;
      on*=step(0.12,h31(id));
      float d=segM(p,vec2(0.0,-0.1),vec2(0.0,0.15))-0.045;
      d=min(d,segM(p,vec2(-0.1,0.0),vec2(-0.1,0.08))-0.028); d=min(d,segM(p,vec2(-0.1,0.0),vec2(-0.03,0.0))-0.028);
      d=min(d,segM(p,vec2(0.09,0.04),vec2(0.09,0.11))-0.026); d=min(d,segM(p,vec2(0.09,0.04),vec2(0.03,0.04))-0.026);
      float pot=step(-0.22,p.y)*step(p.y,-0.1)*step(abs(p.x),0.07+(p.y+0.22)*0.25);
      float spk=step(0.82,h31(vec3(floor(p*55.0),id.x)));
      vec3 cc=uC2*(0.7+0.3*smoothstep(0.0,-0.04,d))*(0.9+0.1*sin(p.x*120.0)); cc=mix(cc,vec3(1.0),spk*0.8);
      c=mix(c,cc,step(d,0.0)*on); c=mix(c,brt(uC1,0.45)*0.8,pot*on);
      c=mix(c,uC3,step(sdStar((p-vec2(0.0,0.19))*12.0)/12.0,0.0)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==220
  { // avions en papier : des avions de papier pliés, de la 1re et de la 2e couleur, avec leur trajet en pointillés de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(0.98,0.97,0.95),0.85);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,1.9,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id)); vec3 pc=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      float w1=inTri(p,vec2(0.2,0.0),vec2(-0.14,0.13),vec2(-0.06,0.0)), w2=inTri(p,vec2(0.2,0.0),vec2(-0.06,0.0),vec2(-0.12,-0.06));
      float tr=step(abs(p.y+0.04*sin(p.x*12.0)-0.02),0.008)*step(p.x,-0.17)*step(0.5,fract(p.x*18.0));
      c=mix(c,uC3*0.8,tr*on); c=mix(c,pc,w1*on); c=mix(c,pc*0.65,w2*on); }
    return vec4(c, 200.0);
  }
#elif MODE==221
  { // bateaux en papier : de petits bateaux de papier de la 1re et de la 2e couleur, sur des vaguelettes de la 3e
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.97,0.96);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.5)*p;
      on*=step(0.12,h31(id)); vec3 pc=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      float hull=step(-0.1,p.y)*step(p.y,-0.01)*step(abs(p.x),0.12+(p.y+0.1)*0.9);
      float sail=inTri(p,vec2(-0.08,-0.01),vec2(0.1,-0.01),vec2(0.0,0.17));
      float wv=step(abs(p.y+0.14-0.015*sin(p.x*40.0)),0.008)*step(abs(p.x),0.22);
      c=mix(c,uC3,wv*on); c=mix(c,pc*0.75,hull*on); c=mix(c,pc*(p.x<0.0?1.0:0.8),sail*on); }
    return vec4(c, 200.0);
  }
#elif MODE==222
  { // glaces : des cornets de glace à deux boules (1re et 2e couleurs) sur un cornet gaufré de la 3e
    vec3 u=normalize(q); vec3 c=vec3(0.97,0.96,0.94);
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot((h31(id+5.0)-0.5)*0.8)*p;
      on*=step(0.12,h31(id));
      float cone=inTri(p,vec2(-0.075,-0.02),vec2(0.075,-0.02),vec2(0.0,-0.25));
      float waf=max(step(abs(fract((p.x+p.y)*28.0)-0.5),0.1),step(abs(fract((p.x-p.y)*28.0)-0.5),0.1));
      float s1=length(p-vec2(0.0,0.03))/0.085, s2=length(p-vec2(0.0,0.14))/0.075;
      c=mix(c,mix(uC3,vec3(0.85,0.65,0.4),0.4)*(1.0-0.3*waf),cone*on);
      c=mix(c,brt(uC1,0.45)*(0.8+0.25*(1.0-s1)),step(s1,1.0)*on);
      c=mix(c,uC2*(0.8+0.25*(1.0-s2)),step(s2,1.0)*on); }
    return vec4(c, 200.0);
  }
// ===================== Peu communs =====================
#elif MODE==223
  { // dentelle : une dentelle blanche, ses rosaces et son filet, posée sur un fond de la 1re couleur, avec des perles de la 2e
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.4+nb*0.25)+so.xy; vec2 f=fract(p)-0.5;
    float r=length(f), a=atan(f.y,f.x);
    vec3 lace=mix(vec3(0.98),uC3,0.2);
    float ros=step(abs(r-0.3),0.025)+step(abs(r-0.18*(0.8+0.2*cos(a*8.0))),0.02)+step(r,0.3)*step(0.3*0.5,r)*step(abs(fract(a/6.2831853*16.0)-0.5),0.06);
    vec2 n=abs(fract(mrot(0.7853982)*p*6.0)-0.5); float net=step(min(n.x,n.y),0.06)*step(0.33,r);
    vec3 c=brt(uC1,0.4)*0.55;
    c=mix(c,lace,min(ros+net,1.0)); c=mix(c,uC2,step(r,0.05));
    return vec4(c, 200.0);
  }
#elif MODE==224
  { // ikat : des losanges tissés aux bords flous, comme si les fils avaient bougé à la teinture, en 3 couleurs
    vec3 u=normalize(q); float lon=atan(u.z,u.x), lat=u.y;
    float y=lat*4.0, b=floor(y); float N=8.0;
    vec2 p=vec2((fract(lon/6.2831853*N+0.5*mod(b,2.0))-0.5)*1.6*sqrt(max(0.05,1.0-lat*lat)),fract(y)-0.5);
    float jit=0.08*(noise(vec3(0.0,lat*90.0,so.x))-0.5);
    float dm=abs(p.x+jit)+abs(p.y);
    float m=mod(b,3.0); vec3 bg=m<1.0?uC3:(m<2.0?mix(uC3,vec3(1.0),0.5):uC2);
    vec3 c=dm<0.42?(dm<0.24?(dm<0.1?uC2:mix(uC3,vec3(1.0),0.4)):brt(uC1,0.45)):bg;
    c*=0.9+0.1*step(0.5,fract(lat*120.0));
    return vec4(c, 200.0);
  }
#elif MODE==225
  { // shibori : un tissu teint de la 1re couleur où les plis ont gardé des ronds clairs (3e couleur) rayés de plis, avec un halo de la 2e
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(2.2+nb*0.25)+so.xy; vec2 f=fract(p)-0.5;
    float r=length(f), a=atan(f.y,f.x);
    float sp=0.03*noise(vec3(a*4.0,r*10.0,cf.w));
    vec3 c=brt(uC1,0.4)*(0.45+0.15*noise(u*20.0+so));
    c=mix(c,uC2,smoothstep(0.42,0.3,r+sp)*0.6);
    float fold=0.7+0.3*step(0.5,fract(a/6.2831853*12.0));
    c=mix(c,mix(uC3,vec3(1.0),0.5)*fold,smoothstep(0.27,0.24,r+sp));
    c=mix(c,brt(uC1,0.4)*0.6,step(r,0.04));
    return vec4(c, 200.0);
  }
#elif MODE==226
  { // velours côtelé : les côtes du velours, bien rondes, en larges bandes douces des 3 couleurs
    vec3 u=normalize(q); float lon=atan(u.z,u.x);
    float rib=0.5+0.5*sin(lon*48.0);
    float t=fbm(vec3(u.x,u.y*0.3,u.z)*1.5+so);
    vec3 c=t<0.45?brt(uC1,0.45):(t<0.55?uC2:uC3);
    c*=0.55+0.5*pow(rib,0.6);
    c*=0.94+0.08*noise(u*120.0+so);
    return vec4(c, 200.0);
  }
#elif MODE==227
  { // tweed : un lainage en chevrons de deux couleurs, moucheté de brins de la 3e et de blanc
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=cf.xy*(14.0+nb);
    float col=floor(p.x/2.0); float s=mod(col,2.0)<1.0?1.0:-1.0;
    float v=fract((p.y+s*p.x)*1.0);
    vec3 c=mix(brt(uC1,0.4)*0.6,uC2*0.8,step(0.5,v));
    float fl=step(0.9,h31(vec3(floor(p*2.5),cf.w)));
    c=mix(c,h31(vec3(floor(p*2.5),cf.w+1.0))<0.6?uC3:vec3(0.95),fl);
    c*=0.85+0.2*noise(vec3(p*3.0,cf.w));
    return vec4(c, 200.0);
  }
#elif MODE==228
  { // cachemire : des gouttes recourbées pleines de petits dessins, de la 2e couleur cerclées de la 3e, sur un fond de la 1re
    vec3 u=normalize(q); vec3 c=brt(uC1,0.4)*0.55;
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,1.8,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id));
      float t=clamp((p.y+0.05)/0.28,0.0,1.0); vec2 cp=vec2(0.1*t*t,p.y);
      float d=p.y<-0.05?length(p-vec2(0.0,-0.05))-0.13:abs(p.x-0.1*t*t)-0.13*(1.0-t);
      float d2=p.y<-0.05?length(p-vec2(0.0,-0.05))-0.08:abs(p.x-0.1*t*t)-0.08*(1.0-t);
      vec3 cc=uC2;
      cc=mix(cc,uC3,step(abs(d),0.018));
      cc=mix(cc,mix(uC3,vec3(1.0),0.3),step(d2,0.0)*step(0.5,fract(length(p-vec2(0.0,-0.05))*30.0)));
      cc=mix(cc,brt(uC1,0.4)*0.6,step(length(p-vec2(0.0,-0.05)),0.03));
      c=mix(c,cc,step(d,0.018)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==229
  { // art déco : des éventails de rayons de deux couleurs, bordés de fins arcs d'or de la 3e, rang par rang
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*(2.2+nb*0.25)+so.xy;
    float row=floor(g.y), x0=mod(row,2.0)*0.5; vec2 f=vec2(fract(g.x-x0)-0.5,fract(g.y));
    float r=length(f), a=atan(f.x,f.y);
    vec3 gold=mix(vec3(1.0,0.82,0.42),uC3,0.4);
    vec3 c=mod(floor(a*8.0/3.14159+8.0),2.0)<1.0?brt(uC1,0.45):uC2;
    c=mix(c,gold,step(abs(r-0.45),0.015)+step(abs(r-0.3),0.01)+step(r,0.08));
    c=r>0.5?brt(uC1,0.3)*0.3:c;
    c=mix(c,gold,step(abs(r-0.5),0.015));
    return vec4(c, 200.0);
  }
#elif MODE==230
  { // liberty : un semis serré de toutes petites fleurs de la 1re et de la 2e couleur, avec leurs feuilles, sur un fond de la 3e
    vec3 u=normalize(q); vec3 c=mix(uC3,vec3(1.0),0.4);
    for(int i=0;i<3;i++){ vec3 id; float on; vec2 p=scatP(u,4.2,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.1,h31(id)); float r=length(p), a=atan(p.y,p.x);
      float lf=step(length((p-vec2(0.17,0.0))/vec2(0.09,0.04)),1.0);
      float fl=step(r,0.15*(0.6+0.4*abs(cos(a*2.5))));
      vec3 fc=h31(id+2.0)<0.5?brt(uC1,0.45):uC2;
      c=mix(c,mix(uC2,vec3(0.2,0.4,0.2),0.5),lf*on); c=mix(c,fc,fl*on); c=mix(c,vec3(0.98,0.9,0.5),step(r,0.035)*on); }
    return vec4(c, 200.0);
  }
#elif MODE==231
  { // ananas : la peau d'ananas, ses losanges bombés et leur petite pointe, de la 3e couleur vers la 2e, cernés de la 1re
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 p=mrot(0.7853982)*cf.xy*(5.0+nb*0.4)+so.xy; vec2 f=fract(p)-0.5;
    float dm=max(abs(f.x),abs(f.y));
    vec3 c=mix(uC3,uC2,smoothstep(0.0,0.5,dm)+0.2*noise(vec3(floor(p),cf.w)));
    c*=0.7+0.4*smoothstep(0.5,0.0,dm);
    c=mix(c,brt(uC1,0.4)*0.5,smoothstep(0.42,0.48,dm));
    c=mix(c,brt(uC1,0.4)*0.4,step(length(f-vec2(0.0,0.12)),0.05));
    return vec4(c, 200.0);
  }
#elif MODE==232
  { // croco : la peau de crocodile, ses grosses écailles bombées et brillantes, de la 1re et de la 2e couleur, le ventre de la 3e
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(vec3(u.x*2.5,u.y*5.0,u.z*2.5)+so,cid,d2);
    float ed=d2-d1;
    vec3 c=h31(cid+4.0)<0.6?brt(uC1,0.4)*0.6:uC2*0.8;
    c=mix(c,mix(uC3,vec3(1.0),0.3),smoothstep(0.25,0.15,abs(u.y+0.05))*0.8);
    c*=0.5+0.6*smoothstep(0.0,0.3,ed);
    return vec4(mix(brt(uC1,0.2)*0.12,c,smoothstep(0.02,0.06,ed)), 200.0);
  }
#elif MODE==233
  { // coquillages : des coquilles Saint-Jacques côtelées, de 3 couleurs, sur un fond de sable
    vec3 u=normalize(q); vec3 c=mix(vec3(0.96,0.91,0.8),uC3,0.1)*(0.92+0.1*noise(u*60.0+so));
    for(int i=0;i<2;i++){ vec3 id; float on; vec2 p=scatP(u,2.0,float(i),id,on); p=mrot(h31(id+5.0)*6.2831853)*p;
      on*=step(0.12,h31(id)); vec2 pp=p-vec2(0.0,-0.12); float r=length(pp), a=atan(pp.x,pp.y);
      float sh=step(r,0.26)*step(abs(a),1.1)*step(0.02,r);
      float ear=step(abs(pp.x),0.09)*step(-0.02,pp.y)*step(pp.y,0.05);
      float rib=0.75+0.25*abs(cos(a*7.0));
      float k=h31(id+2.0); vec3 sc=k<0.34?brt(uC1,0.45):(k<0.67?uC2:uC3);
      c=mix(c,sc*rib*(0.8+0.25*r/0.26),sh*on); c=mix(c,sc*0.75,ear*on*(1.0-sh)); }
    return vec4(c, 200.0);
  }
#elif MODE==234
  { // pomme de pin : des écailles en spirale qui couvrent toute la bille, chacune bombée, rang par rang de 3 couleurs
    vec3 u=normalize(q); float lon=atan(u.z,u.x), lat=asin(clamp(u.y,-1.0,1.0));
    float s1=lon/6.2831853*8.0+lat*2.6, s2=lon/6.2831853*13.0-lat*4.2;
    vec2 id=floor(vec2(s1,s2)), f=fract(vec2(s1,s2))-0.5;
    float dm=max(abs(f.x),abs(f.y));
    float m=mod(id.x+id.y,3.0); vec3 c=m<1.0?brt(uC1,0.45):(m<2.0?uC2:uC3);
    c=mix(c,vec3(0.4,0.28,0.18),0.25)*(0.5+0.65*smoothstep(0.5,0.0,dm)*(0.6+0.4*(0.5-f.y)));
    return vec4(mix(brt(uC1,0.2)*0.12,c,smoothstep(0.5,0.42,dm)), 200.0);
  }
#elif MODE==235
  { // tournesol : un tournesol de chaque côté, ses graines en spirale (1re couleur), sa couronne de la 2e et ses pétales de la 3e
    vec3 u=normalize(q); float rho=length(u.xy), a=atan(u.y,u.x);
    vec3 c=mix(uC3,vec3(1.0,0.9,0.4),0.3);
    float pet=fract(a/6.2831853*18.0); c*=0.75+0.3*sin(pet*3.14159);
    c=rho>0.8?mix(uC2,vec3(0.2,0.45,0.2),0.4)*(0.7+0.2*noise(u*20.0+so)):c;
    if(rho<0.62*(0.85+0.15*sin(pet*3.14159))){ c=uC2*0.9; }
    if(rho<0.45){ float v1=fract(a/6.2831853*21.0+rho*14.0), v2=fract(a/6.2831853*34.0-rho*22.0);
      float seed=smoothstep(0.5,0.25,length(vec2(v1,v2)-0.5));
      c=mix(brt(uC1,0.3)*0.25,brt(uC1,0.3)*0.65,seed); }
    return vec4(c, 200.0);
  }
#elif MODE==236
  { // bargello : la broderie en flammes, des pics en escalier qui montent et descendent, en dégradés des 3 couleurs
    vec3 u=normalize(q); float lon=atan(u.z,u.x); float x=lon/6.2831853*10.0;
    float tri=abs(fract(x)-0.5)*2.0;
    float y=u.y*5.0+tri*1.4+0.3*abs(fract(x*3.0)-0.5); y=floor(y*6.0)/6.0;
    float b=mod(floor(y*3.0),6.0);
    vec3 c=b<1.0?brt(uC1,0.45):(b<2.0?mix(brt(uC1,0.45),uC2,0.5):(b<3.0?uC2:(b<4.0?mix(uC2,uC3,0.5):(b<5.0?uC3:mix(uC3,vec3(1.0),0.5)))));
    c*=0.85+0.15*step(0.5,fract(lon*80.0));
    return vec4(c, 200.0);
  }
#elif MODE==237
  { // fanions : des guirlandes de petits drapeaux triangulaires qui font le tour de la bille, aux 3 couleurs
    vec3 u=normalize(q); float lon=atan(u.z,u.x); vec3 c=vec3(0.97,0.97,0.95);
    for(int i=0;i<3;i++){ float fi=float(i); float y0=-0.5+0.5*fi+0.06*sin(lon*3.0+fi*2.0);
      float N=14.0+fi*2.0; float x=lon/6.2831853*N+fi*0.3; float lx=fract(x)-0.5;
      float d=(y0-u.y)/0.18;
      float flag=step(0.0,d)*step(d,1.0-2.0*abs(lx)*1.1);
      float m=mod(floor(x),3.0); vec3 fc=m<1.0?brt(uC1,0.45):(m<2.0?uC2:uC3);
      c=mix(c,vec3(0.35),step(abs(u.y-y0),0.006));
      c=mix(c,fc*(0.85+0.15*(1.0-d)),flag); }
    return vec4(c, 200.0);
  }
#elif MODE==238
  { // nuancier : des pastilles de couleur rangées comme chez le peintre, chacune une teinte entre les 3 couleurs du coloris, avec son étiquette
    vec3 u=normalize(q); vec4 cf=cubeF(u); vec2 g=cf.xy*vec2(3.0,2.2)+so.xy; vec2 id=floor(g), f=fract(g);
    float t=h31(vec3(id,cf.w)), k=h31(vec3(id,cf.w+2.0));
    vec3 c=k<0.5?mix(brt(uC1,0.45),uC2,t):mix(uC2,uC3,t);
    c=f.y<0.25?vec3(0.97):c;
    c=mix(c,vec3(0.3),step(f.y,0.25)*step(abs(f.y-0.12),0.02)*step(abs(f.x-0.4),0.25));
    vec2 ed=min(f,1.0-f); return vec4(mix(vec3(0.85,0.84,0.8),c,smoothstep(0.03,0.06,min(ed.x,ed.y))), 200.0);
  }
#elif MODE==239
  { // guirlande lumineuse : des fils où brillent de petites ampoules de la 2e, de la 3e couleur et blanches, sur un fond de nuit de la 1re
    vec3 u=normalize(q); float lon=atan(u.z,u.x); vec3 c=brt(uC1,0.3)*0.2;
    for(int i=0;i<4;i++){ float fi=float(i); float y0=-0.6+0.4*fi+0.08*sin(lon*2.0+fi*1.7);
      c=mix(c,vec3(0.15),step(abs(u.y-y0),0.005));
      float N=16.0; float x=lon/6.2831853*N+fi*0.5; float lx=(fract(x)-0.5)*6.2831853/N*sqrt(max(0.05,1.0-y0*y0));
      vec2 p=vec2(lx,u.y-y0+0.035); float L=length(p/vec2(0.022,0.032));
      float m=mod(floor(x)+fi,3.0); vec3 bc=m<1.0?uC2:(m<2.0?uC3:vec3(1.0,0.95,0.8));
      c+=bc*exp(-length(p)*28.0)*0.6;
      c=mix(c,mix(bc,vec3(1.0),0.5),step(L,1.0)); }
    return vec4(c, 200.0);
  }
// ===================== Rares =====================
#elif MODE==240
  { // labradorite : une pierre gris-noir où s'allument, selon l'angle, des éclairs de la 1re, de la 2e et de la 3e couleur
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(u*3.0+so,cid,d2);
    vec3 c=mix(vec3(0.16,0.17,0.19),brt(uC1,0.3)*0.25,0.4)*(0.8+0.4*noise(u*14.0+so));
    c*=0.85+0.15*sin(dot(u,vec3(40.0,10.0,25.0))+h31(cid)*6.0);
    return vec4(c, 200.0);
  }
#elif MODE==241
  { // argent gravé : de l'argent poli (miroir, au rendu) gravé de volutes, incrusté de nielle de la 1re, de pierres de la 2e et de filets d'or de la 3e
    vec3 u=normalize(q); vec4 mt=metalF(q);
    vec3 cid; float d2; float d1=vorF(u*2.2+so,cid,d2);
    vec3 c=mix(brt(uC1,0.3)*0.3,step(d1,0.09)>0.5?uC2:mix(vec3(1.0,0.8,0.35),uC3,0.4),step(d1,0.09)+smoothstep(0.03,0.015,d2-d1));
    return vec4(mix(c,mt.rgb,mt.a), 200.0);
  }
#elif MODE==242
  { // guilloché : des ondes gravées très fines sous un émail transparent de la 2e couleur, un médaillon de la 1re et des filets d'or de la 3e
    vec3 u=normalize(q); float th=acos(clamp(abs(u.y),0.0,1.0)), a=atan(u.z,u.x);
    float w=sin(th*90.0+sin(a*12.0)*1.5)*0.5+0.5;
    vec3 c=uC2*(0.55+0.45*w);
    c=mix(c,brt(uC1,0.45)*(0.6+0.4*w),step(th,0.35));
    c=mix(c,mix(vec3(1.0,0.82,0.4),uC3,0.4),step(abs(th-0.37),0.02)+step(abs(th-1.2),0.02));
    return vec4(c, 200.0);
  }
#elif MODE==243
  { // mica : une pierre feuilletée en mille paillettes plates, chacune d'une teinte du coloris, qui brillent l'une après l'autre
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(u*6.0+so,cid,d2);
    float k=h31(cid+4.0); vec3 c=k<0.34?brt(uC1,0.5):(k<0.67?uC2:uC3);
    c*=0.35+1.0*pow(h31(cid+9.0),2.0);
    c=mix(c,vec3(1.0),step(0.93,h31(cid+11.0))*0.7);
    c=mix(c*0.6,c,smoothstep(0.0,0.04,d2-d1));
    return vec4(c, 200.0);
  }
#elif MODE==244
  { // fleurs séchées : de petites fleurs pressées (une par couleur du coloris) et des feuilles prises dans une résine claire, avec des bulles
    float h=q.z; vec2 p=q.xy*1.3; float lay=exp(-h*h/0.006); e=vec3(0.0);
    vec3 col=vec3(0.95,0.94,0.9); float den=0.15;
    for(int i=0;i<5;i++){ float fi=float(i); vec2 C=(vec2(h31(so+fi*1.3),h31(so+fi*2.9))-0.5)*1.0;
      vec2 pp=p-C; float r=length(pp), a=atan(pp.y,pp.x)+fi;
      float pet=step(r,0.13*(0.5+0.5*abs(cos(a*2.5))));
      vec3 fc=mod(fi,3.0)<1.0?brt(uC1,0.45):(mod(fi,3.0)<2.0?uC2:uC3);
      if(pet>0.5){ col=mix(fc,vec3(0.98,0.85,0.4),step(r,0.025)); den=40.0*lay; }
      float lf=step(length((mrot(fi*1.7)*(pp-vec2(0.15,0.05)))/vec2(0.08,0.025)),1.0);
      if(lf>0.5 && pet<0.5){ col=mix(uC2,vec3(0.3,0.45,0.2),0.6); den=40.0*lay; } }
    vec3 g=q*10.0+so; vec3 fc2=fract(g)-0.5;
    e+=vec3(0.9)*step(0.97,h31(floor(g)))*smoothstep(0.12,0.06,abs(length(fc2)-0.1))*1.2;
    return vec4(col, max(den,0.15));
  }
#elif MODE==245
  { // verre de mer : un morceau de verre poli par la mer, laiteux, teinté de la 2e couleur avec des voiles de la 1re et de la 3e
    float r=length(q); float n=fbm(q*2.5+so);
    vec3 c=mix(uC2,vec3(0.95),0.45);
    c=mix(c,brt(uC1,0.45),smoothstep(0.55,0.7,fbm(q*2.0+so+5.0))*0.6);
    c=mix(c,uC3,smoothstep(0.58,0.72,fbm(q*2.2+so+11.0))*0.6);
    return vec4(c, 1.4+n*1.5+3.0*smoothstep(0.75,0.95,r));
  }
#elif MODE==246
  { // pierre de soleil : une pierre translucide de la 3e couleur pleine de minuscules paillettes de cuivre qui s'allument (1re et 2e couleurs)
    float r=length(q); e=vec3(0.0);
    vec3 g=q*26.0+so; vec3 fc=fract(g)-0.5; float sp=step(0.9,h31(floor(g)))*smoothstep(0.25,0.0,length(fc));
    float k=h31(floor(g)+3.0);
    e+=(k<0.5?brt(uC1,0.5):uC2)*sp*14.0*smoothstep(0.95,0.8,r);
    return vec4(mix(uC3,vec3(1.0,0.75,0.5),0.25), 0.7+0.6*fbm(q*3.0+so));
  }
#elif MODE==247
  { // dendrites : une calcédoine laiteuse où ont poussé des fougères de pierre sombre (1re couleur), de la mousse (2e) et un voile de la 3e
    float r=length(q); vec3 w=q*2.0+so;
    float br=1.0-abs(2.0*noise(w*3.0)-1.0), br2=1.0-abs(2.0*noise(w*7.0+4.0)-1.0);
    float den=smoothstep(0.88,0.96,br*0.6+br2*0.4+0.2*smoothstep(0.4,0.9,r));
    float moss=smoothstep(0.6,0.7,fbm(w*1.5+9.0));
    vec3 c=mix(vec3(0.92,0.92,0.9),uC3,0.25);
    c=mix(c,uC2*0.8,moss); c=mix(c,brt(uC1,0.3)*0.3,den);
    return vec4(c, 0.6+moss*3.0+den*30.0);
  }
#elif MODE==248
  { // quartz rutile : un cristal clair traversé de fines aiguilles d'or (3e couleur) et de quelques-unes de la 2e, à peine teinté de la 1re
    float r=length(q); e=vec3(0.0);
    for(int i=0;i<22;i++){ float fi=float(i);
      vec3 o=(vec3(h31(so+fi*1.3),h31(so+fi*2.9),h31(so+fi*4.1))-0.5)*0.9;
      vec3 d=normalize(vec3(h31(so+fi*5.3),h31(so+fi*6.7),h31(so+fi*7.9))-0.5+0.001);
      vec3 pa=q-o; float t=clamp(dot(pa,d),-0.35,0.35); float ds=length(pa-d*t);
      e+=(mod(fi,5.0)<1.0?uC2:mix(vec3(1.0,0.8,0.35),uC3,0.4))*exp(-ds*120.0)*9.0; }
    e*=smoothstep(0.95,0.8,r);
    return vec4(mix(vec3(0.96),brt(uC1,0.45),0.15), 0.2);
  }
#elif MODE==249
  { // pyrite : des cubes de métal doré (miroir, au rendu) poussés les uns dans les autres, sur une roche de la 1re couleur
    vec4 mt=metalF(q); vec3 u=normalize(q);
    vec3 c=brt(uC1,0.3)*0.3*(0.8+0.4*noise(u*20.0+so));
    return vec4(mix(c,mt.rgb,mt.a), 200.0);
  }
#elif MODE==250
  { // bois pétrifié : un tronc devenu pierre, ses cernes et ses fentes, en bandes des 3 couleurs piquées de cristaux
    vec3 u=normalize(q); float rho=length(u.xz)+0.06*fbm(u*4.0+so), a=atan(u.z,u.x);
    float v=rho*14.0+0.5*fbm(u*3.0+so);
    float m=mod(floor(v),3.0); vec3 c=m<1.0?brt(uC1,0.45):(m<2.0?uC2:uC3);
    c=mix(c,vec3(0.6,0.5,0.45),0.25)*(0.8+0.25*fract(v));
    c=mix(c,c*0.4,smoothstep(0.03,0.0,abs(fract(a/6.2831853*7.0+0.2*noise(u*5.0))-0.5)-0.47)*step(0.3,rho));
    c=mix(c,vec3(1.0),step(0.96,h31(floor(u*80.0+so)))*0.6);
    return vec4(c, 200.0);
  }
#elif MODE==251
  { // laque : une laque profonde de la 1re couleur, peinte à l'or (3e couleur) de vagues et de nuages, avec des touches de la 2e
    vec3 u=normalize(q); vec3 c=brt(uC1,0.3)*0.3;
    float lat=u.y*6.0+0.4*sin(atan(u.z,u.x)*3.0);
    float wv=fract(lat); float crest=smoothstep(0.03,0.0,abs(wv-0.5-0.15*sin(atan(u.z,u.x)*18.0))-0.01);
    vec3 gold=mix(vec3(1.0,0.8,0.35),uC3,0.35);
    c=mix(c,gold,crest);
    float cl=smoothstep(0.66,0.68,fbm(u*2.5+so))-smoothstep(0.7,0.72,fbm(u*2.5+so));
    c=mix(c,gold,cl);
    c=mix(c,uC2,smoothstep(0.7,0.72,fbm(u*2.5+so)));
    c=mix(c,gold,step(0.97,h31(floor(u*60.0+so)))*0.8);
    return vec4(c, 200.0);
  }
#elif MODE==252
  { // titane : un métal (miroir, au rendu) chauffé jusqu'à prendre les 3 couleurs du coloris en reflets, avec un fin brossage
    vec4 mt=metalF(q); return vec4(mt.rgb, 200.0);
  }
#elif MODE==253
  { // obsidienne : un verre de volcan noir, poli, traversé de reflets soyeux de la 2e et de la 3e couleur, et de flocons de la 1re
    vec3 u=normalize(q); vec3 c=vec3(0.04,0.04,0.05);
    float v=dot(u,normalize(vec3(0.3,1.0,0.2)))*14.0+1.5*fbm(u*2.0+so);
    float sh=pow(0.5+0.5*sin(v),6.0);
    c+=mix(uC2,uC3,0.5+0.5*sin(v*0.37))*sh*0.45;
    vec3 cid; float d2; float d1=vorF(u*7.0+so,cid,d2);
    c=mix(c,mix(brt(uC1,0.45),vec3(0.9),0.4),smoothstep(0.12,0.08,d1)*step(0.8,h31(cid)));
    return vec4(c, 200.0);
  }
#elif MODE==254
  { // céladon : un émail de la 2e couleur, pâle et craquelé d'un fin réseau de la 1re, plus épais dans les creux, cerclé de la 3e
    vec3 u=normalize(q); vec3 cid; float d2; float d1=vorF(u*5.0+so+0.1*vec3(noise(u*10.0),noise(u*10.0+2.0),0.0),cid,d2);
    vec3 c=mix(uC2,vec3(0.95),0.4)*(0.88+0.18*fbm(u*3.0+so));
    c=mix(c,brt(uC1,0.3)*0.35,smoothstep(0.025,0.008,d2-d1)*0.8);
    vec3 cid2; float e2; float d3=vorF(u*13.0+so+5.0,cid2,e2); c=mix(c,brt(uC1,0.3)*0.5,smoothstep(0.015,0.004,e2-d3)*0.4);
    c=mix(c,uC3,smoothstep(0.02,0.008,abs(abs(u.y)-0.85)));
    return vec4(c, 200.0);
  }
