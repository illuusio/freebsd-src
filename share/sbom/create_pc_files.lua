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
-- Example using for this would be with normal Lua 5.4:
-- LUA_PATH="./tools/lua/?.lua;;" tools/create_pc_files.lua database.yml pkgconf subdir
-- LUA_PATH="./tools/lua/?.lua;;" tools/create_pc_files.lua database.yml markdown
--

local pkgconf = require("pkgconf")
local ucl = require("ucl")

if #arg <= 1 then
	print("Usage:\tcreate_pc_files.lua database.yml [pkgconf|markdown|deps|apps|ucl] [subdir|additional.yaml]\n")
	print("\tParses database.yml and creates pkfconfig files to pkgconfig or subdir\n")
	print("\tpkgconf  - write pkgconf files under pkgconfig dir or if parameter subdir under package['directory']")
	print("\t           which means for example usr.bin/accton/usr.bin.accton.pc or pkgconfig/accton.pc")
	print("\tmarkdown - Export Database information as Markdown table for for placing it to Github for example")
	print("\tdeps     - Check is all deps in database.yml are correct and they can be found inside YAML structure")
	print("\tapps     - Print apps")
	print("\tucl      - Write YAML entries as UCL to current. They are named after application")
	print("\tmakefile - Write YAML entries as Makefile to current")
	os.exit(1)
end

local input_name = arg[1]
local addition_name = nil

local yaml_obj, whole_packages = pkgconf.parse_database(input_name, false)

if yaml_obj == nil or whole_packages == nil then
	print("Can't open file: " .. input_name)
	os.exit(1)
end

local is_pc_subdir = false

-- If subdir is in command line paramters
-- then .pc files are not placed under pkgconfig.
-- They are placed under directory-key directory
-- and named like usr.bin.accton.pc
if arg[3] ~= nil and arg[3] == "subdir" then
	is_pc_subdir = true
elseif arg[3] ~= nil and arg[3] ~= "subdir" then
	addition_name = arg[3]
end

local license_yaml_obj = nil
if addition_name ~= nil then
	license_yaml_obj = pkgconf.open_yaml(addition_name)
end

