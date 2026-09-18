--==================================================
-- YOKUDO HUB | KEY SYSTEM
-- AUTO VERIFY BEFORE UI
-- AUTO SAVE KEY
-- PLACE ID LOADER
-- NON-DRAG UI
--==================================================

local Players = game:GetService("Players")
local HttpService = game:GetService("HttpService")
local RbxAnalyticsService = game:GetService("RbxAnalyticsService")

local LocalPlayer = Players.LocalPlayer

--==================================================
-- SETTINGS
--==================================================

local API_BASE = "https://yokudohub.com"

local VERIFY_URL =
    API_BASE .. "/api/key/verify"

local GET_LINK_URL =
    API_BASE .. "/api/access/create"

local KEY_FILE =
    "yokudokey.json"

--==================================================
-- PLACE ID -> LOADER
--==================================================

local LOADERS = {

    -- MAIN
    [107778070777162] =
        "https://raw.githubusercontent.com/betdoyvaka/stealanegg/refs/heads/main/Loader.lua",

}

--==================================================
-- HTTP REQUEST
--==================================================

local Request =
    (syn and syn.request)
    or (http and http.request)
    or http_request
    or request

if not Request then

    warn(
        "[YOKUDO] HTTP Request not supported."
    )

    return
end

--==================================================
-- FILE SYSTEM
--==================================================

local CanUseFile =
    type(isfile) == "function"
    and type(readfile) == "function"
    and type(writefile) == "function"

--==================================================
-- COPY
--==================================================

local function CopyText(Text)

    if type(setclipboard) == "function" then

        local Success =
            pcall(function()

                setclipboard(Text)

            end)

        if Success then
            return true
        end

    end

    if type(toclipboard) == "function" then

        local Success =
            pcall(function()

                toclipboard(Text)

            end)

        if Success then
            return true
        end

    end

    return false
end

--==================================================
-- SAVE KEY
--
-- FILE:
--
-- {
--     "key": "YOKUDO-XXXXX-XXXXX-XXXXX"
-- }
--==================================================

local function SaveKey(Key)

    if not CanUseFile then
        return false
    end

    local Data = {
        key = tostring(Key)
    }

    local Success =
        pcall(function()

            writefile(
                KEY_FILE,
                HttpService:JSONEncode(Data)
            )

        end)

    return Success
end

--==================================================
-- LOAD SAVED KEY
--==================================================

local function LoadSavedKey()

    if not CanUseFile then
        return nil
    end

    if not isfile(KEY_FILE) then
        return nil
    end

    local Success, Data =
        pcall(function()

            return HttpService:JSONDecode(
                readfile(KEY_FILE)
            )

        end)

    if not Success then
        return nil
    end

    if type(Data) ~= "table" then
        return nil
    end

    if not Data.key then
        return nil
    end

    local Key =
        tostring(Data.key)

    if Key == "" then
        return nil
    end

    return Key
end

--==================================================
-- DELETE SAVED KEY
--==================================================

local function DeleteSavedKey()

    if not CanUseFile then
        return
    end

    if type(delfile) ~= "function" then
        return
    end

    if isfile(KEY_FILE) then

        pcall(function()

            delfile(KEY_FILE)

        end)

    end
end

--==================================================
-- CLIENT ID / HWID
--==================================================

local function GetClientId()

    local Success, ClientId =
        pcall(function()

            return RbxAnalyticsService:GetClientId()

        end)

    if
        Success
        and ClientId
        and tostring(ClientId) ~= ""
    then

        return tostring(ClientId)

    end

    if LocalPlayer then
        return tostring(LocalPlayer.UserId)
    end

    return "UNKNOWN"
end

--==================================================
-- POST JSON
--==================================================

local function PostJSON(URL, Body)

    local Success, Response =
        pcall(function()

            return Request({

                Url = URL,

                Method = "POST",

                Headers = {

                    ["Content-Type"] =
                        "application/json"

                },

                Body =
                    HttpService:JSONEncode(
                        Body
                    )

            })

        end)

    if not Success then

        return {

            success = false,

            error =
                tostring(Response)

        }

    end

    if not Response then

        return {

            success = false,

            error = "No response"

        }

    end

    if not Response.Body then

        return {

            success = false,

            error = "Empty response"

        }

    end

    local DecodeSuccess, Data =
        pcall(function()

            return HttpService:JSONDecode(
                Response.Body
            )

        end)

    if not DecodeSuccess then

        return {

            success = false,

            error =
                "Invalid JSON response"

        }

    end

    return Data
end

--==================================================
-- VERIFY KEY
--==================================================

local function VerifyKeyRequest(Key)

    return PostJSON(

        VERIFY_URL,

        {

            key =
                tostring(Key),

            hwid =
                GetClientId()

        }

    )
