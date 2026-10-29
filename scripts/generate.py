cat > bench24848/generate.py <<'PY'
from pathlib import Path

out = Path(__file__).parent

configs = {
    "default": {
        "threshold": None,
        "unique_index": True,
    },
    "no_checkpoint": {
        "threshold": "4GB",
        "unique_index": True,
    },
    "no_index": {
        "threshold": None,
        "unique_index": False,
    },
}

for name, config in configs.items():
    lines = []

    # In this configuration, make the checkpoint threshold
    # the first SQL statement.
    if config["threshold"]:
        lines.append(
            f"SET checkpoint_threshold = '{config['threshold']}';"
        )

    lines.extend([
        ".timer on",
        "CREATE SEQUENCE seq;",
        """
CREATE TABLE target(
    id BIGINT DEFAULT nextval('seq'),
    ext UUID,
    qty INT,
    payload VARCHAR
);
""".strip(),
    ])

    if config["unique_index"]:
        lines.append(
            "CREATE UNIQUE INDEX ux_target_ext ON target(ext);"
        )

    lines.extend([
        """
CREATE TABLE source AS
SELECT
    uuid() AS ext,
    CAST(i % 1000 AS INT) AS qty,
    'p-' || i AS payload,
    CAST(i // 100000 AS INT) AS b
FROM range(3000000) t(i);
""".strip(),
    ])

    for batch in range(30):
        lines.append(
            "INSERT INTO target(ext, qty, payload) "
            "SELECT ext, qty, payload "
            f"FROM source WHERE b = {batch};"
        )

    path = out / f"{name}.sql"
    path.write_text("\n\n".join(lines) + "\n")
    print(f"Generated {path}")
PY