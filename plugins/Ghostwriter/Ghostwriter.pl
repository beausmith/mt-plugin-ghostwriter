package MT::Plugin::Ghostwriter;

use strict;
use base qw( MT::Plugin );
use MT 4.0;

our $VERSION = '1.0'; 

my $plugin = MT::Plugin::Ghostwriter->new({
   id          => 'ghostwriter',
   key         => 'ghostwriter',
   name        => 'Ghostwriter',
   description => "Ghostwriter is a Movable Type plugin that adds an author field to Edit Entry and Edit Page screens for users with the role of Editor or Blog Administrator.",
   version     => $VERSION,
   icon        => 'Ghostwriter.gif',
   author_name => "Beau Smith",
   author_link => "http://beausmith.com/",
   plugin_link => "http://beausmith.com/mt/plugins/ghostwriter/",
});

# initialize plugin
MT->add_plugin($plugin);

# add plugin to the mt registry
# set callbacks
sub init_registry {
    my $plugin = shift;
    $plugin->registry({
        callbacks => {
            'MT::App::CMS::template_param.edit_entry' => \&_update_param,
            'MT::App::CMS::cms_pre_save.entry' => \&_pre_save,
        }            
   });
};

# before saving the entry presave the new author
sub _pre_save {
    my ($cb, $app, $entry_page) = @_;

    # continue if user has permission to edit all posts
    my $perms = $app->permissions;
    return 1 unless ($perms && $perms->can_edit_all_posts);

    # continue if new_author_id is set
    if ( my $author_id = $app->param("new_author_id")) {
        $entry_page->author_id($author_id);
    }
    return 1;
    
    #? Where does the plugin assist in updating the database
}

sub _update_param {
    my ($cb, $app, $params, $template) = @_;

    # continue if user has permission to edit all posts
    my $perms = $app->permissions;
    return unless ($perms && $perms->can_edit_all_posts);

    # Load authors with permission on this blog
    my $auth_iter = MT::Author->load_iter(
        { type => MT::Author::AUTHOR() },
        {
            'join' => MT::Permission->join_on(
                'author_id', { blog_id => $app->param('blog_id') }
            )
        }
    );

    my @a_data;
    my $this_author_id;

    if (my $entry_id = $params->{id}) {
        my $entry = MT::Entry->load($entry_id);
        $this_author_id = $entry->author_id;
        $params->{entry_author_name} = $entry->author->name;
        $params->{entry_author_id} = $entry->author->id;
    } else {
        $this_author_id = $app->user->id;
    }

    while ( my $author = $auth_iter->() ) {
        push @a_data,
          {
            author_id   => $author->id,
            author_name => $author->name,
            nickname => ($author->nickname) ? $author->nickname : $author->name,
            author_is_selected => $this_author_id && $this_author_id == $author->id ? 1 : 0,
          };
    }

    @a_data = sort { lc $a->{nickname} cmp lc $b->{nickname} } @a_data;
    $params->{author_loop} = \@a_data;

    my $status = $template->getElementById('status');
    my $created_by = $template->createElement('App:Setting', {id=>"entry_author_name", label=>'<__trans phrase="Author">'});

    $created_by->innerHTML( <<'END_HTML');
            <select name="new_author_id" class="full-width">
        <mt:loop name="author_loop">
                <option value="<$mt:var name="author_id"$>"<mt:if name="author_is_selected"> selected="selected"</mt:if>><$mt:var name="nickname"$></option>
        </mt:loop>
            </select>
END_HTML

    
    $template->insertBefore($created_by, $status);

}



