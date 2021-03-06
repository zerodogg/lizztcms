package LizztCMS::Schema::LzStatus;

# Created by DBIx::Class::Schema::Loader
# DO NOT MODIFY THE FIRST PART OF THIS FILE

use strict;
use warnings;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
extends 'DBIx::Class::Core';


=head1 NAME

LizztCMS::Schema::LzStatus

=cut

__PACKAGE__->table("lz_status");

=head1 ACCESSORS

=head2 status_id

  data_type: 'integer'
  is_auto_increment: 1
  is_nullable: 0

=head2 status_name

  data_type: 'varchar'
  is_nullable: 1
  size: 56

=head2 system_status

  data_type: 'enum'
  default_value: 0
  extra: {list => [0,1]}
  is_nullable: 1

=head2 exclusive

  data_type: 'tinyint'
  default_value: 0
  is_nullable: 0

=cut

__PACKAGE__->add_columns(
  "status_id",
  { data_type => "integer", is_auto_increment => 1, is_nullable => 0 },
  "status_name",
  { data_type => "varchar", is_nullable => 1, size => 56 },
  "system_status",
  {
    data_type => "enum",
    default_value => 0,
    extra => { list => [0, 1] },
    is_nullable => 1,
  },
  "exclusive",
  { data_type => "tinyint", default_value => 0, is_nullable => 0 },
);
__PACKAGE__->set_primary_key("status_id");


# Created by DBIx::Class::Schema::Loader v0.07002 @ 2013-04-23 14:11:54
# DO NOT MODIFY THIS OR ANYTHING ABOVE! md5sum:e4PQyDSgJ5aiKRMD1UFzXg


# LizztCMS content management system
# Copyright (C) Utrop A/S Portu media & Communications 2008-2012
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

__PACKAGE__->has_many(
    articles => 'LizztCMS::Schema::LzArticle', 'status_id',
    { cascade_delete => 0 },
);

around 'status_name' => sub
{
    my $orig = shift;
    my $self = shift;
    if ($self->{realStatusName})
    {
        return $self->{realStatusName};
    }
    my $i18n = shift;
    if(not $i18n)
    {
        return $self->$orig();
    }
    my $name = $self->$orig();
    if ($self->get_column('system_status') == 1)
    {
        $name = $i18n->get($name);
    }
    $self->{realStatusName} = $name;
    return $name;
};

sub status_realname
{
    my $self= shift;
    my $i18n = shift;
    my $name = shift;
    if(not $i18n)
    {
        die('LzStatus->status_realname called without required argument: i18n object. Use: object->status_realname($c->stash->{i18n});'."\n");
    }
    my %Translator = (
        $i18n->get('Draft') => 'Draft',
        $i18n->get('Live') => 'Live',
        $i18n->get('Revision') => 'Revision',
        $i18n->get('Inactive') => 'Inactive',
    );
    if ($Translator{$name})
    {
        return $Translator{$name};
    }
    else
    {
        return $name;
    }
}

# You can replace this text with custom content, and it will be preserved on regeneration
__PACKAGE__->meta->make_immutable;
1;
