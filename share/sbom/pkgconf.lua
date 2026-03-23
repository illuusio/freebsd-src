-- SPDX-License-Identifier: BSD-2-Clause
--
-- Copyright(c) 2025-2026 The FreeBSD Foundation.
--
-- This software was developed by Tuukka Pasanen <tuukka.pasanen@ilmi.fi>
-- under sponsorship from the FreeBSD Foundation.
--
-- Module to help generate files and parse them
--

local lib_yaml = require("lyaml")
local ucl = require("ucl")

local git_url = "https://cgit.freebsd.org/src/tree/"
-- local git_url_addition = "?h=stable/15"
local git_url_addition = ""

local man_url = "https://man.freebsd.org/cgi/man.cgi?query="
-- local man_url_addition = "&manpath=FreeBSD+15.0-RELEASE"
local man_url_addition = ""

local pkgconf = {}

local pc_license_text = [[
# SPDX-License-Identifier: BSD-2-Clause AND LicenseRef-FreeBSD-SBOM
# SPDX-FileCopyrightText: 2026 The FreeBSD Foundation.
#
# Copyright(c) 2026 The FreeBSD Foundation.
#
]]

-------------------------------------------------------------------------------
-- Helper function to create comma separated value from table
-- @param cur_table Current table to print
-- @return Return formated table as string or nil if something goes wrong
-------------------------------------------------------------------------------
local function pkgconf_string_from_table(cur_table)
	local separator = ", "
	local rtn_str = ""

	if type(cur_table) == "table" and #cur_table then
		rtn_str = table.concat(cur_table, separator)
	else
		rtn_str = cur_table
	end

	return rtn_str
end

-------------------------------------------------------------------------------
-- Helper function to print table with or without name
-- @param name Name for this pkgconfig entry
-- @param cur_table Current table to print
-- @param is_lowercase Should be put entry as lowercase
-- @param is_markdown Is entry for markdown or not
-- @return Return formated table as string or nil if something goes wrong
-------------------------------------------------------------------------------
local function pkgconf_pkgconfig_string(name, cur_table, is_lowercase, is_markdown)
	if is_markdown == nil then
		is_markdown = false
	end

	if is_lowercase == nil then
		is_lowercase = false
	end

	local table_str = pkgconf_string_from_table(cur_table)

	if table_str == nil then
		return nil
	end

	if is_lowercase then
		table_str = string.lower(table_str)
	end

	if is_markdown then
		return table_str
	else
		return name .. ": " .. table_str .. "\n"
	end
end

-------------------------------------------------------------------------------
-- Add value to Pkgconfig files parameter
-- they are like 'Name: somepackage'
-- @param orig_str Original string to be concated
-- @param name Name of parameter
-- @param value Value for parameter
-- @return Concated string with new 'Param: value' added
-------------------------------------------------------------------------------
function pkgconf.add_value(orig_str, name, value, is_markdown)
	local local_name = name
	local local_value = value

	if is_markdown == nil then
		is_markdown = false
	end

	if local_name == nil then
		return orig_str
	end

	if local_value == nil then
		return orig_str
	end

	if type(local_value) == "table" then
		return orig_str
	end

	local rtn_str = orig_str .. local_name .. ": " .. local_value .. "\n"

	if is_markdown then
		rtn_str = orig_str .. " " .. local_value .. " |"
	end
	return rtn_str
end

-------------------------------------------------------------------------------
-- Create pkgconf file
-- @param name Name of package
-- @param description description of package
-- @param url Homepage for package
-- @param version Package version
-- @param license Package license
-- @param source Package source
-- @param deps_table Table of depends
-- @return Concated string or nil if problem
-------------------------------------------------------------------------------
function pkgconf.pkgconfig(
	name,
	description,
	url,
	version,
	license,
	source,
	deps_table,
	maintainer_table,
	copyright_table,
	license_table
)
	local pc_str = pc_license_text
	pc_str = pkgconf.add_value(pc_str, "Name", name)
	pc_str = pkgconf.add_value(pc_str, "Description", description)
	pc_str = pkgconf.add_value(pc_str, "URL", url)
	pc_str = pkgconf.add_value(pc_str, "Version", version)
	pc_str = pkgconf.add_value(pc_str, "Source", source)
	pc_str = pkgconf.add_value(pc_str, "License", license)

	if license_table ~= nil and type(license_table) == "table" and #license_table > 0 then
		pc_str = pc_str .. pkgconf_pkgconfig_string("License.file", license_table, false, false)
	end

	if copyright_table ~= nil and type(copyright_table) == "table" and #copyright_table > 0 then
		pc_str = pc_str .. pkgconf_pkgconfig_string("Copyright", copyright_table, false, false)
	end

	if deps_table ~= nil and type(maintainer_table) == "table" and #maintainer_table > 0 then
		pc_str = pc_str .. pkgconf.maintainer_from_table(maintainer_table)
	end

	if deps_table ~= nil and type(deps_table) == "table" and #deps_table then
		pc_str = pc_str .. pkgconf.depends_from_table(deps_table)
	end

	return pc_str
