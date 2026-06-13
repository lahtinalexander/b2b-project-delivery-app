public virtual class TriggerHandler {
    
    // Переменная для контроля рекурсии (защита от бесконечных циклов)
    private static Map<String, LoopCount> loopCountMap = new Map<String, LoopCount>();

    // Основной метод, который вызывается из триггера
    public void run() {
        // Защита: проверяем лимиты на количество повторных входов в этот же триггер
        if (isLoopCountExceeded()) {
            return;
        }

        // Оркестрация в зависимости от контекста выполнения
        if (Trigger.isBefore) {
            if (Trigger.isInsert) this.beforeInsert();
            else if (Trigger.isUpdate) this.beforeUpdate();
            else if (Trigger.isDelete) this.beforeDelete();
        } else if (Trigger.isAfter) {
            if (Trigger.isInsert) this.afterInsert();
            else if (Trigger.isUpdate) this.afterUpdate();
            else if (Trigger.isDelete) this.afterDelete();
            else if (Trigger.isUndelete) this.afterUndelete();
        }
    }

    // Методы-заглушки. Мы помечаем их как virtual, чтобы их можно было переопределить (override)
    protected virtual void beforeInsert() {}
    protected virtual void beforeUpdate() {}
    protected virtual void beforeDelete() {}
    protected virtual void afterInsert() {}
    protected virtual void afterUpdate() {}
    protected virtual void afterDelete() {}
    protected virtual void afterUndelete() {}

    // --- Внутренняя магия контроля рекурсии ---
    public void setMaxLoopCount(Integer max) {
        String handlerName = getHandlerName();
        if (!loopCountMap.containsKey(handlerName)) {
            loopCountMap.put(handlerName, new LoopCount(max));
        } else {
            loopCountMap.get(handlerName).setMax(max);
        }
    }

    private Boolean isLoopCountExceeded() {
        String handlerName = getHandlerName();
        if (!loopCountMap.containsKey(handlerName)) {
            return false;
        }
        return loopCountMap.get(handlerName).increment();
    }

    private String getHandlerName() {
        return String.valueOf(this).split(':').get(0);
    }

    // Вспомогательный внутренний класс для подсчета циклов
    private class LoopCount {
        private Integer max;
        private Integer count;

        public LoopCount(Integer max) {
            this.max = max;
            this.count = 0;
        }

        public void setMax(Integer max) {
            this.max = max;
        }

        public Boolean increment() {
            this.count++;
            return this.count > this.max;
        }
    }
}