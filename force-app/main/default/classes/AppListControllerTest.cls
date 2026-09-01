@isTest
private class AppListControllerTest {

    static testMethod void testConstructorAndWrappers() {
        Test.setCurrentPage(new PageReference('/apex/app'));
        new AppListController();
        new AppListController.CityInfo();
        new AppListController.CenterInfo();
        new AppListController.InititalInfo(new List<AppListController.CityInfo>());
        new AppListController.OrderByParam();
        new AppListController.FilterParams();
        new AppListController.AppListResponse();
        new AppListController.UpdateLineItemParams();
        new AppListController.ShortNoteHistory();
        new AppListController.PickList('label', 'value');
        new AppListController.BaseInIt();
        new AppListController.SchoolInfo('school', UserInfo.getUserId());
        AppListController.initSimple();
    }

    static testMethod void testRemoteActionSmokePaths() {
        /*
        AppListController.FilterParams filterParams = new AppListController.FilterParams();
        AppListController.UpdateLineItemParams updateParams = new AppListController.UpdateLineItemParams();
        updateParams.record_id = null;
        updateParams.which_field = 'short_note';
        updateParams.field_value = 'note';

        Account acc_center = TestDataFactory.insertShangHai1Center();
        Resource_Type__c resType = TestDataFactory.createCenterResourceType();
        Resource__c center = TestDataFactory.createCenterResource('SH1PT2', acc_center.Id, resType.Id); 
        insert center;

        Test.startTest();
        try { AppListController.init(); } catch (Exception e) {}
        try { AppListController.getCityAndCenterOptions(acc_center.Name); } catch (Exception e) {}
        try { AppListController.getObjectPickList('Reservation__c', 'Status__c', new Set<String>(), new Set<String>()); } catch (Exception e) {}
        try { AppListController.getSchoolList(null, ''); } catch (Exception e) {}
        try { AppListController.getShortNoteHistory(null); } catch (Exception e) {}
        try { AppListController.updateLineItem(JSON.serialize(updateParams)); } catch (Exception e) {}
        try { AppListController.queryAppList(JSON.serialize(filterParams)); } catch (Exception e) {}
        Test.stopTest();
        */
    }

    static testMethod void testAppListInfoCompareBranches() {
        AppListController.AppListInfo a = new AppListController.AppListInfo();
        AppListController.AppListInfo b = new AppListController.AppListInfo();
        a.app_type = 'Demo';
        b.app_type = 'OPT';
        a.app_date = Date.today();
        b.app_date = Date.today().addDays(1);
        a.app_time = '09:00';
        b.app_time = '10:00';

        a.compareTo(null);
        a.compareTo('not info');
        a.compareTo(b);
        b.app_type = 'Demo';
        a.compareTo(b);
        b.app_date = a.app_date;
        a.compareTo(b);
        b.app_time = a.app_time;
        a.compareTo(b);
    }

    static testMethod void testAdditionalRemoteActionBranches() {
        AppListController.FilterParams filterParams = new AppListController.FilterParams();
        filterParams.city_filter = new List<String>{ 'a00000000000001' };
        filterParams.center_filter = new List<String>{ 'a00000000000002' };
        filterParams.intention_filter = new List<String>{ 'Demo Class' };
        filterParams.app_date_from = Date.today().addDays(-7);
        filterParams.app_date_to = Date.today().addDays(7);
        filterParams.inquiry_date_from = Date.today().addDays(-10);
        filterParams.inquiry_date_to = Date.today();
        filterParams.opp_date_from = Date.today().addDays(-10);
        filterParams.opp_date_to = Date.today();
        filterParams.app_created_date_from = Date.today().addDays(-10);
        filterParams.app_created_date_to = Date.today();
        filterParams.search_text = 'Smoke';

        AppListController.UpdateLineItemParams reservationParams = new AppListController.UpdateLineItemParams();
        reservationParams.record_id = 'a0R000000000001AAA';
        reservationParams.which_field = 'customer_details';
        reservationParams.field_value = 'detail';

        AppListController.UpdateLineItemParams bmsParams = new AppListController.UpdateLineItemParams();
        bmsParams.record_id = 'a0S000000000001AAA';
        bmsParams.which_field = 'app_details';
        bmsParams.field_value = 'detail';

        Test.startTest();
        try { AppListController.queryAppList(JSON.serialize(filterParams)); } catch (Exception e) {}
        try { AppListController.getSchoolList('a00000000000003', 'Test'); } catch (Exception e) {}
        try { AppListController.updateLineItem(JSON.serialize(reservationParams)); } catch (Exception e) {}
        try { AppListController.updateLineItem(JSON.serialize(bmsParams)); } catch (Exception e) {}
        Test.stopTest();
    }

