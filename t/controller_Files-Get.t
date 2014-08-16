use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LizztCMS' }
BEGIN { use_ok 'LizztCMS::Controller::Admin::Files::Get' }

ok( request(/admin'/files/get')->is_success, 'Request should succeed' );


