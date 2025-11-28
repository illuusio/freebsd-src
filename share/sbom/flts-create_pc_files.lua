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
-- LUA_PATH="./tools/lua/?.lua;;" tools/flts-create_pc_files.lua database.yml pkgconf subdir
-- LUA_PATH="./tools/lua/?.lua;;" tools/flts-create_pc_files.lua database.yml markdown
--

local pkgconf = require("pkgconf")
local ucl = require("ucl")

-- For highlightning parts of BSD license
local test_patterns_bsd = {
	"Redistribution and use in source and binary forms, with or without modification, are permitted providing that the following conditions are met:",
	"Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met:",
	"Redistributions of source code must retain the above copyright notice,",
	"this list of conditions and the following disclaimer%.",
	"Redistributions in binary form must reproduce the above copyright notice,",
	"this list of conditions and the following disclaimer in the documentation",
	"and/or other materials provided with the distribution.",
	"may be used to endorse or promote products derived from this software without specific prior written permission%.",
	"All advertising materials mentioning features or use of this software must display the following acknowledgement:",
	"1%.",
	"2%.",
	"3%.",
	"4%.",
	"THIS SOFTWARE IS PROVIDED BY",
	'"AS IS"',
	"``AS IS''",
	"`AS IS'",
	"'AS IS'",
	"AND ANY EXPRESS OR IMPLIED WARRANTIES,",
	"INCLUDING, BUT NOT LIMITED TO,",
	"THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED%.",
	"IN NO EVENT SHALL",
	"BE LIABLE FOR ANY DIRECT,",
	"INDIRECT,",
	"INCIDENTAL,",
	"SPECIAL,",
	"EXEMPLARY,",
	"OR CONSEQUENTIAL DAMAGES",
	"PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES;",
	"LOSS OF USE,",
	"DATA,",
	"OR PROFITS;",
	"OR BUSINESS INTERRUPTION",
	"HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY,",
	"WHETHER IN CONTRACT,",
	"STRICT LIABILITY,",
	"OR TORT",
	"INCLUDING NEGLIGENCE OR OTHERWISE",
	"ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE,",
	"EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE%.",
}

if #arg <= 1 then
	print("Usage:\tflts-create_pc_files.lua database.yml [pkgconf|markdown|deps|apps|ucl] [subdir|additional.yaml]\n")
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

