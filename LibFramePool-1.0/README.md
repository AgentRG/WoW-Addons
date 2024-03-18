# LibFramePool-1.0
### About:
Creates a table containing _n_ amount of frames of the same type with optional argument to predefine the frames. Since
a table is being returned on creation, the created variable can be looped using a loop of your choice to make changes
to the frames, or individual frames called upon based on their index position.

### Usage:
local lib = LibStub("LibFramePool-1.0")

pool = lib:CreateFramePool(20, "CheckButton", {nil, parentFrame, "ChatConfigCheckButtonTemplate"})

lib:SetOnClickScript(pool, function() print("Hello world!") end)

### Available functions:
* `CreateFramePool(numOfFrames, frameType[, frameArgs])`
* `DeleteFramePool(Pool)`
* `IncrementallyChangeXForAllFrames(Pool, point, initialOffsetX, incrementalOffsetX[, frames])`
* `IncrementallyChangeYForAllFrames(Pool, point, initialOffsetY, incrementalOffsetY[, frames])`
* `SetOnClickScript(Pool, script[, frames])`
* `SetOnEventScript(Pool, script[, frames])`
* `HideFrames(Pool[, frames])`
* `ShowFrames(Pool[, frames])`

Since the object returned by `CreateFramePool` is a table, it can also be iterated to run other WoW functions on them:

        for i = 1, #pool do
            if r == 3 then
                y = y - 20
                x = 8
                r = 0
            end
            pool[i].frame:SetPoint("TOPLEFT", x, y)
            x = x + 200
            r = r + 1
        end

The previous for loop will move the frames to look like this:

    x        x        x
    x        x        x
    x        x        x