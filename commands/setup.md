---
description: Set up Otta in this repo — install the local gate hook and the Pulse GitHub App
---

Set up the Otta shipping loop for this repository.

1. Install the pre-push gate hook (mirrors the Pulse merge gates locally):

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/install-git-hooks.sh"
   ```

2. Onboard the Otta Pulse GitHub App so DORA + lifecycle metrics flow:

   ```bash
   bash "${CLAUDE_PLUGIN_ROOT}/scripts/pulse-install.sh"
   ```

   Installing the App is interactive GitHub consent — you cannot do it for the user. Print the URL from the script and ask the user to open it, pick their account/org, and click Install. Offer to open it for them with `--open` if they're on this machine.

3. Tell the user the loop is ready: `/otta:start <issue>` to begin, `/otta:ship` to gate + open the PR.
