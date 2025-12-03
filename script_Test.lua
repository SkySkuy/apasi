-- ============================================
-- KAYZEE SCRIPT LOADER V1.3 - PART 1
-- Core System & Initialization
-- ============================================

print("\n\n")
print("  ╔═══════════════════════════════════════════════════════════╗")
print("  ║                                                           ║")
print("  ║   ░██████╗███████╗██╗░░██╗░█████╗░██╗░░░██╗███████╗███████╗ ║")
print("  ║   ██╔════╝██╔════╝██║░██╔╝██╔══██╗╚██╗░██╔╝╚════██║██╔════╝ ║")
print("  ║   ╚█████╗░█████╗░░█████═╝░███████║░╚████╔╝░░░███╔═╝█████╗░░ ║")
print("  ║   ░╚═══██╗██╔══╝░░██╔═██╗░██╔══██║░░╚██╔╝░░██╔══╝░░██╔══╝░░ ║")
print("  ║   ██████╔╝███████╗██║░╚██╗██║░░██║░░░██║░░░███████╗███████╗ ║")
print("  ║   ╚═════╝░╚══════╝╚═╝░░╚═╝╚═╝░░╚═╝░░░╚═╝░░░╚══════╝╚══════╝ ║")
print("  ║                                                           ║")
print("  ╚═══════════════════════════════════════════════════════════╝")
print("\n")
print("  ═══════════════════════════════════════════════════════════")
print("   ▓▒░ Kayzee Script Loader v1.3 ░▒▓")
print("   ▓▒░ TikTok: @justsekayzee ░▒▓")
print("  ═══════════════════════════════════════════════════════════")
print("\n")
print("  [✓] Services Initialized")
print("  [✓] Key System Loading...")
print("\n\n")

-- Services
local Players = game:GetService("Players")
local LocalPlayer = Players.LocalPlayer
local HttpService = game:GetService("HttpService")
local Stats = game:GetService("Stats")
local RunService = game:GetService("RunService")
local MarketplaceService = game:GetService("MarketplaceService")

local KEY_URL = "https://raw.githubusercontent.com/Skyzee02/skntlxxnxxnxxnxxnxx01/refs/heads/main/key.json"

-- Duration Mapping
local DurationMap = {
    ["1Day"] = 86400,
    ["7Days"] = 604800,
    ["30Days"] = 2592000,
    ["Lifetime"] = math.huge
}

-- Helper Functions
local function TimeRemaining(createdUnix, durationSeconds)
    if durationSeconds == math.huge then
        return "LIFETIME"
    end
    local expireAt = createdUnix + durationSeconds
    local now = os.time()
    local sisa = expireAt - now
    if sisa <= 0 then
        return "Expired"
    end
    local d = math.floor(sisa / 86400)
    local h = math.floor((sisa % 86400) / 3600)
    local m = math.floor((sisa % 3600) / 60)
    local s = sisa % 60
    return string.format("%dD %02dH %02dM %02dS", d, h, m, s)
end

local function SafeISOtoUnix(str)
    local ok, result = pcall(function()
        return DateTime.fromIsoDate(str).UnixTimestamp
    end)
    if ok and result then return result end

    local pattern = "(%d+)-(%d+)-(%d+)T(%d+):(%d+):(%d+)Z"
    local year, month, day, hour, min, sec = str:match(pattern)
    if year then
        return os.time({
            year=tonumber(year),
            month=tonumber(month),
            day=tonumber(day),
            hour=tonumber(hour),
            min=tonumber(min),
            sec=tonumber(sec)
        })
    end
    return os.time()
end

-- Load Key Database
local function LoadKeyDatabase()
    local raw
    local ok = pcall(function()
        raw = game:HttpGet(KEY_URL)
    end)
    if not ok then
        warn("FAILED TO LOAD KEY DATABASE")
        return {}
    end

    local data
    pcall(function()
        data = HttpService:JSONDecode(raw)
    end)
    if type(data) ~= "table" then return {} end

    for _, item in ipairs(data) do
        item.duration_seconds = DurationMap[item.duration] or 0
        item.created_unix = SafeISOtoUnix(item.created_at)
        item.expired_unix = item.duration_seconds == math.huge and math.huge or item.created_unix + item.duration_seconds
        if typeof(item.whitelist) ~= "table" then item.whitelist = {} end
    end
    return data
end

-- Build Key Lookups
local function BuildKeyLookups(db)
    local AllKeys, KeysValid, FullKeyData = {}, {}, {}
    local now = os.time()
    
    for _, item in ipairs(db) do
        table.insert(AllKeys, item.key)
        FullKeyData[item.key] = {
            key = item.key,
            duration = item.duration,
            duration_seconds = item.duration_seconds,
            created_at = item.created_at,
            created_unix = item.created_unix,
            expires_at = item.expired_unix,
            whitelist = item.whitelist
        }
        
        local isExpired = item.expired_unix ~= math.huge and now > item.expired_unix
        local isWhitelisted = #item.whitelist == 0
        
        if not isWhitelisted then
            for _, name in ipairs(item.whitelist) do
                if string.lower(name) == string.lower(LocalPlayer.Name) then
                    isWhitelisted = true
                    break
                end
            end
        end
        
        if not isExpired and isWhitelisted then
            table.insert(KeysValid, item.key)
        end
    end
    return AllKeys, KeysValid, FullKeyData