if arg[2] == nil or arg[2] == "pkgconf" then
	local meta_package = {}
	local dep_libraries = {}

	for key, value in pairs(whole_packages) do
		local dir_name = "pkgconfig"
		local cur_dir = "bin"
		if is_pc_subdir then
			dir_name = value["directory"]

			if dir_name == nil then
				dir_name = "./"
			end

			if type(dir_name) == "table" then
				dir_name = value["directory"][1]
			end
		end

		if value["directory"] ~= nil then
			if type(value["directory"]) == "table" then
				cur_dir = value["directory"][1]:gsub("%/", ".")
			else
				cur_dir = value["directory"]:gsub("%/", ".")
			end
		end

		local name_str = key

		local output_filename = name_str .. ".pc"
		if is_pc_subdir then
			output_filename = string.gsub(dir_name, "/", ".") .. ".pc"
		end
		local output_full = dir_name .. "/" .. output_filename
		local copyright_table = {}
		local license_file_table = {}
		local license_expression_spdx = {}

		if
			value["directory"] ~= nil
			and type(value["directory"]) == "string"
			and (string.find(value["directory"], "sbin/") ~= nil
			or string.find(value["directory"], "lib/geom") ~= nil)
			and license_yaml_obj ~= nil
			and license_yaml_obj[cur_dir] ~= nil
		then
			local cur_obj = license_yaml_obj[cur_dir]
			for _, subvalue in pairs(cur_obj) do
				if subvalue["copyrights"] ~= nil then
					for _, copyrights_value in ipairs(subvalue["copyrights"]) do
						pkgconf.add_string_to_table(copyright_table, copyrights_value)
					end
				end
				if subvalue["licenses"] ~= nil then
					for _, license_value in ipairs(subvalue["licenses"]) do
						local license_normalized = pkgconf.nomalize_license(license_value["license_original"])
						local hash_cmd = "echo -n '" .. license_normalized .. "' | " .. "openssl dgst -sha256 -"
						local hash_value = pkgconf.run_cmd(hash_cmd):sub(18, 25)
						local license_file = string.gsub(
							license_value["license_expression_spdx"] .. "." .. hash_value .. ".txt",
							"%s",
							"_"
						)
						pkgconf.add_string_to_table(license_expression_spdx, license_value["license_expression_spdx"])
						pkgconf.add_string_to_table(license_file_table, "${pcfiledir}/LICENSES/" .. license_file)
						if pkgconf.file_exists(license_file) == false then
							pkgconf.write_file(
								dir_name .. "/LICENSES/" .. license_file,
								license_value["license_original"]
							)
						end
					end
				end
			end
			if value["license"] == "NOASSERTION" and #license_expression_spdx > 0 then
				table.sort(license_expression_spdx)
				value["license"] = table.concat(license_expression_spdx, " AND ")
			end

			print("Write to PC-file to '" .. output_full .. "'")
			pkgconf.write_pkgconfig(
				output_full,
				name_str,
				value["description"],
				value["homepage"],
				value["version"],
				value["license"],
				value["source"],
				value["depends"],
				value["owner"],
				copyright_table,
				license_file_table
			)
			pkgconf.add_string_to_table(meta_package, string.lower(name_str))

			if value["depends"] ~= nil then
				-- Add depends to dep_libraries
				for _, dep_name in ipairs(value["depends"]) do
					pkgconf.add_string_to_table(dep_libraries, dep_name)
					pkgconf.add_string_to_table(meta_package, string.lower(dep_name))
				end
			end
		end
	end
	-- Create dep packages
	for _, dep_name in ipairs(dep_libraries) do
		if whole_packages[dep_name] ~= nil then
			local package = whole_packages[dep_name]
			local output_filename = dep_name .. ".pc"
			local output_full = "pkgconfig/" .. output_filename
			pkgconf.write_pkgconfig(
				output_full,
				dep_name,
				package["description"],
				package["homepage"],
				package["version"],
				package["license"],
				package["source"],
				package["depends"],
				package["owner"],
				nil,
				nil
			)
			if package["depends"] ~= nil then
				for _, new_dep in ipairs(package["depends"]) do
					pkgconf.add_string_to_table(dep_libraries, new_dep)
					pkgconf.add_string_to_table(meta_package, string.lower(new_dep))
				end
			end
		end
	end

	-- Write FreeBSD metapackage which holds every pkgconfig and make sure that
	-- that we can create whole SBOM
	table.sort(meta_package)
	pkgconf.write_pkgconfig(
		"pkgconfig/FreeBSD.pc",
		"FreeBSD",
		"Power to serve",
		"https://www.freebsd.org/",
		"15.0",
		"NOASSERTION",
		"https://cgit.freebsd.org/src/",
		meta_package
	)
elseif arg[2] ~= nil and arg[2] == "markdown" then
	local markdown_license_table = {}
	local markdown_noassertion_table = {}
	local markdown_what_license_table = {}
	local markdown_license_count = 0
	local markdown_noassertion_count = 0

	for key, value in pairs(whole_packages) do
		local markdown_str = "| " .. key .. " | "
		markdown_str = pkgconf.add_value(markdown_str, "Description", value["description"], true)
		markdown_str = pkgconf.add_value(markdown_str, "Version", value["version"], true)
		markdown_str = pkgconf.add_value(markdown_str, "License", value["license"], true)
		markdown_str = pkgconf.add_value(markdown_str, "Directory", value["directory"], true)
		markdown_str = pkgconf.add_value(markdown_str, "Homepage", value["homepage"], true)
		markdown_str = pkgconf.add_value(markdown_str, "Section", value["section"], true)
		markdown_str = pkgconf.add_value(markdown_str, "Source", value["source"], true)
		markdown_str = pkgconf.add_value(markdown_str, "Upstream", value["upstream"], true)

		local add_str = pkgconf.depends_from_table(value["depends"], true)
		if add_str ~= nil then
			markdown_str = markdown_str .. add_str
		else
			markdown_str = markdown_str .. " | none"
		end

		add_str = pkgconf.maintainer_from_table(value["owner"], true)
		if add_str ~= nil then
			markdown_str = markdown_str .. " | " .. add_str .. " |"
		else
			markdown_str = markdown_str .. " | none |"
		end

		if value["license"] ~= "NOASSERTION" then
			table.insert(markdown_license_table, markdown_str)
			markdown_license_count = markdown_license_count + 1
			local license_str = value["license"]
			if license_str ~= nil and type(license_str) == "string" then
				if markdown_what_license_table[license_str] == nil then
					markdown_what_license_table[license_str] = 0
				end
				markdown_what_license_table[license_str] = markdown_what_license_table[license_str] + 1
			else
				print("License nil or table in: " .. key)
			end
		else
			table.insert(markdown_noassertion_table, markdown_str)
			markdown_noassertion_count = markdown_noassertion_count + 1
		end
	end

	local sorted_key_table = {}
	for key, _ in pairs(markdown_what_license_table) do
		table.insert(sorted_key_table, key)
	end

	table.sort(sorted_key_table)
	print(
		"# FreeBSD current licenses in files which have SPDX-License-Identifier (count: "
			.. markdown_license_count
			.. ")"
	)
	print("| License or combination | count |")
	print("| :--------------------: | :---: |")
	for _, key in ipairs(sorted_key_table) do
		print("| " .. key .. " | " .. markdown_what_license_table[key] .. " |")
	end

	print("\n")

	print("# FreeBSD tools with license information (count: " .. markdown_license_count .. ")")
	print(
		"| Name | Description | Version | License | Directory | Homepage | Section | Source | Upstream | Depends | Owner |"
	)
	print(
		"| :--: | :---------: | :-----: | :-----: | :-------: | :------: | :-----: | :----: | :------: | :-----: | :---: |"
	)

	table.sort(markdown_noassertion_table)
	table.sort(markdown_license_table)
	print(table.concat(markdown_license_table, "\n"))

	print(
		"\n# FreeBSD tools without license information but have man page (count: " .. markdown_noassertion_count .. ")"
	)
	print(
		"| Name | Description | Version | License | Directory | Homepage | Section | Source | Upstream | Depends | Owner |"
	)
	print(
		"| :--: | :---------: | :-----: | :-----: | :-------: | :------: | :-----: | :----: | :------: | :-----: | :---: |"
	)
	print(table.concat(markdown_noassertion_table, "\n"))
