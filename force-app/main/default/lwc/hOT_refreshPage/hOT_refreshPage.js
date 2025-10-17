import { LightningElement, api } from 'lwc';
import { FlowNavigationNextEvent } from 'lightning/flowSupport';

export default class HOT_refreshPage extends LightningElement {
    @api includeAllSubtabs = false; // configurable from Flow

    connectedCallback() {
        this.refreshPage();
    }

    async refreshPage() {
        try {
            // Check if running inside a console app (workspace API available)
            const workspaceAPI = await this.getWorkspaceAPI();

            if (workspaceAPI) {
                const tabInfo = await workspaceAPI.getEnclosingTabId();
                await workspaceAPI.refreshTab({
                    tabId: tabInfo,
                    includeAllSubtabs: this.includeAllSubtabs
                });
            } else {
                // Fallback for non-console environments
                window.location.reload();
            }
        } catch (error) {
            console.error('Error refreshing tab:', error);
            // fallback in case Workspace API isn't available
            window.location.reload();
        } finally {
            // Automatically move Flow forward after refresh is triggered
            this.dispatchEvent(new FlowNavigationNextEvent());
        }
    }

    getWorkspaceAPI() {
        return new Promise((resolve) => {
            // workspaceAPI is available only in console apps
            const workspaceAPI = this.template.querySelector('lightning-workspace-api');
            resolve(workspaceAPI);
        });
    }
}
