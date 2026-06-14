import { LightningElement, api, wire, track } from 'lwc';
import { ShowToastEvent } from 'lightning/platformShowToastEvent';
import { refreshApex } from '@salesforce/apex';
import getAvailableEquipment from '@salesforce/apex/ProjectEquipmentController.getAvailableEquipment';
import assignEquipmentToProject from '@salesforce/apex/ProjectEquipmentController.assignEquipmentToProject';

// Описываем колонки для таблицы lightning-datatable
const COLUMNS = [
    { label: 'Название', fieldName: 'Name', type: 'text' },
    { label: 'Серийный номер', fieldName: 'Serial_Number__c', type: 'text' },
    { label: 'Статус', fieldName: 'Status__c', type: 'text' }
];

export default class ProjectEquipmentManager extends LightningElement {
    @api recordId; // Автоматически получает Id текущего проекта
    columns = COLUMNS;
    
    @track equipmentData = [];
    selectedRows = [];
    wiredEquipmentResult; // Хранилище для рефреша кэша

    // Используем @wire для автоматического вызова Apex при загрузке страницы
    @wire(getAvailableEquipment, { projectId: '$recordId' })
    wiredEquipment(result) {
        this.wiredEquipmentResult = result;
        if (result.data) {
            this.equipmentData = result.data;
        } else if (result.error) {
            this.showToast('Ошибка', 'Не удалось загрузить оборудование', 'error');
        }
    }

    get hasEquipment() {
        return this.equipmentData && this.equipmentData.length > 0;
    }

    get isButtonDisabled() {
        return this.selectedRows.length === 0;
    }

    // Срабатывает при выделении галочками
    handleRowSelection(event) {
        this.selectedRows = event.detail.selectedRows;
    }

    // Императивный вызов Apex по нажатию кнопки
    handleAssign() {
        const assetIds = this.selectedRows.map(row => row.Id);

        assignEquipmentToProject({ assetIds: assetIds, projectId: this.recordId })
            .then(() => {
                this.showToast('Успешно', 'Оборудование успешно привязано к проекту', 'success');
                // Сбрасываем выделение
                this.selectedRows = [];
                // Очищаем кэш @wire, чтобы таблица перерисовалась и добавленное оборудование исчезло из списка доступных
                return refreshApex(this.wiredEquipmentResult);
            })
            .catch(error => {
                this.showToast('Ошибка', error.body.message, 'error');
            });
    }

    showToast(title, message, variant) {
        this.dispatchEvent(
            new ShowToastEvent({
                title: title,
                message: message,
                variant: variant
            })
        );
    }
}