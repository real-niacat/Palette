Palette.mod = SMODS.current_mod
Palette.path = Palette.path or Palette.mod.path
Palette.load_palettes()
Palette.mod.config_tab = function()
    pal_nodes = {
	}
	left_settings = { n = G.UIT.C, config = { align = "tl", padding = 0.05 }, nodes = {} }
	right_settings = { n = G.UIT.C, config = { align = "tl", padding = 0.05 }, nodes = {} }
	config = { n = G.UIT.R, config = { align = "tm", padding = 0 }, nodes = { left_settings, right_settings } }
	pal_nodes[#pal_nodes + 1] = config
    pal_nodes[#pal_nodes + 1] = Palette.config_tab(5.5)
    return {
		n = G.UIT.ROOT,
		config = {
			emboss = 0.05,
			minh = 6,
			r = 0.1,
			align = "cm",
			padding = 0.2,
            colour = {0,0,0,0}
		},
		nodes = pal_nodes,
	}
end
	