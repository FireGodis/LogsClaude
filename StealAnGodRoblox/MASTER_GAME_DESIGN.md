# STEAL A GOD
# MASTER GAME DESIGN DOCUMENT & CODEX DEVELOPMENT SPECIFICATION

**Project:** Steal a God  
**Platform:** Roblox  
**Engine:** Roblox Engine  
**Language:** Luau  
**3D Production:** Blender + ForgeGUI  
**Development Assistant:** OpenAI Codex  
**Genre:** Multiplayer Simulator / Collection / Stealing / Tycoon / Progression  
**Monetization:** Gamepasses, Developer Products, Premium Bundles, Cosmetics and Seasonal Content.

---

# 1. YOUR ROLE

You are the lead game developer, gameplay programmer, systems architect and technical director of STEAL A GOD.

Your responsibility is to develop a complete, commercially viable, polished Roblox experience.

You must work as an experienced game development team would:

- Inspect the existing project before modifying it.
- Design maintainable systems.
- Develop modular Luau code.
- Create complete gameplay loops.
- Build multiplayer systems.
- Integrate external 3D assets.
- Optimize performance.
- Implement monetization.
- Test every important feature.
- Maintain technical documentation.

Do not create a superficial prototype and claim the project is finished.

The objective is a real, publishable Roblox game.

IMPORTANT:

Do not try to implement everything in a single operation. Work in controlled development milestones, preserving existing functionality and validating each system before moving forward.

---

# 2. GAME CONCEPT

STEAL A GOD is a multiplayer experience inspired by the Steal a Brainrot / Steal a Pet genre.

The central concept is that players collect divine eggs containing gods from ancient mythologies.

The initial civilizations are:

1. Greek Mythology.
2. Norse Mythology.
3. Egyptian Mythology.

Each egg contains a specific god.

After hatching, gods can be placed inside a player's personal base, where they generate resources and provide special abilities.

Players can:

- Purchase eggs.
- Hatch divine eggs.
- Collect gods.
- Upgrade gods.
- Earn coins.
- Steal eggs and gods.
- Invade other bases.
- Defend their territory.
- Unlock new civilizations.
- Complete quests.
- Participate in world events.
- Perform rebirths.
- Purchase permanent and consumable upgrades.

An essential feature is an intelligent AI rival population that makes the experience feel active even when very few human players are connected.

The game must remain enjoyable for players playing alone.

---

# 3. CORE DESIGN PRINCIPLES

The project must prioritize five pillars:

### 3.1 Immediate engagement

The player should understand the main objective within 30 seconds.

### 3.2 Continuous progression

There must always be a meaningful objective:

- Get a better egg.
- Hatch a rare god.
- Improve production.
- Build a stronger base.
- Steal a valuable egg.
- Unlock a civilization.
- Discover missing gods.

### 3.3 Multiplayer competition

Stealing, defending, collecting and interacting with rivals must provide meaningful gameplay.

### 3.4 Dynamic world population

AI-controlled NPC rivals must create activity in low-population servers.

Their population should automatically decrease as real players enter.

### 3.5 Sustainable monetization

The game must have multiple monetization opportunities without making the free gameplay completely unenjoyable.

Do not implement fake scarcity, fake players, deceptive purchase interfaces or artificial urgency.

---

# 4. WORLD STRUCTURE

Create a central world containing three initial mythological civilizations.

## 4.1 Olympus

Greek mythology.

Visual elements:

- White marble.
- Golden columns.
- Blue skies.
- Lightning.
- Ancient architecture.
- Floating islands.

## 4.2 Asgard

Norse mythology.

Visual elements:

- Nordic architecture.
- Ice.
- Snow.
- Blue and silver materials.
- Runes.
- Yggdrasil-inspired structures.

## 4.3 Egyptian Kingdom

Egyptian mythology.

Visual elements:

- Pyramids.
- Golden temples.
- Sand.
- Black and gold architecture.
- Turquoise decorations.
- Hieroglyphic patterns.

## 4.4 Central Hub

The hub connects the civilizations and contains:

- Egg shop.
- Premium shop.
- Rebirth area.
- Quests.
- Daily rewards.
- Event portals.
- Collection museum.
- Leaderboards.
- NPC guides.

The map should be compact enough to allow fast movement.

Do not make the initial world excessively large.

---

# 5. GOD COLLECTION SYSTEM

Create a configurable god database.

Every god must have:

- Unique identifier.
- Display name.
- Civilization.
- Rarity.
- Model reference.
- Icon reference.
- Base income.
- Upgrade multiplier.
- Ability.
- Ability cooldown.
- Description.
- Animation references.
- Sound references.
- Visual effects.
- Collection category.

## 5.1 Initial Greek gods

- Zeus.
- Poseidon.
- Hades.
- Athena.
- Ares.
- Apollo.
- Artemis.
- Hermes.

## 5.2 Initial Norse gods

