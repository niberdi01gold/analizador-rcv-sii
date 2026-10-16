"""Dashboard del Analizador RCV.

Ejecutar desde la carpeta del proyecto:
    streamlit run app/dashboard.py
"""

import pandas as pd
import plotly.express as px
import psycopg
import streamlit as st

st.set_page_config(page_title="Analizador RCV", layout="wide")


# ------------------------------------------------------------------ conexión
# Los datos de conexión se leen de .streamlit/secrets.toml (no se sube a GitHub).
@st.cache_resource
def conectar():
    db = st.secrets["postgres"]
    return psycopg.connect(
        host=db["host"], port=db["port"], dbname=db["dbname"],
        user=db["user"], password=db["password"], autocommit=True,
    )


def consulta(sql):
    """Ejecuta una consulta SQL y devuelve el resultado como tabla de pandas."""
    with conectar().cursor() as cur:
        cur.execute(sql)
        columnas = [c.name for c in cur.description]
        return pd.DataFrame(cur.fetchall(), columns=columnas)


def pesos(valor):
    """1234567 -> $1.234.567"""
    return f"${valor:,.0f}".replace(",", ".")


# ------------------------------------------------------------------- datos
iva = consulta("SELECT * FROM posicion_iva ORDER BY periodo")
alertas = consulta("SELECT * FROM alertas ORDER BY severidad, periodo")
proveedores = consulta("""
    SELECT p.razon_social AS proveedor, sum(f.neto * t.signo) AS neto
    FROM factura f
    JOIN proveedor p      ON p.id = f.proveedor_id
    JOIN tipo_documento t ON t.codigo = f.tipo_doc
    GROUP BY p.razon_social
    ORDER BY neto DESC
""")

# ----------------------------------------------------------------- página
st.title("Analizador RCV · SII")
st.caption("Detailing Atacama SpA (datos ficticios) · enero 2025 a septiembre 2026")

col1, col2, col3 = st.columns(3)
col1.metric("IVA pagado en el período", pesos(iva["iva_a_pagar"].sum()))
col2.metric("Meses con remanente", int((iva["remanente_siguiente"] > 0).sum()))
col3.metric("Alertas", len(alertas))

st.subheader("IVA a pagar y remanente, mes a mes")
grafico = px.bar(
    iva, x="periodo", y=["iva_a_pagar", "remanente_siguiente"],
    barmode="group",
    labels={"value": "Pesos (CLP)", "periodo": "Período", "variable": ""},
)
st.plotly_chart(grafico, width="stretch")

st.subheader("Alertas")
st.dataframe(alertas, hide_index=True, width="stretch")

st.subheader("Compras netas por proveedor")
grafico = px.bar(
    proveedores, x="neto", y="proveedor", orientation="h",
    labels={"neto": "Pesos (CLP)", "proveedor": ""},
)
grafico.update_layout(yaxis={"categoryorder": "total ascending"})
st.plotly_chart(grafico, width="stretch")