end

-------------------------------------------------------------------------------
-- Does file exist and can it be opened and read
-- @param filename Filename to be checked
-- @return False if file does not exist and true is it does
-------------------------------------------------------------------------------
function pkgconf.file_exists(filename)
	local is_present = true
	-- Opens a file
	local handle = io.open(filename)

	-- if file is not present, f will be nil
	if not handle then
		is_present = false
	else
		-- close the file
		handle:close()
	end

	-- return status
	return is_present
end

-------------------------------------------------------------------------------
-- Write string to file
-- @param location Where file should be written
-- @param output_string String to be outputted
-- @return false if can't output and true if can
-------------------------------------------------------------------------------
function pkgconf.write_file(location, output_string)
	if type(location) == "string" then
		local output_handle = io.open(location, "w")

		if output_handle == nil then
			print("Can't open file: '" .. location .. "' for output")
			return false
		else
			output_handle:write(output_string)
			output_handle:close()
		end
	end
	return true
end

-------------------------------------------------------------------------------
-- Create pkgconf file
-- @param location Where should pkgconf file be written
-- @param name Name of package
-- @param description description of package
-- @param url Homepage for package
-- @param version Package version
-- @param license Package license
-- @param source Package source
-- @param deps_table Table of depends
-- @return Concated string or nil if problem
-------------------------------------------------------------------------------
function pkgconf.write_pkgconfig(
	location,
	name,
	description,
	url,
	version,
	license,
	source,
	deps_table,
	maintainer_table,
	copyright_table,
	license_file_table
)
	local pc_str = pkgconf.pkgconfig(
		name,
		description,
		url,
		version,
		license,
		source,
		deps_table,
		maintainer_table,
		copyright_table,
		license_file_table
	)
	if pkgconf.write_file(location, pc_str) == false then
		return false, nil
	end
	return true, pc_str
end

-------------------------------------------------------------------------------
-- Return FreeBSD man URL for package
-- @param name Name of Man page wanted
-- @return Return URL to man page
-------------------------------------------------------------------------------
function pkgconf.man_url(name)
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
function pkgconf.git_url(dir, name)
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
function pkgconf.depends_table(dir, name)
	if name == nil then
		print("pkgconf.depends: Nil name")
		return ""
	end

	local filename = dir .. "/" .. "Makefile.depend"

	local handle = io.open(filename, "r")

	if not handle then
		print("pkgconf.depends: Can't open file: " .. dir)
		return {}
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
			local cur_str = line:reverse():sub(3):reverse():sub(2)
			cur_str = cur_str:gsub("/", "."):gsub("${CSU_DIR}", "csu")
			local cur_dir = dir:gsub("/", ".")
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
	return deps_table
end

-------------------------------------------------------------------------------
-- Parse Makefile.depend file and return it as pkgconfig 'Requires'
-- @param dir Where to find Makefile.depend
-- @param name Package name
-- @return Return parsed Makefile.depend as pkgconfig Requires
-------------------------------------------------------------------------------
function pkgconf.depends(dir, name)
	local deps_table = pkgconf.depends_table(dir, name)
	local require_str = ""

	if type(deps_table) == "table" and #deps_table then
		require_str = table.concat(deps_table, ", ")
	elseif type(deps_table) == "string" then
		require_str = deps_table
	end

	return "Requires: " .. require_str .. "\n"
end

-------------------------------------------------------------------------------
-- Print correctly maintainer from them table
-- @param maint_table Table to print
-- @param is_markdown Is this markdown string or Pkgconfig output
-- @return Maintainer table as string
-------------------------------------------------------------------------------
function pkgconf.maintainer_from_table(maint_table, is_markdown)
	return pkgconf_pkgconfig_string("Maintainer", maint_table, false, is_markdown)
