# cython: language_level=3

# SPDX-FileCopyrightText: 2014 The cython-iscsi Authors
#
# SPDX-License-Identifier: LGPL-2.1-or-later

cimport cython
from cpython.bytes cimport PyBytes_FromStringAndSize
from libc.stdint cimport uint32_t
from libc.stdlib cimport calloc


cdef extern from "iscsi/scsi-lowlevel.h":
    cpdef enum scsi_xfer_dir:
        SCSI_XFER_NONE
        SCSI_XFER_READ
        SCSI_XFER_WRITE

    cdef struct scsi_data:
        int size
        char *data

    cdef struct scsi_task:
        scsi_data datain

    cdef struct scsi_sense:
        pass

    scsi_task *scsi_create_task(
        int cdb_size, unsigned char *cdb, int xfer_dir, int expxferlen)
    void scsi_free_scsi_task(scsi_task *task)


cdef extern from "iscsi/iscsi.h":
    cpdef enum iscsi_immediate_data:
        ISCSI_IMMEDIATE_DATA_NO
        ISCSI_IMMEDIATE_DATA_YES

    cpdef enum iscsi_initial_r2t:
        ISCSI_INITIAL_R2T_NO
        ISCSI_INITIAL_R2T_YES

    cpdef enum iscsi_session_type:
        ISCSI_SESSION_DISCOVERY
        ISCSI_SESSION_NORMAL

    cpdef enum iscsi_header_digest:
        ISCSI_HEADER_DIGEST_NONE
        ISCSI_HEADER_DIGEST_NONE_CRC32C
        ISCSI_HEADER_DIGEST_CRC32C_NONE
        ISCSI_HEADER_DIGEST_CRC32C
        ISCSI_HEADER_DIGEST_LAST

    cdef struct iscsi_context:
        pass

    cdef struct iscsi_url:
        char portal[256]
        char target[256]
        char user[256]
        char passwd[256]
        int lun
        iscsi_context *iscsi

    cdef struct iscsi_data:
        pass

    cdef struct iscsi_target_portal:
        iscsi_target_portal *next
        char *portal

    cdef struct iscsi_discovery_address:
        iscsi_discovery_address *next
        char *target_name
        iscsi_target_portal *portals

    cdef iscsi_context *iscsi_create_context(const char *initiator_name)
    cdef int iscsi_destroy_context(iscsi_context *iscsi)
    cdef const char *iscsi_get_error(iscsi_context *iscsi)
    cdef iscsi_url *iscsi_parse_full_url(iscsi_context *iscsi, const char* url)
    cdef void iscsi_destroy_url(iscsi_url *iscsi_url)
    cdef int iscsi_set_targetname(iscsi_context *iscsi, const char *targetname)
    cdef int iscsi_set_session_type(iscsi_context *iscsi, iscsi_session_type session_type)
    cdef int iscsi_set_header_digest(iscsi_context *iscsi, iscsi_header_digest header_digest)
    cdef int iscsi_set_initiator_username_pwd(iscsi_context *iscsi, const char *user, const char *passwd)
    cdef int iscsi_set_target_username_pwd(iscsi_context *iscsi, const char *user, const char *passwd)
    cdef int iscsi_set_isid_oui(iscsi_context *iscsi, uint32_t oui, uint32_t qualifier)
    cdef int iscsi_set_isid_en(iscsi_context *iscsi, uint32_t en, uint32_t qualifier)
    cdef int iscsi_set_timeout(iscsi_context *iscsi, int timeout)
    cdef int iscsi_set_immediate_data(iscsi_context *iscsi, iscsi_immediate_data immediate_data)
    cdef int iscsi_set_initial_r2t(iscsi_context *iscsi, iscsi_initial_r2t initial_r2t)
    cdef int iscsi_full_connect_sync(iscsi_context *iscsi, const char *portal, int lun)
    cdef int iscsi_is_logged_in(iscsi_context *iscsi)
    cdef int iscsi_logout_sync(iscsi_context *iscsi)
    cdef int iscsi_disconnect(iscsi_context *iscsi)

    cdef int scsi_task_add_data_in_buffer(scsi_task *task, int len, unsigned char *buf)
    cdef int scsi_task_add_data_out_buffer(scsi_task *task, int len, unsigned char *buf)

    cdef scsi_task *iscsi_scsi_command_sync(
        iscsi_context *iscsi, int lun, scsi_task *task, iscsi_data *data)
    cdef int scsi_task_get_status(scsi_task *task, scsi_sense *sense)

    cdef iscsi_discovery_address *iscsi_discovery_sync(iscsi_context *iscsi)
    cdef void iscsi_free_discovery_data(iscsi_context *iscsi, iscsi_discovery_address *da)

    cdef int iscsi_task_mgmt_abort_task_set_sync(iscsi_context *iscsi, uint32_t lun)
    cdef int iscsi_task_mgmt_lun_reset_sync(iscsi_context *iscsi, uint32_t lun)
    cdef int iscsi_task_mgmt_target_warm_reset_sync(iscsi_context *iscsi)
    cdef int iscsi_task_mgmt_target_cold_reset_sync(iscsi_context *iscsi)

