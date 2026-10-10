-- =====================================================================
--  TIKALO : fermer les anciennes fonctions de paris (10 octobre 2026)
--  public.miser ne fait plus rien depuis le 6 octobre (elle refuse tout), et aucun pari n'a jamais été
--  enregistré (table mises vide). Mais public.regler_mise restait appelable par un joueur connecté :
--  on retire le droit d'appel aux deux, par sécurité. Le jeu ne les utilise plus.
-- =====================================================================
revoke execute on function public.miser(text, integer) from public, anon, authenticated;
revoke execute on function public.regler_mise(bigint, integer) from public, anon, authenticated;