- Odin.
- Thor.
- Loki.
- Freya.
- Tyr.
- Heimdall.
- Baldr.
- Hel.

## 5.3 Initial Egyptian gods

- Ra.
- Anubis.
- Isis.
- Osiris.
- Horus.
- Seth.
- Bastet.
- Thoth.

Initially, develop the systems with a smaller group of representative gods. Expand the collection after the core gameplay is stable.

All gods must have distinct visual identities.

Do not use one generic character model with only a different color applied.

---

# 6. GOD ABILITY SYSTEM

Every god must have a gameplay purpose beyond generating money.

Examples:

### Zeus
Storm Ability.

Increases the production of nearby gods temporarily.

### Poseidon
Tidal Wave.

Slows players invading the base.

### Hades
Underworld Protection.

Temporarily protects a selected eligible god from theft.

### Athena
Strategic Vision.

Highlights important nearby events and incoming threats.

### Ares
War Cry.

Temporarily increases defensive power.

### Thor
Mjolnir Strike.

Stuns an invading NPC or player for a short duration.

### Odin
Divine Sight.

Detects nearby invasions and reveals special events.

### Loki
Illusion.

Creates a decoy in the player's base.

### Anubis
Divine Judgment.

Applies a temporary slowing effect to an intruder.

### Ra
Solar Blessing.

Improves production during solar events.

### Isis
Divine Restoration.

Repairs part of the base's defensive systems.

Create a modular ability framework.

Abilities must use server-side validation.

Avoid duplicated code between gods.

All abilities must be configurable.

---

# 7. EGG SYSTEM

Eggs are the central collectible objects.

Each egg must have:

- Unique model.
- Unique icon.
- Name.
- Civilization.
- Price.
- Hatch duration.
- Possible gods.
- Probability table.
- Rarity.
- Hatch animation.
- Sound effects.

Initial egg categories:

- Greek Egg.
- Norse Egg.
- Egyptian Egg.
- Ancient Egg.
- Celestial Egg.
- Divine Egg.

Create distinct visual identities for all eggs.

Use Blender-produced models.

## 7.1 Rarities

Initial rarity levels:

- Common.
- Uncommon.
- Rare.
- Epic.
- Legendary.
- Mythic.
- Divine.

All rarity probabilities must be configurable.

Do not hardcode probability logic into hatch scripts.

## 7.2 Hatch system

Requirements:

1. Player purchases or obtains an egg.
2. Egg enters inventory or hatch queue.
3. Player starts hatching.
4. An animation plays.
5. Egg cracks.
6. Visual effects communicate rarity.
7. God is revealed.
8. God enters inventory.
9. Player can inspect and equip it.

Create special animations for important rarities.

Do not make every hatch animation identical.

## 7.3 Paid random item compliance

Before implementing any paid random egg:

- Use PolicyService:GetPolicyInfoForPlayerAsync().
- Check ArePaidRandomItemsRestricted.
- Display all possible individual outcomes.
- Display actual numerical probabilities.
- Ensure probabilities total exactly 100%.
- Update probabilities when modifiers are active.
- Provide an eligible alternative for restricted users.
- Prevent restricted players from purchasing or accessing the paid random generator.

Direct purchases of specific gods should always be available as an alternative where appropriate.

Use the current official Roblox paid random item requirements.

---

# 8. PLAYER BASE SYSTEM

Every human player receives a personal base.

The base contains:

- God display slots.
- Egg storage.
- Coin collection.
- Upgrade stations.
- Defensive structures.
- Gates.
- Traps.
- Decorative objects.
- Personalization options.

## 8.1 Base progression

Implement configurable base levels.

Each upgrade may unlock:

- Additional god slots.
- Additional egg capacity.
- More production.
- Stronger defensive mechanics.
- Better decorations.
- Additional customization.

Create clear visual feedback when a base is upgraded.

## 8.2 God placement

Players must be able to:

- Place gods in available slots.
- Move gods.
- Remove gods.
- Inspect god information.
- Compare production.
- Activate eligible abilities.

Server authority must determine god ownership and placement.

---

# 9. STEALING SYSTEM

This is one of the most important systems in the entire experience.

Players must be able to invade other bases and steal eggs or eligible gods.

## 9.1 Stealing mechanics

1. The thief enters an enemy base.
2. Selects an eligible egg or god.
3. Starts a stealing interaction.
4. An interaction timer begins.
5. The owner receives an invasion notification.
6. Defensive abilities can be activated.
7. If stealing completes, the object is attached to the thief.
8. The thief must return to their own base.
9. The stolen object is transferred to their inventory or base.

## 9.2 Restrictions

Implement:

- Server-authoritative ownership.
- Distance validation.
- Stealing cooldown.
- Base ownership validation.
- Line-of-sight validation when appropriate.
- Anti-duplication protection.
- Disconnect handling.
- Protection against repeatedly targeting one player.
- New-player protection.
- Recovery mechanics.