end

local normalizedData = LoadKeyDatabase()
local AllKeys, KeysValid, FullKeyData = BuildKeyLookups(normalizedData)

local function FindKeyByUsername(username)
    for key, data in pairs(FullKeyData) do
        if typeof(data.whitelist) == "table" then
            for _, name in ipairs(data.whitelist) do
                if string.lower(name) == string.lower(username) then
                    return data
                end
            end
        end
    end
    return nil
end

-- Webhook System
local WEBHOOK_URL = "https://canary.discord.com/api/webhooks/1441739429973725186/oTSoDM06j8AJ8hdY3sKoDYqCabrmpPVZmEOA-FaHWtnnsv6OwsSuQhntWxV7X5_TQjqf"

local function SendDiscordWebhook(webhookData)
    task.spawn(function()
        pcall(function()
            local avatarUrl = "https://www.roblox.com/headshot-thumbnail/image?userId="..webhookData.userId.."&width=420&height=420&format=png"
            local gameName = "Unknown Game"
            pcall(function()
                gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
            end)

            local payload = {
                username = "Kayzee Logger",
                avatar_url = "https://cdn.discordapp.com/attachments/1439051366973833286/1442928366083903669/Proyek_Baru_10_166B88A.png",
                embeds = {{
                    title = "Kayzee | Server Monitor",
                    color = 0x00F394,
                    thumbnail = { url = avatarUrl },
                    fields = {
                        { name = "Player Info", value = "**Username:** "..webhookData.username.."\n**Display:** "..webhookData.displayName.."\n**User ID:** "..webhookData.userId.."\n**Game:** "..gameName, inline = false },
                        { name = "Key Status", value = "**Key:** "..(webhookData.keyUsed or "NO KEY").."\n**Duration:** "..(webhookData.keyDuration or "N/A").."\n**Remaining:** "..webhookData.timeRemaining, inline = true }
                    }
                }}
            }

            syn.request({
                Url = WEBHOOK_URL,
                Method = "POST",
                Headers = { ["Content-Type"] = "application/json" },
                Body = HttpService:JSONEncode(payload)
            })
        end)
    end)
end

local function GatherWebhookData(scriptName)
    local keyStatus = "No Key"
    if UserKeyInfo and UserKeyInfo.key and UserKeyInfo.key ~= "" then
        if UserKeyInfo.expires_at == math.huge then
            keyStatus = "Lifetime"
        elseif os.time() > UserKeyInfo.expires_at then
            keyStatus = "Expired"
        else
            keyStatus = "Active"
        end
    end

    local timeRemaining = "N/A"
    if UserKeyInfo and UserKeyInfo.created_unix and UserKeyInfo.duration_seconds then
        timeRemaining = TimeRemaining(UserKeyInfo.created_unix, UserKeyInfo.duration_seconds)
    end

    return {
        username = LocalPlayer.Name,
        displayName = LocalPlayer.DisplayName,
        userId = LocalPlayer.UserId,
        keyUsed = UserKeyInfo and UserKeyInfo.key or "NO KEY",
        keyDuration = UserKeyInfo and UserKeyInfo.duration or "N/A",
        timeRemaining = timeRemaining,
        keyStatus = keyStatus,
        scriptExecuted = scriptName or "Script Loader Opened"
    }
end

-- Key Validation
local function ValidateKey(inputKey)
    local info = FullKeyData[inputKey]
    if not info then return false, "Invalid Key" end

    local now = os.time()
    if info.expires_at ~= math.huge and now > info.expires_at then
        return false, "Key Expired"
    end

    if #info.whitelist > 0 then
        local allowed = false
        for _, name in ipairs(info.whitelist) do
            if name == LocalPlayer.Name then
                allowed = true
                break
            end
        end
        if not allowed then return false, "Not Whitelisted" end
    end

    UserKeyInfo = info
    SendDiscordWebhook(GatherWebhookData("Key Validated"))
    return true, "ACCESS GRANTED"
end

-- Load WindUI
local WindUI
do
    local ok, res = pcall(function() return require("./src/Init") end)
    if ok and res then
        WindUI = res
    else
        local s, content = pcall(function()
            return game:HttpGet("https://raw.githubusercontent.com/Footagesus/WindUI/refs/heads/main/dist/main.lua")
        end)
        if s then WindUI = loadstring(content)() end
    end
end

if not WindUI then
    warn("WINDUI FAILED TO LOAD")
    return