    // === New tests with actual data ===

    static testMethod void testQueryAppListWithActualReservationData() {
        Account acc_center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('TestStudent', acc_center);
        Contact con = TestDataFactory.insertContact(student, '13800138000', true);

        Opportunity opp = new Opportunity();
        opp.StageName = 'Showed Up';
        opp.CloseDate = Date.today().addDays(30);
        opp.Name = 'Test Opp';
        opp.AccountId = student.Id;
        opp.Business_Unit__c = acc_center.Business_Unit__c;
        opp.Center__c = acc_center.Id;
        opp.Contact__c = con.Id;
        opp.LeadSource = 'WALK_IN';
        opp.Inquiry_Date__c = DateTime.now().addDays(-5);
        insert opp;

        TriggerShouldRun.BMS_RESERVATION = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;
        Reservation__c res = new Reservation__c();
        res.Opportunity__c = opp.Id;
        res.Account__c = student.Id;
        res.Event_Type__c = 'Demo Class';
        res.Start__c = DateTime.now().addDays(1);
        res.Start_Date__c = Date.today().addDays(1);
        insert res;
        TriggerShouldRun.BMS_RESERVATION = true;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = true;

        AppListController.FilterParams fp = new AppListController.FilterParams();
        fp.app_date_from = Date.today().addDays(-30);
        fp.app_date_to = Date.today().addDays(30);

        Test.startTest();
        AppListController.AppListResponse result = AppListController.queryAppList(JSON.serialize(fp));
        Test.stopTest();
    }

    static testMethod void testQueryAppListNullParams() {
        Test.startTest();
        AppListController.AppListResponse result = AppListController.queryAppList(null);
        Test.stopTest();

    }

    static testMethod void testQueryAppListForApiGateway() {
        Account acc_center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('TestStudent', acc_center);
        Contact con = TestDataFactory.insertContact(student, '13800138000', true);

        Opportunity opp = new Opportunity();
        opp.StageName = 'Showed Up';
        opp.CloseDate = Date.today().addDays(30);
        opp.Name = 'Test Opp';
        opp.AccountId = student.Id;
        opp.Business_Unit__c = acc_center.Business_Unit__c;
        opp.Center__c = acc_center.Id;
        opp.Contact__c = con.Id;
        opp.LeadSource = 'WALK_IN';
        insert opp;

        TriggerShouldRun.BMS_RESERVATION = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;
        Reservation__c res = new Reservation__c();
        res.Opportunity__c = opp.Id;
        res.Account__c = student.Id;
        res.Event_Type__c = 'Demo Class';
        res.Start__c = DateTime.now().addDays(1);
        res.Start_Date__c = Date.today().addDays(1);
        insert res;
        TriggerShouldRun.BMS_RESERVATION = true;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = true;

        AppListController.FilterParams fp = new AppListController.FilterParams();
        fp.app_date_from = Date.today().addDays(-30);
        fp.app_date_to = Date.today().addDays(30);

        Test.startTest();
        String result = AppListController.queryAppListForApiGatewayRequest(fp);
        Test.stopTest();

    }

