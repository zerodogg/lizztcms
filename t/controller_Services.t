use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LizztCMS' }
BEGIN { use_ok 'LizztCMS::Controller::Admin::Services' }

ok( request(/admin'/services')->is_success, 'Request should succeed' );