elseif arg[2] ~= nil and arg[2] == "deps" then
	for key, value in pairs(whole_packages) do
		if type(value["depends"]) == "string" then
			print("Depends is string not table: '" .. key .. "'")
		elseif value ~= value["depends"] and type(value["depends"]) == "table" then
			for _, subvalue in ipairs(value["depends"]) do
				local lower_string = string.lower(subvalue)
				if whole_packages[lower_string] == nil then
					print(subvalue)
				end
			end
		end
	end
elseif arg[2] ~= nil and arg[2] == "apps" then
	local usr_bin = {}
	local usr_sbin = {}
	local bin = {}
	local sbin = {}
	local usr_bin_correct = {}
	-- These are installed somewhere else than they are compiled
	usr_bin_correct["usr/sbin/bsnmpget"] = "usr/bin/bsnmpget"
	usr_bin_correct["usr/sbin/chgrp"] = "usr/bin/chgrp"
	usr_bin_correct["usr/sbin/crontab"] = "usr/bin/crontab"
	usr_bin_correct["usr/sbin/crunchgen"] = "usr/bin/crunchgen"
	usr_bin_correct["usr/sbin/crunchide"] = "usr/bin/crunchide"
	usr_bin_correct["usr/sbin/lp"] = "usr/bin/lp"
	usr_bin_correct["usr/sbin/lpq"] = "usr/bin/lpq"
	usr_bin_correct["usr/sbin/lpr"] = "usr/bin/lpr"
	usr_bin_correct["usr/sbin/lprm"] = "usr/bin/lprm"
	usr_bin_correct["usr/sbin/pmcstudy"] = "usr/bin/pmcstudy"
	for key, value in pairs(whole_packages) do
		if value["directory"] ~= nil then
			local output_str = key
			if type(value["directory"]) == "table" then
				for _, innervalue in ipairs(value["directory"]) do
					output_str = output_str .. " / " .. innervalue
				end
			else
				local directory_str = value["directory"]:gsub("%.", "/")

				if directory_str:find("usr/sbin") then
					local cur_dir = "usr/sbin/" .. key
					if usr_bin_correct[cur_dir] ~= nil then
						table.insert(usr_sbin, usr_bin_correct[cur_dir])
					else
						table.insert(usr_sbin, "usr/sbin/" .. key)
					end
				elseif directory_str:find("usr/bin") then
					table.insert(usr_bin, "usr/bin/" .. key)
				elseif directory_str:find("sbin") then
					table.insert(sbin, "sbin/" .. key)
				elseif directory_str:find("bin") then
					table.insert(bin, "bin/" .. key)
				end
			end
		end
	end
	table.sort(usr_bin)
	table.sort(usr_sbin)
	table.sort(sbin)
	table.sort(bin)
	for _, value in ipairs(usr_bin) do
		print(value)
	end
	for _, value in ipairs(usr_sbin) do
		print(value)
	end
	for _, value in ipairs(sbin) do
		print(value)
	end
	for _, value in ipairs(bin) do
		print(value)
	end
