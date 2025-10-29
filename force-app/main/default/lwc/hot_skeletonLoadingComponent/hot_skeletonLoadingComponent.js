import { LightningElement, api } from 'lwc';
import personHighlightPanel from './personHighlightPanel.html';
import table from './table.html';

const DEFAULT_TABLE_ROW_COUNT = 1;
const DEFAULT_TABLE_COLUMN_COUNT = 3;
const LINE_VARIANTS = ['line-wide', 'line-medium', 'line-short', 'line-narrow'];

export default class SkeletonLoadingComponent extends LightningElement {
    @api type;

    _tableRowCount = DEFAULT_TABLE_ROW_COUNT;
    _tableColumnCount = DEFAULT_TABLE_COLUMN_COUNT;

    @api
    get tableRowCount() {
        return this._tableRowCount;
    }

    set tableRowCount(value) {
        this._tableRowCount = this.normalizeCount(value, DEFAULT_TABLE_ROW_COUNT);
    }

    @api
    get tableColumnCount() {
        return this._tableColumnCount;
    }

    set tableColumnCount(value) {
        this._tableColumnCount = this.normalizeCount(value, DEFAULT_TABLE_COLUMN_COUNT);
    }

    get tableRows() {
        const rows = [];
        const rowCount = this._tableRowCount;
        const columnCount = this._tableColumnCount;

        for (let rowIndex = 0; rowIndex < rowCount; rowIndex += 1) {
            const columns = [];

            for (let columnIndex = 0; columnIndex < columnCount; columnIndex += 1) {
                columns.push({
                    key: `row-${rowIndex}-col-${columnIndex}`,
                    className: this.computeColumnClass(rowIndex, columnIndex)
                });
            }

            rows.push({
                key: `row-${rowIndex}`,
                className: rowIndex === rowCount - 1 ? 'skeleton-row skeleton-row-last' : 'skeleton-row',
                columns
            });
        }

        return rows;
    }

    render() {
        switch (this.type) {
            case 'personHighlightPanel':
                return personHighlightPanel;
            case 'table':
                return table;
            default:
                return personHighlightPanel;
        }
    }

    computeColumnClass(rowIndex, columnIndex) {
        const variantIndex = (rowIndex + columnIndex) % LINE_VARIANTS.length;
        return `line ${LINE_VARIANTS[variantIndex]}`;
    }

    normalizeCount(value, fallback) {
        const parsed = parseInt(value, 10);
        if (Number.isFinite(parsed) && parsed > 0) {
            return parsed;
        }
        return fallback;
    }
}
