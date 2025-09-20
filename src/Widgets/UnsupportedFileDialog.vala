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

public class Lumiere.UnsupportedFileDialog : Gtk.Dialog {
    public string content_type { get; construct; }
    public string uri { get; construct; }

    public UnsupportedFileDialog (string uri, string filename, string content_type) {
        Object (
            title: _("Unrecognized file format"),
            transient_for: ((Gtk.Application) Application.get_default ()).active_window,
            content_type: content_type,
            uri: uri
        );
    }

    construct {
        // Create the dialog content
        var content_area = get_content_area ();
        
        // Create a vertical box for the content
        var vbox = new Gtk.Box (Gtk.Orientation.VERTICAL, 12);
        vbox.margin_top = 24;
        vbox.margin_bottom = 24;
        vbox.margin_start = 24;
        vbox.margin_end = 24;
        
        // Add an icon
        var icon = new Gtk.Image.from_icon_name ("dialog-error");
        icon.icon_size = Gtk.IconSize.LARGE;
        vbox.append (icon);
        
        // Add the main message
        var filename = uri.split ("/");
        var message_label = new Gtk.Label (_("Lumiere might not be able to play the file '%s'.".printf (filename[filename.length - 1])));
        message_label.wrap = true;
        message_label.justify = Gtk.Justification.CENTER;
        vbox.append (message_label);
        
        // Add the error details
        var error_text = _("Unable to play file at: %s\nThe file is not a video (\"%s\").").printf (
            uri,
            GLib.ContentType.get_description (content_type)
        );
        var error_label = new Gtk.Label (error_text);
        error_label.wrap = true;
        error_label.justify = Gtk.Justification.CENTER;
        error_label.add_css_class ("dim-label");
        vbox.append (error_label);
        
        content_area.append (vbox);
        
        // Add buttons
        add_button (_("Cancel"), Gtk.ResponseType.CANCEL);
        var play_anyway_button = add_button (_("Play Anyway"), Gtk.ResponseType.ACCEPT);
        play_anyway_button.add_css_class ("destructive-action");
    }
}
