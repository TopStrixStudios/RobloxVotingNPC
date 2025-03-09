# DataStore Setup for Voting NPC Testing in Studio

## Essential Setup for Testing with DataStore

When testing the Voting NPC in Roblox Studio, you must enable the DataStore service or votes won't persist properly. This guide shows you how to set up Studio correctly.

## Step 1: Enable API Services in Studio

1. Open your game in Roblox Studio
2. Click on the "Game Settings" button in the Home tab
3. Select the "Security" tab
4. Check the box for "Enable Studio Access to API Services"
5. Click "Save" to apply the changes

![Enable API Services](https://i.imgur.com/8o5bV9Q.png)

## Step 2: Verify "table.count" Function

The script uses `table.count` which may not be available in some Roblox Studio versions. You might need this small addition at the top of the script:

```lua
-- Add table.count if it doesn't exist
if not table.count then
    table.count = function(t)
        local count = 0
        for _ in pairs(t) do count = count + 1 end
        return count
    end
end
```

## Step 3: Install the Latest Script

1. Download [VotingNPC_OrderFix.lua](https://raw.githubusercontent.com/TopStrixStudios/RobloxVotingNPC/main/VotingNPC_OrderFix.lua)
2. Place it **INSIDE your NPC model** (not in ServerScriptService)
3. Rename it to just `VotingNPC` (remove _OrderFix)
4. Make sure your NPC model has a PrimaryPart (HumanoidRootPart)

## How to Test Properly

1. Start Studio in Play mode (press F5)
2. Click the NPC and vote
3. Stop the game (Shift+F5)
4. Start the game again (F5)
5. Verify your vote is still shown and you can't immediately vote again

## Common Issues and Solutions

### "Attempt to call a nil value" Error

If you see this error, you need to use the newest script version (VotingNPC_OrderFix.lua) which fixes the function ordering.

### "DataStore request was rejected" Error

This means you haven't enabled API Services in Studio. Follow Step 1 above.

### Votes Not Saving Between Sessions

1. Make sure API Services are enabled
2. Ensure you're using the latest script with correct DataStore implementation
3. Check that you're running the server properly (use Play mode, not Run mode)

### Votes Reset After Server Restart

This indicates the DataStore isn't properly saving or loading. Make sure:
1. You have API Services enabled
2. Your place is properly saved
3. You have the correct permissions in Studio
4. Any custom API key settings are correct

## Need More Help?

If you continue to have issues, check:
1. The output console for specific error messages
2. That you're using the latest script version
3. That all script requirements are properly set up

For advanced DataStore troubleshooting, refer to the [Roblox Developer Documentation](https://developer.roblox.com/en-us/articles/Data-store).