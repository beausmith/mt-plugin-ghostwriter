package Ghostwriter::Plugin;

use strict;
use warnings;

# cms_pre_save.entry callback
# Update the entry author (if needed) before saving the entry
sub pre_save {
    my ($cb, $app, $entry_page) = @_;
    my $q = $app->param;
    my $user = $app->user;
    my $oldauthor = $q->param("original_author_id") || 0;
    my $newauthor = $q->param("new_author_id");

    # Return unless there's been a change in the author_id
    # This prevents false positives for $entry->is_changed('author_id')
    # A new entry is always considered to have a modified author_id
    return 1 unless $newauthor and $newauthor != $oldauthor;

    # If there is a current app user, ensure proper permissions
    if ( $user and ! $user->is_superuser() ) {
        # Check user permissions on this blog
        my $perms = $app->permissions;
        return 1 unless (
            $app->user->is_superuser() 
            || ($perms && $perms->can_edit_all_posts)
        );
    }

    # Update the entry's author_id setting with new value
    $entry_page->author_id($newauthor);
    return 1;
}

# template_param.edit_entry callback
# Add the author picker to the Edit Entry/Edit Page screen.
sub update_param {
    my ($cb, $app, $params, $template) = @_;
    my $q = $app->param;
    my $plugin = MT->component('ghostwriter');

    # continue if user has permission to edit all posts
    my $perms = $app->permissions;
    return unless (
        $app->user->is_superuser() 
        || ($perms && $perms->can_edit_all_posts) 
    );

    # This plugin works with MT4 and MT5, though MT5 needs some special 
    # handling. Create the pertinet variables here and just use them later.
    my $options = {};
    if (
        $app->product_name =~ m/Movable/  # Movable Type
        && $app->product_version =~ m/^5/ # Version 5.x
    ) {
        $options->{position} = 'basename';
        $options->{label_class} = 'top-label';
    }
    else {
        $options->{position} = 'authored_on';
        $options->{label_class} = 'left-label';
    }

    # If a default author was specified for this blog, use them.
    my $default = $plugin->get_config_value(
        'default_author',
        'blog:' . $q->param('blog_id')
    );

    # Set the $current_author variable, to be used later in both the popup and
    # dropdown style interfaces.
    my $current_author;

    # Is this an existing entry? If yes, we want to check if the entry was
    # previewed (and then find the author supplied from the preview). If not
    # previewed, load the author assigned to the entry.
    if (my $entry_id = $params->{id}) {

        # This entry was previewed, and the user clicked "Re-Edit this Entry"
        # so they are back at the Edit Entry interface. Use the `reedit` flag
        # to know this and load the correct author.
        if ( $app->param('reedit') ) {
            my $author = MT->model('author')->load( $q->param('author_id') );
            $current_author = $author if $author;
        }
        
        # This is simply a previously-saved entry, now being edited.
        else {
            my $entry = MT->model('entry')->load($entry_id);
            $current_author = $entry->author if $entry;
        }

    # This is a new entry. Check if a Default Author was specified in
    # GhostWriter's plugin Settings, and use it.
    } elsif ($default ne '') {
        my $author = MT->model('author')->load( $default );
        $current_author = $author if $author;
    }

    # Finally, build the interface.
    if ( $plugin->get_config_value('author_select_type') eq 'Popup') {
        _create_popup_interface({
            options        => $options,
            plugin         => $plugin,
            params         => $params,
            template       => $template,
            current_author => $current_author,
        });
    }
    else { # The dropdown interface is the default
        _create_dropdown_interface({
            options        => $options,
            plugin         => $plugin,
            params         => $params,
            template       => $template,
            current_author => $current_author,
        });
    }

}

