# SPEC: feat(rag-lab): implement SocraticLM learning platform and RAG lab

## Problem

Educational learning tracks (trilhas) lack a domain-tailored, local-first Socratic tutoring platform and an empirical RAG laboratory for benchmarking chunkers, hybrid retrieval strategies, and pedagogy quality on course materials and YouTube MCP playlists.

## Design Decision

Implement a modular, decoupled Python architecture based on typing protocols and Pydantic schemas. The platform provides PyMuPDF, Markdown, Text, and YouTube MCP transcript ingestion, configurable chunkers (Fixed, Recursive, Markdown, Pedagogical), hybrid retrieval (Dense vector search + BM25 sparse search with Reciprocal Rank Fusion), Cross-Encoder reranking, and a Socratic inquiry engine (Ollama, OpenAI-compatible, MockLLM) that guides learners through probing questions and timestamped citations. In parallel, an empirical experiment runner evaluates IR metrics (Recall@K, MRR, NDCG@K) and pedagogical generation metrics (Faithfulness, Socratic Inquisitiveness), exposing interactive FastAPI REST endpoints and a `rag-lab` CLI.

## Alternatives Considered

- **Monolithic LangChain / LlamaIndex wrapper**: Rejected because opaque abstractions make empirical metric isolation, custom Reciprocal Rank Fusion, deterministic offline testing, and pedagogical state tracking difficult to benchmark and reproduce predictably.
- **Pure Cloud Vector DB & Proprietary API only**: Rejected because offline reproducibility, student data privacy, and zero-cost local execution (using in-memory Qdrant and local embeddings) are essential requirements for lab experiments.
- **Standard Naive Q&A without Socratic state**: Rejected because direct answer-dumping reduces student engagement and retention; guided inquiry with probing questions and timestamped video chapter citations is foundational to active learning pedagogy.

## Scope

- Includes:
  - Domain models and protocols (`Document`, `Chunk`, `QueryResult`, `SocraticTurn`, `Trail`, `BenchmarkSample`, `BenchmarkResult`, `EmbeddingModel`, `VectorStore`, `Retriever`, `Reranker`, `LLMClient`, `RAGPipeline`, `MetricEvaluator`).
  - Parsers for Plain Text, Markdown, PDF (PyMuPDF), and YouTube MCP playlist/transcript extraction with timestamp cleaning.
  - Chunking implementations: Fixed size, Recursive character, Markdown header-aware, and Pedagogical concept-based chunkers.
  - Embedding adapters: `DeterministicHashEmbedding` (for fast zero-download tests and offline benchmarking), `SentenceTransformerEmbedding`, and `OllamaEmbedding`.
  - Storage layer: `InMemoryVectorStore`, `QdrantVectorStore` (in-memory `:memory:` and Docker modes), and `BM25Index` (`rank-bm25`).
  - Retrieval and reranking: `DenseRetriever`, `SparseRetriever` (BM25), `HybridRetriever` (RRF and Weighted fusion), `CrossEncoderReranker`, and `NoOpReranker`.
  - Generation and Socratic tutoring: `MockLLM`, `OllamaLLM`, `OpenAILLM`, Socratic prompt templates, student knowledge state tracking, and timestamped citations.
  - Pipelines: `NaiveRAGPipeline`, `AdvancedRAGPipeline`, `SocraticRAGPipeline`, and `CRAGPipeline` (Corrective RAG).
  - Evaluation and benchmarking engine: Retrieval metrics (`Recall@K`, `Precision@K`, `MRR`, `NDCG@K`, `Latency`) and generation metrics (`Faithfulness`, `Answer Relevancy`, `Socratic Inquisitiveness`).
  - Matrix experiment runner with local JSON tracking (`experiments/results/`) and Rich CLI comparison tables.
  - Declarative experiment and pipeline YAML configs (`configs/experiments/retrieval_benchmark.yaml`).
  - Sample trail corpus and 10-sample ground-truth QA evaluation benchmark dataset (`datasets/benchmarks/sample_qa_dataset.json`).
  - FastAPI REST server with interactive Swagger UI endpoints (`GET /health`, `POST /api/v1/ingest`, `POST /api/v1/ingest/youtube`, `POST /api/v1/query`, `POST /api/v1/retrieval/search`, `POST /api/v1/experiments/run`, `GET /api/v1/experiments/results`).
  - CLI entrypoint `rag-lab` supporting `run-experiment`, `ingest`, `serve`, `socratic`, and `search`.
  - Docker Compose service definitions for Qdrant, MLflow, and Ollama.
  - Complete pytest unit and integration test suites.