# iscsi_set_noautoreconnect() only appears in the public iscsi.h from
# libiscsi 1.19, but the library has exported it (libiscsi.syms) with this
# signature since well before 1.13, so declare it ourselves.  On 1.19+ this
# is just a compatible redeclaration of the header's prototype.
cdef extern from *:
    """
    struct iscsi_context;
    void iscsi_set_noautoreconnect(struct iscsi_context *iscsi, int state);
    """
    void iscsi_set_noautoreconnect(iscsi_context *iscsi, int state)

cdef class Task:
    cdef scsi_task *_task

    def __cinit__(self):
        self._task = NULL

    def __dealloc__(self):
        # Frees the task and any libiscsi-allocated memory hanging off it
        # (e.g. the datain/sense buffer).  The data_in/data_out buffers
        # passed to Context.command() are owned by Python and untouched.
        if self._task is not NULL:
            scsi_free_scsi_task(self._task)
            self._task = NULL

    def __init__(
            self,
            const unsigned char [::1] cdb,
            scsi_xfer_dir direction,
            size_t xferlen):
        if cdb is None or len(cdb) == 0:
            raise ValueError("Empty CDB when creating task.")
        if self._task is not NULL:
            scsi_free_scsi_task(self._task)
        self._task = scsi_create_task(len(cdb), &cdb[0], direction, xferlen)
        if self._task is NULL:
            raise MemoryError("Unable to allocate SCSI task.")

    @property
    def status(self):
        return scsi_task_get_status(self._task, NULL)

    @property
    def raw_sense(self):
        return PyBytes_FromStringAndSize(&self._task.datain.data[2], self._task.datain.size-2)

