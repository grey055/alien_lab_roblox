# Alien Lab v0.2

A small, playable Rojo/Luau prototype: your aliens make slime, you sell slime
for cash, and you buy eggs to grow your lab. Generated with Rojo 7.7.1.

v0.2 adds a personal fenced farm, visible smiling slimes that roam inside the
garden, an egg dispenser, a selling tank, and a compact green HUD in the top
left. The HUD has a 3D slime icon and shows production below the slime total.

## Gameplay

- Join with **100 cash**, **0 slime**, and one free **Slimelet**.
- Every owned alien produces slime automatically on the server.
- **Hatch Starter Egg** costs **50 cash** and immediately grants one alien.
- **Sell all slime** converts each whole slime into **1 cash**.
- Eggs have a **2 second cooldown**; a lab can hold **25 aliens**.
- Duplicate aliens are allowed. Every owned alien adds to production.
- Your character spawns at your own farm's entrance and returns there on respawn.
- Walk up to your egg dispenser or selling tank and press **E** (or tap its
  prompt on a phone). The HUD buttons work too.
- Slimelet is green, Glowbug is turquoise, and Starling is purple with a gold
  crest. New hatches appear in the garden and start roaming automatically.

| Alien | Rarity | Slime per second | Starter egg chance |
| --- | --- | ---: | ---: |
| Slimelet | Common | 1 | 60% |
| Glowbug | Uncommon | 3 | 30% |
| Starling | Rare | 6 | 10% |

**Progress is session only.** Leaving or stopping Play resets cash, slime, and
aliens. The farms, slime models, egg stations, and HUD are built automatically
when **Play** starts; they do not appear in the edit scene beforehand. Egg
opening animations and DataStore saving can be added later. No manually
created UI or shop objects are required.

## Pull the update and sync it

1. Stop any current Play test in Roblox Studio.
2. Open **Command Prompt** in your existing project folder. For the original
   setup, run these commands:

   ```bat
   cd /d "%USERPROFILE%\OneDrive\Desktop\alien_lab_roblox"
   git pull --ff-only origin main
   ```

   If Git reports local changes or a branch conflict, keep those changes and
   resolve the message before continuing. Do not reset your project to force
   the pull.

3. If your Rojo server is already running from this folder, it will detect the
   pulled files automatically. Otherwise, start it:

   ```bat
   "%USERPROFILE%\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" serve
   ```

   Leave that window open. Use `rojo serve` instead if Rojo is on your PATH.
   Run only one Rojo server on port **34872**.

4. In Studio, open the **Rojo plugin**, connect to `localhost:34872`, and accept
   the sync changes if prompted. Wait until it shows **Connected**.
5. Check Explorer for the objects below, then press **Play** (not Run) so a
   player and the client UI are created.

## What syncs into Studio

The existing `default.project.json`, service mappings, baseplate, and lighting
settings are preserved.

```text
ReplicatedStorage
  Shared
    AlienData                  ModuleScript: settings and alien definitions
    SlimeModel                 ModuleScript: shared native slime model factory
    Remotes                    Folder: six RemoteEvents
ServerScriptService
  Server                       Script: joins, remotes, and production loop
    LabService                 ModuleScript: private player state and economy
    LabWorld                   ModuleScript: personal farms, pets, and stations
StarterPlayer
  StarterPlayerScripts
    Client                     LocalScript: UI updates and button requests
      LabUI                    ModuleScript: creates the UI
      PetController            ModuleScript: cosmetic slime movement
Workspace (during Play)
  AlienLabWorld
    Farm_<UserId>              One personal farm per player
      Aliens                   Visible models for that player's owned aliens
```

Rojo's `init.server.luau` and `init.client.luau` files turn their directories
into a Script and LocalScript. The other files inside become their children,
which is why the code uses `script:WaitForChild("LabService")` and `"LabUI"`.

## Verify in Play mode

1. The panel shows **Cash: $100**, one alien, and **1 slime / second**.
   Slime starts at zero and grows as the server loop runs. The Roblox player
   list also shows your cash under `leaderstats.Cash`.
   You should spawn at a fenced garden with a green Slimelet roaming inside.
2. Hatch one egg. Cash becomes **$50**, the alien count becomes **2**, and
   **Last hatch** shows the alien's name and rarity. Production increases by
   that alien's rate. A cooldown appears briefly on the hatch button.
   A second visible slime joins your garden. Try the physical egg dispenser
   too: approach the egg on the left and press **E** to hatch.
3. Wait for the cooldown, then hatch again. Cash becomes **$0** and the hatch
   button explains that you need $50. Slime keeps accumulating.
4. Sell your slime. Slime becomes **0**, cash increases by the sold amount,
   and the status line confirms the sale. When cash reaches $50, you can
   hatch again.
   You can also sell at the green tank on the right of the entrance using **E**.
5. Reset your character. The UI and this session's progress remain.
6. Stop Play and start again. The session starts fresh. Open **Output** and
   check for `Alien Lab v0.2 farm server ready`, `Alien Lab v0.2 farm client ready`, and
   no script errors.
7. Optional: start a Studio test with **two players**. Their balances,
   production, and hatch results should be independent.
   Each gets a different farm, and cannot use the other player's stations.

If the panel is missing, confirm Rojo is connected, check the Explorer paths
above, and use **Play** rather than **Run**. If port 34872 is busy, use the
Rojo server that is already running or stop it before starting another.
If `Shared` is empty or new modules are missing after a pull, restart the Rojo
server from this project folder and reconnect the plugin. In **Plugins >
Manage Plugins > Rojo**, its **Script Injection** permission must be allowed.

## Code and settings

Change prices, starting cash, alien rates, hatch weights, or the capacity in
`src/shared/AlienData.luau`. Both server and UI read that module.
Alien body colors are there too. Farm layout and station placement are in
`src/server/LabWorld.luau`; the HUD design is in `src/client/LabUI.luau`.

The server stores the real balances and inventory privately. `leaderstats`
and state snapshots display those balances. A client cannot supply a price,
cash reward, slime amount, or hatch result. Egg requests validate their ID,
cash, capacity, and cooldown before charging and granting without yielding.
All incoming request events have server rate limits, and departing players
are removed from the state and request tables.
Station prompts also check the player's farm ownership, character health,
and distance on the server. Leaving frees that player's farm slot and removes
their farm and pets. Cosmetic wandering runs on the client at up to 30 updates
per second, skips distant farms, and does not control slime production.

| RemoteEvent in `Shared.Remotes` | Direction | Purpose |
| --- | --- | --- |
| RequestState | Client to server | Request the initial snapshot after listeners connect |
| StateUpdated | Server to client | Cash, slime, production, count, cooldown, last alien |
| HatchEgg | Client to server | Request the `"Starter"` egg ID |
| HatchResult | Server to client | Purchase success or failure message and optional alien ID |
| SellSlime | Client to server | Sell all server-owned whole slime; no amount argument |
| ActionResult | Server to client | Sale success or failure message |

## Build a place file (optional)

From the project folder:

```bat
"%USERPROFILE%\Downloads\rojo-7.7.1-windows-x86_64\rojo.exe" build -o alien_lab_roblox.rbxlx
```

Open that file in Studio, connect the Rojo plugin to your running server, and
press Play. More Rojo help: <https://rojo.space/docs/v7/>.
