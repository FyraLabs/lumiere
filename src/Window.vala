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

public class Lumiere.Window : He.ApplicationWindow {
    public Gtk.Stack navigation_stack;
    private Gtk.Revealer app_notification;
    private PlayerPage player_page;
    private WelcomePage welcome_page;

    public enum NavigationPage { WELCOME }

    public signal void media_volumes_changed ();

    public const string ACTION_GROUP_PREFIX = "win";
    public const string ACTION_PREFIX = ACTION_GROUP_PREFIX + ".";
    public const string ACTION_BACK = "back";
    public const string ACTION_FULLSCREEN = "action-fullscreen";
    public const string ACTION_OPEN_FILE = "action-open-file";
    public const string ACTION_QUIT = "action-quit";
    public const string ACTION_SEARCH = "action-search";
    public const string ACTION_UNDO = "action-undo";

    private static Gee.MultiMap<string, string> action_accelerators = new Gee.HashMultiMap<string, string> ();

    private const ActionEntry[] ACTION_ENTRIES = {
        { ACTION_BACK, action_back },
        { ACTION_FULLSCREEN, action_fullscreen },
        { ACTION_OPEN_FILE, action_open_file },
        { ACTION_QUIT, action_quit },
        { ACTION_SEARCH, action_search },
        { ACTION_UNDO, action_undo }
    };

    static construct {
        action_accelerators[ACTION_FULLSCREEN] = "F";
        action_accelerators[ACTION_FULLSCREEN] = "F11";
        action_accelerators[ACTION_OPEN_FILE] = "<Control>O";
        action_accelerators[ACTION_QUIT] = "<Control>Q";
        action_accelerators[ACTION_SEARCH] = "<Control>F";
        action_accelerators[ACTION_UNDO] = "<Control>Z";
    }

    public Window (He.Application application) {
        Object (application: application);
    }

    construct {
        add_action_entries (ACTION_ENTRIES, this);

        var application_instance = (Gtk.Application) GLib.Application.get_default ();
        foreach (var action in action_accelerators.get_keys ()) {
            application_instance.set_accels_for_action (
                ACTION_PREFIX + action, action_accelerators[action].to_array ()
            );
        }

        set_default_size (1000, 680);

        welcome_page = new WelcomePage ();

        player_page = new PlayerPage ();


        navigation_stack = new Gtk.Stack ();
        navigation_stack.add_named (welcome_page, "welcome");
        navigation_stack.add_named (player_page, "player");

        // Set the navigation stack for all pages
        welcome_page.set_navigation_stack (navigation_stack);
        player_page.set_navigation_stack (navigation_stack);

        app_notification = new Gtk.Revealer () {
            child = new Gtk.Label (""),
            reveal_child = false,
            valign = Gtk.Align.END,
            halign = Gtk.Align.CENTER
        };

        var overlay = new Gtk.Overlay () {
            child = navigation_stack
        };
        overlay.add_overlay (app_notification);

        titlebar = new Gtk.Grid () {
            visible = false
        };
        child = overlay;
        present ();


        navigation_stack.notify["visible-child-name"].connect (() => {
            update_navigation ();
        });

        // Set initial navigation state
        update_navigation ();

        var playback_manager = Lumiere.PlaybackManager.get_default ();

        playback_manager.play_queue.items_changed.connect ((pos, removed, added) => {
            if (playback_manager.play_queue.get_n_items () == 1) {
                return;
            }

            if (added == 1) {
                var title = Lumiere.get_title (playback_manager.play_queue.get_string (pos));
                var notification_label = (Gtk.Label) app_notification.child;
                notification_label.label = _("\"%s\" added to playlist").printf (title);
                app_notification.reveal_child = true;
            } else if (added > 1) {
                var notification_label = (Gtk.Label) app_notification.child;
                notification_label.label = ngettext ("%u item added to playlist", "%u items added to playlist", added).printf (added);
                app_notification.reveal_child = true;
            }
        });

        playback_manager.ended.connect (on_player_ended);

        var key_controller = new Gtk.EventControllerKey ();
        overlay.add_controller (key_controller);
        key_controller.key_released.connect (handle_key_press);

        var drop_target = new Gtk.DropTarget (typeof (Gdk.FileList), COPY);
        navigation_stack.add_controller (drop_target);
        drop_target.drop.connect ((val) => {
            if (val.type () != typeof (Gdk.FileList)) {
                return false;
            }

            File[] files;
            var file_list = ((Gdk.FileList) val.get_boxed ()).get_files ();
            foreach (var file in file_list) {
                files += file;
            }

            open_files (files);

            return true;
        });
    }

    private void action_back () {
        if (navigation_stack.visible_child_name == "player") {
            navigation_stack.visible_child_name = "welcome";
        }
    }

    private void action_fullscreen () {
        if (fullscreened) {
            unfullscreen ();
        } else {
            fullscreen ();
        }
    }

    private void action_open_file () {
        run_open_file ();
    }

    private void action_quit () {
        destroy ();
    }

    private void action_search () {
        Gdk.Display.get_default ().beep ();
    }

    private void action_undo () {
        // Undo functionality removed with Library
    }

    /** Returns true if the code parameter matches the keycode of the keyval parameter for
    * any keyboard group or level (in order to allow for non-QWERTY keyboards) **/
    public bool match_keycode (uint keyval, uint code) { //TODO: Test with non-QWERTY keyboard
        var display = Gdk.Display.get_default ();
        Gdk.KeymapKey [] keys;
        if (display.map_keyval (keyval, out keys)) {
            foreach (var key in keys) {
                if (code == key.keycode) {
                    return true;
                }
            }
        }

        return false;
    }

