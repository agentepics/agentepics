# SKILL.md: the simplest AI standard with the biggest security problem

**SKILL.md is an open standard by Anthropic for packaging AI agent capabilities as plain Markdown files — and it has achieved the fastest cross-vendor adoption of any agent standard to date.** Released as an open specification on December 18, 2025, it was adopted by OpenAI Codex, GitHub Copilot, Google Gemini CLI, Cursor, and VS Code within weeks. The format's radical simplicity — a folder with a Markdown file and optional scripts — struck a nerve with developers weary of over-engineered protocols. Yet that same simplicity has created what security researchers now call one of the largest supply chain attack surfaces in the AI ecosystem, with **26.1% of publicly shared skills containing at least one vulnerability** according to an empirical study of over 31,000 skills. The SKILL.md story is a case study in how a deliberately under-specified standard can win rapid adoption and simultaneously invite serious risk.

---

## What SKILL.md actually is and where it came from

Anthropic introduced "Agent Skills" on October 16, 2025, as a Claude-specific feature. On December 18, 2025, the company released the format as an open standard at **agentskills.io**, with a reference SDK and an Apache 2.0 / CC-BY-4.0 license. The canonical spec repository (`github.com/agentskills/agentskills`) has accrued roughly **11,900 stars**, while Anthropic's reference skills collection (`github.com/anthropics/skills`) has gathered approximately **69,300 stars** — a staggering number that reflects the standard's momentum.

A skill is a directory containing a required `SKILL.md` file plus optional `scripts/`, `references/`, and `assets/` subdirectories. The `SKILL.md` file itself consists of **YAML frontmatter** (with required `name` and `description` fields) followed by a **Markdown body** containing instructions. Only two fields are mandatory; everything else is optional or unspecified. Simon Willison, one of the most respected voices in AI developer tooling, called the spec "deliciously tiny" and "quite heavily under-specified."

The core architectural innovation is **progressive disclosure** — a three-tier loading system that addresses the context window problem. At startup, the agent loads only skill names and descriptions (~100 tokens each). When a task matches, the full SKILL.md body loads (~2,000–5,000 tokens). Referenced files and scripts load only when explicitly needed during execution. This design means agents can have access to hundreds of skills without burning context tokens, solving a problem that plagues tool-heavy MCP configurations where a single GitHub MCP server can consume **over 50,000 tokens** of JSON schemas before the model begins reasoning.

Anthropic frames skills as complementary to MCP: "MCP is the plumbing — how agents connect to tools and data. Agent Skills are the manual — how agents use those connections to achieve goals." Or, as Block's Goose team put it more concisely: "Skills describe the workflow. MCP provides the runner."

---

## Adoption velocity that surprised even proponents

The speed of cross-vendor adoption has been historically unusual for an AI standard. **Within 48 hours** of Anthropic's open-standard announcement, OpenAI added SKILL.md support to Codex CLI — the OpenAI logo appeared on the Agent Skills homepage by December 20, 2025. GitHub Copilot announced support the same day as Anthropic's release. Google's Gemini CLI followed in early 2026, explicitly citing cross-compatibility with Claude Code, Codex, and Cursor.

The adopter list now spans the major coding AI tools: Claude Code, OpenAI Codex, GitHub Copilot, VS Code (native `chatSkills` contribution point), Cursor, OpenCode, Amp, Letta, and Goose. Partner-built skills from **Atlassian, Canva, Cloudflare, Figma, Notion, Stripe, Sentry, and Zapier** were available at launch. Framework integrations exist for LangChain (via adapters in the `agent-skills-sdk` package), CrewAI, Pydantic AI, DSPy, and Spring AI. The standard is expected to be stewarded by the **Agentic AI Foundation**, a Linux Foundation initiative whose platinum members include AWS, Anthropic, Block, Google, Microsoft, and OpenAI.

This adoption pattern stands in contrast to MCP, which took months to gain multi-vendor traction. The likely explanation is that SKILL.md's barrier to adoption is near-zero: supporting the standard requires only reading a Markdown file and injecting it into a prompt. There is no protocol to implement, no server to run, no schema to validate.

---

## The praise: simplicity as a design philosophy

