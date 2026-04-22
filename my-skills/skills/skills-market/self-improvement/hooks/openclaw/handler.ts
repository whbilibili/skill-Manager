/**
 * Self-Improvement Reminder Handler (CatPaw Desk compatible)
 *
 * This file stays under hooks/openclaw for backward compatibility only.
 * The logic is intentionally framework-agnostic: if an event context has
 * a bootstrapFiles array, a reminder virtual file will be appended.
 */

export type GenericEvent = {
  type?: string;
  action?: string;
  sessionKey?: string;
  context?: {
    bootstrapFiles?: Array<{ path: string; content: string; virtual?: boolean }>;
    [key: string]: unknown;
  };
  [key: string]: unknown;
};

const REMINDER_CONTENT = `## Self-Improvement Reminder

After finishing tasks, evaluate whether you should log to .learnings/:
- correction from user feedback
- tool or command failure
- discovered better approach
- recurring issue that should be promoted

If reusable across sessions, consider memory_write or skill extraction.`;

const handler = async (event: GenericEvent): Promise<void> => {
  if (!event || typeof event !== 'object') return;
  if (!event.context || typeof event.context !== 'object') return;

  const files = event.context.bootstrapFiles;
  if (!Array.isArray(files)) return;

  files.push({
    path: 'SELF_IMPROVEMENT_REMINDER.md',
    content: REMINDER_CONTENT,
    virtual: true,
  });
};

export default handler;
