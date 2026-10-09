# Alien Lab v0.5 — Cosmic Gardens

A colorful alien farming game built with Rojo and commented Luau. Buy seeds,
plant your garden, harvest crops, and sell your basket for cash. Hatch alien
helpers and equip their unique farming abilities. The original Rojo project
mapping is preserved. Models use native Roblox parts and built-in sphere meshes;
there are no external model or image assets to upload.

## What's new

- Personal fenced gardens with **12 planting beds** and visible crop growth.
- A lavender floating island village, mushroom shops, crystals, lanterns,
  distant islands, and a glowing planet in the central plaza.
- Separate **seed, tool, and egg shops**, plus a harvest selling stall.
- Seven cute alien helpers with distinct faces, accessories, and farming passives.
- A compact top-left cash/basket/helper HUD and illustrated garden menus.
- **Captain Nova's Comet Harvest** quest at the center of the village.
- Saved seeds, crops, basket, tools, equipped helpers, and event progress.

The village and interface are created when **Play** starts. The original
template baseplate is hidden at runtime; the Edit scene remains the template.

## v0.5 visual polish

- More detailed mushroom shops with alien shopkeepers, window frames, awnings,
  floating shop displays, and a tall glowing portal landmark.
- Layered island cliffs, richer foliage, garden gates, and wooden bed borders.
- Brighter colors and clearer lighting, with gentle scenery movement.
- Illustrated HUD and navigation, shop preview tiles, menu transitions,
  readable status messages, and cash change animation.
- Local planting, watering, harvest, and quest reward effects, triggered only
  after successful server actions.
- More varied crop groups, carrot details, berry blossoms, mushroom gills,
  melon stripes, and distinctive mutation finishes.

The portal is a scenic village landmark in this version. Effects are cosmetic,
limited in number, and stop updating distant scenery to keep the game light.

## Your first harvest

1. Start with **$100**, **five Star Carrot seeds**, and a free **Gloop** helper.
2. Open **FARM** and choose **Star Carrot**. Walk to an empty bed in your own
   garden and press **E** to plant, or tap its prompt on mobile.
3. Use the bed again to water it once and speed up growth. Gloop also provides
   a 10% growth bonus while equipped.
4. When the bed says **Ready to harvest**, use it to put the crop in your basket.
5. Open the selling page or walk to the **SELL CROPS** stall and sell your basket.
6. Buy more seeds, upgrade tools, and hatch eggs to discover new farming helpers.

The Farm menu has Plant, Water, and Harvest modes and buttons for each bed.
Bed actions still require you to stand near that bed. A ripe crop is harvested
when you use it; using a growing crop in Plant mode waters it automatically.
Each bed consumes one seed and produces one harvest, represented by a small
group of plants. Harvesting clears the bed so you can plant again.

Cash comes from selling crops and completing quests. Helpers do not generate
cash or slime automatically. Crops grow while you are in the server; there is
no offline growth.

## Seeds and tools

| Crop | Seed price | Base growth time | Base sell value |
| --- | ---: | ---: | ---: |
| Star Carrot | $10 | 20 seconds | $28 |
| Moon Berry | $40 | 35 seconds | $100 |
| Glow Shroom | $100 | 50 seconds | $260 |
| Crystal Bloom | $250 | 75 seconds | $620 |
| Comet Melon | $500 | 90 seconds | $1,350 |

Growth bonuses and watering reduce the time you wait. Golden crops sell for
**2×**, and Cosmic crops sell for **3×**. Mutation chances are decided by the
server when planting. Nebula Sprout is a quest plant and cannot be sold.

| Tool | Price | Effect |
| --- | ---: | --- |
| Stellar Watering Can | $120 | Manual watering adds 30% progress instead of 15%. |
| Orbit Sprinkler | $750 | Permanent 20% growth bonus. |
| Mutation Scanner | $450 | Adds 5% chance of a Golden crop when planting. |

