// the class almacena la logica para crear los records
public with sharing class UnitService {
    
    public static Boolean registerUnitResponse(Id unitId, String jsonAnswer) {
        
        //Database.SaveResult sp = Database.setSavePoint();
        
        Boolean booleanStatus = false;
        try {
            //fetch unit from database
            Unit__c unit = [SELECT Module__c, (SELECT Id, Number_Tries__c FROM Unit_Responses__r WHERE Module_Response__r.User__c =: UserInfo.getUserId() ORDER BY Number_Tries__c DESC LIMIT 1), (SELECT Id, Name FROM Questions__r) FROM Unit__c WHERE Id =: unitId];
            
            //verificar si ya existe un module response
            Module_Response__c moduleResp = [SELECT Id FROM Module_Response__c WHERE Module__c =: unit.Module__c AND User__c =: UserInfo.getUserId() AND Status_Completed__c = false];
            
            
            if (moduleResp == null){
                 //create and insert of module response
                moduleResp = new Module_Response__c (User__c = UserInfo.getUserId(), 
                    Module__c = unit.Module__c, Status_Completed__c = true);
                insert moduleResp;
            }
           
            //create and insert of unit response
            Unit_Response__c unitResp = new Unit_Response__c(Unit_Lookup__c = unitId, 
                Module_Response__c = moduleResp.Id, StatusProgress__c = 'Draft');
            //NTH ternario
            if(!unit.Unit_Responses__r.isEmpty()){
                unitResp.Number_Tries__c = unit.Unit_Responses__r[0].Number_Tries__c + 1;
            }else{
                unitResp.Number_Tries__c = 1;
            }
            insert unitResp;
            
            //create and upload question response
            Map<Id, Id> answerMap = (Map<Id, Id>)JSON.deserialize(jsonAnswer, Map<Id, Id>.class);
            List<Question_Response__c> questionRespList = new List<Question_Response__c>();
            
            //itero el Map con un set de key q me realiza el motodo keySet()
            //for (Id questionId : answerMap.keySet()) {
            for(Question__c question : unit.Questions__r){
            
                if (answerMap.containsKey(question.Id)){
                    Question_Response__c questionResp = new Question_Response__c(Question__c = question.Id, 
                    Unit_Response__c = unitResp.Id, Option__c = answerMap.get(question.Id));
                    questionRespList.add(questionResp);
                }else{
                    throw new CustomException('La pregunta ' + question.Name + ' no fue respondida y es requerida.');
                }
            } 
            insert questionRespList;
            
            //update the unit responses to answered to trigger the evaluation process
            unitResp.StatusProgress__c = 'Answered';
            update unitResp;
            
            booleanStatus = true;
            
        } catch (Exception e) {
            //Database.rollback(sp);
            throw e;
        }
        
        return booleanStatus;
    }
}
