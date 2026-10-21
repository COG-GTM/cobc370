# Running the sample on TK5 (MVS 3.8j under Hercules)

Everything the harness needs is in this repository except the emulator and the guest operating system,
which are free downloads.

## One-time install
1. Hercules 4.x (SDL Hyperion), built or packaged for your host: https://sdl-hercules-390.github.io/html/
   Verified with 4.9.1. A source build defaults to `-march=native`, so a binary built on one CPU can die with
   "Illegal instruction" on another (for example after a VM moves hosts); build portable with
   `make CFLAGS="-O2 -march=x86-64 -pthread -D_GNU_SOURCE"` if the machine may change.
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
  `$TK5_HOME/log/hercules-console.log`, and waits for the `MVS038J` ready message. If the guest is already
  running it waits for that same message; if IPL does not finish in 300 s it stops the guest. The PID file
  records the process start time, so a stale file is never mistaken for a running guest. A PID-only file left
  by an older `tk5-start` is honoured only if that process is Hercules running in `$TK5_HOME` (where both versions
  launch it): `tk5-start` refuses to launch a second guest and `tk5-stop` stops it. Otherwise the file is stale.
- `tools/tk5-run <deck.jcl> <outfile>` is the `COBC370_RUNNER` (see the repository README, "Running the tests").
  It sends the deck to the TK5 card reader on 127.0.0.1:3505, waits for JES2's `$HASP150` message for the
  job (class Z output stays queued, so `$HASP250` never arrives), and copies what the job printed
  (`prt/prt00e.txt` class A, `prt/prt00f.txt` class Z) to `<outfile>`. It then purges that job from JES2 by
  number (`/*$PJn` on the reader) and fails if JES2 does not confirm, so finished jobs cannot fill the queue.
- `tools/tk5-stop` stops the emulator.

No credential is needed: the sample's job card has no `USER=`. The runner substitutes the test suite's
`@HERC01PW@` token from `TK5_JOB_PASSWORD` only for decks that carry it, in the stream to the reader
(the password is not written to disk).

## Ports and isolation
TK5's own configuration listens on all interfaces: 3270 (terminals), 3505 (card reader) and 8038 (Hercules
web console). By default `tk5-start` narrows this: the console and card reader bind to 127.0.0.1 only, and the
web console is stopped as soon as Hercules reads its startup script (it may listen for a few seconds before that).
`TK5_EXPOSE=1` keeps TK5's defaults. For full isolation, or if the ports are taken on the host, set
`MVS_NAMESPACE=<name>` for both `tk5-start` and `tk5-run`: the guest then runs in a private Linux network
namespace (needs passwordless `sudo`).