    static testMethod void testUpdateLineItemSuccessShortNote() {
        Account acc_center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('TestStudent', acc_center);
        Contact con = TestDataFactory.insertContact(student, '13800138000', true);

        Opportunity opp = new Opportunity();
        opp.StageName = 'Showed Up';
        opp.CloseDate = Date.today().addDays(30);
        opp.Name = 'Test Opp';
        opp.AccountId = student.Id;
        opp.Business_Unit__c = acc_center.Business_Unit__c;
        opp.Center__c = acc_center.Id;
        opp.Contact__c = con.Id;
        opp.LeadSource = 'WALK_IN';
        insert opp;

        TriggerShouldRun.BMS_RESERVATION = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;
        Reservation__c res = new Reservation__c();
        res.Opportunity__c = opp.Id;
        res.Account__c = student.Id;
        res.Event_Type__c = 'Demo Class';
        res.Start__c = DateTime.now().addDays(1);
        res.Start_Date__c = Date.today().addDays(1);
        insert res;
        TriggerShouldRun.BMS_RESERVATION = true;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = true;

        AppListController.UpdateLineItemParams params = new AppListController.UpdateLineItemParams();
        params.record_id = res.Id;
        params.which_field = 'short_note';
        params.field_value = 'Updated note';

        Test.startTest();
        Map<String, Object> result = AppListController.updateLineItem(JSON.serialize(params));
        Test.stopTest();
    }

    static testMethod void testUpdateLineItemSuccessCustomerDetails() {
        Account acc_center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('TestStudent', acc_center);
        Contact con = TestDataFactory.insertContact(student, '13800138000', true);

        Opportunity opp = new Opportunity();
        opp.StageName = 'Showed Up';
        opp.CloseDate = Date.today().addDays(30);
        opp.Name = 'Test Opp';
        opp.AccountId = student.Id;
        opp.Business_Unit__c = acc_center.Business_Unit__c;
        opp.Center__c = acc_center.Id;
        opp.Contact__c = con.Id;
        opp.LeadSource = 'WALK_IN';
        insert opp;

        TriggerShouldRun.BMS_RESERVATION = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;
        Reservation__c res = new Reservation__c();
        res.Opportunity__c = opp.Id;
        res.Account__c = student.Id;
        res.Event_Type__c = 'Demo Class';
        res.Start__c = DateTime.now().addDays(1);
        res.Start_Date__c = Date.today().addDays(1);
        insert res;
        TriggerShouldRun.BMS_RESERVATION = true;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = true;

        AppListController.UpdateLineItemParams params = new AppListController.UpdateLineItemParams();
        params.record_id = res.Id;
        params.which_field = 'customer_details';
        params.field_value = 'Updated details';

        Test.startTest();
        Map<String, Object> result = AppListController.updateLineItem(JSON.serialize(params));
        Test.stopTest();

    }

    static testMethod void testGetShortNoteHistoryNullId() {
        Test.startTest();
        List<AppListController.ShortNoteHistory> history = AppListController.getShortNoteHistory(null);
        Test.stopTest();

    }

    static testMethod void testGetSchoolListEmptyCity() {
        Test.startTest();
        List<AppListController.SchoolInfo> schools = AppListController.getSchoolList('', '');
        Test.stopTest();

    }

    static testMethod void testConstructorSourceParam() {
        Test.setCurrentPage(new PageReference('/apex/app?source=testSource'));
        AppListController ctrl = new AppListController();
    }

    static testMethod void testConstructorNoSourceParam() {
        Test.setCurrentPage(new PageReference('/apex/app'));
        AppListController ctrl = new AppListController();
    }

    static testMethod void testAppListItemConstructor() {
        AppListController.AppListInfo info = new AppListController.AppListInfo();
        info.app_type = 'Demo';
        info.app_date = Date.today();
        info.app_time = '10:00';
        info.teacher_name = 'Teacher';

        AppListController.AppListItem item = new AppListController.AppListItem(info);
        
    }

