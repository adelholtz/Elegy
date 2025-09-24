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
        showMessageForSeconds = 7,
        deathHistory = {}, -- Store all death records with timestamps
        externalDeathCount = 0, -- Simple counter for external deaths
        trackerFrame = {
            visible = false,
            position = { x = 100, y = -100 }, -- Default position
            opacity = 0.8, -- Background opacity (0.0 to 1.0)
            size = { width = 280, height = 200 } -- Frame dimensions
        }
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


                   -- ChatFrame1EditBox:SetText("/who Codehoof")
                   -- ChatEdit_SendText(ChatFrame1EditBox)

                    Elegy.QueueDeathNotification( "## TEST MESSAGE: ", "TestPlayer", nameColor, messageColor)
                end,
                order = 31
            },
            spacer2 = {
                type = "description",
                name = "\n|cFFFFD700Death History|r",
                fontSize = "large",
                order = 40
            },
            deathHistoryStats = {
                type = "description",
                name = function()
                    local guildDeaths = #Elegy.db.profile.deathHistory -- Only guild deaths are stored in history now
                    local externalDeaths = Elegy.db.profile.externalDeathCount or 0 -- Use counter for external deaths
                    local totalDeaths = guildDeaths + externalDeaths
                    
                    return string.format("Total Deaths Recorded: |cFFFFFFFF%d|r\nGuild Deaths: |cFF00FF00%d|r\nExternal Deaths: |cFFFF8000%d|r", 
                        totalDeaths, guildDeaths, externalDeaths)
                end,
                fontSize = "medium",
                order = 41
            },
            recentDeaths = {
                type = "description",
                name = function()
                    local recentCount = math.min(10, #Elegy.db.profile.deathHistory)
                    if recentCount == 0 then
                        return "\n|cFFFF0000No guild deaths recorded yet.|r"
                    end
                    
                    local result = "\n|cFFFFD700Recent Guild Deaths (last " .. recentCount .. "):|r\n"
                    
                    -- Show most recent deaths first (only guild deaths are stored now)
                    for i = #Elegy.db.profile.deathHistory, math.max(1, #Elegy.db.profile.deathHistory - recentCount + 1), -1 do
                        local death = Elegy.db.profile.deathHistory[i]
                        local levelText = death.level ~= "Unknown" and " (Level " .. death.level .. ")" or ""
                        local classText = death.class and death.class ~= "Unknown" and " - " .. death.class or ""
                        result = result .. string.format("|cFF00FF00[GUILD]|r %s%s%s - %s\n", 
                            death.name, levelText, classText, death.date)
                    end
                    
                    return result
                end,
                fontSize = "small",
                order = 42
            },
            clearHistoryButton = {
                type = "execute",
                name = "Clear Death History",
                desc = "Clear all stored death records. This action cannot be undone!",
                func = function()
                    -- Simple confirmation using StaticPopup
                    StaticPopup_Show("ELEGY_CLEAR_HISTORY")
                end,
                order = 43
            },
            spacer3 = {
                type = "description",
                name = " ",
                order = 44
            },
            toggleTrackerButton = {
                type = "execute",
                name = function()
                    if Elegy.deathTrackerFrame and Elegy.deathTrackerFrame:IsShown() then
                        return "Hide Death Tracker"
                    else
                        return "Show Death Tracker"
                    end
                end,
                desc = "Toggle the movable death tracker frame on screen. Use /elegyt or /elegytracker commands.",
                func = function()
                    Elegy.ToggleDeathTrackerFrame()
                    -- Refresh the options panel to update button text
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Elegy")
                end,
                order = 45
            },
            spacer4 = {
                type = "description",
                name = "\n|cFFFFD700Tracker Customization|r",
                fontSize = "medium",
                order = 46
            },
            trackerOpacity = {
                type = "range",
                name = "Background Opacity",
                desc = "Adjust the transparency of the death tracker background (0% = invisible, 100% = solid).",
                min = 0.1,
                max = 1.0,
                step = 0.05,
                isPercent = true,
                get = function() return Elegy.db.profile.trackerFrame.opacity end,
                set = function(_, value) 
                    Elegy.db.profile.trackerFrame.opacity = value
                    Elegy.UpdateTrackerFrameStyle()
                end,
                order = 47
            },
            trackerWidth = {
                type = "range",
                name = "Frame Width",
                desc = "Set the width of the death tracker frame in pixels.",
                min = 200,
                max = 500,
                step = 10,
                get = function() return Elegy.db.profile.trackerFrame.size.width end,
                set = function(_, value) 
                    Elegy.db.profile.trackerFrame.size.width = value
                    Elegy.UpdateTrackerFrameSize()
                end,
                order = 48
            },
            trackerHeight = {
                type = "range",
                name = "Frame Height",
                desc = "Set the height of the death tracker frame in pixels.",
                min = 150,
                max = 400,
                step = 10,
                get = function() return Elegy.db.profile.trackerFrame.size.height end,
                set = function(_, value) 
                    Elegy.db.profile.trackerFrame.size.height = value
                    Elegy.UpdateTrackerFrameSize()
                end,
                order = 49
            },
            resetTrackerButton = {
                type = "execute",
                name = "Reset to Defaults",
                desc = "Reset tracker opacity and size to default values.",
                func = function()
                    Elegy.db.profile.trackerFrame.opacity = 0.8
                    Elegy.db.profile.trackerFrame.size.width = 280
                    Elegy.db.profile.trackerFrame.size.height = 200
                    Elegy.UpdateTrackerFrameStyle()
                    Elegy.UpdateTrackerFrameSize()
                    LibStub("AceConfigRegistry-3.0"):NotifyChange("Elegy")
                end,
                order = 50
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
    
    -- Create death tracker frame
    Elegy.CreateDeathTrackerFrame()
    
    -- Register slash command
    self:RegisterChatCommand("elegyt", "ToggleDeathTrackerFrame")
    self:RegisterChatCommand("elegytracker", "ToggleDeathTrackerFrame")
end

-- StaticPopup for clearing death history
StaticPopupDialogs["ELEGY_CLEAR_HISTORY"] = {
    text = "Are you sure you want to clear all death history? This action cannot be undone!",
    button1 = "Yes, Clear All",
    button2 = "Cancel",
    OnAccept = function()
        Elegy.db.profile.deathHistory = {}
        Elegy.db.profile.externalDeathCount = 0
        print("|cFFFFD700Elegy:|r Death history has been cleared.")
        -- Refresh the options panel to update display
        LibStub("AceConfigRegistry-3.0"):NotifyChange("Elegy")
    end,
    timeout = 0,
    whileDead = true,
    hideOnEscape = true,
    preferredIndex = 3,
}

-- Create Death Tracker Frame
Elegy.CreateDeathTrackerFrame = function()
    if Elegy.deathTrackerFrame then
        return -- Frame already exists
    end
    
    -- Get size from database
    local size = Elegy.db.profile.trackerFrame.size
    
    -- Main frame
    local frame = CreateFrame("Frame", "ElegyDeathTrackerFrame", UIParent)
    frame:SetSize(size.width, size.height)
    frame:SetPoint("CENTER", UIParent, "CENTER", 0, 0)
    frame:SetFrameStrata("MEDIUM")
    frame:SetFrameLevel(100)
    frame:EnableMouse(true)
    frame:SetMovable(true)
    frame:SetResizable(true)
    frame:RegisterForDrag("LeftButton")
    frame:SetScript("OnDragStart", frame.StartMoving)
    frame:SetScript("OnDragStop", function(self)
        self:StopMovingOrSizing()
        -- Save position
        local point, _, relativePoint, x, y = self:GetPoint()
        Elegy.db.profile.trackerFrame.position.x = x
        Elegy.db.profile.trackerFrame.position.y = y
    end)
    
    -- Background
    local bg = frame:CreateTexture(nil, "BACKGROUND")
    bg:SetAllPoints(frame)
    bg:SetColorTexture(0, 0, 0, Elegy.db.profile.trackerFrame.opacity)
    frame.background = bg -- Store reference for opacity updates
    
    -- Border
    local border = frame:CreateTexture(nil, "BORDER")
    border:SetAllPoints(frame)
    border:SetColorTexture(0.3, 0.3, 0.3, 1)
    border:SetPoint("TOPLEFT", frame, "TOPLEFT", -1, 1)
    border:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", 1, -1)
    
    -- Title Bar
    local titleBar = CreateFrame("Frame", nil, frame)
    titleBar:SetHeight(20)
    titleBar:SetPoint("TOPLEFT", frame, "TOPLEFT", 0, 0)
    titleBar:SetPoint("TOPRIGHT", frame, "TOPRIGHT", 0, 0)
    
    local titleBg = titleBar:CreateTexture(nil, "BACKGROUND")
    titleBg:SetAllPoints(titleBar)
    titleBg:SetColorTexture(0.2, 0.2, 0.2, 1)
    
    -- Title Text
    local title = titleBar:CreateFontString(nil, "OVERLAY")
    title:SetFont("Fonts\\FRIZQT__.TTF", 12, "OUTLINE")
    title:SetPoint("LEFT", titleBar, "LEFT", 5, 0)
    title:SetText("Elegy Death Tracker")
    title:SetTextColor(1, 0.82, 0, 1) -- Gold color
    
    -- Close Button
    local closeBtn = CreateFrame("Button", nil, titleBar)
    closeBtn:SetSize(16, 16)
    closeBtn:SetPoint("RIGHT", titleBar, "RIGHT", -2, 0)
    closeBtn:SetNormalTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Up")
    closeBtn:SetHighlightTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Highlight")
    closeBtn:SetPushedTexture("Interface\\Buttons\\UI-Panel-MinimizeButton-Down")
    closeBtn:SetScript("OnClick", function()
        Elegy.ToggleDeathTrackerFrame()
    end)
    
    -- Resize Handle
    local resizeHandle = CreateFrame("Button", nil, frame)
    resizeHandle:SetSize(16, 16)
    resizeHandle:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -1, 1)
    resizeHandle:SetNormalTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Up")
    resizeHandle:SetHighlightTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Highlight")
    resizeHandle:SetPushedTexture("Interface\\ChatFrame\\UI-ChatIM-SizeGrabber-Down")
    resizeHandle:EnableMouse(true)
    resizeHandle:RegisterForDrag("LeftButton")
    resizeHandle:SetScript("OnDragStart", function()
        frame:StartSizing("BOTTOMRIGHT")
    end)
    resizeHandle:SetScript("OnDragStop", function()
        frame:StopMovingOrSizing()
        -- Get current size and apply limits
        local width, height = frame:GetSize()
        
        -- Apply size limits manually
        width = math.max(200, math.min(500, width))
        height = math.max(150, math.min(400, height))
        
        -- Set constrained size
        frame:SetSize(width, height)
        
        -- Save size to database
        Elegy.db.profile.trackerFrame.size.width = width
        Elegy.db.profile.trackerFrame.size.height = height
        
        -- Update content text width
        if frame.contentText then
            frame.contentText:SetWidth(frame.content:GetWidth() - 10)
        end
    end)
    -- Note: SetMinResize/SetMaxResize don't exist in Classic Era, using manual limits above
    
    -- Content Frame
    local content = CreateFrame("ScrollFrame", nil, frame)
    content:SetPoint("TOPLEFT", titleBar, "BOTTOMLEFT", 5, -5)
    content:SetPoint("BOTTOMRIGHT", frame, "BOTTOMRIGHT", -5, 5)
    
    -- Content Text
    local contentText = content:CreateFontString(nil, "OVERLAY")
    contentText:SetFont("Fonts\\FRIZQT__.TTF", 10, "OUTLINE")
    contentText:SetPoint("TOPLEFT", content, "TOPLEFT", 0, 0)
    contentText:SetWidth(content:GetWidth() - 10)
    contentText:SetJustifyH("LEFT")
    contentText:SetJustifyV("TOP")
    contentText:SetTextColor(1, 1, 1, 1)
    
    frame.contentText = contentText
    frame.content = content
    Elegy.deathTrackerFrame = frame
    
    -- Update content
    Elegy.UpdateDeathTrackerFrame()
    
    -- Set initial visibility and position
    if Elegy.db.profile.trackerFrame.visible then
        frame:Show()
    else
        frame:Hide()
    end
    
    -- Restore position
    local pos = Elegy.db.profile.trackerFrame.position
    frame:ClearAllPoints()
    frame:SetPoint("CENTER", UIParent, "CENTER", pos.x, pos.y)
end

-- Update Death Tracker Frame Content
Elegy.UpdateDeathTrackerFrame = function()
    if not Elegy.deathTrackerFrame or not Elegy.deathTrackerFrame.contentText then
        return
    end
    
    local guildDeaths = #Elegy.db.profile.deathHistory
    local externalDeaths = Elegy.db.profile.externalDeathCount or 0
    local totalDeaths = guildDeaths + externalDeaths
    
    local content = string.format("|cFFFFD700=== DEATH STATISTICS ===|r\n")
    content = content .. string.format("Total Deaths: |cFFFFFFFF%d|r\n", totalDeaths)
    content = content .. string.format("Guild Deaths: |cFF00FF00%d|r\n", guildDeaths)
    content = content .. string.format("External Deaths: |cFFFF8000%d|r\n\n", externalDeaths)
    
    if guildDeaths > 0 then
        content = content .. "|cFFFFD700=== RECENT GUILD DEATHS ===|r\n"
        local recentCount = math.min(8, guildDeaths)
        
        for i = guildDeaths, math.max(1, guildDeaths - recentCount + 1), -1 do
            local death = Elegy.db.profile.deathHistory[i]
            local levelText = death.level ~= "Unknown" and " (L" .. death.level .. ")" or ""
            local classText = death.class and death.class ~= "Unknown" and " - " .. death.class or ""
            content = content .. string.format("|cFF00FF00%s|r%s%s\n", death.name, levelText, classText)
        end
    else
        content = content .. "|cFFFF0000No guild deaths recorded yet.|r"
    end
    
    Elegy.deathTrackerFrame.contentText:SetText(content)
end

-- Toggle Death Tracker Frame
Elegy.ToggleDeathTrackerFrame = function()
    if not Elegy.deathTrackerFrame then
        Elegy.CreateDeathTrackerFrame()
    end
    
    if Elegy.deathTrackerFrame:IsShown() then
        Elegy.deathTrackerFrame:Hide()
        Elegy.db.profile.trackerFrame.visible = false
        print("|cFFFFD700Elegy:|r Death tracker frame hidden.")
    else
        Elegy.deathTrackerFrame:Show()
        Elegy.db.profile.trackerFrame.visible = true
        Elegy.UpdateDeathTrackerFrame() -- Update content when showing
        print("|cFFFFD700Elegy:|r Death tracker frame shown.")
    end
end

-- Update Death Tracker Frame Style (opacity)
Elegy.UpdateTrackerFrameStyle = function()
    -- Create frame if it doesn't exist
    if not Elegy.deathTrackerFrame then
        Elegy.CreateDeathTrackerFrame()
    end
    
    -- Check if frame and background exist
    if not Elegy.deathTrackerFrame or not Elegy.deathTrackerFrame.background then
        return
    end
    
    -- Update the background opacity
    local opacity = Elegy.db.profile.trackerFrame.opacity
    Elegy.deathTrackerFrame.background:SetColorTexture(0, 0, 0, opacity)
end

-- Update Death Tracker Frame Size
Elegy.UpdateTrackerFrameSize = function()
    -- Create frame if it doesn't exist
    if not Elegy.deathTrackerFrame then
        Elegy.CreateDeathTrackerFrame()
    end
    
    -- Check if frame exists
    if not Elegy.deathTrackerFrame then
        return
    end
    
    local size = Elegy.db.profile.trackerFrame.size
    Elegy.deathTrackerFrame:SetSize(size.width, size.height)
    
    -- Update content text width to match new frame width
    if Elegy.deathTrackerFrame.contentText and Elegy.deathTrackerFrame.content then
        Elegy.deathTrackerFrame.contentText:SetWidth(Elegy.deathTrackerFrame.content:GetWidth() - 10)
    end
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

-- Record death to persistent storage
Elegy.RecordDeath = function(name, level, deathType, class)
    local timestamp = time() -- Unix timestamp
    local deathRecord = {
        name = name,
        level = level or "Unknown",
        class = class or "Unknown",
        deathType = deathType, -- "guild" or "external"
        timestamp = timestamp,
        date = date("%Y-%m-%d %H:%M:%S", timestamp) -- Human readable date
    }
    
    -- Add to death history
    table.insert(Elegy.db.profile.deathHistory, deathRecord)
    
    -- Optional: Limit history size to prevent database bloat (keep last 1000 deaths)
    if #Elegy.db.profile.deathHistory > 1000 then
        table.remove(Elegy.db.profile.deathHistory, 1) -- Remove oldest entry
    end
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
Elegy.PrintDeath = function(name, level)
    -- Get class information
    local class = Elegy.GetPlayerClass(name)
    
    -- Record the death persistently
    Elegy.RecordDeath(name, level, "guild", class)
    
    -- Update death tracker frame
    Elegy.UpdateDeathTrackerFrame()
    
    -- Get selected colors
    local nameColor = Elegy.colors[Elegy.db.profile.selectedNameColor]
    local messageColor = Elegy.colors[Elegy.db.profile.selectedMessageColor]

    alertFrame("## GUILD DEATH detected for player: ", name.." ("..level..")", nameColor, messageColor)
    SendChatMessage(name.." has fallen in battle", "GUILD")
    -- Add small delay before sending o7 to ensure proper message order
    Elegy:ScheduleTimer(function()
        SendChatMessage("o7", "GUILD")
    end, 0.2)
end

-- Handle external (non-guild) death notifications
Elegy.RegisterDeathExternal = function(name)
    -- Just increment the external death counter
    Elegy.db.profile.externalDeathCount = Elegy.db.profile.externalDeathCount + 1
    
    -- Update death tracker frame
    Elegy.UpdateDeathTrackerFrame()
    
    -- Get selected colors
    --local nameColor = Elegy.colors[Elegy.db.profile.selectedNameColor]
    --local messageColor = Elegy.colors[Elegy.db.profile.selectedMessageColor]
    --alertFrame("External Death detected - Total: ", tostring(Elegy.db.profile.externalDeathCount), nameColor, messageColor)
end

-- Event handler for chat messages
Elegy.deathEvent = CreateFrame("Frame")
Elegy.deathEvent:SetScript("OnEvent", function(_, _, text, playerName, _, _, _, _, _, _, channel)
    local name = Elegy.ParseOutPlayerName(text)
    local level = Elegy.ParseOutPlayerLevel(text)
    if channel and channel:lower():find("hardcoredeaths") then
        if name then
            local exists = C_GuildInfo.MemberExistsByName(name)
            if exists then
                Elegy.PrintDeath(name, level)
            else
                Elegy.RegisterDeathExternal(name)
            end
        end
    elseif channel and channel:lower():find("adelholtztest") then
        if name then
            local exists = C_GuildInfo.MemberExistsByName(name)
            if exists then
                Elegy.PrintDeath(name, level)
            else
                Elegy.RegisterDeathExternal(name)
            end
        end
    end
end)

-- Parse player name from death message
Elegy.ParseOutPlayerName = function(text)
    return text:match("%[([^%]]+)%]")
end

Elegy.ParseOutPlayerLevel = function(text)
    return text:match("They were level (%d+)")
end

-- Get player class information
Elegy.GetPlayerClass = function(name)
    if not name then return "Unknown" end

    -- Try to get class from guild info (most reliable for guild members)
    local numMembers = GetNumGuildMembers()
    if numMembers and numMembers > 0 then
        for i = 1, numMembers do
            local guildName, _, _, level, class = GetGuildRosterInfo(i)
            if guildName == name then
                return class or "Unknown"
            end
        end
    end

    return "Unknown"
end

-- Register for chat message events
Elegy.deathEvent:RegisterEvent("CHAT_MSG_CHANNEL")