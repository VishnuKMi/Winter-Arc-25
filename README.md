# Winter Arc '25

> Repository for documenting my work as an independent security researcher — reproducible attack reproductions, PoCs, writeups and (future) audit reports.

This repo collects reproducible **attack vectors** I study and implement to learn, teach, and document smart-contract security issues. Each attack folder contains a small, self-contained project with contracts, deployment / test scripts, and tests so you can reproduce results locally.

---

## Quick status / goals

- ✅ Reproduce and document real attack classes (reentrancy, approval race, TOD, etc.)
- ✅ Provide reproducible Foundry projects per attack
- 🔜 Add writeups, full PoCs, and audit-style reports
- 🔜 Publish a curated learning path & checklist for security researchers

---

## Recommended tooling / workflow

- **Foundry (forge, anvil)** — for building & testing (used in each example)
- **VS Code** with:

  - Solidity extension (Nomic Foundation / Juan Blanco)
  - Devcontainer support (if you want reproducible environment)
  - Snippets for NatSpec (helpful while writing writeups)

- **Slither / MythX / Echidna** — static analysis & fuzzing (optional)

---

## Contributing / guidelines

If you want to contribute an attack reproduction, PoC, or writeup:

1. Fork this repo and create a new folder under `attack vectors/` named `Short-Title-Of-Attack`.
2. Add a `README.md` in that folder with:

   - Attack name + CVE / reference (if applicable)
   - Short writeup + severity & impact
   - How to reproduce steps (exact `forge` commands)

3. Keep the example minimal and reproducible:

   - `src/`, `tests/`, `script/`, `foundry.toml`
   - Prefer `forge test` as the canonical reproduction

4. Open a PR with description and expected outputs (logs). I’ll review and merge.

---

## Responsible disclosure & ethics

- The contents are **educational** and for **defensive research / learning** only.
- Do **not** use these PoCs against live targets you do not own or have explicit permission to test.
- If you discover a vulnerability in a live system, follow responsible disclosure (contact the project or vendor privately).
- I will **not** assist in weaponizing vulnerabilities — I focus on understanding and mitigation.

---

## Contact / follow-up

If you have suggestions, requests, or contributions:

- Open an issue or PR in this repo.
- You can also reach me at: `Vishnu KM` (GitHub profile / contact on my profile page).

---

## Roadmap (coming soon)

- Polished writeups & diagrams for each attack class
- Full PoCs with step-by-step reproduction on testnets (where safe)
- Audit-style templates / checklist for independent researchers
- A "Learning Path" directory: curated sequence of exercises

---

Thanks for checking out **winter arc '25** — hope you find the reproductions useful for learning and building safer contracts.

Signed,
**Vishnu KM**
