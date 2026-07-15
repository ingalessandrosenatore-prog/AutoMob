-- La policy consente già solo utenti autenticati, ma il vecchio grant rendeva
-- comunque la tabella visibile nello schema GraphQL anonimo.
revoke all on table public.mechanics from anon;
grant select, update on table public.mechanics to authenticated;
