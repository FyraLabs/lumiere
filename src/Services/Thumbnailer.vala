/*
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

namespace Lumiere.Services {
    [DBus (name = "org.freedesktop.thumbnails.Thumbnailer1")]
    private interface Tumbler : GLib.Object {
        public abstract async uint queue (string[] uris, string[] mime_types, string flavor, string sheduler, uint handle_to_dequeue) throws GLib.IOError, GLib.DBusError;
        public signal void finished (uint handle);
    }

    public class DbusThumbnailer : GLib.Object {
        private Tumbler tumbler;
        private const string THUMBNAILER_IFACE = "org.freedesktop.thumbnails.Thumbnailer1";
        private const string THUMBNAILER_SERVICE = "/org/freedesktop/thumbnails/Thumbnailer1";

        public signal void finished (uint handle);

        public DbusThumbnailer () {
        }

        construct {
            try {
                tumbler = Bus.get_proxy_sync (BusType.SESSION, THUMBNAILER_IFACE, THUMBNAILER_SERVICE);
                tumbler.finished.connect ((handle) => { 
                    debug ("Thumbnail generation finished for handle %u", handle);
                    finished (handle); 
                });
                debug ("Connected to thumbnailer service");
            } catch (Error e) {
                warning ("Failed to connect to thumbnailer service: %s", e.message);
                tumbler = null;
            }
        }

        public void instant (Gee.ArrayList<string> uris, Gee.ArrayList<string> mimes, string size) {
            if (tumbler == null) {
                warning ("Thumbnailer service not available");
                return;
            }
            
            tumbler.queue.begin (uris.to_array (), mimes.to_array (), size, "default", 0);
            debug ("Queued %d URIs for thumbnail generation", uris.size);
        }
    }
}
