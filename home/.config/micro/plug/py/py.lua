local micro = import("micro")
local config = import("micro/config")

VERSION = "1.0.0"

function pyinsert(bp, args)
	if #args < 1 then
		micro.InfoBar():Error("usage: pyinsert arguments")
		return
	end

	text = ""
	for i = 1, #args do
		text = text .. args[i]
		text = text .. " "
	end

	exitCode = os.execute('python3 -c "print(' ..  text .. ')"' .. ' 2> /dev/null > /dev/null')
	if exitCode ~= 0 then
		local cmd = io.popen('python3 -c "print(' .. text .. ')"' .. ' 2> /dev/stdout')
		local err = cmd:read('*a')
		micro.InfoBar():Error(err)
		return
	end
    local cmd = io.popen('python3 -c "print(' .. text .. ')"')
    local output = cmd:read('*a')
    bp.Buf:Insert(-bp.Cursor.loc, output)
end

function pycmd(bp, args)
	if #args < 1 then
		micro.InfoBar():Error("usage: pycmd arguments")
		return
	end

	text = ""
	for i = 1, #args do
		text = text .. args[i]
		text = text .. " "
	end

	exitCode = os.execute('python3 -c "print(' ..  text .. ')"' .. ' 2> /dev/null > /dev/null')
	if exitCode ~= 0 then
		local cmd = io.popen('python3 -c "print(' .. text .. ')"' .. ' 2> /dev/stdout')
		local err = cmd:read('*a')
		micro.InfoBar():Error(err)
		return
	end
	local cmd = io.popen('python3 -c "print(' .. text .. ')"')
	local output = cmd:read('*a')
	micro.InfoBar():Message(output)
end

function init()
		config.MakeCommand("pyinsert", pyinsert, config.NoComplete)
		config.MakeCommand("pycmd", pycmd, config.NoComplete)
end
