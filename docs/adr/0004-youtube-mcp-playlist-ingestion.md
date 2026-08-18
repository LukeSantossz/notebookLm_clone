# Ingest YouTube playlists and transcripts into learning tracks via YouTube MCP

## Context

Educational video lessons and playlists on YouTube contain rich lecture content,
visual chapters, and timestamps that are essential for multimodal learning tracks.
Manually converting video URLs or downloading large video files is bandwidth-heavy
and cumbersome.

## Status

Accepted.

## Considered Options

- **YouTube Model Context Protocol (MCP) & structured transcript extraction (chosen)**:
  Ingest video transcripts, timestamps, and chapter markers via standardized MCP
  payloads or transcript extractors directly into normalized `Document` and `Chunk`
  structures with `timestamp_start`, `timestamp_end`, and `chapter` metadata.
- **Full video/audio download and local Whisper transcription**: Rejected as default —
  incurs massive GPU compute overhead, high network transfer times, and heavy disk
  usage unsuitable for lightweight local-first lab experimentation.
- **Manual text transcription summaries**: Rejected — lacks precise timestamped citation
  grounding for student inquiry.

## Consequences

- Socratic answers can directly cite timestamped YouTube segments (e.g. `[04:12]`) and
  chapter titles alongside written document citations.
- Ingestion is fast and lightweight, handling entire playlists in seconds.
