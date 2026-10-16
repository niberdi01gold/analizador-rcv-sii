-- =====================================================================
-- Crea la base completa desde cero: funciones, tablas, carga, IVA y alertas.
-- Uso (en psql, conectado a una base vacía):
--     \i C:/proyectos/analizador-rcv-sii/crear_todo.sql
-- =====================================================================

\set ON_ERROR_STOP on

\echo '1/6 Funciones'
\ir sql/01_funciones.sql
\echo '2/6 Tablas'
\ir sql/02_tablas.sql
\echo '3/6 Carga de los CSV al staging'
\ir scripts/cargar_staging.sql
\echo '4/6 Transformacion a tablas limpias'
\ir sql/03_transformar.sql
\echo '5/6 IVA mensual y remanente'
\ir sql/04_iva.sql
\echo '6/6 Alertas'
\ir sql/05_alertas.sql

\echo 'Listo. Resumen:'
SELECT (SELECT count(*) FROM factura) AS compras,
       (SELECT count(*) FROM venta)   AS ventas,
       (SELECT count(*) FROM alertas) AS alertas;