sub _create_dropdown_interface {
    my ($arg_ref) = @_;
    my $options        = $arg_ref->{options};
    my $plugin         = $arg_ref->{plugin};
    my $params         = $arg_ref->{params};
    my $template       = $arg_ref->{template};
    my $current_author = $arg_ref->{current_author};
    my ($app) = MT->instance;
    my $q     = $app->param;

    # Load authors with permission on this blog
    my $author_roles = $plugin->get_config_value('author_roles');

    # Were valid author roles specified in GhostWriter's plugin settings? If
    # so, use them.
    my $auth_iter;
    if ($author_roles) {
        require MT::Role;
        my @roles = map { $_->id } MT::Role->load({ 
            name => [ split /\s*,\s*/, $author_roles ]
        });
        return unless @roles;

        require MT::Association;
        $auth_iter = MT::Author->load_iter(
            { type => MT::Author::AUTHOR() },
            {
                'join' => MT::Association->join_on(
                    'author_id', 
                    {
                        role_id => \@roles,
                        blog_id => $q->param('blog_id'),
                    },
                    {
                        unique => 1,
                    }
                ),
            }
        );
    }

    # Author roles were not supplied in GhostWriter's plugin Settings, so just
    # find authors who have adequate permission to post.
    else {
        require MT::Permission;
        $auth_iter = MT::Author->load_iter(
            { type => MT::Author::AUTHOR() },
            {
                'join' => MT::Permission->join_on(
                    'author_id',
                    {
                        blog_id => $q->param('blog_id'),
                        # attempt to filter for postish permissions (excludes
                        # registered users who only have permission to comment
                        # for instance)
                        permissions => { like => '%post%', },
                    },
                    undef,
                ),
            }
        );
    }

    my @a_data;
    my $this_author_id;

    $current_author ||= $app->user;
    $this_author_id = $current_author->id;
    $params->{entry_author_name} = $current_author->name;
    $params->{entry_author_id} = $this_author_id;

    my $hashify = sub {
        my ($author) = @_;
        return {
            author_id          => $author->id,
            nickname           => $author->nickname || $author->name,
            author_is_selected => $this_author_id == $author->id,
        };
    };

    push @a_data, $hashify->($current_author);

    while ( my $author = $auth_iter->() ) {
        next if $this_author_id && $this_author_id == $author->id;
        push @a_data, $hashify->($author);
    }

    # if we have no other authors to display, we don't need this control
    return if @a_data == 1;

    @a_data = sort { lc $a->{nickname} cmp lc $b->{nickname} } @a_data;
    $params->{author_loop} = \@a_data;

    my $position = $template->getElementById( $options->{position} );
    my $created_by = $template->createElement('App:Setting', {
        id          => "entry_author_name",
        label       => '<__trans phrase="Author">',
        label_class => $options->{label_class},
    });

    $created_by->innerHTML(<<'END_HTML');
        <mt:If name="id">
            <input type="hidden" name="original_author_id" value="<$mt:var name="entry_author_id"$>" />
        </mt:If>
            <select name="new_author_id" class="full-width">
        <mt:loop name="author_loop">
                <option value="<$mt:var name="author_id"$>"<mt:if name="author_is_selected"> selected="selected"</mt:if>><$mt:var name="nickname"$></option>
        </mt:loop>
            </select>
END_HTML

    $template->insertBefore($created_by, $position);
}

# If the popup dialog is to be used to select the author, we need to provide
# a link to create that popup as well as inform the user who the current
# author is.
sub _create_popup_interface {
    my ($arg_ref) = @_;
    my $options        = $arg_ref->{options};
    my $plugin         = $arg_ref->{plugin};
    my $params         = $arg_ref->{params};
    my $template       = $arg_ref->{template};
    my $current_author = $arg_ref->{current_author};
    my ($app) = MT->instance;
    my $q     = $app->param;

    my $position = $template->getElementById( $options->{position} );
    my $created_by = $template->createElement('App:Setting', {
        id          => "entry_author_name",
        label       => '<__trans phrase="Author">',
        label_class => $options->{label_class},
    });

    # A hidden field records the original author ID, while another records 
    # the new author ID which is saved later in a cms_pre_save.entry callback.
    my $inner_html = '<mt:If name="id"><input type="hidden" '
        . 'name="original_author_id" id="original_author_id" /></mt:If>'
        . '<input type="hidden" name="new_author_id" id="new_author_id" '
        . 'value="' . $current_author->id . '" />';

    # Create the author widget display name and "change author" content.
    $inner_html .= '<div style="padding-top: 2px;">' # 2px aligns horizontally
        . '<span id="current_author_display_name" style="padding-right: 5px;">' 
        . $current_author->nickname . '</span>';

        # MT4
        if ($app->product_version < 5) {
            $inner_html .= ' (<a href="javascript:void(0)" onclick="return '
                . "openDialog(false, 'ghostwriter_pick_author', "
                . "'blog_id=<mt:BlogID>&amp;idfield=new_author_id&amp;"
                . "namefield=current_author_display_name&amp;"
                . "cur_author_display_name='"
                . " + document.getElementById('current_author_display_name').innerHTML )";
        }
        # MT5
        else {
            $inner_html .= " (<a onclick=\"jQuery.fn.mtDialog.open('"
                . $app->mt_uri . '?__mode=ghostwriter_pick_author&amp;'
                . 'blog_id=' . $app->blog->id . '&amp;'
                . 'idfield=new_author_id&amp;'
                . 'namefield=current_author_display_name&amp;'
                . "cur_author_display_name=' "
                . "+ document.getElementById('current_author_display_name')."
                . 'innerHTML )" style="cursor: pointer;"';
        }

        $inner_html .= '">change&nbsp;author</a>)' # Don't break across lines
            . '</div>';

    $created_by->innerHTML( $inner_html );
    $template->insertBefore($created_by, $position);
}

