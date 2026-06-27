-- ==================================================================
--  [06] NEW PROCEDURES & FUNCTIONS  (24)
--  Safe — objects do not exist in MOAMALAT yet
--  Target schema : MOAMALAT
--  Run as        : DBA or MOAMALAT user
-- ==================================================================

-- NEW PROCEDURE: SP_UPDATE_TASK_STATUS
CREATE OR REPLACE PROCEDURE "SP_UPDATE_TASK_STATUS" (
    p_task_id     IN NUMBER,
    p_new_status  IN VARCHAR2
)
AS
BEGIN
    UPDATE TASKS
       SET STATUS = p_new_status,
           UPDATED_AT = SYSTIMESTAMP
     WHERE ID = p_task_id;
END;
/
/

-- NEW PROCEDURE: SP_GET_TASKS_DUE_SOON
CREATE OR REPLACE PROCEDURE "SP_GET_TASKS_DUE_SOON" (
    p_hours_ahead IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT *
    FROM TASKS
    WHERE DUE_DATE BETWEEN SYSTIMESTAMP AND (SYSTIMESTAMP + INTERVAL '1' HOUR * p_hours_ahead)
      AND STATUS IN ('PENDING', 'IN_PROGRESS');
END;
/
/

-- NEW PROCEDURE: SP_GET_TASKS_BY_CREATOR
CREATE OR REPLACE PROCEDURE "SP_GET_TASKS_BY_CREATOR" (
    p_creator_email IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT *
    FROM TASKS
    WHERE JSON_VALUE(CREATOR_JSON, '$.email') = p_creator_email;
END;
/
/

-- NEW PROCEDURE: SP_GET_TASKS_BY_CORRESP
CREATE OR REPLACE PROCEDURE "SP_GET_TASKS_BY_CORRESP" (
    p_type IN NUMBER,
    p_year IN NUMBER,
    p_seq IN NUMBER,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT *
    FROM TASKS
    WHERE CORRESPONDENCE_TYPE = p_type
      AND CORRESPONDENCE_YEAR = p_year
      AND CORRESPONDENCE_SEQ = p_seq;
END;
/
/

-- NEW PROCEDURE: SP_GET_TASKS_BY_ASSIGNEE
CREATE OR REPLACE PROCEDURE "SP_GET_TASKS_BY_ASSIGNEE" (
    p_assignee_email IN VARCHAR2,
    p_cursor OUT SYS_REFCURSOR
)
AS
BEGIN
    OPEN p_cursor FOR
    SELECT *
    FROM TASKS
    WHERE JSON_VALUE(ASSIGNEE_JSON, '$.email') = p_assignee_email;
END;
/
/

-- NEW PROCEDURE: SP_DELETE_TASK
CREATE OR REPLACE PROCEDURE "SP_DELETE_TASK" (
    p_task_id IN NUMBER,
    p_creator_email IN VARCHAR2
)
AS
    v_creator_json CLOB;
    v_email_from_json VARCHAR2(255);
BEGIN
    SELECT CREATOR_JSON INTO v_creator_json FROM TASKS WHERE ID = p_task_id;

    v_email_from_json := JSON_VALUE(v_creator_json, '$.email');

    IF LOWER(v_email_from_json) != LOWER(p_creator_email) THEN
        RAISE_APPLICATION_ERROR(-20001, 'Unauthorized delete attempt. Only creator can delete the task.');
    END IF;

    DELETE FROM TASKS WHERE ID = p_task_id;
END;
/
/

-- NEW PROCEDURE: SP_CREATE_TASK
CREATE OR REPLACE PROCEDURE "SP_CREATE_TASK" (
    p_title           IN VARCHAR2,
    p_description     IN CLOB,
    p_due_date        IN TIMESTAMP,
    p_priority        IN VARCHAR2,
    p_status          IN VARCHAR2,
    p_assignee_json   IN CLOB,
    p_creator_json    IN CLOB,
    p_corr_type       IN NUMBER,
    p_corr_seq        IN NUMBER,
    p_corr_year       IN NUMBER,
    p_new_id          OUT NUMBER
)
AS
BEGIN
    INSERT INTO TASKS (
        TITLE, DESCRIPTION, DUE_DATE, PRIORITY, STATUS,
        ASSIGNEE_JSON, CREATOR_JSON,
        CORRESPONDENCE_TYPE, CORRESPONDENCE_SEQ, CORRESPONDENCE_YEAR,
        CREATED_AT, UPDATED_AT
    )
    VALUES (
        p_title, p_description, p_due_date, p_priority, p_status,
        p_assignee_json, p_creator_json,
        p_corr_type, p_corr_seq, p_corr_year,
        SYSTIMESTAMP, SYSTIMESTAMP
    )
    RETURNING ID INTO p_new_id;
END;
/
/

-- NEW PROCEDURE: PR_INVITE_USERS
CREATE OR REPLACE PROCEDURE "PR_INVITE_USERS" (
  p_conversation_id IN NUMBER,
  p_invitees        IN SYS.ODCIVARCHAR2LIST,
  p_requested_by    IN VARCHAR2
) AS
  v_is_creator NUMBER := 0;
BEGIN
  SELECT COUNT(1) INTO v_is_creator
    FROM conversation
   WHERE id = p_conversation_id AND created_by = p_requested_by;

  IF v_is_creator = 0 THEN
    RAISE_APPLICATION_ERROR(-20001, 'Only creator can invite.');
  END IF;

  IF p_invitees IS NOT NULL THEN
    FOR i IN 1 .. p_invitees.COUNT LOOP
      BEGIN
        INSERT INTO conversation_user (conversation_id, employee_id)
        VALUES (p_conversation_id, p_invitees(i));
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL;
      END;
    END LOOP;
  END IF;
END;
/
/

-- NEW PROCEDURE: PR_ENSURE_MOAMALAH
CREATE OR REPLACE PROCEDURE "PR_ENSURE_MOAMALAH" (
  p_correspondence_number IN NUMBER,
  p_hijri_year            IN NUMBER,
  p_type_id               IN NUMBER,
  p_moamalah_id           OUT NUMBER
) AS
BEGIN
  BEGIN
    SELECT id INTO p_moamalah_id
      FROM moamalah
     WHERE correspondence_number = p_correspondence_number
       AND hijri_year = p_hijri_year
       AND type_id = p_type_id;
  EXCEPTION WHEN NO_DATA_FOUND THEN
    INSERT INTO moamalah (correspondence_number, hijri_year, type_id)
      VALUES (p_correspondence_number, p_hijri_year, p_type_id)
      RETURNING id INTO p_moamalah_id;
  END;
END;
/
/

-- NEW PROCEDURE: PR_EDIT_CONV_TITLE
CREATE OR REPLACE PROCEDURE "PR_EDIT_CONV_TITLE" (
  p_conversation_id IN NUMBER,
  p_new_title       IN VARCHAR2,
  p_requested_by    IN VARCHAR2
) AS
  v_creator VARCHAR2(32);
BEGIN
  SELECT created_by INTO v_creator FROM conversation WHERE id = p_conversation_id;
  IF v_creator <> p_requested_by THEN
    RAISE_APPLICATION_ERROR(-20005, 'Only creator can edit title.');
  END IF;

  UPDATE conversation SET title = p_new_title WHERE id = p_conversation_id;
END;
/
/

-- NEW PROCEDURE: PR_EDIT_COMMENT
CREATE OR REPLACE PROCEDURE "PR_EDIT_COMMENT" (
  p_comment_id      IN NUMBER,
  p_new_text        IN CLOB,
  p_requested_by    IN VARCHAR2
) AS
  v_owner VARCHAR2(32);
BEGIN
  SELECT commented_by INTO v_owner FROM CONVERSATION_COMMENT WHERE id = p_comment_id;
  IF v_owner <> p_requested_by THEN
    RAISE_APPLICATION_ERROR(-20003, 'Only author can edit this comment.');
  END IF;

  UPDATE CONVERSATION_COMMENT
     SET comment_text = p_new_text,
         commented_at = CURRENT_TIMESTAMP
   WHERE id = p_comment_id;
END;
/
/

-- NEW PROCEDURE: PR_DELETE_CONVERSATION
CREATE OR REPLACE PROCEDURE "PR_DELETE_CONVERSATION" (
  p_conversation_id IN NUMBER,
  p_requested_by    IN VARCHAR2
) AS
  v_creator VARCHAR2(32);
BEGIN
  SELECT created_by INTO v_creator FROM conversation WHERE id = p_conversation_id;
  IF v_creator <> p_requested_by THEN
    RAISE_APPLICATION_ERROR(-20006, 'Only creator can delete conversation.');
  END IF;

  DELETE FROM CONVERSATION_COMMENT WHERE conversation_id = p_conversation_id;
  DELETE FROM conversation_user WHERE conversation_id = p_conversation_id;
  DELETE FROM conversation WHERE id = p_conversation_id;
END;
/
/

-- NEW PROCEDURE: PR_DELETE_COMMENT
CREATE OR REPLACE PROCEDURE "PR_DELETE_COMMENT" (
  p_comment_id   IN NUMBER,
  p_requested_by IN VARCHAR2
) AS
  v_owner VARCHAR2(32);
BEGIN
  SELECT commented_by INTO v_owner FROM CONVERSATION_COMMENT WHERE id = p_comment_id;
  IF v_owner <> p_requested_by THEN
    RAISE_APPLICATION_ERROR(-20004, 'Only author can delete this comment.');
  END IF;

  DELETE FROM CONVERSATION_COMMENT WHERE id = p_comment_id;
END;
/
/

-- NEW PROCEDURE: PR_CREATE_CONVERSATION
CREATE OR REPLACE PROCEDURE "PR_CREATE_CONVERSATION" (
  p_correspondence_number IN NUMBER,
  p_hijri_year            IN NUMBER,
  p_type_id               IN NUMBER,
  p_title                 IN VARCHAR2,
  p_created_by            IN VARCHAR2,
  p_invitees              IN SYS.ODCIVARCHAR2LIST,
  p_conversation_id       OUT NUMBER
) AS
  v_moamalah_id NUMBER;
BEGIN
  PR_ENSURE_MOAMALAH(p_correspondence_number, p_hijri_year, p_type_id, v_moamalah_id);

  INSERT INTO conversation (moamalah_id, title, created_by)
  VALUES (v_moamalah_id, p_title, p_created_by)
  RETURNING id INTO p_conversation_id;

  -- auto-invite creator as a participant? (optional)
  INSERT INTO conversation_user (conversation_id, employee_id)
  VALUES (p_conversation_id, p_created_by);

  IF p_invitees IS NOT NULL THEN
    FOR i IN 1 .. p_invitees.COUNT LOOP
      BEGIN
        INSERT INTO conversation_user (conversation_id, employee_id)
        VALUES (p_conversation_id, p_invitees(i));
      EXCEPTION WHEN DUP_VAL_ON_INDEX THEN NULL;
      END;
    END LOOP;
  END IF;
END;
/
/

-- NEW PROCEDURE: PR_ADD_COMMENT
CREATE OR REPLACE PROCEDURE "PR_ADD_COMMENT" (
  p_conversation_id IN NUMBER,
  p_comment_text    IN CLOB,
  p_commented_by    IN VARCHAR2,
  p_comment_id      OUT NUMBER
) AS
BEGIN
  IF FN_HAS_CONV_ACCESS(p_conversation_id, p_commented_by) = 0 THEN
    RAISE_APPLICATION_ERROR(-20002, 'No access to comment in this conversation.');
  END IF;

  INSERT INTO CONVERSATION_COMMENT (conversation_id, comment_text, commented_by)
  VALUES (p_conversation_id, p_comment_text, p_commented_by)
  RETURNING id INTO p_comment_id;
END;
/
/

-- NEW PROCEDURE: MOF_GET_OUTGOING_DR
CREATE OR REPLACE PROCEDURE "MOF_GET_OUTGOING_DR" (

    RCT1 OUT GLOBALPKG.RCT1,
    p_carrierNumber IN NUMBER,
    p_sequenceNumber IN NUMBER,
    p_reportCreationDate IN NUMBER,
    p_reportHijriYear IN NUMBER,
    p_externalUnitId IN NUMBER

)
AS
BEGIN
    OPEN RCT1 FOR
    SELECT DISTINCT 
        dr.*,
        io_receivemodes.receivemodedesc,
        io_dr_carriers.carrier_id AS carriernumber,
        io_dr_carriers.carrier_name AS carriername,
        io_outgoningdeliveryreporttype.deliveryreportdesc,
        io_outgoningdeliveryreporttype.reportid,
        dr.delevaryreportstyle,
        NVL(dr.olddeliveryreportid, 0) AS dummydeliveryreportid,
        io_deliveryreports_docids.CE_DOCUMENT_ID docid,
        io_deliveryreports_docids.ce_document_vs_id vsid
    FROM 
        io_deliveryreports dr
        INNER JOIN io_deliveryreportitems dri ON dr.deliveryreportid = dri.reportnumber 
            AND dr.reporthijricyear = dri.reporthijricyear
        LEFT OUTER JOIN io_deliveryreports_docids ON dr.DELIVERYREPORTID = io_deliveryreports_docids.REPORT_NUMBER 
            AND dr.reporthijricyear = io_deliveryreports_docids.report_year 
            AND io_deliveryreports_docids.report_type = 2
        LEFT OUTER JOIN io_outgoningdeliveryreporttype ON dr.deliveryreporttypeid = io_outgoningdeliveryreporttype.reportid
        LEFT OUTER JOIN io_receivemodes ON dr.receivemodeid = io_receivemodes.receivemodeid
        LEFT OUTER JOIN io_dr_carriers ON dr.courierid = io_dr_carriers.carrier_id
    WHERE
        (dr.courierid = p_carrierNumber OR p_carrierNumber = -1)
        AND (dr.deliveryreportid = p_sequenceNumber OR p_sequenceNumber = -1)
        AND (dr.datecreated = p_reportCreationDate OR p_reportCreationDate = -1)
        AND (dr.reporthijricyear = p_reportHijriYear OR p_reportHijriYear = -1)
        AND (p_externalUnitId = -1 OR dri.destinationid = p_externalUnitId)
    ORDER BY 
        dr.reporthijricyear NULLS FIRST,
        dr.deliveryreportid NULLS FIRST;
END;
/
/

-- NEW PROCEDURE: MENTION_USER_PROC
CREATE OR REPLACE PROCEDURE "MENTION_USER_PROC" (
  p_correspondence_number IN NUMBER,
  p_hijri_year            IN NUMBER,
  p_correspondence_type   IN NUMBER,
  p_mentioned_by          IN VARCHAR2,
  p_mentioned_user_id     IN VARCHAR2,
  p_permission_level      IN VARCHAR2,
  p_message_text          IN VARCHAR2
) AS
BEGIN
  INSERT INTO USER_MENTIONS (
    CORRESPONDENCE_NUMBER, HIJRI_YEAR, CORRESPONDENCE_TYPE,
    MENTIONED_BY, MENTIONED_USER_ID,
    PERMISSION_LEVEL, MESSAGE_TEXT,
    ISDELETED, CREATED_AT
  ) VALUES (
    p_correspondence_number, p_hijri_year, p_correspondence_type,
    p_mentioned_by, p_mentioned_user_id,
    p_permission_level, p_message_text,
    0, SYSDATE
  );
END;
/
/

-- NEW PROCEDURE: MENTION_REVOKE_PROC
CREATE OR REPLACE PROCEDURE "MENTION_REVOKE_PROC" (
  p_correspondence_number IN NUMBER,
  p_hijri_year            IN NUMBER,
  p_correspondence_type   IN NUMBER,
  p_mentioned_user_id     IN VARCHAR2
) AS
BEGIN
  UPDATE USER_MENTIONS
     SET ISDELETED = 1
   WHERE CORRESPONDENCE_NUMBER = p_correspondence_number
     AND HIJRI_YEAR           = p_hijri_year
     AND CORRESPONDENCE_TYPE  = p_correspondence_type
     AND MENTIONED_USER_ID    = p_mentioned_user_id
     AND ISDELETED = 0;
END;
/
/

-- NEW PROCEDURE: MENTION_REVOKE_BY_ID_PROC
CREATE OR REPLACE PROCEDURE "MENTION_REVOKE_BY_ID_PROC" (
  p_id IN NUMBER
) AS
BEGIN
  UPDATE USER_MENTIONS
     SET ISDELETED = 1
   WHERE ID = p_id
     AND ISDELETED = 0;
END;
/
/

-- NEW PROCEDURE: IO_SAVE_SIGNATURE_INITIAL
CREATE OR REPLACE PROCEDURE "IO_SAVE_SIGNATURE_INITIAL" 
(
  p_user_id  IN VARCHAR2,
  p_sig_data IN BLOB
) AS
  mycount INT;
BEGIN
  SELECT COUNT(*) INTO mycount FROM IO_SIGNATURES WHERE user_id = p_user_id;

  IF mycount > 0 THEN
    UPDATE IO_SIGNATURES
       SET INITIAL_IMAGE = p_sig_data
     WHERE user_id = p_user_id;
  ELSE
    INSERT INTO IO_SIGNATURES (USER_ID, INITIAL_IMAGE)
    VALUES (p_user_id, p_sig_data); 
  END IF;
END IO_SAVE_SIGNATURE_INITIAL;
/
/

-- NEW PROCEDURE: IO_ADDMULTIUSERINSTRUCTION
CREATE OR REPLACE PROCEDURE "IO_ADDMULTIUSERINSTRUCTION" (
    FORWARDING_HISTORY_ID IN NUMBER ,
    OWNER_TYPE            IN NUMBER DEFAULT -999 ,
    OWNER_ID              IN VARCHAR2 DEFAULT -999 ,
    INSTRUCTION_TEXT      IN VARCHAR2 ,
    DIRECTPROCEDURE IN VARCHAR2 
    )
AS
BEGIN
  INSERT
  INTO io_multi_user_instructions
    (
      forwarding_history_id,
      owner_type,
      owner_id,
      instruction_text,
      procedure
    )
    VALUES
    (
      IO_ADDMULTIUSERINSTRUCTION.forwarding_history_id,
      IO_ADDMULTIUSERINSTRUCTION.owner_type,
      IO_ADDMULTIUSERINSTRUCTION.owner_id,
      IO_ADDMULTIUSERINSTRUCTION.instruction_text,
      IO_ADDMULTIUSERINSTRUCTION.DIRECTPROCEDURE
    );
END IO_ADDMULTIUSERINSTRUCTIONSMOBILE;
/
/

-- NEW PROCEDURE: IO_ADDFORWARDINGSHISTORY_TRASOUL
CREATE OR REPLACE PROCEDURE "IO_ADDFORWARDINGSHISTORY_TRASOUL" 
(
forwardingId OUT INT,
correspondenceNumber IN INT,
hijricYear IN INT,
typeId IN INT,
urgencylevel IN INT,
importancelevel IN INT,
instructions IN VARCHAR2,
forwardingTime IN VARCHAR2,
reminder IN VARCHAR2,
deadline IN VARCHAR2,
systemtype IN VARCHAR2
)
AS
BEGIN 

INSERT INTO io_forwardingshistory 
(CORRESPONDENCENUMBER,
HIJRICYEAR,
TYPEID,
URGENCYLEVEL,
IMPORTANCELEVEL,
REMINDER,
DEADLINE,
FORWARDINGTIME,
INSTRUCTIONS,SYSTEMTYPE) 
VALUES 
(IO_ADDFORWARDINGSHISTORY_TRASOUL.correspondenceNumber,
IO_ADDFORWARDINGSHISTORY_TRASOUL.hijricYear,
IO_ADDFORWARDINGSHISTORY_TRASOUL.typeId,
IO_ADDFORWARDINGSHISTORY_TRASOUL.urgencylevel,
IO_ADDFORWARDINGSHISTORY_TRASOUL.importancelevel,
IO_ADDFORWARDINGSHISTORY_TRASOUL.reminder,
IO_ADDFORWARDINGSHISTORY_TRASOUL.deadline,
IO_ADDFORWARDINGSHISTORY_TRASOUL.forwardingTime,
IO_ADDFORWARDINGSHISTORY_TRASOUL.instructions,
IO_ADDFORWARDINGSHISTORY_TRASOUL.systemtype); 

IO_ADDFORWARDINGSHISTORY_TRASOUL.forwardingId := GLOBALPKG.IDENTITY;

END;
/
/

-- NEW PROCEDURE: IO_ADDFORWARDINGDETAIL_Trasoul
CREATE OR REPLACE PROCEDURE "IO_ADDFORWARDINGDETAIL_Trasoul" 
(
forwardingDetailId OUT INT,
forwardingHistoryId IN INT,
forwardingType IN INT,
participantUserId IN VARCHAR2,
participantDeptId IN INT,
participantType IN INT,
systemtype IN INT
)
AS
BEGIN 

INSERT INTO io_forwardingdetails 
(FORWARDINGID,
FORWARDINGTYPE,
PARTICIPANTUSERID,
PARTICIPANTDEPTID,
PARTICIPANTTYPE,
systemtype) 
VALUES 
(IO_ADDFORWARDINGDETAIL_Trasoul.forwardingHistoryId,
IO_ADDFORWARDINGDETAIL_Trasoul.FORWARDINGTYPE,
IO_ADDFORWARDINGDETAIL_Trasoul.PARTICIPANTUSERID,
IO_ADDFORWARDINGDETAIL_Trasoul.PARTICIPANTDEPTID,
IO_ADDFORWARDINGDETAIL_Trasoul.PARTICIPANTTYPE,
IO_ADDFORWARDINGDETAIL_Trasoul.systemtype); 

IO_ADDFORWARDINGDETAIL_Trasoul.forwardingDetailId := GLOBALPKG.IDENTITY;

END;
/
/

-- NEW FUNCTION: FN_HAS_CONV_ACCESS
CREATE OR REPLACE FUNCTION "FN_HAS_CONV_ACCESS" (
  p_conversation_id IN NUMBER,
  p_employee_id     IN VARCHAR2
) RETURN NUMBER IS
  v_count NUMBER := 0;
BEGIN
  SELECT COUNT(1)
    INTO v_count
    FROM CONVERSATION c
   WHERE c.ID = p_conversation_id
     AND (c.CREATED_BY = p_employee_id
          OR EXISTS (SELECT 1 FROM CONVERSATION_USER u
                      WHERE u.CONVERSATION_ID = c.ID
                        AND u.EMPLOYEE_ID = p_employee_id));
  RETURN CASE WHEN v_count > 0 THEN 1 ELSE 0 END;
END;
/
/
