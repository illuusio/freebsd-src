#!/usr/libexec/flua

-- SPDX-License-Identifier: BSD-2-Clause
--
-- Copyright(c) 2025 The FreeBSD Foundation.
--
-- This software was developed by Tuukka Pasanen <tuukka.pasanen@ilmi.fi>
-- under sponsorship from the FreeBSD Foundation.
--
-- Generates .pc files to directories from FreeBSD-files.csv
--
-- !! Heavy WIP warning !!
--

local git_url = "https://cgit.freebsd.org/src/tree/"
local git_url_addition = "?h=stable/15"

local man_url = "https://man.freebsd.org/cgi/man.cgi?query="
local man_url_addition = "&manpath=FreeBSD+15.0-RELEASE"

-------------------------------------------------------------------------------
-- Add value to Pkgconfig files parameter
-- they are like 'Name: somepackage'
-- @param orig_str Original string to be concated
-- @param name Name of parameter
-- @param value Value for parameter
-- @return Concated string with new 'Param: value' added
-------------------------------------------------------------------------------
local function pkgconf_add_value(orig_str, name, value)
	local local_name = name
	local local_value = value
	if local_name == nil then
		local_name = "Could not parse name"
	end

	if local_value == nil then
		local_value = "Could not parse value"
	end

	local rtn_str = orig_str .. local_name .. ": " .. local_value .. "\n"
	return rtn_str
end

-------------------------------------------------------------------------------
-- Return FreeBSD man URL for package
-- @param name Name of Man page wanted
-- @return Return URL to man page
-------------------------------------------------------------------------------
local function pkgconf_get_man_url(name)
	local local_name = name

	if local_name == nil then
		local_name = "Could not parse name"
	end

	return man_url .. local_name .. man_url_addition
end

-------------------------------------------------------------------------------
-- Return Git URL for package
-- @param dir Git sub directory
-- @param name Name of git page wanted
-- @return Return URL to Git
-------------------------------------------------------------------------------
local function pkgconf_get_git_url(dir, name)
	local local_name = name

	if local_name == nil then
		local_name = "Could not parse name"
	end

	return git_url .. dir .. git_url_addition
end

-------------------------------------------------------------------------------
-- Parse Makefile.depend file and return it as pkgconfig 'Requires'
-- @param dir Where to find Makefile.depend
-- @param name Package name
-- @return Return parsed Makefile.depend as pkgconfig Requires
-------------------------------------------------------------------------------
local function pkgconf_get_depends(dir, name)
	if name == nil then
		print("pkgconf_get_depends: Nil name")
		return ""
	end

	filename = dir .. "/" .. "Makefile.depend"

	handle = io.open(filename, "r")

	if not handle then
		print("pkgconf_get_depends: Can't open file: " .. dir)
		return ""
	end

	-- set handle as default input
	io.input(handle)

	local is_dirdeps = false
	local deps_table = {}

	-- traverse through each lines
	for line in io.lines() do
		if string.len(line) == 0 then
			is_dirdeps = false
		end

		if is_dirdeps == true then
			-- Remove last '\' and remove first '\t'
			cur_str = line:reverse():sub(3):reverse():sub(2)
			cur_str = cur_str:gsub("/", "."):gsub("${CSU_DIR}", "csu")
			cur_dir = dir:gsub("/", ".")
			cur_str = cur_str:gsub("${DEP_RELDIR}", cur_dir)

                        -- Currently these packages
                        -- excluded from SBOM
			if
				cur_str:find("include") == nil
				and cur_str:find("usr.") == nil
				and cur_str:find("sbin.") == nil
				and cur_str:find("bin.") == nil
				and cur_str:find("secure.") == nil
				and cur_str:find("kerberos5.") == nil
				and cur_str:find("cddl.") == nil
				and cur_str:find("gnu.") == nil
				and cur_str:find(".host") == nil
			then
				table.insert(deps_table, cur_str)
			end
		end

		if line:find("DIRDEPS =") ~= nil then
			is_dirdeps = true
		end
	end

	io.close(handle)

	require_str = ""
	require_str = table.concat(deps_table, " \\\n\t")

	return "Requires: " .. require_str .. "\n"
end

local function pkgconf_split_line(line)
	local rtn_table = {}
	for str in string.gmatch(line, "([^|]+)") do
		table.insert(rtn_table, str)
	end
	return rtn_table
end

if #arg == 0 then
	print("Usage:\tparse_makefile_depend.lua FreeBSD-apps.csv\n")
	print("\t\tParses CSV and creates pkfconfig files to subdirs\n")
        os.exit(1)
end

dir_name = ""
input_name = arg[1]

name_handle = io.open(input_name, "r")

if not name_handle then
	print("Can't open file: " .. input_file)
	os.exit(1)
end

-- set name_handle as default input
io.input(name_handle)

pc_file_str = "# SPDX-License-Identifier: FreeBSD-DOC and LicenseRef-FreeBSD-SBOM\n"

for line in io.lines() do
	splitted_table = pkgconf_split_line(line)
	name_str = splitted_table[2]
	desc_str = splitted_table[5]
	dir_name = splitted_table[3]

	if name_str ~= nil then
		pc_file_str = pkgconf_add_value(pc_file_str, "Name", name_str)
		pc_file_str = pkgconf_add_value(pc_file_str, "Description", desc_str)
		pc_file_str = pkgconf_add_value(pc_file_str, "URL", pkgconf_get_man_url(name_str))
		pc_file_str = pkgconf_add_value(pc_file_str, "Version", "15.0")
		pc_file_str = pkgconf_add_value(pc_file_str, "License", "NOASSERTION")
		pc_file_str = pkgconf_add_value(pc_file_str, "Source", pkgconf_get_git_url(dir_name, name_str))
		pc_file_str = pc_file_str .. pkgconf_get_depends(dir_name, name_str)

		output_filename = string.gsub(dir_name, "/", ".") .. ".pc"
		output_full = dir_name .. "/" .. output_filename

		output_handle = io.open(output_full, "w")

		if output_handle == nil then
			print("Can't open file: '" .. output_full .. "' for output")
		else
			output_handle:write(pc_file_str)
			output_handle:close()
		end
	else
		print("Can't parse name: " .. line)
	end

	pc_file_str = "# SPDX-License-Identifier: FreeBSD-DOC and LicenseRef-FreeBSD-SBOM\n"
end

io.close(name_handle)

os.exit(1)
