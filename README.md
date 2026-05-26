# 🍽️ TableFlow: Enterprise-Grade AI Restaurant Operations & Automation Engine

TableFlow is an autonomous, production-ready operational management platform designed for modern restaurants. Rather than a simple chatbot, TableFlow is a highly resilient workflow engine that automates customer communication, real-time reservations, intelligent menu search, and database state updates. 

By leveraging **n8n** for enterprise workflow orchestration, **PostgreSQL (with pgvector)** for semantic search, and an **asynchronous Python embedding synchronization pipeline**, TableFlow keeps menu data and AI-agent representations perfectly synchronized without bottlenecking production APIs.

---

## 📈 System Architecture

TableFlow utilizes a decoupled, event-driven architecture to split expensive background operations from real-time customer conversations.

```mermaid
graph TD
    %% Flujo en Tiempo Real de WhatsApp
    A[Cliente WhatsApp] <-->|API de WhatsApp Business| B[Agente Orquestador de Clientes en n8n]
    B <-->|Contexto y Acciones| C{Herramientas del Agente}
    C -->|Consultar / Reservar / Cancelar| D[(PostgreSQL en Supabase)]
    C -->|Búsqueda Semántica del Menú| E[(Almacén de Vectores pgvector)]
    C <-->|OpenRouter / Gemini 2.5 Flash Lite| F[Razonador LLM]

    %% Operaciones de Administración en Tiempo Real
    G[Administrador / Gestor del Restaurante] <-->|Webhook / Dashboard de n8n| H[Agente Administrador en n8n]
    H <-->|Operaciones CRUD| D
    
    %% Pipeline Asíncrono de Sincronización de Embeddings
    D -->|Trigger de Base de Datos: Insertar/Actualizar| I[Canal de Webhooks en Tiempo Real]
    I -->|Payload JSON del Evento| J[Orquestador de Sincronización en n8n]
    J -->|Ejecución de Worker CLI| K[Script Asíncrono en Python]
    K -->|Consulta de API de Embeddings (OpenRouter)| L[Generador de Embeddings]
    L -->|Actualizar Columna Vectorial| E
    
    %% Estilos de Alto Contraste y Premium
    classDef default fill:#1e293b,stroke:#475569,stroke-width:2px,color:#f8fafc;
    classDef customerAgent fill:#0f766e,stroke:#14b8a6,stroke-width:2px,color:#ffffff;
    classDef adminAgent fill:#1d4ed8,stroke:#3b82f6,stroke-width:2px,color:#ffffff;
    classDef pythonScript fill:#b45309,stroke:#f59e0b,stroke-width:2px,color:#ffffff;
    classDef databaseNode fill:#0f172a,stroke:#334155,stroke-width:2px,color:#f8fafc;

    class B customerAgent;
    class H adminAgent;
    class K pythonScript;
    class D,E databaseNode;
```

---

## 📂 Project Directory Structure

Your repository is structured as a ready-to-run package:

```text
TableFlow/
├── n8n/
│   └── tableflow-workflow.json           # Unified production-ready n8n Agent Workflow
├── python-services/
│   └── embedding-pipeline/
│       ├── embed_worker.py               # Asynchronous Python database polling worker
│       └── requirements.txt              # Script library requirements
├── docker-compose.yml                    # n8n + ngrok local dev services compose
├── .env.example                          # Parameterized environment variables template
└── README.md                             # Production documentation
```

---

## ⚙️ Core AI Agents Design (n8n Engine)

TableFlow delegates operations to two specialized agentic workflows running inside the unified **n8n** agent model (`n8n/tableflow-workflow.json`), utilizing **Gemini 2.5 Flash Lite** and **GPT-4o-mini** (via **OpenRouter**) for high-speed, cost-effective reasoning.

### 1. Customer Orchestrator Agent (*Agente Orquestador*)
Orchestrates client-facing interactions over WhatsApp to ensure a human-like, efficient user experience using local Argentine Spanish phrasing (*voseo*).
*   **Menu Queries:** Uses semantic vector search to answer highly specific questions (e.g., *"Do you have anything low-carb under $15 that doesn't contain peanuts?"*).
*   **Reservation Lifecycle:** Autonomously verifies seating availability, creates new bookings, allows customers to look up active reservations, or process cancellations via structured database operations.
*   **Context Management:** Maintains chat memory and persistent conversational context across sessions.

### 2. Admin Agent (*Agente Administrador*)
Empowers restaurant management with conversational backend control.
*   **Administrative Management:** Creates, overrides, or reschedules bookings based on manual restaurant overrides.
*   **Menu Modifications:** Handles on-the-fly updates to item pricing, availability, and allergen profiles directly into PostgreSQL, automatically queuing them for vector updates.