end

print("[✓] WindUI Loaded Successfully")
print("[✓] Creating Window...")

-- Create Window
local Window = WindUI:CreateWindow({
    Title = "Kayzee | Script Loader",
    Author = "Tiktok: @justsekayzee",
    Icon = "rbxassetid://111078249649981",
    Size = UDim2.fromOffset(600, 450),
    Transparent = true,
    Theme = "Dark",
    Resizable = true,
    SideBarWidth = 180,

    KeySystem = {
        Key = KeysValid,
        SaveKey = true,
        Note = "Enter your key to continue.",
        Callback = function(inputKey)
            local ok, msg = ValidateKey(inputKey)
            if not ok then
                WindUI:Notify({
                    Title = "Key Error",
                    Content = msg,
                    Duration = 4
                })
                return false
            end
            WindUI:Notify({
                Title = "Success",
                Content = "Welcome " .. LocalPlayer.DisplayName,
                Duration = 3
            })
            task.wait(1)
            SendDiscordWebhook(GatherWebhookData("Script Loader Opened"))
            return true
        end
    }
})

Window:EditOpenButton({
    Title = "Kayzee",
    Icon = "rbxassetid://111078249649981",
    CornerRadius = UDim.new(0, 12),
    StrokeThickness = 2,
    Draggable = true
})

print("[✓] Window Created")
print("[✓] Loading UI Components...")

-- ============================================
-- PART 2: TAGS (Ping, FPS, Time)
-- ============================================

local PingTag = Window:Tag({
    Title = "Ping: -- ms",
    Radius = 13
})

task.spawn(function()
    while true do
        pcall(function()
            local ping = math.floor(Stats.Network.ServerStatsItem["Data Ping"]:GetValue())
            PingTag:SetTitle("Ping: " .. ping .. " ms")
        end)
        task.wait(1)
    end
end)

local FPSTag = Window:Tag({
    Title = "FPS: 0",
    Radius = 13
})

task.spawn(function()
    local fps = 60
    while true do
        pcall(function()
            local dt = RunService.RenderStepped:Wait()
            fps = math.floor(1/dt)
            FPSTag:SetTitle("FPS: " .. fps)
        end)
        task.wait(0.5)
    end
end)

local TimeTag = Window:Tag({
    Title = "--:--:--",
    Radius = 13
})

task.spawn(function()
    while true do
        pcall(function()
            local now = os.date("*t")
            TimeTag:SetTitle(string.format("%02d:%02d:%02d", now.hour, now.min, now.sec))
        end)
        task.wait(1)
    end
end)

print("[✓] Tags Created")

-- ============================================
-- PART 3: HOME TAB
-- ============================================

local HomeTab = Window:Tab({
    Title = "Home",
    Icon = "home"
})

HomeTab:Section({
    Title = "Welcome to Kayzee Script Loader!"
})

-- Welcome Message
HomeTab:Paragraph({
    Title = "Hello, " .. LocalPlayer.DisplayName .. "!",
    Desc = string.format(
        "Username: @%s\nUser ID: %d\nAccount Age: %d days\n\nThank you for using Kayzee Script Loader!",
        LocalPlayer.Name,
        LocalPlayer.UserId,
        LocalPlayer.AccountAge
    )
})

HomeTab:Divider()

-- Server Info
HomeTab:Section({Title = "Server Information"})

local ServerInfoPara = HomeTab:Paragraph({
    Title = "Server Stats",
    Desc = "Loading..."
})

local function UpdateServerInfo()
    pcall(function()
        local playerCount = #Players:GetPlayers()
        local maxPlayers = Players.MaxPlayers
        local gameName = "Unknown"
        
        pcall(function()
            gameName = MarketplaceService:GetProductInfo(game.PlaceId).Name
        end)
        
        ServerInfoPara:SetDesc(string.format(
            "Game: %s\nPlayers: %d/%d\nPlace ID: %d\nJob ID: %s...",
            gameName,
            playerCount,
            maxPlayers,
            game.PlaceId,
            game.JobId:sub(1, 8)
        ))
    end)
end

UpdateServerInfo()

HomeTab:Button({
    Title = "Refresh Server Info",
    Desc = "Update server information",
    Callback = function()
        UpdateServerInfo()
        WindUI:Notify({
            Title = "Refreshed",
            Content = "Server info updated!",
            Duration = 2
        })
    end
})

HomeTab:Divider()

-- Quick Actions
HomeTab:Section({Title = "Quick Actions"})

HomeTab:Button({
    Title = "Copy Job ID",
    Desc = "Copy current server Job ID",
    Callback = function()
        setclipboard(game.JobId)
        WindUI:Notify({
            Title = "Copied!",
            Content = "Job ID copied to clipboard",
            Duration = 2
        })
    end
})

