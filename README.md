# Ghostwriter

Ghostwriter is a Movable Type plugin that adds a control to change the author on Edit Entry and Edit Page screens.

Perfect when the person entering or editing content is not the user to be specified as the author.

## Documentation

### Editing Entry/Page Author

An **Author** select list will be displayed on the **Edit Entry** and **Edit Page** screens for users with a role (in the current blog) containing the privilege to **Edit All Entries**.

![Ghostwriter Screenshot](http://github.com/beausmith/mt-plugin-ghostwriter/blob/master/screenshot-select-author.png?raw=true)

### Authors Select Menu Population

There are two ways in which the **Author** select list is populated:

* ***Populating by role** is the recommended configuration.* In the system plugin settings, the **Author Role(s)** field can be populated with a comma-separated list of roles. When this field contains *any value*, users with the specified roles on the current blog will be listed in the Author select list.

    To list all authors with the roles "Author" or "Editor" enter the following in the **Author Role(s)** field:
    
    ![Plugin Settings Screenshot](http://github.com/beausmith/mt-plugin-ghostwriter/blob/master/screenshot-plugin-settings.png?raw=true)

    ***Note:** Roles specified which do not exist will be ignored, but will cause the Author select list to be populated by role.*

* If no value is specified in the system plugins settings, the **default behavior** is to populate the select list with users whom have a role (in the current blog) containing the privilege **Create Entries** and/or **Edit All Entries**... essentially any permission to *post*

If the entry/page is associated to a **user who no longer has the ability to publish** entries based upon one of the above methods, they will be listed and selected when viewing an entry they are the specified author of. If the author is changed and the form submitted, the user will no longer be listed unless they match one of the above methods.

## Requirements

[Movable Type 4.0 or greater](http://www.movabletype.com)

**Note:** an issue in MT4.01 doesn't allow changing page authors, but fixed in
MT4.1+.

## Installation

    MT_DIR/
        plugins/
            Ghostwriter/
                Ghostwriter.pl
                tmpl/
                    config.tmpl
        mt-static/
            plugins/
                Ghostwriter/
                    Ghostwriter.gif

## Revision History

<dl>
    <dt>v1.2 - 2009 Aug 21</dt>
    <dd>Always include current author in select menu.<br />
        Limit list of available authors to a specific role(s).</dd>
    <dt>v1.1 - 2007 Sep 20</dt>
    <dd>Removed some testing code</dd>
    <dt>v1.0 - 2007 Sep 19</dt>
    <dd>Initial Release</dd>
</dl>

## Developers

* [Beau Smith](http://beausmith.com) of [Six Apart](http://www.sixapart.com)
* [Brad Choate](http://bradchoate.com) of [Six Apart](http://www.sixapart.com)


## Plugin Website

<http://beausmith.com/mt/plugins/ghostwriter/>

Enjoy!

## License

Artistic License 2.0 (see LICENSE.md file)

