import collections
import re
import sys
from pathlib import Path

path = Path(sys.argv[1])
if not path.is_file():
    raise SystemExit(f"Log not found: {path}")

groups = collections.defaultdict(
    lambda: {"calls": 0, "bytes": 0, "memcpy": 0.0, "register": 0.0, "total": 0.0}
)
phases = collections.Counter()
matched = 0

for line in path.read_text(errors="replace").splitlines():
    if "[FSB_PERSIST_PROFILE]" not in line:
        continue

    d = dict(re.findall(r"(\w+)=([\d.]+)", line))
    required = {
        "seg", "partial", "new_bytes", "size_calc", "block_alloc",
        "pin", "allocate", "memcpy", "partial_create", "register", "total"
    }
    if not required.issubset(d):
        continue

    seg, partial = int(d["seg"]), int(d["partial"])
    row = groups[(seg, partial)]
    row["calls"] += 1
    row["bytes"] += int(d["new_bytes"])

    for name in (
        "size_calc", "block_alloc", "pin", "allocate",
        "memcpy", "partial_create", "register", "total"
    ):
        seconds = float(d[name])
        phases[name] += seconds
        if name in ("memcpy", "register", "total"):
            row[name] += seconds

    matched += 1

if not matched:
    raise SystemExit("No matching profiling records found.")

print(f"Log: {path}")
print(f"Records: {matched}\n")
print("seg  partial  calls  bytes_copied  memcpy_ms  register_ms  total_ms")

for (seg, partial), r in sorted(groups.items()):
    print(
        f"{seg:4} {partial:8} {r['calls']:6} "
        f"{r['bytes']:12} {r['memcpy']*1000:10.3f} "
        f"{r['register']*1000:12.3f} {r['total']*1000:9.3f}"
    )

print("\nAccumulated phase times:")
for name, seconds in phases.most_common():
    print(f"{name:15} {seconds*1000:10.3f} ms")
