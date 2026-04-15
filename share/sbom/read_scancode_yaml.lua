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
-- Run scan code like this to read bin-directory in root:
-- scancode --info --copyright --license --license-text --ignore "test*" --ignore "*.1" --ignore "*.2" --ignore "*.3" --ignore "*.4" --ignore "*.5" --ignore "*.6" --ignore "*.7" --ignore "*.8" --ignore "*.sh" --ignore "Makefile*" --include "*.c" --include "*.h" --include "*.cc" --include "*.hh" --yaml "scancode_bin.yaml" bin
--
-- Run on top directory something like
-- share/sbom/convert_csv_to_json.lua share/sbom/FreeBSD-apps.csv output.yaml database_directory/database.yml

local yaml = require("lyaml")
local ucl = require("ucl")

local function scancode_split_line(line, sep)
	local rtn_table = {}

	if sep == nil then
		sep = " "
	end

	for str in string.gmatch(line, "([^" .. sep .. "]+)") do
		table.insert(rtn_table, str)
	end

	return rtn_table
end

local function scancode_compare_strings(string1, string2)
	local first_table = scancode_split_line(string1)
	local second_table = scancode_split_line(string2)
	local diff_string = nil
	for i, string in ipairs(first_table) do
		if second_table[i] ~= nil then
			if string ~= second_table[i] then
				if diff_string == nil then
					diff_string = ""
				end
				diff_string = diff_string .. " [" .. string .. "/ " .. second_table[i] .. "]"
			end
		end
	end
	return diff_string
end

if #arg < 2 then
	print("Usage:\tread_scancode_yaml.lua [scancode.yaml] [output.yaml]\n")
	print("\t\tParse YAML ja organise it by license and match level\n")
	os.exit(1)
end

local input_name = arg[1]
local output_name = arg[2]

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

local yaml_obj = nil

if input_name:match("%.json$") then
	input_handle:close()
	local parser = ucl.parser()
	local is_error, err = parser:parse_file(input_name)

	if is_error == false then
		print("pkgconf.open_yaml: Can't parse JSON file " .. location .. ": " .. err)
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

license_texts["BSD-2-Clause"] =
	'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. THIS SOFTWARE IS PROVIDED BY <AUTHOR> "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <AUTHOR> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

-- Contains this extra text "in this position and unchanged" when compared with a BSD-2-Clause.
license_texts["LicenseRef-scancode-bsd-unchanged"] =
	'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer in this position and unchanged. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. THIS SOFTWARE IS PROVIDED BY <AUTHOR> "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <AUTHOR> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

-- Contains text: without modification, immediately at the beginning of the file.
license_texts["BSD-Source-beginning-file"] =
	'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer, without modification, immediately at the beginning of the file. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. THIS SOFTWARE IS PROVIDED BY <AUTHOR> "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <AUTHOR> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

license_texts["BSD-3-Clause"] =
	'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 3. Neither the name of <PROMOTE> may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY <AUTHOR> "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <AUTHOR> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

license_texts["BSD-4-Clause"] =
	'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 3. All advertising materials mentioning features or use of this software must display the following acknowledgements: <ACKNOWLEDGEMENTS> 4. The name of the author may not be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY <AUTHOR> "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <AUTHOR> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