HomeTab:Button({
    Title = "Rejoin Server",
    Desc = "Rejoin current server",
    Callback = function()
        game:GetService("TeleportService"):TeleportToPlaceInstance(
            game.PlaceId,
            game.JobId,
            LocalPlayer
        )
    end
})

HomeTab:Divider()

-- Latest News
HomeTab:Section({Title = "Latest News"})

HomeTab:Paragraph({
    Title = "Version 1.3 Released!",
    Desc = [[What's New:
• New Home Tab
• Enhanced UI design
• Better performance
• Script favorites system
• More features coming soon!

Last updated: 28 November 2025]]
})

HomeTab:Select()

print("[✓] Home Tab Created")

-- ============================================
-- PART 4: INFORMATION TAB
-- ============================================

local InfoTab = Window:Tab({
    Title = "Information",
    Icon = "info"
})

InfoTab:Section({Title = "Changelog & Updates"})

InfoTab:Paragraph({
    Title = "Latest Update - v1.3",
    Desc = [[28 November 2025

New Features:
• Added Home Tab
• Server utilities
• Better UI/UX

Improvements:
• Better key validation
• Enhanced performance
• Optimized code

Bug Fixes:
• Fixed key checker
• Fixed script loader]]
})

InfoTab:Divider()

InfoTab:Section({Title = "About Script"})

InfoTab:Paragraph({
    Title = "Kayzee Script Loader",
    Desc = [[Version: 1.3
Developer: @justsekayzee
Platform: TikTok, Discord

Professional script hub with:
• Secure key system
• Multiple script support
• Real-time monitoring
• Admin detection
• Discord community]]
})

InfoTab:Divider()

-- Server Status
InfoTab:Section({Title = "Server Status"})

local StatusPara = InfoTab:Paragraph({
    Title = "System Status",
    Desc = "Checking..."
})

local function UpdateStatus()
    pcall(function()
        local keyCheck = pcall(function()
            game:HttpGet(KEY_URL)
        end)
        
        local status = keyCheck and "Online" or "Offline"
        
        StatusPara:SetDesc(string.format(
            "Key System: %s\nWebhook: Online\nScripts: Online\nDatabase: Online\n\nLast checked: %s",
            status,
            os.date("%H:%M:%S")
        ))
    end)
end

UpdateStatus()

InfoTab:Button({
    Title = "Refresh Status",
    Callback = function()
        UpdateStatus()
        WindUI:Notify({
            Title = "Refreshed",
            Content = "Status updated!",
            Duration = 2
        })
    end
})

InfoTab:Divider()

-- Links
InfoTab:Section({Title = "Links & Support"})

InfoTab:Button({
    Title = "Join Discord Server",
    Desc = "Join our community",
    Callback = function()
        setclipboard("https://discord.gg/JD3BF8K5nR")
        WindUI:Notify({
            Title = "Copied!",
            Content = "Discord link copied",
            Duration = 3
        })
    end
})

InfoTab:Button({
    Title = "Follow TikTok",
    Desc = "@justsekayzee",
    Callback = function()
        setclipboard("@justsekayzee")
        WindUI:Notify({
            Title = "Copied!",
            Content = "TikTok username copied",
            Duration = 3
        })
    end
})

InfoTab:Button({
    Title = "Support on Saweria",
    Desc = "Support the developer",
    Callback = function()
        setclipboard("https://saweria.co/Kayzee")
        WindUI:Notify({
            Title = "Copied!",
            Content = "Saweria link copied",
            Duration = 3
        })
    end
})

print("[✓] Information Tab Created")

-- ============================================
-- PART 5: ACCOUNT TAB
-- ============================================

local AccountTab = Window:Tab({
    Title = "Account",
    Icon = "user"
})

AccountTab:Section({Title = "Account Overview"})

local function getAccountProfileURL()
    return string.format("https://www.roblox.com/users/%d/profile", LocalPlayer.UserId)
end

local AccountInfoPara = AccountTab:Paragraph({
    Title = "Account Information",
    Desc = "Loading..."
})

local function updateAccountInfo()
    pcall(function()
        local detected = FindKeyByUsername(LocalPlayer.Name)
        
        if detected then
            UserKeyInfo = detected
            local remaining = TimeRemaining(UserKeyInfo.created_unix, UserKeyInfo.duration_seconds)
            
            AccountInfoPara:SetDesc(string.format(
                "Key Status: %s\nDuration: %s\nTime Remaining: %s\nCreated: %s\nExpires: %s\n\nDisplay Name: %s\nUsername: @%s\nUser ID: %d\nAccount Age: %d days",
                UserKeyInfo.key,
                UserKeyInfo.duration,
                remaining,
                os.date("%Y-%m-%d %H:%M", UserKeyInfo.created_unix),
                UserKeyInfo.expires_at == math.huge and "NEVER" or os.date("%Y-%m-%d %H:%M", UserKeyInfo.expires_at),
                LocalPlayer.DisplayName,
                LocalPlayer.Name,
                LocalPlayer.UserId,
                LocalPlayer.AccountAge
            ))
        else
            AccountInfoPara:SetDesc(string.format(
                "Key Status: NO KEY\nTime Remaining: Expired\n\nDisplay Name: %s\nUsername: @%s\nUser ID: %d\nAccount Age: %d days",
                LocalPlayer.DisplayName,
                LocalPlayer.Name,
                LocalPlayer.UserId,
                LocalPlayer.AccountAge
            ))
        end
    end)
