# Streaming demo failure plan (written before implementation)

Target: Flutter EasySDK 1.2.0; actual native Flutter example against a temporary single-node cluster (256 hash slots), with a fragmenting compatible model SSE fixture. Preserve JSON reports and screenshots. This demo gives a development client management API access; production provisioning, event writes and model keys belong in an authenticated backend.

Failures to exercise before shipping:
- Singleton and independent peers accidentally share configuration, event listeners or disposal.
- Stream settings disappear from SEND/RECV; legacy setting maps stop working; SENDACK `reason` is ignored.
- EVENT data arrives as an object, JSON string or null; a custom event accidentally receives RECVACK.
- Parent identity differs from `client_msg_no`; partial UTF-8 overlaps duplicate or corrupt emoji; gaps invent text; terminal cancellation/error changes to success on finish.
- Full history replaces partial state incorrectly, replays duplicate live events, polls while online, or reads beyond a bounded window.
- Cancellation/error loses acknowledged text; offline generation cannot recover; reconnect while generating repeats text.
- SSE splits UTF-8, CRLF, multiline data; error payload or missing DONE pretends success; cancellation leaves upstream running.
- Model credentials reach logs/transcripts; unbounded history, reply, dedup, SSE line/event/body buffers; HTTP redirects forward credentials.
- Disposed screens keep producers, recoveries, listeners or network peers alive.

Validation: SDK compatibility and projection tests first; existing SDK tests; analyzer and formatter; native process-level fixture driving the real screen controller and package transport, with progressive/completed/recovered/model screenshots. After publication, resolve the exact public pub.dev version into an empty consumer and repeat native acceptance. Record source and archive hashes separately from runtime proof.
