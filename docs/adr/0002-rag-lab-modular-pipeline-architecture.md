# Decoupled Python Protocols & Pydantic DTOs for RAG and Socratic pipelines

## Context

The RAG platform requires flexible composition across diverse ingestion parsers,
chunking strategies, embedding models, vector stores, hybrid retrieval mechanisms,
rerankers, and LLM generation backends. Coupling components directly to third-party
frameworks (like LangChain or LlamaIndex) creates opaque abstractions, makes
systematic benchmarking difficult, and restricts offline zero-dependency execution.

## Status

Accepted.

## Considered Options

- **Python `typing.Protocol` interfaces and Pydantic DTOs (chosen)**: Define clear,
  lightweight interfaces for `DocumentParser`, `Chunker`, `EmbeddingModel`,
  `VectorStore`, `Retriever`, `Reranker`, and `LLMClient`. Modules communicate
  via immutable, serializable Pydantic data transfer objects (`Document`, `Chunk`,
  `QueryResult`, `SocraticTurn`).
- **Heavy framework abstraction (LangChain / LlamaIndex)**: Rejected — introduces
  heavy external dependencies, frequent breaking changes, and high latency overhead
  that impedes isolated empirical evaluation.
- **Ad-hoc dictionaries and functions**: Rejected — lacks static typing verification,
  schema validation at API boundaries, and clear lifecycle contracts.

## Consequences

- Components can be swapped, mocked, and composed dynamically at runtime via YAML
  configs or API requests.
- Deterministic mock adapters allow 100% offline, zero-download test execution.
- Metrics evaluation and experiment runs isolate individual pipeline stages cleanly.
