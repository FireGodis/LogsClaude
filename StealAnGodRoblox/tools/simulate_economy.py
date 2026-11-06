#!/usr/bin/env python3
"""
simulate_economy.py — progression simulator for STEAL AN GOD.

Reads src/shared/Config/Balance.json (the same file the game uses) and plays simplified
agents second by second: steal eggs in the highest unlocked biome, carry them home at the real
carry speed, incubate, hatch (species/size/mutation rolled with the real weights), earn income,
collect, train on the treadmill and buy upgrades greedily.

Profiles: beginner / intermediate / advanced humans and an "average bot" (skill from the bot
personalities). Prints time-to-biome and income milestones (median of N runs) and can write a
markdown report:  python3 tools/simulate_economy.py --hours 6 --runs 15 --md docs/ECONOMY_SIMULATION.md
"""
import argparse
import json
import math
import os
import random
import statistics

HERE = os.path.dirname(os.path.abspath(__file__))
B = json.load(open(os.path.join(HERE, "..", "src", "shared", "Config", "Balance.json"), encoding="utf-8"))
HUB, BIOME_LEN = 340, 240
RAR = {r["name"]: r["mult"] for r in B["rarities"]}
RARITY_NAMES = [r["name"] for r in B["rarities"]]

PROFILES = {
    "beginner": {"skill": 0.55, "overhead": 1.7, "idle": 0.30, "train_bias": 0.5},
    "intermediate": {"skill": 0.78, "overhead": 1.25, "idle": 0.12, "train_bias": 0.5},
    "advanced": {"skill": 0.93, "overhead": 1.0, "idle": 0.04, "train_bias": 0.45},
    "bot_avg": {"skill": 0.72, "overhead": 1.35, "idle": 0.18, "train_bias": 0.5},
}


def walk(speed, carry=None):
    s = B["speed"]
    ws = min(s["baseWalkSpeed"] + s["walkLogFactor"] * math.log10(1 + speed), s["maxWalkSpeed"])
    if carry:
        ws *= 1 - s["carryPenaltyBySize"][carry]
    return ws


def unlocked(speed):
    u = 1
    for b in B["biomes"]:
        if speed >= b["speedRequired"]:
            u = b["id"]
    return u


def rarity_of(biome, slot):
    return RARITY_NAMES[min(9, max(1, int((biome - 1) * 0.6) + slot)) - 1]


def pick(weights, rng):
    r = rng.random() * sum(weights)
    for i, w in enumerate(weights):
        r -= w
        if r <= 0:
            return i
    return len(weights) - 1


def pet_income(biome, slot, size, mut):
    base = B["biomes"][biome - 1]["baseIncome"] * B["speciesIncomeMultiplier"][slot - 1]
    m = RAR[rarity_of(biome, slot)] * next(s["mult"] for s in B["sizes"] if s["name"] == size) * next(x["mult"] for x in B["mutations"] if x["name"] == mut)
    d = B["diminishingReturns"]
    if m > d["threshold"]:
        m = d["threshold"] + (m - d["threshold"]) ** d["exponent"]
    return base * m


