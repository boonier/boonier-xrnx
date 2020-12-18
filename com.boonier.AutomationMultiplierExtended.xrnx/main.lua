_AUTO_RELOAD_DEBUG = true
-- Placeholder for the dialog
--

local options =
  renoise.Document.create("AutomationMultiplierExtPreferences") {
  set_all_automation = false
}
renoise.tool().preferences = options

--[[============================================================================
main.lua
============================================================================]]
local rns = renoise.song()
local dialog = nil
-- Placeholder to expose the ViewBuilder outside the show_dialog() function
local vb = nil
local all_automation = false

-- Read from the manifest.xml file.
class "RenoiseScriptingTool"(renoise.Document.DocumentNode)
function RenoiseScriptingTool:__init()
  renoise.Document.DocumentNode.__init(self)
  self:add_property("Name", "Untitled Tool")
  self:add_property("Id", "Unknown Id")
end

local manifest = RenoiseScriptingTool()
local ok, err = manifest:load_from("manifest.xml")
local tool_name = manifest:property("Name").value
local tool_id = manifest:property("Id").value

print(tool_name .. " updated/loaded!")
--------------------------------------------------------------------------------
-- Main functions
--------------------------------------------------------------------------------

function process_points(automation, float_multiplier, float_offset)
  local new_points = {}

  local polarity = automation.dest_parameter.polarity

  for int_point, point in pairs(automation.points) do
    local float_newvalue = nil

    if polarity == renoise.DeviceParameter.POLARITY_BIPOLAR then
      print("valore iniziale: " .. point.value)
      float_newvalue = point.value - 0.5
      print("valore normalizzato: " .. float_newvalue)
      float_newvalue = float_newvalue * float_multiplier
      print("valore moltiplicato: " .. float_newvalue)
      float_newvalue = float_newvalue + 0.5
      print("valore finale: " .. float_newvalue)
    else
      renoise.app():show_status("unipolar")
      float_newvalue = point.value * float_multiplier
    end

    point.value = math.max(0.0, math.min(1.0, float_newvalue + float_offset))
    table.insert(new_points, point)
  end

  automation.points = new_points
end

--------------------------------------------------------------------------------
-- GUI
--------------------------------------------------------------------------------

local function show_dialog()
  -- This block makes sure a non-modal dialog is shown once.
  -- If the dialog is already opened, it will be focused.
  if dialog and dialog.visible then
    dialog:show()
    return
  end

  -- The ViewBuilder is the basis
  vb = renoise.ViewBuilder()
  local LABEL_WIDTH = 70
  -- The content of the dialog, built with the ViewBuilder.
  local content_1 =
    vb:row {
    vb:column {
      spacing = 10,
      vb:row {
        vb:text {
          width = LABEL_WIDTH,
          text = "Multiply by:"
        },
        vb:slider {
          id = "multiplier_slider",
          value = 1,
          min = 0,
          max = 2,
          notifier = function(v)
            vb.views.multiplier.value = v
          end,
          width = 150
        },
        vb:valuefield {
          id = "multiplier",
          value = 1,
          min = 0,
          max = 2,
          notifier = function(v)
            vb.views.multiplier_slider.value = v
          end
        }
      },
      vb:row {
        vb:text {
          width = LABEL_WIDTH,
          text = "Offset by:"
        },
        vb:slider {
          id = "offset_slider",
          value = 0,
          min = -1,
          max = 1,
          notifier = function(v)
            vb.views.offset.value = v
          end,
          width = 150
        },
        vb:valuefield {
          id = "offset",
          value = 0,
          min = -1,
          max = 1,
          notifier = function(v)
            vb.views.offset_slider.value = v
          end
        }
      }
    }
  }

  local content_2 =
    vb:row {
    vb:text {
      text = "All parameter automation in track:"
    },
    vb:checkbox {
      value = options.set_all_automation.value,
      notifier = function(value)
        options.set_all_automation.value = value
      end
    }
  }

  local button =
    vb:button {
    text = "GO!",
    notifier = function()
      local float_multiplier = vb.views.multiplier_slider.value
      local float_offset = vb.views.offset_slider.value
      local automation = nil
      local parameter = rns.selected_parameter

      if (parameter ~= nil) then
        if (options.set_all_automation.value) then
          local trk_idx = rns.selected_track_index

          for seq_idx, patt_idx in ipairs(rns.sequencer.pattern_sequence) do
            local patt = rns.patterns[patt_idx]
            local ptrk = patt:track(trk_idx)

            automation = ptrk:find_automation(parameter)

            if (automation ~= nil) then
              process_points(automation, float_multiplier, float_offset)
            end
          end
        else
          automation = rns.selected_pattern_track:find_automation(parameter)

          if (automation ~= nil) then
            process_points(automation, float_multiplier, float_offset)
          end
        end
      end
    end
  }

  local gui =
    vb:column {
    vb:row {
      margin = 10,
      content_1,
      button
    },
    vb:row {
      margin = 10,
      content_2
    }
    -- vb:row {
    --   margin = 10,
    --   content_3
    -- }
  }

  -- A custom dialog is non-modal and displays a user designed
  -- layout built with the ViewBuilder.
  dialog = renoise.app():show_custom_dialog(tool_name, gui)
end

--------------------------------------------------------------------------------
-- Menu entries
--------------------------------------------------------------------------------

renoise.tool():add_menu_entry {
  name = "Track Automation:Process:" .. tool_name .. "...",
  invoke = show_dialog
}

renoise.tool():add_menu_entry {
  name = "Track Automation List:" .. tool_name .. "...",
  --selected = function() return options.show_debug_prints.value end,
  invoke = show_dialog
}

renoise.tool():add_menu_entry {
  name = "Track Automation:" .. tool_name .. "...",
  --selected = function() return options.show_debug_prints.value end,
  invoke = show_dialog
}

--------------------------------------------------------------------------------
-- Key Binding
--------------------------------------------------------------------------------

renoise.tool():add_keybinding {
  name = "Automation:Tools:" .. tool_name .. "...",
  invoke = show_dialog
}

--------------------------------------------------------------------------------
-- MIDI Mapping
--------------------------------------------------------------------------------

--[[
renoise.tool():add_midi_mapping {
  name = tool_id..":Show Dialog...",
  invoke = show_dialog
}
--]]
