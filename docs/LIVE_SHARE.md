# Krom Live Share Protocol (Skeleton)

Phase 5 ships `LiveShareService` and this protocol document.

## Messages

- `join` — `{ type, sessionId, participantId }`
- `edit` — `{ type, sessionId, participantId, filePath, rangeStart, rangeEnd, text }`
- `leave` — `{ type, sessionId }`

Offsets are UTF-16 code units (Flutter `TextSelection`).

## Status

| Layer | Status |
|-------|--------|
| WebSocket client | stub |
| Relay server | not included |
| CRDT / OT | planned |
