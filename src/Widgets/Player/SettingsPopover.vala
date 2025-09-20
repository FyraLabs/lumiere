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

public class Lumiere.Widgets.SettingsPopover : Gtk.Popover {
    public bool is_setup = false;

    private Gtk.DropDown languages;
    private Gtk.DropDown subtitles;
    private Gtk.Label external_subtitle_file_label;

    construct {
        has_arrow = false;
        languages = new Gtk.DropDown (null, null);
        subtitles = new Gtk.DropDown (null, null);

        external_subtitle_file_label = new Gtk.Label ("");

        var external_subtitle_file_image = new Gtk.Image.from_icon_name ("folder-symbolic");

        var external_subtitle_file_box = new Gtk.Box (HORIZONTAL, 3);
        external_subtitle_file_box.set_homogeneous (true);
        external_subtitle_file_box.append (external_subtitle_file_label);
        external_subtitle_file_box.append (external_subtitle_file_image);

        var external_subtitle_file = new Gtk.Button () {
            child = external_subtitle_file_box
        };

        var lang_label = new Gtk.Label (_("Audio")) {
            xalign = 0.0f
        };
        lang_label.add_css_class ("cb-subtitle");

        var sub_label = new Gtk.Label (_("Subtitles")) {
            xalign = 0.0f
        };
        sub_label.add_css_class ("cb-subtitle");

        var sub_ext_label = new Gtk.Label (_("External Subtitles")) {
            xalign = 0.0f
        };
        sub_ext_label.add_css_class ("cb-subtitle");

        var setupgrid = new Gtk.Grid () {
            column_spacing = 12,
            row_spacing = 6,
            margin_top = 6,
            margin_bottom = 6,
            margin_start = 6,
            margin_end = 6
        };
        setupgrid.attach (lang_label, 0, 1);
        setupgrid.attach (languages, 1, 1);
        setupgrid.attach (sub_label, 0, 2);
        setupgrid.attach (subtitles, 1, 2);
        setupgrid.attach (sub_ext_label, 0, 3);
        setupgrid.attach (external_subtitle_file, 1, 3);

        position = TOP;
        child = setupgrid;

        set_external_subtitel_label ();

        var playback_manager = Lumiere.PlaybackManager.get_default ();
        playback_manager.next_audio.connect (next_audio);
        playback_manager.next_text.connect (next_text);

        external_subtitle_file.clicked.connect (get_external_subtitle_file);

        playback_manager.notify["subtitle-uri"].connect (set_external_subtitel_label);

        playback_manager.uri_changed.connect (() => {
            is_setup = false;
        });

        subtitles.notify["selected-item"].connect (on_subtitles_changed);

        languages.notify["selected-item"].connect (on_languages_changed);

        map.connect (() => {
            setup ();
        });
    }

    private void set_external_subtitel_label () {
        var playback_manager = Lumiere.PlaybackManager.get_default ();
        if (playback_manager.subtitle_uri != "") {
            var file = File.new_for_uri (playback_manager.subtitle_uri);
            external_subtitle_file_label.label = file.get_basename ();
        } else {
            external_subtitle_file_label.label = _("None");
        }
    }

    private async void get_external_subtitle_file () {
        popdown ();

        var all_files_filter = new Gtk.FileFilter ();
        all_files_filter.set_filter_name (_("All files"));
        all_files_filter.add_pattern ("*");

        var subtitle_files_filter = new Gtk.FileFilter ();
        subtitle_files_filter.set_filter_name (_("Subtitle files"));
        subtitle_files_filter.add_mime_type ("application/smil"); // .smi
        subtitle_files_filter.add_mime_type ("application/x-subrip"); // .srt
        subtitle_files_filter.add_mime_type ("text/x-microdvd"); // .sub
        subtitle_files_filter.add_mime_type ("text/x-ssa"); // .ssa & .ass
        // exclude .asc, mimetype is generic "application/pgp-encrypted"

        var filters = new ListStore (typeof (Gtk.FileFilter));
        filters.append (subtitle_files_filter);
        filters.append (all_files_filter);

        var file_dialog = new Gtk.FileDialog () {
            title = _("Open"),
            accept_label = _("_Open"),
            filters = filters
        };

        try {
            var subtitle_file = yield file_dialog.open ((Gtk.Window)get_root (), null);

            Lumiere.PlaybackManager.get_default ().set_subtitle (subtitle_file.get_uri ());
        } catch (Error err) {
            warning ("Failed to select subtitle file: %s", err.message);
        }
    }