local allowed_dirs = {
	"bin/",
	"cddl/contrib/opensolaris/tools/ctf/cvt",
	"cddl/contrib/opensolaris/cmd/dtrace",
	"cddl/usr.sbin/dwatch",
	"contrib/bc",
	"contrib/bmake",
	"contrib/bsddialog",
	"contrib/byacc",
	"contrib/bzip2",
	"contrib/com_err",
	"contrib/diff",
	"contrib/ee",
	"contrib/elftoolchain",
	"contrib/file",
	"contrib/flex",
	"contrib/kyua",
	"contrib/lua",
	"contrib/ldns",
	"contrib/less",
	"contrib/libarchive",
	"contrib/libxo",
	"contrib/mandoc",
	"contrib/ncurses",
	"contrib/netcat",
	"contrib/ntp",
	"contrib/nvi",
	"contrib/ofed",
	"contrib/one%-true%-awk",
	"contrib/pf/ftp%-proxy",
	"contrib/sendmail",
	"contrib/smbfs",
	"contrib/tcpdump",
	"contrib/tcp_wrappers",
	"contrib/telnet",
	"contrib/tnftp",
	"contrib/ts",
	"contrib/tzcode",
	"contrib/unifdef",
	"contrib/wireguard%-tools",
	"contrib/wpa",
	"contrib/xz",
	"crypto/krb5",
	"crypto/openssh",
	"lib/geom",
	"sbin/",
	"sys/contrib/openzfs",
	"sys/contrib/zstd",
	"usr.bin/",
	"usr.sbin/",
}

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

		local is_correct = false

		if value["directory"] ~= nil and type(value["directory"]) == "string" then
			for _, searchvalue in ipairs(allowed_dirs) do
				if string.find(value["directory"], searchvalue) ~= nil then
					is_correct = true
					break
				end
			end
		end

		if is_correct == true and license_yaml_obj ~= nil and license_yaml_obj[cur_dir] ~= nil then
			local cur_obj = license_yaml_obj[cur_dir]
			for _, subvalue in pairs(cur_obj) do
				if subvalue["copyrights"] ~= nil then
					for _, copyrights_value in ipairs(subvalue["copyrights"]) do
						pkgconf.add_string_to_table(copyright_table, copyrights_value)
					end
					table.sort(copyright_table)
				end
				if subvalue["licenses"] ~= nil then
					for _, license_value in ipairs(subvalue["licenses"]) do
						local license_normalized = pkgconf.nomalize_license(license_value["license_original"])
						if license_normalized ~= nil then
							license_normalized = license_normalized:gsub("'", "\""):gsub("`", "\"")
						end
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
					table.sort(license_file_table)
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
	local license_hash_table = {}

	for key, value in pairs(whole_packages) do
		local markdown_str = "| " .. key .. " | "
		local cur_dir = nil

		if value["directory"] ~= nil then
			if type(value["directory"]) == "table" then
				cur_dir = value["directory"][1]:gsub("%/", ".")
			else
				cur_dir = value["directory"]:gsub("%/", ".")
			end
		end

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

		local is_correct = false

		if value["directory"] ~= nil and type(value["directory"]) == "string" then
			for _, searchvalue in ipairs(allowed_dirs) do
				if string.find(value["directory"], searchvalue) ~= nil then
					is_correct = true
					break
				end
			end
		end

		if is_correct == true and license_yaml_obj ~= nil and license_yaml_obj[cur_dir] ~= nil then
			local cur_obj = license_yaml_obj[cur_dir]
			for subkey, subvalue in pairs(cur_obj) do
				local copyright_table = {}
				if subvalue["copyrights"] ~= nil then
					for _, copyrights_value in ipairs(subvalue["copyrights"]) do
						pkgconf.add_string_to_table(copyright_table, copyrights_value)
					end
				end
				if subvalue["licenses"] ~= nil then
					for _, license_value in ipairs(subvalue["licenses"]) do
						local license_normalized, sha256_value =
							pkgconf.calculate_sha256(license_value["license_original"])
						local license_name = "License-Name-Unknown"
						local sha256_value_16 = nil
						if sha256_value ~= nil and license_value["license_expression_spdx"] ~= nil then
							license_name = string.gsub(
								-- license_value["license_expression_spdx"] .. "." .. sha256_value:sub(0,8),
								license_value["license_expression_spdx"],
								"%s",
								"_"
							)
							sha256_value_16 = sha256_value:sub(0, 16)
						end
						local acknowledgements = nil
						local promote = nil
						local author = nil
						local event = nil

						if license_normalized ~= nil then
							acknowledgements = pkgconf.get_acknowledgements(license_normalized)
							promote = pkgconf.get_promote(license_normalized)
							author = pkgconf.get_author(license_normalized)
							event = pkgconf.get_event(license_normalized)

							if acknowledgements ~= nil then
								pkgconf.add_string_to_table(test_patterns_bsd, pkgconf.escape_regex(acknowledgements))
							end
							if promote ~= nil then
								pkgconf.add_string_to_table(test_patterns_bsd, pkgconf.escape_regex(promote))
							end
							if author ~= nil then
								pkgconf.add_string_to_table(test_patterns_bsd, pkgconf.escape_regex(author))
							end
							if event ~= nil then
								pkgconf.add_string_to_table(test_patterns_bsd, pkgconf.escape_regex(event))
							end

							for _, value_str in ipairs(test_patterns_bsd) do
								-- Mark founded strings
								license_normalized =
									license_normalized:gsub(value_str, "{" .. value_str:gsub("%%.", ".") .. "}")
							end

							-- Find string that does not comply license
							local not_comply_table = pkgconf.split_line(license_normalized, "}")

							local output_license = ""

							for _, line in ipairs(not_comply_table) do
								if
									line:sub(1, 1) ~= "{"
									and line:sub(1, 2) ~= " {"
									and line:sub(1, 3) ~= " ({"
									and line:sub(1, 3) ~= ") {"
								then
									output_license = output_license
										.. line:gsub("^%s(.*)%s%{", ' <span style="color:tomato">%1</span> {')
								else
									output_license = output_license .. line
								end
							end

							license_normalized = output_license:gsub("{", ""):gsub("%s([1234]%.)%s", " **%1** ")

							if event ~= nil then
								license_normalized =
									license_normalized:gsub(pkgconf.escape_regex(event), "<u>" .. event .. "</u>")
							end
							if acknowledgements ~= nil then
								license_normalized = license_normalized:gsub(
									pkgconf.escape_regex(acknowledgements),
									"<u>" .. acknowledgements .. "</u>"
								)
							end
							if promote ~= nil then
								license_normalized =
									license_normalized:gsub(pkgconf.escape_regex(promote), "<u>" .. promote .. "</u>")
							end
							if author ~= nil then
								license_normalized =
									license_normalized:gsub(pkgconf.escape_regex(author), "<u>" .. author .. "</u>")
							end
						end

						if license_hash_table[license_name] == nil then
							license_hash_table[license_name] = {}
						end
						if sha256_value_16 ~= nil and license_hash_table[license_name][sha256_value_16] == nil then
							license_hash_table[license_name][sha256_value_16] = {}
							license_hash_table[license_name][sha256_value_16]["files"] = {}
							license_hash_table[license_name][sha256_value_16]["license_normalized"] = license_normalized
							license_hash_table[license_name][sha256_value_16]["acknowledgements"] = acknowledgements
							license_hash_table[license_name][sha256_value_16]["promote"] = promote
							license_hash_table[license_name][sha256_value_16]["author"] = author
							license_hash_table[license_name][sha256_value_16]["event"] = event
						end
						local file_location = subkey
						if cur_dir ~= nil then
							file_location = cur_dir:gsub("%.", "/") .. "/" .. subkey
							file_location = file_location:gsub("^usr/", "usr.")
						end
						if license_hash_table[license_name][sha256_value_16]["files"][file_location] == nil then
							license_hash_table[license_name][sha256_value_16]["files"][file_location] = {}
						end
						-- pkgconf.add_string_to_table(license_hash_table[license_name][sha256_value_16]["files"], file_location)
						for _, copyright_value in ipairs(copyright_table) do
							pkgconf.add_string_to_table(
								license_hash_table[license_name][sha256_value_16]["files"][file_location],
								copyright_value
							)
						end
					end
				end
			end
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

	for key, value in pkgconf.get_arranged_table(license_hash_table) do
		print("# License: " .. key .. "\n")
		for subkey, subvalue in pkgconf.get_arranged_table(value) do
			print("## License variant: " .. key .. " / " .. subkey .. "\n")
			if subvalue["acknowledgements"] ~= nil then
				print("* Acknowledgements: " .. subvalue["acknowledgements"])
			end
			if subvalue["promote"] then
				print("* Promote: " .. subvalue["promote"])
			end
			if subvalue["author"] then
				print("* Author: " .. subvalue["author"])
			end
			if subvalue["event"] then
				print("* Event: " .. subvalue["event"])
			end
			print("\n")
			table.sort(subvalue["files"])
			-- table.sort(subvalue["copyrights"])
			print("### File(s)\n")
			for file_location, file_value in pkgconf.get_arranged_table(subvalue["files"]) do
				print("- " .. file_location)
				table.sort(file_value)
				for _, copyright_value in ipairs(file_value) do
					print("    - " .. copyright_value)
				end
			end
			print("\n## Normalized text\n" .. subvalue["license_normalized"] .. "\n")
		end
	end

	os.exit(1)
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
