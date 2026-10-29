import csv
import statistics
import sys

with open(sys.argv[1], newline="") as f:
    rows = list(csv.DictReader(f, delimiter="\t"))

default = {}
four_gb = {}

for row in rows:
    pair = int(row["pair"])
    elapsed = float(row["elapsed_sec"])

    if row["config"] == "default":
        default[pair] = elapsed
    elif row["config"] == "4gb":
        four_gb[pair] = elapsed

if len(default) != 5 or len(four_gb) != 5:
    raise SystemExit(
        f"Expected 5 runs per configuration; got "
        f"{len(default)} default and {len(four_gb)} 4GB runs."
    )

if set(default) != set(four_gb) or set(default) != set(range(1, 6)):
    raise SystemExit("The paired results are incomplete.")

wins = 0

print("Pair   Default (s)   4 GB (s)   Improvement")

for pair in range(1, 6):
    a, b = default[pair], four_gb[pair]
    improvement = (a - b) / a * 100 if a else 0

    if b < a:
        wins += 1

    print(f"{pair:>4}   {a:>11.3f}   {b:>8.3f}   {improvement:>9.2f}%")

median_default = statistics.median(default.values())
median_4gb = statistics.median(four_gb.values())
reduction = (
    (median_default - median_4gb) / median_default * 100
    if median_default else 0
)

print(f"\nDefault median: {median_default:.3f} s")
print(f"4 GB median:    {median_4gb:.3f} s")
print(f"Median reduction: {reduction:.2f}%")
print(f"Pairs favouring 4 GB: {wins}/5")
