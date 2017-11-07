public class DemoSetUp_Controller {

    public List < Account > accountsList {get; set;}
    public List < JBCXM__CustomerInfo__c > customerInfoList {get; set;}
    public List < JBCXM__SurveyMaster__c > surveyList {get; set;}
    public string accountId {get; set;}
    public string customerInfoId {get; set;}
    public string surveyId {get; set;}
    public string fromCompany {get; set;}
    public string toCompany {get; set;}
    public Date dateField {get; set;}
    public User loginUser {get; set;}

    // msg center
    public boolean accSuccess {get; set;}
    public boolean accFailure {get; set;}

    set < Id > accIds = new Set < Id > ();
    set < Id > infoIds = new Set < Id > ();
    set < Id > sIds = new Set < Id > ();

    public DemoSetUp_Controller() {
        loginUser = [SELECT Id, FirstName, LastName, Email FROM User WHERE Id =: UserInfo.getUserId()];
        accountsList = new List < Account > ();
        accountsList = [Select Id, name, Industry from Account where Name IN('Abbett', 'Facebook', 'Sharp', 'Symantec', 'Udemy', 'Google Inc.', 'Apple', 'AAA', 'Spotify', 'Xerox', 'Kaspersky Lab')];
        customerInfoList = new List < JBCXM__CustomerInfo__c > ();
        surveyList = new List < JBCXM__SurveyMaster__c > ();

        // flags init
        accSuccess = false;
        accFailure = false;

    }


    public void saveUserDetails() {
        update loginUser;
        // fix CTA views invoked here
        fixCTA_views();
        fixTask_DueDates();
        fixCTAs_DueDates();
        alertSponsorTracking();
    }

    public void getAccounts() {
        if (accountId != null) {
            accIds.add(accountId);
            accountsList.add([Select Id, name, Industry from Account where Id IN: accIds]);
        }
    }

    public void updateAccounts() {
        try {
            update accountsList;
            accSuccess = true;
        }
        Catch(Exception Ex) {
            accFailure = false;
            system.debug('Accounts Update => ' + Ex.getMessage());
        }
    }

    public void resetAccounts() {
        accountId = null;
        accSuccess = false;
        accFailure = false;
        accountsList.clear();
    }

    public void getCustomerLicenses() {
        if (customerInfoId != null) {
            infoIds.add(customerInfoId);
            customerInfoList = [SELECT Id, JBCXM__CustomerName__c, JBCXM__ASV__c, JBCXM__Users__c, JBCXM__NextRenewalDate__c, JBCXM__MRR__c FROM JBCXM__CustomerInfo__c where Id IN: infoIds];
            system.debug('customer info list =>' + customerInfoList.size());
        }
    }

    public void updateCustomerInfoList() {
        try {
            update customerInfoList;
        }
        Catch(Exception Ex) {
            system.debug('Accounts Update => ' + Ex.getMessage());
        }
    }

    public void resetCustomerInfoList() {
        customerInfoId = null;
        customerInfoList.clear();
    }

    public void getSurveys() {
        if (surveyId != null) {
            sIds.add(surveyId);
            surveyList = [SELECT Id, JBCXM__SurveyName__c FROM JBCXM__SurveyMaster__c where Id IN: sIds];
        }
    }

    public void resetSurveys() {
        surveyId = null;
        surveyList.clear();
    }

    public void licenses() {
        //SELECT Id, JBCXM__CustomerName__c, JBCXM__ASV__c, JBCXM__Users__c, JBCXM__NextRenewalDate__c, JBCXM__MRR__c  FROM JBCXM__CustomerInfo__c  
    }

    public void updateTaskDate() {
        List < JBCXM__CSTask__c > CTAList = new List < JBCXM__CSTask__c > ();
        Set < String > NameSet = new Set < String > ();
        Set < String > NamesToChange = new Set < String > ();

        if (dateField != null) {
            for (JBCXM__CSTask__c CTA: [SELECT Id, JBCXM__Date__c FROM JBCXM__CSTask__c WHERE JBCXM__Date__c != null]) {
                CTA.JBCXM__Date__c = dateField;
                NameSet.add(CTA.Name);
                CTAList.add(CTA);
            }
            update CTAList;
            dateField = null;
        }
    }

    public void updateCTADate() {
        List < JBCXM__CTA__c > CTAList = new List < JBCXM__CTA__c > ();
        Set < String > NameSet = new Set < String > ();
        Set < String > NamesToChange = new Set < String > ();

        if (dateField != null) {
            for (JBCXM__CTA__c CTA: [SELECT Id, JBCXM__Assignee__c, Name, JBCXM__DueDate__c FROM JBCXM__CTA__c WHERE JBCXM__DueDate__c != null]) {
                CTA.JBCXM__DueDate__c = dateField;
                NameSet.add(CTA.Name);
                CTAList.add(CTA);
            }

            System.debug('# of CTAS: ' + CTAList.size());
            update CTAList;
        }

        for (String S: NameSet) {
            System.debug(S);
        }
    }

    public void refreshScoreCard() {
        //Get Scorecard Metric Map to get ID by Scorecard metric Name
        Map < String, String > scmLabeltoId = new Map < String, String > ();
        List < JBCXM__ScorecardMetric__c > scm = [Select Id, Name FROM JBCXM__ScorecardMetric__c where JBCXM__IsGroup__c = false];
        for (JBCXM__ScorecardMetric__c sm: scm) {
            scmLabeltoId.put(sm.Name, sm.Id);
        }

        //gets labels and API names from Usage Data Object for Scorecard Measures
        Map < String, String > apiNameToSCMLabel = new Map < String, String > ();
        Map < String, Schema.SObjectField > fieldsMap = Schema.SObjectType.JBCXM__UsageData__c.fields.getMap();
        for (Schema.SObjectField field: fieldsMap.values()) {
            if (field.getDescribe().getName().contains('SC_') && !(field.getDescribe().getName().contains('SC_OVERALLSCORE__c'))) {
                apiNameToSCMLabel.put(field.getDescribe().getName(), field.getDescribe().getLabel());
            }
        }

        System.debug(JSON.Serialize(apiNameToSCMLabel));

        //Application Settings Adoption Map field JSON converted to a Map
        JBCXM__ApplicationSettings__c aps = [select Id, JBCXM__AdoptionMeasureColMap__c FROM JBCXM__ApplicationSettings__c limit 1];
        String asJSON = aps.JBCXM__AdoptionMeasureColMap__c;

        Map < string, string > asMap = (Map < string, string > ) JSON.deserialize(asJSON, Map < string, string > .class);
        system.debug(asMap);
        for (String s: asMap.keySet()) {
            String apiName = asMap.get(s);
            if (apiNameToSCMLabel.ContainsKey(apiName)) {
                String newId = scmLabeltoId.get(apiNameToSCMLabel.get(apiName));
                if (newID != null) {
                    asMap.remove(s);
                    asMap.put(newId, apiName);
                }
            }
        }

        System.debug(JSON.Serialize(asMap));
        aps.JBCXM__AdoptionMeasureColMap__c = JSON.Serialize(asMap);
        update aps;

        // for abbett
        String accountId = [SELECT Id FROM Account where Name = 'Abbett'].Id; // replace account Id here
        Date myDate = Date.today();
        Date weekStart = myDate.toStartofWeek() - 7;
        system.debug(weekStart);
        Integer i = 25;
        List < JBCXM__USageData__c > udList = new List < JBCXM__USageData__c > ();
        JBCXM__USageData__c ud;
        while (i > 1) {
            try {
                ud = [SELECT id, JBCXM__WeekLabel__c, SC_Overallscore__c, SC_a0no000000KmmKWAAZ__c, SC_a0no000000KmmEuAAJ__c, SC_a0no000000KmmJLAAZ__c, SC_a0no000000KmmHyAAJ__c, SC_a0no000000KmmJGAAZ__c, SC_a0no0000000n0N6AAI__c, SC_a0no0000000n0N5AAI__c, SC_a0no0000000n0N3AAI__c FROM JBCXM__USageData__c WHERE Name = 'ACCOUNTLEVEL'
                    AND JBCXM__Account__c =: accountId AND JBCXM__WeekLabel__c =: weekStart
                ];
            }
            Catch(Exception Ex) {
                system.debug('no records for week ' + weekStart);
                ud = new JBCXM__USageData__c();
            }
            if (ud.Id == null) {
                ud.JBCXM__Account__c = accountId;
                ud.JBCXM__WeekLabel__c = weekstart;
                ud.JBCXM__Date__c = weekStart;
                ud.Name = 'ACCOUNTLEVEL';
            }
            ud.SC_Overallscore__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no000000KmmKWAAZ__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no000000KmmEuAAJ__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no000000KmmJLAAZ__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no000000KmmHyAAJ__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no000000KmmJGAAZ__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no0000000n0N6AAI__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no0000000n0N5AAI__c = Decimal.valueOf(getRandomNumber_35());
            ud.SC_a0no0000000n0N3AAI__c = Decimal.valueOf(getRandomNumber_35());
            udList.add(ud);
            system.debug('inserted ud => ' + ud);

            weekStart = weekStart - 7;
            i--;
        }

        if (udList.size() > 0) {
            upsert udList;
        }


    }

    public void updateCompany() {
        List < JBCXM__SponsorTracking__c > st_List = new List < JBCXM__SponsorTracking__c > ();
        for (JBCXM__SponsorTracking__c st: [Select id, name, JBCXM__IsChanged__c, JBCXM__ChangedInfo__c from JBCXM__SponsorTracking__c]) {
            string str = st.JBCXM__ChangedInfo__c;
            if (str != null && str.contains(fromCompany)) {
                system.debug(str.replace(fromCompany, toCompany));
                str.replace(fromCompany, toCompany);
                st.JBCXM__ChangedInfo__c = str.replace(fromCompany, toCompany);
                st_List.add(st);
            }
        }
        if (st_List.size() > 0) {
            update st_List;
        }
    }

    public void updateHealthScore() {
        // values for <=50 get updated with random number between 51 - 98
        Map < String, String > config_map = new Map < String, String > ();
        for (JBCXM__ScoringSchemeDefinition__c sc_config: [SELECT Id, Name FROM JBCXM__ScoringSchemeDefinition__c WHERE Name >= '51'
                AND Name <= '98'
            ]) {
            config_map.put(sc_config.Name, sc_config.Id);
        }

        List < JBCXM__CustomerInfo__c > updateList = new List < JBCXM__CustomerInfo__c > ();
        Set < Id > accountIds_set = new Set < Id > ();
        for (JBCXM__CTA__c cta: [SELECT Id, Name, JBCXM__Account__r.Name, JBCXM__DueDate__c, JBCXM__TypeName__c, JBCXM__IsRecurring__c, JBCXM__STAGE__r.Name, JBCXM__Parent__c FROM JBCXM__CTA__c WHERE JBCXM__Account__c != null and JBCXM__STAGE__r.Name != 'Closed Success'
                AND JBCXM__STAGE__r.Name != 'Deprecated Internal Escalation'
                AND JBCXM__STAGE__r.Name != 'Closed Lost'
                and JBCXM__DueDate__c >= 2015-09-30 and JBCXM__TypeName__c != 'Objective'
                and JBCXM__Account__r.JBCXM__CustomerInfo__c != null ORDER BY JBCXM__Account__r.Name
            ]) {
            accountIds_set.add(cta.JBCXM__Account__c);
        }

        for (JBCXM__CustomerInfo__c customer: [SELECT Id, jbcxm__Account__r.Name, JBCXM__CurScoreId__r.Name, JBCXM__CurScoreId__c FROM JBCXM__CustomerInfo__c WHERE JBCXM__CurScoreId__r.Name <= '50'
                AND jbcxm__Account__c IN: accountIDs_set
            ]) {
            customer.JBCXM__CurScoreId__c = config_map.get(getRandomNumber());
            //system.debug(getRandomNumber());
            //system.debug(config_map.get(getRandomNumber()));
            updateList.add(customer);
        }

        if (updateList.size() > 0) {
            update updateList;
        }

    }

    public void updateScoreCardByWeek() {
        List < JBCXM__USageData__c > udList = new List < JBCXM__USageData__c > ();
        for (JBCXM__USageData__c ud: [SELECT id, SC_Overallscore__c, SC_a0no000000KmmKWAAZ__c, SC_a0no000000KmmEuAAJ__c, SC_a0no000000KmmJLAAZ__c, SC_a0no000000KmmHyAAJ__c,
                SC_a0no000000KmmJGAAZ__c, SC_a0no0000000n0N6AAI__c, SC_a0no0000000n0N5AAI__c
                FROM JBCXM__USageData__c WHERE JBCXM__Account__c = '0014100000AJHjcAAH'
                AND(JBCXM__WeekLabel__c = 2016-11-13 OR JBCXM__WeekLabel__c = 2016-11-06) ORDER BY Id Desc LIMIT 2]) {
            udList.add(ud);
        }
        if (udList.size() > 0) {
            update udList;
        }
    }

    public String getRandomNumber() {
        return String.valueOf(Integer.ValueOf(Math.floor(Math.random() * (98 - 51 + 1) + 51)));
    }

    public String getRandomNumber_35() {
        return String.valueOf(Integer.ValueOf(Math.floor(Math.random() * (98 - 35 + 1) + 35)));
    }

    public Integer getRandomNumber_10() {
        return Integer.ValueOf(Math.floor(Math.random() * (90 - 10 + 1) + 10));
    }
    
    public void fixCTA_views() {
        List < JBCXM__GSCockpitView__c > viewList = new LIst < JBCXM__GSCockpitView__c > ();
        Id newId = [SELECT Id, Name FROM JBCXM__GSReportCategory__c WHERE Name = 'Open'].Id;
        String str;
        for (JBCXM__GSCockpitView__c v: [SELECT Id, Name, JBCXM__WhereClause__c FROM JBCXM__GSCockpitView__c WHERE Name = 'My CTAs'
                OR Name = 'All CTAs'
            ]) {
            str = v.JBCXM__WhereClause__c;
            v.JBCXM__WhereClause__c = str.replace('a1ao000000fAw0OAAS', newId);
            viewList.add(v);
        }

        if (Viewlist.size() > 0) {
            update viewList;
        }
    }

    public void fixTask_DueDates() {
        List < JBCXM__CSTask__c > taskList = new List < JBCXM__CSTask__c > ();
        for (JBCXM__CSTask__c task: [SELECT Id, JBCXM__Date__c FROM JBCXM__CSTask__c WHERE JBCXM__Date__c != null]) {
            task.JBCXM__Date__c = System.today() + getRandomNumber_10();
            taskList.add(task);
            system.debug('updating Task due date => ' + task.JBCXM__Date__c);
        }
        update taskList;
    }

    public void fixCTAs_DueDates() {
        List < JBCXM__CTA__c > CTAList = new List < JBCXM__CTA__c > ();
        for (JBCXM__CTA__c CTA: [SELECT Id, JBCXM__Assignee__c, Name, JBCXM__DueDate__c FROM JBCXM__CTA__c WHERE JBCXM__DueDate__c != null]) {
            CTA.JBCXM__DueDate__c = System.today() + getRandomNumber_10();
            CTAList.add(CTA);
            system.debug('updating cta due date => ' + CTA.JBCXM__DueDate__c);
        }
        update CTAList;
    }

    public void alertSponsorTracking() {
        List < JBCXM__SponsorTracking__c > updateList = new List <JBCXM__SponsorTracking__c > ();
        for (JBCXM__SponsorTracking__c st: [select id, JBCXM__IsChanged__c FROM JBCXM__SponsorTracking__c WHERE JBCXM__SponsorFullName__c IN('Mike Madison', 'Laura James')]) {
            st.JBCXM__IsChanged__c = true;
            updateList.add(st);
        }

        if (updateList.size() > 0) {

            update updateList;

        }
    }

}
