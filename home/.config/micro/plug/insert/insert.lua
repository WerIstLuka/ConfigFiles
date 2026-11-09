local micro = import("micro")
local config = import("micro/config")

VERSION = "1.0.0"

function insert(bp, args)
	if #args < 1 then
		micro.InfoBar():Error("usage: insert arguments")
		return
	end

	text = ""
	for i = 1, #args do
		text = text .. args[i]
		text = text .. " "
	end

	exitCode = os.execute('bash -c "' .. text .. '"' .. ' 2> /dev/null > /dev/null')
	if exitCode ~= 0 then
		local cmd = io.popen('bash -c "' .. text .. '"' .. ' 2> /dev/stdout')
		local err = cmd:read('*a')
		micro.InfoBar():Error(err)
		return
	end
    local cmd = io.popen('bash -c "' .. text .. '"')
    local output = cmd:read('*a')
    bp.Buf:Insert(-bp.Cursor.loc, output)
end

function init()
		config.MakeCommand("insert", insert, config.FileComplete)
end