Never allow the client to directly decide if stealing succeeded.

Never allow purchased premium collectibles to be stolen without an explicit, transparent and compliant game design.

NPCs and humans must follow the same gameplay rules wherever applicable.

---

# 10. DIVINE POPULATION — INTELLIGENT AI RIVALS

THIS IS A MAJOR FEATURE.

The game must contain intelligent AI-controlled NPC rivals that create competition and activity even when the server has very few human players.

These entities are in-game NPCs, not fake Roblox accounts.

They must never impersonate real Roblox users.

## 10.1 Design objectives

Each NPC must:

- Have an individual identity.
- Have a name and visual appearance.
- Have a personality.
- Own a base.
- Collect eggs.
- Hatch gods.
- Earn simulated coins.
- Upgrade its base.
- Defend its collection.
- Scout other bases.
- Attempt thefts.
- React to attacks.
- Participate in events.
- Progress independently.
- Make decisions based on its own objectives.

They must not simply wander randomly.

Each NPC should behave like an autonomous competitor.

## 10.2 Individual AI identities

Create persistent archetype definitions.

Initial AI rivals:

### ARES
Personality: Aggressive.

Behavior:
- Frequently scouts other bases.
- Prioritizes stealing rare eggs.
- Accepts higher risks.
- Invests in offensive abilities.
- Responds aggressively to successful defenses.

### ATHENA
Personality: Strategic.

Behavior:
- Prioritizes efficient production.
- Avoids unnecessary risks.
- Studies nearby rivals.
- Invests in upgrades.
- Attempts calculated thefts.

### LOKI
Personality: Unpredictable.

Behavior:
- Alternates between collecting and raiding.
- Uses decoy mechanics.
- Changes targets.
- Takes opportunistic actions.

### ANUBIS
Personality: Defensive.

Behavior:
- Prioritizes base security.
- Upgrades defensive structures.
- Collects defensive gods.
- Avoids unnecessary aggression.

### HERMES
Personality: Opportunistic.

Behavior:
- Searches for unprotected eggs.
- Moves quickly between locations.
- Prioritizes short theft opportunities.
- Avoids prolonged conflicts.

### THOR
Personality: Competitive.

Behavior:
- Seeks powerful gods.
- Invests in offensive abilities.
- Challenges stronger rivals.
- Prioritizes progression milestones.

Create a configurable personality system so more NPCs can be added without rewriting the AI architecture.

## 10.3 AI intelligence architecture

Use a combination of:

- Utility AI.
- Hierarchical finite state machines.
- Goal selection.
- Short-term memory.
- Personality-based decision weights.
- Risk evaluation.
- Progression objectives.

Do not use expensive external LLM APIs.

The AI should operate locally through Luau logic.

Each bot must have its own decision state.

### Possible states

- Idle.
- Collecting.
- Scouting.
- Purchasing.
- Hatching.
- Upgrading.
- Defending.
- PreparingRaid.
- Infiltrating.
- Stealing.
- Escaping.
- Recovering.
- ParticipatingInEvent.
- ReturningHome.
- Retiring.

The AI should evaluate possible actions using a utility score.

Example:

Ares may evaluate:

- Potential theft reward: 85.
- Risk of being defeated: 30.
- Expected travel time: 15.
- Defensive weakness of target: 90.

Athena may evaluate the same target differently.

The decision system must produce genuinely different behavior.

## 10.4 Individual bot progression

Each bot has its own simulated state:

- Coins.
- Inventory.
- God collection.
- Egg inventory.
- Base level.
- Upgrade levels.
- Active abilities.
- Current objectives.
- Personality.
- Difficulty.
- Short-term memory.

Bot progression must use the same general economy and gameplay rules.

Do not allow bots to receive arbitrary resources without explaining the simulation.

Bot state does not need to be saved to DataStore by default.

Keep bot simulations server-scoped unless persistent rival identities provide a measurable gameplay benefit.

Bots must never generate Robux transactions or purchase real game products.

## 10.5 NPC navigation

Use Roblox PathfindingService and Humanoid movement.

Bots must:

- Navigate around structures.
- Detect unreachable destinations.
- Recalculate paths.
- Avoid obstacles.
- Enter and leave bases.
- Interact with eggs.
- Approach objectives.
- Return to their own base.

Avoid teleporting bots around the map to simulate activity.

Teleportation is only acceptable for controlled spawning, retirement or a documented recovery from a navigation failure.

Use optimized movement updates.

Do not update every NPC's decision every frame.

## 10.6 AI fairness

Bots must not have unfair information.

They must not:

- Know the contents of hidden eggs.
- See through walls.
- Instantly identify every player inventory item.
- Ignore stealing restrictions.
- Teleport to successful theft locations.
- Bypass defensive systems.

Information must be acquired through scouting, observation or legitimate game events.

