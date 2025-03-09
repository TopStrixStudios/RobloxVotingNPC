# Enhanced Voting NPC System

## Latest Improvements

The Enhanced Voting NPC system includes several major improvements:

1. **Hologram Display with Title**
   - Added title above the like/dislike count
   - Enhanced visibility and appearance
   - Updated content about different areas with different vibes

2. **Improved "E" Key Interaction**
   - Uses ProximityPrompt for modern interaction
   - Shows title in the prompt text
   - Easy to see and use on mobile and desktop

3. **Redesigned Cooldown Notification**
   - Wide and slim notification at the top of the screen
   - Single line text for better readability
   - Smoother animations

4. **Customizable Content**
   - Easy to change the idea title and description
   - Shared between server and client
   - Hebrew text support throughout

## Installation Instructions

### Step 1: Install the Server Script

1. Download [VotingNPC_Enhanced.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPC_Enhanced.lua)
2. Place it INSIDE your NPC model
3. Rename it to just "VotingNPC"
4. Make sure the NPC model has a PrimaryPart

### Step 2: Install the Client Script

1. Download [VotingNPCClient_Enhanced.client.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPCClient_Enhanced.client.lua)
2. Place it in StarterPlayer → StarterPlayerScripts
3. Rename it to "VotingNPCClient.client.lua"

### Step 3: Test in Studio

1. Make sure "API Services" are enabled in Studio settings
2. Enter Play mode to test the system
3. Approach the NPC and press E to interact

## Customizing the Idea Content

To change the idea content, edit these lines at the top of the server script:

```lua
-- IDEA CONTENT
local IDEA_TITLE = "אזורים עם ווייבים שונים" -- Different areas with different vibes
local IDEA_DESCRIPTION = "הוספת אזורים שונים עם מוזיקות שונות: אזור לשינה, אזור לריכוז, אזור לעבודה, אזור לכיף עם חברים ועוד."
-- Adding different areas with different music: areas for sleep, focus, work, fun with friends, and more
```

## Other Configuration Options

Additional settings you can adjust:

```lua
-- CONFIGURATION
local VOTE_COOLDOWN = 10 -- Seconds before a player can change their vote
local DISPLAY_VISIBILITY_DISTANCE = 25 -- Maximum distance to see the display (studs)
local HOLOGRAM_HEIGHT = 3.5 -- Height above NPC
local UPDATE_INTERVAL = 0.5 -- How often to refresh the display
local AUTO_SAVE_INTERVAL = 60 -- How often to auto-save vote data (seconds)
local INTERACTION_DISTANCE = 8 -- How close player needs to be to interact (studs)
```

## Features Maintained from Previous Versions

- Full data persistence between server restarts
- 10-second cooldown for changing votes
- Anti-exploit vote verification
- Self-repair system for the display
- Player vote tracking

## Troubleshooting

If you encounter any issues:

1. Make sure you've removed all previous voting NPC scripts
2. Check that Studio's API Services are enabled for DataStore
3. Verify the NPC model has a PrimaryPart
4. Check the Output window for error messages

## Credits

Created by TopStrixStudios