The most consistent theme across practitioner commentary is that SKILL.md's simplicity is its defining strength. Willison captured the sentiment widely shared in the developer community: "MCP is a whole protocol specification... Skills are Markdown with a tiny bit of YAML metadata and some optional scripts in whatever you can make executable in the environment. They feel a lot closer to the spirit of LLMs."

Several specific advantages recur across dozens of blog posts and forum discussions:

- **Token efficiency** through progressive disclosure, enabling agents to maintain awareness of hundreds of capabilities without context bloat
- **Human readability** — skills are simultaneously documentation for developers and instructions for agents, reviewable in pull requests and trackable in Git history
- **Zero infrastructure** — no servers, no compilation, no SDK required; a developer can create a functional skill in minutes
- **Cross-platform portability** — write once, use across Claude, Codex, Copilot, Gemini, and Cursor
- **Organizational knowledge capture** — as one Creative Tim article observed, "the moment you move your standards from 'what I told the model yesterday' into a SKILL.md folder, they become team knowledge, not personal memory"

LangChain's team highlighted a surprising observation from their deep agents research: generalist agents like Claude Code use remarkably few tools (about a dozen), and skills provide a way to add domain expertise without expanding the tool surface. Daniel Miessler, an influential security and AI blogger, built **77+ skills** for his personal AI infrastructure and declared skills "maybe a bigger deal than MCP."

A particularly interesting emergent use case came from Sionic AI, who published on Hugging Face about using skills as **team memory for ML experiments**. Their "Failed Attempts" sections in skills — documenting what didn't work and why — became the most-read content on their team. "Success paths are nice to know, but failure paths are what save time," the team noted.

On Hacker News, user **Spivak** offered a wry observation that captured a real phenomenon: "Have we finally tricked devs and companies into writing good documentation by making it into an AI thing?"

---

## The criticism: six substantive concerns from practitioners

### Non-determinism is the fundamental tradeoff

The most technically significant criticism comes from LlamaIndex's team, who conducted a direct comparison between skills and MCP tools for their documentation use case. Their finding was sobering: "Being defined with natural language leaves skills open for misinterpretations and hallucinations by the LLM, and does not provide only one deterministic way to execute a task. This is in contrast to an MCP tool, which once an agent chooses to use, is a straightforward API call under the hood." They found that their documentation MCP yielded comparable or better results than skills for code generation, with the added benefit of auto-updating when docs changed — while skills required **manual maintenance** to stay current.

### The description field is a single point of failure

Multiple practitioners independently converged on the same practical insight: the `description` field in the YAML frontmatter determines whether a skill ever activates, and getting it right is surprisingly difficult. Bibek Poudel, who built skills from scratch for multiple use cases, identified this as the primary stumbling block: "The problem was never what you wrote inside the skill. It was the two lines at the top that the agent uses to decide whether to activate it at all." A dev.to commenter articulated a deeper tension: "The SKILL.md file is doing double duty — documentation for humans AND instructions for the agent. Those two audiences need different things. When you write a SKILL.md that tries to serve both, it ends up serving neither well."

### Supply chain security is genuinely alarming

This is the area where criticism has been most severe and best-documented. An arXiv paper analyzing **31,132+ skills** found that **26.1% contain at least one vulnerability** across 14 distinct attack patterns, with data exfiltration (13.3%) and privilege escalation (11.8%) most prevalent. Skills with executable scripts are **2.12x more likely** to contain vulnerabilities. Snyk's "ToxicSkills" research found **36.8% of nearly 4,000 scanned skills** had at least one security flaw. Koi Security discovered **1,184+ confirmed malicious skills** on ClawHub in what they called one of the largest supply chain poisoning campaigns in agent ecosystems.

Johann Rehberger of Embrace The Red demonstrated particularly concerning attacks using **hidden Unicode Tag codepoints** in SKILL.md files — characters that certain models interpret as instructions but are invisible to human readers. As 1Password's analysis noted: "People don't expect a markdown file to be dangerous." The Grith.ai team articulated the core problem: "Instructions are prompts. The control plane is natural language. There is no strict data/instruction boundary."

### Ecosystem churn erodes trust

