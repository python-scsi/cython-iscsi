# cython-iscsi

Cython-based wrapper for [libiscsi](https://github.com/sahlberg/libiscsi).

## Prerequisites

This module depends on [libiscsi](https://github.com/sahlberg/libiscsi). You must first install the library before you can build this module.

In Debian-compatible distributions, you can do so:

    $ apt install libiscsi-dev

## Building and installing

To build and install from the repository:

    cython-iscsi $ pip install .

## Development

To set up a development environment, you can use the following commands:

```shell
$ git clone https://github.com/python-scsi/cython-iscsi
$ cd cython-iscsi
$ python3 -m venv venv
$ . venv/bin/activate
$ pip install -e .[dev]  # editable installation
$ pre-commit install
```

## License

Copyright © 2014-2020 The cython-iscsi Authors

This program is free software; you can redistribute it and/or modify
it under the terms of the GNU Lesser General Public License as published
by the Free Software Foundation; either version 2.1 of the License, or
(at your option) any later version.

This program is distributed in the hope that it will be useful,
but WITHOUT ANY WARRANTY; without even the implied warranty of
MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE. See the
GNU Lesser General Public License for more details.

You should have received a copy of the GNU Lesser General Public License
along with this program; if not, see <http://www.gnu.org/licenses/>.