end

--==================================================
-- KICK
--==================================================

local function KickPlayer()

    pcall(function()

        LocalPlayer:Kick(
            "YOKUDO HUB\n\nInvalid Key"
        )

    end)

end

--==================================================
-- LOAD LOADER BY PLACE ID
--==================================================

local function LoadGameLoader()

    local PlaceId =
        tonumber(game.PlaceId)

    local LoaderURL =
        LOADERS[PlaceId]

    print(
        "[YOKUDO] PlaceId: "
        .. tostring(PlaceId)
    )

    if not LoaderURL then

        warn(
            "[YOKUDO] Unsupported PlaceId: "
            .. tostring(PlaceId)
        )

        return false
    end

    print(
        "[YOKUDO] Loading loader..."
    )

    local Success, Error =
        pcall(function()

            local Source =
                game:HttpGet(
                    LoaderURL
                )

            local Loader =
                loadstring(Source)

            if not Loader then

                error(
                    "loadstring failed"
                )

            end

            Loader()

        end)

    if not Success then

        warn(
            "[YOKUDO] Loader Error: "
            .. tostring(Error)
        )

        return false
    end

    return true
end

--==================================================
--==================================================
-- CHECK SAVED KEY BEFORE UI
--==================================================
--==================================================

local SavedKey =
    LoadSavedKey()

if SavedKey then

    print(
        "[YOKUDO] Saved key found."
    )

    print(
        "[YOKUDO] Verifying..."
    )

    local Result =
        VerifyKeyRequest(
            SavedKey
        )

    --==================================================
    -- VALID
    -- NO UI
    --==================================================

    if
        Result
        and Result.success == true
        and Result.valid == true
    then

        print(
            "[YOKUDO] Key valid."
        )

        LoadGameLoader()

        return
    end

    --==================================================
    -- REASON
    --==================================================

    local Reason =
        Result
        and Result.reason
        or
        Result
        and Result.error
        or
        "unknown"

    Reason =
        tostring(Reason)

    print(
        "[YOKUDO] Verify failed: "
        .. Reason
    )

    --==================================================
    -- WRONG KEY
    -- KICK
    --==================================================

    if
        Reason == "key_not_found"
        or
        Reason == "hwid_mismatch"
    then

        DeleteSavedKey()

        KickPlayer()

        return
    end

    --==================================================
    -- EXPIRED
    -- DELETE + SHOW UI
    --==================================================

    if Reason == "key_expired" then

        DeleteSavedKey()

    --==================================================
    -- REVOKED
    -- DELETE + SHOW UI
    --==================================================

    elseif Reason == "key_revoked" then

        DeleteSavedKey()

    end

end

--==================================================
-- CREATE UI
--==================================================

local ScreenGui =
    Instance.new("ScreenGui")

ScreenGui.Name =
    "YokudoKeySystem"

ScreenGui.ResetOnSpawn =
    false

ScreenGui.ZIndexBehavior =
    Enum.ZIndexBehavior.Sibling

pcall(function()

    ScreenGui.Parent =
        game:GetService("CoreGui")

end)

if not ScreenGui.Parent then

    ScreenGui.Parent =
        LocalPlayer:WaitForChild(
            "PlayerGui"
        )

end

--==================================================
-- MAIN FRAME
--==================================================

local Main =
    Instance.new("Frame")

Main.Name =
    "Main"

Main.Size =
    UDim2.new(
        0,
        390,
        0,
        280
    )

Main.Position =
    UDim2.new(
        0.5,
        -195,
        0.5,
        -140
    )

Main.BackgroundColor3 =
    Color3.fromRGB(
        20,
        20,
        24
    )

Main.BorderSizePixel =
    0

Main.Parent =
    ScreenGui

local MainCorner =
    Instance.new("UICorner")

MainCorner.CornerRadius =
    UDim.new(
        0,
        12
    )

MainCorner.Parent =
    Main

--==================================================
-- TITLE
--==================================================

local Title =
    Instance.new("TextLabel")

Title.Size =
    UDim2.new(
        1,
        -20,
        0,
        35
    )

Title.Position =
    UDim2.new(
        0,
        10,
        0,
        8
    )

Title.BackgroundTransparency =
    1

Title.Text =
    "YOKUDO HUB"

Title.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

Title.TextSize =
    20

Title.Font =
    Enum.Font.GothamBold

Title.TextXAlignment =
    Enum.TextXAlignment.Left

Title.Parent =
    Main

--==================================================
-- SUBTITLE
--==================================================

local SubTitle =
    Instance.new("TextLabel")

SubTitle.Size =
    UDim2.new(
        1,
        -20,
        0,
        20
    )

