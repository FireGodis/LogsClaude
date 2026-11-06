#!/usr/bin/env python3
"""
test_balance.py — executable invariant tests for the data-driven parts of STEAL AN GOD.
Mirrors the pure formulas in src/shared/Util/Formulas.luau and validates the config files.

Run: python3 tools/test_balance.py   (exit 1 on failure)
"""
import json
import math
import os
import re
import sys

ROOT = os.path.join(os.path.dirname(os.path.abspath(__file__)), "..", "src", "shared", "Config")
B = json.load(open(os.path.join(ROOT, "Balance.json"), encoding="utf-8"))
CREATURES_SRC = open(os.path.join(ROOT, "Creatures.luau"), encoding="utf-8").read()
MONET_SRC = open(os.path.join(ROOT, "Monetization.luau"), encoding="utf-8").read()

RARITIES = ["Common", "Uncommon", "Rare", "Epic", "Legendary", "Mythic", "Secret", "Eternal", "Divine"]
ABILITY_KINDS = {"SpeedBurst", "Dash", "Leap", "Reveal", "Shockwave", "Frost", "Decoy", "GuardShield", "EggShield",
                 "WeightRelief", "TrapWard", "Rescue", "HatchBoost", "IncomeBoost", "TrainBoost", "CatchReach"}

failures = []
passed = 0


def check(cond, msg):
    global passed
    if cond:
        passed += 1
    else:
        failures.append(msg)


# ---------- formulas (mirror of Formulas.luau) ----------
def bot_count(real):
    b = B["bots"]
    return min(b["maxBots"], max(0, b["targetPopulation"] - real))


def walk_speed(speed, carry=None):
    s = B["speed"]
    ws = min(s["baseWalkSpeed"] + s["walkLogFactor"] * math.log10(1 + max(0, speed)), s["maxWalkSpeed"])
    if carry:
        ws *= 1 - s["carryPenaltyBySize"][carry]
    return ws


def unlocked_biome(speed):
    u = 1
    for b in B["biomes"]:
        if speed >= b["speedRequired"]:
            u = b["id"]
    return u


def dr(mult):
    d = B["diminishingReturns"]
    return d["threshold"] + (mult - d["threshold"]) ** d["exponent"] if mult > d["threshold"] else mult


# 1. bot population table from the spec
for real, bots in [(1, 5), (2, 4), (3, 3), (4, 2), (5, 1), (6, 0), (7, 0), (0, 5)]:
    check(bot_count(real) == bots, f"bot_count({real}) should be {bots}, got {bot_count(real)}")

# 2. biome progression strictly increasing and matches the spec curve
spec = [0, 150, 1200, 9000, 65000, 450000, 3e6, 20e6, 140e6, 1e9, 7e9, 50e9]
check([b["speedRequired"] for b in B["biomes"]] == spec, "biome speed requirements differ from the spec table")
check(len(B["biomes"]) == 12, "there must be 12 biomes")
for a, b in zip(B["biomes"], B["biomes"][1:]):
    check(b["baseIncome"] > a["baseIncome"], f"income must grow {a['key']} -> {b['key']}")
    check(b["incubation"] >= a["incubation"], f"incubation should not shrink {a['key']} -> {b['key']}")
    check(b["guardianSpeed"] > a["guardianSpeed"], f"guardians must get faster {a['key']} -> {b['key']}")
check(unlocked_biome(149) == 1 and unlocked_biome(150) == 2 and unlocked_biome(5e10) == 12, "unlocked_biome thresholds")

# 3. incubation ranges per rarity tier of the spec (common 12-30s ... divine 10-20min)
check(12 <= B["biomes"][0]["incubation"] <= 30, "biome 1 incubation must be 12-30s")
check(600 <= B["biomes"][11]["incubation"] <= 1200, "biome 12 incubation must be 10-20 min")

# 4. shop tables monotonic
for key, field in (("treadmills", "perStep"), ("treadmills", "price"), ("trails", "mult"), ("trails", "price"), ("baseLevels", "price"), ("baseLevels", "incubators"), ("baseLevels", "petSlots")):
    vals = [x[field] for x in B[key]]
    check(all(b > a for a, b in zip(vals, vals[1:])), f"{key}.{field} must be strictly increasing: {vals}")
check(len(B["treadmills"]) == 10, "10 treadmills")
check(len(B["trails"]) == 11, "11 purchasable trails")
check(B["baseLevels"][0]["incubators"] == 4 and B["baseLevels"][-1]["incubators"] >= 20, "incubators 4 -> 20+")

