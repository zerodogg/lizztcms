use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LizztCMS' }
BEGIN { use_ok 'LizztCMS::Controller::Admin::Files::Upload' }

ok( request(/admin'/files/upload')->is_success, 'Request should succeed' );


