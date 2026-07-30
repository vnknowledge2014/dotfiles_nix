> **Static review only.** These diffs were authored and reviewed by independent agents reading source. They were NOT compiled, run, or re-attacked. Review each diff yourself before applying.

## bug_00: [HIGH] Supply chain vulnerability via dynamic execution of @latest npm package (f001)

`home/modules/services/9router.nix:14` · code-execution · owner: component: home/modules/services/; top committer mike
**Status:** static_review_only · review ACCEPT · style 8/10

**Rationale:** Pinning the npm package version mitigates the supply chain risk of executing `@latest` automatically on every start.
**Variants checked:** No other npx @latest calls found in service definitions.
**Bypass considered:** If the pinned version itself has vulnerabilities, it remains vulnerable, but the attacker cannot silently push an update that is automatically executed.

## bug_01: [LOW] Command injection risk in eval statement (f002)

`docs/SECRETS.md:73` · command-injection · owner: component: docs/; top committer mike
**Status:** static_review_only · review ACCEPT · style 9/10

**Rationale:** Replacing `eval` with `source <(...)` prevents arbitrary command execution if the decrypted dotenv file contains malicious bash syntax.
**Variants checked:** No other eval commands on sops output found.
**Bypass considered:** An attacker could still theoretically place bash code in the dotenv output, but `source` with `set -a` on a dotenv format is generally safer.
