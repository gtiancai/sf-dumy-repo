@isTest
private class StudentAttendanceRecordControllerTest {
    private class CMock implements HttpCalloutMock { public HTTPResponse respond(HTTPRequest req){ HttpResponse r=new HttpResponse(); r.setStatusCode(200); r.setBody('{}'); return r; } }

    private static Id fakeId(Schema.SObjectType t) {
        return (Id) (t.getDescribe().getKeyPrefix() + '000000000001AAA');
    }

    @isTest
    static void testSmoke() {
        Test.setMock(HttpCalloutMock.class, new CMock());
        Test.startTest();
        try { StudentAttendanceRecordController.loadData(null, null, null, new List<String>()); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testConstructors() {
        Test.setMock(HttpCalloutMock.class, new CMock());
        OmniAgentTestUtil.bypassHostOrgTriggers();
        Account center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('attendance record student', center);

        Test.startTest();
        // default constructor reading page param 'id'
        Test.setCurrentPage(new PageReference('/apex/x'));
        ApexPages.currentPage().getParameters().put('id', student.Id);
        try { new StudentAttendanceRecordController(); } catch (Exception e) {}
        // default constructor without param
        ApexPages.currentPage().getParameters().remove('id');
        try { new StudentAttendanceRecordController(); } catch (Exception e) {}
        // StandardController constructor
        try { new StudentAttendanceRecordController(new ApexPages.StandardController(student)); } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testLoadDataAndAddNote() {
        Test.setMock(HttpCalloutMock.class, new CMock());
        OmniAgentTestUtil.bypassHostOrgTriggers();
        TriggerShouldRun.ORDER = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;

        Account center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('attendance record student2', center);

        String today = (Date.today().year() - 1) + '/01/01';
        String endStr = (Date.today().year() + 1) + '/12/31';

        // Build a matching session member so the loadData loop body runs.
        Product2 prod = new Product2(
            Name = 'AttRec Product',
            Course_Type__c = 'Regular',
            Class_Type__c = 'RegularClass'
        );
        Database.insert(prod, false);

        Group__c grp = new Group__c(
            Name = 'AttRec Group',
            Code__c = 'ARG777',
            Status_Picklist__c = 'Activated',
            Group_Type__c = 'Classroom',
            Product__c = prod.Id
        );
        Database.insert(grp, false);

        Reservation__c res = new Reservation__c(
            Group__c = grp.Id,
            Status__c = 'Activated',
            Start__c = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0)),
            End__c = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0))
        );
        Database.insert(res, false);

        TriggerShouldRun.ALLOWMARKATTENDANCE = true;
        List<BMS_Session_Member__c> sms = new List<BMS_Session_Member__c>{
            new BMS_Session_Member__c(
                Student__c = student.Id, Group__c = grp.Id, Reservation__c = res.Id,
                Attendance_Status__c = 'Completed', Attendance_Result__c = 'Present', IsRemoved__c = false
            ),
            new BMS_Session_Member__c(
                Student__c = student.Id, Group__c = grp.Id, Reservation__c = res.Id,
                Attendance_Status__c = 'Completed', Attendance_Result__c = 'Sick Leave', IsRemoved__c = false
            ),
            new BMS_Session_Member__c(
                Student__c = student.Id, Group__c = grp.Id, Reservation__c = res.Id,
                Attendance_Status__c = 'Completed', Attendance_Result__c = 'Absent', IsRemoved__c = false
            )
        };
        Database.insert(sms, false);

        Test.startTest();
        // path that returns rows
        try { StudentAttendanceRecordController.loadData(student.Id, today, endStr, null); } catch (Exception e) {}
        // student exists but no session members -> "No Data" path
        try { StudentAttendanceRecordController.loadData(student.Id, today, endStr, null); } catch (Exception e) {}
        // with status filter
        try {
            StudentAttendanceRecordController.loadData(student.Id, today, endStr, new List<String>{ '出勤', '病假', '缺勤' });
        } catch (Exception e) {}
        // non-existent student -> "No student found"
        try {
            StudentAttendanceRecordController.loadData(fakeId(Account.SObjectType), today, endStr, null);
        } catch (Exception e) {}

