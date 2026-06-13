public with sharing class ProjectLogGenerator {

    @InvocableMethod(
        label='Generate Project Execution Log' 
        description='Принимает список ID проектов и генерирует текстовый лог выполнения задач.'
        category='Project Management'
    )
    public static List<String> generateLogs(List<Id> projectIds) {
        List<String> resultLogs = new List<String>();

        // Защита от пустых данных
        if (projectIds == null || projectIds.isEmpty()) {
            return resultLogs;
        }

        // Вытаскиваем нужные поля для лога ОДНИМ SOQL запросом (Bulkified)
        Map<Id, Project__c> projectsMap = new Map<Id, Project__c>([
            SELECT Id, Name, Status__c, Start_Date__c, End_Date__c, Project_Manager__r.Name
            FROM Project__c
            WHERE Id IN :projectIds
        ]);

        // Проходим по исходному списку ID, чтобы сохранить строгий порядок элементов
        for (Id projId : projectIds) {
            Project__c proj = projectsMap.get(projId);
            
            if (proj == null) {
                resultLogs.add('Ошибка: Проект с ID ' + projId + ' не найден.');
                continue;
            }

            // Формируем красивый текстовый лог
            String managerName = proj.Project_Manager__r.Name != null ? proj.Project_Manager__r.Name : 'Не назначен';
            String startDate = proj.Start_Date__c != null ? String.valueOf(proj.Start_Date__c) : 'Не задана';
            String endDate = proj.End_Date__c != null ? String.valueOf(proj.End_Date__c) : 'Не задана';

            String logText = '=== ЛОГ ВЫПОЛНЕНИЯ ПРОЕКТА: ' + proj.Name + ' ===\n' +
                             'Текущий статус: ' + proj.Status__c + '\n' +
                             'Менеджер проекта: ' + managerName + '\n' +
                             'Дата начала: ' + startDate + '\n' +
                             'Дата завершения: ' + endDate + '\n' +
                             'Лог успешно сгенерирован: ' + String.valueOf(Datetime.now()) + '\n' +
                             '========================================';
            
            resultLogs.add(logText);
        }

        return resultLogs;
    }
}