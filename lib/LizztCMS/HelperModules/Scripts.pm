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

package LizztCMS::HelperModules::Scripts;
use strict;
use warnings;
use Exporter qw(import);
use Config::Any;
use FindBin;
use Cwd qw(realpath);
use Test::MockClass;
use LizztCMS::Schema;
our @EXPORT_OK = qw(fakeC getConfig getLizztCMSRoot mockC getDBIC);

our $root;
my $conf;

sub fakeC
{
    eval
    {
        package LizztCMS::HelperModules::Log;
        sub _out { shift; warn(join(' ',@_)."\n") };
        sub error { my $s = shift or return; return $s->_out(@_) };
        sub debug { my $s = shift or return; return $s->_out(@_) };
        sub info { my $s = shift or return; return $s->_out(@_) };
        sub warn { my $s = shift or return; return $s->_out(@_) };
        sub _log { my $s = shift or return; return $s->_out(@_) };
    };
    my $c = bless({
            stack => [
                bless(
                    {
                        'namespace' => '',
                        name => 'auto',
                        class => 'LizztCMS::Controller::Root',
                        attributes => {
                            'Private' => [],
                        },
                        code => sub {},
                        reverse => 'auto',

                    },
                    'Catalyst::Action'),
            ],
            request => { arguments => {} },
        },'LizztCMS');
    return $c;
}

sub mockC
{
    local *STDERR;
    local *STDOUT;
    open(STDERR,'>','/dev/null');
    open(STDOUT,'>','/dev/null');

    my $mockLog = Test::MockClass->new('LizztCMS::HelperModules::Log');
    foreach my $type (qw(debug info warn _log))
    {
        $mockLog->addMethod($type, sub
            {
                warn($type.': '.join(' ',@_)."\n");
            });
    }

    my $logger = $mockLog->create;

    my $dbic = getDBIC();

    my $mockCache = Test::MockClass->new('LizztCMS::MockCache');
    $mockCache->defaultConstructor();
    $mockCache->addMethod('set',sub { });
    $mockCache->addMethod('get',sub { });
    $mockCache->addMethod('stash',sub { {} });
    my $mockCacheInstance = $mockCache->create;

    my $mockClass = Test::MockClass->new('LizztCMS');
    $mockClass->defaultConstructor();
    $mockClass->addMethod('config',sub { getConfig() });
    $mockClass->addMethod('log', sub { return $logger });
    $mockClass->addMethod('cache',sub { return $mockCacheInstance });
    $mockClass->addMethod('model', sub {
            shift;
            my $fetch = shift;
            $fetch =~ s/^LizztCMSDB:://;
            return $dbic->resultset($fetch);
        });
    return $mockClass->create;
}

sub getLizztCMSRoot
{
    if ($root)
    {
        return $root;
    }
    foreach (qw(./ ../ ../../ ../../../))
    {
        my $dir = $FindBin::RealBin.'/'.$_;
        if (-e $dir.'/lizztcms.yml')
        {
            $root = realpath($dir);
            return $root;
        }
    }
    return undef;
}

sub getConfig
{
    my $root = getLizztCMSRoot();
    if(not $root)
    {
        die("Failed to locate LizztCMS root: Can't load config");
    }
    if ($conf)
    {
        return $conf;
    }
    my $confFile = $root.'/lizztcms.yml';
    my $confloader = Config::Any->load_files({ files => [ $confFile ], use_ext => 1 });
    $conf = $confloader->[0]->{$confFile};
    return $conf;
}

sub getDBIC
{
    my $config = getConfig();
	my $cinfo = $config->{'Model::LizztCMSDB'}->{'connect_info'};
	$cinfo->{mysql_enable_utf8} = 1;
    return LizztCMS::Schema->connect( $cinfo );
}

1;
