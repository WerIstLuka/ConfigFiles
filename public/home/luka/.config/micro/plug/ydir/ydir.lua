local _tl_compat
if (tonumber((_VERSION or ''):match('[%d.]*$')) or 0) < 5.3 then
   local p, m = pcall(require, 'compat53.module')
   if p then
      _tl_compat = m
   end
end
local ipairs = _tl_compat and _tl_compat.ipairs or ipairs
local math = _tl_compat and _tl_compat.math or math
local string = _tl_compat and _tl_compat.string or string
local table = _tl_compat and _tl_compat.table or table
local micro = import("micro")
local shell = import("micro/shell")
local buffer = import("micro/buffer")
local config = import("micro/config")
local goos = import("os")
local goio = import("io")
local ioutil = import("io/ioutil")
local filepath = import("path/filepath")
local time = import("time")

local YDIR_BUFFER_TYPE_READONLY = "ydir"
local YDIR_BUFFER_TYPE_WRITEABLE = "ydir-writeable"
local YDIR_LISTING_START = 3
local YDIR_BACKSPACE_HISTORY_LENGTH = 100

local NERD_DIR = ""
local NERD_FILE = ""
local NERD_LOOKUP = {

   ["readme"] = "", ["license"] = "",
   [".txt"] = "",

   [".md"] = "󰽛", [".html"] = "",
   [".css"] = "", [".scss"] = "",

   [".lua"] = "", [".c"] = "",
   [".cpp"] = "", [".cs"] = "",
   [".py"] = "", [".php"] = "",
   [".sh"] = "", [".java"] = "",
   [".js"] = "", ["makefile"] = "",
   [".go"] = "󰟓", [".ts"] = "",
   [".kt"] = "", [".svelte"] = "",
   [".vue"] = "",

   [".lock"] = "", [".gitignore"] = "",
   [".yml"] = "", [".yaml"] = "",
   [".json"] = "", [".xml"] = "󰗀",
   [".ini"] = "", [".cfg"] = "",
   [".sql"] = "", [".toml"] = "",
   [".csv"] = "", [".db"] = "",

   [".png"] = "", [".jpg"] = "",
   [".gif"] = "", [".svg"] = "",

   [".zip"] = "", [".pdf"] = "",
   [".wasm"] = "", [".gz"] = "",
}








local function hasbit(mode, n)
   return math.floor(mode / 2 ^ n) % 2 == 1
end

local function is_regular(mode)
   for _, n in ipairs({ 31, 27, 26, 25, 24, 21, 19 }) do
      if hasbit(mode, n) then return false end
   end
   return true
end

local function fmode_to_string(mode)
   local kind = "-"
   if hasbit(mode, 31) then kind = "d"
   elseif hasbit(mode, 27) then kind = "l"
   elseif hasbit(mode, 25) then kind = "p"
   elseif hasbit(mode, 24) then kind = "s"
   elseif hasbit(mode, 26) then
      kind = hasbit(mode, 21) and "c" or "b"
   end

   local rwx = { "r", "w", "x" }
   local out = {}
   for i = 0, 8 do
      out[i + 1] = hasbit(mode, 8 - i) and rwx[(i % 3) + 1] or "-"
   end


   if hasbit(mode, 23) then out[3] = (out[3] == "x") and "s" or "S" end
   if hasbit(mode, 22) then out[6] = (out[6] == "x") and "s" or "S" end
   if hasbit(mode, 20) then out[9] = (out[9] == "x") and "t" or "T" end

   return kind .. table.concat(out)
end


