# Ghostwriter

Ghostwriter is a Movable Type plugin that adds a control to change the author
on Edit Entry and Edit Page screens.

Perfect when the person entering or editing content is not the user to be
specified as the author.

## Documentation

### Editing Entry/Page Author

An **Author** select list will be displayed on the **Edit Entry** and **Edit
Page** screens for users with:

* a role (in the current blog) containing the privilege to **Edit All
  Entries**.
* the **System Administrator** system permissions.

Valid authors can be selected from a dropdown list (as shown in this
screenshot) or from a searchable, popup dialog.

![Ghostwriter Screenshot](http://github.com/beausmith/mt-plugin-ghostwriter/blob/master/screenshot-select-author.png?raw=true)

### Authors Select Menu Population

There are two ways in which the **Author** select list is populated...

**Note:** The select menu will not appear if only one user matches the
population method in use.

* ***Populating by role** is the recommended configuration.* In the system
  plugin settings, the **Author Role(s)** field can be populated with a
  comma-separated list of roles. When this field contains *any value*, users
  with the specified roles on the current blog will be listed in the Author
  select list.

    To list all authors with the roles "Author" or "Editor" enter the
    following in the **Author Role(s)** field:
    
     ![Plugin Settings
    Screenshot](http://github.com/beausmith/mt-plugin-ghostwriter/blob/master/screenshot-plugin-settings.png?raw=true)

    ***Note:** Roles specified which do not exist will be ignored, but will
    cause the Author select list to be populated by role.*

* If no value is specified in the system plugins settings, the **default
  population behavior** is to list with users whom have a role (in the current
  blog) containing the privilege **Create Entries** and/or **Edit All
  Entries**... essentially any permission to *post*

If the entry/page is associated to a **user who no longer has the ability to
publish** entries based upon one of the above methods, they will be listed and
selected when viewing an entry they are the specified author of. If the author
is changed and the form submitted, the user will no longer be listed unless
they match one of the above methods.

The Author select list is available as either a dropdown list or a popup
dialog. This selection is made from the system plugin Settings screen.


## Requirements

[Movable Type 4.0 or greater](http://www.movabletype.com)

**Note:** an issue in MT4.01 doesn't allow changing page authors, but fixed in
MT4.1+.

## Installation

    MT_DIR/
        plugins/
            Ghostwriter/
                [Files and folders]
        mt-static/
            plugins/
                Ghostwriter/
                    Ghostwriter.gif

## Revision History

<dl>
    <dt>v1.5 - 2011 Jul 25</dt>
    <dd>Converted to a <code>config.yaml</code> style plugin.<br />
        Added a popup dialog author select option.</dd>
    <dt>v1.3 - 2010 Jan 11</dt>
    <dd>Initial MT 5.x fix</dd>
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
* [Dan Wolfgang](http://danandsherree.com) of [Endevver](http://endevver.com)

## Plugin Website

<https://github.com/beausmith/mt-plugin-ghostwriter>

Enjoy!

## License

Artistic License 2.0 (see LICENSE.md file)

