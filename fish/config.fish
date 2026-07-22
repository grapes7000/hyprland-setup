# Add these to your ~/.config/fish/config.fish

# Put ~/.local/bin (theme/wallgen/shortcuts) on PATH.
fish_add_path -g ~/.local/bin

# starship prompt (palette is themed by the `theme` command).
# Must come AFTER any distro fish config that sets its own prompt.
starship init fish | source
