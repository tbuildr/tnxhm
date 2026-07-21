function Linemode:ls_l()
	-- 1. Fetch permissions natively using the :perm() function
	local perm_str = self._file.cha:perm() or "---------"

	-- 2. Fetch human-readable size and strip internal spacing
	local size = self._file:size()
	local size_str = size and ya.readable_size(size):gsub(" ", "") or "-"

	-- 3. Pad the size string (e.g., "%7s" right-aligns it to exactly 7 characters)
	local size_padded = string.format("%7s", size_str)

	-- 4. Fetch modification time (formatted like ls -l)
	local time = math.floor(self._file.cha.mtime or 0)
	local time_str = ""
	if time > 0 then
		time_str = os.date("%b %d %H:%M", time)
	end

	-- 5. Combine everything cleanly into the right side of the layout row
	return ui.Line(string.format(" %s  %s  %s ", perm_str, size_padded, time_str))
end
