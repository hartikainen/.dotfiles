import os
from pathlib import Path
import platform
import sys
import tempfile

from gi.repository import Gio, GLib


def main():
    if os.environ.get("DOTFILES_TEST_GUEST") != "1" or platform.system() != "Linux":
        raise RuntimeError("Run only in a disposable Linux guest")
    expected = {
        "org.gnome.desktop.peripherals.keyboard": {"repeat-interval": 10, "delay": 200},
        "org.gnome.desktop.interface": {
            "monospace-font-name": "Monospace 12",
            "clock-show-date": sys.argv[1] == "a",
        },
        "org.gnome.desktop.input-sources": {"xkb-options": ["ctrl:nocaps"]},
    }
    for schema, keys in expected.items():
        settings = Gio.Settings.new(schema)
        for key, value in keys.items():
            actual = settings.get_value(key).unpack()
            assert actual == value, (schema, key, actual, value)
    sources = (
        Gio.Settings.new("org.gnome.desktop.input-sources")
        .get_value("sources")
        .unpack()
    )
    assert [tuple(source) for source in sources] == [("xkb", "us"), ("xkb", "fi")]
    pictures = Path(GLib.get_user_special_dir(GLib.UserDirectory.DIRECTORY_PICTURES))
    destination = Path.home() / "Desktop/screenshots"
    screenshots = pictures / "Screenshots"
    assert screenshots.is_symlink()
    assert screenshots.resolve() == destination.resolve()
    with tempfile.NamedTemporaryFile(
        dir=screenshots, prefix="dotfiles-preference-test-"
    ) as probe:
        probe.write(b"screenshot destination probe\n")
        probe.flush()
        assert (
            destination / Path(probe.name).name
        ).read_bytes() == b"screenshot destination probe\n"


if __name__ == "__main__":
    main()
