/**
 * OMNI-70320
 * @description Shared helper for Attendance Makeup / Notes audit Task creation.
 *              Both the RemoteAction (StudentAttendanceRecordController.addNote / updateMakeupDoneBulk)
 *              and the trigger handlers (BMS_SessionMemberMakeupDoneAuditHandler /
 *              BMS_SessionMemberNotesSyncHandler) call this helper so Subject / Notes
 *              format / SKIP-flag wrap / Admin attribution stay in one place.
 */
public without sharing class AttendanceAuditTaskHelper {

    // ---- Subject vocabulary (Req 2 & 4 — literals) -------------------------------
    public static final String SUBJECT_MAKEUP_CHECK = '出勤记录 - 勾选已补课';
    public static final String SUBJECT_MAKEUP_UNCHECK = '出勤记录 - 取消已补课';
    public static final String SUBJECT_MAKEUP_AUTO_CLEAR = '出勤记录 - 自动清空已补课';
    public static final String SUBJECT_NOTE_ADD = '出勤记录 - 增加备注';

    public static final String TASK_CATEGORY_OTHER = 'Other';

    // ---- Build a makeup-done audit Task (Req 2) ---------------------------------
    /**
     * @description Build a makeup-done audit Task (Req 2). wasForcedClear=true ->
     *              Subject 自动清空已补课, OwnerId=Admin (Util.getE1AdminUserId()).
     *              wasForcedClear=false, newVal=true -> Subject 勾选已补课, OwnerId=current user.
     *              wasForcedClear=false, newVal=false -> Subject 取消已补课, OwnerId=current user.
     * @param sm            the session member (Group__r / Reservation__r must be queried)
     * @param wasForcedClear true if this is the system-forced-clear path (Req 1 bullet 2)
     * @param newVal        the new value of Is_Makeup_Done__c (ignored when wasForcedClear=true)
     * @return              a populated Task (not yet inserted); null if sm is null
     */
    public static Task buildMakeupAuditTask(
        BMS_Session_Member__c sm,
        Boolean wasForcedClear,
        Boolean newVal
    ) {
        if (sm == null) {
            return null;
        }

        Id studentId = sm.Student__c;
        Id adminUserId = Util.getE1AdminUserId();
        Id ownerId = wasForcedClear ? adminUserId : UserInfo.getUserId();

        String subject;
        String operationLine;
        if (wasForcedClear) {
            subject = SUBJECT_MAKEUP_AUTO_CLEAR;
            operationLine = '考勤状态变动，自动清空已补课';
        } else if (newVal == true) {
            subject = SUBJECT_MAKEUP_CHECK;
            operationLine = '操作：勾选已补课';
        } else {
            subject = SUBJECT_MAKEUP_UNCHECK;
            operationLine = '操作：取消已补课';
        }

        Task t = new Task();
        t.RecordTypeId = RecordTypeUtil.getRecordTypeId('Task', 'Student Notes');
        t.Subject = subject;
        t.WhatId = studentId;
        t.OwnerId = ownerId;
        t.Status = 'Completed';
        t.Priority = 'Normal';
        t.ActivityDate = System.today();
        t.Description = buildNotesField(sm, operationLine);
        t.Notes__c = truncateForNotes(t.Description);
        t.Category__c = TASK_CATEGORY_OTHER;
        return t;
    }

    // ---- Build a notes audit Task (Req 4) ---------------------------------------
    /**
     * @description Build a notes audit Task (Req 4). Always user-driven (no Admin path
     *              for notes edits) -> OwnerId=current user.
     * @param sm        the session member (Group__r / Reservation__r must be queried)
     * @param noteText  the user-entered note content for the 备注 line
     * @return          a populated Task (not yet inserted); null if sm is null
     */
    public static Task buildNoteAuditTask(
        BMS_Session_Member__c sm,
        String noteText
    ) {
        if (sm == null) {
            return null;
        }

        Id studentId = sm.Student__c;

        Task t = new Task();
        t.RecordTypeId = RecordTypeUtil.getRecordTypeId('Task', 'Student Notes');
        t.Subject = SUBJECT_NOTE_ADD;
        t.WhatId = studentId;
        t.OwnerId = UserInfo.getUserId();
        t.Status = 'Completed';
        t.Priority = 'Normal';
        t.ActivityDate = System.today();
        t.Description = buildNoteNotesField(sm, noteText);
        t.Notes__c = truncateForNotes(t.Description);
        t.Category__c = TASK_CATEGORY_OTHER;
        return t;
    }

    /**
     * @description Bulk insert audit Tasks with the SKIP-flag wrap (Q5 — matches
     *              OpportunityShortNoteHandler:75-79). Bypasses TaskAsyncTriggerHandler
     *              so the new 出勤记录 - … Subjects don't trigger short-note-prefix
     *              exclusion or any FCAT/LCAT downstream logic.
     * @param tasks the Tasks to insert (null/empty -> no-op)
     */
    public static void insertAuditTasks(List<Task> tasks) {
        if (tasks == null || tasks.isEmpty()) {
            return;
        }

        Boolean prevTaskFlag = TriggerShouldRun.TASK;
        Boolean prevSkip = TaskAsyncTriggerHandler.SKIP;
        try {
            TriggerShouldRun.TASK = false;
            TaskAsyncTriggerHandler.SKIP = true;
            insert tasks;
        } finally {
            TriggerShouldRun.TASK = prevTaskFlag;
            TaskAsyncTriggerHandler.SKIP = prevSkip;
        }
    }

    // ---- Notes field formatters --------------------------------------------------
    //  Lines: Group Name / Reservation / 上课时间 / 操作
    /**
     * @description Build the multi-line Notes field for makeup audit Tasks.
     *              Lines: Group Name / Reservation / 上课时间 / 操作
     * @param sm            the session member (Group__r / Reservation__r must be queried)
     * @param operationLine the 操作 line (varies by makeup action type)
     * @return              newline-joined Notes string
     */
    public static String buildNotesField(BMS_Session_Member__c sm, String operationLine) {
        List<String> lines = new List<String>{
            'Group Name: ' + safeStr(getGroupName(sm)),
            'Reservation: ' + safeStr(getReservationName(sm)),
            '上课时间: ' + safeStr(getClassTime(sm)),
            operationLine
        };
        return String.join(lines, '\n');
    }

    //  Lines: Group Name / Reservation / 上课时间 / 备注：<note>
    /**
     * @description Build the multi-line Notes field for notes audit Tasks.
     *              Lines: Group Name / Reservation / 上课时间 / 备注：<note>
     * @param sm        the session member (Group__r / Reservation__r must be queried)
     * @param noteText  the user-entered note content
     * @return          newline-joined Notes string
     */
    public static String buildNoteNotesField(BMS_Session_Member__c sm, String noteText) {
        List<String> lines = new List<String>{
            'Group Name: ' + safeStr(getGroupName(sm)),
            'Reservation: ' + safeStr(getReservationName(sm)),
            '上课时间: ' + safeStr(getClassTime(sm)),
            '备注：' + safeStr(noteText)
        };
        return String.join(lines, '\n');
    }

    // ---- Field extractors (null-safe; rely on Group__r / Reservation__r being queried) --
    private static String getGroupName(BMS_Session_Member__c sm) {
        return sm?.Group__r?.Name;
    }

    private static String getReservationName(BMS_Session_Member__c sm) {
        return sm?.Reservation__r?.Name;
    }

    private static String getClassTime(BMS_Session_Member__c sm) {
        Reservation__c resv = sm?.Reservation__r;
        if (resv == null || resv.Start__c == null || resv.End__c == null) {
            return '';
        }
        // Reuse controller's inner-class formatter (public + public ctor, callable here)
        StudentAttendanceRecordController.ReservationInfo info =
            new StudentAttendanceRecordController.ReservationInfo(resv);
        return info.getClassTime();
    }

    private static String truncateForNotes(String text) {
        if (String.isBlank(text)) {
            return '';
        }
        if (text.length() > 255) {
            return text.substring(0, 255);
        }
        return text;
    }

    private static String safeStr(String s) {
        return s == null ? '' : s;
    }
}
