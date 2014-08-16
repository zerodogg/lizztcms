# LizztCMS - Content management system

LizztCMS is a content management system written in perl. LizztCMS is
alpha-quality software.

## Development VM

LizztCMS comes with a [Vagrant](http://vagrantup.com)-based development
environment. To quickly get a Debian 7 VM with LizztCMS and all dependencies first
install Vagrant and then run:

    vagrant up

Once a VM is running you can start a LizztCMS server that will listen on
http://127.0.0.1:3000/ by running:

    vagrant ssh -c bin/lizztcms_server

See the Vagrant documentation as well as the message output once `vagrant up`
finishes for more information.

## Documentation

Installation documentation, as well as template API documentation etc. can be
found in the docs/ directory.

## License

Copyright (C) Eskild Hustvedt 2014

Derived from Lixuz: Copyright (C) Utrop A/S Portu media & Communications 2008-2014

This program is free software: you can redistribute it and/or modify
it under the terms of the GNU General Public License as
published by the Free Software Foundation, either version 3 of the
License, or (at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
GNU General Public License for more details.

You should have received a copy of the GNU General Public License
along with this program.  If not, see <http://www.gnu.org/licenses/>.
