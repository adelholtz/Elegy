-- Initialize the Elegy table
Elegy = LibStub("AceAddon-3.0"):NewAddon("Elegy", "AceConsole-3.0", "AceTimer-3.0")

-- Color codes for chat messages
Elegy.colors = {
    RED = "|cFFFF0000",
    GREEN = "|cFF00FF00",
    BLUE = "|cFF0000FF",
    YELLOW = "|cFFFFFF00",
    ORANGE = "|cFFFF8000",
    PURPLE = "|cFF8000FF",
    WHITE = "|cFFFFFFFF",
    GRAY = "|cFF808080",
    PINK = "|cFFFF69B4",
    CYAN = "|cFF00FFFF",
    RESET = "|r"
}

-- Queue system for death notifications
Elegy.deathQueue = {}
Elegy.isShowingAlert = false

-- Database defaults
local defaults = {
    profile = {
        messageDestination = "GUILD", -- or "WHISPER"
        selectedNameColor = "WHITE",
        selectedMessageColor = "PURPLE",
        showMessageForSeconds = 7
    }
}

-- Create options panel configuration
Elegy.CreateOptions = function()
    local options = {
        type = "group",
        args = {
            preview = {
                type = "description",
               -- name = "Color Preview",
                name = function()
                    local nameColor = Elegy.colors[Elegy.db.profile.selectedNameColor] or Elegy.colors.WHITE
                    local messageColor = Elegy.colors[Elegy.db.profile.selectedMessageColor] or Elegy.colors.PURPLE
                    local reset = Elegy.colors.RESET
                    return messageColor .. "## GUILD DEATH detected for player: " .. nameColor .. "ExamplePlayer" .. reset
                end,
                fontSize = "medium",
                order = 1
            },
            spacer1 = {
                type = "description",
                name = " ",
                order = 2
            },
            messageDestination = {
                type = "select",
                name = "Message Destination",
                desc = "Select where to send the messages (Guild or Whisper).",
                values = {
                    GUILD = "Guild",
                    WHISPER = "Whisper"
                },
                get = function() return Elegy.db.profile.messageDestination end,
                set = function(_, value) Elegy.db.profile.messageDestination = value end,
                order = 10
            },
            showMessageForSeconds = {
                type = "range",
                name = "Time (seconds)",
                desc = "Select the time (in seconds) the message is shown on screen.",
                min = 1,
                max = 20,
                step = 1,
                get = function() return Elegy.db.profile.showMessageForSeconds end,
                set = function(_, value) Elegy.db.profile.showMessageForSeconds = value end,
                order = 15
            },
            nameColor = {
                type = "select",
                name = "Name Color",
                desc = "Select the color for player names in messages.",
                values = {
                    RED = Elegy.colors.RED.."Red"..Elegy.colors.RESET,
                    GREEN = Elegy.colors.GREEN.."Green"..Elegy.colors.RESET,
                    BLUE = Elegy.colors.BLUE.."Blue"..Elegy.colors.RESET,
                    YELLOW = Elegy.colors.YELLOW.."Yellow"..Elegy.colors.RESET,
                    ORANGE = Elegy.colors.ORANGE.."Orange"..Elegy.colors.RESET,
                    PURPLE = Elegy.colors.PURPLE.."Purple"..Elegy.colors.RESET,
                    WHITE = Elegy.colors.WHITE.."White"..Elegy.colors.RESET,
                    CYAN = Elegy.colors.CYAN.."Cyan"..Elegy.colors.RESET,
                    PINK = Elegy.colors.PINK.."Pink"..Elegy.colors.RESET
                },
                get = function() return Elegy.db.profile.selectedNameColor end,
                set = function(_, value) 
                    Elegy.db.profile.selectedNameColor = value
                    -- Refresh the options panel to update preview
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Elegy")
                end,
                order = 20
            },
            messageColor = {
                type = "select",
                name = "Message Color",
                desc = "Select the color for death messages.",
                values = {
                    RED = Elegy.colors.RED.."Red"..Elegy.colors.RESET,
                    GREEN = Elegy.colors.GREEN.."Green"..Elegy.colors.RESET,
                    BLUE = Elegy.colors.BLUE.."Blue"..Elegy.colors.RESET,
                    YELLOW = Elegy.colors.YELLOW.."Yellow"..Elegy.colors.RESET,
                    ORANGE = Elegy.colors.ORANGE.."Orange"..Elegy.colors.RESET,
                    PURPLE = Elegy.colors.PURPLE.."Purple"..Elegy.colors.RESET,
                    WHITE = Elegy.colors.WHITE.."White"..Elegy.colors.RESET,
                    CYAN = Elegy.colors.CYAN.."Cyan"..Elegy.colors.RESET,
                    PINK = Elegy.colors.PINK.."Pink"..Elegy.colors.RESET
                },
                get = function() return Elegy.db.profile.selectedMessageColor end,
                set = function(_, value) 
                    Elegy.db.profile.selectedMessageColor = value
                    -- Refresh the options panel to update preview
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Elegy")
                end,
                order = 30
            },
            testButton = {
                type = "execute",
                name = "Test Alert",
                desc = "Show a test death notification with current color settings.",
                func = function()
                    local nameColor = Elegy.colors[Elegy.db.profile.selectedNameColor]
                    local messageColor = Elegy.colors[Elegy.db.profile.selectedMessageColor]
                    Elegy.QueueDeathNotification( "## TEST MESSAGE: ", "TestPlayer", nameColor, messageColor)
                end,
                order = 31
            }
        }
    }
    return options
