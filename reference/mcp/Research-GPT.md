Report: Strengths and weaknesses of the Model Context Protocol (MCP) for AI agents (as of March 5, 2026)

1) Methodology (deep research approach)

Research goal: assess MCP as a standard (protocol design + governance + real-world adoption) through documented praise/critique from practitioners, security researchers, and organizations that have implemented or evaluated it.

How sources were chosen
	•	Primary sources (highest weight): the MCP specification and security guidance, plus governance announcements (Linux Foundation, Anthropic, OpenAI).  ￼
	•	Security research (high weight): proof-of-concept attack writeups and an academic survey-style paper on MCP ecosystem risks.  ￼
	•	Practitioner critiques (medium weight): detailed “worked-with-it” essays about DX, gaps, and enterprise friction (often where sharp insights surface early).  ￼
	•	Industry analyses (medium weight): Thoughtworks and a16z (useful for framing but treated as secondary).  ￼

Bias control
	•	When a claim is self-reported by a project sponsor (e.g., adoption numbers), it is treated as directional unless corroborated elsewhere.  ￼
	•	Critiques are separated into: protocol design limits vs implementation/ecosystem issues (because many “MCP problems” are actually “agent security” problems).  ￼

⸻

2) What MCP actually standardizes

At its core, MCP is a JSON-RPC 2.0 protocol for connecting an “LLM host” to external “servers” that provide:
	•	Resources (context/data),
	•	Tools (callable functions),
	•	Prompts (templated workflows).  ￼

It explicitly borrows the ecosystem logic of the Language Server Protocol: many clients, many servers, one shared contract so integrations are reusable across tools.  ￼

Transport layer: the current spec defines two standard transports:
	•	stdio (client spawns server as a subprocess),
	•	Streamable HTTP (replacing the older HTTP+SSE transport; optional SSE for streaming).  ￼

Lifecycle and capability negotiation: MCP has a formal initialization phase where client and server negotiate protocol version and capabilities before normal operation.  ￼

Authorization direction (for HTTP): the spec now frames protected MCP servers as OAuth 2.1 resource servers, includes discovery metadata requirements, PKCE requirements, and explicitly requires Resource Indicators (RFC 8707) for audience binding.  ￼

⸻

3) Strengths

A. Interoperability that genuinely reduces the “N×M integration tax”

A recurring praise from builders is that MCP turns bespoke, per-agent connectors into portable integrations: build a server once, use it from many agentic clients (IDE, desktop assistant, orchestration runtime). That’s the core “standard interface” argument, and it is consistent across the spec itself and serious ecosystem analyses.  ￼

This matters for agents because tool ecosystems otherwise fragment quickly: every tool needs slightly different schemas, auth, retries, streaming, and semantics. MCP doesn’t eliminate that complexity, but it moves it behind a repeatable contract (especially for discovery, invocation, and streaming).  ￼

B. Strong “protocol hygiene”: versioning, negotiation, and operational utilities

MCP reads like a protocol written by people who have lived through real integration pain:
	•	explicit version negotiation,
	•	explicit capability negotiation,
	•	cancellation, progress, logging guidance,
	•	backward-compatibility guidance for older transports.  ￼

This is a real strength versus “tool calling” approaches that are primarily API features rather than a cross-client integration contract.

C. A pragmatic local-first path (stdio) that unlocked adoption

The stdio transport is a big adoption accelerant: it fits developer workflows (run a local server, connect instantly), avoids early network/auth complexity, and makes MCP feel like “plugins for agents”. That’s part of why MCP spread fast across dev tools.  ￼

D. Governance credibility improved significantly with Linux Foundation stewardship

MCP’s move into a vendor-neutral home is not cosmetic. The creation of the Agentic AI Foundation (AAIF) under the Linux Foundation explicitly positions MCP as shared infrastructure, with major backers across competing ecosystems.  ￼

For teams deciding whether to bet on MCP long-term, neutral stewardship is a tangible risk-reducer: fewer fears that the protocol becomes subtly optimized for one vendor’s product priorities.  ￼

E. The standard is expanding beyond “tools” into richer human-in-the-loop interaction

The emergence of MCP Registry (discoverability + moderation mechanics) and MCP Apps (UI surfaces inside agent experiences) indicates MCP is becoming a platform layer, not only a remote tool invocation format.  ￼

That direction is strategically coherent for agents: many agent failures are not “reasoning”, but “getting stuck in text-only interaction when a choice should be a UI step”.

⸻

4) Weaknesses

A. The fundamental security tension: MCP increases power faster than it enforces safety

The spec itself acknowledges MCP enables “arbitrary data access and code execution paths” and warns that tool descriptions/annotations should be treated as untrusted unless sourced from a trusted server.  ￼

But the deeper criticism from security research is structural: MCP often places context, metadata, and executable intent into a shared semantic channel. That blurs trust boundaries and amplifies prompt-injection-style failures into real actions (tool calls). An academic paper surveying the MCP ecosystem calls the security posture “underdeveloped” and highlights context poisoning and lack of uniform safeguards as systemic issues.  ￼

