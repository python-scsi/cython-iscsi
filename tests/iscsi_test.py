# SPDX-FileCopyrightText: 2014 The cython-iscsi Authors
#
# SPDX-License-Identifier: LGPL-2.1-or-later

import unittest

import iscsi


class ContextTest(unittest.TestCase):
    def test_url_parse(self):
        context = iscsi.Context("foobar")

        url = iscsi.URL(context, "iscsi://localhost/my-target/0")
        self.assertEqual(url.portal, "localhost")

    def test_set_context_params(self):
        context = iscsi.Context("foobar")
        context.set_targetname("my-target")
        context.set_header_digest(iscsi.ISCSI_HEADER_DIGEST_NONE)

    def test_command(self):
        context = iscsi.Context("foobar")
        task = iscsi.Task(b"\x12\x00\x00\x00\x60\x00", iscsi.SCSI_XFER_READ, 96)
        data_in = bytearray(96)
        context.command(0, task, None, data_in)


class TaskTest(unittest.TestCase):
    def test_basic(self):
        task = iscsi.Task(b"\x12\x00\x00\x00\x60\x00", iscsi.SCSI_XFER_READ, 96)
        self.assertIsNotNone(task)

    def test_bytearray(self):
        task = iscsi.Task(
            bytearray(b"\x12\x00\x00\x00\x60\x00"), iscsi.SCSI_XFER_READ, 96
        )
        self.assertIsNotNone(task)

    def test_empty_cdb(self):
        with self.assertRaises(ValueError):
            iscsi.Task(None, iscsi.SCSI_XFER_READ, 96)