elseif arg[2] ~= nil and arg[2] == "ucl" then
	-- local parser = ucl.parser()
	local license_obj = {}
	license_obj["texts"] = {}
	for key, value in pairs(whole_packages) do
		local ucl_obj = {}
		local cur_dir = "bin"
		print(key)

		ucl_obj["application"] = key
		if value["version"] ~= nil then
			ucl_obj["version"] = value["version"]
		end
		if value["depends"] ~= nil then
			ucl_obj["deps"] = value["depends"]
		end
		if value["directory"] ~= nil then
			if type(value["directory"]) == "string" then
				ucl_obj["origin"] = { value["directory"] }
				cur_dir = value["directory"]:gsub("%/", ".")
			else
				ucl_obj["origin"] = value["directory"]
				cur_dir = value["directory"][1]:gsub("%/", ".")
			end
		end
		if value["owner"] ~= nil then
			if type(value["owner"]) == "string" then
				ucl_obj["owner"] = { value["owner"] }
			else
				ucl_obj["owner"] = value["owner"]
			end
		end
		if value["homepage"] ~= nil then
			ucl_obj["homepage"] = value["homepage"]
		end
		if value["description"] ~= nil then
			ucl_obj["desc"] = value["description"]
		end
		if value["license"] ~= nil then
			if string.match(value["license"], " AND ") then
				-- for i in string.gmatch(value["license"], " AND ") do
				print(value["license"])
				local first_index = 1
				local start_index = nil
				local end_index = nil
				local cur_loop = true
				local split = {}
				while cur_loop == true do
					start_index, end_index = string.find(value["license"], " AND ", end_index)
					if start_index == nil then
						cur_loop = false
						table.insert(split, value["license"]:sub(first_index))
					else
						table.insert(split, value["license"]:sub(first_index, (end_index - 5)))
						first_index = (end_index + 1)
					end
				end

				ucl_obj["license"] = split
			else
				ucl_obj["license"] = {}
				table.insert(ucl_obj["license"], value["license"])
			end
			ucl_obj["spdx_license_identifier"] = value["license"]
		end
		if value["source"] ~= nil then
			ucl_obj["source"] = value["source"]
		end
		if value["section"] ~= nil then
			ucl_obj["man"] = key .. "(" .. value["section"] .. ")"
		end
		print(cur_dir)

		if license_yaml_obj ~= nil and license_yaml_obj[cur_dir] ~= nil then
			local cur_obj = license_yaml_obj[cur_dir]
			if ucl_obj["copyright"] == nil then
				ucl_obj["copyright"] = {}
			end
			if ucl_obj["license_text"] == nil then
				ucl_obj["license_text"] = {}
			end
			for _, subvalue in pairs(cur_obj) do
				if value["copyrights"] ~= nil then
					for _, subbervalue in ipairs(value["copyrights"]) do
						print(ucl_obj["copyright"])
						pkgconf.add_string_to_table(ucl_obj["copyright"], subbervalue)
					end
				end
				if subvalue["license_original"] ~= nil then
					print(subvalue["license_original"])
					pkgconf.add_string_to_table(ucl_obj["license_text"], subvalue["license_original"])
					pkgconf.add_string_to_table(license_obj["texts"], subvalue["license_original"])
				end
			end
		end
		local fh, err = io.open(cur_dir .. ".ucl", "w")
		if not fh then
			io.stderr:write(arg[0] .. ": fail to open(" .. arg[#arg] .. "): " .. err)
			os.exit(1)
		end
		fh:write(ucl.to_format(ucl_obj, "ucl", true))
		fh:flush()
		fh:close()
	end
	local fh, err = io.open("licenses.ucl", "w")
	if not fh then
		io.stderr:write(arg[0] .. ": fail to io.open(licenses.ucl): " .. err)
		os.exit(1)
	end
	fh:write(ucl.to_format(license_obj, "ucl", true))
	fh:flush()
	fh:close()
end

os.exit(0)
