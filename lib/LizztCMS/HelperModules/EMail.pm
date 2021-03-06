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

# LizztCMS::HelperModules::EMail;
#
# This module contains functions that assists with sending emails
#
# It exports nothing by default, you need to explicitly import the
# functions you want.
package LizztCMS::HelperModules::EMail;

use strict;
use warnings;
use Exporter qw(import);
our @EXPORT_OK = qw(send_email_to send_raw_email_to);
use MIME::Base64 qw(encode_base64);
use LizztCMS::HelperModules::Mailer;
use Encode qw(encode);
use Carp;

# Usage: send_raw_email_to($c,'subject','content',to,from,type);
#
# content is the main message content
# to is the recipient e-mail address
# from is the from e-mail address
# type is eithe TEXT or HTML, declares the type of content
sub send_raw_email_to
{
    my ($c,$subject,$content,$to,$from,$type) = @_;
    carp('Call to deprecated function: send_raw_email_to(), use LizztCMS::HelperModules::Mailer');

    if(not defined $type or not length $type)
    {
        $c->log->warn('Got no type when attempting to send e-mail, using TEXT');
        $type = 'TEXT';
    }
    elsif(not $type =~ /^(TEXT|HTML)$/)
    {
        $c->log->warn('Got invalid type when attempting to send e-mail('.$type.'), using TEXT');
        $type = 'TEXT';
    }

    if(not $from =~ /<.*>/)
    {
        $c->log->warn('from address "'.$from.'": did not have <> (no name)');
    }

    my($message_text,$message_html);
    if ($type eq 'HTML')
    {
        $message_html = $content;
    }
    else
    {
        $message_text = $content;
    }
    my $mailer = LizztCMS::HelperModules::Mailer->new( c => $c );
    $mailer->add_mail({
        recipients   => $to,
        subject      => $subject,
        message_text => $message_text,
        message_html => $message_html,
        from         => $from
    });
    $mailer->send;
}

# Usage: send_email_to($c,'automessage','subject','content',to, to,to);
# automessage can be undef, if it is a default will be used.
sub send_email_to
{
    my $c = shift;
    my $automessage = shift;
    carp('Call to deprecated function: send_email_to(), use LizztCMS::HelperModules::Mailer');
    if (not $automessage)
    {
        $automessage = $c->stash->{i18n} ?
            $c->stash->{i18n}->get('This message has been automatically generated by LizztCMS')
            : 'This message has been automatically generated by LizztCMS';
    }
    $automessage = "\n\n--\n".$automessage;
    $automessage .= "\n".$c->uri_for('/admin');
    my $subject = shift;
    my $content = shift;
    $content .= $automessage;
    my $from_address = $c->config->{LizztCMS}->{from_email};
    if(not $from_address)
    {
        $c->log->error('from_email is not set in the config, using dummy e-mail');
        $from_address = 'EMAIL_NOT_SET_IN_CONFIG@localhost';
    }
    
    if(
        defined $c->config->{LizztCMS}->{email_to_override} && 
        (not $c->config->{LizztCMS}->{email_to_override} eq 'false') &&
        length $c->config->{LizztCMS}->{email_to_override})
    {
        $content = "ORIGINAL TO: ".join(',',@_)."\n\n".$content;
        $c->log->debug('Sending to '.$c->config->{LizztCMS}->{email_to_override}.' instead of the real recipient because email_to_override is in effect');
        _send_email($c,$subject,$content,$c->config->{LizztCMS}->{email_to_override},$from_address);
    }
    else
    {
        foreach my $to (@_)
        {
            _send_email($c,$subject,$content,$to,$from_address);
        }
    }
}

sub _send_email
{
    my ($c,$subject,$content,$to,$from) = @_;
    carp('Call to deprecated function: _send_email(), use LizztCMS::HelperModules::Mailer');

    return send_raw_email_to($c, '[LizztCMS] '.$subject, $content, $to, 'LizztCMS <'.$from.'>','TEXT');
}
