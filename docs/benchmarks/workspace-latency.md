# Workspace command latency

Measured on the current M1 MacBook Air (16 GB), AeroSpace 0.21.3-Beta.

Each route has 20 samples, split evenly between both directions. Numbered pair: 2 ↔ 1; special pair: 2 ↔ W. Both pairs were occupied and assigned to the same monitor.

Timers cover subprocess launch through command completion. Focus was verified after every workspace switch, outside the timed interval. An 80 ms pause between samples lets callbacks settle. These measurements exclude physical keypress/Karabiner latency and do not establish when every window finishes repainting.

| Command path | Median (ms) | 95th percentile (ms) |
| --- | ---: | ---: |
| numbered: native back-and-forth (Command-Tab command) | 71.2 | 82.4 |
| numbered: direct summon | 75.4 | 114.0 |
| numbered: history script (Option-number) | 175.4 | 274.0 |
| numbered: history script (Option-backtick) | 141.8 | 177.6 |
| special: native back-and-forth (Command-Tab command) | 129.9 | 233.3 |
| special: direct summon | 104.4 | 164.5 |
| special: history script (Option-letter) | 205.0 | 309.5 |
| special: history script (Option-Tab) | 252.9 | 330.1 |
| component: focused workspace query | 31.0 | 45.8 |
| component: focused monitor query | 31.5 | 40.5 |
| component: empty Bash process | 16.1 | 20.7 |

The numbered history path was about 100 ms slower than direct summon; the letter path was also about 101 ms slower than direct summon. These differences include metadata queries, shell/process startup, locking, and file operations—not just writing history. Separately measured focused-workspace and focused-monitor queries each took about 31 ms, and an empty Bash invocation took about 16 ms. These component measurements suggest where the extra cost comes from but are not a trace of the actual script.

Native back-and-forth also varied by workspace pair, so window/app mix matters. This is one session of measurements rather than a hardware comparison or a universal latency guarantee.

The original workspace, focused window, native previous/current pair, and saved shell-history files were restored after the run.

Re-run (will switch the desktop repeatedly):

```sh
python3 scripts/benchmark-workspaces.py --samples 20 --output docs/benchmarks/workspace-latency.json
```