- Does NOT include:
  - Proprietary cloud-only database lock-ins.
  - Frontend graphical user interface beyond the interactive OpenAPI Swagger UI at `/docs`.
  - Direct hardware GPU acceleration drivers (uses CPU/PyTorch standard bindings).

## Acceptance Criteria

- `document_parsers_extract_text_and_metadata`: Plain text, markdown, PDF, and YouTube MCP transcript inputs are parsed into normalized `Document` objects with trail and timestamp metadata.
- `chunkers_partition_documents_according_to_strategy`: Fixed, recursive, markdown, and pedagogical chunkers partition documents into chunks with boundary indices and metadata.
- `embedding_adapters_generate_consistent_vectors`: Deterministic hash, SentenceTransformer, and Ollama adapters produce valid floating-point vector lists with matching dimensions.
- `storage_stores_and_queries_vectors_and_lexical_index`: In-memory vector store, Qdrant store, and BM25 index store chunks and return relevant results filtered by trail ID.
- `retrieval_combines_dense_and_sparse_with_rrf`: Hybrid retriever combines dense and sparse search rankings using Reciprocal Rank Fusion to yield improved recall.
- `reranker_orders_results_by_query_relevance`: CrossEncoder and mock rerankers score and sort retrieved chunks by query relevance.
- `socratic_tutor_generates_probing_questions_and_citations`: Socratic RAG pipeline generates educational responses containing guiding questions, conceptual hints, and timestamped citations.
- `benchmark_engine_calculates_all_retrieval_and_pedagogical_metrics`: Evaluation runner computes Recall@K, MRR, NDCG@K, Faithfulness, and Socratic guidance scores over sample QA benchmarks.
- `experiment_runner_executes_matrix_and_reports_rich_table`: CLI and experiment runner parse YAML matrix configs, execute trials, log results, and render comparison tables.
- `fastapi_endpoints_respond_with_valid_schemas`: All REST API endpoints (`/health`, `/api/v1/ingest`, `/api/v1/ingest/youtube`, `/api/v1/query`, `/api/v1/retrieval/search`, `/api/v1/experiments/run`, `/api/v1/experiments/results`) execute and return validated Pydantic JSON payloads.
- `cli_commands_execute_without_error`: `rag-lab run-experiment`, `rag-lab ingest`, and `rag-lab search` execute properly from terminal.
- `pytest_suite_passes_all_tests`: `uv run pytest` passes 100% of unit and integration test assertions.

## Reproducibility

- Command to run all tests: `uv run pytest`
- Command to reproduce benchmark results: `uv run rag-lab run-experiment --config configs/experiments/retrieval_benchmark.yaml`
- Versions: Python >= 3.12, uv >= 0.11, FastAPI >= 0.110, Qdrant-Client >= 1.8, PyMuPDF >= 1.23.

## Risks and Assumptions

- Assumption: Deterministic mock embedding and LLM adapters enable deterministic, zero-download testing and CI execution without requiring GPU or external API keys.
- Assumption: When neural models or Ollama are available, their adapters adhere to the identical Protocol interfaces.
- Risk: PyMuPDF requires binary C-extension compilation; a fallback pure-text extractor is implemented to guarantee zero-breakage on constrained environments.
