# Complete Workflow Overview

The Moamalat Correspondence System is organized into five interconnected activity flows. Each flow operates independently while interacting with the others through defined transition points. Correspondence created and sent in **AD-01** is delivered to the shared inbox managed by **AD-02**. If a deadline is assigned, **AD-04** initiates reminder and escalation tracking. Correspondence may be recalled by the sender through **AD-03**, and users can be mentioned at any stage via **AD-05**. In the workflow diagrams, solid arrows represent standard process paths, while dashed arrows indicate optional or conditional transitions.

## AD-01 — Create and Send Correspondence

The correspondence lifecycle begins in **Draft** status. A document remains in this state until the author explicitly chooses to send it. The **"Ready to Send?"** decision point ensures that incomplete correspondence cannot leave the drafting stage prematurely.

Before sending, the author selects the intended recipients and may optionally define a deadline. Once **Send** is executed, the correspondence transitions to **Sent** status and can no longer revert to Draft.

Sending initiates several downstream actions:

* The correspondence is delivered to the recipient's inbox for processing (**AD-02**).
* If a deadline has been specified, reminder and escalation tracking is activated (**AD-04**). The tracking period begins at the moment of sending, not when the deadline was initially entered.
* The sender retains the ability to recall the correspondence through the recall process (**AD-03**).

This workflow also serves as the re-entry point for correspondence returned by a recipient (from **AD-02**) or resent following a successful recall (from **AD-03**).

## AD-02 — Receive and Process Correspondence

Once sent, correspondence is delivered to a shared inbox accessible to authorized handlers. When a user opens an item, the system applies a lock to prevent concurrent processing and eliminate the risk of duplicate or conflicting actions.

The assigned handler may then perform one of the following actions:

* **Forward** the correspondence to another recipient, restarting the processing cycle.
* **Unlock** the item, releasing it for processing by another authorized user without taking further action.
* **Return to Sender**, transferring control back to **AD-01** for revision and resubmission.

If the original sender initiates a recall, the correspondence is removed from the inbox through **AD-03**.

## AD-03 — Recall Correspondence

The recall process allows a sender to retract correspondence after it has been sent. Recall may be initiated from the Create & Send workflow, the Sent Items page, or the Search page.

Upon initiation, the system verifies whether the recipient has already opened or acted on the correspondence:

* If the correspondence has been accessed or processed, the recall request is **blocked**, and no further action is taken.
* If the correspondence has not yet been accessed, it is removed from the recipient's inbox, moved to a **Recalled** folder, and a persistent audit notification is generated.

The sender may subsequently resend the correspondence by re-entering **AD-01** at the recipient selection step. The notification remains available until it is formally dismissed.

Recall does not permit deletion; the correspondence remains preserved for audit and traceability purposes.

## AD-04 — Deadline Management, Reminders, and Escalation

For correspondence with an assigned deadline, this workflow ensures timely follow-up and escalation.

Two reminder notifications are automatically scheduled and triggered at **50%** and **75%** of the available time before the deadline.

Following each reminder, the system evaluates whether action has been taken:

* If the correspondence has been addressed, it is marked **Resolved**, and the workflow concludes.
* If no action has been taken, the item is escalated to the next authority level.

Escalation progresses through the following hierarchy:

1. Direct Manager
2. Deputy Governor's Office
3. Deputy Governor

At each level, the same **Resolve or Escalate** decision process applies. The Deputy Governor represents the final escalation authority; therefore, if no action is taken at this stage, the escalation process terminates.

## AD-05 — Mention

The mention feature provides an informational notification mechanism without assigning ownership or responsibility.

A handler may mention an individual user, department, or group. The mentioned party receives an **FYI notification** and is granted **read-only access** to the correspondence.

Mentioned users can view the correspondence but cannot modify, process, forward, or otherwise act upon it. Because mentions do not alter workflow ownership, status, or routing, they may be initiated at any point within any workflow.
