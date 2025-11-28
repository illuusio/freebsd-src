#!/usr/libexec/flua

-- SPDX-License-Identifier: BSD-2-Clause
--
-- Copyright(c) 2025 The FreeBSD Foundation.
--
-- This software was developed by Tuukka Pasanen <tuukka.pasanen@ilmi.fi>
-- under sponsorship from the FreeBSD Foundation.
--
-- Convert scancode JSON output to more easier to use JSON
--
-- Basic structure is:
-- "bin.cat": {
--   "cat.c": {
--      "copyrights": [
--         "2026, Copyright text"
--      ],
--      "license_expression_spdx": "NOASSERTION",
--      "licenses": [
--        {
--          "license_acknowledgements": "NOASSERTION",
--          "license_author": "NOASSERTION",
--          "license_event": "NOASSERTION",
--          "license_expression_spdx": "NOASSERTION",
--          "license_match": 100,
--          "license_normalized": "License text which does is normalized§",
--          "license_original": "Original license text",
--          "license_promote": "NOASSERTION"
--        }
--      ],
--      "spdx_license_identifier_incorrect": false,
--      "spdx_license_identifier_match": "NOASSERTION"
--    }
-- },
--

local pkgconf = require("pkgconf")
local yaml = require("lyaml")
local ucl = require("ucl")

if #arg < 2 then
	print("Usage:\tflts-convert_scancode.lua [scancode.json] [output.json]\n")
	print("\t\tParse YAML ja organise it by license and match level\n")
	os.exit(1)
end

local input_name = arg[1]
local output_name = arg[2]

local input_handle = io.open(input_name, "r")
local output_handle = io.open(output_name, "w+")

if not input_handle then
	io.close(output_handle)
	print("Can't open file: " .. input_name)
	os.exit(1)
end

if not output_handle then
	io.close(input_handle)
	print("Can't open file: " .. output_name)
	os.exit(1)
end

-- set name_handle as default input
io.input(input_handle)
io.output(output_handle)

local yaml_obj = nil

if input_name:match("%.json$") then
	input_handle:close()
	local parser = ucl.parser()
	local is_error, err = parser:parse_file(input_name)

	if is_error == false then
		print("flts-convert_scancode.lua: Can't parse JSON file " .. input_name .. ": " .. err)
		io.close(input_handle)
		io.close(output_handle)
		return nil
	end

	yaml_obj = parser:get_object()
else
	local yaml_content = input_handle:read("*all")
	input_handle:close()
	yaml_obj = yaml.load(yaml_content)
	yaml_content = nil
end

local license_texts = {}
local license_table = {}

for _, cur_obj in pairs(yaml_obj["files"]) do
	if cur_obj["type"] == "file" then
		local spdx_header = false
		local license_expression_spdx = ""
		local from_file = cur_obj["path"]
		local dir_name = from_file:match("^(.+)%/.+$"):gsub("%/", ".")
		local file_name = from_file:match("^.+%/(.+)$")
		if license_table[dir_name] == nil then
			license_table[dir_name] = {}
		end
		if license_table[dir_name][file_name] == nil then
			license_table[dir_name][file_name] = {}
		end
		local cur_table = license_table[dir_name][file_name]
		cur_table["licenses"] = {}
		cur_table["license_expression_spdx"] = "NOASSERTION"
		for _, license_detections_obj in pairs(cur_obj["license_detections"]) do
			for _, matches_obj in pairs(license_detections_obj["matches"]) do
				license_expression_spdx = matches_obj["license_expression_spdx"]

				if matches_obj["matcher"] == "1-spdx-id" then
					cur_table["spdx_license_identifier_match"] = matches_obj["matched_text"]
					cur_table["spdx_license_identifier_incorrect"] = false
					if matches_obj["license_expression_spdx"] ~= license_expression_spdx then
						print(
							from_file
								.. " "
								.. matches_obj["license_expression_spdx"]
								.. "Indetifier does not match to "
								.. license_expression_spdx
						)
						cur_table["spdx_license_identifier_incorrect"] = true
					end
					cur_table["license_expression_spdx"] = license_expression_spdx
					spdx_header = true
				else
					local license_text = pkgconf.remove_commenting(matches_obj["matched_text"])
					if license_text == nil then
						print("flts-convert_scancode.lua: Can't remove comments")
						io.close(output_handle)
						io.close(input_handle)
						os.exit(1)
					end
					local license_text_without_enter = pkgconf.nomalize_license(license_text)
					-- Changes this as just for comparing
					if license_text_without_enter == nil then
						print("flts-convert_scancode.lua: Can't normalize license")
						io.close(output_handle)
						io.close(input_handle)
						os.exit(1)
					end
					local license_author = pkgconf.get_author(license_text_without_enter)
					local license_acknowledgements = pkgconf.get_acknowledgements(license_text_without_enter)
					local license_promote = pkgconf.get_promote(license_text_without_enter)
					local license_event = pkgconf.get_event(license_text_without_enter)

					if license_author == nil then
						license_author = "NOASSERTION"
					end
					if license_event == nil then
						license_event = "NOASSERTION"
					end
					if license_promote == nil then
						license_promote = "NOASSERTION"
					end
					if license_acknowledgements == nil then
						license_acknowledgements = "NOASSERTION"
					end
					local cur_license = {}
					cur_license["license_expression_spdx"] = license_expression_spdx
					cur_license["license_original"] = license_text
					cur_license["license_normalized"] = license_text_without_enter
					cur_license["license_match"] = matches_obj["match_coverage"]
					cur_license["license_author"] = license_author
					cur_license["license_acknowledgements"] = license_acknowledgements
					cur_license["license_promote"] = license_promote
					cur_license["license_event"] = license_event
					table.insert(cur_table["licenses"], cur_license)
				end
			end
		end

		cur_table["copyrights"] = {}
		for _, copyright_obj in pairs(cur_obj["copyrights"]) do
			local copyright_str = copyright_obj["copyright"]:gsub("Copyright %(c%) ", "")
			table.insert(cur_table["copyrights"], copyright_str)
		end

		if
			license_expression_spdx ~= ""
			and from_file ~= ""
			and cur_table ~= nil
			and cur_table["license_normalized"] ~= nil
		then
			if spdx_header == false then
				cur_table["spdx_license_identifier"] = "License-Missing"
				cur_table["spdx_license_identifier_incorrect"] = true
			end
		end
	end
end

-- io.write(yaml.dump({ license_table }))
io.write(ucl.to_format(license_table, "json", true))
io.flush()

io.close(output_handle)

os.exit(0)