end

-------------------------------------------------------------------------------
-- Print correctly depend from them table
-- @param deps_table Table to print
-- @param is_markdown Is this markdown string or Pkgconfig output
-- @return Depends table as string
-------------------------------------------------------------------------------
function pkgconf.depends_from_table(deps_table, is_markdown)
	return pkgconf_pkgconfig_string("Requires", deps_table, true, is_markdown)
end

-------------------------------------------------------------------------------
-- Split line tiwh separator
-- @param line String to separate
-- @param sep Separator char
-- @return Return parsed Makefile.depend as pkgconfig Requires
-------------------------------------------------------------------------------
function pkgconf.split_line(line, sep)
	local rtn_table = {}
	if sep == nil then
		sep = "|"
	end
	for str in string.gmatch(line, "([^" .. sep .. "]+)") do
		table.insert(rtn_table, str)
	end
	return rtn_table
end

-------------------------------------------------------------------------------
-- Remove * at the begining and other variants
-- Also remove double spaces and tabs and replace
-- with one space
-- @param license licese text to normalize
-- @return Return nil or nomalized text
-------------------------------------------------------------------------------
function pkgconf.nomalize_license(license)
	if license == nil then
		return nil
	end

	local license_text = license
		:gsub("\\n", "\n")
		:gsub("\\t", " ")
		:gsub("\n %* ", "\n")
		:gsub("\n %*\t", "\n\t")
		:gsub("^ %* ", "")
		:gsub("\n%* ", "\n")
		:gsub("\n%*", "\n")
		:gsub("^%* ", "")
		:gsub("\n %*\n", "\n")
		:gsub("\n", " ")
		:gsub("\t", " ")
		:gsub("%s+", " ")
		:gsub("`", "'")
		:gsub("%'+", '"')
		:gsub(" $", "")

	return license_text
end

function pkgconf.add_string_to_table(cur_table, add_string)
	for _, value in ipairs(cur_table) do
		if value == add_string then
			return false
		end
	end

	table.insert(cur_table, add_string)
	return true
end

-------------------------------------------------------------------------------
-- Open YAML file and make and object
-- @param location Location for YAML file
-- @return Return YAML object tree or nil if can't do it
-------------------------------------------------------------------------------
function pkgconf.open_yaml(location)
	if location:match("%.json$") then
		local parser = ucl.parser()
		local is_error, err = parser:parse_file(location)

		if is_error == false then
			print("pkgconf.open_yaml: Can't parse JSON file " .. location .. ": " .. err)
			return nil
		end

		return parser:get_object()
	else
		local yaml_file = io.open(location, "r")

		if yaml_file == nil then
			print("pkgconf.open_yaml: Can't parse YAML file: " .. location)
			return nil
		end

		local yaml_content = yaml_file:read("*all")
		yaml_file:close()

		local yaml_obj = lib_yaml.load(yaml_content)
		yaml_content = nil

		return yaml_obj
	end
end

-------------------------------------------------------------------------------
-- Parse database to flattened version and return original and
-- flattened versio
-- @param location Location for YAML file
-- @param use_dir Use dir in key like usr.bin.ar not just ar
-- @return Original version
-- @return Return flattened version
-------------------------------------------------------------------------------
function pkgconf.parse_database(location, use_dir)
	local yaml_obj = pkgconf.open_yaml(location)

	if yaml_obj == nil then
		return nil, nil
	end

	local is_use_dir = use_dir or false

	local whole_packages = {}

	for _, v in pairs(yaml_obj["Sections"]) do
		for sk, sv in pairs(v) do
			local lowercase_name = ""
			if is_use_dir then
				if type(sv["directory"]) == "string" then
					lowercase_name = string.lower(sv["directory"])
				end
			else
				lowercase_name = string.lower(sk)
			end

			whole_packages[lowercase_name] = sv
			whole_packages[lowercase_name]["is_database_yml"] = 1
		end
	end

	return yaml_obj, whole_packages
end

-------------------------------------------------------------------------------
-- Run command and return output as string
-- @param cmd Command to be run
-- @return Stdout outpout of make-command
-------------------------------------------------------------------------------
function pkgconf.run_cmd(command)
	local handle = io.popen(command)
	local output = ""
	if handle ~= nil then
		output = handle:read("*a")
		handle:close()
	end
	return output
end

return pkgconf