end

-- Initialize addon
function Elegy:OnInitialize()
    -- Initialize the database using LibStub
    self.db = LibStub("AceDB-3.0"):New("ElegyDB", defaults, true)

    -- Register options
    LibStub("AceConfig-3.0"):RegisterOptionsTable("Elegy", Elegy.CreateOptions())
    self.optionsFrame = LibStub("AceConfigDialog-3.0"):AddToBlizOptions("Elegy", "Elegy")
end

-- [Cimt] has been slain by a Zombie in Skullcrusher Valley. They were level 15
-- [Test] has been slain by a Zombie in Skullcrusher Valley. They were level 15

-- Process the death queue - shows notifications one after another
Elegy.ProcessDeathQueue = function()
    if Elegy.isShowingAlert or #Elegy.deathQueue == 0 then
        return
    end
    
    Elegy.isShowingAlert = true
    local notification = table.remove(Elegy.deathQueue, 1) -- Get first item and remove it
    
    -- Hide existing frame if it exists and is visible
    if Elegy.achievement_alert_frame and Elegy.achievement_alert_frame:IsShown() then
        Elegy.achievement_alert_frame:Hide()
    end
    
    local reset = Elegy.colors.RESET

    -- Frame positioning
    local static_offset_x = 0
    local static_offset_y = 250
    local modified_offset_x = 0
    local modified_offset_y = 0

    -- Create achievement-style alert frame
    Elegy.achievement_alert_frame = CreateFrame("frame")
    Elegy.achievement_alert_frame:SetHeight(200)
    Elegy.achievement_alert_frame:SetWidth(400)
    Elegy.achievement_alert_frame:SetPoint(
        "CENTER",
        UIParent,
        static_offset_x + modified_offset_x,
        static_offset_y + modified_offset_y
    )

    -- Create background texture with opacity
    local background = Elegy.achievement_alert_frame:CreateTexture(nil, "BACKGROUND")
    background:SetColorTexture(0, 0, 0, 0.7) -- Black background with 70% opacity
    background:SetPoint("CENTER", 0, -55)
    background:SetWidth(360)
    background:SetHeight(50)

    -- Create text display
    local text = Elegy.achievement_alert_frame:CreateFontString(nil, "OVERLAY")
    text:SetFont("Interface\\AddOns\\Hardcore\\Media\\BreatheFire.ttf", 20, "")
    text:SetPoint("CENTER", 0, -55)
    text:SetText(notification.messageColor .. notification.msg .. notification.nameColor .. notification.name .. reset)
    text:SetWidth(350)

    -- Show the frame
    Elegy.achievement_alert_frame:Show()

    -- Hide the frame after the specified duration in seconds and process next in queue
    Elegy:ScheduleTimer(function()
        if Elegy.achievement_alert_frame then
            Elegy.achievement_alert_frame:Hide()
        end
        Elegy.isShowingAlert = false
        Elegy.ProcessDeathQueue() -- Process next notification
    end, Elegy.db.profile.showMessageForSeconds)
end

-- Add notification to queue
Elegy.QueueDeathNotification = function(msg, name, nameColor, messageColor)
    table.insert(Elegy.deathQueue, {
        msg = msg,
        name = name,
        nameColor = nameColor,
        messageColor = messageColor
    })
    Elegy.ProcessDeathQueue()
end

-- Create and display alert frame (now uses queue system)
local alertFrame = function(msg, name, nameColor, messageColor)
    Elegy.QueueDeathNotification(msg, name, nameColor, messageColor)
end

-- Handle guild member death notifications
Elegy.PrintDeath = function(name)
    -- Get selected colors
    local nameColor = Elegy.colors[Elegy.db.profile.selectedNameColor]
    local messageColor = Elegy.colors[Elegy.db.profile.selectedMessageColor]

    alertFrame("## GUILD DEATH detected for player: ", name, nameColor, messageColor)
    SendChatMessage(name.." has fallen in battle", "GUILD")
    SendChatMessage("o7", "GUILD")
end

-- Handle external (non-guild) death notifications
Elegy.PrintDeathExternal = function(name)
    -- Get selected colors
    local nameColor = Elegy.colors[Elegy.db.profile.selectedNameColor]
    local messageColor = Elegy.colors[Elegy.db.profile.selectedMessageColor]
    alertFrame("External Death detected for player: ", name, nameColor, messageColor)
end

-- Event handler for chat messages
Elegy.deathEvent = CreateFrame("Frame")
Elegy.deathEvent:SetScript("OnEvent", function(_, _, text, playerName, _, _, _, _, _, _, channel)
    if channel and channel:lower():find("hardcoredeaths") then
        local name = Elegy.ParseOutPlayerName(text)
        if name then
            local exists = C_GuildInfo.MemberExistsByName(name)
            if exists then
                Elegy.PrintDeath(name)
            --else
               -- Elegy.PrintDeathExternal(name)
            end
        end
    elseif channel and channel:lower():find("adelholtztest") then
        local name = Elegy.ParseOutPlayerName(text)
        if name then
            local exists = C_GuildInfo.MemberExistsByName(name)
            if exists then
                Elegy.PrintDeath(name)
            else
                Elegy.PrintDeathExternal(name)
            end
        end
    end
end)

-- Parse player name from death message
Elegy.ParseOutPlayerName = function(text)
    return text:match("%[([^%]]+)%]")
end

-- Register for chat message events
Elegy.deathEvent:RegisterEvent("CHAT_MSG_CHANNEL")