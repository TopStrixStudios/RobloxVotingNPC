# Roblox Voting NPC System

An interactive NPC system that allows players to vote on game ideas using the "E" key with ProximityPrompt.

## Features

- NPC interaction using ProximityPrompt (E key)
- Beautiful voting UI with animated opening/closing
- Persistent vote tracking
- Prevention of duplicate votes
- Holographic vote counter display above the NPC
- Hebrew text support

## Installation Instructions

### 1. Server Script Setup

1. Place the `VotingNPC.lua` script inside your NPC model in Workspace
2. Rename the script to exactly "VotingNPC" (no extension)

### 2. Client Script Setup

1. Place the `VotingNPCClient.client.lua` script in `StarterPlayer/StarterPlayerScripts`

### 3. NPC Model Requirements

- Your NPC model must have:
  - A Humanoid
  - A HumanoidRootPart or other primary part
  - All parts properly connected

### 4. Test Your NPC

1. Make sure your NPC model has a PrimaryPart set (right-click → Set Primary Part)
2. Ensure the PrimaryPart is anchored (Anchored = true)
3. Run the game and approach your NPC
4. Press "E" when the prompt appears
5. Vote on the idea
6. See your vote count above the NPC

## Troubleshooting

If you encounter issues:

1. Check the Output window for error messages
2. Make sure both scripts are in the correct locations
3. Verify that your NPC model is properly configured
4. Ensure the script is named exactly "VotingNPC" (no extension)

## Files

- `VotingNPC.lua` - Script to place inside your NPC model
- `VotingNPCClient.client.lua` - Client script for handling UI

## Direct Download Links

- [VotingNPC.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPC.lua)
- [VotingNPCClient.client.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPCClient.client.lua)