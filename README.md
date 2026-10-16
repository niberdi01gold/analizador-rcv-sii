# Analizador RCV · SII

Base de datos en **PostgreSQL** que carga el Registro de Compras y Ventas (RCV) del SII, calcula el IVA mes a mes con arrastre de remanente y **detecta automáticamente errores** en las facturas.

Pensado para pymes chilenas que revisan sus impuestos sin contador.

## El problema

Cada mes el SII entrega un CSV de compras y otro de ventas. Revisarlos a mano en Excel es lento y los errores pasan de largo:

- una factura que el proveedor cobró dos veces con otro folio
- un IVA que no es el 19 % del neto
- un cobro muy superior a lo habitual de un proveedor
- un remanente de crédito fiscal que no se descontó el mes siguiente

## Qué hace

| Módulo | Resultado |
|---|---|
| **Carga (ETL)** | Lee 42 archivos CSV a tablas de staging, valida cada fila y pasa solo las correctas. La carga se puede repetir sin duplicar datos. |
| **Validación** | Rechaza RUT con dígito verificador incorrecto (módulo 11), fechas imposibles, fechas fuera del período y montos no numéricos. |
| **IVA mensual** | Débito y crédito fiscal por período; las notas de crédito restan. |
| **Remanente** | Arrastra el crédito fiscal a favor al mes siguiente con un CTE recursivo. |
| **Alertas** | 5 reglas: posible duplicado, IVA inconsistente, monto atípico, proveedor nuevo con monto alto y nota de crédito sin factura. |

## Resultados con los datos de ejemplo

21 meses de una pyme ficticia (*Detailing Atacama SpA*, Copiapó): **378 compras y 309 ventas válidas, 4 filas rechazadas y 7 alertas**.

El remanente evita pagar de más: en marzo de 2025 la compra de una hidrolavadora deja **$2.603.595** de crédito a favor, que cubre todo el IVA de abril y parte del de mayo.

| Período | Débito | Crédito | Remanente anterior | IVA a pagar | Remanente siguiente |
|---|---|---|---|---|---|
| 2025-03 | 1.784.149 | 4.387.744 | 0 | **0** | 2.603.595 |
| 2025-04 | 2.153.330 | 502.715 | 2.603.595 | **0** | 952.980 |
| 2025-05 | 2.431.283 | 575.553 | 952.980 | **902.750** | 0 |

## Técnicas SQL usadas

- **Modelo normalizado** con claves primarias, foráneas y unicidad compuesta `(tipo, proveedor, folio)` que impide facturas duplicadas.
- **Funciones en PL/pgSQL**: validación de RUT con módulo 11 y conversiones que devuelven `NULL` en vez de fallar (`EXCEPTION WHEN others`).
- **Restricciones `CHECK`**: la base rechaza sola cualquier RUT inválido.
- **ETL con staging**: `\copy` a tablas de texto, transformación con `INSERT ... SELECT` e idempotencia con `ON CONFLICT DO NOTHING`.
- **CTE (`WITH`) y vistas** para armar consultas complejas por partes.
- **CTE recursivo (`WITH RECURSIVE`)** para el remanente, donde cada mes depende del anterior.
- **Funciones de ventana** (`avg`, `count`, `stddev_samp` con `OVER (PARTITION BY ... ROWS BETWEEN ...)`) para comparar cada factura con el historial del proveedor.
- **Control estadístico**: regla de las 3 desviaciones estándar, igual que una carta de control de laboratorio.
- **Self-join, `NOT EXISTS`, `DISTINCT ON` y `percentile_cont`** en las alertas.

## Cómo ejecutarlo

Requisitos: PostgreSQL 16.

1. Clona el repositorio en `C:\proyectos\analizador-rcv-sii`.
2. En psql, crea una base vacía y ejecuta el script principal:

```sql
CREATE DATABASE rcv;
\c rcv
\i C:/proyectos/analizador-rcv-sii/crear_todo.sql
```

3. Consulta los resultados:

```sql
SELECT * FROM posicion_iva ORDER BY periodo;
SELECT * FROM alertas ORDER BY severidad, periodo;
```

## Estructura

```
crear_todo.sql              construye todo en orden
sql/01_funciones.sql        RUT y conversiones seguras
sql/02_tablas.sql           modelo de datos y staging
scripts/cargar_staging.sql  carga de los 42 CSV
sql/03_transformar.sql      staging -> tablas limpias
sql/04_iva.sql              IVA mensual y remanente
sql/05_alertas.sql          motor de alertas
data/                       CSV de ejemplo (ficticios)
```

## Alcance

- Herramienta de análisis y control; **no reemplaza la declaración del F29**. El remanente no se reajusta por UTM (mejora pendiente).
- **Los datos son 100 % ficticios.** Nombres y RUT inventados, con dígito verificador válido.

## Próximos pasos

- Dashboard con gráficos en Python
- Reajuste del remanente por UTM

## Autor

**Nicolás Berrios** · Copiapó, Chile
[GitHub](https://github.com/niberdi01gold) · [LinkedIn](https://linkedin.com/in/nicolas-berrios-b9165a431)