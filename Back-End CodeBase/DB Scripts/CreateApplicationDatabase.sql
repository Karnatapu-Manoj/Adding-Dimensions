-- Run with psql as an administrator. Supply application_password as a psql variable.
-- This creates a dedicated non-superuser login and its database without modifying
-- pre-existing accounts or databases. It intentionally does not reset passwords.
\set ON_ERROR_STOP on

SELECT format('CREATE ROLE adding_dimensions LOGIN NOSUPERUSER NOCREATEDB NOCREATEROLE PASSWORD %L', :'application_password')
WHERE NOT EXISTS (SELECT 1 FROM pg_roles WHERE rolname = 'adding_dimensions')
\gexec

SELECT 'CREATE DATABASE adding_dimensions OWNER adding_dimensions'
WHERE NOT EXISTS (SELECT 1 FROM pg_database WHERE datname = 'adding_dimensions')
\gexec