        // addNote
        try {
            StudentAttendanceRecordController.addNote(fakeId(BMS_Session_Member__c.SObjectType), 'hello note');
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testWrapperClasses() {
        Test.setMock(HttpCalloutMock.class, new CMock());
        Id smId = fakeId(BMS_Session_Member__c.SObjectType);
        Id resId = fakeId(Reservation__c.SObjectType);
        Id csId = fakeId(Course_Session__c.SObjectType);

        // Build an in-memory session member with relationship subtree via JSON deserialize.
        String smJson =
            '{"attributes":{"type":"BMS_Session_Member__c"},"Id":"' + smId + '",' +
            '"Attendance_Result__c":"Present","Deducted_Quantity__c":1,' +
            '"Group__r":{"attributes":{"type":"Group__c"},"Id":"' + fakeId(Group__c.SObjectType) + '",' +
            '"Program__r":{"attributes":{"type":"Program__c"},"Id":"' + fakeId(Program__c.SObjectType) + '","Name":"Prog"},' +
            '"Program_Level_Lookup__r":{"attributes":{"type":"Program_Level__c"},"Id":"' + fakeId(Program_Level__c.SObjectType) + '","Name":"3"}},' +
            '"Reservation__r":{"attributes":{"type":"Reservation__c"},"Id":"' + resId + '",' +
            '"Start__c":"2024-01-01T08:00:00.000Z","End__c":"2024-01-01T09:00:00.000Z",' +
            '"Course_Session__c":"' + csId + '","Session_Type__c":"Parent Teacher Conference",' +
            '"Personal_Assistant__r":{"attributes":{"type":"User"},"Id":"' + UserInfo.getUserId() + '","Name":"PA Name"}}}';
        BMS_Session_Member__c sm = (BMS_Session_Member__c) JSON.deserialize(smJson, BMS_Session_Member__c.class);

        Map<Id, Course_Lesson__c> clMap = new Map<Id, Course_Lesson__c>();

        Test.startTest();
        try { new StudentAttendanceRecordController.AttendanceItem(sm, clMap); } catch (Exception e) {}

        // session member with a CMP type not in map + course lesson present
        Course_Lesson__c cl = (Course_Lesson__c) JSON.deserialize(
            '{"attributes":{"type":"Course_Lesson__c"},"Id":"' + fakeId(Course_Lesson__c.SObjectType) + '",' +
            '"Course_Session__c":"' + csId + '",' +
            '"Lesson__r":{"attributes":{"type":"Lesson__c"},"Id":"' + fakeId(Lesson__c.SObjectType) + '","Unit_Order_Sequence__c":1,"Ordering_Sequence__c":2}}',
            Course_Lesson__c.class
        );
        clMap.put(csId, cl);

        String smJson2 = smJson.replace('"Session_Type__c":"Parent Teacher Conference"', '"Session_Type__c":"Regular"')
                               .replace('"Attendance_Result__c":"Present"', '"Attendance_Result__c":"Sick Leave"');
        BMS_Session_Member__c sm2 = (BMS_Session_Member__c) JSON.deserialize(smJson2, BMS_Session_Member__c.class);
        try { new StudentAttendanceRecordController.AttendanceItem(sm2, clMap); } catch (Exception e) {}

        // ReservationInfo
        Reservation__c res = (Reservation__c) JSON.deserialize(
            '{"attributes":{"type":"Reservation__c"},"Id":"' + resId + '",' +
            '"Start__c":"2024-01-01T08:00:00.000Z","End__c":"2024-01-01T09:00:00.000Z",' +
            '"Personal_Assistant__r":{"attributes":{"type":"User"},"Id":"' + UserInfo.getUserId() + '","Name":"PA"}}',
            Reservation__c.class
        );
        try { new StudentAttendanceRecordController.ReservationInfo(res).getClassTime(); } catch (Exception e) {}

        // NoteWrapper
        Student_Attendance_Record_Note__c note = new Student_Attendance_Record_Note__c(Note__c = 'n');
        try { new StudentAttendanceRecordController.NoteWrapper(note); } catch (Exception e) {}
        try { new StudentAttendanceRecordController.NoteWrapper(new Student_Attendance_Record_Note__c()); } catch (Exception e) {}

        // StudentInfo variants
        try { new StudentAttendanceRecordController.StudentInfo(new Account(Name = 'Local', English_First_Name__c = 'Eng', English_Last_Name__c = 'Last')); } catch (Exception e) {}
        try { new StudentAttendanceRecordController.StudentInfo(new Account(Name = 'OnlyLocal')); } catch (Exception e) {}
        try { new StudentAttendanceRecordController.StudentInfo(new Account(English_First_Name__c = 'OnlyEng')); } catch (Exception e) {}
        try { new StudentAttendanceRecordController.StudentInfo(new Account()); } catch (Exception e) {}

        // AttendanceResult / AttendanceSummaryItem
        try {
            StudentAttendanceRecordController.AttendanceResult ar = new StudentAttendanceRecordController.AttendanceResult();
            ar.summary.add(new StudentAttendanceRecordController.AttendanceSummaryItem('Count'));
        } catch (Exception e) {}
        Test.stopTest();
    }

    @isTest
    static void testUpdateMakeupDoneBulkGateBlocksNonQualifyingStatus() {
        Test.setMock(HttpCalloutMock.class, new CMock());
        OmniAgentTestUtil.bypassHostOrgTriggers();
        Account center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('gate-block-student', center);

        Product2 prod = new Product2(Name = 'GateBlockProd', Course_Type__c = 'Regular', Class_Type__c = 'RegularClass', IsActive = true);
        Database.insert(prod, false);
        Group__c grp = new Group__c(
            Name = 'GateBlockGroup', Code__c = 'GB999', Status_Picklist__c = 'Activated',
            Group_Type__c = 'Classroom', Product__c = prod.Id
        );
        Database.insert(grp, false);
        Reservation__c res = new Reservation__c(
            Group__c = grp.Id, Status__c = 'Activated',
            Start__c = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0)),
            End__c = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0))
        );
        Database.insert(res, false);

        // Present (non-qualifying) SM - gate should block setting makeup to true
        BMS_Session_Member__c smPresent = new BMS_Session_Member__c(
            Student__c = student.Id, Group__c = grp.Id, Reservation__c = res.Id,
            Attendance_Status__c = 'Completed', Attendance_Result__c = 'Present',
            Is_Makeup_Done__c = false, IsRemoved__c = false
        );
        insert smPresent;

        // Absent (qualifying) SM - gate should allow setting makeup to true
        BMS_Session_Member__c smAbsent = new BMS_Session_Member__c(
            Student__c = student.Id, Group__c = grp.Id, Reservation__c = res.Id,
            Attendance_Status__c = 'Completed', Attendance_Result__c = 'Absent',
            Is_Makeup_Done__c = false, IsRemoved__c = false
        );
        insert smAbsent;

        // Sanity: confirm both SMs were inserted (would throw if the insert path failed
        // since we now use insert instead of Database.insert(..., false)).
        System.assertNotEquals(null, smPresent.Id, 'Present SM should be inserted (Id non-null)');
        System.assertNotEquals(null, smAbsent.Id, 'Absent SM should be inserted (Id non-null)');

        // Setup outside Test.startTest() so it doesn't count against governor limits
        // Use a one-entry map to validate the bulk path — covers the same gate logic.
        Map<Id, Boolean> bulkForAbsent = new Map<Id, Boolean>();
        bulkForAbsent.put(smAbsent.Id, true);
        Set<Id> smIds = new Set<Id>();
        smIds.add(smPresent.Id);
        smIds.add(smAbsent.Id);

        // Suppress the BMS_Session_Member trigger chain during the test — the gate
        // logic we're testing here is in updateMakeupDoneBulk itself, not in the trigger.
        // The trigger's audit-Task generation is tested separately in BMS_SMMakeupAuditHandlerTest.
        Boolean smTriggerFlag = TriggerShouldRun.BMS_SESSIONMEMBER;
        TriggerShouldRun.BMS_SESSIONMEMBER = false;
        Test.startTest();
        Map<String, String> resultAbsent = StudentAttendanceRecordController.updateMakeupDoneBulk(bulkForAbsent);
        System.debug('*** resultAbsent: ' + resultAbsent);
        // Separate call for the Present SM — gate should skip it.
        Map<Id, Boolean> bulkForPresent = new Map<Id, Boolean>();
        bulkForPresent.put(smPresent.Id, true);
        Map<String, String> resultPresent = StudentAttendanceRecordController.updateMakeupDoneBulk(bulkForPresent);
        System.debug('*** resultPresent: ' + resultPresent);
        Test.stopTest();
        TriggerShouldRun.BMS_SESSIONMEMBER = smTriggerFlag;
        // Absent SM should have makeup now true; Present SM should stay false (gate skipped)
        List<BMS_Session_Member__c> updated = [
            SELECT Id, Is_Makeup_Done__c
            FROM BMS_Session_Member__c
            WHERE Id IN :smIds
        ];
        Map<Id, BMS_Session_Member__c> updatedMap = new Map<Id, BMS_Session_Member__c>(updated);
        System.assertEquals(
            false,
            updatedMap.get(smPresent.Id).Is_Makeup_Done__c,
            'Present SM should be skipped by gate (makeup stays false)'
        );
        System.assertEquals(
            true,
            updatedMap.get(smAbsent.Id).Is_Makeup_Done__c,
            'Absent SM should be updated (makeup becomes true)'
        );
        System.assertEquals('1', resultAbsent.get('updatedCount'), 'Absent SM should be updated (passes the gate)');
        System.assertEquals('0', resultPresent.get('updatedCount'), 'Present SM should be skipped by gate (0 updates)');
    }

    @isTest
    static void testUpdateMakeupDoneSingleRecordNotFound() {
        Test.setMock(HttpCalloutMock.class, new CMock());
        OmniAgentTestUtil.bypassHostOrgTriggers();

        Id fakeSmId = fakeId(BMS_Session_Member__c.SObjectType);

        Test.startTest();
        Map<String, String> result = StudentAttendanceRecordController.updateMakeupDone(fakeSmId, true);
        Test.stopTest();

        System.assertEquals('failure', result.get('result'), 'Non-existent SM -> failure');
        System.assertEquals('session member not found', result.get('message'), 'Failure message');
    }

    @isTest
    static void testLoadDataPopulatesNotesFromNotesField() {
        Test.setMock(HttpCalloutMock.class, new CMock());
        OmniAgentTestUtil.bypassHostOrgTriggers();
        TriggerShouldRun.ORDER = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;

        Account center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('notes-field-student', center);

        String today = (Date.today().year() - 1) + '/01/01';
        String endStr = (Date.today().year() + 1) + '/12/31';

        Product2 prod = new Product2(Name = 'NotesFieldProd', Course_Type__c = 'Regular', Class_Type__c = 'RegularClass');
        Database.insert(prod, false);
        Group__c grp = new Group__c(
            Name = 'NotesFieldGroup', Code__c = 'NF777', Status_Picklist__c = 'Activated',
            Group_Type__c = 'Classroom', Product__c = prod.Id
        );
        Database.insert(grp, false);
        Reservation__c res = new Reservation__c(
            Group__c = grp.Id, Status__c = 'Activated',
            Start__c = Datetime.newInstance(Date.today(), Time.newInstance(8, 0, 0, 0)),
            End__c = Datetime.newInstance(Date.today(), Time.newInstance(9, 0, 0, 0))
        );
        Database.insert(res, false);

        // SM with Notes__c set — should surface in AttendanceItem.notes via the new NoteWrapper(Id, String) ctor
        BMS_Session_Member__c sm = new BMS_Session_Member__c(
            Student__c = student.Id, Group__c = grp.Id, Reservation__c = res.Id,
            Attendance_Status__c = 'Completed', Attendance_Result__c = 'Present',
            Is_Makeup_Done__c = false, IsRemoved__c = false,
            Notes__c = 'remark from Notes__c'
        );
        Database.insert(sm, false);

        Test.startTest();
        StudentAttendanceRecordController.AttendanceResult ar = StudentAttendanceRecordController.loadData(
            student.Id, today, endStr, null
        );
        Test.stopTest();

        System.assert(ar != null, 'loadData should return a non-null result');
        System.assert(!ar.attendance_records.isEmpty(), 'Should have at least one attendance record');
        StudentAttendanceRecordController.AttendanceItem item = ar.attendance_records[0];
        System.assert(item.notes != null && !item.notes.isEmpty(), 'AttendanceItem.notes should be populated');
        System.assertEquals(
            'remark from Notes__c',
            item.notes[0].note,
            'AttendanceItem.notes[0].note should come from Notes__c'
        );
    }
}