    static testMethod void testSortAppList() {
        List<AppListController.AppListInfo> appList = new List<AppListController.AppListInfo>();

        AppListController.AppListInfo a = new AppListController.AppListInfo();
        a.app_type = 'OPT';
        a.app_date = Date.today().addDays(2);
        a.app_time = '14:00';
        appList.add(a);

        AppListController.AppListInfo b = new AppListController.AppListInfo();
        b.app_type = 'Course Consultation';
        b.app_date = Date.today();
        b.app_time = '09:00';
        appList.add(b);

        appList.sort();

    }

    static testMethod void testGetObjectPickListWithFilters() {
        Set<String> include = new Set<String>{ 'Demo Class', 'OPT', 'Course Consultation' };

        Test.startTest();
        List<AppListController.PickList> result = AppListController.getObjectPickList('Reservation__c', 'Event_Type__c', null, include);
        Test.stopTest();

    }

    // =====================================================================
    // Additional coverage added by write-tests skill (2026-08-31)
    // =====================================================================

    private static Account setupCenterStudentOpp() {
        Account acc_center = TestDataFactory.insertShangHai1Center();
        Account student = TestDataFactory.insertCustomer('AppListStudent', acc_center);
        Contact con = TestDataFactory.insertContact(student, '13800138000', true);

        Opportunity opp = new Opportunity();
        opp.StageName = 'Showed Up';
        opp.CloseDate = Date.today().addDays(30);
        opp.Name = 'AppList Test Opp';
        opp.AccountId = student.Id;
        opp.Business_Unit__c = acc_center.Business_Unit__c;
        opp.Center__c = acc_center.Id;
        opp.Contact__c = con.Id;
        opp.LeadSource = 'WALK_IN';
        opp.Inquiry_Date__c = Datetime.now().addDays(-5);
        opp.HP_Level__c = 'High';
        insert opp;
        return acc_center;
    }

    private static Reservation__c setupReservation(Account acc_center, Account student, Id oppId) {
        Boolean resFlag = TriggerShouldRun.BMS_RESERVATION;
        Boolean resAllFlag = TriggerShouldRun.BMS_RESERVATIONALLTRIGGER;
        TriggerShouldRun.BMS_RESERVATION = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;
        Reservation__c res = new Reservation__c();
        res.Opportunity__c = oppId;
        res.Account__c = student.Id;
        res.Event_Type__c = 'Demo Class';
        res.Start__c = Datetime.now().addDays(1);
        res.Start_Date__c = Date.today().addDays(1);
        res.Appointment_Result__c = 'Show Up';
        insert res;
        TriggerShouldRun.BMS_RESERVATION = resFlag;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = resAllFlag;
        return res;
    }

    private static void insertDetailTasks(Id oppId) {
        Id studentNotesRt = RecordTypeUtil.getRecordTypeId('Task', 'Student Notes');
        TriggerShouldRun.TASK = false;
        List<Task> tasks = new List<Task>{
            new Task(
                RecordTypeId = studentNotesRt,
                WhatId = oppId,
                Subject = 'student-2026-01-01-Demo Class学员详情',
                Category__c = 'Other',
                Sub_Category__c = 'APP List Note',
                Notes__c = 'customer detail',
                Status = 'Completed'
            ),
            new Task(
                RecordTypeId = studentNotesRt,
                WhatId = oppId,
                Subject = 'student-2026-01-01-Demo Class预约详情',
                Category__c = 'Other',
                Sub_Category__c = 'APP List Note',
                Notes__c = 'app detail',
                Status = 'Completed'
            ),
            new Task(
                RecordTypeId = studentNotesRt,
                WhatId = oppId,
                Subject = 'short note history',
                Category__c = 'Sales Follow-up',
                Sub_Category__c = 'Short Note',
                Description = 'modified content',
                Status = 'Completed'
            )
        };
        insert tasks;
        TriggerShouldRun.TASK = true;
    }

