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

public class Lumiere.LibraryItem : Gtk.Box {
    public enum Style {
        THUMBNAIL,
        ROW
    }

    public Style style { get; construct; }

    private Gtk.Label title_label;
    private Gtk.Picture poster;
    private Gtk.Stack spinner_stack;

    private Objects.MediaItem? item;

    public LibraryItem (Style style) {
        Object (
            style: style
        );
    }

    construct {
        add_css_class ("mini-content-block");

        var move_to_trash = new He.Button ("", _("Move to Trash")) {
            halign = START
        };
        move_to_trash.is_textual = true;

        var context_menu_box = new Gtk.Box (VERTICAL, 4);
        context_menu_box.set_homogeneous (true);
        context_menu_box.margin_top = 4;
        context_menu_box.margin_bottom = 4;
        context_menu_box.margin_start = 4;
        context_menu_box.margin_end = 4;
        context_menu_box.append (move_to_trash);

        var context_menu = new Gtk.Popover () {
            child = context_menu_box,
            halign = START,
            has_arrow = false,
            position = BOTTOM
        };
        context_menu.set_parent (this);

        title_label = new Gtk.Label ("");
        title_label.xalign = 0.0f;
        title_label.add_css_class ("cb-title");

        if (style == THUMBNAIL) {
            title_label.ellipsize = END;
            title_label.wrap = true;
            title_label.max_width_chars = 0;
            title_label.justify = CENTER;

            var new_cover = new He.Button ("", "Set Artwork") {
                tooltip_text = _("Set Artwork"),
                halign = START
            };
            new_cover.is_textual = true;
            
            context_menu_box.append (new_cover);

            poster = new Gtk.Picture () {
                content_fit = COVER,
                hexpand = true,
                vexpand = true
            };

            var spinner = new Gtk.Spinner () {
                spinning = true,
                hexpand = true,
                vexpand = true,
                halign = Gtk.Align.CENTER,
                valign = Gtk.Align.CENTER,
                height_request = 32,
                width_request = 32
            };

            spinner_stack = new Gtk.Stack () {
                height_request = Lumiere.Services.POSTER_HEIGHT,
                width_request = Lumiere.Services.POSTER_WIDTH,
                halign = CENTER,
                valign = CENTER,
                overflow = HIDDEN
            };
            spinner_stack.add_named (spinner, "spinner");
            spinner_stack.add_named (poster, "poster");

            append (spinner_stack);
            append (title_label);

            new_cover.clicked.connect (() => {
                context_menu.popdown ();
                set_new_cover.begin ();
            });
            map.connect (poster_visibility);
            poster.notify ["paintable"].connect (poster_visibility);
        } else {
            append (title_label);
            title_label.halign = START;
        }

        orientation = VERTICAL;
        spacing = 12;
        hexpand = true;
        vexpand = true;
        margin_top = 12;
        margin_bottom = 12;
        margin_start = 12;
        margin_end = 12;

        move_to_trash.clicked.connect (() => {
            context_menu.popdown ();
            item.trash ();
        });

        var gesture_click = new Gtk.GestureClick () {
            button = Gdk.BUTTON_SECONDARY
        };
        add_controller (gesture_click);
        gesture_click.released.connect ((n_press, x, y) => {
            context_menu.pointing_to = Gdk.Rectangle () {
                x = (int) x,
                y = (int) y
            };

            context_menu.popup ();
        });
    }

    public void bind (Objects.MediaItem item) {
        this.item = item;

        title_label.label = item.title;

        if (style == THUMBNAIL) {
            item.notify["poster"].connect (() => {
                poster.set_paintable ((Gdk.Paintable) item.poster);
            });

            poster.set_paintable ((Gdk.Paintable) item.poster);
        }
    }

    private void poster_visibility () {
        if (poster.paintable != null) {
            spinner_stack.visible_child_name = "poster";
        } else {
            spinner_stack.visible_child_name = "spinner";
        }
    }

    private async void set_new_cover () {
        var image_filter = new Gtk.FileFilter ();
        image_filter.set_filter_name (_("Image files"));
        image_filter.add_mime_type ("image/*");

        var filters = new ListStore (typeof (Gtk.FileFilter));
        filters.append (image_filter);

        var file_dialog = new Gtk.FileDialog () {
            title = _("Open"),
            accept_label = _("_Open"),
            filters = filters
        };

        try {
            var toplevel = get_root () as Gtk.Window;
            var cover = yield file_dialog.open (toplevel, null);

            yield item.set_custom_poster (cover);
        } catch (Error err) {
            warning ("Failed to select new cover: %s", err.message);
        }
    }
}
