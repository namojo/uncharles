#!/usr/bin/env python3
"""Converts the canon dialogue (design/narrative/dialogue/*.md) into game data.

Godot has no YAML parser, so this extracts every fenced ```yaml block that
holds a dialogue scene (a mapping with `scene:` and `nodes:`), validates all
of them together, and writes JSON under assets/data/dialogue/:

  <markdown file stem>.json   {"source": ..., "scenes": [{"id", "backdrop", "nodes"}]}
  index.json                  {"files": [<json file names>]}  (the order the game loads them)

Yaml blocks that are plain lists (enemy data, command proposals) are not
dialogue and are skipped. Scene metadata other than `scene`, `backdrop` and
`nodes` (trigger, lit, ...) is dropped.

Usage (from the repo root):  python -I tools/dialogue/build_dialogue.py
Exit code 0 = written, 1 = validation problems (nothing is written).

Node format: design/narrative/dialogue/job1-narae.md section 0.
Allowed names (affinity steps, candidates, counters, thresholds, placeholders)
come from assets/data/dialogue/affinity_values.json; end values, actions and
flow come from assets/data/dialogue/flow.json. Implements Story 002
(production/epics/uncharles/story-002-dialogue-affinity.md).
"""

import json
import re
import sys
from pathlib import Path

import yaml

ROOT = Path(__file__).resolve().parents[2]
SOURCE_DIR = ROOT / "design" / "narrative" / "dialogue"
OUT_DIR = ROOT / "assets" / "data" / "dialogue"
ENEMY_DIR = ROOT / "assets" / "data" / "battle" / "enemies"

MAX_TEXT = 120
MIN_CHOICES, MAX_CHOICES = 2, 4
# Exactly one of these decides where a node goes next.
FLOW_KEYS = ("next", "choices", "battle", "condition", "end")
BATTLE_KEYS = ("on_persuaded", "on_defeated", "on_depleted")
MINUS = "−"
CONDITION_TOKEN = re.compile(r"\s*(>=|<=|==|!=|>|<|\(|\)|\d+|[A-Za-z_][A-Za-z0-9_.]*)")
PLACEHOLDER = re.compile(r"\{([^{}]*)\}")


def extract_blocks(text: str) -> list[str]:
    blocks, current = [], None
    for line in text.splitlines():
        stripped = line.strip()
        if current is None:
            if stripped.startswith("```yaml"):
                current = []
        elif stripped.startswith("```"):
            blocks.append("\n".join(current))
            current = None
        else:
            current.append(line)
    return blocks


def load_scenes(problems: list[str]) -> dict[str, list[dict]]:
    """File stem -> scene dicts, in file order."""
    files: dict[str, list[dict]] = {}
    for md in sorted(SOURCE_DIR.glob("*.md")):
        scenes = []
        for number, block in enumerate(extract_blocks(md.read_text(encoding="utf-8")), 1):
            try:
                data = yaml.safe_load(block)
            except yaml.YAMLError as error:
                problems.append(f"{md.name}: yaml block {number} does not parse: {error}")
                continue
            if not isinstance(data, dict):
                continue  # enemy / command lists
            if "scene" not in data or not isinstance(data.get("nodes"), list):
                problems.append(f"{md.name}: yaml block {number} is a mapping without `scene` and `nodes`")
                continue
            scenes.append(data)
        files[md.stem] = scenes
    return files


def check_condition(expr: str, where: str, names: dict, problems: list[str]) -> None:
    position, tokens = 0, []
    while position < len(expr):
        match = CONDITION_TOKEN.match(expr, position)
        if match is None:
            if expr[position:].strip():
                problems.append(f"{where}: condition '{expr}' has an unreadable part near '{expr[position:]}'")
            break
        tokens.append(match.group(1))
        position = match.end()
    for token in tokens:
        if not re.match(r"[A-Za-z_]", token) or token in ("and", "or", "not"):
            continue
        if token.startswith("affinity."):
            if token[len("affinity."):] not in names["candidates"]:
                problems.append(f"{where}: condition '{expr}' names unknown candidate '{token}'")
        elif token.startswith("flag."):
            if token[len("flag."):] not in names["flags"]:
                problems.append(f"{where}: condition '{expr}' reads flag '{token}' that no node sets")
        elif token not in names["counters"] and token not in names["thresholds"]:
            problems.append(f"{where}: condition '{expr}' names unknown value '{token}'")


