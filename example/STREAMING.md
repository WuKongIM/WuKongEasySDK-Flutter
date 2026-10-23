# Flutter 流消息 Demo / Streaming demo

From the repository root:

```sh
flutter pub get
cd example
flutter pub get
flutter run -d <device-id>
```

The shipped native example uses Flutter 3.41+ / Dart 3.11+; the SDK library retains its existing platform requirements.

Open **流消息**. Enter a writable development WuKongIM HTTP API, connect, and send a question. The example provisions two users and a group, discovers the device-reachable WebSocket route, and uses two independent EasySDK peers. The ordinary communication tab remains available.

The default reply is simulated, with configurable chunk size and interval. **回复设置 → 兼容模型 SSE** accepts an API base URL (for example `http://127.0.0.1:11434/v1`), model name and optional key. Requests use text-only Chat Completions streaming and include recent completed conversation context. Keys stay in screen memory, never logs or transcript. Cancellation closes the upstream HTTP client. Errors and EOF without `[DONE]` preserve confirmed partial text as a failed snapshot.

Try **取消生成**, **模拟失败**, or disconnect only the reader while the writer keeps generating. Reconnect to recover the full snapshot once through `/channel/messagesync` with `event_summary_mode: full`. Live events arriving during recovery are buffered and merged using UTF-8 byte offsets. There is no online history/event polling.

The producer sends a persisted parent through `send(options: SendOptions(clientMsgNo: key, setting: MessageSetting(stream: true)))`, then sequentially writes `stream.open`, `stream.delta`, optional `stream.cancel` / `stream.error`, and `stream.finish` to `/message/event`. `client_msg_no` is the stable parent identity; `event_key` is `main`. Custom events are received through `WuKongEvent.customEvent` and do not generate RECVACK.

Development access is intentional: production account provisioning, authorization, model credentials, and `/message/event` writes belong in an authenticated business backend. Use HTTPS/WSS when traffic leaves a trusted development network. Android emulators reach the host via `10.0.2.2`; iOS simulators use `127.0.0.1`; physical devices require LAN-accessible addresses, including the server's advertised WebSocket route. Browsers additionally need permitted CORS. The example's HTTP parser refuses redirects.

Bounds: 40 history rows, 16,384 UTF-16 units per reply, 2,048 event IDs per row and recovery buffer, 24,000 units of model context, 64 KiB SSE line/event, 4 MiB SSE response, 30s model idle timeout, 180s total deadline, and 100 safe protocol log entries. Disposing the screen closes both peers and HTTP transports. Use a new session to change the cluster address.

## Repeatable native acceptance

```sh
python3 example/tools/stream_acceptance.py \
  --server-bin /absolute/path/to/wukongim \
  --simulator <booted-ios-simulator-udid> \
  --output /tmp/wk-flutter-stream
```

Requires Flutter on PATH, Xcode and Python 3 on macOS. Pass `--flutter /absolute/path/to/flutter` when needed. The runner starts its own temporary single-node cluster (256 hash slots) and fragmented SSE fixture. It compiles and runs the real Flutter screen controller with actual SDK WebSockets, then saves JSON evidence plus partial/completed/recovered/model screenshots. It terminates only its owned processes. Use `--consumer /path/to/example-copy` to repeat against an exact public pub.dev dependency. Acceptance activates only in debug builds with explicit `STREAM_ACCEPTANCE_API` and `STREAM_ACCEPTANCE_MODEL` compile-time defines; normal app launches do not run it.

See [failure plan](../doc/STREAMING_VALIDATION.md). Native iOS runtime verification and web compilation are distinct evidence; do not treat an untested platform as runtime-verified.