    private void setup () {
        if (!is_setup) {
            is_setup = true;
            setup_text ();
            setup_audio ();
        }
    }

    private void on_subtitles_changed () {
        if (subtitles.selected == Gtk.INVALID_LIST_POSITION) {
            return;
        }

        var string_list = (Gtk.StringList) subtitles.model;
        var selected_text = string_list.get_string (subtitles.selected);
        
        if (selected_text == _("None")) {
            Lumiere.PlaybackManager.get_default ().set_subtitle_track (-1);
        } else {
            Lumiere.PlaybackManager.get_default ().set_subtitle_track ((int) subtitles.selected);
        }
    }

    private void on_languages_changed () {
        if (languages.selected == Gtk.INVALID_LIST_POSITION) {
            return;
        }

        Lumiere.PlaybackManager.get_default ().set_audio_track ((int) languages.selected);
    }

    private void setup_text () {
        subtitles.notify["selected-item"].disconnect (on_subtitles_changed);

        var playback_manager = Lumiere.PlaybackManager.get_default ();
        var string_list = new Gtk.StringList (null);

        uint track = 1;
        playback_manager.get_subtitle_tracks ().foreach ((lang) => {
            // FIXME: Using Track since lang is actually a bad pointer :/
            string_list.append (_("Track %u").printf (track++));
        });
        string_list.append (_("None"));

        subtitles.model = string_list;
        subtitles.sensitive = string_list.get_n_items () > 1;
        if (subtitles.sensitive && (playback_manager.get_subtitle_track () >= 0)) {
            subtitles.selected = playback_manager.get_subtitle_track ();
        } else {
            subtitles.selected = string_list.get_n_items () - 1;
        }

        subtitles.notify["selected-item"].connect (on_subtitles_changed);
    }

    private void setup_audio () {
        languages.notify["selected-item"].disconnect (on_languages_changed);

        var playback_manager = Lumiere.PlaybackManager.get_default ();
        var string_list = new Gtk.StringList (null);

        uint track = 1;
        playback_manager.get_audio_tracks ().foreach ((language_code) => {
            var audio_stream_lang = Gst.Tag.get_language_name (language_code);
            if (audio_stream_lang != null) {
                string_list.append (audio_stream_lang);
            } else {
                string_list.append (_("Track %u").printf (track));
            }
            track++;
        });

        languages.model = string_list;
        languages.sensitive = string_list.get_n_items () > 1;
        if (languages.sensitive) {
            languages.selected = playback_manager.get_audio_track ();
        } else {
            string_list = new Gtk.StringList (null);
            string_list.append (_("Default"));
            languages.model = string_list;
            languages.selected = 0;
        }

        languages.notify["selected-item"].connect (on_languages_changed);
    }

    private void next_audio () {
        setup ();
        var string_list = (Gtk.StringList) languages.model;
        if (string_list.get_n_items () > 0) {
            languages.selected = (languages.selected + 1) % (int) string_list.get_n_items ();
        }
    }

    private void next_text () {
        setup ();
        var string_list = (Gtk.StringList) subtitles.model;
        if (string_list.get_n_items () > 0) {
            subtitles.selected = (subtitles.selected + 1) % (int) string_list.get_n_items ();
        }
    }
}