def check_affinity(value, where: str, names: dict, problems: list[str]) -> dict:
    if not isinstance(value, dict):
        problems.append(f"{where}: affinity must be a mapping candidate -> step")
        return {}
    fixed = {}
    for candidate, step in value.items():
        step = str(step).replace("-", MINUS)
        fixed[candidate] = step
        if candidate not in names["candidates"]:
            problems.append(f"{where}: affinity for unknown candidate '{candidate}'")
        if step not in names["steps"]:
            problems.append(f"{where}: affinity step '{step}' is not one of {sorted(names['steps'])}")
    return fixed


def check_text(text, where: str, names: dict, problems: list[str]) -> None:
    if not isinstance(text, str) or not text:
        problems.append(f"{where}: missing text")
        return
    if len(text) > MAX_TEXT:
        problems.append(f"{where}: text is {len(text)} chars (limit {MAX_TEXT})")
    for name in PLACEHOLDER.findall(text):
        if name not in names["placeholders"]:
            problems.append(f"{where}: unknown placeholder {{{name}}}")


def validate(files: dict[str, list[dict]], values: dict, flow: dict, problems: list[str]) -> None:
    node_ids: dict[str, str] = {}
    scene_ids: dict[str, str] = {}
    for stem, scenes in files.items():
        for scene in scenes:
            scene_id = str(scene["scene"])
            if scene_id in scene_ids:
                problems.append(f"{stem}: scene id '{scene_id}' already used in {scene_ids[scene_id]}")
            scene_ids[scene_id] = stem
            for node in scene["nodes"]:
                node_id = node.get("id")
                if node_id in node_ids:
                    problems.append(f"{stem}: node id '{node_id}' already used in {node_ids[node_id]}")
                node_ids[node_id] = stem
    for clash in sorted(set(node_ids) & set(scene_ids)):
        problems.append(f"'{clash}' is both a scene id and a node id")

    flags = {
        str(item["set_flag"])
        for scenes in files.values() for scene in scenes for node in scene["nodes"]
        for item in [node, *node.get("choices", [])] if "set_flag" in item
    }
    names = {
        "candidates": set(values["candidates"]),
        "steps": set(values["steps"]),
        "counters": set(values["counter_defaults"]),
        "thresholds": set(values["thresholds"]),
        "placeholders": set(values["placeholders"]),
        "flags": flags,
    }
    end_routes = set(flow.get("end_routes", {}))
    targeted: set[str] = set()

    def check_target(target, where: str) -> None:
        if target not in node_ids and target not in scene_ids:
            problems.append(f"{where}: target '{target}' is neither a node id nor a scene id")
        targeted.add(str(target))

    for stem, scenes in files.items():
        for scene in scenes:
            family = str(scene["scene"]).split("_")[0] + "_"
            for node in scene["nodes"]:
                node_id = node.get("id")
                where = f"{stem}:{node_id}"
                if not isinstance(node_id, str) or not node_id.startswith(family):
                    problems.append(f"{where}: node id must start with '{family}' (scene '{scene['scene']}')")
                used = [key for key in FLOW_KEYS if key in node]
                if len(used) != 1:
                    problems.append(f"{where}: needs exactly one of {FLOW_KEYS}, has {used}")
                    continue
                kind = used[0]
                if kind == "condition":
                    check_condition(node["condition"], where, names, problems)
                    for key in ("then", "else"):
                        check_target(node.get(key), f"{where}.{key}")
                    if "text" in node or "speaker" in node:
                        problems.append(f"{where}: a condition node does not speak")
                    continue
                if not node.get("speaker"):
                    problems.append(f"{where}: missing speaker")
                check_text(node.get("text"), where, names, problems)
                if "affinity" in node:
                    node["affinity"] = check_affinity(node["affinity"], where, names, problems)
                if "cut" in node and node["cut"] not in flow.get("backdrops", {}):
                    problems.append(f"{where}: cut '{node['cut']}' is not a flow.json backdrops id")
                if "action" in node and node["action"] not in flow.get("actions", []):
                    problems.append(f"{where}: unknown action '{node['action']}'")
                if kind == "next":
                    check_target(node["next"], f"{where}.next")
                elif kind == "end":
                    if node["end"] not in end_routes and node["end"] not in scene_ids:
                        problems.append(f"{where}: end '{node['end']}' is not in flow.json end_routes or a scene id")
                elif kind == "battle":
                    if not (ENEMY_DIR / f"{node['battle']}.tres").exists():
                        problems.append(f"{where}: no enemy data assets/data/battle/enemies/{node['battle']}.tres")
                    for key in BATTLE_KEYS:
                        check_target(node.get(key), f"{where}.{key}")
                elif kind == "choices":
                    choices = node["choices"]
                    if not isinstance(choices, list) or not MIN_CHOICES <= len(choices) <= MAX_CHOICES:
                        problems.append(f"{where}: needs {MIN_CHOICES}-{MAX_CHOICES} choices")
                        continue
                    if all("condition" in choice for choice in choices):
                        problems.append(f"{where}: at least one choice must have no condition")
                    for index, choice in enumerate(choices):
                        choice_where = f"{where}.choices[{index}]"
                        check_text(choice.get("text"), choice_where, names, problems)
                        check_target(choice.get("next"), f"{choice_where}.next")
                        if "affinity" in choice:
                            choice["affinity"] = check_affinity(choice["affinity"], choice_where, names, problems)
                        if "condition" in choice:
                            check_condition(choice["condition"], choice_where, names, problems)

    check_flow(flow, scene_ids, problems)
    if flow.get("entry") not in node_ids and flow.get("entry") not in scene_ids:
        problems.append(f"flow.json: entry '{flow.get('entry')}' is not a node id or scene id")

    first_nodes = {scene["nodes"][0]["id"] for scenes in files.values() for scene in scenes if scene["nodes"]}
    loose = sorted(set(node_ids) - targeted - first_nodes)
    if loose:
        print(f"note: nodes nothing points to (fine if the game code reaches them): {', '.join(loose)}")