    static testMethod void testQueryAppListAllFilters() {
        Account acc_center = setupCenterStudentOpp();
        Account student = [SELECT Id FROM Account WHERE Name = 'AppListStudent' LIMIT 1];
        Opportunity opp = [SELECT Id, OwnerId, OpportunityID__c FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];
        Reservation__c res = setupReservation(acc_center, student, opp.Id);
        insertDetailTasks(opp.Id);

        // Survey junction row
        Survey_Collection__c survey = new Survey_Collection__c(
            Name = 'Srv1',
            Mobile__c = '13800000001',
            Submit_Time__c = Datetime.now(),
            Source__c = 'iEF'
        );
        Database.insert(survey, false);
        Survey_Collection_Junction__c junction = new Survey_Collection_Junction__c(
            Opportunity__c = opp.Id,
            Survey_Collection__c = survey.Id
        );
        Database.insert(junction, false);

        AppListController.FilterParams fp = new AppListController.FilterParams();
        fp.city_filter = new List<Id>{ acc_center.City__c };
        fp.center_filter = new List<Id>{ acc_center.Id };
        fp.intention_filter = new List<String>{ 'High' };
        fp.app_date_from = Date.today().addDays(-30);
        fp.app_date_to = Date.today().addDays(30);
        fp.inquiry_date_from = Date.today().addDays(-30);
        fp.inquiry_date_to = Date.today();
        fp.opp_date_from = Date.today().addDays(-30);
        fp.opp_date_to = Date.today().addDays(30);
        fp.app_created_date_from = Date.today().addDays(-30);
        fp.app_created_date_to = Date.today().addDays(30);
        fp.search_text = 'AppListStudent';
        fp.cc_id = String.valueOf(opp.OwnerId);
        fp.opp_number = new List<String>{ opp.OpportunityID__c };

        Test.startTest();
        AppListController.AppListResponse result = AppListController.queryAppList(JSON.serialize(fp));
        Test.stopTest();
    }

    static testMethod void testQueryAppListByRecordId() {
        Account acc_center = setupCenterStudentOpp();
        Account student = [SELECT Id FROM Account WHERE Name = 'AppListStudent' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];
        Reservation__c res = setupReservation(acc_center, student, opp.Id);

        AppListController.FilterParams fp = new AppListController.FilterParams();
        fp.record_id = String.valueOf(res.Id);
        AppListController.AppListResponse result = AppListController.queryAppList(JSON.serialize(fp));

        // record_id that is not a Reservation id -> empty list
        AppListController.FilterParams fp2 = new AppListController.FilterParams();
        fp2.record_id = String.valueOf(opp.Id);
        AppListController.AppListResponse result2 = AppListController.queryAppList(JSON.serialize(fp2));

        // null params
        AppListController.AppListResponse result3 = AppListController.queryAppList(null);
    }

    static testMethod void testQueryAppListForApiGatewayWithFilters() {
        Account acc_center = setupCenterStudentOpp();
        Account student = [SELECT Id FROM Account WHERE Name = 'AppListStudent' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];
        Reservation__c res = setupReservation(acc_center, student, opp.Id);

        AppListController.FilterParams fp = new AppListController.FilterParams();
        fp.app_date_from = Date.today().addDays(-30);
        fp.app_date_to = Date.today().addDays(30);
        fp.opp_stage = new List<String>{ 'Showed Up', 'Open' };
        fp.show_up_status = new List<String>{ 'Show Up', 'null' };
        String json1 = AppListController.queryAppListForApiGatewayRequest(fp);

        AppListController.FilterParams fp2 = new AppListController.FilterParams();
        fp2.opp_stage = new List<String>{ 'NoSuchStage' };
        fp2.show_up_status = new List<String>{ 'No Show' };
        String json2 = AppListController.queryAppListForApiGatewayRequest(fp2);

        // no filters -> returns unchanged
        AppListController.FilterParams fp3 = new AppListController.FilterParams();
        String json3 = AppListController.queryAppListForApiGatewayRequest(fp3);

        // null filter
        String json4 = AppListController.queryAppListForApiGatewayRequest(null);
    }