---

## 🧠 High-Performance Semantic Search & pgvector

Rather than relying on basic string matching or raw database scans, TableFlow treats the restaurant menu as a **multi-dimensional vector space**.

1.  **Menu Vectorization:** Menu items (descriptions, ingredients, categorization, pricing) are serialized into structured textual records and projected into vector space.
2.  **Cosine Similarity Matching:** User prompts are embedded in real-time and queried against the database using PostgreSQL cosine operators (`<=>`):
    ```sql
    SELECT name, description, price 
    FROM menu 
    ORDER BY embedding <=> CURRENT_QUERY_EMBEDDING 
    LIMIT 3;
    ```
3.  **Context-Injection:** The top 3 closest items are retrieved and fed to the *Customer Orchestrator Agent* as grounding context, guaranteeing 100% factual responses.

---

## ⚡ Asynchronous Embedding Sync Pipeline (Production Thinking)

A common design flaw in AI projects is generating vector embeddings synchronously during conversational API requests or direct database writes. This causes high API latencies, locks threads, and risks out-of-sync vector records if an API call fails.

### The TableFlow Approach:
TableFlow decouples database modifications from vector mathematical computations using an event-driven sync pipeline (`python-services/embedding-pipeline/embed_worker.py`):

1.  **State Change:** The manager updates a menu row (e.g., changing the price of the *Vegan Salad*).
2.  **Null Embedding State:** The row is saved with `embedding = NULL`.
3.  **Asynchronous Script Polling:** The background Python script (`embed_worker.py`) queries the table for rows where `embedding IS NULL` at short intervals:
    ```sql
    SELECT id, nombre_plato, descripcion, precio, tiempo_preparacion, clasificacion, content
    FROM menu
    WHERE embedding IS NULL
    LIMIT 20;
    ```
4.  **Generates Vector Representation:** For each null-vector row, the script serializes the data, sends a request to the OpenRouter Embedding API (`openai/text-embedding-3-small`), and writes the vector back in a secure transaction.
5.  **Zero Interface Blocking:** The customer talking on WhatsApp experiences zero lag or latency, while the AI system's search capabilities update automatically within seconds of a database write.

---

## 🚀 Quick-Start Guide (Local Deployment)

### 1. Spin up the Core Services (Docker & ngrok)
TableFlow includes a pre-configured `docker-compose.yml` that spawns both `n8n` and an `ngrok` tunnel for secure, HTTPS-accessible webhooks.

1. Copy `.env.example` to `.env`:
   ```bash
   cp .env.example .env
   ```
2. Populate `.env` with your `NGROK_AUTHTOKEN`, `OPENROUTER_API_KEY`, and `DATABASE_URL`.
3. Spin up the environment:
   ```bash
   docker-compose up -d
   ```
4. Access your local n8n instance at `https://macaroni-owl-arise.ngrok-free.dev/` or via port `5678`.

### 2. Configure the n8n Workflow
1. Go to the n8n dashboard.
2. Select **Import from File** and upload the `n8n/tableflow-workflow.json` workflow file.
3. Configure your credentials for PostgreSQL, Supabase, OpenRouter, and the WhatsApp Business API.

### 3. Run the Embedding Sync Worker
To start processing vector embeddings for new or updated menu items:
1. Navigate to the pipeline directory:
   ```bash
   cd python-services/embedding-pipeline
   ```
2. Install Python dependencies:
   ```bash
   pip install -r requirements.txt
   ```
3. Run the worker script:
   ```bash
   python embed_worker.py
   ```

---

## 💼 Business Value & Return on Investment (ROI)

*   **Operational Resilience:** By offloading booking, scheduling, and repetitive menu inquiries to autonomous agents, staff can focus on guest service.
*   **Hallucination Protection:** The strict separation of grounding contextual knowledge (via pgvector) prevents the AI from inventing non-existent dishes or incorrect pricing.
*   **Ultra-low Operational Overhead:** Leveraging Gemini 2.5 Flash Lite through OpenRouter keeps conversational costs to a fraction of a cent per session, providing immense scalability margins.

---

## 🔮 Future Roadmap

*   **Advanced Semantic Caching:** Implement a Redis semantic cache to store and instantly serve identical vector queries, cutting API expenses to zero for common requests.
*   **Stripe Integration:** Allow customers to pay reservation deposits or settle tabs directly through the WhatsApp interface.
*   **Interactive Voice Responses (IVR):** Transition the conversational logic to handle direct phone calls using Twilio Voice and real-time transcription.