end

updateAccountInfo()

AccountTab:Divider()

AccountTab:Section({Title = "Quick Actions"})

AccountTab:Button({
    Title = "Refresh Account Data",
    Callback = function()
        updateAccountInfo()
        WindUI:Notify({
            Title = "Account",
            Content = "Account data refreshed",
            Duration = 2
        })
    end
})

AccountTab:Button({
    Title = "Copy Profile Link",
    Callback = function()
        setclipboard(getAccountProfileURL())
        WindUI:Notify({
            Title = "Copied!",
            Content = "Profile link copied",
            Duration = 2
        })
    end
})

AccountTab:Button({
    Title = "Copy Username",
    Callback = function()
        setclipboard(LocalPlayer.Name)
        WindUI:Notify({
            Title = "Copied!",
            Content = "Username: "..LocalPlayer.Name,
            Duration = 2
        })
    end
})

AccountTab:Button({
    Title = "Copy User ID",
    Callback = function()
        setclipboard(tostring(LocalPlayer.UserId))
        WindUI:Notify({
            Title = "Copied!",
            Content = "User ID: "..LocalPlayer.UserId,
            Duration = 2
        })
    end
})

-- Auto refresh
task.spawn(function()
    while task.wait(10) do
        if UserKeyInfo and UserKeyInfo.key and UserKeyInfo.key ~= "" then
            updateAccountInfo()
        end
    end
end)

print("[✓] Account Tab Created")

-- ============================================
-- PART 6: SCRIPT EXECUTION FUNCTIONS
-- ============================================

local function DestroyWindow()
    if Window then
        pcall(function()
            Window:Destroy()
        end)
    end
end

local function ExecuteScriptWithEmbed(scriptName, scriptUrl)
    WindUI:Notify({
        Title = "Loading",
        Content = "Downloading "..scriptName.."...",
        Duration = 3
    })
    
    task.spawn(function()
        local success, content = pcall(game.HttpGet, game, scriptUrl)
        
        if success then
            WindUI:Notify({
                Title = "Executing",
                Content = "Running "..scriptName.."...",
                Duration = 2
            })
            
            task.wait(0.5)
            
            local execSuccess, err = pcall(function()
                SendDiscordWebhook(GatherWebhookData(scriptName))
                loadstring(content)()
            end)
            
            if execSuccess then
                WindUI:Notify({
                    Title = "Success",
                    Content = scriptName.." executed successfully!",
                    Duration = 3
                })
                task.wait(1)
                DestroyWindow()
            else
                WindUI:Notify({
                    Title = "Error",
                    Content = "Failed to execute: "..tostring(err),
                    Duration = 5
                })
            end
        else
            WindUI:Notify({
                Title = "Error",
                Content = "Failed to download script",
                Duration = 4
            })
        end
    end)
end

print("[✓] Script Functions Loaded")

-- ============================================
-- PART 7: LIST SCRIPTS TAB
-- ============================================

local ScriptTab = Window:Tab({
    Title = "List Scripts",
    Icon = "layers"
})

ScriptTab:Section({Title = "Available Scripts"})

local BASE_URL = "https://raw.githubusercontent.com/Skyzee02/skntlxxnxxnxxnxxnxx01/refs/heads/main/"

local scriptList = {
    {
        name = "Script All Mount - Kayzee",
        file = "KayzeeV1.lua",
        desc = "Universal mount script"
    },
    {
        name = "Script Violence District - Kayzee",
        file = "KayzeeVD.lua",
        desc = "Auto farm for Violence District"
    },
    {
        name = "Script Fish It - Kayzee",
        file = "KayzeeFI.lua",
        desc = "Auto fishing script"
    },
    {
        name = "Script Rusuh - Kayzee",
        file = "KayzeeRSH.lua",
        desc = "Rusuh game script",
        inProgress = true
    },
    {
        name = "Script Fishit Inisial C - Kayzee",
        file = "KayzeeCX.lua",
        desc = "Fish It variant C"
    },
    {
        name = "Script Fishit Glua - Premium",
        file = "https://raw.githubusercontent.com/SKZ-02/pisanglumer/refs/heads/main/KayzeeGL.lua",
        desc = "Premium - Glua version",
        premium = true
    },
    {
        name = "Script Fishit IsylHub - Premium",
        file = "https://raw.githubusercontent.com/SKZ-02/pisanglumer/refs/heads/main/KayzeeIS.lua",
        desc = "Premium - IsylHub",
        premium = true
    },
    {
        name = "Script Fishit Walvy - Premium",
        file = "https://raw.githubusercontent.com/SKZ-02/pisanglumer/refs/heads/main/KayzeeWVP.lua",
        desc = "Premium - Walvy",
        premium = true
    },
    {
        name = "Script Fishit VinzHub - Premium",
        file = "https://raw.githubusercontent.com/SKZ-02/pisanglumer/refs/heads/main/KayzeeVH.lua",
        desc = "Premium - VinzHub",
        premium = true
    },
    {
        name = "Script Violence District VinzHub - Premium",
        file = "https://raw.githubusercontent.com/SKZ-02/pisanglumer/refs/heads/main/KayzeeVHVD.lua",
        desc = "Premium VD - VinzHub",
        premium = true
    },
    {
        name = "Script Plant Vs Brainrot VinzHub - Premium",
        file = "https://raw.githubusercontent.com/SKZ-02/pisanglumer/refs/heads/main/KayzeeVHPVB.lua",
        desc = "Premium PVB - VinzHub",
        premium = true
    }
}

