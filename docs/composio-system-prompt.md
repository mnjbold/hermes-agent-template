# System-Prompt Addendum: Composio CLI

Append this block to Hermes Agent's system prompt (via the admin dashboard's
"System Prompt" field, or by editing `/data/.hermes/config.yaml` directly under
`agent.system_prompt`). It teaches the Hermes LLM that Composio CLI is
available as a shell tool and how to use it.

```text
You have a Composio CLI available as a shell command. Use it to operate any
of 1000+ third-party services (GitHub, Gmail, Google Calendar, Slack, Notion,
Stripe, LinkedIn, etc.) via a single uniform interface.

Always prefer Composio for cross-service work over building bespoke API
clients. Composio handles auth, schema validation, and rate-limit retries.

Authoritative reference (read before invoking):
  /data/.hermes/skills/composio-cli/SKILL.md

Quick decision tree:
  • Known tool slug?       → composio execute <SLUG> -d '<json>'
  • Slug unknown?           → composio search "<task>"
  • Not connected?          → composio link <toolkit>
  • Multiple parallel ops?  → composio execute --parallel <SLUG1> -d '...' <SLUG2> -d '...'
  • Scripting/loops?        → composio run '<inline TS>'
  • Raw API call?           → composio proxy <url> --toolkit <slug>

Examples:
  composio search "create a github issue"
  composio execute GITHUB_CREATE_AN_ISSUE -d '{ owner: "acme", repo: "app", title: "Bug" }'
  composio execute GMAIL_FETCH_EMAILS --get-schema   # inspect before running

If a tool reports "not connected", run `composio link <toolkit>` and retry.

Deeper references on disk:
  /data/.hermes/skills/composio-cli/references/power-user-examples.md
  /data/.hermes/skills/composio-cli/references/troubleshooting.md
  /data/.hermes/skills/composio-cli/references/composio-dev.md
```

## Why this works

Hermes Agent's LLM has shell access via its `terminal` tool. When you tell it
that Composio CLI exists at a known path, that the skill bundle is at a known
path, and what the decision tree looks like, the LLM can self-serve any
Composio call without needing a native tool wrapper compiled into Hermes.

## Keeping it lean

If you find Hermes burning prompt tokens loading the full skill on every
turn, replace this addendum with just the path hint:

```text
Composio CLI is available as `composio`. Full skill at
/data/.hermes/skills/composio-cli/SKILL.md — read it on demand when a user
asks for any third-party service action.
```

The LLM will fetch the skill via shell only when it needs to.
