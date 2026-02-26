#!/usr/bin/env python3
"""
Update the root README.md charts table from Chart.yaml metadata.

Replaces the content between:
  <!-- BEGIN_CHARTS_TABLE -->
  <!-- END_CHARTS_TABLE -->

Run this after helm-docs to keep the root README summary table in sync.
"""

import os
import re
import sys

try:
    import yaml
except ImportError:
    print("PyYAML not found — installing...")
    os.system("pip install pyyaml -q")
    import yaml

CHARTS_DIR = "charts"
README_PATH = "README.md"
BEGIN_MARKER = "<!-- BEGIN_CHARTS_TABLE -->"
END_MARKER = "<!-- END_CHARTS_TABLE -->"


def load_charts():
    charts = []
    if not os.path.isdir(CHARTS_DIR):
        print(f"Charts directory '{CHARTS_DIR}' not found", file=sys.stderr)
        sys.exit(1)

    for chart_name in sorted(os.listdir(CHARTS_DIR)):
        chart_yaml_path = os.path.join(CHARTS_DIR, chart_name, "Chart.yaml")
        if not os.path.isfile(chart_yaml_path):
            continue
        with open(chart_yaml_path) as f:
            data = yaml.safe_load(f)
        charts.append({
            "name": data["name"],
            "version": data["version"],
            "appVersion": str(data.get("appVersion", "")),
            "description": data.get("description", ""),
        })
    return charts


def build_table(charts):
    rows = [
        "| Chart | Version | App Version | Description |",
        "|-------|---------|-------------|-------------|",
    ]
    for c in charts:
        rows.append(
            f"| [{c['name']}]({CHARTS_DIR}/{c['name']}/) "
            f"| {c['version']} "
            f"| {c['appVersion']} "
            f"| {c['description']} |"
        )
    return "\n".join(rows)


def update_readme(table):
    if not os.path.isfile(README_PATH):
        print(f"README not found at '{README_PATH}'", file=sys.stderr)
        sys.exit(1)

    with open(README_PATH, "r") as f:
        content = f.read()

    pattern = re.compile(
        rf"({re.escape(BEGIN_MARKER)}).*?({re.escape(END_MARKER)})",
        re.DOTALL,
    )

    if not pattern.search(content):
        print(
            f"Markers not found in {README_PATH}. "
            f"Add '{BEGIN_MARKER}' and '{END_MARKER}' to enable auto-update.",
            file=sys.stderr,
        )
        sys.exit(1)

    new_content = pattern.sub(
        rf"\1\n{table}\n\2",
        content,
    )

    if new_content == content:
        print("Root README is already up to date.")
        return

    with open(README_PATH, "w") as f:
        f.write(new_content)
    print("Root README updated successfully.")


if __name__ == "__main__":
    charts = load_charts()
    table = build_table(charts)
    update_readme(table)
