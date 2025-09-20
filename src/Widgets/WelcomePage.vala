/*
 * Copyright 2025 Fyra Labs
 *
 * This program is free software; you can redistribute it and/or
 * modify it under the terms of the GNU General Public
 * License as published by the Free Software Foundation; either
 * version 3 of the License, or (at your option) any later version.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
 * General Public License for more details.
 *
 * You should have received a copy of the GNU General Public License
 * along with this program. If not, see <http://www.gnu.org/licenses/>.
 */

public class Lumiere.WelcomePage : Gtk.Box {
    private string current_video;
    private He.Button replay_button;
    private Gtk.Image replay_button_image;
    private Gtk.Label replay_button_title;
    private Gtk.Label replay_button_description;
    public HeaderBar header_bar { get; private set; }

    construct {
        var placeholder = new Gtk.Box (Gtk.Orientation.VERTICAL, 24) {
            halign = Gtk.Align.CENTER,
            valign = Gtk.Align.CENTER,
            hexpand = true,
            vexpand = true
        };

        var title_label = new Gtk.Label (_("No Videos Open")) {
            halign = Gtk.Align.CENTER
        };
        title_label.add_css_class ("title-label");
        var description_label = new Gtk.Label (_("Select a source to begin playing.")) {
            halign = Gtk.Align.CENTER
        };
        description_label.add_css_class ("description-label");

        var open_button = new He.Button ("", _("Open file"));
        open_button.is_pill = true;
        replay_button = new He.Button ("", _("Replay last video"));
        replay_button.is_pill = true;
        var library_button = new He.Button ("", _("Browse Library"));
        library_button.is_pill = true;

        placeholder.append (title_label);
        placeholder.append (description_label);
        placeholder.append (open_button);
        placeholder.append (replay_button);
        placeholder.append (library_button);

        var box = new Gtk.Box (VERTICAL, 0);
        header_bar = new HeaderBar ();
        box.append (header_bar);
        box.append (placeholder);

        append (box);

        // Simple button setup
        replay_button_title = new Gtk.Label (_("Replay last video"));
        replay_button_image = new Gtk.Image.from_icon_name ("media-playlist-repeat");
        replay_button_description = new Gtk.Label ("");

        var library_manager = Lumiere.Services.LibraryManager.get_instance ();
        library_button.visible = library_manager.library_items.get_n_items () > 0;

        update_replay_button ();
        update_replay_title ();

        open_button.clicked.connect (() => {
            var window = (Lumiere.Window)get_root ();
            window.run_open_file ();
        });

        replay_button.clicked.connect (() => {
            var window = (Lumiere.Window)get_root ();
            Lumiere.PlaybackManager.get_default ().append_to_playlist ({ current_video });
            window.resume_last_videos ();
        });

        library_button.clicked.connect (() => {
            var window = (Lumiere.Window)get_root ();
            window.show_library ();
        });

        settings.changed["current-video"].connect (update_replay_button);

        settings.changed["last-stopped"].connect (update_replay_title);

        library_manager.library_items.items_changed.connect (() => {
            library_button.visible = library_manager.library_items.get_n_items () > 0;
        });
    }

    private void update_replay_button () {
        bool show_replay_button = false;

        current_video = settings.get_string ("current-video");
        if (current_video != "") {
            var last_file = File.new_for_uri (current_video);
            if (last_file.query_exists ()) {
                replay_button_description.label = Lumiere.get_title (last_file.get_basename ());

                show_replay_button = true;
            }
        }

        replay_button.visible = show_replay_button;
    }

    private void update_replay_title () {
        if (settings.get_int64 ("last-stopped") == 0) {
            replay_button_title.label = _("Replay last video");
            replay_button_image.set_from_icon_name ("media-playlist-repeat");
        } else {
            replay_button_title.label = _("Resume last video");
            replay_button_image.set_from_icon_name ("media-playback-start");
        }
    }

    public void set_navigation_stack (Gtk.Stack stack) {
        header_bar.stack = stack;
    }
}
