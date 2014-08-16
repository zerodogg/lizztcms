use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LizztCMS' }
BEGIN { use_ok 'LizztCMS::Controller::Admin::Settings::Admin::Info' }

ok( request('/admin/settings/admin/info')->is_success, 'Request should succeed' );


