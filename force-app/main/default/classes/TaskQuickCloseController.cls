/**
 * OMNI-70387 Close one Task straight from a list view column.
 *
 * Both Completed and Cancelled are closed statuses, so the platform's
 * single-click status icon always opens the "Choose Status" picker (3 clicks per
 * task). Lightning Task list views support only standard buttons, so a list view
 * button cannot be the entry point either - but a formula column can, because
 * columns come from fields. Two HYPERLINK formula fields on Activity link here.
 *
 * Page: TaskQuickClose.
 */
public with sharing class TaskQuickCloseController {
    @TestVisible
    private static final String STATUS_COMPLETED = 'Completed';
    @TestVisible
    private static final String STATUS_CANCELLED = 'CANCELLED';
    private static final String TASK_LIST_PATH = '/lightning/o/Task/list';

    public String messageLevel { get; private set; }
    public String messageContent { get; private set; }
    public Boolean succeeded { get; private set; }

    // Server-side fallback only. The page prefers document.referrer, because the
    // Referer header arrives without the ?filterName= that names the list view the
    // user was actually looking at, and landing them on a different list reads as
    // the update having been lost.
    public String fallbackUrl {
        get { return returnUrl(); }
    }

    public TaskQuickCloseController() {
        messageLevel = 'info';
        messageContent = '';
        succeeded = false;
    }

    public PageReference closeTask() {
        String rawId = param('id');
        String targetStatus = canonicalStatus(param('status'));

        // Task.Status is NOT a restricted picklist (proven on both staging orgs:
        // an arbitrary string saves fine), and the status arrives in a URL, so the
        // allow-list is what stops ?status=anything from being written.
        if (targetStatus == null) {
            return fail('Unsupported status. Use the Complete or Cancel column link.');
        }

        Id taskId;
        try {
            taskId = Id.valueOf(rawId);
        } catch (Exception e) {
            return fail('No task to close - the link is missing a valid record id.');
        }

        // `with sharing`: a task the user cannot see simply is not returned.
        List<Task> found = [SELECT Id, IsClosed FROM Task WHERE Id = :taskId];
        if (found.isEmpty()) {
            return fail('That task no longer exists, or you do not have access to it.');
        }
        if (found[0].IsClosed) {
            return fail('That task is already closed.');
        }

        // Partial-failure form on a single record: Task carries validation rules and
        // trigger guards (Mark Attendance status lock, CN Own TPU progress updates,
        // the ERP-1132 drop-out rule) and their message is what the user must read.
        Database.SaveResult result = Database.update(new Task(Id = taskId, Status = targetStatus), false);
        if (!result.isSuccess()) {
            return fail(result.getErrors()[0].getMessage());
        }
        succeeded = true;
        return null;
    }

    public PageReference backToList() {
        return new PageReference(returnUrl()).setRedirect(true);
    }

    private PageReference fail(String reason) {
        messageLevel = 'error';
        messageContent = reason;
        succeeded = false;
        return null;
    }

    private static String param(String name) {
        return ApexPages.currentPage() == null ? null : ApexPages.currentPage().getParameters().get(name);
    }

    @TestVisible
    private static String canonicalStatus(String raw) {
        if (STATUS_COMPLETED.equalsIgnoreCase(raw)) {
            return STATUS_COMPLETED;
        }
        if (STATUS_CANCELLED.equalsIgnoreCase(raw)) {
            return STATUS_CANCELLED;
        }
        return null;
    }

    /**
     * Back to the exact list view the user clicked from, so the row they just
     * closed is re-read rather than served from the client's cache. The referer is
     * caller-controlled, so only a Task list path is honoured - anything else
     * would turn this page into an open redirect.
     */
    @TestVisible
    private static String returnUrl() {
        String referer = ApexPages.currentPage() == null
            ? null
            : ApexPages.currentPage().getHeaders().get('Referer');
        if (String.isBlank(referer)) {
            return TASK_LIST_PATH;
        }
        Integer pathStart = referer.indexOf(TASK_LIST_PATH);
        return pathStart < 0 ? TASK_LIST_PATH : referer.substring(pathStart);
    }
}