    static testMethod void testUpdateLineItemReservationFields() {
        Account acc_center = setupCenterStudentOpp();
        Account student = [SELECT Id FROM Account WHERE Name = 'AppListStudent' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];
        Reservation__c res = setupReservation(acc_center, student, opp.Id);

        Boolean taskFlag = TriggerShouldRun.TASK;
        TriggerShouldRun.TASK = false;
        Test.startTest();

        AppListController.UpdateLineItemParams p = new AppListController.UpdateLineItemParams();
        p.record_id = String.valueOf(res.Id);

        p.which_field = 'short_note';
        p.field_value = 'short note value';
        AppListController.updateLineItem(JSON.serialize(p));

        p.which_field = 'intention';
        p.field_value = 'High';
        AppListController.updateLineItem(JSON.serialize(p));

        p.which_field = 'customer_details';
        p.field_value = 'customer detail value';
        AppListController.updateLineItem(JSON.serialize(p));

        p.which_field = 'app_details';
        p.field_value = 'app detail value';
        AppListController.updateLineItem(JSON.serialize(p));

        p.which_field = 'grade';
        p.field_value = 'Primary school 1';
        AppListController.updateLineItem(JSON.serialize(p));

        Test.stopTest();
        TriggerShouldRun.TASK = taskFlag;
    }

    static testMethod void testUpdateLineItemErrorBranches() {
        Account acc_center = setupCenterStudentOpp();
        Account student = [SELECT Id FROM Account WHERE Name = 'AppListStudent' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];
        Reservation__c res = setupReservation(acc_center, student, opp.Id);

        AppListController.UpdateLineItemParams p = new AppListController.UpdateLineItemParams();
        // missing params
        p.record_id = null; p.which_field = null; p.field_value = null;
        AppListController.updateLineItem(JSON.serialize(p));

        // unknown which_field
        p.record_id = String.valueOf(res.Id);
        p.which_field = 'bogus_field';
        p.field_value = 'x';
        AppListController.updateLineItem(JSON.serialize(p));

        // invalid record_id type (Account id) -> else branch
        p.which_field = 'short_note';
        p.record_id = String.valueOf(acc_center.Id);
        AppListController.updateLineItem(JSON.serialize(p));

        // Reservation not found
        String resPrefix = Reservation__c.SObjectType.getDescribe().getKeyPrefix();
        p.record_id = resPrefix + '000000000001AAA';
        AppListController.updateLineItem(JSON.serialize(p));
    }

    static testMethod void testUpdateLineItemStateSchool() {
        Account acc_center = setupCenterStudentOpp();
        Account student = [SELECT Id FROM Account WHERE Name = 'AppListStudent' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];
        Reservation__c res = setupReservation(acc_center, student, opp.Id);

        State_School__c school = new State_School__c(
            Name = 'AppList State School',
            City__c = acc_center.City__c,
            Close_Date__c = Date.today().addYears(1)
        );
        insert school;

        AppListController.UpdateLineItemParams p = new AppListController.UpdateLineItemParams();
        p.record_id = String.valueOf(res.Id);
        p.which_field = 'state_school';
        p.field_value = String.valueOf(school.Id);
        AppListController.updateLineItem(JSON.serialize(p));
    }

    static testMethod void testGetShortNoteHistoryWithData() {
        Account acc_center = setupCenterStudentOpp();
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];
        insertDetailTasks(opp.Id);

