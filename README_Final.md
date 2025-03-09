# Final Voting NPC System with Data Persistence

## Complete Final Version

This is the **FINAL** version of the Voting NPC system with all issues fixed and enhanced features:

- ✅ **Visible fixed-size hologram** that doesn't scale with distance
- ✅ **Vote data persistence** between server restarts
- ✅ **Centered UI** for better user experience
- ✅ **10-second cooldown** for changing votes
- ✅ **Clear emoji display** with 👍 and 👎 counts

## Installation Instructions

### Step 1: Clean Up Everything

Remove ALL existing voting scripts from:
- The NPC model
- StarterPlayerScripts
- ServerScriptService
- Any other locations

### Step 2: Install the Server Script

1. Download [VotingNPC_Final.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPC_Final.lua)
2. Place it **INSIDE your NPC model** (not in ServerScriptService)
3. Rename it to just `VotingNPC` (remove _Final)
4. Make sure your NPC model has a PrimaryPart (HumanoidRootPart)

### Step 3: Install the Client Script

1. Download [VotingNPCClient_Final.client.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPCClient_Final.client.lua)
2. Place it in **StarterPlayer → StarterPlayerScripts**
3. Rename it to just `VotingNPCClient.client.lua` (remove _Final)

## Important Notes on Data Persistence

The script now uses DataStore to save vote counts between server restarts. Here's how it works:

1. Vote counts are saved automatically:
   - Every 60 seconds
   - When a vote changes
   - When the server shuts down

2. Player votes are persistent:
   - When a player leaves, their vote still counts
   - When they rejoin, they'll need to wait for cooldown if they try to vote again

3. Each NPC has its own data store key:
   - If you have multiple NPCs, give each an attribute called "NPCId" with a unique name
   - Example: `npcModel:SetAttribute("NPCId", "LobbyNPC1")`

## Hologram Display

The hologram has been completely redesigned:
- Fixed size that doesn't scale with distance
- Clear background with white outline
- Visible up to 25 studs away
- Updates automatically every 0.5 seconds
- Self-repairs if it disappears

## UI Improvements

The voting UI has been improved:
- Perfectly centered on the screen
- Better animations
- Highlights the player's current vote
- Shows clear feedback on vote success

## Customization

You can easily customize these settings at the top of the server script:

```lua
-- CONFIGURATION
local VOTE_COOLDOWN = 10 -- Seconds before a player can change their vote
local DISPLAY_VISIBILITY_DISTANCE = 25 -- Maximum distance to see the display (studs)
local HOLOGRAM_HEIGHT = 3.5 -- Height above NPC
local UPDATE_INTERVAL = 0.5 -- How often to refresh the display
local AUTO_SAVE_INTERVAL = 60 -- How often to auto-save vote data (seconds)
```

## Troubleshooting

If you have any issues:

1. Make sure you've completely removed all old scripts
2. Check the Output console for any error messages
3. Verify the NPC model has a PrimaryPart
4. If you're testing in Studio, enable Studio Access to API Services for DataStore

## Credits

Created by TopStrixStudios