    public void handle_key_press (uint keyval, uint keycode, Gdk.ModifierType state) {
        if (keyval == Gdk.Key.Escape) {
            if (fullscreened) {
                unfullscreen ();
            } else {
                destroy ();
            }
        }

        if (navigation_stack.visible_child_name == "player") {
            if (match_keycode (Gdk.Key.space, keycode) || match_keycode (Gdk.Key.p, keycode)) {
                var play_pause_action = Application.get_default ().lookup_action (Lumiere.App.ACTION_PLAY_PAUSE);
                ((SimpleAction) play_pause_action).activate (null);
            } else if (match_keycode (Gdk.Key.a, keycode)) {
                Lumiere.PlaybackManager.get_default ().next_audio ();
            } else if (match_keycode (Gdk.Key.s, keycode)) {
                Lumiere.PlaybackManager.get_default ().next_text ();
            }

            bool shift_pressed = SHIFT_MASK in state;
            switch (keyval) {
                case Gdk.Key.Down:
                    player_page.seek_jump_seconds (shift_pressed ? -5 : -60);
                    break;
                case Gdk.Key.Left:
                    player_page.seek_jump_seconds (shift_pressed ? -1 : -10);
                    break;
                case Gdk.Key.Right:
                    player_page.seek_jump_seconds (shift_pressed ? 1 : 10);
                    break;
                case Gdk.Key.Up:
                    player_page.seek_jump_seconds (shift_pressed ? 5 : 60);
                    break;
                case Gdk.Key.Page_Down:
                    player_page.seek_jump_seconds (-600); // 10 mins
                    break;
                case Gdk.Key.Page_Up:
                    player_page.seek_jump_seconds (600); // 10 mins
                    break;
                default:
                    break;
            }
        } else if (navigation_stack.visible_child_name == "welcome") {
            if (match_keycode (Gdk.Key.p, keycode) || match_keycode (Gdk.Key.space, keycode)) {
                resume_last_videos ();
            }
        }
    }

    public void open_files (File[] files, bool clear_playlist_items = false, bool force_play = true) {
        if (clear_playlist_items) {
            Lumiere.PlaybackManager.get_default ().clear_playlist (false);
        }

        string[] videos = {};

        foreach (var file in files) {
            if (file.query_file_type (0) == FileType.DIRECTORY) {
                Lumiere.recurse_over_dir (file, (file_ret) => {
                    videos += file_ret.get_uri ();
                });
            } else {
                videos += file.get_uri ();
            }
        }

        Lumiere.PlaybackManager.get_default ().append_to_playlist (videos);

        if (force_play && videos.length > 0) {
            string videofile = videos [0];
            play_file (videofile, NavigationPage.WELCOME);
        }
    }

    public void resume_last_videos () {
        if (settings.get_string ("current-video") != "") {
            play_file (settings.get_string ("current-video"), NavigationPage.WELCOME, false);
        } else {
            action_open_file ();
        }
    }


    public void run_open_file (bool clear_playlist = false, bool force_play = true) {
        var file_dialog = new Gtk.FileDialog () {
            title = _("Open"),
            accept_label = _("_Open")
        };
        
        // Set initial folder if it exists and is valid
        var last_folder_path = settings.get_string ("last-folder");
        if (last_folder_path != "" && last_folder_path != "-1") {
            var last_folder = File.new_for_path (last_folder_path);
            if (last_folder.query_exists ()) {
                file_dialog.initial_folder = last_folder;
            }
        }

        file_dialog.open_multiple.begin (this, null, (obj, res) => {
            try {
                File[] files = {};

                var files_list = file_dialog.open_multiple.end (res);
                /* Do nothing when no files are selected.
                 * Gtk.FileDialog.open_multiple does not throw an error
                 * so handle this abnormal case by ourselves.
                 */
                uint num_files = files_list.get_n_items ();
                if (num_files < 1) {
                    return;
                }

                for (int i = 0; i < num_files; i++) {
                    files += (File)files_list.get_item (i);
                }

                open_files (files, clear_playlist, force_play);

                /* We already checked at least one file is selected so this won't fail,
                 * but guarantee safer access to the array in case
                 */
                return_if_fail (files.length > 0);
                /* Get the parent directory of the first File on behalf of opened files,
                 * because all of them should be in the same directory.
                 */
                var last_folder = files[0].get_parent ();
                settings.set_string ("last-folder", last_folder.get_path ());
            } catch (Error e) {
                if (e.message != "Dismissed by user") {
                    warning ("Failed to open video files: %s", e.message);
                }
            }
        });
    }

    private void on_player_ended () {
        navigation_stack.visible_child_name = "welcome";
    }

    public void play_file (string uri, NavigationPage origin, bool from_beginning = true) {
        navigation_stack.visible_child_name = "player";

        Lumiere.PlaybackManager.get_default ().play_file (uri, from_beginning);
    }

    private void update_navigation () {
        int64 position = Lumiere.PlaybackManager.get_default ().position;
        if (position > 0) {
            settings.set_int64 ("last-stopped", position);
        }

        var play_pause_action = Application.get_default ().lookup_action (Lumiere.App.ACTION_PLAY_PAUSE);

        if (navigation_stack.visible_child_name == "player") {
            ((SimpleAction) play_pause_action).set_state (true);
        } else {
            ((SimpleAction) play_pause_action).set_state (false);
        }

        // Update HeaderBar navigation
        string current_page = navigation_stack.visible_child_name ?? "welcome";
        switch (current_page) {
            case "welcome":
                welcome_page.header_bar.update_navigation (current_page);
                break;
            case "player":
                player_page.header_bar.update_navigation (current_page);
                break;
        }
    }
}
