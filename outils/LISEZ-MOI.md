# Outils de Tikalo (sur le PC)

Copies versionnées des outils rangés dans le dossier personnel (`C:\Users\ptitn\`). Ils lisent le jeton Supabase dans
`~/.tikalo-supabase-token` (jamais dans le dépôt). Les lancer depuis le dossier personnel : `node ~/tikalo-….mjs`.

- `tikalo-sql.mjs` : exécuter une requête ou un fichier SQL sur la base (`node ~/tikalo-sql.mjs -f supabase/fichier.sql`).
- `tikalo-backup.mjs` : l'export de toutes les données dans `sauvegardes-donnees/` (tâche planifiée « Tikalo - export Supabase », 21 h 30).
- `tikalo-restaurer.mjs` : remettre un export dans la base.
  - `verifier [dossier]` : lecture seule, compare l'export à la base.
  - `copie [dossier]` : charge l'export dans le schéma `restauration`, sans toucher au jeu (pour récupérer quelques lignes à la main).
  - `remplacer [dossier] --essai` : fait tout le remplacement puis l'annule, et compare les chiffres (test sans risque).
  - `remplacer [dossier] --oui` : export de sécurité, puis remplacement de toutes les tables en une seule transaction.
  - `nettoyer` : supprime le schéma `restauration`.
  Ne remet pas les comptes (mots de passe gérés par Supabase) : ne jamais supprimer le projet Supabase.