local function starts_with(str, prefix)
   return str:sub(1, #prefix) == prefix
end

local function command_options(opts)
   return function(bp)
      local line = bp:Line(0)
      local before = line:sub(1, bp:GetActiveCursor().X)
      local input = before:match("([^%s]*)$") or ""
      local completions = {}
      local suggestions = {}
      for _, opt in ipairs(opts) do
         if starts_with(opt, input) then
            table.insert(suggestions, opt)
            table.insert(completions, opt:sub(#input + 1))
         end
      end
      return completions, suggestions
   end
end

local function copy_single(src, dst)
   local info, err = goos.Lstat(src)
   if err ~= nil then return err:Error() end
   local perm = info:Mode() % 512
   if info:IsDir() then

      if starts_with(dst, src) then

         return "Recursion detected, abort"
      end

      err = goos.MkdirAll(dst, perm)
      if err ~= nil then return err:Error() end

      local entries, derr = ioutil.ReadDir(src)
      if derr ~= nil then return err:Error() end
      for i = 1, #entries do
         local name = entries[i]:Name()
         local cerr = copy_single(
         filepath.Join(src, name),
         filepath.Join(dst, name))

         if err ~= nil then return cerr end
      end
      return nil
   end

   if not is_regular(info:Mode()) then
      local target, serr = goos.Readlink(src)
      if serr ~= nil then return serr:Error() end
      err = goos.Symlink(target, dst)
      if err ~= nil then return err:Error() end
      return nil
   end

   local input, ferr = goos.Open(src)
   if ferr ~= nil then return ferr:Error() end

   local output, ferr2 = goos.OpenFile(
   dst,

   goos.O_WRONLY +
   goos.O_CREATE +
   goos.O_EXCL,
   perm)

   if ferr2 ~= nil then
      input:Close()
      return ferr2:Error()
   end

   local _, cerr = goio.Copy(output, input)
   input:Close()
   if cerr ~= nil then return cerr:Error() end
   err = output:Close()
   if err == nil then
      return nil
   end
   return err:Error()
end

local function copy_paths(src_paths, dst)
   for i = 1, #src_paths do
      local src = src_paths[i]
      local target = filepath.Join(dst, filepath.Base(src))
      local err = copy_single(src, target)
      if err ~= nil then return err end
   end
   return nil
end

local function move_single(src, dst)
   local err = goos.Rename(src, dst)
   if err ~= nil then
      local cerr = copy_single(src, dst)
      if cerr ~= nil then return cerr end
      err = goos.RemoveAll(src)
      return err:Error()
   end
end

local function move_paths(src_paths, dst)
   for i = 1, #src_paths do
      local src = src_paths[i]
      local target = filepath.Join(dst, filepath.Base(src))
      local merr = move_single(src, target)
      if merr ~= nil then return merr end
   end
   return nil
end

local function create_path(base, rel_path)
   local path = filepath.Join(base, rel_path)
   local is_dir = rel_path:sub(-1) == "/"

   local dir = path
   if not is_dir then dir = filepath.Dir(path) end

   local err = goos.MkdirAll(dir, 493)
   if err ~= nil then
      micro.InfoBar():Error(err:Error())
      return false
   end

   if is_dir then return true end


   local _, serr = goos.Lstat(path)
   if serr == nil then
      micro.InfoBar():Error("File `" .. path .. "` already exists!")
      return false
   end

   local err2 = ioutil.WriteFile(path, "", 420)
   if err2 ~= nil then
      micro.InfoBar():Error(err2:Error())
      return false
   end
   return true
end

function ydir_buffer_type(bp)
   if bp.Buf:FileType() == YDIR_BUFFER_TYPE_READONLY then return "readonly" end
   if bp.Buf:FileType() == YDIR_BUFFER_TYPE_WRITEABLE then return "writeable" end
   return nil
end

function is_ydir_buffer(bp)
   return ydir_buffer_type(bp) ~= nil
end










local backspace_history = {}
local backspace_history_idx = 1

local function get_history_index(path)
   for i = 1, #backspace_history do
      if backspace_history[i] and path == backspace_history[i]["path"] then
         return i
      end
   end
   return nil
end

local function get_history(path)
   local idx = get_history_index(path)
   if idx == nil then return nil end
   return backspace_history[idx]["element"]
end

local function add_history(path, entry)
   local idx = get_history_index(path)
   if idx ~= nil then

      backspace_history[idx] = nil
   end


   backspace_history[backspace_history_idx] = {
      path = path,
      element = entry,
   }


   backspace_history_idx = backspace_history_idx + 1
   if backspace_history_idx > YDIR_BACKSPACE_HISTORY_LENGTH then
      backspace_history_idx = 1
   end
end






local function format_size(size)
   if not size then return "  N/A " end

   if size < 1000 then
      return string.format("%5dB", size)
   end

   local units = { "K", "M", "G", "T", "P" }
   local value, i = size / 1024, 1



   while value >= 999.95 and i < #units do
      value = value / 1024
      i = i + 1
   end
   return string.format("%5.1f%s", value, units[i])
end


local function format_date(t)
   local age = time.Now():Unix() - t:Unix()
   if age < 0 or age > config.GetGlobalOption("ydir.DateSwitchAmount") then
      return t:Format("Jan _2  2006")
   else
      return t:Format("Jan _2 15:04")
   end
end


local function format_perm(perm)
   return fmode_to_string(perm)
end





local function dir_as_list(path)
   local entries, err = ioutil.ReadDir(path)
   if err ~= nil then return nil, err end
   local output = {}
   local files = {}

   for i = 1, #entries do
      local entry = entries[i]
      local name = entry:Name()
      local fileinfo, serr = goos.Lstat(filepath.Join(path, name))
      if serr == nil then
         local isDir = fileinfo:IsDir()
         if isDir then
            table.insert(output, name .. "/")
         else
            table.insert(files, name)
         end
      end
   end

   table.sort(output)
   table.sort(files)

   for i = 1, #files do
      table.insert(output, files[i])
   end


   table.insert(output, 1, "..")
   return output, nil
end


local function path_to_position(base, entries, path)
   for i = 1, #entries do
      local name = entries[i]
      local abs, err = filepath.Abs(filepath.Join(base, name))
      if err == nil and path == abs then
         return i - 1
      end
   end
   return nil
end

function ydir_attribute_end()
   local hide_date = config.GetGlobalOption("ydir.HideDate")
   local hide_perm = config.GetGlobalOption("ydir.HidePermission")
   local hide_size = config.GetGlobalOption("ydir.HideSize")
   local has_nerdfont = config.GetGlobalOption("ydir.Nerdfont")

   local width = 2
   width = width + 1
   if not hide_size then
      width = width + 6
      width = width + 2
   end
   if not hide_date then
      width = width + 12
      width = width + 2
   end
   if not hide_perm then
      width = width + 10
      width = width + 2
   end

   return width
end

local function set_cursor_to_idx(bp, idx)
   if idx == nil then idx = 0 end
   if idx >= bp.Buf:LinesNum() - YDIR_LISTING_START - 1 then idx = bp.Buf:LinesNum() - YDIR_LISTING_START - 1 end

   bp:CursorStart()


   local has_nerd = config.GetGlobalOption("ydir.Nerdfont")
   local nerd_select = config.GetGlobalOption("ydir.NerdfontIconSelect")
   local offset = 0
   if has_nerd and not nerd_select then
      offset = 2
   end


   bp.Cursor:GotoLoc(buffer.Loc(ydir_attribute_end() + offset, YDIR_LISTING_START - 1 + idx))
   bp:Relocate()
end

local function text_generator(base_path, entries)
   local hide_date = config.GetGlobalOption("ydir.HideDate")
   local hide_perm = config.GetGlobalOption("ydir.HidePermission")
   local hide_size = config.GetGlobalOption("ydir.HideSize")
   local has_nerdfont = config.GetGlobalOption("ydir.Nerdfont")

   local lines = {}

   table.insert(lines, base_path)
   table.insert(lines, "")

   for i = 1, #entries do
      local name = entries[i]

      local fileinfo, serr = goos.Lstat(filepath.Join(base_path, name))
      if serr == nil then




         local text = "   "

         if not hide_date then
            text = text .. format_date(fileinfo:ModTime()) .. "  "
         end

         if not hide_perm then
            text = text .. format_perm(fileinfo:Mode()) .. "  "
         end

         if not hide_size then
            text = text .. format_size(fileinfo:Size()) .. "  "
         end

         if has_nerdfont then
            local symbol = NERD_FILE
            local pos = #name
            while pos > 1 do
               if name:sub(pos, pos) == "." then break end
               pos = pos - 1
            end
            local ext = name:sub(pos, #name)

            if fileinfo:IsDir() then
               symbol = NERD_DIR
            elseif NERD_LOOKUP[ext:lower()] ~= nil then
               symbol = NERD_LOOKUP[ext:lower()]
            end

            text = text .. symbol .. " "
         end

         text = text .. name
         table.insert(lines, text)
      end
   end
   local text = table.concat(lines, "\n") .. "\n"
   return text
end

local function update_buffer(bp, path, cursor_path)
   local entries, err = dir_as_list(path)
   if err ~= nil then
      micro.InfoBar():Error("ydir failed: ", err:Error())
      return
   end
   local text = text_generator(path, entries)
   bp.Buf:Replace(bp.Buf:Start(), bp.Buf:End(), text)

   local cursor_idx = path_to_position(path, entries, cursor_path)
   set_cursor_to_idx(bp, cursor_idx)
end

function ydir(bp, args)
   local pane = config.GetGlobalOption("ydir.Default")
   if args and #args > 0 then
      if args[1]:lower() == "vsplit" then
         pane = "vsplit"
      elseif args[1]:lower() == "hsplit" then
         pane = "hsplit"
      elseif args[1]:lower() == "tab" then
         pane = "tab"
      elseif args[1]:lower() == "current" then
         pane = "current"
      else
         micro.InfoBar():Error("Unsupported pane mode in default")
         return
      end
   end

   local b = buffer.NewBuffer("", "")
   b:SetName("ydir")
   b:SetOption("filetype", YDIR_BUFFER_TYPE_READONLY)
   b.Type.Scratch = true
   b.Type.Readonly = true

   local initial_selection = bp.Buf.AbsPath
   local base_path = filepath.Dir(initial_selection)
   local fileinfo, serr = goos.Lstat(initial_selection)
   if serr ~= nil or fileinfo:IsDir() then
      base_path = goos.Getwd()
   end

   if pane == "vsplit" then
      bp:VSplitAction()
   elseif pane == "hsplit" then
      bp:HSplitAction()
   elseif pane == "tab" then
      bp:AddTab()
   else
      if config.GetGlobalOption("ydir.SaveBufWhenOpenOnCurrent") then
         bp:Save()
      end
   end

   micro.CurPane():OpenBuffer(b)
   update_buffer(micro.CurPane(), base_path, initial_selection)
end





local function get_file_name_by_line(bp, y)
   if y < YDIR_LISTING_START - 1 then return nil end
   if y > bp.Buf:LinesNum() - 1 then return nil end
   local line = bp.Buf:Line(y)
   local start = ydir_attribute_end() + 1
   local has_nerdfont = config.GetGlobalOption("ydir.Nerdfont")
   if has_nerdfont then
      local icon_width = line:sub(start):find(" ", 1, true)
      start = start + icon_width
   end

   return line:sub(start)
end

local function get_file_name_on_cursor(bp)
   local y = bp.Cursor.Y
   return get_file_name_by_line(bp, y)
end

local function get_current_dir(bp)
   return bp.Buf:Line(0)
end





local function is_line_selected(bp, y)
   if y < YDIR_LISTING_START then return false end
   if y > bp.Buf:LinesNum() - 1 then return false end

   local line = bp.Buf:Line(y)
   return line:sub(2, 2) == "*"
end

local function mark_line_selected(bp, y)
   if y < YDIR_LISTING_START then return false end
   if y > bp.Buf:LinesNum() - 2 then return false end
   bp.Buf:Replace(
   buffer.Loc(1, y),
   buffer.Loc(2, y),
   "*")
   return true
end

local function unmark_line_selected(bp, y)
   if y < YDIR_LISTING_START then return false end
   if y > bp.Buf:LinesNum() - 2 then return false end
   bp.Buf:Replace(
   buffer.Loc(1, y),
   buffer.Loc(2, y),
   " ")
   return true
end

local function toggle_selection(bp, y)
   if is_line_selected(bp, y) then
      unmark_line_selected(bp, y)
   else
      mark_line_selected(bp, y)
   end
end

function ydir_smart_mark(bp)
   if not bp.Cursor:HasSelection() then
      local y = bp.Cursor.Y
      toggle_selection(bp, y)
      return
   end

   local sel = bp.Cursor.CurSelection
   local s, e = sel[1], sel[2]
   local min = math.min(s.Y, e.Y)
   local max = math.max(s.Y, e.Y)

   local all_marked = true
   for i = min, max do
      if not is_line_selected(bp, i) then

         all_marked = false
      end
   end

   if all_marked then
      for i = min, max do
         unmark_line_selected(bp, i)
      end
   else
      for i = min, max do
         mark_line_selected(bp, i)
      end
   end
end

local function get_files_selected(bp)
   local entries = {}
   for i = YDIR_LISTING_START - 1, bp.Buf:LinesNum() - 1 do
      if is_line_selected(bp, i) then
         entries[#entries + 1] = get_file_name_by_line(bp, i)
      end
   end


   if #entries == 0 then
      if bp.Cursor.Y == YDIR_LISTING_START - 1 then return {} end
      if bp.Cursor.Y == bp.Buf:LinesNum() - 1 then return {} end

      local file = get_file_name_on_cursor(bp)
      if file ~= nil then
         entries[1] = file
      end
   end

   return entries
end










local paste_storage = {
   mode = nil,
   base = nil,
   paths = {},
}

local function set_paste_abs_paths(bp)
   local selection = get_files_selected(bp)
   local current_path = get_current_dir(bp)
   paste_storage["base"] = current_path
   paste_storage["paths"] = {}
   for i = 1, #selection do
      local abs_path = filepath.Join(current_path, selection[i])
      paste_storage["paths"][(#paste_storage["paths"]) + 1] = abs_path
   end
end

function ydir_copy(bp)
   paste_storage["mode"] = "copy"
   set_paste_abs_paths(bp)
   micro.InfoBar():Message("Copied " .. #paste_storage["paths"] .. " files")
end

function ydir_cut(bp)
   paste_storage["mode"] = "cut"
   set_paste_abs_paths(bp)
   micro.InfoBar():Message("Cut " .. #paste_storage["paths"] .. " files")
end

function ydir_paste(bp)
   if paste_storage["mode"] == nil then return end
   local current_path = get_current_dir(bp)
   if paste_storage["mode"] == "copy" then
      local err = copy_paths(paste_storage["paths"], current_path)
      if err ~= nil then
         micro.InfoBar():Error(err)
      end
   elseif paste_storage["mode"] == "cut" then
      local err = move_paths(paste_storage["paths"], current_path)
      if err ~= nil then
         micro.InfoBar():Error(err)
      end
      paste_storage["mode"] = nil
      paste_storage["base"] = nil
      paste_storage["paths"] = {}
   end

   local line = bp.Cursor.Y
   update_buffer(bp, current_path, nil)
   set_cursor_to_idx(bp, line + 1 - YDIR_LISTING_START)
end




function ydir_open_cursor(bp)
   if not is_ydir_buffer(bp) then return true end
   if bp.Cursor.Y < (YDIR_LISTING_START - 1) then return false end

   local name = get_file_name_on_cursor(bp)
   if not name then return false end


   local current_path = get_current_dir(bp)
   local future_path = filepath.Join(current_path, name)
   local fileinfo, serr = goos.Lstat(future_path)
   if serr ~= nil then
      micro.InfoBar():Error("open failed: ", name)
      return false
   end


   if fileinfo:IsDir() then
      local last = get_history(future_path)
      if last ~= nil then
         last = filepath.Join(future_path, last)
      end
      update_buffer(bp, future_path, last)
      return false
   end


   local b, err = buffer.NewBufferFromFile(future_path)
   if err ~= nil then
      micro.InfoBar():Error("open failed: ", name)
      return false
   end
   local path = goos.Getwd()



   local display_name = b:GetName()
   if display_name and display_name:sub(1, #path) == path then
      b:SetName(display_name:sub(#path + 2))
   end

   bp:OpenBuffer(b)
   return false
end

function ydir_open_parent(bp)
   if not is_ydir_buffer(bp) then return true end

   local current_path = get_current_dir(bp)
   local future_path = filepath.Join(current_path, "..")

   add_history(current_path, get_file_name_on_cursor(bp))

   update_buffer(bp, future_path, current_path)
   return false
end

function ydir_create_path(bp)
   if not is_ydir_buffer(bp) then return true end
   micro.InfoBar():Prompt("Create Path: ", "", "CreatePath", function() end,
   function(resp, canceled)
      if canceled then return end
      if resp == "" then return end
      local current_path = get_current_dir(bp)
      local rel = filepath.ToSlash(resp)
      create_path(current_path, rel)

      local idx = rel:find("/", 1, true)
      local first = rel
      if idx ~= nil then
         first = rel:sub(1, idx - 1)
      end
      local abs_path = filepath.Join(current_path, first)

      update_buffer(bp, current_path, abs_path)
   end)
   return true
end

function ydir_delete_selection(bp)
   if not is_ydir_buffer(bp) then return true end
   local current_path = get_current_dir(bp)
   local selection = get_files_selected(bp)

   local any_dir = false
   if #selection == 0 then
      return true
   end
   for i = 1, #selection do
      local path = filepath.Join(current_path, selection[i])
      local info, err = goos.Lstat(path)
      if err ~= nil then
         micro.InfoBar():Error("Cannot access: " .. path)
         return true
      end
      if path == current_path then
         micro.InfoBar():Error("Cannot delete folder you are in")
      end
      if info:IsDir() then
         any_dir = true
      end
   end

   local function callback(objects)
      for i = 1, #objects do
         local path = filepath.Join(current_path, objects[i])
         local _, err = goos.Lstat(path)
         if err ~= nil then
            micro.InfoBar():Error("Cannot access: " .. path)
            return
         end
         local delete_err = goos.RemoveAll(path)
         if delete_err ~= nil then
            micro.InfoBar():Error("Delete failed: " .. delete_err:Error())
            return
         end
      end

      micro.InfoBar():Message("Deleted " .. #selection .. " objects")

      local line = bp.Cursor.Y
      update_buffer(bp, current_path, nil)
      set_cursor_to_idx(bp, line + 1 - YDIR_LISTING_START)
   end

   if any_dir then
      local text = "Delete DIRECTORIES in " .. #selection .. " objects recursivly? (yes,no,esc) "
      if #selection == 1 then
         text = "Delete DIRECTORY `" .. selection[1] .. "` recursivly? (yes,no,esc) "
      end
      micro.InfoBar():Prompt(text, "", "DeletePath", function() end,
      function(resp, canceled)
         if canceled then return end
         if resp:lower() == "yes" then
            callback(selection)
         else
            micro.InfoBar():Message("Delete cancelled")
         end
      end)
   else
      local text = "Delete " .. #selection .. " objects? (y,n,esc)"
      if #selection == 1 then
         text = "Delete file `" .. selection[1] .. "`? (y,n,esc) "
      end
      micro.InfoBar():YNPrompt(text,
      function(yes, canceled)
         if canceled or not yes then return end
         callback(selection)
      end)
   end
   return true
end

function ydir_cursor_start(bp)
   set_cursor_to_idx(bp, 0)
end

function ydir_cursor_end(bp)
   local last_line = bp.Buf:LinesNum() - 1
   local last_idx = last_line - YDIR_LISTING_START
   set_cursor_to_idx(bp, last_idx)
end




function preInsertNewline(bp)
   if not is_ydir_buffer(bp) then return true end
   return ydir_open_cursor(bp)
end

function preBackspace(bp)
   if not is_ydir_buffer(bp) then return true end
   return ydir_open_parent(bp)
end

function preToggleOverwriteMode(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_create_path(bp)
   return false
end

function preDelete(bp)
   if not is_ydir_buffer(bp) then return true end
   return ydir_delete_selection(bp)
end

function preCursorUp(bp)
   if not is_ydir_buffer(bp) then return true end
   if bp.Cursor.Y < YDIR_LISTING_START then
      ydir_cursor_end(bp)
      return false
   end
   return true
end

function preCursorDown(bp)
   if not is_ydir_buffer(bp) then return true end
   if bp.Cursor.Y > bp.Buf:LinesNum() - YDIR_LISTING_START then
      ydir_cursor_start(bp)
      return false
   end
   return true
end

function preCursorLeft(bp)
   if not config.GetGlobalOption("ydir.HorizontalCursorMovement") then return true end
   if not is_ydir_buffer(bp) then return true end
   return ydir_open_parent(bp)
end

function preCursorRight(bp)
   if not config.GetGlobalOption("ydir.HorizontalCursorMovement") then return true end
   if not is_ydir_buffer(bp) then return true end
   return ydir_open_cursor(bp)
end

function preCursorStart(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_cursor_start(bp)
   return false
end

function preCursorEnd(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_cursor_end(bp)
   return false
end

function preIndentSelection(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_smart_mark(bp)
   return false
end





function prePaste(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_paste(bp)
   return false
end

function preCut(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_cut(bp)
   return false
end

function preCutLine(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_cut(bp)
   return false
end

function preCopyLine(bp)
   if not is_ydir_buffer(bp) then return true end
   ydir_copy(bp)
   return false
end




local has_mouse_been_dragged = false

function onMousePress()
   has_mouse_been_dragged = false
end

function onMouseDrag()
   has_mouse_been_dragged = true
end

function onMouseRelease(bp, event)
   if not has_mouse_been_dragged and not bp.Cursor:HasSelection() and is_ydir_buffer(bp) then
      local mloc = event:Position()
      local loc = bp:LocFromVisual(buffer.Loc(mloc.X, mloc.Y))
      if loc.Y >= YDIR_LISTING_START - 1 and loc.Y < bp.Buf:LinesNum() - 1 then
         ydir_open_cursor(bp)
      end
   end
   has_mouse_been_dragged = false
end

function MouseRightClick(bp)
   if not is_ydir_buffer(bp) then return true end
   return ydir_open_parent(bp)
end





function preShellMode(bp)
   if not is_ydir_buffer(bp) then return true end

   local dir = get_current_dir(bp)
   micro.InfoBar():Prompt(dir .. "$ ", "", "Shell", nil, function(input, canceled)
      if canceled or input == "" then
         return
      end

      local line = bp.Cursor.Y
      local current_path = get_current_dir(bp)
      local prev = goos.Getwd()

      bp:HandleCommand("cd \"" .. current_path .. "\"")
      shell.RunInteractiveShell(input, true, false)
      bp:HandleCommand("cd \"" .. prev .. "\"")

      update_buffer(bp, current_path, nil)
      set_cursor_to_idx(bp, line + 1 - YDIR_LISTING_START)
   end)
   return false
end

local function make_command(cmd, cb, opt)
   config.MakeCommand(cmd,
   function(bp, args)
      cb(bp, args)
   end, opt)
end

function init()
   make_command("ydir", ydir, command_options({ "current", "hsplit", "tab", "vsplit" }))

   make_command("ydir_open", ydir_open_cursor, config.NoComplete)
   make_command("ydir_back", ydir_open_parent, config.NoComplete)
   make_command("ydir_create", ydir_create_path, config.NoComplete)
   make_command("ydir_delete", ydir_delete_selection, config.NoComplete)
   make_command("ydir_mark", ydir_smart_mark, config.NoComplete)

   make_command("ydir_copy", ydir_copy, config.NoComplete)
   make_command("ydir_cut", ydir_cut, config.NoComplete)
   make_command("ydir_paste", ydir_paste, config.NoComplete)

   config.RegisterCommonOption("ydir", "Default", "current")
   config.RegisterCommonOption("ydir", "SaveBufWhenOpenOnCurrent", true)
   config.RegisterCommonOption("ydir", "DateSwitchAmount", 15552000)
   config.RegisterCommonOption("ydir", "HorizontalCursorMovement", true)

   config.RegisterCommonOption("ydir", "HideDate", false)
   config.RegisterCommonOption("ydir", "HideSize", false)
   config.RegisterCommonOption("ydir", "HidePermission", false)
   config.RegisterCommonOption("ydir", "Nerdfont", false)
   config.RegisterCommonOption("ydir", "NerdfontIconSelect", false)
end
