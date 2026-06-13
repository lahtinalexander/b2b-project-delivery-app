trigger ProjectTrigger on Project__c (before insert, before update, after insert, after update) {
    // Просто создаем экземпляр нашего хэндлера и запускаем его через базовый метод run()
    new ProjectTriggerHandler().run();
}