# Ghostwriter

![Ghostwriter Screenshot](http://github.com/beausmith/mt-plugin-ghostwriter/blob/master/screenshot.png?raw=true)

Ghostwriter is a Movable Type plugin that adds an author field to Edit Entry and Edit Page screens. This plugin is for those who add content to MT, but who need to specify another user as the author.

The select menu of authors is populated with users which are associated to the current blog with a role containing the privilege to "Create Entries" and/or "Edit All Entries".

The select menu will be available to users which are associated to the current blog with a role containing the privilege to "Edit All Entries".

Requires [Movable Type 4.0 or greater](http://www.movabletype.com).

**Note:** changing author of pages is broken due to an issue in MT4.01 but fixed in MT4.1.

### Installation

    MT_DIR/
        plugins/
            Ghostwriter/
                Ghostwriter.pl
        mt-static/
            plugins/
                Ghostwriter/
                    Ghostwriter.gif

### Revision History

<dl>
    <dt>v1.1 - 2007 Sep 20</dt>
    <dd>Removed some testing code</dd>
    <dt>v1.0 - 2007 Sep 19</dt>
    <dd>Initial Release</dd>
</dl>

### Developers

* [Beau Smith](http://beausmith.com) of [Six Apart](http://www.sixapart.com)
* [Brad Choate](http://bradchoate.com) of [Six Apart](http://www.sixapart.com)


## Plugin Website

<http://beausmith.com/mt/plugins/ghostwriter/>

Enjoy!

## License

Artistic License 2.0 (see LICENSE.md file)

