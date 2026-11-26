global import: function(string): any

global record MouseEvent
	Position: function(self: MouseEvent): MicroLoc
end

global record MicroInfobar
	Error: function(self: MicroInfobar, ...: string)
	Message: function(self: MicroInfobar, ...: string)
	Info: function(self: MicroInfobar, ...: string)
	Prompt: function(self: MicroInfobar, prompt: string, msg: string, ptype: string, eventcb: function(string), donecb: function(string, boolean))
	YNPrompt: function(self: MicroInfobar, prompt: string, donecb: function(boolean, boolean))
end

global record MicroBase
	InfoBar: function(): MicroInfobar
	CurPane: function(): MicroBufPane
end

global record MicroShell
	RunInteractiveShell: function(input: string, wait: boolean, getOutput: boolean): string, GoError
end
	
global record MicroBuffer
	Loc: function(x: integer, y: integer): MicroLoc
	NewBuffer: function(text:string, path:string): MicroBuf
	NewBufferFromFile: function(path: string): MicroBuf, GoError
end

global record MicroIO
	Copy: function(dst:GoFile, src:GoFile): integer,GoError 
end

global record GoError
	Error: function(self: GoError): string
end

global record GoFileInfo
	Name: function(self: GoFileInfo): string
	Size: function(self: GoFileInfo): integer
	Mode: function(self: GoFileInfo): integer
	ModTime: function(self: GoFileInfo): GoTime
	IsDir: function(self: GoFileInfo): boolean
	Sys: function(self: GoFileInfo): any
end

global record GoFile
	Close: function(self: GoFile): GoError
end

global record MicroOS
	Lstat: function(path: string):GoFileInfo,GoError
	MkdirAll: function(path: string, perm:integer): GoError
	Readlink: function(name: string): string, GoError
	Symlink: function(old: string, new:string): GoError
	Open: function(name:string): GoFile, GoError
	OpenFile: function(name: string, flag:integer, perm:integer): GoFile, GoError
	Rename: function(old: string, new: string): GoError
	RemoveAll: function(name: string): GoError
	Getwd: function(): string
	O_EXCL: integer
	O_CREATE: integer
	O_WRONLY: integer
end

global record MicroLoc
	X: integer
	Y: integer
end

global record MicroCursor
	X: integer
	Y: integer 
	CurSelection: {MicroLoc}
	HasSelection: function(self: MicroCursor): boolean
	GetSelection: function(self: MicroCursor): string
	DeleteSelection: function(self: MicroCursor)
	GotoLoc: function(self: MicroCursor, loc: MicroLoc)
end

global record MicroBufType
	Scratch: boolean
	Readonly: boolean
end

global record MicroBuf
	Path: string
	AbsPath: string
	FileType: function(self: MicroBuf): string
	GetName: function(self: MicroBuf): string
	Line: function(self: MicroBuf, n: integer): string
	LinesNum: function(self: MicroBuf): integer
	GetActiveCursor: function(self:MicroBuf): MicroLoc
	Replace: function(self: MicroBuf, s: MicroLoc, e: MicroLoc, t:string)
	Start: function(self: MicroBuf): MicroLoc
	End: function(self: MicroBuf): MicroLoc
	SetName: function(self: MicroBuf, name: string)
	SetOption: function(self: MicroBuf, opt: string, val:any)
	Type: MicroBufType
end

global record MicroBufPane
	Buf: MicroBuf
	Cursor: MicroCursor
	Save: function(self: MicroBufPane): boolean
	Quit: function(self: MicroBufPane): boolean
	HandleCommand: function(self: MicroBufPane, input: string)
	CursorStart: function(self: MicroBufPane)
	CursorEnd: function(self: MicroBufPane)
	Relocate: function(self: MicroBufPane)
	VSplitAction: function(self: MicroBufPane)
	HSplitAction: function(self: MicroBufPane)
	AddTab: function(self: MicroBufPane)
	OpenBuffer: function(self: MicroBufPane, buf: MicroBuf)
	LocFromVisual: function(self: MicroBufPane, loc:MicroLoc): MicroLoc
end

global record MicroConfig
	GetGlobalOption: function(name:string): any
	MakeCommand: function(name: string, action: function(MicroBufPane, {string}), completer:any)
	NoComplete: any
	RegisterCommonOption: function(pl:string, name:string, defaultValue:any)
end

global record GoIOutil
	ReadDir: function(path:string): {GoFileInfo}, GoError
	WriteFile: function(filename: string, data: string, perm: integer): GoError
end

global record GoPathFilepath
	Join: function(path: string, path2:string): string
	Base: function(path: string): string
	Clean: function(path: string): string
	Dir: function(path: string): string
	Ext: function(path: string): string
	IsAbs: function(path: string): boolean
	Abs: function(path: string): string, GoError
	ToSlash: function(path: string): string
end

global record GoTime
	Now: function(): GoTime
	Unix: function(self: GoTime): integer
	Format: function(self: GoTime, fmt: string): string
end