# 5. sizes / mutations / rarities
check([s["name"] for s in B["sizes"]] == ["Small", "Normal", "Large", "Huge", "Titan"], "size names")
check([r["name"] for r in B["rarities"]] == RARITIES, "rarity names")
check(abs(sum(m["weight"] for m in B["mutations"]) - 100) < 1e-6, "mutation weights should sum to 100")
mutnames = [m["name"] for m in B["mutations"]]
for m in ["Golden", "Silver", "Shadow", "Celestial", "Radiant", "Cosmic", "Void", "Rainbow"]:
    check(m in mutnames, f"missing mutation {m}")
max_mult = B["rarities"][-1]["mult"] * B["sizes"][-1]["mult"] * B["mutations"][-1]["mult"]
check(dr(max_mult) < max_mult and dr(max_mult) < 40, f"diminishing returns must tame the max stack ({max_mult} -> {dr(max_mult):.1f})")
check(dr(5) == 5, "no diminishing below threshold")
for k, p in B["speed"]["carryPenaltyBySize"].items():
    check(0 < p < 0.5, f"carry penalty {k} out of range")
check(walk_speed(5e10) <= B["speed"]["maxWalkSpeed"], "walk speed cap")
check(walk_speed(1000, "Titan") < walk_speed(1000, "Small"), "bigger eggs must be slower to carry")

# 6. creatures catalog
ids = re.findall(r'\{ id = "(\w+)", name = "([^"]+)", biome = (\d+), slot = (\d)', CREATURES_SRC)
check(len(ids) == 52, f"expected 48 biome + 4 event creatures, found {len(ids)}")
check(len({i[0] for i in ids}) == len(ids), "creature ids must be unique")
per_biome = {}
for cid, _, biome, slot in ids:
    per_biome.setdefault(int(biome), set()).add(int(slot))
for b in range(1, 13):
    check(per_biome.get(b) == {1, 2, 3, 4}, f"biome {b} must have slots 1-4")
check(len(per_biome.get(0, set())) >= 1 and CREATURES_SRC.count('event = "') == 4, "4 event creatures")
kinds = re.findall(r'kind = "(\w+)", cd = (\d+)', CREATURES_SRC)
check(len(kinds) == 52, f"every creature needs an ability (found {len(kinds)})")
for kind, cd in kinds:
    check(kind in ABILITY_KINDS, f"unknown ability kind {kind}")
    check(int(cd) >= 25, f"ability cooldown too low ({kind} {cd}s)")
ab_names = re.findall(r'ab = \{ name = "([^"]+)"', CREATURES_SRC)
check(len(set(ab_names)) == len(ab_names), "ability names must be unique per creature")
for god in ["Hermes", "Athena", "Ares", "Poseidon", "Artemis", "Apollo", "Hades", "Zeus", "Thor", "Loki", "Odin", "Freyja",
            "Heimdall", "Fenrir", "Jormungandr", "Skadi", "Ra", "Anubis", "Horus", "Isis", "Osiris", "Thoth", "Sobek", "Sekhmet", "Bastet"]:
    check(f'id = "{god}"' in CREATURES_SRC, f"required god missing: {god}")
# no ability may teleport forward / steal remotely: only Rescue moves you, and only back to base
check("Teleport" not in " ".join(k for k, _ in kinds), "no teleport abilities")

# 7. monetization: odds sum to 100, ids default to 0 (never invented)
odds = [float(x) for x in re.findall(r"chance = ([\d.]+)", MONET_SRC)]
check(abs(sum(odds) - 100) < 1e-9, f"reliquary odds must sum to 100 (got {sum(odds)})")
ids_set = re.findall(r"\bid = (\d+)", MONET_SRC)
check(all(i == "0" for i in ids_set), "monetization ids must stay 0 until filled from the Creator Dashboard")
for gp in ["VIP", "DoubleMoney", "DoubleGrowth", "AutoCollect", "ExtraBase", "DoubleTraining"]:
    check(f"{gp} = {{" in MONET_SRC, f"gamepass {gp} missing")
for dp in ["GoldSmall", "MoneyBoost", "HatchInstant", "SpeedBoost", "BaseShield", "EventBoost", "DivineReliquary"]:
    check(f"{dp} " in MONET_SRC or f"{dp}=" in MONET_SRC, f"product {dp} missing")

# 8. economy rules from the spec
e = B["economy"]
check(e["offlineRate"] == 0.5 and e["offlineCapSeconds"] == 8 * 3600, "offline earnings 50% capped at 8h")
check(B["specialEgg"]["intervalSeconds"] == 300, "special egg every 5 minutes")
check(B["traps"]["maxActive"] == 3 and 3 <= B["traps"]["stunSeconds"] <= 5, "traps: max 3, ~4s")
check(B["globalModifierCap"] <= 8, "global income modifier cap")

print(f"{passed} checks passed, {len(failures)} failed")
for f in failures:
    print("FAIL:", f)
sys.exit(1 if failures else 0)
