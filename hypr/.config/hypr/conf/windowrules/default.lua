-- Flameshot
hl.window_rule({
	name = "flameshot",
	match = { class = "*flameshot*" },
	float = true,
})

-- swaync draws its panel inside a screen-sized layer, so GTK CSS cannot animate
-- the card itself (GTK4 ignores `transform` on .control-center - verified). The
-- compositor does the work instead: `slide` drags the whole surface down from
-- the top edge, which reads as the panel dropping out of the bar. The overshoot
-- comes from the `fluidDrop` curve on layersIn (conf/animations/default.lua).
hl.layer_rule({
	name = "swaync-fluid",
	match = { namespace = "swaync-control-center" },
	animation = "slide",
})

-- ML4W Dotfiles Settings is a real toplevel (class org.quickshell), so it is
-- the compositor that animates it in. Match on the title to avoid catching
-- other Quickshell floating windows.
hl.window_rule({
	name = "ml4w-settings-fluid",
	match = { class = "org.quickshell", title = "ML4W Dotfiles Settings" },
	float = true,
	animation = "popin 40%",
})
