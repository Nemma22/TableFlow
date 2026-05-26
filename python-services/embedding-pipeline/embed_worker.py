import os
import time
import requests
import psycopg2
from dotenv import load_dotenv

load_dotenv()

# =========================
# CONFIG
# =========================
OPENROUTER_API_KEY = os.getenv("OPENROUTER_API_KEY")
DATABASE_URL = os.getenv("DATABASE_URL")
MODEL = os.getenv("EMBEDDING_MODEL", "openai/text-embedding-3-small")

HEADERS = {
    "Authorization": f"Bearer {OPENROUTER_API_KEY}",
    "Content-Type": "application/json",
    "HTTP-Referer": "http://localhost",
    "X-Title": "menu-embedding-worker"
}

# =========================
# DB
# =========================
def get_conn():
    return psycopg2.connect(DATABASE_URL)

# =========================
# FETCH
# =========================
def fetch_rows(cur, limit=20):
    cur.execute("""
        SELECT id,
               nombre_plato,
               descripcion,
               precio,
               tiempo_preparacion,
               clasificacion,
               content
        FROM menu
        WHERE embedding IS NULL
        LIMIT %s;
    """, (limit,))
    return cur.fetchall()

# =========================
# BUILD TEXT (IMPORTANTE)
# =========================
def build_text(row):
    id, nombre, descripcion, precio, tiempo, clasificacion, content = row

    return f"""
Plato: {nombre}
Descripcion: {descripcion}
Clasificacion: {clasificacion}
Precio: {precio}
Tiempo de preparacion: {tiempo}
Contenido: {content}
""".strip()

# =========================
# OPENROUTER EMBEDDING
# =========================
def get_embedding(text):
    r = requests.post(
        "https://openrouter.ai/api/v1/embeddings",
        headers=HEADERS,
        json={
            "model": MODEL,
            "input": text
        }
    )

    r.raise_for_status()
    return r.json()["data"][0]["embedding"]

# =========================
# UPDATE DB
# =========================
def update_embedding(cur, row_id, embedding):
    cur.execute("""
        UPDATE menu
        SET embedding = %s
        WHERE id = %s;
    """, (embedding, row_id))

# =========================
# PROCESS
# =========================
def process_batch():
    conn = get_conn()
    cur = conn.cursor()

    rows = fetch_rows(cur)

    if not rows:
        print("✅ No hay filas sin embedding")
        return False

    for row in rows:
        try:
            row_id = row[0]

            text = build_text(row)
            print(f"🔄 Procesando ID {row_id}")

            embedding = get_embedding(text)

            update_embedding(cur, row_id, embedding)
            conn.commit()

            print(f"✅ OK ID {row_id}")

            time.sleep(0.2)

        except Exception as e:
            print(f"❌ Error ID {row[0]}:", e)
            conn.rollback()

    return True

# =========================
# LOOP
# =========================
if __name__ == "__main__":
    print("🚀 Worker embeddings iniciado")

    while True:
        has_data = process_batch()

        if not has_data:
            print("⏳ esperando nuevos registros...")
            time.sleep(30)
        else:
            time.sleep(2)
