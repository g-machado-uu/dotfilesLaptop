//@ pragma UseQApplication

import Quickshell
import Quickshell.Io
import "StatusbarApp"
import "DesktopWidget"
import "CustomTheme"

ShellRoot {
    // Test IPC tools: qs ipc show

    IpcHandler {
        target: "theme-manager"
        function reload(): void {
            Theme.reloadTheme()
            // The widget picks its text colour from the wallpaper rather than
            // from the theme, so a theme reload is a good moment to look again.
            desktopWidget.sampleWallpaper()
        }
    }

    // Declared before the bar so the bar's surface is mapped last and therefore
    // stacked above it: the widget's sections then disappear *underneath* the
    // bar as they are sucked in, instead of sliding over the top of it.
    DesktopWidgetWindow {
        id: desktopWidget

        barHeight: bar.visible ? bar.reservedHeight : 0
        location: bar.settings.weather.location
        timeFormat: bar.settings.clock.format
        // A dropped panel would otherwise land on top of the widget.
        suppressed: bar.openPanel !== ""
    }

    StatusbarWindow {
        id: bar

        // The widget owns the clock while it is on screen.
        hideClock: desktopWidget.hideBarClock
    }
}
