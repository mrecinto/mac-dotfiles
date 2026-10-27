# Workspace latency after optimization

M1 MacBook Air, 16 GB; AeroSpace 0.21.3-Beta. Twenty samples per route in both runs. Same occupied workspace pairs (2 ↔ 1 and 2 ↔ W), on the same monitor. Routes ran sequentially; app/background load was not controlled.

| Command path | Before median | After median | Reduction | Before p95 | After p95 |
| --- | ---: | ---: | ---: | ---: | ---: |
| numbered: native back-and-forth (Command-Tab command) | 71.2 ms | 75.3 ms | -5.8% | 82.4 ms | 133.0 ms |
| numbered: direct summon | 75.4 ms | 76.2 ms | -1.1% | 114.0 ms | 106.0 ms |
| numbered: history script (Option-number) | 175.4 ms | 107.5 ms | 38.7% | 274.0 ms | 133.3 ms |
| numbered: history script (Option-backtick) | 141.8 ms | 109.1 ms | 23.0% | 177.6 ms | 161.7 ms |
| special: native back-and-forth (Command-Tab command) | 129.9 ms | 134.8 ms | -3.8% | 233.3 ms | 269.0 ms |
| special: direct summon | 104.4 ms | 115.8 ms | -11.0% | 164.5 ms | 174.5 ms |
| special: history script (Option-letter) | 205.0 ms | 165.3 ms | 19.4% | 309.5 ms | 228.9 ms |
| special: history script (Option-Tab) | 252.9 ms | 195.8 ms | 22.6% | 330.1 ms | 233.6 ms |

The history helper now uses AeroSpace’s documented Unix socket API. One live query returns both focused workspace and monitor; the same connection executes the switch. Python handles locking and atomic history-file replacement without launching mkdir, mv, rmdir, or separate aerospace processes. A kernel lock covers the focus query through the completed switch and state write, avoiding stale state between overlapping helper invocations.

The existing workspace.sh entry point remains, so shortcuts and callers require no changes. The four-line per-monitor history file format remains compatible. No additional daemon or focus cache is used. The helper uses the system Python 3 standard library and socket protocol version 1, supported by the installed AeroSpace 0.21.3.

Numbered history overhead relative to direct summon fell from about 100 ms to 31 ms; letter history overhead fell from about 101 ms to 49 ms. These are differences between medians, not a component trace. Window/app-dependent switch work and process startup still contribute latency.

Timings measure subprocess start through command completion. They exclude physical keyboard/Karabiner latency, and do not establish the time of the final visual repaint. Workspace focus was checked after each switch. Workspace, window focus, native previous/current pair, and saved script history were restored afterward.

Validation: 11 history/IPC tests passed, including independent monitor history, external focus changes, special-workspace origin/return, occupied-workspace wraparound, failed-switch history preservation, and fragmented socket responses with connection reuse.

Raw data: [before](workspace-latency.json), [after](workspace-latency-optimized.json).
