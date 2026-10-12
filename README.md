# WST Commander for Windows

One-click installer for the WST Commander desktop agent.

## Install
1. Download this repository as ZIP or download the latest release.
2. Extract it.
3. Double-click **INSTALL-WST-COMMANDER.cmd**.
4. A browser page opens. Sign in, click **Approve code**, and paste the code shown by the installer (it is also copied to the clipboard).
5. Done. The agent starts automatically with Windows and reconnects by itself.

No Node.js, Python, Git, or PowerShell knowledge is required.

## What the installer does
- downloads the latest signed/served WST Commander agent package from `https://commander.montag.uz`;
- installs it per-user under `%LOCALAPPDATA%\WSTCommander`;
- creates a per-user Scheduled Task for automatic startup and restart;
- creates a fresh pairing request and opens the WST Commander control page;
- waits for approval, completes pairing, sends a heartbeat, and verifies the agent is online.

## Uninstall
Double-click **UNINSTALL-WST-COMMANDER.cmd**.

## Security
This public repository contains no production credentials, OAuth secrets, ERP credentials, Telegram sessions, or private server code. Pairing is always explicit and account-scoped.

Website: https://commander.montag.uz/
