-- Lakota VM display override. Loaded after the base Caelestia monitor rule.
hl.monitor({
    output = "Virtual-1",
    mode = "3840x2160@60",
    position = "0x0",
    scale = 1,
})

-- QEMU exposes a second absolute tablet alongside SPICE. At scaled output
-- resolutions it can duplicate the SPICE absolute pointer stream.
hl.device({
    name = "qemu-qemu-usb-tablet",
    enabled = false,
})

-- Keep compositor coordinates native for SPICE, and scale client UI instead.
hl.env("QT_SCALE_FACTOR", "2")
hl.env("GDK_SCALE", "2")
hl.env("XCURSOR_SIZE", "48")
