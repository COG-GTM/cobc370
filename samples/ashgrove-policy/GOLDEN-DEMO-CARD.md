# Golden Demo card: Insurance policy administration, IBM HLASM (mainframe assembler) modernization

## Title
Insurance / Policy administration (IBM HLASM): Devin explains an undocumented assembler routine under a policy batch, writes the spec, and proves a latent control-block bug on a real MVS system

## Use case tags
- Part 4 use case: Large-Scale Modernization
- Flow type: Modernization
- Keywords: policy administration, mainframe, IBM HLASM, assembler, COBOL-74, MVS 3.8j, Hercules, specification, test harness. Audience: CIO, mainframe modernization lead.

## Repo(s)
- Repository: [COG-GTM/cobc370](https://github.com/COG-GTM/cobc370), synthetic carrier Ashgrove Mutual.
- Branch: `devin/1791850300-ins-mainframe-hlasm-spec` (base `main`), PR [#1](https://github.com/COG-GTM/cobc370/pull/1).
- Shared: **no.** All files are new, under `samples/ashgrove-policy/`; no compiler changes.

## Business problem
Policy batches still call small hand-written assembler routines that nobody documented and whose last expert retired, so every change is a guess and every modernization estimate carries a large unknown. Teams need to know what these routines really do, and whether they hide defects, before they can retire or rewrite them safely.

## Trigger
Audit of an undocumented dependency: the routine's author retired and the shared macro it uses has no owner.
- [src/PLCYBAT.cbl](https://github.com/COG-GTM/cobc370/blob/45b04c9/samples/ashgrove-policy/src/PLCYBAT.cbl): the COBOL-74 renewal batch `CALL`s `PLCYIO` for open, read and close.
- [src/PLCYIO.asm:21-27](https://github.com/COG-GTM/cobc370/blob/45b04c9/samples/ashgrove-policy/src/PLCYIO.asm#L21-L27): `GET POLDCB`, then the length comes from shop macro `ASHRLEN 9,5` and drives an `MVCL` copy into the caller's record.
- [maclib/ASHRLEN.mac:5](https://github.com/COG-GTM/cobc370/blob/45b04c9/samples/ashgrove-policy/maclib/ASHRLEN.mac#L5): `LH &REG,62(,&DCB)` commented `LRECL`, written in 1987, no owner today.
- [docs/CALLGRAPH.md](https://github.com/COG-GTM/cobc370/blob/45b04c9/samples/ashgrove-policy/docs/CALLGRAPH.md): the author of PLCYIO retired.

## Wow moment
On a real MVS 3.8j system (TK5 on Hercules), one script runs the batch twice: the unblocked file matches the golden, the blocked file shows **24 of 24 reads overwriting the caller's storage**, and Devin traces this to one wrong offset in a 1987 macro, cites the operating system's own control-block map, and proves the fix with **0 overwrites** without changing the shared macro.

## Talk track
About 10 minutes.
1. (1.5 min) **Say:** "This policy batch calls PLCYIO, an assembler routine. There is no documentation, and the person who wrote it retired. HLASM is IBM's mainframe assembly language: the lowest-level code on the box." -> **Show:** `src/PLCYIO.asm` and `docs/CALLGRAPH.md` line 3.
2. (1 min) **Say:** "Devin read the source and recovered the call graph and the register conventions: which register carries the function code, the status, and the caller's buffer." -> **Show:** `docs/CALLGRAPH.md`.
3. (1.5 min) **Say:** "Then Devin wrote a specification, every statement cited to a source line, with the jargon explained: a DCB is the control block MVS keeps for an open file, LRECL is the record length, BLKSIZE is how many bytes are read per block." -> **Show:** `docs/SPEC.md`.
4. (1.5 min) **Say:** "To check the routine against the operating system itself, Devin assembled IBM's own DCB map on the system and pulled the real offsets. Offset 62 is the block size. The record length is at offset 82." -> **Show:** `evidence/dcbd-offsets.txt`.
5. (2 min) **Say:** "Now the harness, on a real MVS system. Unblocked file, 80-byte blocks: matches the golden, which is why nobody ever noticed. Blocked file, 800-byte blocks: every one of 24 reads overwrites the caller's guard. With the proposed one-line macro fix: matches the golden, zero overwrites." -> **Show:** `bash harness/verify.sh` table (7/7 job steps COND CODE 0000 for both variants, 8 seconds).
6. (1 min) **Say:** "Here is the finding, with proof." -> **Show:** `docs/FINDING-001.md`.
7. (1.5 min) **Say:** "Devin did not change the macro. The macro is shared, other routines may depend on it, and nobody owns it. Devin proposed the fix with evidence and asked for an owner." -> **Show:** `docs/ESCALATION.md` and `proposals/ASHRLEN.proposed.mac`.

## Hard case / human decision
`ASHRLEN` lives in a shared shop macro library with no named owner, so Devin does not change it. `docs/ESCALATION.md` asks the mainframe platform lead to (1) name an owner, (2) approve or reject `proposals/ASHRLEN.proposed.mac` (offset 82, `DCBLRECL`), and (3) schedule reassembly of every routine that uses the macro.

## Deterministic setup
Setup notes are in [samples/ashgrove-policy/docs/TK5-SETUP.md](https://github.com/COG-GTM/cobc370/blob/45b04c9/samples/ashgrove-policy/docs/TK5-SETUP.md).
- Prerequisites: Hercules 4.x (verified 4.9.1) and TK5 Update 5, unzipped to `~/mvs-demo/mvs-tk5` (or set `TK5_HOME` and `HERCULES`); both are free downloads, linked in TK5-SETUP.md. Then `git clone https://github.com/COG-GTM/cobc370 && cd cobc370 && git checkout devin/1791850300-ins-mainframe-hlasm-spec && make -C src`.
- Before the meeting: `samples/ashgrove-policy/tools/tk5-start` (unattended IPL, measured 44 s; returns when MVS reports `system initialization complete`). Not part of the demo.
- Run: `bash samples/ashgrove-policy/harness/verify.sh`. Expected runtime: 8.1 s measured. The harness uses the in-repo runner `tools/tk5-run`, which submits the JCL to the TK5 card reader (127.0.0.1:3505) and waits for JES2's `$HASP150` print-complete message; `COBC370_RUNNER` can point at another runner.
- Reset: `bash samples/ashgrove-policy/harness/reset.sh` (removes `harness/work`; measured 0.006 s). Optionally stop the guest with `samples/ashgrove-policy/tools/tk5-stop`.
- Fixture vs live: the 24 policy records (`data/POLMAST.dat`) and the golden (`goldens/unblocked.txt`) are fixtures. The assemble, compile, link and both batch runs happen live on the TK5 guest each time. No credentials are needed: the sample's job card has no `USER=`.

## Devin inputs
- Prompt: "Explain PLCYIO in samples/ashgrove-policy: call graph, register conventions, a spec with line citations, and a TK5 golden harness. Report any defect with proof; do not change shared macros without an owner."
- Versioned link: the prompt is versioned in this card on the PR branch; the sample and run instructions are [samples/ashgrove-policy/README.md @ 45b04c9](https://github.com/COG-GTM/cobc370/blob/45b04c9/samples/ashgrove-policy/README.md). No playbook or automation is required.

## Outputs
`docs/CALLGRAPH.md`, `docs/SPEC.md`, `docs/FINDING-001.md`, `docs/ESCALATION.md`, `evidence/dcbd-offsets.txt`, `harness/run_tk5.sh`, `harness/verify.sh`, `harness/reset.sh`, `goldens/unblocked.txt`, `proposals/ASHRLEN.proposed.mac`, `tools/tk5-start`, `tools/tk5-run`, `tools/tk5-stop`, `docs/TK5-SETUP.md`.

## Evidence
- Pre-run session: https://devin-gtm.devinenterprise.com/sessions/f2fb4f5cc4f14faaac12cbc1d9689fc6
- PR: [#1](https://github.com/COG-GTM/cobc370/pull/1), open, not merged.
- CI: Devin Review passed (the only check on this repo).
- Recording: clean-clone run at `98d06f7`, 58 s, zero failing steps, `git status` clean afterwards. The animated preview and mp4 link are at the top of the [PR #1 description](https://github.com/COG-GTM/cobc370/pull/1).
- Fresh-clone re-run at `45b04c9` using only repo contents: TK5 restarted with `tools/tk5-start`, `verify.sh` exit 0 in 8.1 s, reset, `git status` clean (log: `fresh-clone-verify.log`).
- Screenshots at the top of the PR description: verify table, FINDING-001, call graph, escalation. DCB offsets and assembler source screenshots are in the evidence bundle.
- Golden: `RESULT POLICIES=00024 RENEWALS=00016 PREMIUM=    72458.77`.

## Known caveats
- **Synthetic.** The routine, the macro and the offset bug were written for this demo. They say nothing about any production system and are not production-equivalent. The DCB offsets are real (from TK5's `SYS1.MACLIB`).
- "The team confirms" is scripted: the confirmation in the demo is Devin's own reproduction on MVS plus the escalation, not a real platform team.
- MVS 3.8j with IFOX00 is a public-domain predecessor of z/OS and HLASM. The DCB layout is the same; the assembler and operating system are older.
- Ports: TK5 listens on 3270, 3505 and 8038. If those are taken or must not be exposed, set `MVS_NAMESPACE` to run the guest in a private network namespace (needs passwordless sudo).

## Discovery questions
1. How many assembler routines are still called from your COBOL batch, and how many have a living owner?
2. When a routine has no documentation, how does your team find out what it does today: reading dumps, asking a retiree, or not touching it?
3. Who in your organization can approve a change to a shared macro library, and is that written down anywhere?

## Owner, Last verified, Next re-verify
- Owner: Garret Andreine
- Last verified: 2026-10-13 (fresh-clone run at `45b04c9` using only repo contents; recorded clean-clone run at `98d06f7`)
- Next re-verify: 2026-11-13