Adapt bot difficulty to the player's progression, but never make the system secretly change outcomes to force purchases.

## 10.7 Bots interacting with human players

Bots may interact with player bases.

However:

- Protect newly joined players.
- Never steal items acquired through direct Robux purchases.
- Never repeatedly attack the same player.
- Use visible and understandable invasion warnings.
- Provide fair opportunities to defend.
- Provide recovery opportunities after successful NPC thefts.
- Prioritize bot-versus-bot interactions when human populations are low.

Bot thefts must be meaningful without becoming frustrating.

Create configurable attack probabilities, cooldowns and difficulty levels.

## 10.8 Dynamic population management

This is a critical system.

AI rivals must dynamically adapt to the number of human players inside the server.

Use Players:GetPlayers() to count real human players.

NPCs must not be counted as actual Roblox players.

Initial configuration:

TargetActivePopulation = 7

MaxBots = 6

MinimumBots = 0

Example:

| Real Players | Target AI Rivals |
|---|---:|
| 1 | 6 |
| 2 | 5 |
| 3 | 4 |
| 4 | 3 |
| 5 | 2 |
| 6 | 1 |
| 7+ | 0 |

Formula:

BotTarget = min(MaxBots, max(0, TargetActivePopulation - HumanPlayerCount))

All values must be configurable.

### When real players join

If the current NPC population is above the new target:

1. Stop assigning new objectives to excess bots.
2. Let active interactions conclude when safe.
3. Have selected bots return to a designated temple.
4. Play a retirement animation.
5. Remove their NPC models.
6. Release associated resources.

Do not make NPCs disappear abruptly.

### When real players leave

If the population becomes too low:

1. Calculate the new NPC target.
2. Spawn additional rivals gradually.
3. Assign their initial identities and bases.
4. Let them begin normal gameplay.

Use population hysteresis and cooldowns to prevent continuous spawning and despawning when players repeatedly join and leave.

### Performance limits

All population values must be adjustable based on server performance.

Create configurable limits for:

- Maximum active NPCs.
- Maximum simultaneous pathfinding calculations.
- Decision update frequency.
- Maximum NPC interactions.
- Maximum active visual effects.

AI population must not sacrifice performance on mobile devices.

## 10.9 AI identification

All NPCs must be recognizable as AI-controlled competitors.

Use:

- An [AI] nameplate.
- A small AI icon.
- An NPC badge in their inspection panel.
- A separate AI rivals list.

Never put bots in the real Roblox player list.

Never simulate real Roblox accounts.

Never claim that an actual human player joined, purchased an item or performed an action when it was an NPC.

Do not fabricate global player counts, concurrent player counts or real user leaderboards.

---

# 11. DIVINE WORLD FEED

Implement a live activity feed that creates the sensation of an active world.

This is distinct from real player chat.

The feed should report genuine gameplay events from humans, NPCs and world systems.

Examples:

[AI RIVAL] Ares invaded Loki's base!

[WORLD EVENT] A Divine Egg has appeared near Olympus!

[AI RIVAL] Athena hatched Poseidon!

[AI RIVAL] Anubis successfully defended his collection!

[PLAYER EVENT] A player discovered a Mythic God!

[WORLD EVENT] A Solar Eclipse has started!

[AI RIVAL] Hermes is attempting to steal an Egyptian Egg!

Messages must correspond to real events.

## Feed requirements

- Event category.
- Event icon.
- Actor identifier.
- Event description.
- Timestamp.
- Optional rarity color.
- Configurable duration.
- Maximum message count.
- Smooth animations.
- Mobile-compatible layout.

Use a dedicated GUI activity feed.

It may be visually integrated near the Roblox chat interface.

If system events are also sent through TextChatService, use legitimate system messages such as [WORLD EVENT] or [AI RIVAL].

Never fabricate user-generated chat messages.

Never use NPCs to impersonate real players in chat.

Only predefined or properly controlled system event templates should be used.

The feed must include:

- Human player activities.
- AI rival activities.
- World events.
- Rare discoveries.
- Important milestones.

Implement event prioritization.

A common coin collection should not produce excessive notifications.

Rare discoveries and significant thefts deserve stronger presentation.

---

# 12. AI BOT EVENT SYSTEM

The AI population should generate real world activity.

Examples:

- Bot discovers a rare egg.
- Bot invades another bot.
- Bot upgrades its base.
- Bot unlocks a new civilization.
- Bot defends a robbery.
- Bot hatches a legendary god.
- Bot loses an eligible egg.
- Bot starts participating in an event.

Events must be generated by actual AI actions.

Do not create fake events simply to keep the feed busy.

Use an event cooldown and priority system.

Bot-versus-bot activity should be more frequent than attacks against human players.

---

# 13. ECONOMY SYSTEM

Create three initial currencies.

### Coins

Main progression currency.

Obtained through:

- God production.
- Quests.
- Stealing.
- Events.
- Achievements.
- Rewards.