Tools are permanent purchases. Each crop can be manually watered once.
Lab research costs **$150, $400, $900, $1,800, and $3,500**; each level adds
**10% growth speed** and unlocks the corresponding egg tiers.

## Alien helpers

You can own up to **25 aliens** and equip up to **three different species** in
the ALIENS menu. Duplicate species do not stack their ability. Helpers roam
the garden entrance, and their labels show whether their ability is equipped.

| Helper | Rarity | Equipped ability |
| --- | --- | --- |
| Gloop | Common | Green Thumb: all crops grow 10% faster. |
| Orbit | Uncommon | Hydro Helper: manual watering adds another 10% progress. |
| Starlight | Rare | Lucky Stars: adds 8% Golden mutation chance. |
| Petal | Rare | Berry Bloom: harvested berries are worth 25% more. |
| Cinder | Epic | Crystal Keeper: harvested crystals are worth 35% more. |
| Sprout | Epic | Seed Saver: 20% chance to keep an ordinary seed when planting. |
| Nova | Legendary | Cosmic Touch: 4% chance of a Cosmic crop when planting. |

Berry/crystal bonuses apply when you harvest. Seed Saver does not refund quest
seeds. Quest crops always use the normal mutation. The game's stable internal
species IDs are kept so older alien inventories remain compatible.

| Egg | Price | Required lab | Hatch chances |
| --- | ---: | ---: | --- |
| Starter | $50 | 0 | Gloop 60%, Orbit 30%, Starlight 10% |
| Botanical | $250 | 1 | Orbit 35%, Petal 50%, Cinder 15% |
| Cosmic | $1,000 | 2 | Starlight 30%, Sprout 55%, Nova 15% |

Eggs have a two-second cooldown. New species equip automatically if a helper
slot is free. If your inventory fills up, the ALIENS menu can release one of
your weakest helpers after a confirming click. There is no refund; discoveries
remain unlocked, and your final helper is protected.

## The central event

1. Walk to **Captain Nova**, the blue alien beside the glowing planet, and press E.
2. Accept **The Comet Harvest**. You receive **three Nebula Sprout seeds**.
3. Choose those seeds in FARM or QUEST and plant them in your garden.
4. Grow and harvest all three. These harvests count toward the mission.
5. Return to Captain Nova and collect **$500 + two Crystal Bloom seeds**.

You must stand near Captain Nova to accept or claim the mission. The event is
repeatable after completing it. It is an always-available farming quest in this
version; it has no timer or shared global progress.

## Pull and verify in Roblox Studio

If Codex already updated your local folder, skip the pull and begin at step 3.

1. When you are ready, stop your current Play test.
2. In **Command Prompt**, run:

   ```bat
   cd /d "%USERPROFILE%\OneDrive\Desktop\alien_lab_roblox"
   git pull --ff-only origin main
   ```

   If Git reports local edits or a conflict, keep those edits and resolve the
   conflict before continuing. Do not reset the project to force the pull.

3. Keep Rojo running from that project folder. If needed, start it:

   ```bat
   "%USERPROFILE%\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" serve default.project.json
   ```

4. Open **Plugins > Rojo**, connect to **localhost:34872**, and accept the sync.
5. In Explorer, check:

   - `ReplicatedStorage > Shared`: `AlienData`, `FarmData`, `CropModel`, `SlimeModel`, `Remotes`.
   - `Remotes`: `BuySeed`, `BuyTool`, `BedAction`, `SellHarvest`, `EquipAlien`, `ClaimEvent`, `OpenShop`.
   - `Remotes > FarmFeedback` sends successful farming effects to the client.
   - `ServerScriptService > Server`: `LabService`, `LabWorld`, `GardenDecor`, `DataPersistence`, `FarmSaveSchema`.
   - `StarterPlayer > StarterPlayerScripts > Client`: `LabUI`, `PetController`, `WorldEffects`.

