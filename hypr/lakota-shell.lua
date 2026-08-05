-- Lakota Shell behavior integration.
-- Visual styling remains in generated/lakota-theme.lua.

hl.bind(
    "SUPER + SPACE",
    hl.dsp.exec_cmd("qs -c lakota-shell ipc call launcher toggle")
)