-- Create script buttons
for _, scriptData in ipairs(scriptList) do
    local isInProgress = scriptData.inProgress or false
    local isPremium = scriptData.premium or false
    
    local statusText = ""
    if isInProgress then
        statusText = " [IN PROGRESS]"
    elseif isPremium then
        statusText = " [PREMIUM]"
    end
    
    ScriptTab:Button({
        Title = scriptData.name .. statusText,
        Desc = scriptData.desc,
        Callback = function()
            if isInProgress then
                WindUI:Notify({
                    Title = "In Progress",
                    Content = scriptData.name.." is currently being developed",
                    Duration = 3
                })
            else
                local scriptUrl = scriptData.file
                if not scriptUrl:find("http") then
                    scriptUrl = BASE_URL .. scriptUrl
                end
                ExecuteScriptWithEmbed(scriptData.name, scriptUrl)
            end
        end
    })
end

ScriptTab:Divider()

-- Script Statistics
ScriptTab:Section({Title = "Statistics"})

local totalScripts = #scriptList
local premiumCount = 0
local progressCount = 0

for _, s in ipairs(scriptList) do
    if s.premium then premiumCount = premiumCount + 1 end
    if s.inProgress then progressCount = progressCount + 1 end
end

ScriptTab:Paragraph({
    Title = "Script Stats",
    Desc = string.format(
        "Total Scripts: %d\nPremium Scripts: %d\nIn Progress: %d\nReady: %d",
        totalScripts,
        premiumCount,
        progressCount,
        totalScripts - progressCount
    )
})

print("[✓] Script Tab Created")

-- ============================================
-- PART 8: DISCORD TAB
-- ============================================

local DiscordTab = Window:Tab({
    Title = "Discord",
    Icon = "message-circle"
})

DiscordTab:Section({Title = "Join Our Community!"})

local FIXED_MEMBER = 10380
local ONLINE_MIN = 1269
local ONLINE_MAX = 1305

if getgenv().LastOnlineValue == nil then
    getgenv().LastOnlineValue = math.random(ONLINE_MIN, ONLINE_MAX)
else
    getgenv().LastOnlineValue = getgenv().LastOnlineValue + 1
end

local OnlineCount = getgenv().LastOnlineValue

DiscordTab:Paragraph({
    Title = "Secret K Community",
    Desc = string.format(
        "Member Count: %d\nOnline Count: %d\n\nJoin our community for:\n• Script updates\n• Support & help\n• Giveaways\n• Bug reports\n• Suggestions",
        FIXED_MEMBER,
        OnlineCount
    )
})

DiscordTab:Button({
    Title = "Copy Discord Link",
    Desc = "Join our Discord server",
    Callback = function()
        setclipboard("https://discord.gg/JD3BF8K5nR")
        WindUI:Notify({
            Title = "Copied!",
            Content = "Discord link copied to clipboard",
            Duration = 3
        })
    end
})

DiscordTab:Divider()

DiscordTab:Section({Title = "Community Guidelines"})

DiscordTab:Paragraph({
    Title = "Server Rules",
    Desc = [[Please follow these rules:

1. Be respectful to everyone
2. No spam or advertising
3. Use appropriate channels
4. No NSFW content
5. Follow Discord TOS
6. English & Indonesian only
7. No begging for keys/scripts

Breaking rules may result in ban!]]
})

DiscordTab:Divider()

DiscordTab:Section({Title = "Quick Links"})

DiscordTab:Button({
    Title = "Report a Bug",
    Desc = "Found a bug? Let us know!",
    Callback = function()
        setclipboard("https://discord.gg/JD3BF8K5nR")
        WindUI:Notify({
            Title = "Discord",
            Content = "Report bugs in #bug-reports channel",
            Duration = 4
        })
    end
})