SubTitle.Position =
    UDim2.new(
        0,
        10,
        0,
        34
    )

SubTitle.BackgroundTransparency =
    1

SubTitle.Text =
    "KEY SYSTEM"

SubTitle.TextColor3 =
    Color3.fromRGB(
        145,
        145,
        155
    )

SubTitle.TextSize =
    11

SubTitle.Font =
    Enum.Font.GothamMedium

SubTitle.TextXAlignment =
    Enum.TextXAlignment.Left

SubTitle.Parent =
    Main

--==================================================
-- KEY BOX
--==================================================

local KeyBox =
    Instance.new("TextBox")

KeyBox.Name =
    "KeyBox"

KeyBox.Size =
    UDim2.new(
        1,
        -30,
        0,
        45
    )

KeyBox.Position =
    UDim2.new(
        0,
        15,
        0,
        65
    )

KeyBox.BackgroundColor3 =
    Color3.fromRGB(
        30,
        30,
        36
    )

KeyBox.BorderSizePixel =
    0

KeyBox.PlaceholderText =
    "Enter your YOKUDO key..."

KeyBox.PlaceholderColor3 =
    Color3.fromRGB(
        105,
        105,
        115
    )

KeyBox.Text =
    ""

KeyBox.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

KeyBox.TextSize =
    14

KeyBox.Font =
    Enum.Font.Gotham

KeyBox.ClearTextOnFocus =
    false

KeyBox.Parent =
    Main

local KeyCorner =
    Instance.new("UICorner")

KeyCorner.CornerRadius =
    UDim.new(
        0,
        8
    )

KeyCorner.Parent =
    KeyBox

--==================================================
-- GET KEY BUTTON
--==================================================

local GetKeyButton =
    Instance.new("TextButton")

GetKeyButton.Name =
    "GetKey"

GetKeyButton.Size =
    UDim2.new(
        0.48,
        -7,
        0,
        42
    )

GetKeyButton.Position =
    UDim2.new(
        0,
        15,
        0,
        122
    )

GetKeyButton.BackgroundColor3 =
    Color3.fromRGB(
        40,
        40,
        48
    )

GetKeyButton.BorderSizePixel =
    0

GetKeyButton.Text =
    "GET KEY"

GetKeyButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

GetKeyButton.TextSize =
    13

GetKeyButton.Font =
    Enum.Font.GothamBold

GetKeyButton.Parent =
    Main

local GetCorner =
    Instance.new("UICorner")

GetCorner.CornerRadius =
    UDim.new(
        0,
        8
    )

GetCorner.Parent =
    GetKeyButton

--==================================================
-- VERIFY BUTTON
--==================================================

local VerifyButton =
    Instance.new("TextButton")

VerifyButton.Name =
    "Verify"

VerifyButton.Size =
    UDim2.new(
        0.48,
        -7,
        0,
        42
    )

VerifyButton.Position =
    UDim2.new(
        0.52,
        -8,
        0,
        122
    )

VerifyButton.BackgroundColor3 =
    Color3.fromRGB(
        70,
        70,
        78
    )

VerifyButton.BorderSizePixel =
    0

VerifyButton.Text =
    "VERIFY KEY"

VerifyButton.TextColor3 =
    Color3.fromRGB(
        255,
        255,
        255
    )

VerifyButton.TextSize =
    13

VerifyButton.Font =
    Enum.Font.GothamBold

VerifyButton.Parent =
    Main

local VerifyCorner =
    Instance.new("UICorner")

VerifyCorner.CornerRadius =
    UDim.new(
        0,
        8
    )

VerifyCorner.Parent =
    VerifyButton

--==================================================
-- STATUS
--==================================================

local Status =
    Instance.new("TextLabel")

Status.Name =
    "Status"

Status.Size =
    UDim2.new(
        1,
        -30,
        0,
        65
    )

Status.Position =
    UDim2.new(
        0,
        15,
        0,
        177
    )

Status.BackgroundTransparency =
    1

Status.Text =
    "Please enter your key."

Status.TextColor3 =
    Color3.fromRGB(
        170,
        170,
        180
    )

Status.TextSize =
    13

Status.Font =
    Enum.Font.Gotham

Status.TextWrapped =
    true

Status.Parent =
    Main

--==================================================
-- FOOTER
--==================================================

local Footer =
    Instance.new("TextLabel")

Footer.Size =
    UDim2.new(
        1,
        -20,
        0,
        20
    )

Footer.Position =
    UDim2.new(
        0,
        10,
        1,
        -25
    )

Footer.BackgroundTransparency =
    1

Footer.Text =
    "YOKUDO HUB • Secure Key System"

Footer.TextColor3 =
    Color3.fromRGB(
        90,
        90,
        100
    )

