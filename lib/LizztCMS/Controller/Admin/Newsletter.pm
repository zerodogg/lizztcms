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

package LizztCMS::Controller::Admin::Newsletter;

use Moose;
use MooseX::NonMoose;
use namespace::autoclean;
BEGIN { extends 'Catalyst::Controller::FormBuilder' };
with 'LizztCMS::Role::List::Database';

use LizztCMS::HelperModules::Lists qw(reply_json_list);
use LizztCMS::HelperModules::JSON qw(json_response json_error);
use LizztCMS::HelperModules::Includes qw(add_jsIncl);
use LizztCMS::HelperModules::Editor qw(add_editor_incl);
use LizztCMS::HelperModules::Search qw(perform_search perform_advanced_search);
use LizztCMS::HelperModules::Mailer;
use POSIX qw(strftime);
use Text::CSV_XS;
use Regexp::Common qw[Email::Address];

# Summary: Handle requests for the subscriber list
sub index : Path Args(0) Form('/core/search')
{
    my ( $self, $c, $query ) = @_;
    my $subscription = $c->model('LizztCMSDB::LzNewsletterSubscription');
    my $list = $self->handleListRequest($c,{
            c => $c,
            query => $query,
            object => $subscription,
            objectName => 'subscriptions',
            template => 'adm/newsletter/index.html',
            orderParams => [qw(subscription_id name file status)],
            searchColumns => [qw(email name)],
            advancedSearch =>[ qw(groups.group_id) ],
            paginate => 1,
        });
    if ($c->req->param('_JSON_Submit'))
    {
        return reply_json_list($c,$list,[ 'subscription_id','email','name', 'format','send_every' ]);
    }
    my $i18n = $c->stash->{i18n};
    $c->stash->{template} = 'adm/newsletter/index.html';
    $c->stash->{pageTitle} = $i18n->get('Newsletter subscriptions');
    add_jsIncl($c,'newsletter.js','utils.js');
    add_editor_incl($c);
    $self->init_searchFilters($c);
}

# Summary: Delete a subscriber
sub delete : Local Param
{
    my ($self,$c,$subid) = @_;

    my $sub = $c->model('LizztCMSDB::LzNewsletterSubscription')->find({ subscription_id => $subid });

    if(not $sub or not defined $subid or $subid =~ /\D/)
    {
        return json_error($c);
    }
    $sub->delete();
    return json_response($c);
}

# Summary: Import a CSV list of users that are to be added to the database as
# subscribers
sub importsubscriber : Local
{
    my ( $self, $c ) = @_;
    if ( my $upload = $c->req->upload('impsub') )
    {
        my $csv = Text::CSV_XS->new ({
                binary    => 1,
                auto_diag => 1,
                sep_char  => ','    # not really needed as this is the default
            });
        my $subscriber;
        open(my $data, '<:encoding(utf8)',$upload->tempname);
        while (my $fields = $csv->getline( $data ))
        {
            if ($csv->parse($fields)) 
            {
                if(defined $fields->[0] and (Email::Address->parse($fields->[0])))
                {
                    my $email = $fields->[0];
                    my $findduplicates = $c->model('LizztCMSDB::LzNewsletterSubscription')->find({ email => $email });
                    if (not $findduplicates)
                    {
                        my $name = $fields->[1] || 'No Name';
                        my $interval = $fields->[2] || 'none';
                        my $format = (defined $fields->[3] && $fields->[3] =~ /^(text|html)$/) ? $fields->[3] : 'text';
                        $subscriber = $c->model('LizztCMSDB::LzNewsletterSubscription')->create({
                            email => $email,
                            name => $name,
                            format => $format,
                            send_every => $interval,
                        });
                        $subscriber->update();
                        my $latestsubscriberid = $subscriber->subscription_id;
                        if (defined $c->req->param('chk_bk') and length $c->req->param('chk_bk'))
                        {
                            my @check_group_array = $c->req->param('chk_bk');
                            foreach my $grpid (@check_group_array)
                            {
                                my $subgroupobj = $c->model('LizztCMSDB::LzNewsletterSubscriptionGroup')->create({
                                        group_id => $grpid,
                                        subscription_id => $latestsubscriberid,
                                    });
                                $subgroupobj->update();
                            }
                        }

                    }
                }
            }
        }
    }
    $c->response->redirect('/admin/newsletter');
    $c->detach();
}

