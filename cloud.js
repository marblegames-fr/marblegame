/* =====================================================================
   TIKALO : tout ce qui parle à la base de données (Supabase).
   Le jeu n'utilise que l'objet Cloud ci-dessous : pour changer
   d'hébergeur un jour, c'est ce seul fichier qu'il faut réécrire.
   ===================================================================== */
(function(){
  const URL = "https://gflnjqxtxqxoybaaaszp.supabase.co";
  // clé publique « anon » : faite pour être dans le code du site (la sécurité vient des règles de la base)
  const KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdmbG5qcXh0eHF4b3liYWFhc3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1OTQyOTUsImV4cCI6MjEwNjE3MDI5NX0.NAzRYHfPRXak5aShzxuMpRKS11s2o95ORtTyHCQ3_p4";
  const AUTH_KEY = "sb-gflnjqxtxqxoybaaaszp-auth-token";   // là où Supabase garde la session dans le navigateur
  // anti-robots (Cloudflare Turnstile) : la clé publique du site. Vide = pas de vérification.
  // À activer dans cet ordre : 1) mettre la clé ici et mettre le site en ligne, 2) activer le captcha dans Supabase
  // (sinon plus personne ne peut se connecter). Supabase la demande à l'inscription, à la connexion et pour le mot de passe oublié.
  const CAPTCHA_KEY = "0x4AAAAAAFKB73jX7PPwNGR6";

  const db = window.supabase ? window.supabase.createClient(URL, KEY) : null;
  const need = () => { if(!db) throw new Error("hors-ligne"); };
  const ok = ({data, error}) => { if(error) throw error; return data; };
  const back = () => location.origin + location.pathname;   // les liens des e-mails ramènent au jeu, où qu'il soit hébergé

  // bille du jeu <-> ligne de la table
  const toRow = s => { const d = Object.assign({}, s); delete d.id; delete d.no;
    return {id:s.id, seed:s.seed>>>0, taille:s.type, decor:s.family, coloris:s.pal, shiny:s.shiny||0, secrete:s.secret||null, donnees:d, obtenue_le:new Date(s.at||Date.now()).toISOString()} };
  const fromRow = r => Object.assign({}, r.donnees, {id:r.id, no:r.numero}, r.origine==="serveur" ? {srv:true} : {});
  // appel d'une fonction du serveur (supabase/serveur.sql) : l'erreur garde le code renvoyé par la base (« pas_assez », « deja »…)
  const rpc = async (nom, args) => {
    need();
    const {data, error} = await db.rpc(nom, args||{});
    if(error){ const m = /^[a-z_]+$/.test(error.message) ? error.message : (error.code==="PGRST202" || error.code==="42883" ? "serveur_absent" : "reseau");
      throw Object.assign(new Error(m), {code:m, cause:error}) }
    return data;
  };

  window.Cloud = {
    available: !!db,
    captchaKey: CAPTCHA_KEY,

    // identifiant du joueur connecté, lu tout de suite (sans réseau) pour démarrer vite
    cachedUserId(){ try{ return JSON.parse(localStorage.getItem(AUTH_KEY))?.user?.id || null }catch(e){ return null } },

    // callback(evenement, utilisateur) : "SIGNED_IN", "SIGNED_OUT", "PASSWORD_RECOVERY"…
    onAuth(cb){ if(db) db.auth.onAuthStateChange((ev, session)=>setTimeout(()=>cb(ev, session?.user||null))); },
    async currentUser(){ need(); return ok(await db.auth.getSession()).session?.user || null; },

    async signUp(email, password, pseudo, captchaToken, extra){
      need();
      // extra : ce que le joueur a accepté à l'inscription (version des règles du jeu), gardé avec le compte
      const d = ok(await db.auth.signUp({email, password, options:{data:{pseudo, ...extra}, emailRedirectTo:back(), captchaToken}}));
      // e-mail déjà utilisé : Supabase répond sans erreur mais sans identité
      if(d.user && Array.isArray(d.user.identities) && !d.user.identities.length) throw Object.assign(new Error("deja"), {code:"user_already_exists"});
      return {needsConfirm: !d.session};
    },
    async signIn(email, password, captchaToken){ need(); return ok(await db.auth.signInWithPassword({email, password, options:{captchaToken}})).user; },
    // (26 octobre 2026) le mode invité (supabase/invite.sql) : un compte sans e-mail, créé d'un clic
    async signInGuest(captchaToken){ need(); return ok(await db.auth.signInAnonymously({options:{captchaToken}})).user; },
    // l'invité sauvegarde sa partie : on ajoute l'e-mail à CE compte (même identifiant, il garde tout). Le mot de passe se choisit
    // après le clic sur le lien de l'e-mail (Supabase ne l'accepte qu'une fois l'adresse confirmée) : mdp_a_choisir le rappelle
    async linkEmail(email, pseudo, extra){ need(); ok(await db.auth.updateUser({email, data:{pseudo, ...extra, mdp_a_choisir:true}}, {emailRedirectTo:back()})); },
    // l'utilisateur à jour, demandé au serveur (l'invité a-t-il confirmé son e-mail ailleurs ?)
    async freshUser(){ need(); const u = ok(await db.auth.getUser()).user; if(u && !u.is_anonymous) await db.auth.refreshSession().catch(()=>{}); return u; },
    async signOut(){ if(db) await db.auth.signOut({scope:"local"}); },
    async resetPassword(email, captchaToken){ need(); ok(await db.auth.resetPasswordForEmail(email, {redirectTo:back(), captchaToken})); },
    async updatePassword(password){ need(); ok(await db.auth.updateUser({password, data:{mdp_a_choisir:null}})); },
    async resendConfirm(email, captchaToken){ need(); ok(await db.auth.resend({type:"signup", email, options:{emailRedirectTo:back(), captchaToken}})); },

    // tout ce qu'il faut pour reprendre la partie
    async pull(uid){
      need();
      const [profil, sauvegarde, billes, remise] = await Promise.all([
        db.from("profils").select("pseudo").eq("id", uid).maybeSingle().then(ok),
        db.from("sauvegardes").select("donnees, appareil, maj_le").eq("joueur", uid).maybeSingle().then(ok),
        this.billes(uid),
        this.remise(),
      ]);
      return {profil, sauvegarde, billes, remise};
    },
    async billes(uid){
      // l'API renvoie au plus 1000 lignes à la fois : la première page dit combien il y en a, les suivantes partent toutes ensemble
      // (20 octobre 2026 : avant, une page après l'autre, soit 4 allers-retours pour une boîte de 3 800 billes)
      const page = (from, count) => db.from("billes").select("id, numero, donnees, origine", count ? {count:"exact"} : undefined).eq("proprietaire", uid).is("detruite_le", null).order("numero").range(from, from+999);
      const first = await page(0, true), out = ok(first);
      if(first.count!=null){ const more = []; for(let from=1000; from<first.count; from+=1000) more.push(page(from).then(ok)); (await Promise.all(more)).forEach(r=>out.push(...r)) }
      else for(let r = out; r.length===1000;){ r = ok(await page(out.length)); out.push(...r) }   // (sans le total : page après page, comme avant)
      const seen = new Set(); return out.filter(r=>!seen.has(r.id) && seen.add(r.id)).map(fromRow);   // (une bille arrivée entre deux pages peut en décaler une)
    },
    // (21 octobre 2026) une empreinte de la boîte (supabase/vitesse.sql) : elle change dès qu'une bille arrive, part ou change
    empreinte: () => rpc("billes_empreinte"),
    // le numéro de la dernière remise à zéro (supabase/remise.sql), null s'il n'y en a jamais eu
    async remise(){ const {data, error} = await db.from("remise").select("numero").eq("id", 1).maybeSingle(); return error ? null : data?.numero ?? null },
    async lastUpdate(uid){ need(); return ok(await db.from("sauvegardes").select("appareil, maj_le").eq("joueur", uid).maybeSingle()); },
    async pushSave(uid, donnees, appareil){
      need();
      ok(await db.from("sauvegardes").upsert({joueur:uid, donnees, appareil, maj_le:new Date().toISOString()}, {onConflict:"joueur"}));
    },
    // nouvelles billes : renvoie [{id, numero, edition}] (une bille déjà enregistrée est ignorée)
    async addBilles(specs){
      need(); const out = [];
      for(let i=0; i<specs.length; i+=200)
        out.push(...ok(await db.from("billes").upsert(specs.slice(i, i+200).map(toRow), {onConflict:"id", ignoreDuplicates:true}).select("id, numero, edition")));
      return out;
    },
    async destroyBilles(ids, raison){ need(); return ok(await db.rpc("detruire_billes", {ids, raison})); },
    // ---------- le serveur décide : bonbecs, sacs, récompenses (supabase/serveur.sql) ----------
    eco: {
      start: (bonbecs, sacs, pity) => rpc("eco_demarrer", {bonbecs, sacs, pity}),
      state: () => rpc("eco_etat"),
      openBag: (nom, offert, evenement) => rpc("ouvrir_sac", {nom, offert:!!offert, evenement:!!evenement}),   // evenement : la case « billes d'événement » cochée
      recycle: ids => rpc("echanger_billes", {ids}),
      fuse: ids => rpc("fusionner", {ids}),
      fuseLot: ids => rpc("fusionner_lot", {ids}),   // (21 octobre 2026) jusqu'à 10 fusions d'un coup, les billes des fusions à la suite
      fuseEv: ids => rpc("fusion_evenement", {ids}),
      pachinko: payer => rpc("pachinko", {payer:!!payer}),
      // les jeux de hasard (supabase/chance.sql) : payer = false pour la partie offerte du jour
      roue: payer => rpc("roue", {payer:!!payer}),
      grattage: payer => rpc("grattage", {payer:!!payer}),
      marelle: payer => rpc("marelle", {payer:!!payer}),   // (9 octobre 2026) remplace le Pot
      distributeur: payer => rpc("distributeur", {payer:!!payer}),
      // (22 octobre 2026) les nouveaux jeux de chance (supabase/jeux-chance-2.sql)
      gobelets: payer => rpc("gobelets", {payer:!!payer}),
      tierce: payer => rpc("tierce", {payer:!!payer}),
      toupie: payer => rpc("toupie", {payer:!!payer}),
      pince: payer => rpc("pince", {payer:!!payer}),
      pinceEtat: () => rpc("pince_etat"),
      loterie: () => rpc("loterie_etat"),
      loterieTicket: () => rpc("loterie_ticket"),
      daily: () => rpc("bonbec_du_jour"),
      gain: (source, cle, montant, sac) => rpc("gagner", {source, cle, montant, sac:sac||null}),
      marble: (source, cle, graine, bid) => rpc("bille_gagnee", {source, cle, graine:graine??null, bid:bid||null}),
      bet: (jeu, montant) => rpc("miser", {jeu, montant}),
      settle: (mise, gain) => rpc("regler_mise", {mise, gain}),
      test: action => rpc("outil_test", {action}),
      // (20 octobre 2026) un mot de l'équipe, avec son cadeau versé à la lecture (supabase/messages.sql)
      messages: () => rpc("messages_a_lire"),
      messageLu: mid => rpc("message_lu", {mid}),
    },
    // ---------- la Grande Course, à 12 h et à 20 h (supabase/course.sql) ----------
    course: {
      etat: () => rpc("course_etat"),
      inscrire: bid => rpc("course_inscrire", {bid:bid||null}),
      desinscrire: () => rpc("course_desinscrire"),
      lots: (jour, heure) => rpc("course_lots", {j:jour, h:heure||20}),
    },
    // ---------- la cour de récré : copains, troc, marché (supabase/cour.sql) ----------
    cour: {
      moi: () => rpc("cour_moi"),
      ajouter: pseudo => rpc("ami_demander", {pseudo}),
      repondre: (de, oui) => rpc("ami_repondre", {de, oui}),
      retirer: ami => rpc("ami_retirer", {ami}),
      profil: qui => rpc("profil_joueur", {qui}),
      echangeables: qui => rpc("billes_echangeables", {qui}),
      collection: qui => rpc("collection_copain", {qui}),
      verrouiller: (ids, v) => rpc("verrouiller", {ids, v:!!v}),   // (16 octobre 2026) supabase/verrou.sql   // (16 octobre 2026) clés « taille|motif|coloris|shiny » de toute sa boîte
      fil: () => rpc("fil_amis"),
      proposer: (vers, donne, demande, mot, remplace, donneB, demandeB) => rpc("troc_proposer", {vers, donne, demande, mot:mot||null, remplace:remplace||null, donne_bonbecs:donneB||0, demande_bonbecs:demandeB||0}),
      repondreTroc: (troc, oui) => rpc("troc_repondre", {troc, oui}),
      annuler: troc => rpc("troc_annuler", {troc}),
      trocs: () => rpc("mes_trocs"),
      // en heures (3 h, 12 h) ou en jours (1, 3, 7)
      vendre: (bille, prix, jours, heures) => rpc("vendre", heures ? {bille, prix, heures} : {bille, prix, jours:jours||3}),
      retirerAnnonce: annonce => rpc("retirer_annonce", {annonce}),
      acheter: annonce => rpc("acheter", {annonce}),
      // « genre » (achat immédiat ou enchère) n'est envoyé que s'il est choisi : le marché marche aussi avec l'ancien serveur
      marche: f => rpc("marche", Object.assign({taille:f.taille||null, decor:f.decor??null, coloris:f.coloris??null, shiny:f.shiny===""||f.shiny==null?null:f.shiny==="1", tri:f.tri||"recent", page:f.page||0}, f.genre ? {genre:f.genre} : {})),
      encheres: () => rpc("mes_encheres"),
      mettreAuxEncheres: (bille, prix, heures) => rpc("mettre_aux_encheres", {bille, prix, heures}),
      prix: s => rpc("prix_modele", {taille:s.type, decor:s.family, coloris:s.pal, shiny:!!s.shiny}),   // (16 octobre 2026) les ventes des 30 derniers jours
      encherir: (annonce, montant) => rpc("encherir", {annonce, montant}),
      // page : 0 = la page où je suis, 1 = la première… (sans page : les 50 premiers, comme avant le 10 octobre 2026)
      classement: (portee, page) => rpc("classement", page==null ? {portee:portee||"tous"} : {portee:portee||"tous", page}),
      // (14 octobre 2026) le classement de la semaine, le palmarès des semaines closes, et « j'ai vu mon lot »
      semaine: portee => rpc("classement_semaine", {portee:portee||"tous"}),
      palmares: () => rpc("palmares_semaines"),
      semaineVu: s => rpc("semaine_vu", {s}),
      annonces: () => rpc("mes_annonces"),
      journal: (depuis, limite) => rpc("cour_journal", {depuis:depuis||0, limite:limite||80}),
      stats: () => rpc("cour_stats"),
      // les notifications en temps réel (supabase/notifs.sql) : cb(quoi) dès qu'il se passe quelque chose qui concerne ce joueur.
      // Renvoie une fonction pour arrêter d'écouter.
      ecouter(uid, cb){
        if(!db || !uid) return () => {};
        const ch = db.channel("pings-" + uid)
          .on("postgres_changes", {event:"*", schema:"public", table:"pings", filter:"joueur=eq." + uid}, p => cb(p.new?.quoi || null))
          .subscribe();
        return () => { try{ db.removeChannel(ch) }catch(e){} };
      },
    },
    // ---------- « Signaler un bug » (supabase/signalements.sql) ----------
    bugs: {
      envoyer: (categorie, texte, details) => rpc("signaler", {categorie, texte, details:details||{}}),
      liste: tous => rpc("signalements_liste", {tous:!!tous}),
      regle: (sid, oui) => rpc("signalement_regle", {sid, oui:!!oui}),
    },
    // ---------- compteur de fréquentation anonyme (supabase/frequentation.sql) ----------
    freq: {
      compter: (etape, source) => db ? db.rpc("compter", {etape, source}).then(()=>{}, ()=>{}) : Promise.resolve(),
      liste: jours => rpc("frequentation_liste", {jours:jours||14}),
    },
    async setPseudo(uid, pseudo){
      need();
      const {error} = await db.from("profils").update({pseudo}).eq("id", uid);
      if(error) throw Object.assign(new Error(error.message), {code: error.code==="23505" ? "pseudo_pris" : error.code});
    },
  };
})();
