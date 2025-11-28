-- SPDX-License-Identifier: BSD-2-Clause
--
-- Copyright(c) 2025 The FreeBSD Foundation.
--
-- This software was developed by Tuukka Pasanen <tuukka.pasanen@ilmi.fi>
-- under sponsorship from the FreeBSD Foundation.
--
-- Module to help generate files and parse them
--

local lib_yaml = require("lyaml")
local ucl = require("ucl")

local git_url = "https://cgit.freebsd.org/src/tree/"
-- Should be something like: "?h=stable/15"
local git_url_addition = "${FREEBSD_GIT_QUERY}"

local man_url = "https://man.freebsd.org/cgi/man.cgi?query="
-- Should be something like: "&manpath=FreeBSD+15.0-RELEASE"
local man_url_addition = "${FREEBSD_MAN_QUERY}"

local pkgconf = {}

local pc_license_text = [[
# Copyright (c) 2026 The FreeBSD Foundation
#
# SPDX-License-Identifier: BSD-2-Clause AND LicenseRef-FreeBSD-SBOM
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

	-- These are in these order
	-- Copyright: Copyright of application
	-- Description: Description for this application
	-- License: License for application in SPDX License Identifier short format
	-- License.file: This should point to license file which contains license text
	-- Maintainer: Maintener or maintainers
	-- Name: Name of application
	-- Requires: Requirements for this application that it can be build
	-- Source: Source where one can get application
	-- URL: Homepage for this application
	-- Version: Application version

	if copyright_table ~= nil and type(copyright_table) == "table" and #copyright_table > 0 then
		pc_str = pc_str .. pkgconf_pkgconfig_string("Copyright", copyright_table, false, false)
	end

	pc_str = pkgconf.add_value(pc_str, "Description", description)
	pc_str = pkgconf.add_value(pc_str, "License", license)

	-- This will be back when license file slurp is in
	-- if license_table ~= nil and type(license_table) == "table" and #license_table > 0 then
	--	pc_str = pc_str .. pkgconf_pkgconfig_string("License.file", license_table, false, false)
	--end
	if deps_table ~= nil and type(maintainer_table) == "table" and #maintainer_table > 0 then
		pc_str = pc_str .. pkgconf.maintainer_from_table(maintainer_table)
	end
	pc_str = pkgconf.add_value(pc_str, "Name", name)
	if deps_table ~= nil and type(deps_table) == "table" and #deps_table then
		pc_str = pc_str .. pkgconf.depends_from_table(deps_table)
	end
	pc_str = pkgconf.add_value(pc_str, "Source", source)
	pc_str = pkgconf.add_value(pc_str, "URL", url)
	pc_str = pkgconf.add_value(pc_str, "Version", version)

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
	if url ~= nil and url:match(pkgconf.escape_regex(man_url)) ~= nil then
		url = url .. man_url_addition
	end
	if source ~= nil and source:match(pkgconf.escape_regex(git_url)) ~= nil then
		source = source .. git_url_addition
	end
	if version ~= nil and type(version) == "string" and version:match("15.0") ~= true then
		version = "${FREEBSD_RELEASE}"
	end
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
	if line == nil then
		return {}
	end

	if sep == nil then
		sep = "|"
	end
	for str in string.gmatch(line, "([^" .. sep .. "]+)") do
		table.insert(rtn_table, str)
	end
	return rtn_table
end

-------------------------------------------------------------------------------
-- remove commenting and convert '\t' and multiple spaces to one space.
-- from license text with regex. It can remove
--   ' *'
--   ' * '
--   ' ** '
--   '/*'
--   '*/'
--   '//'
--   '// '
--   '#'
--   '# '
--
-- @param license licese text to remove comments
-- @return Return nil or nomalized text
-------------------------------------------------------------------------------
function pkgconf.remove_commenting(license)
	local output_text = license
		:gsub("\n%s%*\n", "\n\n")
		:gsub("^%s%*%s", "")
		:gsub("\n%s%*%s", "\n")
		:gsub("\n%s%*%*%s", "\n")
		:gsub("%s+%*%*", "")
		:gsub("\n%s+", "\n")
		:gsub("^%s+", "")
		:gsub("/%*%s+", "")
		:gsub("%s+%*/", "\n")
		:gsub("^%/%/%s", "")
		:gsub("\n%/%/%s", "")
		:gsub("\n%#\n", "\n\n")
		:gsub("\n%#%s", "\n")
		:gsub("^%#%s", "")
	return output_text
end

-------------------------------------------------------------------------------
-- Normalize text which means removing enters and more than one space
-- @param license licese text to normalize
-- @return Return nil or nomalized text
-------------------------------------------------------------------------------
function pkgconf.nomalize_license(license)
	if license == nil then
		return nil
	end

	local uncommeted_text = pkgconf.remove_commenting(license)

	local license_text = uncommeted_text
		:gsub("\\n", "\n")
		:gsub("\\t", " ")
		:gsub("\n", " ")
		:gsub("\t", " ")
		:gsub("%s+", " ")
		:gsub("([%a%d])%-%s([%a%d])", "%1%2")
		:gsub(" $", "")

	return license_text
end

-------------------------------------------------------------------------------
-- Escape some some char which should be treated normally. Chars are:
--  '('
--  ')'
--  '['
--  ']'
--  '.'
--  ','
--  '-'
--  '''
-- @param regex_string string to be escaped
-- @return Return nil or escaped text
-------------------------------------------------------------------------------
function pkgconf.escape_regex(regex_string)
	if regex_string == nil then
		return nil
	end

	local rtn_str = regex_string
		:gsub("%(", "%%(")
		:gsub("%)", "%%)")
		:gsub("%[", "%%[")
		:gsub("%]", "%%]")
		:gsub("%.", "%%.")
		:gsub("%,", "%%,")
		:gsub("%-", "%%-")
		:gsub("%'", "%%'")
		:gsub("%?", "%%?")
		return rtn_str
end

local function seek_pattern(text_str, pattern_table)
	local match_str = nil
	for _, pattern in ipairs(pattern_table) do
		match_str = text_str:match(pattern)
		if match_str ~= nil then
			break
		end
	end
	return match_str
end

-------------------------------------------------------------------------------
-- Parse who should be acknowledgement in BSD-4-Clause
-- @param license licese text
-- @return Return nil or acknowledgement text
-------------------------------------------------------------------------------
function pkgconf.get_acknowledgements(license)
	if license == nil then
		return nil
	end
	local regex_strings = {
		"display the following acknow.+%:%s(.+)%s4%.",
		'the following acknowledgement%:%s"(.+)"%sNeither',
		"3%.%s(.+)%s4%.",
	}

	return seek_pattern(license, regex_strings)
end

-------------------------------------------------------------------------------
-- Parse who should be promote in BSD-4-Clause and BSD-3-Clause
-- @param license licese text
-- @return Return nil or promote text
-------------------------------------------------------------------------------
function pkgconf.get_promote(license)
	if license == nil then
		return nil
	end

	local regex_strings = {
		"Neither the name of%s(.+)%smay be used to",
		"%s4%.%s(.+)%smay not",
		"%s3%.%s(.+)%smay not",
	}

	return seek_pattern(license, regex_strings)
end

-------------------------------------------------------------------------------
-- Parse who is author of license
-- @param license licese text
-- @return Return nil or author text
-------------------------------------------------------------------------------
function pkgconf.get_author(license)
	if license == nil then
		return nil
	end

	local regex_strings = {
		'PROVIDED BY%s(.+)%s"AS',
		'PROVIDED BY%s(.+)"AS',
		"PROVIDED BY%s(.+)%s%`%`AS",
		"PROVIDED BY%s(.+)%`%`AS",
		"PROVIDED BY%s(.+)%s''AS",
		"PROVIDED BY%s(.+)''AS",
		"PROVIDED BY%s(.+)%sAS",
		"PROVIDED BY%s(.+)%s%`AS",
	}

	return seek_pattern(license, regex_strings)
end

-------------------------------------------------------------------------------
-- Parse who is event owner
-- @param license licese text
-- @return Return nil or event text
-------------------------------------------------------------------------------
function pkgconf.get_event(license)
	if license == nil then
		return nil
	end

	local regex_strings = {
		"IN NO EVENT SHALL%s(.+)%sBE",
	}

	return seek_pattern(license, regex_strings)
end

-------------------------------------------------------------------------------
-- Use openSSL to create SHA256 sum of text
-- @param input input text
-- @return Return nil or SHA256 text
-------------------------------------------------------------------------------
function pkgconf.calculate_sha256(input)
	if input == nil then
		return nil
	end
	local hash_value = nil
	local license_normalized = pkgconf.nomalize_license(input)
	if license_normalized ~= nil then
		local hash_cmd = 'echo -n "'
			.. license_normalized:gsub('"', '\\"'):gsub("`", "\\`")
			.. '" | '
			.. "openssl dgst -sha256 -"
		-- 'Output: SHA2-256(stdin)= <64 bytes hash>'
		hash_value = pkgconf.run_cmd(hash_cmd):sub(18, 81)
	end
	return license_normalized, hash_value
end

-------------------------------------------------------------------------------
-- Add string to table is it's not inserted already
-- @param cur_table Table that should be used
-- @param add_string String to be added
-- @return True if added and False if not§
-------------------------------------------------------------------------------
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
-- Arrange table by key
-- @param input_table Table to be arrange
-- @param func Function to be used if not inner one
-- @return Return table which is arranged
-------------------------------------------------------------------------------
function pkgconf.get_arranged_table(input_table, func)
	local output_table = {}
	for input_key in pairs(input_table) do
		table.insert(output_table, input_key)
	end
	table.sort(output_table, func)
	local i = 0 -- iterator variable
	local iter = function() -- iterator function
		i = i + 1
		if output_table[i] == nil then
			return nil
		else
			return output_table[i], input_table[output_table[i]]
		end
	end
	return iter
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