# Summary: Export a CSV list of users
sub export : Local
{
    my($self,$c) = @_;
    $c->res->content_type('text/csv');
    my $domain = $c->req->uri->host;
    $domain =~ s/\.[^\.]+$//;
    $domain =~ s/(.*\.)?([^\.]+)$/$2/;
    $c->res->headers->header('Content-Disposition' => 'attachment; filename="lizztcmsNewsletter-'.$domain.'-'.strftime('%Y-%m-%d',localtime).'.csv"');
    $c->stash->{_requestHandled} = 1;
    my $i18n = $c->stash->{i18n};
    my $subscription = $c->model('LizztCMSDB::LzNewsletterSubscription');
    my $csv = Text::CSV_XS->new ({
            binary    => 0,
            auto_diag => 1,
            sep_char  => ','    # not really needed as this is the default
        });
    $csv->print($c->res,[ 'ID',$i18n->get('E-mail'),$i18n->get('Name'),$i18n->get('Format'),$i18n->get('Interval'),$i18n->get('Group') ]);
    $c->res->print("\r\n");
    while(my $entry = $subscription->next)
    {
        my @groups;
        my $groups = $entry->groups;
        if ($groups)
        {
            while(my $group = $groups->next)
            {
                if ($group->group)
                {
                    push(@groups,$group->group->group_name);
                }
            }
        }
        $csv->print($c->res, [ $entry->id, $entry->email, $entry->name, $entry->format, $entry->send_every, join('+',@groups) ]);
        $c->res->print("\r\n");
    }
    $c->detach;
}

# Summary: Display an editor that allows a user to send a newsletter manually
# to a select number of users
sub send : Local
{
    my ( $self, $c, $query ) = @_;
    my $i18n = $c->stash->{'i18n'};
    my $nid = $c->req->param('nid');
    my $nsubject;
    my $nformat;
    my $nmessage;
    if ($nid)
    {
        my $newsletter = $c->model('LizztCMSDB::LzNewsletterSaved')->find({ saved_id => $nid});
        $nsubject = $newsletter->subject;
        $nformat = $newsletter->format;
        $nmessage = $newsletter->body;
    }    
    $c->stash->{nsubject} =  $nsubject;
    $c->stash->{nformat} =  $nformat;
    $c->stash->{nmessage} =  $nmessage;    
    my $subscription = $c->model('LizztCMSDB::LzNewsletterSubscription')->search();
    $c->stash->{template} = 'adm/newsletter/send.html';
    $c->stash->{pageTitle} = $i18n->get('Manual newsletter');
    add_jsIncl($c,'newsletter.js','utils.js');
    add_editor_incl($c);
}

# Summary: Returns a list of *manually sent* newsletters that have been sent so
# far
sub sentPreviously : Local
{
    my ( $self, $c ) = @_;

    my $wants = $c->req->param('wants');

    if ($wants eq 'list')
    {
        my @content;
        my $saved = $c->model('LizztCMSDB::LzNewsletterSaved')->search(undef,{ order_by => 'sent_at' });
        while(defined($saved) && (my $s = $saved->next))
        {
            push(@content,{
                    saved_id => $s->saved_id,
                    from => $s->from_address,
                    subject => $s->subject,
                    body => $s->body,
                    format => $s->format,
                    sent_at => $s->sent_at,
                    action => '<span class="useTipsy" original-title="Copy text from this newsletter into a new message">Copy</span>',
                });
        }
        return json_response($c, { content => \@content });
    }
    elsif(length($wants))
    {
        my $newsletter = $c->model('LizztCMSDB::LzNewsletterSaved')->find({ saved_id => $wants});
        if(not $newsletter)
        {
            return json_error($c,'NOTFOUND');
        }
        return(json_response($c, {
                    from => $newsletter->from_address,
                    subject => $newsletter->subject,
                    body => $newsletter->body,
                    format => $newsletter->format,
                    sent_at => $newsletter->sent_at,
                    saved_id => $newsletter->saved_id,
                }));
    }
    else
    {
        return json_error($c,'UNKNOWN_REQUEST');
    }
    return json_error($c);
}

