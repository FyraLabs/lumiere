/*-
 * Copyright 2025 Fyra Labs
 *
 * This program is free software: you can redistribute it and/or modify
 * it under the terms of the GNU General Public License as published by
 * the Free Software Foundation, either version 3 of the License, or
 * (at your option) any later version.

 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU General Public License for more details.

 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 *
 */

public class Lumiere.Widgets.BottomBar : Gtk.Box {
    public bool should_stay_revealed {
        get {
            var play_pause_action = Application.get_default ().lookup_action (Lumiere.App.ACTION_PLAY_PAUSE);
            return hovered || playlist_popover.visible || settings_popover.visible ||
                !play_pause_action.get_state ().get_boolean ();
        }
    }

    private Lumiere.Widgets.PreviewPopover preview_popover;
    private double playback_duration;
    private PlaylistPopover playlist_popover;
    private SettingsPopover settings_popover;
    private bool hovered;

    construct {
        add_css_class ("mediacontrols");
    
        var play_button = new He.Button ("media-playback-start-symbolic", "") {
            action_name = App.ACTION_PREFIX + App.ACTION_PLAY_PAUSE,
            tooltip_text = _("Play"),
            is_iconic = true
        };

        playlist_popover = new PlaylistPopover ();

        var playlist_button = new Gtk.MenuButton () {
            icon_name = "view-list-symbolic",
            popover = playlist_popover,
            tooltip_text = _("Playlist"),
            direction = UP
        };
        // Get the button inside the Gtk.MenuButton and update its style classes
        playlist_button.realize.connect (() => {
            var btn = playlist_button.get_first_child () as Gtk.Button;
            if (btn != null) {
                btn.add_css_class ("iconic-button");
                btn.remove_css_class ("image-button");
            }
        });

        settings_popover = new SettingsPopover ();

        var settings_button = new Gtk.MenuButton () {
            icon_name = "open-menu-symbolic",
            popover = settings_popover,
            primary = true,
            tooltip_markup = ("%s\n<small>%s</small>").printf (
                _("Settings"),
                "F10"
            ),
            direction = UP
        };
        // Get the button inside the Gtk.MenuButton and update its style classes
        settings_button.realize.connect (() => {
            var btn = settings_button.get_first_child () as Gtk.Button;
            if (btn != null) {
                btn.add_css_class ("iconic-button");
                btn.remove_css_class ("image-button");
            }
        });

        var progression_label = new Gtk.Label (format_time (0));

        var duration_label = new Gtk.Label (null);

        var scale = new He.Slider () {
            hexpand = true,
            can_focus = false
        };

        preview_popover = new Lumiere.Widgets.PreviewPopover ();
        preview_popover.set_parent (scale);

        append (play_button);
        append (progression_label);
        append (scale);
        append (duration_label);
        append (settings_button);
        append (playlist_button);

        var motion_controller = new Gtk.EventControllerMotion ();
        add_controller (motion_controller);

        motion_controller.enter.connect (() => {
            hovered = true;
            notify_property ("should-stay-revealed");
        });

        motion_controller.leave.connect (() => {
            hovered = false;
            notify_property ("should-stay-revealed");
        });

        playlist_popover.notify["visible"].connect (() => notify_property ("should-stay-revealed"));
        settings_popover.notify["visible"].connect (() => notify_property ("should-stay-revealed"));

        GLib.Application.get_default ().action_state_changed.connect ((name, new_state) => {
            if (name == Lumiere.App.ACTION_PLAY_PAUSE) {
                if (new_state.get_boolean () == false) {
                    play_button.icon_name = "media-playback-start-symbolic";
                    play_button.tooltip_text = _("Play");
                } else {
                    play_button.icon_name = "media-playback-pause-symbolic";
                    play_button.tooltip_text = _("Pause");
                }
                notify_property ("should-stay-revealed");
            }
        });

        var playback_manager = Lumiere.PlaybackManager.get_default ();

        playback_manager.notify["position"].connect (() => {
            progression_label.label = format_time ((int)(playback_manager.position / 1000000000));
            scale.scale.set_value (playback_manager.position);
        });

        playback_manager.notify["duration"].connect (() => {
            playback_duration = playback_manager.duration;
            if (playback_duration < 0) {
                debug ("Duration value less than zero, duration set to 0.0");
                playback_duration = 0;
            }

            scale.set_range (0, playback_duration);
            duration_label.label = format_time ((int)(playback_duration / 1000000000));

            scale.scale.set_value (playback_manager.position);

            // Don't allow to change the time if there is none.
            sensitive = (playback_duration > 0);
            if (sensitive) {
                preview_popover.playback_uri = playback_manager.get_uri ();
            }
        });

        var scale_motion_controller = new Gtk.EventControllerMotion ();
        scale.add_controller (scale_motion_controller);

        scale_motion_controller.enter.connect (preview_popover.schedule_show);

        scale_motion_controller.leave.connect (preview_popover.schedule_hide);

        scale_motion_controller.motion.connect ((x, y) => {
            preview_popover.pointing_to = Gdk.Rectangle () {
                x = (int) x
            };

            preview_popover.set_preview_position (
                (int64)(x / (double) scale.get_width () * playback_duration),
                !playback_manager.playing
            );
        });

        scale.scale.change_value.connect ((scroll, new_value) => {
            playback_manager.seek ((int64)new_value);
            return true;
        });
    }

    public void hide_popovers () {
        playlist_popover.popdown ();
        preview_popover.schedule_hide ();
    }

    private string format_time (int seconds) {
        int hours = seconds / 3600;
        int minutes = (seconds % 3600) / 60;
        int secs = seconds % 60;

        if (hours > 0) {
            return "%d:%02d:%02d".printf (hours, minutes, secs);
        } else {
            return "%d:%02d".printf (minutes, secs);
        }
    }
}