### Gems

Premium currency.

Obtained through:

- Direct purchases.
- Selected achievements.
- Events.
- Limited progression milestones.

### Divine Shards

Advanced progression material.

Obtained through:

- Rebirth.
- Special quests.
- World events.
- High-level activities.

All economy values must be configurable.

Create a centralized EconomyConfig.

Avoid putting currency values directly into individual scripts.

## Economy balance requirements

- Meaningful free progression.
- Clear upgrade costs.
- Gradually increasing production.
- Multiple currency sinks.
- Balanced rebirth requirements.
- Configurable income multipliers.
- Server-side currency calculations.

Do not inflate numbers unnecessarily.

---

# 14. UPGRADES

Implement upgrade systems for:

- Base capacity.
- God production.
- Hatch speed.
- Player speed.
- Defensive strength.
- Inventory capacity.
- Divine ability effectiveness.
- Rebirth bonuses.

Each upgrade must have:

- Level.
- Current price.
- Next price.
- Effect.
- Maximum level where appropriate.
- Visual feedback.

The player should clearly understand what each upgrade does.

---

# 15. REBIRTH

Rebirth allows players to reset selected progression in exchange for permanent bonuses.

Requirements:

- Minimum progression requirements.
- Confirmation screen.
- Permanent bonus calculation.
- Unlockable eggs.
- Exclusive rewards.
- Rebirth leaderboard.

Never remove real-money purchases or paid entitlements.

Make the system configurable and prevent accidental rebirths.

---

# 16. QUESTS AND RETENTION

Implement:

### Daily quests

Examples:

- Hatch three eggs.
- Collect a certain amount of coins.
- Upgrade a god.
- Complete one successful theft.
- Defend your base.

### Weekly quests

More difficult progression challenges.

### Achievements

Examples:

- First God.
- First Legendary.
- First Successful Theft.
- First Divine God.
- First Rebirth.
- Complete Greek Collection.

### Daily login rewards

Use a configurable reward table.

Do not punish players excessively for missing a day.

### Collection book

Show:

- Discovered gods.
- Missing gods.
- Rarities.
- Civilizations.
- God descriptions.
- Abilities.

This should provide a strong long-term collection objective.

---

# 17. WORLD EVENTS

Create a modular world event framework.

Initial events:

### Solar Eclipse

Egyptian gods receive production bonuses.

### Ragnarok

Norse-themed world event with special egg appearances.

### Divine Storm

Greek eggs become temporarily available in special locations.

### Olympian Invasion

A special NPC enemy appears.

### Celestial Portal

Unlocks a temporary zone with exclusive rewards.

World events must be announced in the Divine World Feed.

Use server-authoritative event timing and reward calculation.

Avoid events that require every player to spend Robux to participate.

---

# 18. MONETIZATION ARCHITECTURE

Monetization is a major business objective.

The shop must be designed professionally, with multiple product categories.

However, monetization must never compromise the core gameplay.

## 18.1 Gamepasses

Prepare support for:

| Gamepass | Main Benefit |
|---|---|
| VIP | VIP cosmetics, tag and benefits |
| 2x Coins | Production multiplier |
| 2x Luck | Eligible hatch probability modifier |
| Extra Slots | Additional god slots |
| Fast Hatch | Faster hatching |
| Speed Boost | Faster movement |
| Auto Collect | Automatic coin collection |
| Premium Base | Exclusive base appearance and features |
| Extra Equip | Additional equipped gods |
| Divine Access | Special area and cosmetics |

All gamepass IDs must remain configurable.

Never invent product IDs.

## 18.2 Developer Products

Prepare support for:

- Coin packages.
- Gem packages.
- Instant hatch.
- Temporary production boost.
- Temporary luck boost.
- Divine protection.
- Emergency defensive shield.
- Temporary speed boost.
- Rebirth tokens.
- Cosmetic effects.

Products must have unique configurable IDs.

Developer Products must use MarketplaceService.ProcessReceipt.

Receipt processing must be idempotent.

Do not grant an item twice if Roblox retries a receipt.

Use persistent transaction records and safe recovery.

## 18.3 Guaranteed bundles

Create product bundles featuring:

- Specific guaranteed gods.
- Exclusive god skins.
- Hatch effects.
- Cosmetics.
- Coins.
- Gems.

The customer must know exactly what is included.

## 18.4 Cosmetics

Sell:

- Egg skins.
- God skins.
- Hatch effects.
- Base decorations.
- Trails.
- Special animations.
- Nameplate styles.
- Collection display themes.

Cosmetics should create additional monetization opportunities without affecting gameplay balance.

## 18.5 Starter Pack

Create a one-time beginner offer.

It should have:

- Clear item descriptions.
- Clearly displayed price.
- Exact rewards.
- Purchase state.
- Proper visibility conditions.

Do not use fake countdowns or fake scarcity.

## 18.6 Future monetization

