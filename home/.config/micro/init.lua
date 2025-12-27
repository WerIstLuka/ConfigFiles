local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")

function init()
    config.MakeCommand(
        "bashmode",
        function ()
            local callback = function (resp, canceled)
                if not canceled and resp ~= "" then
                    local bashCmd = string.format("bash -c '%s'", resp)
                    local waitForUser = true
                    local getOutput = false
                    shell.RunInteractiveShell(bashCmd, waitForUser, getOutput)
                end
            end
            micro.InfoBar():Prompt("$ ", "", "Bash", nil, callback)
        end,
        config.FileComplete
    )
end
