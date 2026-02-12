print("(Loaded) Ongleng by Kevin rimek by Nperma")

local Common = {
  ["AG"] = "Antigua and Barbuda",
  ["BT"] = "Bhutan",
  ["IT"] = "Italy",
  ["TV"] = "Tuvalu",
  ["AI"] = "Anguilla",
  ["AU"] = "Australia",
  ["BZ"] = "Belize",
  ["VU"] = "Vanuatu",
  ["BY"] = "Belarus",
  ["MU"] = "Mauritius",
  ["LA"] = "Laos",
  ["SN"] = "Senegal",
  ["TR"] = "Turkey",
  ["BO"] = "Bolivia",
  ["LK"] = "Sri Lanka",
  ["NF"] = "Norfolk Island",
  ["CN"] = "China",
  ["BQ"] = "Caribbean Netherlands",
  ["GG"] = "Guernsey",
  ["SD"] = "Sudan",
  ["YT"] = "Mayotte",
  ["BL"] = "Saint Barthélemy",
  ["VA"] = "Vatican City",
  ["TC"] = "Turks and Caicos Islands",
  ["CW"] = "Curaçao",
  ["BW"] = "Botswana",
  ["BJ"] = "Benin",
  ["LT"] = "Lithuania",
  ["MS"] = "Montserrat",
  ["VG"] = "British Virgin Islands",
  ["BI"] = "Burundi",
  ["UM"] = "United States Minor Outlying Islands",
  ["IE"] = "Ireland",
  ["SB"] = "Solomon Islands",
  ["BM"] = "Bermuda",
  ["FI"] = "Finland",
  ["PE"] = "Peru",
  ["BD"] = "Bangladesh",
  ["DK"] = "Denmark",
  ["VC"] = "Saint Vincent and the Grenadines",
  ["DO"] = "Dominican Republic",
  ["MD"] = "Moldova",
  ["BG"] = "Bulgaria",
  ["CR"] = "Costa Rica",
  ["NA"] = "Namibia",
  ["SJ"] = "Svalbard and Jan Mayen",
  ["LU"] = "Luxembourg",
  ["RU"] = "Russia",
  ["AE"] = "United Arab Emirates",
  ["SX"] = "Sint Maarten",
  ["BS"] = "Bahamas",
  ["JP"] = "Japan",
  ["NG"] = "Nigeria",
  ["GH"] = "Ghana",
  ["SL"] = "Sierra Leone",
  ["PM"] = "Saint Pierre and Miquelon",
  ["AL"] = "Albania",
  ["TK"] = "Tokelau",
  ["SH"] = "Saint Helena, Ascension and Tristan da Cunha",
  ["TO"] = "Tonga",
  ["TM"] = "Turkmenistan",
  ["DJ"] = "Djibouti",
  ["CF"] = "Central African Republic",
  ["LB"] = "Lebanon",
  ["LV"] = "Latvia",
  ["CC"] = "Cocos (Keeling) Islands",
  ["GM"] = "Gambia",
  ["HN"] = "Honduras",
  ["NU"] = "Niue",
  ["MR"] = "Mauritania",
  ["XK"] = "Kosovo",
  ["WF"] = "Wallis and Futuna",
  ["GS"] = "South Georgia",
  ["PF"] = "French Polynesia",
  ["TG"] = "Togo",
  ["BE"] = "Belgium",
  ["ZM"] = "Zambia",
  ["KY"] = "Cayman Islands",
  ["PN"] = "Pitcairn Islands",
  ["CK"] = "Cook Islands",
  ["MG"] = "Madagascar",
  ["ME"] = "Montenegro",
  ["KR"] = "South Korea",
  ["ET"] = "Ethiopia",
  ["MN"] = "Mongolia",
  ["SK"] = "Slovakia",
  ["CU"] = "Cuba",
  ["AQ"] = "Antarctica",
  ["GT"] = "Guatemala",
  ["GF"] = "French Guiana",
  ["NO"] = "Norway",
  ["GD"] = "Grenada",
  ["RE"] = "Réunion",
  ["CL"] = "Chile",
  ["CO"] = "Colombia",
  ["SA"] = "Saudi Arabia",
  ["IL"] = "Israel",
  ["DE"] = "Germany",
  ["NZ"] = "New Zealand",
  ["GL"] = "Greenland",
  ["KG"] = "Kyrgyzstan",
  ["SV"] = "El Salvador",
  ["FO"] = "Faroe Islands",
  ["PW"] = "Palau",
  ["MT"] = "Malta",
  ["SY"] = "Syria",
  ["TL"] = "Timor-Leste",
  ["HR"] = "Croatia",
  ["PG"] = "Papua New Guinea",
  ["NL"] = "Netherlands",
  ["LR"] = "Liberia",
  ["SO"] = "Somalia",
  ["VE"] = "Venezuela",
  ["HT"] = "Haiti",
  ["DZ"] = "Algeria",
  ["MP"] = "Northern Mariana Islands",
  ["MF"] = "Saint Martin",
  ["HM"] = "Heard Island and McDonald Islands",
  ["AW"] = "Aruba",
  ["EG"] = "Egypt",
  ["MW"] = "Malawi",
  ["GQ"] = "Equatorial Guinea",
  ["VI"] = "United States Virgin Islands",
  ["EC"] = "Ecuador",
  ["UZ"] = "Uzbekistan",
  ["GA"] = "Gabon",
  ["SS"] = "South Sudan",
  ["IR"] = "Iran",
  ["KZ"] = "Kazakhstan",
  ["NI"] = "Nicaragua",
  ["IS"] = "Iceland",
  ["SI"] = "Slovenia",
  ["GP"] = "Guadeloupe",
  ["CM"] = "Cameroon",
  ["AR"] = "Argentina",
  ["AZ"] = "Azerbaijan",
  ["UG"] = "Uganda",
  ["NE"] = "Niger",
  ["CX"] = "Christmas Island",
  ["MM"] = "Myanmar",
  ["PL"] = "Poland",
  ["JO"] = "Jordan",
  ["HK"] = "Hong Kong",
  ["CD"] = "DR Congo",
  ["ER"] = "Eritrea",
  ["KI"] = "Kiribati",
  ["MH"] = "Marshall Islands",
  ["BF"] = "Burkina Faso",
  ["ZW"] = "Zimbabwe",
  ["KE"] = "Kenya",
  ["KM"] = "Comoros",
  ["GI"] = "Gibraltar",
  ["BN"] = "Brunei",
  ["SE"] = "Sweden",
  ["LS"] = "Lesotho",
  ["IM"] = "Isle of Man",
  ["FM"] = "Micronesia",
  ["TZ"] = "Tanzania",
  ["CV"] = "Cape Verde",
  ["AF"] = "Afghanistan",
  ["AD"] = "Andorra",
  ["GR"] = "Greece",
  ["VN"] = "Vietnam",
  ["TF"] = "French Southern and Antarctic Lands",
  ["IQ"] = "Iraq",
  ["LY"] = "Libya",
  ["PT"] = "Portugal",
  ["PK"] = "Pakistan",
  ["MV"] = "Maldives",
  ["MA"] = "Morocco",
  ["BA"] = "Bosnia and Herzegovina",
  ["WS"] = "Samoa",
  ["PS"] = "Palestine",
  ["OM"] = "Oman",
  ["BH"] = "Bahrain",
  ["US"] = "United States",
  ["PR"] = "Puerto Rico",
  ["IO"] = "British Indian Ocean Territory",
  ["JE"] = "Jersey",
  ["MK"] = "North Macedonia",
  ["TN"] = "Tunisia",
  ["TT"] = "Trinidad and Tobago",
  ["EE"] = "Estonia",
  ["SG"] = "Singapore",
  ["PA"] = "Panama",
  ["CH"] = "Switzerland",
  ["UY"] = "Uruguay",
  ["TJ"] = "Tajikistan",
  ["TW"] = "Taiwan",
  ["ZA"] = "South Africa",
  ["LI"] = "Liechtenstein",
  ["BR"] = "Brazil",
  ["AM"] = "Armenia",
  ["GE"] = "Georgia",
  ["AX"] = "Åland Islands",
  ["QA"] = "Qatar",
  ["DM"] = "Dominica",
  ["UA"] = "Ukraine",
  ["GN"] = "Guinea",
  ["MO"] = "Macau",
  ["EH"] = "Western Sahara",
  ["CZ"] = "Czechia",
  ["AT"] = "Austria",
  ["KN"] = "Saint Kitts and Nevis",
  ["LC"] = "Saint Lucia",
  ["YE"] = "Yemen",
  ["RW"] = "Rwanda",
  ["MC"] = "Monaco",
  ["ST"] = "São Tomé and Príncipe",
  ["CG"] = "Republic of the Congo",
  ["PY"] = "Paraguay",
  ["BV"] = "Bouvet Island",
  ["MZ"] = "Mozambique",
  ["FR"] = "France",
  ["SZ"] = "Eswatini",
  ["BB"] = "Barbados",
  ["ES"] = "Spain",
  ["TH"] = "Thailand",
  ["GW"] = "Guinea-Bissau",
  ["AO"] = "Angola",
  ["IN"] = "India",
  ["MQ"] = "Martinique",
  ["NC"] = "New Caledonia",
  ["SC"] = "Seychelles",
  ["FK"] = "Falkland Islands",
  ["GB"] = "United Kingdom",
  ["FJ"] = "Fiji",
  ["SM"] = "San Marino",
  ["ML"] = "Mali",
  ["CA"] = "Canada",
  ["JM"] = "Jamaica",
  ["NR"] = "Nauru",
  ["ID"] = "Indonesia",
  ["GU"] = "Guam",
  ["CI"] = "Ivory Coast",
  ["KW"] = "Kuwait",
  ["PH"] = "Philippines",
  ["GY"] = "Guyana",
  ["HU"] = "Hungary",
  ["MX"] = "Mexico",
  ["KP"] = "North Korea",
  ["RO"] = "Romania",
  ["SR"] = "Suriname",
  ["AS"] = "American Samoa",
  ["NP"] = "Nepal",
  ["TD"] = "Chad",
  ["RS"] = "Serbia",
  ["KH"] = "Cambodia",
  ["MY"] = "Malaysia",
  ["CY"] = "Cyprus"
}