A concrete example: Palo Alto Networks Unit 42 describes new prompt injection attack vectors via MCP “sampling”, including PoCs where a malicious MCP server abuses implicit trust to drive unsafe behaviors.  ￼

Key point: This is not merely “implementation bugs”. It’s the reality that agents are decision-makers, and MCP is an action surface.

B. stdio is convenient, but it is also “implicit trust by construction”

The stdio transport frequently has no authentication between client and server because the server is spawned locally; security depends on OS/user boundaries and whatever credentials the server then uses downstream. Stack Overflow’s engineering writeup is blunt: no explicit auth occurs between client and server in stdio mode, and the spec does not cover how the server authenticates to upstream services.  ￼

So stdio is a strength for adoption, but a weakness for security posture in real environments where “local” is still a supply-chain risk (malicious server packages, poisoned repos, etc).

C. “MCP is not secure” is a fair critique if you interpret “secure” as authorization, not authentication

Authzed’s critique captures a subtle but important distinction: MCP can standardize how to connect (and increasingly, how to authenticate), but it does not inherently solve what an authenticated actor is allowed to do across tools, tenants, and data domains. That policy layer is left to implementers, and real incidents suggest many implementers get it wrong.  ￼

This gap shows up as:
	•	over-permissioned connectors,
	•	token handling mistakes,
	•	weak auditability,
	•	unclear mapping from “user consent” to enforceable policy across chained actions.

D. Authorization has improved, but the path has been turbulent and enterprise-fit is still debated

Early and mid-2025 critiques from Christian Posta and Solo.io argued the authorization approach created enterprise friction, especially around OAuth role confusion and assumptions that don’t match how enterprises centralize identity.  ￼

The current spec (2025-11-25) clearly moves toward more standard OAuth framing (resource servers, audience binding, PKCE, metadata discovery), and Aaron Parecki (deep OAuth expertise) describes the newer direction as motivated by real “open ecosystem” client registration constraints.  ￼

Net assessment: authorization is now much more serious, but enterprises still face hard questions:
	•	identity consolidation across many MCP servers,
	•	secrets management and token lifecycle at scale,
	•	how to implement least-privilege when “tools” are arbitrary functions.

E. Developer experience and “host-building” guidance has been a recurring pain point

Victor Dibia’s critique is not that MCP is useless, but that documentation historically skewed toward “use this with Claude Desktop” rather than “here is how to build a robust MCP host/client runtime,” which is what real system builders need.  ￼

Shrivu Shankar’s practitioner critique similarly frames MCP as powerful but full of nuanced edge cases and failure modes that developers will encounter first-hand when they go beyond demos.  ￼

F. Standardization gaps remain around semantics, error behavior, and ecosystem consistency

A practical critique: MCP standardizes discovery/invocation well, but leaves many behaviors “outside the protocol,” leading to inconsistent server conventions and brittle multi-vendor workflows.  ￼

Related: performance and token costs can rise when handling many MCP connections and large tool catalogs, which becomes an agent-runtime scaling problem, not just a protocol question.  ￼

⸻

5) Synthesis: what MCP is excellent at, and what it cannot be

A clean way to see MCP is: it is an interoperability and execution contract, not a safety guarantee, not an agent framework, and not an ontology of tool semantics.
	•	MCP is excellent at making tools/resources pluggable across agents (the LSP-style win).  ￼
	•	MCP is not, by itself, a solution to “agents acting safely” because that requires enforceable policy, sandboxing, and robust human-in-the-loop design across tool chains.  ￼

A useful mental model from security research is that MCP turns the messy world of “stuff agents can touch” into a high-leverage bus. Standardization increases composability, but also creates a clearer target and a larger blast radius when something goes wrong.

⸻

6) Practical implications for agent builders

If you are adopting MCP for real agents (not demos), the critiques above converge on a few grounded lessons:
	1.	Treat MCP servers as part of your attack surface, not as “plugins”. Favor allowlists, signing, provenance, and explicit trust tiers.  ￼
	2.	Assume prompt injection will happen and design tool policies accordingly (capabilities, scopes, rate limits, audit logs, step-up approvals for dangerous actions).  ￼
	3.	For remote servers, take OAuth seriously and validate that your identity provider supports what MCP requires (and that your architecture matches enterprise reality).  ￼
	4.	Expect version churn and capability differences across clients/servers; build negotiation and graceful degradation into your runtime.  ￼

⸻

Bottom line

MCP’s biggest strength is that it is one of the first widely adopted, protocol-disciplined attempts to make agent tool ecosystems interoperable, with credible governance and a rapidly expanding ecosystem.  ￼

MCP’s biggest weakness is that it standardizes a powerful action interface faster than the ecosystem can reliably secure it, and many of the risks are structural to agentic execution, not mere bugs.  ￼