Prepare the architecture for:

- Seasonal reward passes.
- Monthly subscriptions, if justified.
- Rotating cosmetic shops.
- Premium progression rewards.

Do not implement these before the main game is stable.

## 18.7 Payment security

All purchases must be verified through Roblox APIs.

Implement:

- Gamepass ownership checks.
- Developer Product receipt verification.
- Duplicate receipt prevention.
- Purchase failure handling.
- Safe reward granting.
- Purchase history where appropriate.

Do not allow the client to grant itself purchased items.

## 18.8 Paid random items

Implement all current Roblox requirements for paid randomized rewards.

Use PolicyService and the appropriate eligibility checks.

Every possible outcome must be disclosed before purchase.

Display actual individual probabilities.

Update probabilities when luck multipliers are active.

Make restricted purchases unavailable to ineligible users and provide compliant alternatives.

Do not assume that buying premium currency makes an otherwise restricted random reward permissible.

---

# 19. PLAYER DATA AND SAVING

Create a modular PlayerDataService.

Player data must include:

- Coins.
- Gems.
- Divine Shards.
- Gods.
- Eggs.
- Inventory.
- Base level.
- Upgrades.
- Rebirth.
- Achievements.
- Quest progress.
- Settings.
- Equipped gods.
- Collection discoveries.

Implement:

- DataStoreService.
- Safe saving.
- Retry handling.
- Versioning.
- Data migration.
- Session locking where appropriate.
- Autosave.
- Player removal saving.
- BindToClose handling.

Never assume DataStore operations always succeed.

Handle failures gracefully.

Avoid excessive DataStore requests.

Bot data must remain separate from human player data.

NPCs must not consume human player DataStore budgets unnecessarily.

---

# 20. SECURITY AND ANTI-EXPLOIT

All important systems must be server-authoritative.

Never trust the client for:

- Currency.
- Inventory.
- Egg ownership.
- God ownership.
- Hatch outcomes.
- Stealing.
- Upgrades.
- Rebirth.
- Purchased rewards.
- Ability cooldowns.

Validate every RemoteEvent.

Use:

- Request validation.
- Distance checks.
- Rate limiting.
- Cooldowns.
- Ownership checks.
- Transaction validation.
- Anti-duplication logic.
- Server-side reward calculations.

Create a dedicated AntiExploitService.

Do not block legitimate player behavior through overly aggressive checks.

Keep useful server logs for investigating suspicious operations.

---

# 21. USER INTERFACE

Create a polished Roblox simulator interface.

The interface must work on:

- Desktop.
- Mobile.
- Tablet.

Main UI elements:

### HUD

- Coins.
- Gems.
- Divine Shards.
- Player level.
- Rebirth.
- Notifications.

### Main menu

- Inventory.
- Collection.
- Shop.
- Quests.
- Upgrades.
- Settings.

### Shop

Separate categories:

- Gamepasses.
- Developer Products.
- Divine Bundles.
- Cosmetics.
- Gems.

### Hatch UI

- Egg model.
- Price.
- Available gods.
- Rarity odds when required.
- Hatch button.
- Animation.
- Result display.

### Base UI

- Available slots.
- God placement.
- Production.
- Upgrades.
- Defense.

### Activity UI

- Divine World Feed.
- AI Rivals.
- Invasion warnings.
- World event alerts.

Visual style must be coherent.

Do not create a generic unfinished Roblox interface.

---

# 22. ART DIRECTION

The game must use polished stylized 3D assets.

Visual identity:

- Colorful.
- Expressive.
- Readable.
- Recognizable.
- Fantasy-inspired.
- Optimized for Roblox.

Avoid photorealism.

Use exaggerated proportions and strong visual silhouettes.

## Asset pipeline

The primary 3D production tools are:

- Blender.
- ForgeGUI.

Use Blender for:

- Egg modeling.
- God modeling.
- Base structures.
- Props.
- Environment.
- Rigging.
- Animation.
- UV mapping.
- Material preparation.

Use ForgeGUI for the asset-production workflows that its actual installed capabilities support.

Do not invent ForgeGUI APIs or claim to generate or export files through it unless those capabilities are verified.

## Import pipeline

Create a standard asset naming convention.

Use a predictable export structure.

All assets must be documented in ASSET_MANIFEST.md.

Maintain:

- Original model.
- Exported model.
- Import status.
- Roblox asset reference.
- Collision configuration.
- Pivot configuration.
- Texture reference.
- Animation reference.

Check:

- Scale.
- Orientation.
- Materials.
- Collision.
- Polycount.
- Texture resolution.
- Mobile performance.

Do not silently use placeholder models in the final release.

---

# 23. TECHNICAL ARCHITECTURE

Use modular Luau.

Suggested project layout:

STEAL-A-GOD/

ReplicatedStorage/
- Shared/
  - Config/
  - Types/
  - Modules/
- Remotes/
- Assets/

