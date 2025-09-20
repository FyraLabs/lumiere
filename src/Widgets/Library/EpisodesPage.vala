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

public class Lumiere.EpisodesPage : Gtk.Box {
    private Gtk.Picture poster;
    private Gtk.FilterListModel filter_model;
    private Gtk.SearchEntry search_entry;
    private Gtk.ListView view_episodes;
    private Gtk.Box alert_view;
    public HeaderBar header_bar { get; private set; }

    construct {
        search_entry = new Gtk.SearchEntry () {
            placeholder_text = _("Search Videos"),
            valign = CENTER
        };
        search_entry.remove_css_class ("disclosure-button");
        search_entry.add_css_class ("text-field");

        var autoqueue_next = new Gtk.Switch () {
            valign = Gtk.Align.CENTER
        };
        autoqueue_next.remove_css_class ("disclosure-button");
        settings.bind ("autoqueue-next", autoqueue_next, "active", SettingsBindFlags.DEFAULT);

        header_bar = new HeaderBar ();
        header_bar.header_bar.append (search_entry);
        header_bar.header_bar.append (autoqueue_next);

        poster = new Gtk.Picture () {
            height_request = Lumiere.Services.POSTER_HEIGHT,
            width_request = Lumiere.Services.POSTER_WIDTH,
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 0,
            valign = Gtk.Align.START
        };

        filter_model = new Gtk.FilterListModel (null, new Gtk.CustomFilter (episodes_filter_func));
        var selection_model = new Gtk.NoSelection (filter_model);

        var factory = new Gtk.SignalListItemFactory ();

        view_episodes = new Gtk.ListView (selection_model, factory) {
            margin_top = 24,
            margin_bottom = 24,
            margin_start = 24,
            margin_end = 24,
            single_click_activate = true,
            valign = Gtk.Align.START
        };

        var scrolled_window = new Gtk.ScrolledWindow () {
            hexpand = true,
            vexpand = true,
            child = view_episodes
        };

        alert_view = new Gtk.Box (Gtk.Orientation.VERTICAL, 12) {
            visible = false,
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER
        };
        var alert_icon = new Gtk.Image.from_icon_name ("edit-find-symbolic");
        var alert_title = new Gtk.Label ("");
        var alert_description = new Gtk.Label (_("Try changing search terms."));
        alert_view.append (alert_icon);
        alert_view.append (alert_title);
        alert_view.append (alert_description);

        var grid = new Gtk.Grid () {
            hexpand = true,
            vexpand = true
        };
        grid.attach (poster, 0, 1);
        grid.attach (scrolled_window, 1, 1);
        grid.attach (alert_view, 1, 1);

        var box = new Gtk.Box (VERTICAL, 0);
        box.append (header_bar);
        box.append (grid);

        append (box);

        factory.setup.connect ((obj) => {
            var item = (Gtk.ListItem) obj;
            item.child = new LibraryItem (ROW);
        });

        factory.bind.connect ((obj) => {
            var item = (Gtk.ListItem) obj;
            ((LibraryItem) item.child).bind ((Objects.MediaItem) item.item);
        });

        view_episodes.activate.connect (play_video);

        search_entry.search_changed.connect (filter);

        var search_entry_key_controller = new Gtk.EventControllerKey ();
        search_entry.add_controller (search_entry_key_controller);
        search_entry_key_controller.key_pressed.connect ((keyval) => {
            if (keyval == Gdk.Key.Escape) {
                search_entry.text = "";
                return true;
            }
            return false;
        });
    }

    public void search () {
        search_entry.grab_focus ();
    }

    public void set_show (Objects.MediaItem item) {
        filter_model.model = item.children;
        poster.set_paintable ((Gdk.Paintable) item.poster);
    }

    private void play_video (uint position) {
        var video = (Objects.MediaItem) filter_model.get_item (position);

        string[] videos = { video.uri };

        if (settings.get_boolean ("autoqueue-next")) {
            // Add next from the current view to the queue
            for (position++; position < filter_model.get_n_items (); position++) {
                videos += ((Objects.MediaItem) filter_model.get_item (position)).uri;
            }
        }

        var playback_manager = PlaybackManager.get_default ();
        playback_manager.clear_playlist ();
        playback_manager.append_to_playlist (videos);

        bool from_beginning = video.uri != settings.get_string ("current-video");

        var window = App.get_instance ().mainwindow;
        window.play_file (video.uri, Window.NavigationPage.EPISODES, from_beginning);
    }

    private void filter () {
        filter_model.model.items_changed (0, filter_model.model.get_n_items (), filter_model.model.get_n_items ());
        if (filter_model.get_n_items () == 0) {
            var alert_title = (Gtk.Label) alert_view.get_first_child ().get_next_sibling ();
            alert_title.label = _("No Results for \"%s\"").printf (search_entry.text);
            alert_view.visible = true;
        } else {
            alert_view.visible = false;
        }
    }

    private bool episodes_filter_func (Object obj) {
        if (search_entry.text.length == 0) {
            return true;
        }

        string[] filter_elements = search_entry.text.split (" ");
        var video_title = ((Objects.MediaItem) obj).title;

        foreach (string filter_element in filter_elements) {
            if (!video_title.down ().contains (filter_element.down ())) {
                return false;
            }
        }
        return true;
    }

    public void set_navigation_stack (Gtk.Stack stack) {
        header_bar.stack = stack;
    }
}
