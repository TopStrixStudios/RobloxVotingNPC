# Multi-Idea Voting NPC System

## Easy Cloning for Multiple Ideas

This enhanced system allows you to have multiple voting NPCs in your game, each with:
- Different ideas/proposals
- Separate vote counts
- Independent data storage
- Unique titles and descriptions

## How to Set Up Multiple NPCs

### Step 1: Install the Scripts

1. Download the server script: [VotingNPC_MultiIdea.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPC_MultiIdea.lua)
2. Download the client script: [VotingNPCClient_MultiIdea.client.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPCClient_MultiIdea.client.lua)
3. Place the client script in StarterPlayer → StarterPlayerScripts (rename to VotingNPCClient.client.lua)

### Step 2: Create Your First NPC

1. Create an NPC model with a PrimaryPart (usually HumanoidRootPart)
2. Place the server script inside the NPC model
3. Add these attributes to the NPC model:
   - `NPCId`: A unique identifier (e.g., "MusicAreas")
   - `IdeaTitle`: The title of your idea (e.g., "אזורים עם ווייבים שונים")
   - `IdeaDescription`: A description of your idea

### Step 3: Clone for Additional Ideas

To create more NPCs with different ideas:
1. Duplicate the NPC model
2. Change the attributes on the new model:
   - `NPCId`: A different unique identifier (e.g., "NewSkins")
   - `IdeaTitle`: The title for this idea
   - `IdeaDescription`: The description for this idea

That's it! Each NPC will automatically:
- Use its own separate data storage
- Display its own title and vote counts
- Track votes independently

## Setting Attributes in Studio

To set attributes on an NPC model:
1. Select the model in the Explorer
2. Open the Properties panel
3. Click the "Attributes" section
4. Add the required attributes:

| Attribute Name | Type | Example Value |
|----------------|------|---------------|
| NPCId | String | "MusicAreas" |
| IdeaTitle | String | "אזורים עם ווייבים שונים" |
| IdeaDescription | String | "הוספת אזורים שונים עם מוזיקות שונות..." |

## Example Ideas

Here are some example ideas you could use:

### Music Areas NPC
- **NPCId**: "MusicAreas"
- **IdeaTitle**: "אזורים עם ווייבים שונים"
- **IdeaDescription**: "הוספת אזורים שונים עם מוזיקות שונות: אזור לשינה, אזור לריכוז, אזור לעבודה, אזור לכיף עם חברים ועוד."

### New Skins NPC
- **NPCId**: "NewSkins"
- **IdeaTitle**: "סקינים חדשים לדמויות"
- **IdeaDescription**: "הוספת סקינים חדשים לדמויות במשחק, כולל תלבושות עונתיות, אביזרים מיוחדים, ואפשרויות התאמה אישית."

### Game Modes NPC
- **NPCId**: "GameModes"
- **IdeaTitle**: "מצבי משחק חדשים"
- **IdeaDescription**: "הוספת מצבי משחק חדשים כמו תחרויות, משימות קבוצתיות, ואירועים מיוחדים שמתרחשים מדי פעם."

## How It Works

The system uses these key features:

1. **Unique DataStore Keys**: Each NPC saves its data with a unique key based on its NPCId
2. **Separate RemoteEvent Folders**: Each NPC has its own folder of RemoteEvents
3. **Attribute-Based Configuration**: All settings are stored as attributes on the model
4. **Dynamic Client Connections**: The client script automatically connects to all NPCs

## Advanced Features

- **Auto-Generated IDs**: If you don't set an NPCId, one will be generated automatically
- **Default Content**: If title/description aren't set, defaults will be used
- **Self-Repair**: If displays or prompts disappear, they'll be recreated
- **Continuous Updates**: Vote displays update in real-time
- **Data Persistence**: All vote data is saved between server restarts

## Troubleshooting

If you encounter issues:
1. Make sure each NPC has a unique NPCId
2. Verify that all NPCs have a PrimaryPart
3. Check that Studio's API Services are enabled for DataStore
4. Look for error messages in the Output window

## Credits

Created by TopStrixStudios