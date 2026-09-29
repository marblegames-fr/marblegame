/* =====================================================================
   BILLY : tout ce qui parle à la base de données (Supabase).
   Le jeu n'utilise que l'objet Cloud ci-dessous : pour changer
   d'hébergeur un jour, c'est ce seul fichier qu'il faut réécrire.
   ===================================================================== */
(function(){
  const URL = "https://gflnjqxtxqxoybaaaszp.supabase.co";
  // clé publique « anon » : faite pour être dans le code du site (la sécurité vient des règles de la base)
  const KEY = "eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6ImdmbG5qcXh0eHF4b3liYWFhc3pwIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTA1OTQyOTUsImV4cCI6MjEwNjE3MDI5NX0.NAzRYHfPRXak5aShzxuMpRKS11s2o95ORtTyHCQ3_p4";
  const AUTH_KEY = "sb-gflnjqxtxqxoybaaaszp-auth-token";   // là où Supabase garde la session dans le navigateur

  const db = window.supabase ? window.supabase.createClient(URL, KEY) : null;
  const need = () => { if(!db) throw new Error("hors-ligne"); };
  const ok = ({data, error}) => { if(error) throw error; return data; };
  const back = () => location.origin + location.pathname;   // les liens des e-mails ramènent au jeu, où qu'il soit hébergé

  // bille du jeu <-> ligne de la table
  const toRow = s => { const d = Object.assign({}, s); delete d.id; delete d.no;
    return {id:s.id, seed:s.seed>>>0, taille:s.type, decor:s.family, coloris:s.pal, shiny:s.shiny||0, secrete:s.secret||null, donnees:d, obtenue_le:new Date(s.at||Date.now()).toISOString()} };
  const fromRow = r => Object.assign({}, r.donnees, {id:r.id, no:r.numero});

  window.Cloud = {
    available: !!db,

    // identifiant du joueur connecté, lu tout de suite (sans réseau) pour démarrer vite
    cachedUserId(){ try{ return JSON.parse(localStorage.getItem(AUTH_KEY))?.user?.id || null }catch(e){ return null } },

    // callback(evenement, utilisateur) : "SIGNED_IN", "SIGNED_OUT", "PASSWORD_RECOVERY"…
    onAuth(cb){ if(db) db.auth.onAuthStateChange((ev, session)=>setTimeout(()=>cb(ev, session?.user||null))); },
    async currentUser(){ need(); return ok(await db.auth.getSession()).session?.user || null; },

    async signUp(email, password, pseudo){
      need();
      const d = ok(await db.auth.signUp({email, password, options:{data:{pseudo}, emailRedirectTo:back()}}));
      // e-mail déjà utilisé : Supabase répond sans erreur mais sans identité
      if(d.user && Array.isArray(d.user.identities) && !d.user.identities.length) throw Object.assign(new Error("deja"), {code:"user_already_exists"});
      return {needsConfirm: !d.session};
    },
    async signIn(email, password){ need(); return ok(await db.auth.signInWithPassword({email, password})).user; },
    async signOut(){ if(db) await db.auth.signOut({scope:"local"}); },
    async resetPassword(email){ need(); ok(await db.auth.resetPasswordForEmail(email, {redirectTo:back()})); },
    async updatePassword(password){ need(); ok(await db.auth.updateUser({password})); },
    async resendConfirm(email){ need(); ok(await db.auth.resend({type:"signup", email, options:{emailRedirectTo:back()}})); },

    // tout ce qu'il faut pour reprendre la partie
    async pull(uid){
      need();
      const [profil, sauvegarde, billes] = await Promise.all([
        db.from("profils").select("pseudo").eq("id", uid).maybeSingle().then(ok),
        db.from("sauvegardes").select("donnees, appareil, maj_le").eq("joueur", uid).maybeSingle().then(ok),
        this.billes(uid),
      ]);
      return {profil, sauvegarde, billes};
    },
    async billes(uid){
      const out = [];
      for(let from=0;; from+=1000){   // l'API renvoie au plus 1000 lignes à la fois
        const rows = ok(await db.from("billes").select("id, numero, donnees").eq("proprietaire", uid).is("detruite_le", null).order("numero").range(from, from+999));
        out.push(...rows.map(fromRow));
        if(rows.length<1000) return out;
      }
    },
    async lastUpdate(uid){ need(); return ok(await db.from("sauvegardes").select("appareil, maj_le").eq("joueur", uid).maybeSingle()); },
    async pushSave(uid, donnees, appareil){
      need();
      ok(await db.from("sauvegardes").upsert({joueur:uid, donnees, appareil, maj_le:new Date().toISOString()}, {onConflict:"joueur"}));
    },
    // nouvelles billes : renvoie [{id, numero}] (une bille déjà enregistrée est ignorée)
    async addBilles(specs){
      need(); const out = [];
      for(let i=0; i<specs.length; i+=200)
        out.push(...ok(await db.from("billes").upsert(specs.slice(i, i+200).map(toRow), {onConflict:"id", ignoreDuplicates:true}).select("id, numero")));
      return out;
    },
    async destroyBilles(ids, raison){ need(); return ok(await db.rpc("detruire_billes", {ids, raison})); },
    async setPseudo(uid, pseudo){
      need();
      const {error} = await db.from("profils").update({pseudo}).eq("id", uid);
      if(error) throw Object.assign(new Error(error.message), {code: error.code==="23505" ? "pseudo_pris" : error.code});
    },
  };
})();