# Summary: Send a manual newsletter
sub submitManual : Local
{
    my ( $self, $c ) = @_;

    my($message_html,$message_text);

    my $subject = $c->req->param('subject');
    my $type = $c->req->param('type');
    my $from = $c->req->param('from');
    $type = (defined $type && $type eq 'html') ? 'HTML' : 'TEXT';
    # FIXME: e-mail ought to be validated
    $from = (defined $from && $from =~ /.+@.*\./) ? $from : $c->config->{LizztCMS}->{from_email};
    my @recipients = $c->req->param('recipient');
    my %dupeCheck;

    if ($type eq 'HTML')
    {
        $message_html = $c->req->param('message');
    }
    else
    {
        $message_text = $c->req->param('message');
    }

    my @sendTo;

    foreach my $email (@recipients)
    {
        next if $dupeCheck{$email};
        if ($email =~ s/^group_(\d+)$/$1/)
        {
            my $groups = $c->model('LizztCMSDB::LzNewsletterSubscriptionGroup')->search({ group_id => $email });
            while((defined $groups) && (my $g = $groups->next))
            {
                $g = $g->subscription;
                my $add = $g->email;
                next if $dupeCheck{$add};
                $dupeCheck{$add} = 1;
                push(@sendTo,{ email => $g->email, name => $g->name });
            }
        }
        else
        {
            my $nameFinder = $c->model('LizztCMSDB::LzNewsletterSubscription')->search({ email => $email });
            my $name;
            if ($nameFinder && $nameFinder->count > 0)
            {
                $name = $nameFinder->next;
                if ($name && $name->name)
                {
                    $name = $name->name;
                }
                else
                {
                    $name = undef;
                }
            }
            $dupeCheck{$email} = 1;
            push(@sendTo, { email => $email, name => $name });
        }
    }
    my @to;
    foreach my $email (@sendTo)
    {
        my $name = $email->{name};
        my $address = $email->{email};
        if (defined $name)
        {
            $name =~ s/(<|>)//g;
            $address = $name.' <'.$address.'>';
        }
        push(@to,$address);
    }
    my $mailer = LizztCMS::HelperModules::Mailer->new( c => $c );
    $mailer->add_mail({
        recipients   => \@to,
        subject      => $subject,
        message_text => $message_text,
        message_html => $message_html,
        from         => $from
    });
    $mailer->send;
    my $newMessage = $c->model('LizztCMSDB::LzNewsletterSaved')->create({
            sent_by_user => $c->user->user_id,
            from_address => $from,
            format => $type,
            subject => $subject,
            body => $c->req->param('message'),
        });
    return json_response($c);
}

# Summary: Returns a JSON-list of subscriber groups
sub groupList : Local
{
    my ( $self, $c ) = @_;

    my @groupList;
    my $groups = $c->model('LizztCMSDB::LzNewsletterGroup')->search(undef,{order_by => 'group_name'});
    while(my $group = $groups->next)
    {
        my $info = {
                group_id => $group->group_id,
                group_name=> $group->group_name,
            };
        if(defined $c->stash->{__groupsEnabled} )
        {
            if($c->stash->{__groupsEnabled}->{$group->group_id})
            {
                $info->{enabled} = 1;
            }
            else
            {
                $info->{enabled} = 0;
            }
        }
        push(@groupList,$info);
    }
    return json_response($c,{ groups => \@groupList });
}

# Summary: Returns a JSON-structure with information about a newsletter
# subscriber group
sub groupInfo : Local Param
{
    my ( $self, $c, $group_id ) = @_;
    my $group = $c->model('LizztCMSDB::LzNewsletterGroup')->find({ group_id => $group_id });
    if(not $group)
    {
        return(json_error($c,'INVALIDID'));
    }
    my $info = {
        group_name => $group->group_name,
        group_id => $group->group_id,
        internal => $group->internal,
    };
    return json_response($c,$info);
}

# Summary: Delete a newsletter subscriber group
sub groupDelete : Local Param
{
    my ( $self, $c, $group_id ) = @_;
    my $group = $c->model('LizztCMSDB::LzNewsletterGroup')->find({ group_id => $group_id });
    if(not $group)
    {
        return(json_error($c,'INVALIDID'));
    }
    $group->delete();
    return json_response($c);
}

# Summary: Create or rename a newsletter subscriber group
sub groupSave : Local
{
    my ( $self, $c ) = @_;

    my $group;
    if ($c->req->param('group_id') eq 'new')
    {
        if(not defined $c->req->param('group_name'))
        {
            return json_error($c,'GROUP_NAME_MISSING');
        }
        $group = $c->model('LizztCMSDB::LzNewsletterGroup')->create({
                group_name => $c->req->param('group_name'),
                internal => $c->req->param('group_internal') eq 'false' ? 0 : 1,
            });
    }
    else
    {
        $group = $c->model('LizztCMSDB::LzNewsletterGroup')->find({ group_id => $c->req->param('group_id') });
        if(not $group)
        {
            return json_error($c,'INVALID_GROUP_ID');
        }
        if(defined $c->req->param('group_name'))
        {
            $group->set_column('group_name',$c->req->param('group_name'));
        }
        if(defined $c->req->param('group_internal'))
        {
            $group->set_column('internal',
                $c->req->param('group_internal') eq 'false' ? 0 : 1);
        }
    }
    $group->update();
    return json_response($c);
}

