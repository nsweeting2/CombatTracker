------------------------------------------------------------------------
--  Xaos CombatTracker written by Noax and Quid.                      --
--  Created January 2022                                              --
--                                                                    --
--  Updater code based on Jor'Mox's Generic Map Script,               --
--  I opted to check for updates only when a character is             --
--  connected or reconnected to the server to save on complexity.     --
--  I do this by handling a IAC AYT signal with sysTelnetEvent.       --
--                                                                    --
--  Requires the msdp protocol.                                       --
------------------------------------------------------------------------

--setup global table for msdp, the client will put things here automatically.
--keep in mind other packages will work with this table.
--table should always be created as seen below, so you don't overwrite.
msdp = msdp or {}

local profilePath = getMudletHomeDir() --setup profilePath so we can use in in functions below.
profilePath = profilePath:gsub("\\","/") --fix the path for windows folks

--setup global table for CombatTracker
ct = ct or {
    version = 1.0, --version we compare for updating
    downloading = false, --if we are downloading a update,
    downloadPath = "https://raw.githubusercontent.com/nsweeting2/Xaos-UI/main/CombatTracker/",
    folder = "/combattracker",
    file = "/CombatTracker.xml",
    updating = false, --if we are installing and update,
    rounds = 50, --number of rounds we want to record
    name = { --names for our regex{} keys, and other places
        "youHit", "youGotHit", "otherHit",
        "youDodge", "theyDodge", "otherDodge",
        "youParry", "theyParry", "otherParry",
        "youBlock", "theyBlock", "otherBlock",
        "youShield", "theyShield", "otherShield",
        "youPhase", "theyPhase", "otherPhase",
        "youAbsorb", "theyAbsorb", "otherAbsorb",
        "youKinetic", "theyKinetic", "otherKinetic",
        },
    exp = { --regex for our regex{} values
        [[^Your (?:pathetic|clumsy|fumbling|basic|lucky|shabby|average|competent|successful|skillful|well-aimed|effective|cunning|amazing|expert|deadly|vicious|wicked|brutal|powerful|incredible|masterful|monstrous|horrific|terrifying|savage|ungodly|MASSIVE|SADISTIC|-=GODLY=-) .+? (?:reflects off|misses|nicks|lightly skins|skins|lightly grazes|grazes|scratches|scrapes|hits|strikes|wounds|injures|mauls|scars|maims|mangles|destroys|decimates|guts|leaves GASHES|forever SCARS|DEMOLISHES|MASSACRES|DEVASTATES|does UNSPEAKABLE things to|SPLATTERS|-ANNIHILATES-|-=OBLITERATES=-|-=EVISCERATES=-|-=LAYS WASTE=- to|whiffs|biffs|lightly taps|taps|lightly touches|touches|feathers|strokes|contacts|jiggles|brushes up against|skimms|lightly rubs|nudges|prods|ravishes|pecks|smooches|fondles|leaves FEELINGS in|forever WOOS|lovingly FEEDS|gently AROUSES|lovingly CARESSES|does NAUGHTY things to|LEWDLY SPANKS|CREATES URGES within|GIVES JOY to|PROVIDES THE LOVE to|GIVES SWEET LOVIN' to) .+? \(\d+ dam\)$]],
        [[^.*? (?:pathetic|clumsy|fumbling|basic|lucky|shabby|average|competent|successful|skillful|well-aimed|effective|cunning|amazing|expert|deadly|vicious|wicked|brutal|powerful|incredible|masterful|monstrous|horrific|terrifying|savage|ungodly|MASSIVE|SADISTIC|-=GODLY=-) .+? (?:reflects off|misses|nicks|lightly skins|skins|lightly grazes|grazes|scratches|scrapes|hits|strikes|wounds|injures|mauls|scars|maims|mangles|destroys|decimates|guts|leaves GASHES|forever SCARS|DEMOLISHES|MASSACRES|DEVASTATES|does UNSPEAKABLE things to|SPLATTERS|-ANNIHILATES-|-=OBLITERATES=-|-=EVISCERATES=-|-=LAYS WASTE=- to|whiffs|biffs|lightly taps|taps|lightly touches|touches|feathers|strokes|contacts|jiggles|brushes up against|skimms|lightly rubs|nudges|prods|ravishes|pecks|smooches|fondles|leaves FEELINGS in|forever WOOS|lovingly FEEDS|gently AROUSES|lovingly CARESSES|does NAUGHTY things to|LEWDLY SPANKS|CREATES URGES within|GIVES JOY to|PROVIDES THE LOVE to|GIVES SWEET LOVIN' to) (?:in you|your) .+? \(\d+ dam\)$]],
        [[.*'s (?:pathetic|clumsy|fumbling|basic|lucky|shabby|average|competent|successful|skillful|well-aimed|effective|cunning|amazing|expert|deadly|vicious|wicked|brutal|powerful|incredible|masterful|monstrous|horrific|terrifying|savage|ungodly|MASSIVE|SADISTIC|-=GODLY=-) .+? (?:reflects off|misses|nicks|lightly skins|skins|lightly grazes|grazes|scratches|scrapes|hits|strikes|wounds|injures|mauls|scars|maims|mangles|destroys|decimates|guts|leaves GASHES|forever SCARS|DEMOLISHES|MASSACRES|DEVASTATES|does UNSPEAKABLE things to|SPLATTERS|-ANNIHILATES-|-=OBLITERATES=-|-=EVISCERATES=-|-=LAYS WASTE=- to|whiffs|biffs|lightly taps|taps|lightly touches|touches|feathers|strokes|contacts|jiggles|brushes up against|skimms|lightly rubs|nudges|prods|ravishes|pecks|smooches|fondles|leaves FEELINGS in|forever WOOS|lovingly FEEDS|gently AROUSES|lovingly CARESSES|does NAUGHTY things to|LEWDLY SPANKS|CREATES URGES within|GIVES JOY to|PROVIDES THE LOVE to|GIVES SWEET LOVIN' to) .+?.$]],
        [[^You (?:roll to avoid|easily avoid|side-step|dodge) .*\.$]],
        [[^.* (?:rolls to avoid|easily avoids|side-steps|dodges) your .*\.$]],
        [[^.* (?:rolls to avoid|easily avoids|side-steps|dodges) .*'s .*\.$]],
        [[^You(.*)parry (.*) with (.*)$]],
        [[^(.*) parries your (.*) with (.*)$]],
        [[^(.*) parries (.*)'s (.*) with (.)$]],
        [[^You block (.*)'s (.*)$]],
        [[^(.*) blocks your (.*)$]],
        [[NA]],
        [[^You block (.*)'s (.*) with (.*)!$]],
        [[^(.*) blocks your (.*) with (.*)$]],
        [[NA]],
        [[^You phase to avoid (.*)'s (.*)$]],
        [[^(.*) phases to avoid your (.*)$]],
        [[NA]],
        [[^Your (.*) absorb[\s] (.*)$]],
        [[^(.*) absorb your (.*)$]],
        [[^(.*)'s (.*) absorb[\s] (.*)'s (.*)$]],
        [[^(.*) intercepts (.*)'s attack!$]],
        [[^(.*) intercepts your attack!$]],
        [[NA]],
        },
    regex = {}, --table we will combine names{} and exp{} into
    tracker = {}, --table we will store all our recorded data in
    ar = {}, --table we store active round data in before tracker{}
    }

--formatting for our stylized echos
local ctTag = "<firebrick>[TRACKR]  - <reset>"

--echo function for style points
function ct.echo(text)

    cecho(ctTag .. text .. "\n")

end


--This function fires on the msdp.ROUNDS event by handle_ROUND
--msdp.ROUNDS increments every combat round, its value is truely unimportant
--Values from the server range from 0 to 2147483647 (c integer)
--The important point is that if msdp.ROUNDS changed, it is a new round
local function on_ROUNDS()

    --Add a table to tracker so we can copy in ct.ar
    ct.tracker[#ct.tracker + 1] = { }

    --add all our keys to the table, with values of 0
    for k, v in pairs(ct.name) do
        ct.ar[#ct.tracker] = 0
    end

    --copy ct.cr into ct.tracker at the new table
    for k, v in pairs(ct.ar) do
        ct.tracker[#ct.tracker][k] = v
    end

    --Set everything in ct.ar to 0
    for k, v in pairs(ct.name) do
        ct.ar[v] = 0
    end

    --remove 1st table from tracker so that our 51st becomes 50th
    while #ct.tracker > ct.rounds do
        table.remove(ct.tracker, 1)
    end

    --show everything in our miniconsole
    ct.trackerConsole:clear()
    ct.trackerConsole:echo("               |")
    for i = 1, #ct.tracker do
        if tonumber(i) < 10 then
            ct.trackerConsole:echo("  " .. tostring(i) .. "|")
        else
            ct.trackerConsole:echo(" " ..tostring(i) .. "|")
        end
    end
    ct.trackerConsole:echo("\n")
    for key, name in pairs(ct.name) do
        local len = 15 - string.len(name)
        while len > 0 do
          ct.trackerConsole:echo(" ")
          len = len - 1
        end
        ct.trackerConsole:echo(tostring(name))
        ct.trackerConsole:echo("|")
        for k, v in pairs(ct.tracker) do
            local len = 3 - string.len(tostring(ct.tracker[k][name]))
            while len > 0 do
                ct.trackerConsole:echo(" ")
                len = len -1
            end
            ct.trackerConsole:echo(tostring(ct.tracker[k][name]))
            ct.trackerConsole:echo("|")
        end
        ct.trackerConsole:echo("\n")
    end
    ct.trackerConsole:echo("Updated: " .. getTime(true, "hh:mm:ssap") .. "\n")

end

--will make us a miniconsole in an adjustable container
--by deafult our info is displayed here, Quid will make a graphical visulization
local function buildTrackerMiniConsole()

    --setup adjustable container
    ct.trackerAdjCon =  ct.trackerAdjCon or Adjustable.Container:new({
        name = "trackerAdjCon",
        adjLabelstyle = "background-color:rgba(220,220,220,100%); border: 5px groove grey;",
        buttonstyle = [[
            QLabel{ border-radius: 7px; background-color: rgba(140,140,140,100%);}
            QLabel::hover{ background-color: rgba(160,160,160,50%);}
            ]],
        buttonFontSize = 10,
        buttonsize = 20,
        titleText = "CombatTracker",
        titleTxtColor = "black",
        padding = 15,
        })

    --setup miniconsole inside the adjustable container
    ct.trackerConsole = ct.trackerConsole or Geyser.MiniConsole:new({
        name="trackerConsole",
        x = 0, y = 0,
        autoWrap = false,
        color = "black",
        scrollBar = true,
        fontSize = 8,
        width = "100%", height = "100%",
        },ct.trackerAdjCon)

    --hide the situation, user can show/hide with alais
    ct.trackerAdjCon:hide()

end

--will save needed values into config.lua
function ct.saveConfigs()

    local configs = {}
    local path = profilePath .. ct.folder

    --this is where we would save stuff
    table.save(path.."/configs.lua",configs)
    ct.saveTimer = tempTimer(60, [[ct.saveConfigs()]])

end

--will load needed values from config.lua
--will setup MSDP and check it
--will setup regex table for trackers matching
--will setup tracker and ar tables for trackers recording
local function config()

    local configs = {}
    local path = profilePath .. ct.folder

    --if our subdir doesn't exist make it
    if not io.exists(path) then
        lfs.mkdir(path)
    end

    --load stored configs from file if it exists
    if io.exists(path.."/configs.lua") then
        table.load(path.."/configs.lua",configs)
        --this is where we would load stuff
    end

    --configure the msdp we need for tracker
    sendMSDP("REPORT","ROUNDS")

    --verify our msdp was set as reported
    --commented off becasue server msdp takes too long to report
    --so this check alwasy fails
    --if not msdp.ROUNDS then
        --ct.echo("config() failed because it was unable to get MSDP to report.")
        --return
    --end

    --verify we have the right amount of data for regex table
    if #ct.name ~= #ct.exp then
        ct.echo("config() failed due to unmatched table sizes in regex{} dependants.")
        return
    end

    --combine ct.name and ct.exp into a new table ct.regex
    for k, v in pairs(ct.name) do
        ct.regex[v] = ct.exp[k]
    end

    --populate ct.tracker to contain the number of tables per rounds setting
    --populate each round with ct.names for keys and 0 for values
    for i = 1, tonumber(ct.rounds) do
        ct.tracker[i] = { }
        for k, v in pairs(ct.name) do
            ct.tracker[i][v] = 0
        end
    end

    --populate ct.ar with ct.names for keys and 0 for values, for our active round data
    for k, v in pairs(ct.name) do
        ct.ar[v] = 0
    end

    --setup our miniconsole for output
    buildTrackerMiniConsole()

    --call on_ROUNDS so that we prepopulate the miniconsole
    on_ROUNDS()

    --start the config save cycle
    ct.saveConfigs()

    --and we are done configuring CombatTracker
    ct.echo("CombatTracker has been configured.")

end

--will compare ct.version to highest version is version.lua
--versions.lua must be downloaded by ct.downloadVersions first
local function compareVersion()

    local path = profilePath .. ct.folder .. "/versions.lua"
    local versions = {}

    --load versions.lua into versions table
    table.load(path, versions)

    --set pos to the index of value of ct.version
    local pos = table.index_of(versions, ct.version) or 0

    --if pos isn't the top side of versions then we are out of date by the difference
    --enable the update alias and echo that we are out of date
    if pos ~= #versions then
        enableAlias("TrackerUpdate")
        ct.echo(string.format("Combat Tracker is currently %d versions behind.",#versions - pos))
        ct.echo("To update now, please type: tracker update")
    end

end

--will download the versions.lua file from the web
function ct.downloadVersions()

    if ct.downloadPath ~= "" then
        local path, file = profilePath .. ct.folder, "/versions.lua"
        ct.downloading = true
        downloadFile(path .. file, ct.downloadPath .. file)
    end

end

--will uninstall CombatTracker and reinstall CombatTracker
local function updatePackage()

    local path = profilePath .. ct.folder .. ct.file

    disableAlias("TrackerUpdate")
    ct.updating = true
    uninstallPackage("CombatTracker")
    installPackage(path)
    ct.updating = nil
    ct.echo("Combat Tracker Script updated successfully!")
    config()

end

--will download the CombatTracker.xml file from the web
function ct.downloadPackage()

    local path, file = profilePath .. ct.folder, ct.file
    ct.downloading = true
    downloadFile(path .. file, ct.downloadPath .. file)

end

--This function gets a line from the mud and runs it through ct.regex
--When it matches something we increment that location in ct.ar
function ct.lineHandler(line)

    for k, v in pairs(ct.regex) do
      if rex.find(tostring(line), v) then
        ct.ar[k] = ct.ar[k] + 1
        ct.echo("DEBUG: " .. tostring(k))
        break
      end
    end

end

--will show our output miniconosle
function ct.showMiniConsole()

    ct.trackerAdjCon:show()

end

--will hide our output miniconsole
function ct.hideMiniConsole()

    ct.trackerAdjCon:hide()

end

--handles out annonymus events
function ct.eventHandler(event, ...)

    --download done, if this package was downloading, check the file name and launch a function
    if event == "sysDownloadDone" and ct.downloading then
        local file = arg[1]
        if string.ends(file,"/versions.lua") then
            ct.downloading = false
            compareVersion()
        elseif string.ends(file,"/CombatTracker.xml") then
            ct.downloading = false
            updatePackage()
        end
    --download error, if this package was downloading, toss a error to screen
    elseif event == "sysDownloadError" and ct.downloading then
        local file = arg[1]
        if string.ends(file,"/versions.lua") then
            ct.echo("ct failed to download file versions.lua")
        elseif string.ends(file,"/CombatTracker.xml") then
            ct.echo("ct failed to download file CombatTracker.xml")
        end
    --package is being uninstalled, unregister our events
    elseif event == "sysUninstallPackage" and not ct.updating and arg[1] == "CombatTracker" then
        for _,id in ipairs(ct.annonEvents) do
            killAnonymousEventHandler(id)
        end

    --the server has been coded to send IAC AYT on connect and reconnect, use this to kick into config()
    elseif event == "sysTelnetEvent" then
        if tonumber(arg[1]) == 246 then --246 is AYT
            ct.downloading = false
            config()
            ct.downloadVersions()
        end
    end

end


ct.annonEvents = { --all of the annon events we will need  
    registerAnonymousEventHandler("sysDownloadDone", "ct.eventHandler"),
    registerAnonymousEventHandler("sysDownloadError", "ct.eventHandler"),
    registerAnonymousEventHandler("sysUninstallPackage", "ct.eventHandler"),
    registerAnonymousEventHandler("sysTelnetEvent", "ct.eventHandler"),
    }

ct.namedEvents = { --all of the named events we will need
    registerNamedEventHandler("noax","handle_ROUNDS","msdp.ROUNDS",on_ROUNDS),
    }