#!/usr/libexec/flua

-- SPDX-License-Identifier: BSD-2-Clause
--
-- Copyright(c) 2025-2026 The FreeBSD Foundation.
--
-- This software was developed by Tuukka Pasanen <tuukka.pasanen@ilmi.fi>
-- under sponsorship from the FreeBSD Foundation.
--
-- Convert CSV files to YAML for easier reading and writing
-- One needs database from:
-- https://github.com/FreeBSDFoundation/alpha-omega-beach-cleaning/blob/main/database.yml
--
-- Scripts also reads subdir/Makefile.deps for dependency information
--
-- Run on top directory something like
-- share/sbom/convert_csv_to_json.lua share/sbom/FreeBSD-apps.csv output.yaml database_directory/database.yml

local yaml = require("lyaml")
local pkgconf = require("pkgconf")

local function convert_create_table(
	name,
	directory,
	upstream,
	homepage,
	description,
	version,
	license,
	source,
	man_section,
	depends,
	requires,
	owner
)
	local rtn_table = {}
	rtn_table["description"] = description:gsub("^%l", string.upper)
	rtn_table["directory"] = directory
	rtn_table["version"] = version
	rtn_table["upstream"] = "FreeBSD project"
	if rtn_table["description"] ~= "Library missing description" then
		rtn_table["homepage"] = homepage
	end
	rtn_table["license"] = "NOASSERTION"
	rtn_table["source"] = source
	rtn_table["security"] = nil
	rtn_table["section"] = man_section

	if next(depends) ~= nil then
		rtn_table["depends"] = depends
	end

	rtn_table["plan"] = nil
	-- rtn_table["owner"] = nil

	return rtn_table
end

if #arg <= 2 then
	print("Usage:\tconvert_csv_to_json.lua [csv input file (separator '|')] [output.yaml] [input.json]\n")
	print("\t\tParse CSV file and convert it to easier use JSON file\n")
	os.exit(1)
end

local input_name = arg[1]
local output_name = arg[2]
local yaml_name = arg[3]

local input_handle = io.open(input_name, "r")
local output_handle = io.open(output_name, "w+")

if not input_handle then
	print("Can't open file: " .. input_name)
	os.exit(1)
end

if not output_handle then
	io.close(output_handle)
	print("Can't open file: " .. output_name)
	os.exit(1)
end

-- set name_handle as default input
io.input(input_handle)
io.output(output_handle)

local yaml_obj, whole_packages = pkgconf.parse_database(yaml_name)

if yaml_obj == nil or whole_packages == nil then
	io.close(input_handle)
	io.close(output_handle)
	print("Can't open file: " .. yaml_name)
	os.exit(1)
end

if yaml_obj["Sections"]["General Commands"] == nil then
	-- This is section 1
	yaml_obj["Sections"]["General Commands"] = {}
end

if yaml_obj["Sections"]["Macros and Conventions"] == nil then
	-- This is section 7
	yaml_obj["Sections"]["Macros and Conventions"] = {}
end

if yaml_obj["Sections"]["Maintenance Commands"] == nil then
	-- This is section 8
	yaml_obj["Sections"]["Maintenance Commands"] = {}
end

if yaml_obj["Sections"]["Extra libraries"] == nil then
	-- Extra libraries that does not go under base libraries
	yaml_obj["Sections"]["Extra libraries"] = {}
end

for line in io.lines() do
	local is_package_available = false
	local corrected_deps = {}
	local splitted_table = pkgconf.split_line(line, "|")
	local location_str = splitted_table[1]
	local name_str = splitted_table[2]
	local name_str_section = splitted_table[2]
	-- local dir_name = splitted_table[3]
	-- local another_name_str = splitted_table[4]
	local desc_str = splitted_table[3]
	local man_section = nil

	local name_ext = string.sub(location_str, -1)

	if tonumber(name_ext) ~= nil then
		name_str_section = name_str .. "(" .. name_ext .. ")"
		man_section = tonumber(name_ext)
	end

	local directory = location_str:match("(.*)/.*$")

	if whole_packages ~= nil and whole_packages[name_str] ~= nil then
		is_package_available = true
	end

	-- Parse depens from files
	local depends = pkgconf.depends_table(directory, name_str)

	if depends ~= nil and type(depends) == "table" then
		for _, v in ipairs(depends) do
			local cor_dep = v:match(".*%.(.*)$")
			table.insert(corrected_deps, cor_dep)
		end
	else
		print("Depends for " .. name_str .. " were nil")
	end

	if is_package_available == false then
		local cur_table = convert_create_table(
			name_str,
			directory,
			"FreeBSD project",
			pkgconf.man_url(name_str_section),
			desc_str,
			"15.0",
			"NOASSERTION",
			pkgconf.git_url(name_str),
			man_section,
			corrected_deps,
			nil,
			nil
		)

		if man_section then
			if man_section == 1 then
				yaml_obj["Sections"]["General Commands"][name_str] = cur_table
			elseif man_section == 7 then
				yaml_obj["Sections"]["Macros and Conventions"][name_str] = cur_table
			else
				yaml_obj["Sections"]["Maintenance Commands"][name_str] = cur_table
			end
		else
			yaml_obj["Sections"]["Extra libraries"][name_str] = cur_table
		end

		whole_packages[name_str] = cur_table
	end
end

for _, value in pairs(whole_packages) do
	value["is_database_yml"] = nil
end

io.write(yaml.dump({ yaml_obj }))

io.close(output_handle)
io.close(input_handle)

os.exit(0)
