// (16 octobre 2026) Maquette « course studio » : une variante de video-insta/course-moteur.js avec une physique plus fine,
// pour comparer dans maquette-course-studio.html (window.COURSE_FINE à côté de window.COURSE). Rien ne change dans le jeu.
//  - 2 pas de calcul par image (1/120 s au lieu de 1/60) : moins de billes qui traversent ou tremblent, des chocs plus nets
//  - plus d'adhérence sur la piste (0,04 → 0,22) : les billes roulent vraiment au lieu de glisser (on voit le motif tourner)
//  - rebond sur la piste un peu plus mat (0,35 → 0,25), chocs entre billes plus vifs (0,75 → 0,85), comme du verre
//  - moins de freinage de la rotation (0,05 → 0,01)
// usage (depuis le dossier du projet) : node maquettes/video-insta/fabriquer-course.mjs puis node maquettes/fabriquer-course-fine.mjs
import fs from "fs";

let s = fs.readFileSync("maquettes/video-insta/course-moteur.js", "utf8");
const rep = (a, b) => { if(!s.includes(a)) throw new Error("introuvable : " + a); s = s.replace(a, b) };
rep("window.COURSE = ", "window.COURSE_FINE = ");
rep("{friction:.04, restitution:.35}", "{friction:.22, restitution:.25}");
rep("{friction:.02, restitution:.75}", "{friction:.05, restitution:.85}");
rep("linearDamping:.02, angularDamping:.05", "linearDamping:.02, angularDamping:.01");
rep("W.world.step(DT); t += DT;", "W.world.step(DT/2); W.world.step(DT/2); t += DT;");
s = "// Fichier fabriqué par maquettes/fabriquer-course-fine.mjs (physique fine, pour la maquette) : ne pas modifier à la main.\n" + s.replace(/^\/\/ Fichier fabriqué[^\n]*\n/, "");
fs.writeFileSync("maquettes/course-moteur-fine.js", s);
console.log("course-moteur-fine.js :", Math.round(s.length/1024), "Ko");
