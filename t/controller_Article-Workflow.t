use strict;
use warnings;
use Test::More tests => 3;

BEGIN { use_ok 'Catalyst::Test', 'LizztCMS' }
BEGIN { use_ok 'LizztCMS::Controller::Admin::Article::Workflow' }

ok( request(/admin'/article/workflow')->is_success, 'Request should succeed' );


