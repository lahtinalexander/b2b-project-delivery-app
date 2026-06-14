public with sharing class ProjectEquipmentController {

    @AuraEnabled(cacheable=true)
    public static List<Installed_Asset__c> getAvailableEquipment(Id projectId) {
        // 1. Сначала узнаем ID Аккаунта (клиента), к которому привязан наш Проект
        Project__c proj = [
            SELECT OpportunityId__r.AccountId 
            FROM Project__c 
            WHERE Id = :projectId 
            LIMIT 1
        ];
        
        Id accountId = proj.OpportunityId__r?.AccountId;
        if (accountId == null) {
            return new List<Installed_Asset__c>();
        }

        // 2. Вытаскиваем всё оборудование этого клиента, которое ЕЩЕ НЕ привязано к этому проекту
        // И статус которого 'Active'
        return [
            SELECT Id, Name, Serial_Number__c, Status__c, Installation_Date__c
            FROM Installed_Asset__c
            WHERE AccountId__c = :accountId 
              AND Status__c = 'Active'
              AND ProjectId__c != :projectId
        ];
    }

    @AuraEnabled
    public static void assignEquipmentToProject(List<Id> assetIds, Id projectId) {
        if (assetIds == null || assetIds.isEmpty() || projectId == null) {
            return;
        }

        List<Installed_Asset__c> assetsToUpdate = new List<Installed_Asset__c>();
        for (Id assetId : assetIds) {
            assetsToUpdate.add(new Installed_Asset__c(
                Id = assetId,
                ProjectId__c = projectId // Привязываем к текущему проекту
            ));
        }

        update assetsToUpdate;
    }
}