test =
	'Redistribution and use in source and binary forms, with or without modification, are permitted provided that the following conditions are met: 1. Redistributions of source code must retain the above copyright notice, this list of conditions and the following disclaimer. 2. Redistributions in binary form must reproduce the above copyright notice, this list of conditions and the following disclaimer in the documentation and/or other materials provided with the distribution. 3. Neither the name of <PROMOTE> may be used to endorse or promote products derived from this software without specific prior written permission. THIS SOFTWARE IS PROVIDED BY <AUTHOR> "AS IS" AND ANY EXPRESS OR IMPLIED WARRANTIES, INCLUDING, BUT NOT LIMITED TO, THE IMPLIED WARRANTIES OF MERCHANTABILITY AND FITNESS FOR A PARTICULAR PURPOSE ARE DISCLAIMED. IN NO EVENT SHALL <AUTHOR> BE LIABLE FOR ANY DIRECT, INDIRECT, INCIDENTAL, SPECIAL, EXEMPLARY, OR CONSEQUENTIAL DAMAGES (INCLUDING, BUT NOT LIMITED TO, PROCUREMENT OF SUBSTITUTE GOODS OR SERVICES; LOSS OF USE, DATA, OR PROFITS; OR BUSINESS INTERRUPTION) HOWEVER CAUSED AND ON ANY THEORY OF LIABILITY, WHETHER IN CONTRACT, STRICT LIABILITY, OR TORT (INCLUDING NEGLIGENCE OR OTHERWISE) ARISING IN ANY WAY OUT OF THE USE OF THIS SOFTWARE, EVEN IF ADVISED OF THE POSSIBILITY OF SUCH DAMAGE.'

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
				end
				if matches_obj["matcher"] ~= "1-spdx-id" then
					local license_text = matches_obj["matched_text"]
						:gsub("\n %* ", "\n")
						:gsub("\n %*\t", "\n\t")
						:gsub("^ %* ", "")
						:gsub("\n%* ", "\n")
						:gsub("\n%*", "\n")
						:gsub("^%* ", "")
						:gsub("\n %*\n", "\n")
					local license_text_without_enter = license_text
						:gsub("\n", " ")
						:gsub("\t", " ")
						:gsub("%s+", " ")
						:gsub("`", "'")
						:gsub("%'+", '"')
						:gsub(" $", "")
					-- Changes this as just for comparing
					local license_author = license_text_without_enter:match('PROVIDED BY%s(.+)%s"AS')
					local license_acknowledgements = "NOASSERTION"
					local license_promote = "NOASSERTION"
					if license_expression_spdx == "BSD-4-Clause" or license_expression_spdx == "BSD-4-Clause-UC" then
						license_acknowledgements =
							license_text_without_enter:match("display the following acknow.+%:%s(.+)%s4%.")
						license_promote = license_text_without_enter:match("4%.%sNeither the name of%s(.+)%smay be")
						if license_promote == nil then
							license_promote = license_text_without_enter:match("4%.%s(.+)%smay")
						end
						if license_acknowledgements == nil then
							license_acknowledgements = license_text_without_enter:match("3%.%s(.+)%s4%.")
						end
						print(license_expression_spdx .. "|" .. from_file .. ": " .. license_text_without_enter)
						print(
							from_file
								.. ": "
								.. license_expression_spdx
								.. " (acknowledgement: '"
								.. license_acknowledgements
								.. "' promote: '"
								.. license_promote
								.. "')"
						)
					end
					if license_expression_spdx == "BSD-3-Clause" then
						license_promote = license_text_without_enter:match("Neither the name of%s(.+)%smay be used to")
						if license_promote == nil then
							license_promote = license_text_without_enter:match("[34]%.%s(.+)%smay not")
						end
						if license_promote == nil then
							print(from_file .. ": " .. license_text_without_enter)
							license_promote = "NOASSERTION"
						end
						print(from_file .. ": " .. license_expression_spdx .. " (promote: '" .. license_promote .. "')")
					end
					if license_acknowledgements == "NOASSERTION" and license_promote == "NOASSERTION" then
						print(from_file .. ": " .. license_expression_spdx)
					end
					local license_text_without_enter = license_text_without_enter
						:gsub('PROVIDED BY%s.+%s"AS', 'PROVIDED BY <AUTHOR> "AS')
						:gsub("EVENT SHALL .+ BE LIABLE", "EVENT SHALL <AUTHOR> BE LIABLE")
						:gsub(
							"following acknowledgemen%a+:%s.+%s4%.",
							"following acknowledgements: <ACKNOWLEDGEMENTS> 4."
						)
						:gsub("%s%- Redistributions of source", " 1. Redistributions of source")
						:gsub("%s%- Redistributions in binary", " 2. Redistributions in binary")
						:gsub("%s%- Neither the name of", " 3. Neither the name of")
						:gsub("Neither the name of%s.+%smay be used to", "Neither the name of <PROMOTE> may be used to")

					-- Fix BSD-4-Clause style expression
					if license_expression_spdx == "BSD-3-Clause" then
						license_text_without_enter = license_text_without_enter:gsub(
							"3%.(.+)may not be used to",
							"3. Neither the name of <PROMOTE> may be used to"
						)
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
			if
				license_expression_spdx == "BSD-2-Clause"
				or license_expression_spdx == "LicenseRef-scancode-bsd-unchanged"
				or license_expression_spdx == "BSD-3-Clause"
				or license_expression_spdx == "BSD-4-Clause"
			then
				local rtn_string =
					scancode_compare_strings(license_texts[license_expression_spdx], cur_table["license_normalized"])
				if rtn_string ~= nil then
					if license_expression_spdx ~= "BSD-2-Clause" then
						print(
							from_file
								.. ": "
								.. license_expression_spdx
								.. " is not correct and here is diff: "
								.. rtn_string
						)
					else
						local bsd_source_diff = scancode_compare_strings(
							license_texts["BSD-Source-beginning-file"],
							cur_table["license_normalized"]
						)
						if bsd_source_diff ~= nil then
							print(
								from_file
									.. ": "
									.. license_expression_spdx
									.. " or BSD-Source-beginning-file is not correct and here is diff: "
									.. rtn_string
							)
						else
							cur_table["spdx_license_identifier_incorrect"] = true
							cur_table["spdx_license_identifier_corrected"] = "BSD-Source-beginning-file"
						end
					end
				end

				if spdx_header == false then
					cur_table["spdx_license_identifier"] = "License-Missing"
					cur_table["spdx_license_identifier_incorrect"] = true
				end
			end
		end
	end
end

io.write(yaml.dump({ license_table }))

io.close(output_handle)

os.exit(0)