Footer.TextSize =
    10

Footer.Font =
    Enum.Font.GothamMedium

Footer.Parent =
    Main

--==================================================
-- STATUS FUNCTION
--==================================================

local function SetStatus(Text)

    Status.Text =
        tostring(Text)

end

--==================================================
-- VERIFY INPUT
--==================================================

local Verifying = false

local function VerifyInputKey(Key)

    if Verifying then
        return
    end

    Verifying = true

    VerifyButton.Text =
        "VERIFYING..."

    SetStatus(
        "Checking your key..."
    )

    local Result =
        VerifyKeyRequest(
            Key
        )

    --==================================================
    -- VALID
    --==================================================

    if
        Result
        and Result.success == true
        and Result.valid == true
    then

        SaveKey(Key)

        SetStatus(
            "Key verified!\n"
            .. "Loading YOKUDO HUB..."
        )

        task.wait(0.25)

        ScreenGui:Destroy()

        LoadGameLoader()

        Verifying = false

        return
    end

    --==================================================
    -- REASON
    --==================================================

    local Reason =
        Result
        and Result.reason
        or
        Result
        and Result.error
        or
        "unknown"

    Reason =
        tostring(Reason)

    --==================================================
    -- WRONG KEY
    --==================================================

    if
        Reason == "key_not_found"
        or
        Reason == "hwid_mismatch"
    then

        DeleteSavedKey()

        Verifying = false

        KickPlayer()

        return
    end

    --==================================================
    -- EXPIRED
    --==================================================

    if Reason == "key_expired" then

        DeleteSavedKey()

        KeyBox.Text =
            ""

        VerifyButton.Text =
            "VERIFY KEY"

        SetStatus(
            "Key expired.\n"
            .. "Please get a new key."
        )

        Verifying = false

        return
    end

    --==================================================
    -- REVOKED
    --==================================================

    if Reason == "key_revoked" then

        DeleteSavedKey()

        KeyBox.Text =
            ""

        VerifyButton.Text =
            "VERIFY KEY"

        SetStatus(
            "Key revoked.\n"
            .. "Please get a new key."
        )

        Verifying = false

        return
    end

    --==================================================
    -- OTHER ERROR
    --==================================================

    VerifyButton.Text =
        "VERIFY KEY"

    SetStatus(
        "Verification error:\n"
        .. Reason
    )

    Verifying = false
end

--==================================================
-- GET KEY
--==================================================

GetKeyButton.MouseButton1Click:Connect(function()

    if Verifying then
        return
    end

    GetKeyButton.Text =
        "LOADING..."

    SetStatus(
        "Creating access link..."
    )

    local Success, Response =
        pcall(function()

            return Request({

                Url =
                    GET_LINK_URL,

                Method =
                    "POST",

                Headers = {

                    ["Content-Type"] =
                        "application/json"

                },

                Body =
                    HttpService:JSONEncode({})

            })

        end)

    if
        not Success
        or
        not Response
        or
        not Response.Body
    then

        GetKeyButton.Text =
            "GET KEY"

        SetStatus(
            "Failed to create access link."
        )

        return
    end

    local DecodeSuccess, Data =
        pcall(function()

            return HttpService:JSONDecode(
                Response.Body
            )

        end)

    if
        not DecodeSuccess
        or
        not Data
        or
        Data.success ~= true
    then

        GetKeyButton.Text =
            "GET KEY"

        SetStatus(
            "Failed to create access link."
        )

        return
    end

    local Link =
        Data.url
        or
        Data.shortUrl
        or
        Data.shortenedUrl

    if not Link then

        GetKeyButton.Text =
            "GET KEY"

        SetStatus(
            "No access link returned."
        )

        return
    end

    CopyText(Link)

    GetKeyButton.Text =
        "GET KEY"

    SetStatus(
        "Access link copied!\n"
        .. "Complete the steps, then enter your key."
    )

end)

--==================================================
-- VERIFY BUTTON
--==================================================

VerifyButton.MouseButton1Click:Connect(function()

    local Key =
        tostring(
            KeyBox.Text or ""
        ):match(
            "^%s*(.-)%s*$"
        )

    if Key == "" then

        SetStatus(
            "Please enter your key."
        )

        return
    end

    VerifyInputKey(Key)

end)

--==================================================
-- FINAL
--==================================================

print("========================================")
print("        YOKUDO HUB KEY SYSTEM")
print("========================================")
print(
    "PlaceId: "
    .. tostring(game.PlaceId)
)
print(
    "Saved Key: "
    .. tostring(SavedKey ~= nil)
)
print("Verify Before UI: ENABLED")
print("UI Drag: DISABLED")
print("========================================")
