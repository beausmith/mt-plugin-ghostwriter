package Ghostwriter::Plugin;

use strict;
use warnings;

# cms_pre_save.entry callback
# Update the entry author (if needed) before saving the entry
sub pre_save {
    my ($cb, $app, $entry_page) = @_;
    my $user = $app->user;
    my $oldauthor = $app->param("original_author_id") || 0;
    my $newauthor = $app->param("new_author_id");

    # Return unless there's been a change in the author_id
    # This prevents false positives for $entry->is_changed('author_id')
    # A new entry is always considered to have a modified author_id
    return 1 unless $newauthor and $newauthor != $oldauthor;

    # If there is a current app user, ensure proper permissions
    if ( $user and ! $user->is_superuser() ) {
        # Check user permissions on this blog
        my $perms = $app->permissions;
        return 1 unless ($perms && $perms->can_edit_all_posts);
    }
    
    # Update the entry's author_id setting with new value
    $entry_page->author_id($newauthor);
    return 1;
}

# template_param.edit_entry callback
# Add the author picker to the Edit Entry/Edit Page screen.
sub update_param {
    my ($cb, $app, $params, $template) = @_;
    my $plugin = MT->component('ghostwriter');

    # continue if user has permission to edit all posts
    my $perms = $app->permissions;
    return unless ($perms && $perms->can_edit_all_posts);

    # Load authors with permission on this blog
    my $author_roles = $plugin->get_config_value('author_roles');

    my $auth_iter;
    if ($author_roles) {
        require MT::Role;
        my @roles = map { $_->id } MT::Role->load({ name => [ split /\s*,\s*/, $author_roles ]});
        return unless @roles;

        require MT::Association;
        $auth_iter = MT::Author->load_iter(
            { type => MT::Author::AUTHOR() },
            {
                'join' => MT::Association->join_on('author_id', {
                    'role_id' => \@roles,
                    'blog_id' => $app->param('blog_id')
                }),
            }
        );
    }
    else {
        $auth_iter = MT::Author->load_iter(
            { type => MT::Author::AUTHOR() },
            {
                'join' => MT::Permission->join_on('author_id', {
                    blog_id => $app->param('blog_id'),
                    # attempt to filter for postish permissions (excludes
                    # registered users who only have permission to comment
                    # for instance)
                    permissions => { like => '%post%', }
                })
            }
        );
    }

    my @a_data;
    my $this_author_id;
    my $current_author;

    if (my $entry_id = $params->{id}) {
        my $entry = MT::Entry->load($entry_id);
        $current_author = $entry->author if $entry;
    }

    $current_author ||= $app->user;
    $this_author_id = $current_author->id;
    $params->{entry_author_name} = $current_author->name;
    $params->{entry_author_id} = $this_author_id;

    my $hashify = sub {
        my ($author) = @_;
        return {
            author_id   => $author->id,
            nickname => $author->nickname || $author->name,
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

    my $position = $template->getElementById('status');
    my $created_by = $template->createElement('App:Setting', {
        id => "entry_author_name",
        label => '<__trans phrase="Author">',
        label_class => "left-label",
    });

    $created_by->innerHTML(<<'END_HTML');
            <input type="hidden" name="original_author_id" value="<$mt:var name="entry_author_id"$>" />
            <select name="new_author_id" class="full-width">
        <mt:loop name="author_loop">
                <option value="<$mt:var name="author_id"$>"<mt:if name="author_is_selected"> selected="selected"</mt:if>><$mt:var name="nickname"$></option>
        </mt:loop>
            </select>
END_HTML

    $template->insertAfter($created_by, $position);
}

1;

__END__
