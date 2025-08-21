-- Extra Keybinds Mod - Sit on Ground Feature
-- Allows players to sit down on the ground using a keybind

require "TimedActions/ISSitOnGround"
require "EKModOptions"

-- Main function: makes the player sit on the ground
local function sitOnGround()
    local player = getPlayer()
    if not player then return end
    
    -- Check if already sitting
    if player:isSitOnGround() then
        player:Say("Already sitting")
        return
    end
    
    -- Check if in vehicle
    if player:getVehicle() then 
        player:Say("Can't sit while in vehicle")
        return 
    end
    
    -- Check if has timed actions
    if player:hasTimedActions() then 
        player:Say("Busy with other actions")
        return 
    end
    
    -- Check if player is idle (required for sitting)
    if player:getCurrentActionContextStateName() ~= "idle" then
        player:Say("Must be idle to sit")
        return
    end
    
    -- Create and add the sitting action
    local sitAction = ISSitOnGround:new(player)
    ISTimedActionQueue.add(sitAction)
    
    player:Say("Sitting down")
end

-- Key handler: checks if the sitting key was pressed
local function sitKeyHandler(key)
    if isGamePaused() then return end
    if key == nil then return end

    -- Use the keybind from mod options
    local configuredKey = ExtraKeybindsSettings and ExtraKeybindsSettings.getSitOnGroundKeybind and ExtraKeybindsSettings.getSitOnGroundKeybind()
    if configuredKey and configuredKey > 0 and key == configuredKey then
        sitOnGround()
    end
end

-- Register the hotkey event
Events.OnCustomUIKey.Add(sitKeyHandler)
