# LizztCMS content management system
# Copyright (C) Utrop A/S Portu media & Communications 2008-2011
#
# This program is free software: you can redistribute it and/or modify
# it under the terms of the GNU General Public License as
# published by the Free Software Foundation, either version 3 of the
# License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details.
#
# You should have received a copy of the GNU General Public License
# along with this program.  If not, see <http://www.gnu.org/licenses/>.

package LizztCMS::Controller::LizztCMS;
use strict;
use warnings;
use 5.010;
use base 'Catalyst::Controller';

# Summary: Display the LizztCMS license if possible
sub license : Path('/lizztcms/license')
{
    my($self,$c) = @_;
    $c->stash->{template} = 'adm/core/dummy.html';
    $c->stash->{pageTitle} = 'LizztCMS license';
    $c->forward(qw/LizztCMS::Controller::Admin initI18N/);
    if ($c->user)
    {
        $c->stash->{username} = $c->user->user_name;
        $c->stash->{user_id} = $c->user->get_column('user_id');
        $c->user->set_c($c);
    }
    if (-e $LizztCMS::PATH.'/COPYING')
    {
        open(my $f,'<',$LizztCMS::PATH.'/COPYING');
        local $/;
        undef $/;
        my $content = <$f>;
        close($f);
        $content =~ s/</&lt/g;
        $content =~ s/>/&gt/g;
        $c->stash->{content} = '<pre>'.$content.'</pre>';
    }
    else
    {
        $c->stash->{content} = 'See <a href="http://www.gnu.org/licenses/gpl.html">http://www.gnu.org/licenses/gpl.html</a>';
    }
}

1;