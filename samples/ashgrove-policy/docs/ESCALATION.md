# Escalation: shared shop macro ASHRLEN has no owner

Devin has **not** changed `maclib/ASHRLEN.mac`.

- ASHRLEN is in the shared shop macro library (1987, Systems Programming). Any routine that issues it gets the wrong field, not only PLCYIO, and every one of them is reassembled with the new value the next time it is built.
- There is no named owner for the macro library today, so nobody can approve the change or say which other load modules depend on it.

What Devin provides instead:
1. The defect with line citations and the authoritative offset (`FINDING-001.md`, `evidence/dcbd-offsets.txt`).
2. A proposed macro (`proposals/ASHRLEN.proposed.mac`) and a run on the guest proving it clears the overwrite with unchanged totals (`harness/verify.sh`).
3. Interim guard: keep POLMAST unblocked until the fix is approved.

Decision needed from the mainframe platform lead: name an owner for the shop macro library, approve the proposed change, and schedule reassembly of the routines that use it.