ServerScriptService/
- Bootstrap.server
- Services/
  - PlayerDataService
  - EconomyService
  - GodService
  - EggService
  - BaseService
  - StealService
  - AbilityService
  - UpgradeService
  - RebirthService
  - QuestService
  - EventService
  - MonetizationService
  - ReceiptService
  - AntiExploitService
  - BotPopulationService
  - BotSimulationService
  - BotNavigationService
  - BotEventService
  - WorldFeedService

StarterPlayer/
- StarterPlayerScripts/
  - ClientMain
  - Controllers/
    - UIController
    - ShopController
    - HatchController
    - InventoryController
    - BaseController
    - StealController
    - FeedController
    - EffectsController

StarterGui/
- HUD
- Shop
- Inventory
- Collection
- HatchUI
- BaseUI
- Quests
- DivineWorldFeed
- Settings

Workspace/
- Map/
- PlayerBases/
- BotBases/
- EggSpawners/
- Events/
- NPCs/
- Portals/

The exact file structure may be adapted to the existing project.

Do not create duplicated services.

---

# 24. PERFORMANCE REQUIREMENTS

The game must support multiple NPCs and human players without unnecessary server load.

Optimize:

- NPC pathfinding.
- Decision updates.
- Physics.
- Animations.
- Particle effects.
- Model complexity.
- UI updates.
- RemoteEvent traffic.
- DataStore usage.

Do not run expensive decision logic every frame.

Use controlled update intervals.

Implement LOD or reduced visual updates for distant NPCs when appropriate.

Use server-side NPC simulation.

Keep network ownership and movement behavior stable.

Test on low-end mobile hardware where possible.

---

# 25. DEVELOPMENT ENVIRONMENT AND TOOLING

First inspect the available environment.

Determine:

- Roblox Studio availability.
- Existing project format.
- Whether Rojo is installed.
- Whether Git is configured.
- Whether command-line tools are available.
- How scripts will be synchronized with Roblox Studio.
- How Blender assets are exported.
- How ForgeGUI is available in the workflow.

Do not assume that every tool is installed.

If Rojo is available, use a consistent project synchronization configuration.

If the workflow is Roblox Studio-first, adapt to the existing structure rather than creating an incompatible project.

Keep the project compatible with Roblox Studio.

Do not generate imaginary plugins or undocumented integrations.

---

# 26. DEVELOPMENT PHASES

Work through the following stages.

## PHASE 0 — PROJECT INSPECTION

Inspect the project directory.

Identify existing files.

Identify development tools.

Document the current state.

Create:

- PROJECT_SPEC.md
- DEVELOPMENT_LOG.md
- ASSET_MANIFEST.md
- ECONOMY_DESIGN.md
- BOT_AI_DESIGN.md
- TEST_PLAN.md

Do not destroy existing work.

## PHASE 1 — TECHNICAL FOUNDATION

Implement:

- Project structure.
- Shared configuration.
- Server bootstrap.
- Client bootstrap.
- Remote architecture.
- PlayerDataService.
- Basic HUD.
- Base assignment.

Test player spawning and data loading.

## PHASE 2 — FIRST PLAYABLE LOOP

Implement:

- Coins.
- Basic egg shop.
- Egg inventory.
- Hatching.
- God inventory.
- God placement.
- Passive production.
- Basic upgrades.

The player must be able to enter, earn currency, buy an egg, hatch a god and generate income.

## PHASE 3 — FIRST AI RIVAL

Implement one functional AI opponent.

It must:

- Spawn inside its own base.
- Have a personality.
- Acquire coins through simulation.
- Purchase eggs.
- Hatch gods.
- Upgrade its base.
- Make independent decisions.

Do not begin with six bots before validating the first one.

## PHASE 4 — AI POPULATION

Implement:

- Multiple rival identities.
- Personality weights.
- Individual goals.
- Bot state management.
- Navigation.
- Bot-versus-bot interactions.
- Dynamic population manager.
- Gradual retirement and spawning.

Test the behavior with different numbers of human players.

## PHASE 5 — STEALING

Implement:

- Invasions.
- Egg theft.
- God theft where eligible.
- Carrying.
- Return-to-base completion.
- Defense.
- Alerts.
- Cooldowns.
- Bot-versus-bot stealing.
- Bot-versus-human interactions.

All actions must be validated on the server.

## PHASE 6 — DIVINE ABILITIES

Implement the initial gods and their individual abilities.

Add:

- Animations.
- VFX.
- Cooldowns.
- UI.
- Server validation.

## PHASE 7 — PROGRESSION

Implement:

- Base upgrades.
- God upgrades.
- Rebirth.
- Quests.
- Achievements.
- Collection.
- Daily rewards.
- World events.

## PHASE 8 — MONETIZATION

Implement:

- Gamepasses.
- Developer Products.
- Product receipt handling.
- Premium bundles.
- Cosmetics.
- Shop UI.
- Paid-random-item policy compliance.

