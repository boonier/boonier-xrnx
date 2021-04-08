_AUTO_RELOAD_DEBUG = true

if os.platform() == "MACINTOSH" then
  SOX_PATH = "/usr/local/bin/sox"
  SOXI_PATH = "/usr/local/bin/soxi"
end

renoise.tool():add_menu_entry {
  name = "Main Menu:Tools:Multi-channel File to Instruments",
  invoke = function()
    pretty_hello_world()
  end
}

--------------------------------------------------------------------------------
-- Helper Function
--------------------------------------------------------------------------------

local function show_status(message)
  renoise.app():show_status(message)
  print(message)
end

--------------------------------------------------------------------------------
local vb = renoise.ViewBuilder()
local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN
local CONTENT_SPACING = renoise.ViewBuilder.DEFAULT_CONTROL_SPACING

local channels_info_text =
  vb:text {
  text = ""
}
local dialog_content = {}
local inputs_container = nil
function pretty_hello_world()
  -- Beside of texts, controls and backgrounds and so on, the viewbuilder also
  -- offers some helper views which will help you to 'align' and stack views.

  -- lets start by creating a view builder again:
  -- local vb = renoise.ViewBuilder()
  local dialog_title = "Multichannel Audio to Instruments"

  -- get some consts to let the dialog look like Renoises default views...
  -- local DEFAULT_MARGIN = renoise.ViewBuilder.DEFAULT_CONTROL_MARGIN

  local path_textfield =
    vb:textfield {
    width = 500,
    text = "",
    visible = false,
    notifier = function()
    end
  }

  dialog_content =
    vb:column {
    margin = DEFAULT_MARGIN,
    height = "100%",
    vb:column {
      margin = DEFAULT_MARGIN,
      spacing = CONTENT_SPACING,
      vb:text {
        text = "First select some multi-channel audio (wav, aiff)",
        font = "bold"
      },
      vb:button {
        text = "Select audio file",
        width = 60,
        notifier = function()
          local file_path = renoise.app():prompt_for_filename_to_read({"wav", "aiff"}, dialog_title)
          local num_chans = os.tmpname("txt")
          local file_info = os.tmpname("txt")
          --
          path_textfield.text = file_path
          -- get number of channels
          os.execute(SOX_PATH .. " --i -c '" .. file_path .. "' > " .. num_chans)
          -- get header data
          os.execute(SOXI_PATH .. " '" .. file_path .. "' > " .. file_info)
          update_ui(file_info, num_chans, file_path)
          --
          -- local input = file
          -- local output = "~/output_1_test.wav"
          -- os.execute(SOX_PATH .. " '" .. input .. "' " .. output .. " remix 1")
        end
      },
      path_textfield,
      vb:column {
        margin = DEFAULT_MARGIN,
        style = "group",
        channels_info_text
      }
    }
  }

  renoise.app():show_custom_dialog(dialog_title, dialog_content)
end

function update_ui(file_info, num_chans, file_path)
  local header = io.open(file_info, "r")
  local file = io.open(num_chans, "r")
  local nchans = nil

  -- local header_data = {}
  channels_info_text.text = ""
  local hdr_arr = {}
  for line in header:lines() do
    if string.len(line) > 0 then
      channels_info_text.text = channels_info_text.text .. line .. "\n"
      table.insert(hdr_arr, line)
    end
  end

  -- rprint(hdr_arr)

  -- extract number of channels
  for line in file:lines() do
    nchans = line
  end

  if inputs_container then
    print("inputs_container not empty remove it")
    dialog_content:remove_child(inputs_container)
    inputs_container = nil
  end

  inputs_container =
    vb:column {
    spacing = CONTENT_SPACING,
    margin = DEFAULT_MARGIN
  }

  local file_name = file_path:match("[^/]+$"):gsub(".wav", "")
  local file_name_extension = file_path:match("[^.]+$")

  -- print(file_name)
  -- print(file_name_extension)
  --

  --[[ 
    create a array of tables to hold data for each channel so:
    {
      id = number,
      active= boolean,
      file_name = string,
      link = boolean,
    }
  ]]
  local channels = {}
  for i = 1, nchans, 1 do
    local bool = {true, false}
    local tb =
      vb:textfield {
      text = file_name .. "[" .. i .. "]." .. file_name_extension,
      width = 300,
      active = bool[math.random(1, 2)]
    }
    table.insert(channels, tb)
    inputs_container:add_child(tb)
  end
  rprint(channels)

  local links_container =
    vb:column {
    spacing = CONTENT_SPACING,
    margin = DEFAULT_MARGIN,
    vb:column {
      height = 7
    }
  }
  for i = 1, table.count(channels) - 1, 1 do
    local cb =
      vb:checkbox {
      value = false
    }
    links_container:add_child(cb)
  end

  local bits =
    vb:column {
    vb:column {
      vb:text {
        text = "Choose channels to import",
        font = "bold"
      }
    },
    vb:row {
      inputs_container,
      links_container
    }
  }

  -- meat_container:add_child(meat_label)
  -- meat_container:add_child(bits)

  dialog_content:add_child(bits)
end
