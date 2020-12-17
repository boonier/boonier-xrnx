_AUTO_RELOAD_DEBUG = true
print("that works!!!")
--------------------------------------------------------------------------------
-- preferences
--------------------------------------------------------------------------------

-- tools can have preferences, just like Renoise. To use them we first need
-- to create a renoise.Document object which holds the options that we want to
-- store/restore

local options = renoise.Document.create("AutomationTypePreferences") {}

-- then we simply register this document as the main preferences for the tool:
renoise.tool().preferences = options

-- show_debug_prints is now a persistent option which gets saved & restored
-- for upcoming Renoise seesions, program launches.
-- the preferences file for tools is saved inside the tools bundle as
-- "preferences.xml"

-- for more complex documents, or if you prefere doing things the OO way, you can
-- also inherit from renoise.Document.DocumentNode and register properties there:
--
class "AutomationTypePreferences"(renoise.Document.DocumentNode)

function AutomationTypePreferences:__init()
  renoise.Document.DocumentNode.__init(self)

  -- register an observable property "show_debug_prints" which also will be
  -- loaded/saved with the document
  self:add_property("show_debug_prints", false)
end

local options = AutomationTypePreferences()
renoise.tool().preferences = options

-- which also allows you to create more complex documents.
-- please have a look at the Renoise.Tool.API.txt for more info and details
-- about documents and what else you can load/store this way...

------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "--- Track Automation List:Convert all Automation Type to POINTS",
  --selected = function() return options.show_debug_prints.value end,
  invoke = function()
    convert_automation_type("POINTS")
  end
}

renoise.tool():add_menu_entry {
  name = "Track Automation List:Convert all Automation Type to LINEAR",
  --selected = function() return options.show_debug_prints.value end,
  invoke = function()
    convert_automation_type("LINEAR")
  end
}

renoise.tool():add_menu_entry {
  name = "Track Automation List:Convert all Automation Type to CURVE",
  --selected = function() return options.show_debug_prints.value end,
  invoke = function()
    convert_automation_type("CURVE")
  end
}

renoise.tool():add_menu_entry {
  name = "--- Track Automation:Convert all Automation Type to POINTS",
  --selected = function() return options.show_debug_prints.value end,
  invoke = function()
    convert_automation_type("POINTS")
  end
}
renoise.tool():add_menu_entry {
  name = "Track Automation:Convert all Automation Type to LINEAR",
  --selected = function() return options.show_debug_prints.value end,
  invoke = function()
    convert_automation_type("LINEAR")
  end
}

renoise.tool():add_menu_entry {
  name = "Track Automation:Convert all Automation Type to CURVE",
  --selected = function() return options.show_debug_prints.value end,
  invoke = function()
    convert_automation_type("CURVE")
  end
}

function convert_automation_type(type)
  print(type)
  do
    local playmode
    local stub = renoise.PatternTrackAutomation

    if type == "POINTS" then
      playmode = renoise.PatternTrackAutomation.PLAYMODE_POINTS
    end
    if type == "LINEAR" then
      playmode = renoise.PatternTrackAutomation.PLAYMODE_LINES
    end
    if type == "CURVE" then
      playmode = renoise.PatternTrackAutomation.PLAYMODE_CURVES
    end

    local rns = renoise.song()
    local prm = rns.selected_automation_parameter

    if not prm then
      print("No parameter selected!")
      return
    end

    local trk_idx = rns.selected_track_index
    for seq_idx, patt_idx in ipairs(rns.sequencer.pattern_sequence) do
      local patt = rns.patterns[patt_idx]
      local ptrk = patt:track(trk_idx)
      local pauto = ptrk:find_automation(prm)
      if pauto then
        pauto.playmode = playmode
      end
    end
  end
end

--------------------------------------------------------------------------------