6. Press **F5 / Play**. You should spawn at your garden entrance with the HUD,
   a green Gloop helper, and the cosmic village around you.
7. Plant, water, harvest, and sell a Star Carrot. Check that planting uses a seed,
   harvesting increases your basket, and selling changes your cash once.
8. Buy a seed and a tool, hatch a Starter Egg, and try equipping its helper.
9. Accept Captain Nova's mission, harvest three Nebula Sprouts, and return for
   the reward. Claiming again must not give another free reward.

For multiplayer testing, use two clients in Studio's server test. Each player
should receive a separate garden and balance. Players cannot use another
player's beds. These changes passed a fresh Rojo build and isolated native
Roblox checks for farming, networking, models, menus, and saving. A live Play
test is still needed to confirm movement and appearance on your device.

## Saving and older progress

An unpublished `Place1` uses **Session mode**: the whole game works, but progress
resets when you stop or leave. For a saving test, publish a separate test
experience and enable **Experience Settings > Security > Enable Studio Access
to API Services**. See [Roblox's DataStore documentation](https://create.roblox.com/docs/cloud-services/data-stores).

Saving runs every **60 seconds**, on leaving, and during shutdown. Studio uses
`AlienLab_v1_Studio`; published servers use `AlienLab_v1`. The HUD shows the
save status. Cash, alien inventory/discoveries, lab level, seeds, beds and their
growth, harvest basket, tools, equipped helpers, and quest progress are saved.

Older saves keep their cash, aliens, discoveries, and lab level. Stored slime
is converted to cash once, and players receive five starting carrot seeds.
The converted record is marked with `FarmVersion = 1` to prevent repeat grants.
Failed loads run in session mode and do not overwrite existing progress with
defaults. Session ownership prevents two servers from saving the same player
at once. A crashed server's lock expires after three minutes.

## Beginner-friendly code structure

```text
src/
  shared/
    AlienData.luau       -- species, unique abilities, eggs, upgrades
    FarmData.luau        -- crops, tools, mutation values, quest rewards
    SlimeModel.luau      -- reusable alien companion models
    CropModel.luau       -- visible crop families and growth stages
    Remotes.model.json  -- RemoteEvents created by Rojo
  server/
    init.server.luau     -- player lifecycle, requests, growth, autosaves
    LabService.luau      -- private inventory and validated farming economy
    LabWorld.luau        -- gardens, shops, NPC, beds, ownership/distance checks
    GardenDecor.luau     -- island, mushroom shops, crystals, lighting
    FarmSaveSchema.luau  -- farming save validation and older save conversion
    DataPersistence.luau -- save retries, session locks, and load protection
  client/
    init.client.luau     -- requests, updates, menus, pending action handling
    LabUI.luau           -- HUD, farming pages, previews, hatch reveal
    PetController.luau   -- cosmetic walking, blinking, companion animation
    WorldEffects.luau    -- floating scenery, portal motes, farming feedback
```

Change `FarmData` and `AlienData` to adjust balance. The client requests actions;
the server decides prices, inventory changes, mutations, hatch outcomes, and
rewards. Farming and quest interactions validate distance and character health.

Build without starting Studio:

```bat
"%USERPROFILE%\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" build default.project.json -o alien-lab.rbxlx
```

## If nothing appears

- Stop Play before syncing new scripts, then start a fresh test.
- Confirm Rojo serves this folder and the Explorer modules above are present.
- If new modules are missing, stop the old Rojo server, restart it from this
  folder, and reconnect. Use only one server on port 34872.
- Rojo's plugin permissions must allow `localhost:34872` and **Script Injection**.
- If every object has checker or grid lines, check **View > Grid Material** in
  Studio and turn it off to see the normal materials.
- Output should print `Alien Lab v0.5 cosmic farming server ready` and
  `Alien Lab v0.5 cosmic garden client ready`. Share the first red error if startup fails.
