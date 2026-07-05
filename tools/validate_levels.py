#!/usr/bin/env python3
"""Validate all Echo Labyrinth levels — run: python tools/validate_levels.py"""
import json
import os
from collections import deque

BASE = os.path.join(os.path.dirname(__file__), "..", "assets", "levels")


def parse(grid):
    w, h = len(grid[0]), len(grid)
    walls, boxes, goals = set(), set(), set()
    start = goal = key_pos = door_pos = None
    for y, row in enumerate(grid):
        for x, c in enumerate(row):
            if c == "#":
                walls.add((x, y))
            elif c == "@":
                start = (x, y)
            elif c == "G":
                goals.add((x, y))
                goal = (x, y)
            elif c == "B":
                boxes.add((x, y))
            elif c == "K":
                key_pos = (x, y)
            elif c == "D":
                door_pos = (x, y)
    return w, h, walls, start, goal, goals, boxes, key_pos, door_pos


def blocked(walls, door_pos, has_key, pos):
    if pos in walls:
        return True
    if door_pos and pos == door_pos and not has_key:
        return True
    return False


def key_door_solvable(w, h, walls, start, goal, key_pos, door_pos, max_moves):
    """BFS: collect key if present, then reach goal."""
    q = deque([(start[0], start[1], False, 0)])
    vis = {(start[0], start[1], False)}
    while q:
        px, py, has_key, m = q.popleft()
        if (px, py) == goal and (key_pos is None or has_key) and m <= max_moves:
            return m
        if m >= max_moves:
            continue
        if key_pos and (px, py) == key_pos:
            has_key = True
        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            nx, ny = px + dx, py + dy
            if not (0 <= nx < w and 0 <= ny < h):
                continue
            if blocked(walls, door_pos, has_key, (nx, ny)):
                continue
            hk = has_key or (key_pos and (nx, ny) == key_pos)
            k = (nx, ny, hk)
            if k not in vis:
                vis.add(k)
                q.append((nx, ny, hk, m + 1))
    return None


def bfs_path(walls, w, h, start, goal, limit=200):
    q = deque([(start, 0)])
    vis = {start}
    while q:
        p, m = q.popleft()
        if p == goal:
            return m
        if m >= limit:
            continue
        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            n = (p[0] + dx, p[1] + dy)
            if 0 <= n[0] < w and 0 <= n[1] < h and n not in walls and n not in vis:
                vis.add(n)
                q.append((n, m + 1))
    return None


def sokoban_solvable(grid, max_moves):
    """BFS with all box positions."""
    w, h, walls, start, _, goals, init_boxes, _, _ = parse(grid)
    if not init_boxes or not goals or len(init_boxes) != len(goals):
        return None
    boxes = tuple(sorted(init_boxes))

    def key(px, py, bx):
        return (px, py, bx)

    q = deque([(start[0], start[1], boxes, 0)])
    vis = {key(start[0], start[1], boxes)}
    while q:
        px, py, bx, m = q.popleft()
        box_set = set(bx)
        if box_set == goals and m <= max_moves:
            return m
        if m >= max_moves:
            continue
        for dx, dy in ((0, 1), (0, -1), (1, 0), (-1, 0)):
            nx, ny = px + dx, py + dy
            if not (0 <= nx < w and 0 <= ny < h) or (nx, ny) in walls:
                continue
            nboxes = list(bx)
            if (nx, ny) in box_set:
                bi = nboxes.index((nx, ny))
                bx2, by2 = nx + dx, ny + dy
                if (bx2, by2) in walls or (bx2, by2) in box_set:
                    continue
                nboxes[bi] = (bx2, by2)
            nboxes = tuple(sorted(nboxes))
            k = key(nx, ny, nboxes)
            if k not in vis:
                vis.add(k)
                q.append((nx, ny, nboxes, m + 1))
    return None


def main():
    seen = set()
    failed = []
    passed = 0
    for root, _, files in os.walk(BASE):
        for f in sorted(files):
            if not f.endswith(".json"):
                continue
            path = os.path.normpath(os.path.join(root, f))
            if path in seen:
                continue
            seen.add(path)
            rel = os.path.relpath(path, BASE)
            data = json.load(open(path, encoding="utf-8"))
            grid = data["grid"]
            maxm = data["maxMoves"]
            mechanics = data.get("mechanics", [])
            w, h, walls, start, goal, goals, boxes, key_pos, door_pos = parse(grid)

            if not start or not goal:
                failed.append((rel, "missing @ or G"))
                continue

            if boxes:
                need = sokoban_solvable(grid, maxm + 5)
                kind = "sokoban"
            elif "key_door" in mechanics or key_pos or door_pos:
                need = key_door_solvable(w, h, walls, start, goal, key_pos, door_pos, maxm + 5)
                kind = "key_door"
            else:
                need = bfs_path(walls, w, h, start, goal)
                kind = "path"

            if need is None:
                failed.append((rel, f"{kind} impossible"))
            elif need > maxm:
                failed.append((rel, f"{kind} needs {need} moves, max {maxm}"))
            else:
                passed += 1
                print(f"  OK   {rel}: {kind} in {need}/{maxm} moves")

    print(f"Passed: {passed}, Failed: {len(failed)}")
    for rel, msg in failed:
        print(f"  FAIL {rel}: {msg}")
    return 1 if failed else 0


if __name__ == "__main__":
    raise SystemExit(main())
