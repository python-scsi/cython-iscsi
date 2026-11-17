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
        context.set_header_digest(iscsi.iscsi_header_digest.ISCSI_HEADER_DIGEST_NONE)

    def test_set_isid(self):
        context = iscsi.Context("foobar")
        context.set_isid_oui(0x001405, 0x0)
        context.set_isid_en(0x001405, 0x0)

    def test_command(self):
        context = iscsi.Context("foobar")
        task = iscsi.Task(
            b"\x12\x00\x00\x00\x60\x00", iscsi.scsi_xfer_dir.SCSI_XFER_READ, 96
        )
        data_in = bytearray(96)
        # Not connected, so the command can't be sent.
        with self.assertRaises(RuntimeError):
            context.command(0, task, None, data_in)

    def test_set_session_params(self):
        context = iscsi.Context("foobar")
        context.set_timeout(5)
        context.set_timeout(0)
        context.set_immediate_data(iscsi.iscsi_immediate_data.ISCSI_IMMEDIATE_DATA_NO)
        context.set_initial_r2t(iscsi.iscsi_initial_r2t.ISCSI_INITIAL_R2T_YES)
        context.set_noautoreconnect(True)
        context.set_noautoreconnect(False)

    def test_not_logged_in(self):
        context = iscsi.Context("foobar")
        self.assertFalse(context.is_logged_in)

    def test_ops_without_session_raise(self):
        context = iscsi.Context("foobar")
        for op in (
            context.logout,
            context.target_warm_reset,
            context.target_cold_reset,
            lambda: context.lun_reset(0),
            lambda: context.abort_task_set(0),
        ):
            with self.assertRaises(RuntimeError) as cm:
                op()
            # The libiscsi error string is included in the message.
            self.assertNotIn("unknown error", str(cm.exception))

    def test_connect_error_message(self):
        context = iscsi.Context("foobar")
        context.set_targetname("my-target")
        with self.assertRaises(RuntimeError) as cm:
            context.connect("not a portal", 0)
        self.assertIn(":", str(cm.exception))

    def test_url_outlives_context_reference(self):
        context = iscsi.Context("foobar")
        url = iscsi.URL(context, "iscsi://localhost/my-target/0")
        del context
        self.assertEqual(url.target, "my-target")
        del url

    def test_dealloc(self):
        for _ in range(1000):
            context = iscsi.Context("foobar")
            iscsi.URL(context, "iscsi://localhost/my-target/0")
            iscsi.Task(b"\x00" * 6, iscsi.scsi_xfer_dir.SCSI_XFER_NONE, 0)


class TaskTest(unittest.TestCase):
    def test_basic(self):
        task = iscsi.Task(
            b"\x12\x00\x00\x00\x60\x00", iscsi.scsi_xfer_dir.SCSI_XFER_READ, 96
        )
        self.assertIsNotNone(task)

    def test_bytearray(self):
        task = iscsi.Task(
            bytearray(b"\x12\x00\x00\x00\x60\x00"),
            iscsi.scsi_xfer_dir.SCSI_XFER_READ,
            96,
        )
        self.assertIsNotNone(task)

    def test_empty_cdb(self):
        with self.assertRaises(ValueError):
            iscsi.Task(None, iscsi.scsi_xfer_dir.SCSI_XFER_READ, 96)
