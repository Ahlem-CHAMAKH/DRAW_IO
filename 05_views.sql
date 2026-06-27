-- ==================================================================
--  [05] VIEWS  (New: 1  Changed: 1)
--  Safe — CREATE OR REPLACE does not affect data
--  Target schema : MOAMALAT
--  Run as        : DBA or MOAMALAT user
-- ==================================================================

-- New VIEW: WF_DRAFTS
CREATE OR REPLACE FORCE VIEW "WF_DRAFTS" 
 ( "SRC_TYPE", "SEQUENCENUMBER", "HIJRICYEAR", "SUBJECT", "FROM_USER", "CREATE_TIME"
  )  AS 
  SELECT

      'INCOMING'         AS SRC_TYPE,

      i.CORRESPONDENCENUMBER AS SEQUENCENUMBER,

      i.HIJRICYEAR           AS HIJRICYEAR,

      i.CORRESPONDENCESUBJECT              AS SUBJECT,

      i.RECEIVEDBY           AS FROM_USER,

      i.DATE_CREATED       AS CREATE_TIME     -- use your actual create date column

  FROM IO_INCOMING i

  WHERE NOT EXISTS (

    SELECT 1 FROM WORKFLOW_WORKITEMS w

     WHERE w.SEQUENCENUMBER = i.CORRESPONDENCENUMBER

       AND w.HIJRICYEAR      = i.HIJRICYEAR

  ) AND NOT EXISTS (

    SELECT 1 FROM WORKFLOW_WORKITEMS_HIST h

     WHERE h.SEQUENCENUMBER = i.CORRESPONDENCENUMBER

       AND h.HIJRICYEAR      = i.HIJRICYEAR

  )
 
  UNION ALL
 
  SELECT

      'INTERNAL'         AS SRC_TYPE,

      n.CORRESPONDENCENUMBER,

      n.HIJRICYEAR,

      n.CORRESPONDENCESUBJECT,

      n.SENTBY,

      n.DATE_CREATED

  FROM IO_INTERNAL n

  WHERE NOT EXISTS (

    SELECT 1 FROM WORKFLOW_WORKITEMS w

     WHERE w.SEQUENCENUMBER = n.CORRESPONDENCENUMBER

       AND w.HIJRICYEAR      = n.HIJRICYEAR

  ) AND NOT EXISTS (

    SELECT 1 FROM WORKFLOW_WORKITEMS_HIST h

     WHERE h.SEQUENCENUMBER = n.CORRESPONDENCENUMBER

       AND h.HIJRICYEAR      = n.HIJRICYEAR

  )
 
  UNION ALL
 
  SELECT

      'OUTGOING'         AS SRC_TYPE,

      o.CORRESPONDENCENUMBER,

      o.HIJRICYEAR,

      o.CORRESPONDENCESUBJECT,

      o.SENTBY,

      o.DATE_CREATED

  FROM IO_OUTGOING o

  WHERE NOT EXISTS (

    SELECT 1 FROM WORKFLOW_WORKITEMS w

     WHERE w.SEQUENCENUMBER = o.CORRESPONDENCENUMBER

       AND w.HIJRICYEAR      = o.HIJRICYEAR

  ) AND NOT EXISTS (

    SELECT 1 FROM WORKFLOW_WORKITEMS_HIST h

     WHERE h.SEQUENCENUMBER = o.CORRESPONDENCENUMBER

       AND h.HIJRICYEAR      = o.HIJRICYEAR

  );

-- Changed VIEW: IO_SEARCH_INTERNAL_VIEW
CREATE OR REPLACE FORCE VIEW "IO_SEARCH_INTERNAL_VIEW" 
 ( "F_CLASS", "PARTICIPANTUSERID", "PARTICIPANTDEPTID", "FORWARDINGTYPE", "CORRESPONDENCESUBJECT", "TOUNITID", "CORRESPONDENCEDATE", "CREATOR", "CORRESPONDENCENUMBER", "HIJRICYEAR", "CORRESPONDENCETYPE", "CORRESPONDENCESUBTYPEID", "CORRESPONDENCECATEGORYID", "CONFIDENTIALITYID", "FROMUNITID", "FROMUNITNAME", "SECTOR_ID", "WF_LAUNCHED", "MONUMBER", "IS_SUPPLY_CORR", "REMARKS", "CIVILID", "REFERENCECODE"
  )  AS 
  ( SELECT DISTINCT 1 AS F_Class,
  io_forwardingdetails.participantuserid,
  io_forwardingdetails.participantdeptid,
  io_forwardingdetails.forwardingtype,
  io_internal.correspondencesubject,
  io_internaldestinations.departmentid AS toUnitId,
  io_internal.correspondencedate,
  io_internal.sentby AS creator,
  io_internal.correspondencenumber,
  io_internal.hijricyear,
  3                                AS correspondencetype,
  io_internal.correspondenceTypeId AS correspondenceSubTypeId,
  io_internal.correspondencecategoryid,
  io_internal.confidentialityid,
  io_internal.sentbydepartmentid AS fromUnitId,
  io_departments.departmentname  AS fromUnitName,
  io_departments.sector_id,
  io_internal.wf_launched,
  io_internal.ministerofficenumber AS MONumber,
  io_internal.is_supply_corr,
  io_internal.remarks,
  io_internal.civilid,
  io_internal.referencecode
FROM io_internal
LEFT OUTER JOIN io_forwardingshistory
ON io_forwardingshistory.typeid      = 3
AND io_internal.correspondencenumber = io_forwardingshistory.correspondencenumber
AND io_internal.hijricyear           = io_forwardingshistory.hijricyear
LEFT OUTER JOIN io_forwardingdetails
ON io_forwardingshistory.forwardingid = io_forwardingdetails.forwardingid
LEFT OUTER JOIN io_internaldestinations
ON IO_INTERNAL.correspondencenumber = IO_INTERNALDESTINATIONS.correspondencenumber
AND IO_INTERNAL.hijricyear          = IO_INTERNALDESTINATIONS.hijricyear
INNER JOIN io_departments
ON io_internal.sentbydepartmentid = io_departments.departmentid
);
