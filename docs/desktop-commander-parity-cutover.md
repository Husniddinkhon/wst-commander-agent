# WST Commander: Desktop Commander parity cutover

**Current state (2026-10-29): NOT VERIFIED.** Local extension at `127.0.0.1:4320` is installed, and original Commander is reachable on 4318/4319. Remote ChatGPT MCP at `https://commander.montag.uz/mcp` does **not** yet expose the extension's desktop/files/process tools. The older gateway's explicit policy currently denies writes and app opening. Local port health is not remote parity.

## Read-only preflight (Node.js 20+)

Run on the paired Windows computer:

```powershell
node .\tools\verify-local-extension.mjs
node --test .\tools\verify-local-extension.test.mjs
```

The probe inspects ports 4318/4319/4320 and authenticates to the localhost-only extension using its existing token. It **never prints the token** and **never invokes a write, shell, UI or other mutation**. Successful results only prove local registration.

## Gateway implementation work (server backend, not the installer)

1. Identify the deployed `commander.montag.uz/mcp` server and paired outbound Windows agent source, back up server configuration and document rollback.
2. Add gateway tool discovery for the authenticated *paired* device, retrieving the local `tools/list` via existing outbound agent channel. Namespace extension tool names and preserve MCP descriptions and JSON schemas. Never let a model choose arbitrary device IDs or URLs.
3. Implement an audited, correlation-ID-bound relay from remote `tools/call` to local `127.0.0.1:4320/mcp` through that authenticated agent channel. **Do not expose port 4320 to the internet.** Keep the local bearer token on the paired computer; never forward it in chat responses or logs.
4. Enforce authorization **twice**: server/account/pairing permissions at gateway, explicit per-tool local policy and human approval for shell, file writes, deletion, clipboard, and sensitive UI actions. Never silently disable `restricted` or widen roots. Preserve error status, timeouts and image content.
5. Publish refreshed remote MCP tool schemas and reload/reconnect ChatGPT plugin only after relay passes verified end-to-end tests.

## Release gates

- [ ] Paired device identity and scope validated at gateway and agent.
- [ ] Remote `tools/list` shows extension capabilities; ChatGPT can see them.
- [ ] Read-only file listing/read passes end-to-end on approved workspace.
- [ ] Scratch-file write/edit/move/read-back passes with authorized policy & approval, without production data changes.
- [ ] Screenshot/window discovery, click, typing and clipboard actions tested in a disposable Windows test window with explicit approval.
- [ ] Allowlisted shell process start/output/terminate works under approved policy.
- [ ] Telegram/browser flows verified without sharing private messages or bypassing user approvals.
- [ ] Security tests: cross-user denial, fake device ID denial, external port 4320 inaccessible, unauthorized mutation denied, token never appears in logs.
- [ ] Watchdog reconnect and reboot recovery tested; no duplicate agent loops.
- [ ] 24-hour stability window without unhandled timeout and documented rollback to existing 4318/4319 behavior.
- [ ] Only after these checks: retire Desktop Commander dependency.

## Orchestration / chief agent rules

The WST Chief assigns work to Discovery, Implementer, Verifier and SRE roles based on real system state. For every task record: intent, owner, permitted tools, evidence, preconditions, change, verification, rollback and status. Investigate blockers through known connected sources rather than asking for server details already discoverable. Execute reversible low-risk changes autonomously; high-risk, financial or externally visible operations require appropriate approval. Do not claim work complete without the release gates above.
