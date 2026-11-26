local micro = import("micro")
local config = import("micro/config")
local util = import("micro/util")

function init()
    config.MakeCommand("si", selectInnerCommand, config.NoComplete)
    config.MakeCommand("so", selectOuterCommand, config.NoComplete)
end

function parseTokenPairArgs(args)
    local allPairs = {
        ["["] = "]",
        ["("] = ")",
        ["{"] = "}",
        ["<"] = ">",
    }
    if args ~= nil and #args > 0 then
        -- replace empty string with " so users can do `si ""` as alias for `si \"`
        local startTok = args[1]:gsub("^$", '"')
        local endTok = #args > 1 and args[2]:gsub("^$", '"') or startTok:gsub("[%(%[{<]", allPairs)
        return { [startTok] = endTok }
    end
    -- defaults
    return {
        ["["] = "]",
        ["("] = ")",
        ["{"] = "}",
    }
end

function selectOuterCommand(bp, args)
    selectInner(bp, parseTokenPairArgs(args), true)
end

function selectInnerCommand(bp, args)
    selectInner(bp, parseTokenPairArgs(args), false)
end

function selectInner(bp, tokenPairs, includeDelims)
    local buf = bp.Buf
    local cursor = buf:GetActiveCursor()

    local function tryToFind(startTok, endTok, from)
        local startLoc = cursor.Loc:Move(-1, buf)
        local endLoc = -cursor.Loc
        local skips = 0
        local foundStart = false
        local foundEnd = false

        while startLoc:GreaterEqual(from) and startLoc:LessEqual(buf:End():Move(-#startTok, buf)) do
            if util.String(buf:Substr(startLoc, startLoc:Move(#startTok, buf))) == startTok then
                if skips > 0 then
                    skips = skips - 1
                else
                    foundStart = true
                    break
                end
            elseif startLoc:LessEqual(buf:End():Move(-#endTok, buf))
            and util.String(buf:Substr(startLoc, startLoc:Move(#endTok, buf))) == endTok
            then
                skips = skips + 1
            end
            startLoc = startLoc:Move(-1, buf)
        end

        if not foundStart then
            return false, nil, nil
        end

        while endLoc:LessEqual(buf:End():Move(-#endTok, buf)) do
            if util.String(buf:Substr(endLoc, endLoc:Move(#endTok, buf))) == endTok then
                if skips == 0 then
                    return true, startLoc, endLoc
                end
                skips = skips - 1
            elseif endLoc:LessEqual(buf:End():Move(-#startTok, buf))
            and util.String(buf:Substr(endLoc, endLoc:Move(#startTok, buf))) == startTok
            then
                skips = skips + 1
            end
            endLoc = endLoc:Move(1, buf)
        end

        return false, nil, nil
    end

    local foundStart = nil
    local foundEnd = nil
    for startTok, endTok in pairs(tokenPairs) do
        local from = foundStart and foundStart:Move(1, buf) or buf:Start()
        local found, startLoc, endLoc = tryToFind(startTok, endTok, from)
        if found then
            if includeDelims then
                foundStart = startLoc
                foundEnd = endLoc:Move(#endTok, buf)
            else
                foundStart = startLoc:Move(#startTok, buf)
                foundEnd = endLoc
            end
        end
    end
    -- micro.InfoBar():Message("si/", tokenPairs, " found/", foundStart, "/", foundEnd)
    if foundStart then
        cursor:SetSelectionStart(foundStart)
        cursor:SetSelectionEnd(foundEnd)
    else
        micro.InfoBar():Message("siso: not found")
    end
end