def check_flow(flow: dict, scene_ids: dict, problems: list[str]) -> None:
    maps = flow.get("maps", {})
    for end_value, route in flow.get("end_routes", {}).items():
        if "scene" in route and route["scene"] not in scene_ids:
            problems.append(f"flow.json: end_routes['{end_value}'] scene '{route['scene']}' does not exist")
        if "map" in route and route["map"] not in maps:
            problems.append(f"flow.json: end_routes['{end_value}'] map '{route['map']}' does not exist")
    for map_id, menu in maps.items():
        for item in menu.get("items", []):
            if "scene" in item and item["scene"] not in scene_ids:
                problems.append(f"flow.json: map '{map_id}' item '{item.get('label')}' scene '{item['scene']}' does not exist")
    for job in flow.get("jobs", []):
        for key in ("board_scene", "return_scene"):
            if job.get(key) not in scene_ids:
                problems.append(f"flow.json: job '{job.get('id')}' {key} '{job.get(key)}' is not a scene id")
    if flow.get("reboot_scene") not in scene_ids:
        problems.append(f"flow.json: reboot_scene '{flow.get('reboot_scene')}' is not a scene id")
    for pattern, path in flow.get("backdrops", {}).items():
        if not (ROOT / path.removeprefix("res://")).exists():
            problems.append(f"flow.json: backdrop '{pattern}' texture {path} does not exist")


def main() -> int:
    problems: list[str] = []
    values = json.loads((OUT_DIR / "affinity_values.json").read_text(encoding="utf-8"))
    flow = json.loads((OUT_DIR / "flow.json").read_text(encoding="utf-8"))
    files = load_scenes(problems)
    if not files:
        problems.append(f"no markdown files in {SOURCE_DIR}")
    validate(files, values, flow, problems)
    if problems:
        print(f"{len(problems)} problem(s), nothing written:")
        for problem in problems:
            print(f"  - {problem}")
        return 1

    OUT_DIR.mkdir(parents=True, exist_ok=True)
    names = []
    for stem, scenes in files.items():
        out = {
            "source": f"design/narrative/dialogue/{stem}.md",
            "scenes": [
                {"id": str(s["scene"]), **({"backdrop": str(s["backdrop"])} if "backdrop" in s else {}), "nodes": s["nodes"]}
                for s in scenes
            ],
        }
        (OUT_DIR / f"{stem}.json").write_text(json.dumps(out, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
        names.append(f"{stem}.json")
        print(f"wrote {stem}.json: {len(scenes)} scenes, {sum(len(s['nodes']) for s in scenes)} nodes")
    (OUT_DIR / "index.json").write_text(json.dumps({"files": names}, ensure_ascii=False, indent=1) + "\n", encoding="utf-8", newline="\n")
    return 0


if __name__ == "__main__":
    sys.exit(main())
