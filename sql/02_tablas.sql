-- =====================================================================
-- 02 · Tablas
-- Modelo normalizado: cada dato vive en un solo lugar (Lecciones 1 y 4).
-- =====================================================================

-- Catálogo de documentos del SII. signo = -1 hace que las notas de crédito resten.
CREATE TABLE tipo_documento (
    codigo  smallint PRIMARY KEY,
    nombre  text     NOT NULL,
    signo   smallint NOT NULL DEFAULT 1
);

INSERT INTO tipo_documento (codigo, nombre, signo) VALUES
    (33, 'Factura electrónica',          1),
    (34, 'Factura exenta electrónica',   1),
    (39, 'Boleta electrónica',           1),
    (61, 'Nota de crédito electrónica', -1);

-- ---------------------------------------------------------------- compras
CREATE TABLE proveedor (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rut           text NOT NULL UNIQUE,
    razon_social  text NOT NULL,
    CONSTRAINT proveedor_rut_valido CHECK (rut_valido(rut))
);

CREATE TABLE factura (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_doc      smallint NOT NULL REFERENCES tipo_documento (codigo),
    proveedor_id  integer  NOT NULL REFERENCES proveedor (id),
    folio         bigint   NOT NULL,
    fecha         date     NOT NULL,
    periodo       date     NOT NULL,
    neto          bigint   NOT NULL,
    iva           bigint   NOT NULL,
    total         bigint   NOT NULL,
    UNIQUE (tipo_doc, proveedor_id, folio)          -- impide facturas duplicadas
);

-- ----------------------------------------------------------------- ventas
CREATE TABLE cliente (
    id            integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    rut           text NOT NULL UNIQUE CHECK (rut_valido(rut)),
    razon_social  text NOT NULL
);

CREATE TABLE venta (
    id          integer GENERATED ALWAYS AS IDENTITY PRIMARY KEY,
    tipo_doc    smallint NOT NULL REFERENCES tipo_documento (codigo),
    cliente_id  integer  NOT NULL REFERENCES cliente (id),
    folio       bigint   NOT NULL,
    fecha       date     NOT NULL,
    periodo     date     NOT NULL,
    neto        bigint   NOT NULL,
    iva         bigint   NOT NULL,
    total       bigint   NOT NULL,
    UNIQUE (tipo_doc, cliente_id, folio)
);

-- ---------------------------------------------------------------- staging
-- Zona de aterrizaje: todo como texto, igual que viene en el CSV (Lección 3).
CREATE TABLE stg_compra (
    nro text, tipo_doc text, tipo_compra text, rut_proveedor text, razon_social text,
    folio text, fecha_docto text, fecha_recepcion text, fecha_acuse text,
    monto_exento text, monto_neto text, monto_iva text, monto_iva_no_rec text,
    codigo_iva_no_rec text, monto_total text, neto_activo_fijo text,
    iva_activo_fijo text, iva_uso_comun text,
    periodo date
);

CREATE TABLE stg_venta (
    nro text, tipo_doc text, tipo_venta text, rut_cliente text, razon_social text,
    folio text, fecha_docto text, fecha_recepcion text, fecha_acuse text, fecha_reclamo text,
    monto_exento text, monto_neto text, monto_iva text, monto_total text, iva_retenido text,
    periodo date
);
