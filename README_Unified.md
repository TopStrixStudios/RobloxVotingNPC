# Roblox Voting NPC System

This is a complete system for implementing an interactive voting NPC in Roblox. Players can vote on an idea by clicking the NPC and choosing to like or dislike it.

## New Unified Version

This is the **UNIFIED** version of the voting NPC system, which fixes multiple issues:

- ✅ Fixed hologram text duplication issues
- ✅ Added 10-second cooldown for changing votes
- ✅ Limited hologram visibility to 7 studs
- ✅ Self-repair system that recreates the display if it gets removed
- ✅ Proper cleanup of votes when players leave
- ✅ Prevention of duplicate scripts running simultaneously

## Installation Instructions

### 1. Setup the NPC Model

1. Create an NPC model in your game (can be any humanoid or object)
2. Make sure the model has a **PrimaryPart** (usually Torso/HumanoidRootPart)
3. The NPC model should be in Workspace

### 2. Install the Server Script

1. Download `VotingNPC_Unified.lua` from this repository
2. Insert it **INSIDE the NPC model** (not in ServerScriptService)
3. Make sure no other voting NPC scripts are present in the model

### 3. Install the Client Script

1. Download `VotingNPCClient_Unified.client.lua` from this repository
2. Rename it to just `VotingNPCClient.client.lua` (remove "Unified" from name)
3. Insert it into `StarterPlayer/StarterPlayerScripts`

### 4. IMPORTANT: Clean Up Old Scripts

If you've been testing earlier versions of this system:

1. Delete any existing voting NPC scripts from ServerScriptService
2. Delete any existing voting NPC client scripts from StarterPlayerScripts
3. Remove any extra voting scripts from your NPC model
4. The new script will automatically disable any duplicate scripts it finds in the NPC model

## How It Works

1. Players click on the NPC to see a voting UI
2. They can vote "Like" or "Dislike" on the proposed idea
3. Their vote appears as a hologram above the NPC's head
4. Players can change their vote after a 10-second cooldown
5. The system tracks votes and prevents exploits
6. When players leave, their votes are automatically removed

## Customization

You can modify these values at the top of the server script:

```lua
-- CONFIGURATION
local VOTE_COOLDOWN = 10 -- Seconds before a player can change their vote
local DISPLAY_RADIUS = 7 -- Studs radius for hologram visibility
local HOLOGRAM_HEIGHT = 5 -- Height above NPC head for the vote display
```

## Troubleshooting

If you experience any issues:

1. Make sure the NPC model has a PrimaryPart
2. Check that you've placed the scripts in the correct locations
3. Check the output console for any error messages
4. Make sure you've removed all old/duplicate voting scripts
5. The server script should be inside the NPC model, not in ServerScriptService

## Credits

Created by TopStrixStudios