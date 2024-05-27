local MAJOR_VERSION = "LibFramePool-1.0"
local MINOR_VERSION = 0
if not LibStub then
    error(MAJOR_VERSION .. " requires LibStub.")
end
local lib = LibStub:NewLibrary(MAJOR_VERSION, MINOR_VERSION)
if not lib then
    return
end

local PoolTable = {}

local function is_frames_arg_correct(frames)
    if #frames > 0 then
        if type(frames) ~= 'table' then
            error("frames arg has to be a range of frames stylized as {1, 7} or nil, instead got \"" .. frames .. "\" instead.")
            return false
        end
        if #frames ~= 2 then
            error("Expected two frame references in the table but got " .. #frames)
            return false
        end
        if frames[2] < frames[1] then
            error("Second frame position cannot be smaller than the first frame position.")
            return false
        end
        return true
    else
        return false
    end
end

---
---Creates a pool of frames of same type that are accessible by calling the library. All frames are hidden on creation.
---Usage: pool = lib:CreateFramePool(20, "CheckButton", {nil, frame, "ChatConfigCheckButtonTemplate"})
---@param numOfFrames Number of frames to create for the pool.
---@param frameType Frame type to create. Can be a button, frame, checkbutton, slider, etc...
---@param frameArgs Table of arguments to pass to the frame type.
---
function lib:CreateFramePool(numOfFrames, frameType, --[[optional]]frameArgs)
    local pool = {}
    setmetatable(pool, { __index = PoolTable })
    if frameArgs ~= nil then
        if type(frameArgs) ~= 'table' then
            error("frameArgs needs to be a table, but got type " .. type(frameArgs))
        end
        for i = 1, tonumber(numOfFrames) do
            pool[#pool + 1] = { frame = CreateFrame(frameType, unpack(frameArgs)) }
            pool[i].frame:Hide()
        end
    else
        for i = 1, tonumber(numOfFrames) do
            pool[#pool + 1] = { frame = CreateFrame(frameType) }
            pool[i].frame:Hide()
        end
    end
    return pool
end

---
---Since frames cannot be removed from memory, the closest possible thing is to nullify the frames inside. Generally
--- bad practice because it's better to reuse frames, but if truly needed, can be used. The reference to all frames will
--- stay in memory until the UI is reloaded.
---Usage: lib:DeleteFramePool(ObjectName)
---
function lib:DeleteFramePool(Pool)
    if getmetatable(Pool).__index == PoolTable then
        for i in ipairs(Pool) do
            Pool[i].frame = nil
        end
    end
end

function lib:IncrementallyChangeXForAllFrames(Pool, point, initialOffsetX, incrementalOffsetX, --[[optional]]frames)
    frames = frames or {}
    if getmetatable(Pool).__index == PoolTable then
        if is_frames_arg_correct(frames) == true then
            for i = frames[1], frames[2] do
                local y = 0
                if select(5, Pool[i].frame:GetPoint()) ~= nil then
                    y = select(5, Pool[i].frame:GetPoint())
                end
                Pool[i].frame:SetPoint(point, initialOffsetX, y)
                initialOffsetX = initialOffsetX + incrementalOffsetX
            end
        else
            for i = 1, #Pool do
                local y = 0
                if select(5, Pool[i].frame:GetPoint()) ~= nil then
                    y = select(5, Pool[i].frame:GetPoint())
                end
                Pool[i].frame:SetPoint(point, initialOffsetX, y)
                initialOffsetX = initialOffsetX + incrementalOffsetX
            end
        end
    end
end

function lib:IncrementallyChangeYForAllFrames(Pool, point, initialOffsetY, incrementalOffsetY, --[[optional]]frames)
    frames = frames or {}
    if getmetatable(Pool).__index == PoolTable then
        if is_frames_arg_correct(frames) == true then
            for i = frames[1], frames[2] do
                local x = 0
                if select(4, Pool[i].frame:GetPoint()) ~= nil then
                    x = select(4, Pool[i].frame:GetPoint())
                end
                Pool[i].frame:SetPoint(point, x, initialOffsetY)
                initialOffsetY = initialOffsetY + incrementalOffsetY
            end
        else
            for i = 1, #Pool do
                local x = 0
                if select(4, Pool[i].frame:GetPoint()) ~= nil then
                    x = select(4, Pool[i].frame:GetPoint())
                end
                Pool[i].frame:SetPoint(point, x, initialOffsetY)
                initialOffsetY = initialOffsetY + incrementalOffsetY
            end
        end
    end
end

function lib:SetOnClickScript(Pool, script, --[[optional]]frames)
    frames = frames or {}
    if getmetatable(Pool).__index == PoolTable then
        if type(script) ~= 'function' then
            error("script arg has to be a function")
        else
            if is_frames_arg_correct(frames) == true then
                for i = frames[1], frames[2] do
                    Pool[i].frame:SetScript("OnClick", script)
                end
            else
                for i = 1, #Pool do
                    Pool[i].frame:SetScript("OnClick", script)
                end
            end
        end
    end
end

function lib:SetOnEventScript(Pool, script, --[[optional]]frames)
    frames = frames or {}
    if getmetatable(Pool).__index == PoolTable then
        if type(script) ~= 'function' then
            error("script arg has to be a function")
        else
            if is_frames_arg_correct(frames) == true then
                for i = frames[1], frames[2] do
                    Pool[i].frame:SetScript("OnEvent", script)
                end
            else
                for i = 1, #Pool do
                    Pool[i].frame:SetScript("OnEvent", script)
                end
            end
        end
    end
end

function lib:HideFrames(Pool, --[[optional]]frames)
    frames = frames or {}
    if getmetatable(Pool).__index == PoolTable then
        if is_frames_arg_correct(frames) == true then
            for i = frames[1], frames[2] do
                Pool[i].frame:Hide()
            end
        else
            for i = 1, #Pool do
                Pool[i].frame:Hide()
            end
        end
    end
end

function lib:ShowFrames(Pool, --[[optional]]frames)
    frames = frames or {}
    if getmetatable(Pool).__index == PoolTable then
        if is_frames_arg_correct(frames) == true then
            for i = frames[1], frames[2] do
                Pool[i].frame:Show()
            end
        else
            for i = 1, #Pool do
                Pool[i].frame:Show()
            end
        end
    end
end