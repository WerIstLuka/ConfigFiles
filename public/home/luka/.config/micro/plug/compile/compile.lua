local buffer = import("micro/buffer")
local config = import("micro/config")
local goos = import("os")
local micro = import("micro")
local time = import("time")
local screen = import("screen")

VERSION = "1.0.0"
compileRunning = false

local function appendToBuffer(bp, text)
	bp.Buf:Replace(bp.Buf:End(), bp.Buf:End(), text.."\n")
end

local function beginBuffer(bp, text)
	bp.Buf:Replace(bp.Buf:Start(), bp.Buf:End(), text)
	appendToBuffer(bp, "\n\n")
	local dateTime = os.date("%Y/%m/%d %X")
	appendToBuffer(bp, "Compilation started at "..dateTime)
end

local function endBuffer(bp, exitCode)
	local dateTime = os.date("%Y/%m/%d %X")
	if exitCode == 0 then
		appendToBuffer(bp, "Compilation succeded at "..dateTime)
	else
		appendToBuffer(bp, "Compilation failed at "..dateTime)
	end
end

local function updateBuffer(bp)
	local i = 0
	appendToBuffer(bp, output)
	while true do
		if i == 10 then
			return
		end
		appendToBuffer(bp, string.format(i))
		i = i + 1
		time.Sleep(time.Millisecond*50)
	end
end

function createBuffer(bp, args)
	if #args == 0 then
		micro.InfoBar():Error("no compile command given")
		return
	end
	local b = buffer.NewBuffer("", "")
	b:SetName("compile")
	b:SetOption("filetype", "compile")
	b.Type.Scratch = true
	b.Type.Readonly = true
	bp:HSplitAction()
	micro.CurPane():OpenBuffer(b)

	local text = ""
	for i = 1, #args do
		text = text .. args[i]
		text = text .. " "
	end
	text = text:sub(1, -2)

	compileRunning = true
	beginBuffer(micro.CurPane(), text)
	updateBuffer(micro.CurPane())
	-- endBuffer()
end

function init()
	config.MakeCommand("compile", createBuffer, config.FileComplete)
end

-- make it so when pressing close it prioritizes compile paneing close it prio