# This is the popup window that a user can pick an author from.
sub popup_select_author {
    my $app    = shift;
    my $q      = $app->param;
    my $param  = {};
    my $plugin = MT->component('ghostwriter');
    my $tmpl   = $plugin->load_tmpl('pick_author.mtml');

    # Load authors with permission on this blog
    my $author_roles = $plugin->get_config_value('author_roles');

    # Create the arguments for the listing screen based on whether roles have
    # been specified for Ghostwriter to filter on.
    my $args = {};
    if ($author_roles) {
        my @roles = map { $_->id } MT->model('role')->load({ 
            name => [ split(/\s*,\s*/, $author_roles) ]
        });
        return unless @roles;

        require MT::Association;
        $args = {
            sort => 'name',
            join => MT::Association->join_on(
                'author_id',
                {
                    role_id => \@roles,
                    blog_id => $app->param('blog_id')
                },
                {
                    unique => 1,
                },
            ),
        };
    }
    else {
        require MT::Permission;
        $args = {
            sort => 'name',
            join => MT::Permission->join_on(
                'author_id',
                {
                    blog_id => $app->param('blog_id'),
                    # attempt to filter for postish permissions (excludes
                    # registered users who only have permission to comment
                    # for instance)
                    permissions => { like => '%post%', },
                },
                undef
            ),
        };
    }

    my $hasher = sub {
        my ( $obj, $row ) = @_;
        $row->{label}       = $row->{name};
        $row->{description} = $row->{nickname};
    };

    # MT::CMS::User::dialog_select_author mostly does what is needed, so that
    # served as the starting point. We're supplying an argument list to 
    # augment it.
    $app->listing(
        {
            type  => 'author',
            terms => {
                type   => MT::Author::AUTHOR(),
                status => MT::Author::ACTIVE(),
            },
            args     => $args,
            code     => $hasher,
            template => $tmpl,
            params   => {
                dialog_title =>
                  $app->translate("Select an entry author"),
                items_prompt =>
                  $app->translate("Selected author"),
                search_prompt => $app->translate(
                    "Type a username to filter the choices below."),
                panel_title       => $app->translate("Current author: ") 
                    . $q->param('cur_author_display_name'),
                panel_label       => $app->translate("Entry Author"),
                panel_description => $app->translate("Display Name"),
                panel_type        => 'author',
                panel_multi       => defined $app->param('multi')
                    ? $app->param('multi')
                    : 0,
                panel_searchable => 1,
                panel_first      => 1,
                panel_last       => 1,
                list_noncron     => 1,
                idfield          => $app->param('idfield'),
                namefield        => $app->param('namefield'),
            },
        }
    );
}


sub pre_preview {
    my ($plugin, $app, $entry, $data) = @_;
    my $q = $app->param;

    # This causes any preview tags to use the selected author.
    $entry->author_id( $q->param('new_author_id') );
    @$data[0]->{data_value} = $q->param('new_author_id');

    # Supply the `original_author_id` and `new_author_id` fields to the
    # preview, which allows the post-save callback to work properly for the
    # "Save this Entry" button found on the preview page.
    push @$data, {
        data_name  => 'original_author_id',
        data_value => $q->param('author_id'),
    };
    push @$data, {
        data_name  => 'new_author_id',
        data_value => $q->param('new_author_id'),
    };

    return 1;
}

1;

__END__
