/*
 * SPDX-License-Identifier: LGPL-3.0-or-later
 * SPDX-FileCopyrightText: 2025 Fyralabs
 */

public class Lumiere.HeaderBar : Gtk.Box {
    public bool fullscreened {
        set {
            if (value) {
                header_bar.decoration_layout = "close";
            } else {
                header_bar.decoration_layout = null;
            }

            unfullscreen_button.visible = value;
        }
    }

    public He.AppBar header_bar { get; construct; }
    public Gtk.Stack? stack { get; set; }

    private Gtk.Button unfullscreen_button;
    private unowned GLib.Binding binding;

    construct {
        unfullscreen_button = new He.Button ("view-restore-symbolic", "") {
            visible = false,
            tooltip_text = _("Unfullscreen")
        };

        header_bar = new He.AppBar () {
            show_left_title_buttons = true,
            show_right_title_buttons = true,
            hexpand = true
        };
        header_bar.append (unfullscreen_button);
        
        // Set the stack when it becomes available
        notify["stack"].connect (() => {
            if (stack != null) {
                header_bar.stack = stack;
            }
        });

        var spacer = new Gtk.Box (Gtk.Orientation.HORIZONTAL, 0);
        header_bar.viewtitle_widget = spacer;
        spacer.hexpand = true;

        append (header_bar);

        map.connect (() => {
            binding = ((Window) get_root ()).bind_property ("fullscreened", this, "fullscreened", SYNC_CREATE);
        });

        unmap.connect (() => binding.unbind ());

        unfullscreen_button.clicked.connect (() => ((Window) get_root ()).unfullscreen ());
    }

    public void update_navigation (string current_page) {
        switch (current_page) {
            case "welcome":
                header_bar.show_back = false;
                break;
            case "player":
                header_bar.show_back = true;
                break;
            default:
                header_bar.show_back = false;
                break;
        }
    }
}
