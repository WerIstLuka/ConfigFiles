local micro = import("micro")
local config = import("micro/config")
local shell = import("micro/shell")

VERSION = "1.0.0"

function runCommand()
    local callback = function (resp, canceled)
        if not canceled and resp ~= "" then
            local bashCmd = string.format("bash -c '%s'", resp)
            local waitForUser = true
            local getOutput = false
            shell.RunInteractiveShell(bashCmd, waitForUser, getOutput)
        end
    end
    micro.InfoBar():Prompt("$ ", "", "Bash", nil, callback)
end

function runShell()
    shell.RunInteractiveShell("bash -c 'NOFETCH=true bash'", false, true)
end

function init()
        config.MakeCommand("cmd", runCommand, config.NoComplete)
        config.MakeCommand("bash", runShell, config.NoComplete)
        config.MakeCommand("shell", runShell, config.NoComplete)
end