def simulate(profile, hours, seed):
    p = PROFILES[profile]
    rng = random.Random(seed)
    st = {"gold": B["economy"]["startingGold"], "speed": 0.0, "tread": 1, "trail_mult": 1.0, "trail_i": 0, "base": 1}
    pets, eggs = [], []  # eggs: (hatch_t, biome, size, mut)
    t, end = 0.0, hours * 3600
    biome_time = {1: 0}
    income_at = {}
    marks = [900, 1800, 3600, 7200, 14400, 21600]

    def income():
        return sum(pets)

    def advance(dt):
        nonlocal t
        steps = int(dt)
        for _ in range(max(1, steps)):
            t += 1
            st["gold"] += income()
            # hatch
            for e in list(eggs):
                if e[0] <= t and len(pets) < B["baseLevels"][st["base"] - 1]["petSlots"]:
                    eggs.remove(e)
                    slot = pick(B["speciesHatchWeights"]["normal"], rng) + 1
                    pets.append(pet_income(e[1], slot, e[2], e[3]))
            for m in marks:
                if m not in income_at and t >= m:
                    income_at[m] = income()
            if t >= end:
                return

    while t < end:
        # buy greedily (cheapest useful upgrade)
        options = []
        if st["tread"] < len(B["treadmills"]):
            options.append(("tread", B["treadmills"][st["tread"]]["price"]))
        if st["trail_i"] < len(B["trails"]):
            options.append(("trail", B["trails"][st["trail_i"]]["price"]))
        if st["base"] < len(B["baseLevels"]):
            options.append(("base", B["baseLevels"][st["base"]]["price"]))
        options.sort(key=lambda o: o[1])
        bought = False
        for kind, price in options:
            if st["gold"] >= price:
                st["gold"] -= price
                if kind == "tread":
                    st["tread"] += 1
                elif kind == "trail":
                    st["trail_mult"] = B["trails"][st["trail_i"]]["mult"]
                    st["trail_i"] += 1
                else:
                    st["base"] += 1
                bought = True
                break
        if bought:
            advance(5)
            continue
        if rng.random() < p["idle"] * 0.1:
            advance(20)
            continue
        cap_inc = B["baseLevels"][st["base"] - 1]["incubators"]
        cap_pets = B["baseLevels"][st["base"] - 1]["petSlots"]
        can_steal = len(eggs) < cap_inc and len(pets) + len(eggs) < cap_pets
        biome = unlocked(st["speed"])
        want_train = biome < 12 and (not can_steal or rng.random() < p["train_bias"])
        if want_train:
            gain = B["treadmills"][st["tread"] - 1]["perStep"] * B["speed"]["stepsPerSecond"] * st["trail_mult"]
            for _ in range(60):
                st["speed"] += gain
                advance(1)
                nb = unlocked(st["speed"])
                if nb not in biome_time:
                    biome_time[nb] = t
            continue
        if not can_steal:
            # sell the worst pet to make room for progress
            if pets:
                worst = min(pets)
                pets.remove(worst)
                st["gold"] += worst * B["economy"]["sellSecondsOfIncome"]
            advance(10)
            continue
        # steal trip
        dist = HUB - 170 + (biome - 0.5) * BIOME_LEN
        size = B["sizes"][pick([s["weight"] for s in B["sizes"]], rng)]["name"]
        mut = B["mutations"][pick([m["weight"] for m in B["mutations"]], rng)]["name"]
        trip = (dist / walk(st["speed"]) + dist / walk(st["speed"], size) + 12) * p["overhead"]
        advance(trip)
        if rng.random() < p["skill"]:
            inc = B["biomes"][biome - 1]["incubation"] * next(s["incubationMult"] for s in B["sizes"] if s["name"] == size)
            eggs.append((t + inc, biome, size, mut))
    return biome_time, income_at


def fmt_t(s):
    if s is None:
        return "—"
    h, m = int(s // 3600), int(s % 3600 // 60)
    return f"{h}h{m:02d}" if h else f"{m}m{int(s % 60):02d}"


def fmt_n(n):
    for suf, v in (("T", 1e12), ("B", 1e9), ("M", 1e6), ("K", 1e3)):
        if n >= v:
            return f"{n / v:.2f}{suf}"
    return f"{n:.1f}"


def main():
    ap = argparse.ArgumentParser()
    ap.add_argument("--hours", type=float, default=6)
    ap.add_argument("--runs", type=int, default=15)
    ap.add_argument("--md", default=None)
    a = ap.parse_args()
    lines = [f"# Simulação de economia (mediana de {a.runs} execuções, {a.hours:g}h de jogo ativo)", "",
             "Gerado por `tools/simulate_economy.py` a partir de `src/shared/Config/Balance.json`.", "",
             "## Tempo até desbloquear cada bioma", "",
             "| Bioma | " + " | ".join(PROFILES) + " |", "|---|" + "---|" * len(PROFILES)]
    results = {k: [simulate(k, a.hours, 1000 + i) for i in range(a.runs)] for k in PROFILES}
    for b in B["biomes"]:
        row = [f"{b['id']}. {b['name']} ({fmt_n(b['speedRequired'])})"]
        for k in PROFILES:
            ts = [r[0].get(b["id"]) for r in results[k]]
            reached = [x for x in ts if x is not None]
            row.append(fmt_t(statistics.median(reached)) + ("" if len(reached) == len(ts) else f" ({len(reached)}/{len(ts)})") if reached else "—")
        lines.append("| " + " | ".join(row) + " |")
    lines += ["", "## Renda por segundo (mediana)", "", "| Tempo | " + " | ".join(PROFILES) + " |", "|---|" + "---|" * len(PROFILES)]
    for m in [900, 1800, 3600, 7200, 14400, 21600]:
        if m > a.hours * 3600:
            continue
        row = [fmt_t(m)]
        for k in PROFILES:
            row.append(fmt_n(statistics.median(r[1].get(m, 0) for r in results[k])) + "/s")
        lines.append("| " + " | ".join(row) + " |")
    text = "\n".join(lines) + "\n"
    print(text)
    if a.md:
        with open(a.md, "w", encoding="utf-8") as f:
            f.write(text)


if __name__ == "__main__":
    main()
