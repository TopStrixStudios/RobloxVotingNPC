# Enhanced Roblox Voting NPC System

An improved interactive NPC system that allows players to vote on game ideas and change their votes later. Fixed issues with duplicating displays and added anti-exploit features.

## Enhanced Features

- **Vote Changing**: Players can now change their vote from like to dislike or vice versa
- **No Duplicating Displays**: Fixed the issue where multiple hologram displays would appear
- **Anti-Exploit Protections**:
  - Rate limiting to prevent spam
  - Vote verification to prevent inconsistencies
  - Player validation to prevent fake submissions
  - Periodic automatic vote count verification
- **Improved User Interface**:
  - Shows current vote status
  - Highlights selected vote option
  - Smooth animations for better feedback

## Installation Instructions

### 1. Server Script Setup

1. Place the `VotingNPC_Enhanced.lua` script inside your NPC model in Workspace
2. Rename the script to exactly "VotingNPC" (no extension)

### 2. Client Script Setup

1. Place the `VotingNPCClient_Enhanced.client.lua` script in `StarterPlayer/StarterPlayerScripts`

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
6. Approach again later to change your vote if desired

## Fixes and Improvements

### 1. Duplicating Hologram Fix
The system now properly removes old hologram displays before creating new ones, ensuring only one display per NPC.

### 2. Vote Changing Implementation
Players' votes are now stored as BoolValue objects, allowing them to change their vote. The system updates vote counts appropriately when a vote is changed.

### 3. Anti-Exploit Measures
- Time-based cooldowns to prevent rapid interactions
- Validation of player existence and connections
- Periodic automatic verification of vote counts
- Protection against duplicate voting

## Direct Download Links

- [VotingNPC_Enhanced.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPC_Enhanced.lua)
- [VotingNPCClient_Enhanced.client.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPCClient_Enhanced.client.lua)