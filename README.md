# Alien Lab v0.3

A playful slime garden built with Rojo and beginner-friendly Luau. Your slimes
make slime, you sell it for cash, and you hatch new species and upgrade your lab.
The existing Rojo project mapping is preserved. All visuals use native Roblox
parts and UI; no imported models, meshes, or image uploads are required.

## What's new

- Landscaped hub, trees, glowing path lights, garden gates, mushrooms, and a research reactor.
- A personal fenced garden and visible slimes that hop, wobble, and roam inside it.
- Seven slime species, each with a different color and accessories.
- Three egg tiers with visible odds and server-checked lab requirements.
- Five research upgrades that increase every slime's production.
- Green cash and 3D slime stats in the top left, with production directly below slime.
- Bottom action dock, scrollable egg shop, collection gallery, and research menu.
- Animated egg opening, a 3D hatch reveal, and local confetti.
- Server saves with autosaving, validated inventories, session ownership, and separate Studio data.

The farm, stations, slimes, and interface appear when **Play** starts. The edit
scene still shows the original baseplate; you do not need to build the farm by hand.

## How to play

1. Start with **$100**, **0 slime**, and a free **Slimelet**.
2. Your slimes produce slime automatically. Press **SELL** to convert all whole slime into cash.
3. Open **EGGS** and hatch a Starter Egg for **$50**.
4. Open **UPGRADE** and buy Lab 1 for **$150**. Botanical eggs become available.
5. Reach Lab 2 to unlock Cosmic eggs and work toward discovering Nebula!
6. Open **SLIMES** to see your discovered collection. Duplicates still produce slime.

You can also walk to the egg stations, selling tank, or research reactor in
your own farm and press **E**, or tap the prompt on a phone. Your character
returns to the farm entrance on respawn. A garden holds up to **25 slimes**.

| Slime | Rarity | Base slime / second |
| --- | --- | ---: |
| Slimelet | Common | 1 |
| Glowbug | Uncommon | 3 |
| Starling | Rare | 6 |
| Blossom | Rare | 8 |
| Ember | Epic | 12 |
| Frost | Epic | 18 |
| Nebula | Legendary | 30 |

| Egg | Price | Required lab | Hatch chances |
| --- | ---: | ---: | --- |
| Starter | $50 | 0 | Slimelet 60%, Glowbug 30%, Starling 10% |
| Botanical | $250 | 1 | Glowbug 35%, Blossom 50%, Ember 15% |
| Cosmic | $1,000 | 2 | Starling 30%, Frost 55%, Nebula 15% |

Each egg has a **2 second cooldown**. Upgrade prices are **$150, $400, $900,
$1,800, and $3,500**. Each level adds **25% of base production**, so a fully
upgraded lab produces **2.25 times** the base total. Fractions are retained
server-side until they become whole slime.

If your garden fills up, open **SLIMES** and use **Make room**. It releases one
of your weakest slimes after a second confirming click. There is no refund;
the collection discovery stays unlocked, and your final slime is protected.

## Pull and play-test

If your local project was already updated by Codex, skip the pull and start at step 3.

1. Stop your current Play test when you are ready.
2. In **Command Prompt**, run:

   ```bat
   cd /d "%USERPROFILE%\OneDrive\Desktop\alien_lab_roblox"
   git pull --ff-only origin main
   ```

   Keep any local edits if Git reports a conflict. Do not reset the project to force the pull.

3. Keep Rojo running from this project folder. If it is not running, start it:

   ```bat
   "%USERPROFILE%\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" serve default.project.json
   ```

4. In Studio, open **Plugins > Rojo**, connect to **localhost:34872**, and accept the sync if prompted.
5. Before pressing Play, check these objects in **Explorer**:

   - `ReplicatedStorage > Shared`: `AlienData`, `SlimeModel`, and `Remotes`.
   - `Remotes` contains `UpgradeLab` as well as the original events.
   - `ServerScriptService > Server`: `LabService`, `LabWorld`, `GardenDecor`, `DataPersistence`.
   - `StarterPlayer > StarterPlayerScripts > Client`: `LabUI` and `PetController`.

6. Click **Play** (F5). You should spawn at your farm, see the green HUD and bottom dock,
   and find a smiling green slime walking in the garden.
7. Wait a few seconds, sell slime, hatch a Starter Egg, and dismiss the hatch reveal.
   Check that the cash changes and a second slime appears.
8. Earn $150, upgrade once, and check that the production rate increases and Botanical eggs unlock.

To check multiplayer ownership, use Studio's server test with two players.
Each player should have a separate farm and balance, and cannot use the other
player's station prompts. These updates were checked with isolated native
Roblox instances and simulated network/save services; your live Play test is
still needed to confirm how they look on your device.

## Saving

An unpublished `Place1` runs in **Session mode**. You can test the whole game,
but progress resets when you stop or leave.

For a saving test, publish a **separate test experience**, then enable
**File > Experience Settings > Security > Enable Studio Access to API Services**
and save the setting. See [Roblox's DataStore setup documentation](https://create.roblox.com/docs/cloud-services/data-stores).
Do not enable this setting on a live production experience just for testing.

The HUD reports `Session mode`, `Autosave ready`, `Saved`, or `Save retrying`.
The research menu shows the fuller save status. Saving runs every **60 seconds**,
on leaving, and during server shutdown. Check saving by earning cash, hatching a
slime, buying an upgrade, leaving, and rejoining the published test experience.

Studio uses `AlienLab_v1_Studio`; published Roblox servers use `AlienLab_v1`.
Cash, slime, inventory, lab level, and discoveries are saved. There is no offline
production. Failed loads use session-only play and never save starter defaults
over existing progress. Active save sessions cannot be opened by another server;
a crashed server's lock expires after three minutes. Repeated service failures
can still prevent the latest progress from saving; check the HUD and Output.

## Where the code lives

```text
src/
  shared/
    AlienData.luau         -- prices, odds, species, upgrades, shared types
    SlimeModel.luau        -- reusable smiling slime models
    Remotes.model.json    -- RemoteEvents created by Rojo
  server/
    init.server.luau       -- player lifecycle, remotes, production, autosaves
    LabService.luau        -- private balances and validated transactions
    LabWorld.luau          -- personal farms, visible inventory, station checks
    GardenDecor.luau       -- hub and garden decorations
    DataPersistence.luau   -- save validation, retries, and session locks
  client/
    init.client.luau       -- requests, updates, and pending request handling
    LabUI.luau             -- HUD, menus, previews, and hatch effects
    PetController.luau     -- cosmetic slime movement and wobble
```

Change `AlienData` first when balancing the game. The client sends egg IDs and
action requests; it cannot choose its cash, price, upgrade level, or hatch result.
Ownership, distance, and character health are checked before station actions.

Build the Rojo place without running Studio:

```bat
"%USERPROFILE%\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" build default.project.json -o alien-lab.rbxlx
```

## If nothing appears

- Stop Play before syncing new scripts, then start a fresh test.
- Confirm Rojo is serving **this folder**, and the Explorer objects above are present.
- If `Shared` is empty despite files being on disk, stop the existing Rojo server,
  restart it from this folder, and reconnect the plugin. Do not run two servers on port 34872.
- In Rojo's plugin permissions, allow `localhost:34872` and **Script Injection**.
- Open Studio's **Output** window. Startup should print `Alien Lab v0.3 garden server ready`
  and `Alien Lab v0.3 garden client ready`. Share the first red error if startup fails.
