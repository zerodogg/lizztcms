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

package LizztCMS::HelperModules::TemplateRenderer::Resolver::RSSImport;
use Moose;
with 'LizztCMS::Role::TemplateRenderer::Resolver';

use LizztCMS::HelperModules::Live::Comments qw(comment_handler);
use LizztCMS::HelperModules::Calendar qw(datetime_from_SQL_to_unix);
use HTML::Entities qw(decode_entities);
use Carp;
use constant { true => 1, false => 0 };

sub get
{
    my($self,$type,$params) = @_;

    if($type eq 'list')
    {
        return $self->get_list($params);
    }

    die('Unknown data request: '.$type);
}

sub get_list
{
    my($self,$searchContent) = @_;
    my $return = {};

    my $saveAs = $searchContent->{as};
    if(not $saveAs)
    {
        $self->log('Resolver RSSImport list: No as= parameter for data, ignoring request. Template might crash.');
        return;
    }
    my $content;
    if ($self->renderer->has_var($saveAs))
    {
        $content = $self->renderer->get_var($saveAs);
    }
    else
    {
        my $limit = $searchContent->{limit} ? $searchContent->{limit} : 10;
        $content = $self->c->model('LizztCMSDB::LzRssArticle')->search({ deleted => \'!= 1', status => 'Active' }, { order_by => 'pubdate DESC', rows => $limit });
        $return->{$saveAs} = $content;
    }
    if ($searchContent->{allowPagination})
    {
        my $page = 1;

        if ($self->c->req->param('page') and $self->c->req->param('page') =~ /^\d+$/)
        {  
            $page = $self->c->req->param('page');
        }
        $content = $content->page($page);
        $return->{$saveAs.'_pager'} = $content->pager;
    }
    return $return;
}

__PACKAGE__->meta->make_immutable;
1;