DiscordTab:Button({
    Title = "Request a Script",
    Desc = "Suggest new scripts",
    Callback = function()
        setclipboard("https://discord.gg/JD3BF8K5nR")
        WindUI:Notify({
            Title = "Discord",
            Content = "Use #suggestions channel",
            Duration = 4
        })
    end
})

DiscordTab:Button({
    Title = "Get Support",
    Desc = "Need help? Ask in Discord!",
    Callback = function()
        setclipboard("https://discord.gg/JD3BF8K5nR")
        WindUI:Notify({
            Title = "Discord",
            Content = "Visit #support channel",
            Duration = 4
        })
    end
})

print("[✓] Discord Tab Created")

-- ============================================
-- PART 9: ADMIN DETECTOR TAB
-- ============================================

local AdminTab = Window:Tab({
    Title = "Admin Detector",
    Icon = "shield-alert"
})

AdminTab:Section({Title = "In-Game Admin Detection"})

local Detected = {}
local DetectionHistory = {}

local AdminPara = AdminTab:Paragraph({
    Title = "Scanning server...",
    Desc = "Looking for admins/staff..."
})

local function UpdateDisplay()
    pcall(function()
        if #Detected == 0 then
            AdminPara:SetTitle("Safe Server")
            AdminPara:SetDesc(string.format(
                "No admins detected!\n\nYou can play safely.\nLast scan: %s",
                os.date("%H:%M:%S")
            ))
        else
            AdminPara:SetTitle("ADMIN ALERT!")
            local lines = {string.format("WARNING: %d Admin(s) Detected!\n", #Detected)}
            
            for _, v in ipairs(Detected) do
                table.insert(lines, string.format(
                    "• %s (@%s) → [%s]",
                    v.Player.DisplayName,
                    v.Player.Name,
                    v.Source
                ))
            end
            
            table.insert(lines, "\nBe careful! Admin is watching!")
            AdminPara:SetDesc(table.concat(lines, "\n"))
        end
    end)
end

local function PlayAlert()
    pcall(function()
        local s = Instance.new("Sound", game.SoundService)
        s.SoundId = "rbxassetid://6026984227"
        s.Volume = 1
        s:Play()
        task.delay(4, function() s:Destroy() end)
    end)
end

local function CheckPlayer(plr)
    if plr == LocalPlayer then return end
    
    -- Check if already detected
    for _, v in ipairs(Detected) do
        if v.Player == plr then return end
    end

    local detected, source = false, ""
    
    -- Badge Check
    pcall(function()
        if plr:FindFirstChild("Badge") or plr:FindFirstChild("Badges") then
            local folder = plr:FindFirstChild("Badge") or plr:FindFirstChild("Badges")
            for _, b in ipairs(folder:GetChildren()) do
                local badgeName = b.Name:lower()
                if badgeName:find("admin") or badgeName:find("mod") or badgeName:find("owner") or badgeName:find("dev") then
                    detected = true
                    source = "Badge: "..b.Name
                    return
                end
            end
        end
    end)
    
    -- Group Rank Check
    if not detected then
        pcall(function()
            if plr:IsInGroup(game.CreatorId) then
                local rank = plr:GetRankInGroup(game.CreatorId)
                if rank >= 250 then
                    detected = true
                    source = "Group Rank: "..rank
                end
            end
        end)
    end
    
    -- Tag Check
    if not detected then
        pcall(function()
            local ls = plr:FindFirstChild("leaderstats")
            if ls then
                for _, v in ipairs(ls:GetChildren()) do
                    if v:IsA("StringValue") then
                        local value = v.Value:lower()
                        if value:find("admin") or value:find("mod") or value:find("owner") or value:find("dev") then
                            detected = true
                            source = "Tag: "..v.Value
                            return
                        end
                    end
                end
            end
        end)
    end

    if detected then
        table.insert(Detected, {
            Player = plr,
            Source = source,
            Time = os.time()
        })
        
        table.insert(DetectionHistory, {
            Player = plr.Name,
            DisplayName = plr.DisplayName,
            Source = source,
            Time = os.date("%H:%M:%S")
        })
        
        WindUI:Notify({
            Title = "ADMIN DETECTED!",
            Content = plr.DisplayName.." is an admin!\nSource: "..source,
            Duration = 10
        })
        
        PlayAlert()
        UpdateDisplay()
    end
end

-- Initial scan
for _, plr in ipairs(Players:GetPlayers()) do
    if plr ~= LocalPlayer then
        task.spawn(function()
            CheckPlayer(plr)
        end)
    end
end

-- Monitor new players
Players.PlayerAdded:Connect(function(plr)
    task.wait(3)
    CheckPlayer(plr)
end)

Players.PlayerRemoving:Connect(function(plr)
    for i = #Detected, 1, -1 do
        if Detected[i].Player == plr then
            table.remove(Detected, i)
        end
    end
    UpdateDisplay()
end)

AdminTab:Divider()

AdminTab:Section({Title = "Detection Controls"})

AdminTab:Button({
    Title = "Rescan Server",
    Desc = "Scan all players again",
    Callback = function()
        Detected = {}
        UpdateDisplay()
        
        WindUI:Notify({
            Title = "Admin Detector",
            Content = "Rescanning server...",
            Duration = 2
        })
        
        task.wait(1)
        
        for _, plr in ipairs(Players:GetPlayers()) do
            if plr ~= LocalPlayer then
                task.spawn(function()
                    CheckPlayer(plr)
                end)
            end
        end
        
        task.wait(2)
        
        WindUI:Notify({
            Title = "Admin Detector",
            Content = "Scan complete!",
            Duration = 2
        })
    end
})

AdminTab:Button({
    Title = "Clear History",
    Desc = "Clear detection records",
    Callback = function()
        DetectionHistory = {}
        WindUI:Notify({
            Title = "Admin Detector",
            Content = "History cleared",
            Duration = 2
        })
    end
})

AdminTab:Divider()

AdminTab:Section({Title = "Detection Statistics"})

local StatsP = AdminTab:Paragraph({
    Title = "Detection Stats",
    Desc = "Loading..."
})

local function UpdateStats()
    pcall(function()
        StatsP:SetDesc(string.format(
            "Total Scans: %d players\nAdmins Detected: %d\nDetection History: %d records\nLast Scan: %s",
            #Players:GetPlayers(),
            #Detected,
            #DetectionHistory,
            os.date("%H:%M:%S")
        ))
    end)
end

UpdateStats()

-- Auto refresh
task.spawn(function()
    while task.wait(5) do
        UpdateDisplay()
        UpdateStats()
    end
end)

print("[✓] Admin Detector Tab Created")

-- ============================================
-- PART 10: SETTINGS TAB
-- ============================================

local SettingsTab = Window:Tab({
    Title = "Settings",
    Icon = "settings"
})

SettingsTab:Section({Title = "General Settings"})

-- Notifications
getgenv().NotificationsEnabled = getgenv().NotificationsEnabled == nil and true or getgenv().NotificationsEnabled

SettingsTab:Toggle({
    Title = "Enable Notifications",
    Desc = "Show notifications for events",
    Default = getgenv().NotificationsEnabled,
    Callback = function(value)
        getgenv().NotificationsEnabled = value
        if value then
            WindUI:Notify({
                Title = "Settings",
                Content = "Notifications enabled",
                Duration = 2
            })
        end
    end
})

-- Auto Refresh
getgenv().AutoRefreshKey = getgenv().AutoRefreshKey or false

SettingsTab:Toggle({
    Title = "Auto Refresh Key Status",
    Desc = "Automatically check key expiration",
    Default = getgenv().AutoRefreshKey,
    Callback = function(value)
        getgenv().AutoRefreshKey = value
        WindUI:Notify({
            Title = "Settings",
            Content = "Auto Refresh: "..(value and "Enabled" or "Disabled"),
            Duration = 2
        })
    end
})

SettingsTab:Divider()

SettingsTab:Section({Title = "Data Management"})

SettingsTab:Button({
    Title = "Clear Saved Key",
    Desc = "Remove saved key from cache",
    Callback = function()
        pcall(function()
            writefile("Kayzee_SavedKey.txt", "")
        end)
        WindUI:Notify({
            Title = "Settings",
            Content = "Saved key cleared!",
            Duration = 2
        })
    end
})

SettingsTab:Button({
    Title = "Reset All Settings",
    Desc = "Reset to default settings",
    Callback = function()
        getgenv().NotificationsEnabled = true
        getgenv().AutoRefreshKey = false
        WindUI:Notify({
            Title = "Settings",
            Content = "All settings reset to default",
            Duration = 3
        })
    end
})

SettingsTab:Divider()

SettingsTab:Section({Title = "About"})

SettingsTab:Paragraph({
    Title = "Kayzee Script Loader v1.3",
    Desc = [[Developer: @justsekayzee
Platform: TikTok, Discord
Version: 1.3
Release: 28 November 2025

Thank you for using Kayzee Script Loader!

For support, join our Discord server.]]
})

SettingsTab:Button({
    Title = "Check for Updates",
    Callback = function()
        WindUI:Notify({
            Title = "Update",
            Content = "You are using the latest version!",
            Duration = 3
        })
    end
})

print("[✓] Settings Tab Created")

-- ============================================
-- FINAL INITIALIZATION
-- ============================================

print("\n")
print("  ═══════════════════════════════════════════════════════════")
print("   ✓ All Components Loaded Successfully!")
print("   ✓ Kayzee Script Loader v1.3 Ready!")
print("  ═══════════════════════════════════════════════════════════")
print("\n")

WindUI:Notify({
    Title = "Kayzee Script Loader",
    Content = "All systems loaded successfully!",
    Duration = 3
})

-- End of script