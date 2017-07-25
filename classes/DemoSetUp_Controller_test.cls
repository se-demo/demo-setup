@isTest(SeeAllData=true)
public class DemoSetUp_Controller_test {
    static testMethod void unitTest(){
        DemoSetUp_Controller ds = new DemoSetUp_Controller();
        ds.saveUserDetails();
        ds.fromCompany = 'abc';
        ds.toCompany = 'xyz';
        ds.getAccounts();
        ds.getSurveys();
        ds.resetSurveys();
        ds.licenses();
        ds.refreshScoreCard();
        ds.resetAccounts();
        ds.resetAccounts();
        ds.updateAccounts();
        ds.getCustomerLicenses();
        ds.updateCustomerInfoList();
        ds.resetCustomerInfoList();
        ds.updateCompany();
        ds.updateCTADate();
        ds.updateTaskDate();
        ds.updateHealthScore();
        ds.updateScoreCardByWeek();
    }
}