local statsCommands = {"online", "on"}
local serverStartTime = os.time()
local cache = {}

local function updateStatsCache()
    local onlinePlayers = getServerPlayers()
    local newCache = {
        onlineCount = #onlinePlayers,
        serverName = getServerName(),
        uptime = os.time() - serverStartTime,
        devices = { PC = 0, Android = 0, iOS = 0, Other = 0 },
        countries = {},
        worlds = {},
        playerListStr = ""
    }

    local playerList = {}
    local worldCounts = {}

    for _, p in ipairs(onlinePlayers) do
        local platform = tostring(p:getPlatform() or "")
        if platform == "0,1,1" or platform:match("^0,") then 
            newCache.devices.PC = newCache.devices.PC + 1
        elseif platform == "4" then 
            newCache.devices.Android = newCache.devices.Android + 1
        elseif platform == "1" then 
            newCache.devices.iOS = newCache.devices.iOS + 1
        else 
            newCache.devices.Other = newCache.devices.Other + 1 
        end

        local country = p:getCountry()
        if country and country ~= "" then
            local longName = Common[country:upper()] or nil
            if not newCache.countries[country] then newCache.countries[country] = {count=0} end
            local count = (newCache.countries[country].count or 0) + 1
            newCache.countries[country] = {name=(longName or country),count=count}
        end

        local worldName = p:getWorldName() or "EXIT"
        worldCounts[worldName] = (worldCounts[worldName] or 0) + 1
        
        table.insert(playerList, "`w" .. p:getName())
    end

    local sortedWorlds = {}
    for name, count in pairs(worldCounts) do
        table.insert(sortedWorlds, { name = name, count = count })
    end
    table.sort(sortedWorlds, function(a, b) return a.count > b.count end)

    newCache.worlds = sortedWorlds
    newCache.playerListStr = table.concat(playerList, ", ")
    cache = newCache
