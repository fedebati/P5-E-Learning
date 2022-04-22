// the class almacena la logica para crear los records
public with sharing class UnitService {
    
    public static Boolean registerUnitResponse(Id unitId, String jsonAnswer) {
        
        //fetch unit from database
        Unit__c unit = [SELECT Module__c FROM Unit__c WHERE Id =: unitId];
        
        //create and insert of module response
        Module_Response__c moduleResp = new Module_Response__c (User__c = UserInfo.getUserId(), 
        Module__c = unit.Module__c, Status_Completed__c = true);
        insert moduleResp;
        
        //create and insert of unit response
        Unit_Response__c unitResp = new Unit_Response__c(Unit_Lookup__c = unitId, User = Module_Response__c = moduleResp.Id, );
        insert unitResp;
        
        //create and upload question response
        Map<Id, Id> answerMap = (Map<Id, Id>)JSON.deserialize(jsonAnswer, Map<Id, Id>.class);
        List<Question_Response__c> questionRespList = new List<Question_Response__c>();
        //itero el Map con un set de key q me realiza el motodo keySet()
        for (Id questionId : answerMap.keySet()) {
            Question_Response__c questionResp = new Question_Response__c(Question__c = questionId, Unit_Response__c = unitResp.Id, Option__c = answerMap.get(questionId));
            questionResp.add(questionResp);
        } 
        insert questionRespList;
    }
}
 