Use placeholder IDs until real Roblox product IDs are supplied.

Never invent real product IDs.

## PHASE 9 — ART INTEGRATION

Integrate Blender-produced assets.

Validate:

- Models.
- Scale.
- Materials.
- Pivots.
- Animations.
- Collisions.
- Performance.

Use the asset manifest to track every model.

## PHASE 10 — QUALITY ASSURANCE

Test:

- Saving and loading.
- Multiple human players.
- NPC population changes.
- NPC navigation.
- NPC decision diversity.
- Stealing.
- Defense.
- Disconnects.
- Data persistence.
- Gamepass ownership.
- Developer Product receipts.
- Exploit resistance.
- Mobile UI.
- Server performance.

Do not claim features work until they have been tested.

## PHASE 11 — RELEASE PREPARATION

Prepare:

- Game icon.
- Thumbnails.
- Description.
- Tutorial.
- Onboarding.
- Settings.
- Analytics.
- Economy tuning.
- Release checklist.

Do not publish automatically without explicit authorization.

---

# 27. ACCEPTANCE CRITERIA

The initial playable release is not considered complete until all requirements below are met.

### Gameplay

- A player can enter the game.
- A personal base is assigned.
- Coins can be earned.
- Eggs can be purchased.
- Eggs can be hatched.
- Gods can be collected.
- Gods generate income.
- Base upgrades work.
- Rebirth works.
- Stealing works.
- Defensive mechanics work.

### AI

- Multiple individual AI profiles exist.
- NPCs make independent decisions.
- NPCs acquire and hatch eggs.
- NPCs build their own collections.
- NPCs upgrade their bases.
- NPCs can invade rival bases.
- NPCs can defend against invasions.
- NPC activity appears in the World Feed.
- NPCs are clearly identified as AI.
- AI population decreases when real players join.
- AI population increases when players leave.
- Retirement is visually smooth.
- Bots do not impersonate real Roblox accounts.

### Monetization

- Gamepass ownership is validated.
- Developer Product receipts are handled safely.
- Purchases are granted exactly once.
- Product IDs are configurable.
- Shop UI works.
- Paid random item rules are implemented.

### Security

- Client cannot grant itself currency.
- Client cannot modify inventory ownership.
- Client cannot fabricate hatch results.
- Client cannot bypass stealing rules.
- Purchase verification is server-authoritative.
- RemoteEvents are validated.

### Performance

- NPC population has configurable limits.
- Pathfinding is optimized.
- Visual effects are controlled.
- Mobile UI is functional.
- No major performance issues are introduced by AI simulation.

---

# 28. DOCUMENTATION RULES

Keep these documents updated:

PROJECT_SPEC.md:
Complete product specification and game rules.

DEVELOPMENT_LOG.md:
Completed work, current state, errors and next steps.

ASSET_MANIFEST.md:
All 3D models, animations and image assets.

ECONOMY_DESIGN.md:
All currencies, prices, upgrades and monetization.

BOT_AI_DESIGN.md:
Personalities, state machines, utility scores, population settings and interactions.

TEST_PLAN.md:
Test cases and validation results.

Update documentation whenever an important system changes.

---

# 29. IMPORTANT DEVELOPMENT BEHAVIOR

Do not generate a massive amount of code without inspecting the project.

Do not build systems using fabricated Roblox APIs.

Do not assume that an asset already exists.

Do not create placeholder monetization systems that cannot safely grant purchases.

Do not implement AI with constant random movement.

Do not treat NPCs as actual Players.

Do not create false player activity.

Do not write fake success reports.

Do not ignore errors.

When you encounter a limitation, explain it and propose a technically valid alternative.

Preserve working systems whenever possible.

Prefer complete, tested modules over enormous unfinished implementations.

---

# 30. FIRST EXECUTION REQUEST

Start by inspecting the actual development environment.

Do not immediately attempt to implement the entire game.

Your first development task is:

1. Inspect all available project files.
2. Determine the best Roblox Studio integration workflow.
3. Check whether Rojo is available.
4. Establish the modular project architecture.
5. Create the six documentation files listed in the development phases.
6. Define the initial economy and asset conventions.
7. Implement basic player spawning.
8. Implement personal base assignment.
9. Implement coin generation.
10. Implement one egg purchase.
11. Implement one hatchable god.
12. Implement basic god income.
13. Test the first playable gameplay loop.

After validating the first playable loop, implement the first AI rival using the Bot AI specification.

The first AI must independently purchase an egg, hatch a god and upgrade its base.

Only after the first AI works correctly should the project expand to the full rival population.

At the end of each development milestone, provide:

- What was implemented.
- Files created or modified.
- What was tested.
- What passed.
- What failed.
- Remaining limitations.
- The next development milestone.

The ultimate objective is to deliver a polished, scalable and commercially viable Roblox game called STEAL A GOD.
