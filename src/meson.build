executable(
    meson.project_name(),
    config_file,
    gresource,
    'Application.vala',
    'Consts.vala',
    'Utils.vala',
    'Window.vala',
    'DBus/MprisPlayer.vala',
    'DBus/MprisRoot.vala',
    'Services/PlaybackManager.vala',
    'Widgets/HeaderBar.vala',
    'Widgets/UnsupportedFileDialog.vala',
    'Widgets/WelcomePage.vala',
    'Widgets/Player/BottomBar.vala',
    'Widgets/Player/PlayerPage.vala',
    'Widgets/Player/PlaylistItem.vala',
    'Widgets/Player/PlaylistPopover.vala',
    'Widgets/Player/PreviewPopover.vala',
    'Widgets/Player/SettingsPopover.vala',

    vala_args: [
        '--enable-experimental',
        '--target-glib=2.32',
    ],

    c_args: [
        '-w'
    ],

    dependencies: [
        dependency('gdk-pixbuf-2.0'),
        dependency('gee-0.8'),
        dependency('glib-2.0'),
        dependency('gobject-2.0'),
        dependency('gstreamer-1.0'),
        dependency('gstreamer-pbutils-1.0'),
        dependency('gstreamer-video-1.0'),
        dependency('gstreamer-tag-1.0'),
        dependency('gtk4', version: '>= 4.10'),
        dependency('libhelium-1'),
        dependency('libbismuth-1'),

        meson.get_compiler('vala').find_library('posix'),
        meson.get_compiler('c').find_library('m', required : false)
    ],
    install : true
)
