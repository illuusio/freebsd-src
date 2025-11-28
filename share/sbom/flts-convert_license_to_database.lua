#!/usr/libexec/flua

-- SPDX-License-Identifier: BSD-2-Clause
--
-- Copyright(c) 2025 The FreeBSD Foundation.
--
-- This software was developed by Tuukka Pasanen <tuukka.pasanen@ilmi.fi>
-- under sponsorship from the FreeBSD Foundation.
--
-- Convert license CSV information to YAML database.yml format
-- Script seeks correct package and adds license information
-- It also combines multiple licenses to one SPDX expression
--
-- Run on top directory something like
-- share/sbom/flts-convert_license_to_database.lua share/sbom/FreeBSD-license.csv database_directory/database.yml

local yaml = require("lyaml")
local pkgconf = require("pkgconf")

local function convert_license_descending(a, b)
	return a > b
end

if #arg <= 2 then
	print("Usage:\tflts-convert_license_to_database.lua [csv input file (separator '|')] [output.yaml] [input.json]\n")
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

local yaml_obj, whole_packages = pkgconf.parse_database(yaml_name, true)

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

local cur_dir = nil
-- local cur_app = nil
local cur_license_table = {}

for line in io.lines() do
	-- local is_package_available = false
	-- local corrected_deps = {}
	local splitted_table = pkgconf.split_line(line, "|")
	local location_str = splitted_table[1]
	local location_directory = location_str:match("(.*)/.*$")
	-- local location_filename = location_str:match(".*/(.*)$")
	local license_str = splitted_table[2]

	if cur_dir == nil then
		cur_dir = location_directory
		-- cur_app = location_filename
	end

	-- If directory is same then just add license if it's not found
	if cur_dir == location_directory then
		local is_found = false

		for _, value in ipairs(cur_license_table) do
			if value == license_str then
				is_found = true
			end
		end

		if is_found == false then
			table.insert(cur_license_table, license_str)
		end
	elseif cur_dir ~= nil and cur_dir ~= location_directory then
		table.sort(cur_license_table, convert_license_descending)

		if whole_packages ~= nil and whole_packages[cur_dir] ~= nil then
			print("Found '" .. cur_dir .. "' license: " .. table.concat(cur_license_table, " AND "))
			if whole_packages[cur_dir]["license"] ~= nil then
				whole_packages[cur_dir]["license"] = table.concat(cur_license_table, " AND ")
			end
		else
			print("Not Found '" .. cur_dir .. "' license: " .. table.concat(cur_license_table, " AND "))
		end

		cur_dir = nil
		-- cur_app = nil
		cur_license_table = {}
		table.insert(cur_license_table, license_str)
	end
end

if whole_packages ~= nil then
	for _, value in pairs(whole_packages) do
		value["is_database_yml"] = nil
	end
end

io.write(yaml.dump({ yaml_obj }))

io.close(output_handle)
io.close(input_handle)

os.exit(0)