cdef class Context:
    cdef iscsi_context *_ctx

    def __cinit__(self):
        self._ctx = NULL

    def __dealloc__(self):
        # iscsi_destroy_context() closes the socket without sending a Logout,
        # so a Context that is garbage-collected while still logged in looks
        # like an unclean connection drop to the target -- the same as
        # disconnect().  Call logout() first for a clean shutdown.
        if self._ctx is not NULL:
            iscsi_destroy_context(self._ctx)
            self._ctx = NULL

    def __init__(self, str initiator_name):
        if self._ctx is not NULL:
            iscsi_destroy_context(self._ctx)
        self._ctx = iscsi_create_context(initiator_name.encode('utf-8'))
        if not self._ctx:
            raise ValueError("Invalid initiator name: %s" % initiator_name)

    cdef str _error(self):
        cdef const char *err = iscsi_get_error(self._ctx)
        if err is NULL or err[0] == 0:
            return "unknown error"
        return err.decode('utf-8', 'replace')

    @property
    def error(self):
        """The most recent error message recorded by libiscsi."""
        return self._error()

    @property
    def is_logged_in(self):
        return bool(iscsi_is_logged_in(self._ctx))

    def set_targetname(self, str targetname):
        if iscsi_set_targetname(self._ctx, targetname.encode('utf-8')) < 0:
            raise ValueError("Invalid target name: %s: %s" % (targetname, self._error()))

    def set_session_type(self, iscsi_session_type session_type):
        if iscsi_set_session_type(self._ctx, session_type) < 0:
            raise ValueError("Invalid session type: %s: %s" % (session_type, self._error()))

    def set_header_digest(self, iscsi_header_digest header_digest):
        if iscsi_set_header_digest(self._ctx, header_digest) < 0:
            raise ValueError("Invalid header digest: %s: %s" % (header_digest, self._error()))

    def set_initiator_username_pwd(self, str user, str passwd):
        if iscsi_set_initiator_username_pwd(self._ctx, user.encode('utf-8'), passwd.encode('utf-8')) < 0:
            raise ValueError("Invalid initiator user/pass: %s: %s" % (user, self._error()))

    def set_target_username_pwd(self, str user, str passwd):
        if iscsi_set_target_username_pwd(self._ctx, user.encode('utf-8'), passwd.encode('utf-8')) < 0:
            raise ValueError("Invalid target user/pass: %s: %s" % (user, self._error()))

    def set_isid_oui(self, uint32_t oui, uint32_t qualifier):
        if iscsi_set_isid_oui(self._ctx, oui, qualifier) < 0:
            raise ValueError("Invalid ISID OUI/qualifier: %#x/%#x: %s" % (oui, qualifier, self._error()))

    def set_isid_en(self, uint32_t en, uint32_t qualifier):
        if iscsi_set_isid_en(self._ctx, en, qualifier) < 0:
            raise ValueError("Invalid ISID EN/qualifier: %#x/%#x: %s" % (en, qualifier, self._error()))

    def set_timeout(self, int timeout):
        """Set the timeout, in seconds, for subsequent sync calls.

        0 (the default) means wait forever.
        """
        if iscsi_set_timeout(self._ctx, timeout) < 0:
            raise ValueError("Invalid timeout: %d: %s" % (timeout, self._error()))

    def set_immediate_data(self, iscsi_immediate_data immediate_data):
        """Set the ImmediateData value to offer at login."""
        if iscsi_set_immediate_data(self._ctx, immediate_data) < 0:
            raise ValueError("Invalid immediate data: %s: %s" % (immediate_data, self._error()))

    def set_initial_r2t(self, iscsi_initial_r2t initial_r2t):
        """Set the InitialR2T value to offer at login."""
        if iscsi_set_initial_r2t(self._ctx, initial_r2t) < 0:
            raise ValueError("Invalid initial R2T: %s: %s" % (initial_r2t, self._error()))

    def set_noautoreconnect(self, bint state):
        """Disable (True) or re-enable (False) automatic session reconnect.

        By default libiscsi transparently reconnects and logs back in if the
        session drops, which can hide target-side session loss from a test.
        """
        iscsi_set_noautoreconnect(self._ctx, state)

    def connect(self, str portal, int lun):
        if iscsi_full_connect_sync(self._ctx, portal.encode('utf-8'), lun) < 0:
            raise RuntimeError("Unable to connect to %s: %s" % (portal, self._error()))

    def logout(self):
        """Send an iSCSI Logout and wait for the response.

        This does not close the TCP connection; call disconnect() afterwards.
        """
        if iscsi_logout_sync(self._ctx) < 0:
            raise RuntimeError("Logout failed: %s" % self._error())

    def disconnect(self):
        """Close the TCP connection.

        If still logged in, no Logout is sent, so the target sees an unclean
        connection drop.  Call logout() first for a clean shutdown.
        """
        if iscsi_disconnect(self._ctx) < 0:
            raise RuntimeError("Disconnection error: %s" % self._error())

    def abort_task_set(self, int lun):
        if iscsi_task_mgmt_abort_task_set_sync(self._ctx, lun) < 0:
            raise RuntimeError("ABORT TASK SET failed for lun %d: %s" % (lun, self._error()))

    def lun_reset(self, int lun):
        if iscsi_task_mgmt_lun_reset_sync(self._ctx, lun) < 0:
            raise RuntimeError("LUN RESET failed for lun %d: %s" % (lun, self._error()))

    def target_warm_reset(self):
        if iscsi_task_mgmt_target_warm_reset_sync(self._ctx) < 0:
            raise RuntimeError("TARGET WARM RESET failed: %s" % self._error())

    def target_cold_reset(self):
        if iscsi_task_mgmt_target_cold_reset_sync(self._ctx) < 0:
            raise RuntimeError("TARGET COLD RESET failed: %s" % self._error())

    def command(self, int lun, Task task, bytearray data_out, bytearray data_in):
        # Get the data in/out bytearrays here so that Python can't change them.
        cdef unsigned char[:] data_out_view = data_out
        cdef unsigned char[:] data_in_view = data_in

        if data_out is not None and len(data_out):
            if scsi_task_add_data_out_buffer(task._task, len(data_out), &data_out_view[0]) < 0:
                raise ValueError("Invalid data_out argument.")
        if data_in is not None and len(data_in):
            if scsi_task_add_data_in_buffer(task._task, len(data_in), &data_in_view[0]) < 0:
                raise ValueError("Invalid data_in argument.")

        # A NULL return means the command was never sent (e.g. not logged
        # in).  The task status would still read as GOOD, so raise instead.
        # Transport errors after sending are reported via task.status.
        if iscsi_scsi_command_sync(self._ctx, lun, task._task, NULL) is NULL:
            raise RuntimeError("SCSI command failed: %s" % self._error())

    def discover(self):
        _da = iscsi_discovery_sync(self._ctx)
        result = {}
        da = _da
        while da:
            portals = []
            dp = da.portals
            while dp:
                portals.append(dp.portal.decode('utf-8'))
                dp = dp.next
            result[da.target_name.decode('utf-8')] = portals
            da = da.next
        iscsi_free_discovery_data(self._ctx, _da)
        return result

# no_gc_clear: if a URL ends up in a reference cycle, the GC must not drop
# _ctx before __dealloc__ has returned the URL to the context.
@cython.no_gc_clear
cdef class URL:
    cdef iscsi_url *_url
    # The URL is allocated from (and freed back to) the context, so keep the
    # Context alive for as long as the URL exists.
    cdef Context _ctx

    def __cinit__(self):
        self._url = NULL

    def __dealloc__(self):
        if self._url is not NULL:
            iscsi_destroy_url(self._url)
            self._url = NULL

    def __init__(self, Context ctx, str url_str):
        if self._url is not NULL:
            iscsi_destroy_url(self._url)
            self._url = NULL
        self._ctx = ctx
        self._url = iscsi_parse_full_url(ctx._ctx, url_str.encode('utf-8'))
        if not self._url:
            raise ValueError("URL parsing failed: %s: %s" % (url_str, ctx._error()))

    @property
    def portal(self):
        return self._url.portal.decode('utf-8')

    @property
    def target(self):
        return self._url.target.decode('utf-8')

    @property
    def user(self):
        return self._url.user.decode('utf-8')

    @property
    def passwd(self):
        return self._url.passwd.decode('utf-8')

    @property
    def lun(self):
        return self._url.lun
