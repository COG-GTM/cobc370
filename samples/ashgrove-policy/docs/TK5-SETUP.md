# Running the sample on TK5 (MVS 3.8j under Hercules)

Everything the harness needs is in this repository except the emulator and the guest operating system,
which are free downloads.

## One-time install
1. Hercules 4.x (SDL Hyperion), built or packaged for your host: https://sdl-hercules-390.github.io/html/
   Verified with 4.9.1.
2. TK5 (a ready-to-run MVS 3.8j system for Hercules): https://www.prince-webdesign.nl/tk5
   Unzip it, for example to `~/mvs-demo/mvs-tk5`. Verified with TK5 Update 5.
3. Build the cobc370 compiler: `make -C src` (from the repository root).

Defaults match the paths above. Otherwise set `TK5_HOME` (the TK5 directory) and `HERCULES` (the binary).

## Every run
```bash
samples/ashgrove-policy/tools/tk5-start                 # IPL, about 40 s; returns when MVS reports "system initialization complete"
bash samples/ashgrove-policy/harness/verify.sh          # about 8 s; uses tools/tk5-run unless COBC370_RUNNER is set
bash samples/ashgrove-policy/harness/reset.sh           # removes harness/work
samples/ashgrove-policy/tools/tk5-stop                  # optional; leave the guest up between rehearsals
```

## What the tools do
- `tools/tk5-start` starts Hercules with TK5's unattended IPL script, logs the console to
  `$TK5_HOME/log/hercules-console.log`, and waits for the `MVS038J` ready message.
- `tools/tk5-run <deck.jcl> <outfile>` is the `COBC370_RUNNER` (see the repository README, "Running the tests").
  It sends the deck to the TK5 card reader on 127.0.0.1:3505, waits for JES2's `$HASP150` message for the
  job (class Z output stays queued, so `$HASP250` never arrives), and copies what the job printed
  (`prt/prt00e.txt` class A, `prt/prt00f.txt` class Z) to `<outfile>`.
- `tools/tk5-stop` stops the emulator.

No credential is needed: the sample's job card has no `USER=`. The runner substitutes the test suite's
`@HERC01PW@` token from `TK5_JOB_PASSWORD` only for decks that carry it.

## Ports and isolation
TK5 listens on 3270 (terminals), 3505 (card reader) and 8038 (Hercules web console). If those are taken on
the host, or should not be exposed, set `MVS_NAMESPACE=<name>` for both `tk5-start` and `tk5-run`: the guest
then runs in a private Linux network namespace (needs passwordless `sudo`).