# Summary: Edit
sub subscriptionGroupEdit : Local Param
{
    my ( $self, $c, $subid ) = @_;

    my $sub = $c->model('LizztCMSDB::LzNewsletterSubscription')->find({ subscription_id => $subid });

    if(not $sub or not defined $subid or $subid =~ /\D/)
    {
        return json_error($c);
    }

    my $groups = $sub->groups;
    if (defined $c->req->param('groups'))
    {
        while((defined $groups) && (my $group = $groups->next))
        {
            $group->delete();
        }
        foreach my $gid (split(/,/, $c->req->param('groups')))
        {
            $c->model('LizztCMSDB::LzNewsletterSubscriptionGroup')->create({ subscription_id => $subid, group_id => $gid});
        }
        return json_response($c);
    }
    else
    {
        my %groupsEnabled;
        while((defined $groups) && (my $group = $groups->next))
        {
            $groupsEnabled{$group->group_id} = 1;
        }
        $c->stash->{__groupsEnabled} = \%groupsEnabled;
        return $self->groupList($c);
    }
}

sub init_searchFilters : Private
{
    my ( $self, $c ) = @_;

    my $i18n = $c->stash->{i18n};
    my $groupOptions = [];
    my $groups = $c->model('LizztCMSDB::LzNewsletterGroup')->search(undef,{order_by => 'group_name'});
    while(my $group = $groups->next)
    {
        push(@{$groupOptions}, {
                value => $group->group_id,
                label => $group->group_name,
            });
    }
    $c->stash->{searchFilters} = [
        {
            name => $i18n->get('Group'),
            realname => 'group_id',
            options => $groupOptions,
            selected => defined $c->req->param('filter_group_id') ? $c->req->param('filter_group_id') : undef,
        },
    ];
}

sub subscriberSave : Local
{
    my ( $self, $c ) = @_;
    my $subscriber;
    my $email = $c->req->param('email');
    my $name = $c->req->param('name');
    my $format = (defined $c->req->param('format') && $c->req->param('format') =~ /^(text|html)$/) ? $c->req->param('format') : 'text';
    my $interval = $c->req->param('interval') || 'none' ;

    if(defined $email and (Email::Address->parse($email)))
    {
        if ($c->req->param('subsciber_id') eq 'new')
        {
            my $findduplicates = $c->model('LizztCMSDB::LzNewsletterSubscription')->find({ email => $email });
            if (not $findduplicates)
            {
                $subscriber = $c->model('LizztCMSDB::LzNewsletterSubscription')->create({
                        email => $email,
                        name => $name,
                        format => $format,
                        send_every => $interval,
                 });
             }
        }
        else
        {
            $subscriber = $c->model('LizztCMSDB::LzNewsletterSubscription')->find({ subscription_id => $c->req->param('subsciber_id')});
            if(not $subscriber)
            {
                return json_error($c,'INVALID_SUBSCRIPTION_ID');
            }
            else
            {

                $subscriber->set_column('email',$email);
                if(defined $name)
                {
                    $subscriber->set_column('name',$name);
                }
                if(defined $format)
                {
                    $subscriber->set_column('format',$format);
                }
                if(defined $interval)
                {
                    $subscriber->set_column('send_every',$interval);
                }
            }
         }
         $subscriber->update();
         return json_response($c);
     }
     else
     {
         return json_error($c,'EMAIL_MISSING');
     }
}

sub subscriberInfo : Local Param
{
     my ( $self, $c, $subscriber_id ) = @_;
     my $subscriber = $c->model('LizztCMSDB::LzNewsletterSubscription')->find({ subscription_id => $subscriber_id });
     if(not $subscriber)
     {
         return(json_error($c,'INVALIDID'));
     }
     my $info = {
         email => $subscriber->email,
         subscriber_id => $subscriber->subscription_id,
         name => $subscriber->name,
         format => $subscriber->format,
         interval => $subscriber->send_every,
     };
     return json_response($c,$info);
}
1;