end

local function formatUptime(seconds)
    local hours = math.floor(seconds / 3600)
    local minutes = math.floor((seconds % 3600) / 60)
    return hours .. "h " .. minutes .. "m"
end

local function showServerStatsDialog(player)
    updateStatsCache()
    local dialog = "set_default_color|\n"
    dialog = dialog .. "set_bg_color|43,34,74,200|\n"
    dialog = dialog .. "set_border_color|112,86,191,255|\n"
    dialog = dialog .. "add_label_with_icon|big|`oServer Statistics|left|3802|\n"
    dialog = dialog .. "add_label_with_icon|medium|`oInfo|left|7190|\n"
    dialog = dialog .. "add_textbox|`oServer: `2" .. cache.serverName .. "|left|\n"
    dialog = dialog .. "add_textbox|`oOnline: `2" .. cache.onlineCount .. "`o/`43,000`o|\n"
    dialog = dialog .. "add_textbox|`o────────────────────────────|\n"
    dialog = dialog .. "add_label_with_icon|medium|`oPlayer Devices|left|572|\n"
    dialog = dialog .. "add_textbox|`oPC Users: `2" .. cache.devices.PC .. "|\n"
    dialog = dialog .. "add_textbox|`oiOS Users: `2" .. cache.devices.iOS .. "|\n"
    dialog = dialog .. "add_textbox|`oAndroid Users: `2" .. cache.devices.Android .. "|\n"
    dialog = dialog .. "add_textbox|`oUnknown Users: `2" .. cache.devices.Other .. "|\n"
    dialog = dialog .. "add_textbox|`o────────────────────────────|\n"
    local countryList = {}
    for country, data in pairs(cache.countries) do
        table.insert(countryList, string.format("add_custom_button|%s|image:%s;image_size:16,16;width:0.035;margin:2,0;|\nadd_textbox|%s|\nreset_placement_x|\nadd_custom_break|","flag",("interface/flags/"..country..".rttex"),"`o"..data.name.." - "..data.count.." Users Online"))
    end
    if #countryList > 0 then
        dialog = dialog .. "add_textbox|`oCountries: |\n"
        dialog = dialog .. table.concat(countryList,"\n") .. "\n"
        dialog = dialog .. "add_textbox|`o────────────────────────────|\n"
    end
    dialog = dialog .. "reset_placement_x|\nadd_textbox|`oPlayers Online: " .. cache.playerListStr .. "|\n"
    dialog = dialog .. "add_quick_exit|\n"
    dialog = dialog .. "end_dialog|ons_stats|||\n"
    player:onDialogRequest(dialog)
end

onPlayerCommandCallback(function(world, player, fullCommand)
    local command = fullCommand:match("^(%S+)")
    if command then
        for _, cmd in ipairs(statsCommands) do
            if command:lower() == cmd then
                showServerStatsDialog(player)
                return true
            end
        end
    end
    return false
end)