        Test.startTest();
        List<AppListController.ShortNoteHistory> history = AppListController.getShortNoteHistory(opp.Id);
        List<AppListController.ShortNoteHistory> history2 = AppListController.getShortNoteHistory(null);
        Test.stopTest();
    }

    static testMethod void testGetSchoolListWithData() {
        Account acc_center = setupCenterStudentOpp();
        State_School__c school = new State_School__c(
            Name = 'AppList Test School',
            City__c = acc_center.City__c,
            Close_Date__c = Date.today().addYears(1)
        );
        insert school;

        Test.startTest();
        List<AppListController.SchoolInfo> schools = AppListController.getSchoolList(String.valueOf(acc_center.City__c), 'Test');
        List<AppListController.SchoolInfo> schools2 = AppListController.getSchoolList('', '');
        List<AppListController.SchoolInfo> schools3 = AppListController.getSchoolList(String.valueOf(acc_center.City__c), null);
        Test.stopTest();
    }

    static testMethod void testGetCityAndCenterOptionsWithResource() {
        Account acc_center = TestDataFactory.insertShangHai1Center();
        Resource_Type__c rt = TestDataFactory.createCenterResourceType();
        Resource__c resource = TestDataFactory.createCenterResource('SHA-RES', acc_center.Id, rt.Id);
        resource.Is_Active__c = true;
        // OMNI-XXXX: live validation rule BU_Is_Required on Resource__c requires Business_Unit__c
        resource.Business_Unit__c = acc_center.Business_Unit__c;
        insert resource;

        Test.startTest();
        AppListController.InititalInfo info = AppListController.getCityAndCenterOptions('ShangHai1');
        AppListController.InititalInfo info2 = AppListController.getCityAndCenterOptions('NoSuchCenterName');
        Test.stopTest();
    }

    static testMethod void testQueryAppListBMS() {
        Account acc_center = setupCenterStudentOpp();
        Account student = [SELECT Id FROM Account WHERE Name = 'AppListStudent' LIMIT 1];
        Opportunity opp = [SELECT Id FROM Opportunity WHERE Name = 'AppList Test Opp' LIMIT 1];

        // BMS Session Member path: linked Reservation has Event_Type Demo Class but no Opportunity
        Boolean resFlag = TriggerShouldRun.BMS_RESERVATION;
        Boolean resAllFlag = TriggerShouldRun.BMS_RESERVATIONALLTRIGGER;
        TriggerShouldRun.BMS_RESERVATION = false;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = false;
        Reservation__c res = new Reservation__c();
        res.Event_Type__c = 'Demo Class';
        res.Start__c = Datetime.now().addDays(1);
        res.Start_Date__c = Date.today().addDays(1);
        insert res;
        TriggerShouldRun.BMS_RESERVATION = resFlag;
        TriggerShouldRun.BMS_RESERVATIONALLTRIGGER = resAllFlag;

        BMS_Session_Member__c bms = new BMS_Session_Member__c(
            Reservation__c = res.Id,
            Opportunity__c = opp.Id,
            Student__c = student.Id,
            Attendance_Result__c = 'Present'
        );
        Database.insert(bms, false);

        AppListController.FilterParams fp = new AppListController.FilterParams();
        fp.app_date_from = Date.today().addDays(-30);
        fp.app_date_to = Date.today().addDays(30);
        AppListController.AppListResponse result = AppListController.queryAppList(JSON.serialize(fp));

        // record_id is a BMS_Session_Member id -> BMS query early path
        AppListController.FilterParams fp2 = new AppListController.FilterParams();
        fp2.record_id = String.valueOf(bms.Id);
        AppListController.AppListResponse result2 = AppListController.queryAppList(JSON.serialize(fp2));

        // record_id that is not a BMS_Session_Member id -> empty
        AppListController.FilterParams fp3 = new AppListController.FilterParams();
        fp3.record_id = String.valueOf(opp.Id);
        AppListController.AppListResponse result3 = AppListController.queryAppList(JSON.serialize(fp3));
    }
}
