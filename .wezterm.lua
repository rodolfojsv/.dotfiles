local wezterm = require("wezterm")
local act = wezterm.action
local config = wezterm.config_builder()

-- ==========================================================================
-- Appearance
-- ==========================================================================
config.color_scheme = "Catppuccin Mocha"
config.font = wezterm.font("JetBrainsMono Nerd Font", { weight = "Regular" })
config.font_size = 12.5
config.line_height = 1.2
config.window_background_opacity = 0.85
config.window_padding = { left = 15, right = 15, top = 15, bottom = 15 }
config.window_decorations = "RESIZE"
config.hide_tab_bar_if_only_one_tab = true
config.use_fancy_tab_bar = false
config.default_cwd = "C:\\Dev\\NeoSMIB"

-- ==========================================================================
-- Scrollback
-- ==========================================================================
config.scrollback_lines = 100000

-- ==========================================================================
-- Leader key — Ctrl-a (same as your tmux prefix)
-- ==========================================================================
config.leader = { key = "a", mods = "CTRL", timeout_milliseconds = 1000 }

-- ==========================================================================
-- Keybindings
-- ==========================================================================
config.keys = {
	-- ======================================================================
	-- Pane management (splits)
	-- ======================================================================
	{ key = "|", mods = "LEADER|SHIFT", action = act.SplitHorizontal({ domain = "CurrentPaneDomain" }) },
	{ key = "-", mods = "LEADER", action = act.SplitVertical({ domain = "CurrentPaneDomain" }) },
	{ key = "x", mods = "LEADER", action = act.CloseCurrentPane({ confirm = true }) },
	{ key = "z", mods = "LEADER", action = act.TogglePaneZoomState },

	-- ======================================================================
	-- Vim-style pane navigation (like your tmux h/j/k/l)
	-- ======================================================================
	{ key = "h", mods = "LEADER", action = act.ActivatePaneDirection("Left") },
	{ key = "j", mods = "LEADER", action = act.ActivatePaneDirection("Down") },
	{ key = "k", mods = "LEADER", action = act.ActivatePaneDirection("Up") },
	{ key = "l", mods = "LEADER", action = act.ActivatePaneDirection("Right") },

	-- Resize panes with Leader + arrow keys
	{ key = "LeftArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Left", 5 }) },
	{ key = "DownArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Down", 5 }) },
	{ key = "UpArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Up", 5 }) },
	{ key = "RightArrow", mods = "LEADER", action = act.AdjustPaneSize({ "Right", 5 }) },

	-- ======================================================================
	-- Tab management (like tmux windows)
	-- ======================================================================
	{ key = "c", mods = "LEADER", action = act.SpawnTab("CurrentPaneDomain") },
	{ key = "n", mods = "LEADER", action = act.ActivateTabRelative(1) },
	{ key = "p", mods = "LEADER", action = act.ActivateTabRelative(-1) },
	{ key = "^", mods = "LEADER|SHIFT", action = act.ActivateLastTab },
	{ key = "1", mods = "LEADER", action = act.ActivateTab(0) },
	{ key = "2", mods = "LEADER", action = act.ActivateTab(1) },
	{ key = "3", mods = "LEADER", action = act.ActivateTab(2) },
	{ key = "4", mods = "LEADER", action = act.ActivateTab(3) },
	{ key = "5", mods = "LEADER", action = act.ActivateTab(4) },

	-- ======================================================================
	-- Workspace management (your tmux-sessionizer equivalent!)
	-- ======================================================================

	-- Sessionizer: scan C:\Dev for projects, fuzzy pick, switch workspace
	{ key = "f", mods = "LEADER", action = wezterm.action_callback(function(window, pane)
		local projects = {}
		local dev_dirs = { "C:\\Dev" }

		for _, dev_dir in ipairs(dev_dirs) do
			local success, entries = pcall(wezterm.read_dir, dev_dir)
			if success then
				for _, entry in ipairs(entries) do
					local attr = wezterm.glob(entry .. "\\*")
					if attr then
						table.insert(projects, { label = entry, id = entry })
					end
				end
			end
		end

		-- Also include any currently active workspaces
		for _, name in ipairs(wezterm.mux.get_workspace_names()) do
			local already = false
			for _, p in ipairs(projects) do
				if p.label:match("([^\\]+)$") == name then
					already = true
					break
				end
			end
			if not already then
				table.insert(projects, { label = "● " .. name .. " (active)", id = name })
			end
		end

		window:perform_action(act.InputSelector({
			title = "  Sessionizer",
			choices = projects,
			fuzzy = true,
			action = wezterm.action_callback(function(inner_window, inner_pane, id, label)
				if not id then return end
				local workspace_name = id:match("([^\\]+)$") or id
				inner_window:perform_action(act.SwitchToWorkspace({
					name = workspace_name,
					spawn = { cwd = id },
				}), inner_pane)
			end),
		}), pane)
	end) },

	-- Quick list of active workspaces only:  Leader + F
	{ key = "F", mods = "LEADER|SHIFT", action = act.ShowLauncherArgs({ flags = "FUZZY|WORKSPACES" }) },

	-- Quick-jump to project workspaces (like your tmux h/g/T/N bindings)
	{ key = "s", mods = "LEADER", action = act.SwitchToWorkspace({
		name = "NeoSMIB",
		spawn = { cwd = "C:\\Dev\\NeoSMIB" },
	}) },
	{ key = "d", mods = "LEADER", action = act.SwitchToWorkspace({
		name = "dotfiles",
		spawn = { cwd = "C:\\Dev\\dotfiles" },
	}) },

	-- Create a new workspace by name (ad-hoc sessions)
	{ key = "w", mods = "LEADER", action = act.PromptInputLine({
		description = wezterm.format({
			{ Foreground = { Color = "#89b4fa" } },
			{ Text = "Enter workspace name: " },
		}),
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				window:perform_action(act.SwitchToWorkspace({ name = line }), pane)
			end
		end),
	}) },

	-- ======================================================================
	-- Convenience
	-- ======================================================================
	{ key = "[", mods = "LEADER", action = act.ActivateCopyMode },
	{ key = "R", mods = "LEADER|SHIFT", action = act.ReloadConfiguration },
	{ key = ":", mods = "LEADER|SHIFT", action = act.ActivateCommandPalette },

	-- Clipboard
	{ key = "C", mods = "CTRL|SHIFT", action = act.CopyTo("Clipboard") },
	{ key = "V", mods = "CTRL|SHIFT", action = act.PasteFrom("Clipboard") },

	-- Rename current tab
	{ key = "r", mods = "LEADER", action = act.PromptInputLine({
		description = wezterm.format({
			{ Foreground = { Color = "#89b4fa" } },
			{ Text = "Enter new tab title: " },
		}),
		action = wezterm.action_callback(function(window, pane, line)
			if line then
				window:active_tab():set_title(line)
			end
		end),
	}) },
}

-- ==========================================================================
-- Status bar — show workspace name (like your catppuccin tmux status)
-- ==========================================================================
wezterm.on("update-status", function(window)
	local workspace = window:active_workspace()
	local left = wezterm.format({
		{ Foreground = { Color = "#89b4fa" } },
		{ Text = "  " .. workspace .. " " },
	})
	window:set_left_status(left)
end)

-- ==========================================================================
-- Tab title — show process name (like tmux window titles)
-- ==========================================================================
wezterm.on("format-tab-title", function(tab)
	local pane = tab.active_pane
	local title = tab.tab_title
	if not title or #title == 0 then
		title = pane.foreground_process_name:match("([^/\\]+)$") or "shell"
	end
	local index = tab.tab_index + 1
	if tab.is_active then
		return wezterm.format({
			{ Foreground = { Color = "#a6e3a1" } },
			{ Text = " " .. index .. ":" .. title .. " " },
		})
	end
	return " " .. index .. ":" .. title .. " "
end)

return config
