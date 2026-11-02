# blind-review

A Claude Code skill that reviews a finished deliverable against the brief it was made from. It gives a fresh subagent only the brief and the deliverable, never the conversation, and asks it to review the way the real audience would. It has two modes: `interactive`, where you decide what to act on, and `gate`, where a calling skill acts on the verdict itself. Every report opens with a `PASS` or `FAIL` verdict; `FAIL` means at least one blocking finding.

- `skills/blind-review/SKILL.md` - the skill
- `.claude-plugin/` - plugin and marketplace manifests, so the repo installs as a Claude Code plugin
- `tests/run.sh` - checks run by `make test` and CI

## Install

Prerequisites: Claude Code. Pick one of the three.

As a Claude Code plugin (the skill runs as `/blind-review:blind-review`):

```bash
claude plugin marketplace add nkassis/blind-review
claude plugin install blind-review@blind-review
```

Globally, by hand (the skill runs as `/blind-review`; `git pull` updates it):

```bash
git clone https://github.com/nkassis/blind-review.git ~/src/blind-review
mkdir -p ~/.claude/skills
ln -s ~/src/blind-review/skills/blind-review ~/.claude/skills/blind-review
```

In one project (the skill runs as `/blind-review` in that repo; commit it to share it):

```bash
src="$(mktemp -d)"
git clone https://github.com/nkassis/blind-review.git "$src"
mkdir -p .claude/skills
cp -R "$src/skills/blind-review" .claude/skills/
rm -rf "$src"
```

## Use

```text
/blind-review [mode] [audience]
/blind-review interactive "a senior engineer on this repo, skeptical"
```

Installed as a plugin, type `/blind-review:blind-review` instead. Run it in the session that produced the work; it takes the brief and the deliverable from there.

`mode` is `interactive` (the default) or `gate`. `audience` is who judges the work in reality; the default is skeptical and experienced. In `gate` mode the skill fixes the blocking findings it agrees with and reviews again, at most two more rounds; any it disagrees with go back to the caller with a reason.

The skill builds the bundle the reviewer sees, in a new directory outside any repo:

| Put in the bundle | Leave out |
| --- | --- |
| The brief: for a PR, the issue description and human comments; for a document, the request | Transcripts, plans, notes, drafts, agent comments |
| The deliverable as the audience gets it: for a PR, the diff, a checkout path and the verification output; for a document, exported markdown or PDF | Live links |

The report is saved as `review-<n>.md` in that bundle directory. The skill returns its path and the verdict, and in `interactive` mode also shows it to you.

## Report

| Section | Contents |
| --- | --- |
| Verdict | `PASS` or `FAIL`; `FAIL` if and only if there is a blocking finding |
| Brief coverage | Every requirement in the brief: met, partly, not met, or not verifiable from the bundle |
| Findings | Each with severity (blocking or non-blocking), location, what is wrong, one action |
| Consistency | Contradictions between parts of the deliverable |
| Judgment | Whether it answers the question asked; what is overclaimed or missing |
| Keep | The three strongest aspects, so fixes don't destroy them |

## How it differs

Google's [Elephant-Goldfish Model](https://github.com/google/elephant-goldfish-model) uses the same isolation idea for design docs before code. This skill is lighter (one subagent, one gate), reviews against a separate brief, gates any deliverable, and makes the triage of false findings explicit.

The `blind-review` skill in the compound-engineering plugin is a different thing: three code reviewers blind to each other. This one is a single reviewer blind to the conversation.

## Developing this repo

`make test` runs the checks; see [AGENTS.md](AGENTS.md) for the harness.