When Mintlify deprecated their `install.md` format just **six days** after announcing it in favor of SKILL.md, the Hacker News community reacted sharply. User **lovich** offered the most pointed critique: "There is no world outside of a cult or hype bubble where a 6 day turnaround time from announcement to deprecation is acceptable for a standard." User **RadiozRadioz** added: "Far too much churn in this ecosystem. This decreases my confidence." The pattern of rapidly proliferating standards — SKILL.md, AGENTS.md, CLAUDE.md, llms.txt, install.md — has produced visible fatigue. Ian Nuttall captured this on X: "Claude might be in danger of overcomplicating a lot of stuff — Skills, Agents, Marketplaces, Plugins, Projects. All with their own way of doing things."

### Enterprise readiness gaps persist

GitHub issues across multiple repositories document real enterprise blockers. Claude Code issue #26254 describes organization-wide skill deployment that "does not reliably work" with "silent failure: users have no indication that skills aren't loading." One user invested time building **36 custom skills** that completely failed in Cowork mode on Windows. Case sensitivity of the SKILL.md filename caused "several hours of debugging" for another user, with no helpful error messages.

### Context pollution and staleness

Matthew Groff's practical implementation guide warned: "Skills can burn context when they are no longer useful. Install-heavy skills linger in your .claude/skills/ directory and get loaded into sessions where they add nothing." He also noted skills can conflict with existing codebase conventions — a generic "React best practices" skill might contradict your architecture. LlamaIndex's team found skills needed "constant manual updates" compared to MCP's ability to reflect documentation changes automatically.

---

## How SKILL.md fits the emerging agent architecture stack

The AI agent ecosystem is converging on a layered architecture where SKILL.md occupies a specific niche. At the **communication layer**, Google's Agent2Agent (A2A) protocol handles inter-agent discovery and delegation using JSON-RPC over HTTP. At the **connectivity layer**, MCP provides structured tool integration with deterministic execution and OAuth-native authentication. At the **knowledge layer**, SKILL.md packages procedural expertise — the "how" of approaching tasks. Below these, OpenAPI describes API interfaces, and function calling schemas enable structured invocation of specific operations. Project-level conventions live in AGENTS.md files.

David Cramer of Sentry, who uses both MCP and ~12 skills in production, offered a nuanced view: "MCP is an over-engineered protocol that does a lot of things that no one uses, but tools pair extremely well with harnesses and Skills." Speakeasy, which released 21 production skills, provided the practical synthesis: "You go all-in on skills, and your agents have great playbooks but no live access to your services. They know how to query your API but can't actually authenticate and call it." The consensus position, articulated by the dev.to community, is that production agents combine "system prompt for baseline behavior, skills for task-specific expertise, MCP for external data, function calling for actions, and subagents for complex orchestration."

One forward-looking perspective worth noting: a commenter named **harsimony** predicted that "skills will soon be replaced by LoRA adapters given that we know a LoRA can provide a similar function to additional context." Meanwhile, a Peking University paper on "Meta Context Engineering via Agentic Skill Evolution" references SKILL.md as a "static skill architecture" and proposes dynamic skill evolution — suggesting the academic community views the current format as a starting point, not an endpoint.

---

## Conclusion: a standard that won on vibes and faces real consequences

SKILL.md succeeded because it aligned perfectly with how LLMs actually work — they process natural language, and skills are natural language. The format requires no infrastructure, no protocol implementation, and no specialized tooling. This made adoption nearly frictionless, producing the rare outcome of competing companies (Anthropic, OpenAI, Google, Microsoft) converging on a shared standard within weeks.

The critical question is whether the format's deliberate under-specification — its greatest adoption advantage — will prove to be its greatest technical liability. The **26.1% vulnerability rate** in public skills is not a theoretical concern; it represents a live, actively exploited attack surface. The spec is still at **v0.9**, with v1.0 expected in the second half of 2026. The Agentic AI Foundation is working on skill verification (digital signatures), which would address provenance but not the fundamental problem that natural language instructions cannot be formally verified for safety.

The most actionable insight from practitioners is clear: **custom, team-written skills deliver strong value; third-party marketplace skills carry serious risk.** The format works best as organizational knowledge capture — versioned, reviewed in PRs, and specific to your codebase — rather than as a plug-and-play package ecosystem. The parallel to early npm or PyPI security challenges is apt, but with a critical difference: in traditional package managers, code is at least syntactically verifiable. In SKILL.md, the "code" is natural language interpreted by a probabilistic model, making the attack surface fundamentally harder to defend.