public with sharing class ProjectTriggerHandler extends TriggerHandler {

    // Конструктор (опционально, но полезно для настройки лимитов циклов)
    public ProjectTriggerHandler() {
        // Запрещаем триггеру выполняться более 2 раз в рамках одной транзакции (защита от рекурсии)
        this.setMaxLoopCount(2);
    }

    // Переопределяем Before Insert
    protected override void beforeInsert() {
        validateProjectManagersNotOnLeave(Trigger.new, null);
    }

    // Переопределяем Before Update
    protected override void beforeUpdate() {
        validateProjectManagersNotOnLeave(Trigger.new, (Map<Id, Project__c>) Trigger.oldMap);
    }

    // Переопределяем After Update
    protected override void afterUpdate() {
        handleProjectStatusChanges(Trigger.new, (Map<Id, Project__c>) Trigger.oldMap);
    }

    // =========================================================================
    // ЛОГИКА 1: Синхронизация статусов с Opportunity (After Update)
    // =========================================================================
    private void handleProjectStatusChanges(List<Project__c> newProjects, Map<Id, Project__c> oldProjectsMap) {
        Set<Id> oppIdsToUpdate = new Set<Id>();
        Map<Id, String> oppIdToAlertMessage = new Map<Id, String>();

        for (Project__c proj : newProjects) {
            if (proj.OpportunityId__c == null) {
                continue;
            }
            Project__c oldProj = oldProjectsMap != null ? oldProjectsMap.get(proj.Id) : null;
            if (!isStatusChanged(oldProj, proj)) {
                continue;
            }
            processProjectForOpportunity(proj, oldProj, oppIdsToUpdate, oppIdToAlertMessage);
        }

        if (!oppIdsToUpdate.isEmpty()) {
            List<Opportunity> oppsToUpdate = new List<Opportunity>();
            for (Id oppId : oppIdsToUpdate) {
                oppsToUpdate.add(new Opportunity(
                    Id = oppId,
                    Alert_Reason__c = oppIdToAlertMessage.get(oppId)
                ));
            }
            update oppsToUpdate;
        }
    }

    private static Boolean isStatusChanged(Project__c oldProj, Project__c newProj) {
        return (oldProj == null || oldProj.Status__c != newProj.Status__c);
    }

    private static void processProjectForOpportunity(Project__c proj, Project__c oldProj, Set<Id> oppIdsToUpdate, Map<Id, String> oppIdToAlertMessage) {
        if (proj.Status__c == 'Blocked') {
            oppIdsToUpdate.add(proj.OpportunityId__c);
            oppIdToAlertMessage.put(proj.OpportunityId__c, 'Проект заблокирован! Требуется внимание');
        } else if (proj.Status__c == 'In Progress' && oldProj != null && oldProj.Status__c == 'Blocked') {
            oppIdsToUpdate.add(proj.OpportunityId__c);
            oppIdToAlertMessage.put(proj.OpportunityId__c, null);
        }
    }

    // =========================================================================
    // ЛОГИКА 2: Валидация менеджеров в отпуске (Before Insert / Before Update)
    // =========================================================================
    private void validateProjectManagersNotOnLeave(List<Project__c> newProjects, Map<Id, Project__c> oldProjectsMap) {
        Set<Id> managerIdsToCheck = collectManagerIds(newProjects, oldProjectsMap);
        if (managerIdsToCheck.isEmpty()) return;

        Set<Id> managersOnLeaveIds = getManagersOnLeave(managerIdsToCheck);
        if (managersOnLeaveIds.isEmpty()) return;

        applyValidationErrors(newProjects, managersOnLeaveIds);
    }

    private static Set<Id> collectManagerIds(List<Project__c> newProjects, Map<Id, Project__c> oldProjectsMap) {
        Set<Id> managerIds = new Set<Id>();
        for (Project__c proj : newProjects) {
            if (proj.Project_Manager__c == null) continue;

            Project__c oldProj = oldProjectsMap != null ? oldProjectsMap.get(proj.Id) : null;
            if (oldProj == null || oldProj.Project_Manager__c != proj.Project_Manager__c) {
                managerIds.add(proj.Project_Manager__c);
            }
        }
        return managerIds;
    }

    private static Set<Id> getManagersOnLeave(Set<Id> managerIds) {
        Map<Id, User> usersOnLeave = new Map<Id, User>([
            SELECT Id FROM User WHERE Id IN :managerIds AND On_Leave__c = true
        ]);
        return usersOnLeave.keySet();
    }

    private static void applyValidationErrors(List<Project__c> newProjects, Set<Id> managersOnLeaveIds) {
        for (Project__c proj : newProjects) {
            if (proj.Project_Manager__c != null && managersOnLeaveIds.contains(proj.Project_Manager__c)) {
                proj.Project_Manager__c.addError('Невозможно назначить этого пользователя Менеджером проекта, так как он находится в отпуске (On Leave).');
            }
        }
    }
}