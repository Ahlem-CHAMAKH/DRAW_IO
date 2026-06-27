-- ==================================================================
--  [08] CHANGED PROCEDURES/FUNCTIONS — CODE ONLY  (80)
--  No parameter changes — safe to apply (CREATE OR REPLACE)
--  Target schema : MOAMALAT
--  Run as        : DBA or MOAMALAT user
-- ==================================================================

-- CHANGED PROCEDURE: WS_PENSION_GETFORWARDHISTORY
CREATE OR REPLACE PROCEDURE "WS_PENSION_GETFORWARDHISTORY" 
(
    correspondenceNumber IN INT,
    hijricYear IN INT,
    typeId IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR 
SELECT DISTINCT
io_forwardingshistory.FORWARDINGID,
io_forwardingshistory.CORRESPONDENCENUMBER,
io_forwardingshistory.HIJRICYEAR,
io_forwardingshistory.TYPEID,
io_forwardingshistory.URGENCYLEVEL,
io_forwardingshistory.IMPORTANCELEVEL,
io_forwardingshistory.FORWARDINGTIME,
io_forwardingshistory.REMINDER,
io_forwardingshistory.DEADLINE,
NVL(Tmp_UserComments.HasRemarks, 0) AS HasRemarks,
io_forwardingshistory.INSTRUCTIONS,
src.participantuserid,
src.participantdeptid,
src.participanttype,
srcEmps.fullname AS fromemployeename,
srcDepts.departmentname AS fromdepartmentname,
srcQueues.departmentnamear AS fromqueuedeptname,
dest.participanttype,
destEmps.departmentid AS toDepartmentId,
destDepts.departmentname AS toDepartmentName,
destQueues.departmentid AS toQueueDepartmentId,
destQueues.departmentnamear AS toQueueDeptName

FROM  io_forwardingshistory INNER JOIN io_incoming 
      ON io_forwardingshistory.correspondencenumber = io_incoming.correspondencenumber AND io_forwardingshistory.hijricyear = io_incoming.hijricyear AND io_incoming.clone_Id = 2
                            INNER JOIN io_forwardingdetails src
      ON io_forwardingshistory.FORWARDINGID = src.FORWARDINGID AND src.forwardingtype = 1 --join with the "ForwardingType = From" detail...
                            LEFT JOIN io_employees srcEmps
      ON lower(src.participantuserid) = lower(srcEmps.userid)
                            LEFT JOIN io_departments srcDepts
      ON src.participantdeptid = srcDepts.departmentid
                            LEFT JOIN io_departmentqueues srcQueues
      ON src.participantdeptid = srcQueues.departmentid
      
                            LEFT JOIN io_forwardingdetails dest   -- LEFT JOIN because "save action" forwardings do not have a destination
      ON io_forwardingshistory.FORWARDINGID = dest.FORWARDINGID AND dest.forwardingtype in (2,3) --join with the "ForwardingType = To and CC" detail...
                            LEFT JOIN io_employees destEmps
      ON lower(dest.participantuserid) = lower(destEmps.userid)
                            LEFT JOIN io_departments destDepts
      ON destEmps.departmentid = destDepts.departmentid
                            LEFT JOIN io_departmentqueues destQueues
      ON lower(dest.participantuserid) = lower(destQueues.queuename)
      
                            LEFT JOIN (SELECT FORWARDINGID, CAST(COUNT(*) AS NUMBER(2)) HasRemarks FROM io_usercomments WHERE typeid = WS_PENSION_GETFORWARDHISTORY.typeId GROUP BY FORWARDINGID) Tmp_UserComments
      ON io_forwardingshistory.FORWARDINGID = Tmp_UserComments.FORWARDINGID

WHERE (io_forwardingshistory.CorrespondenceNumber = WS_PENSION_GETFORWARDHISTORY.correspondenceNumber)
AND (io_forwardingshistory.HijricYear = WS_PENSION_GETFORWARDHISTORY.hijricYear)
AND (io_forwardingshistory.typeId = WS_PENSION_GETFORWARDHISTORY.typeId)

--ORDER BY io_forwardingshistory.FORWARDINGID;
--ORDER BY TO_DATE(FORWARDINGTIME, 'DD/MM/YYYY HH24:MI:SS');  -- some hijri dates are invalid as gregorian such as 30-FEB (max days in FEB is 29)
--ORDER BY TO_DATE(FORWARDINGTIME, 'DD/MM/YYYY HH24:MI:SS','nls_calendar=''English Hijrah'''); -- MAY FAIL, BECAUSE FORWARDINGTIME CAN HAVE HOUR 24:00:00 INSTEAD OF 00:00:00, and to_date takes range 0-23
ORDER BY TO_DATE(REGEXP_REPLACE(forwardingtime, '(24)\:([[:digit:]]{2})\:([[:digit:]]{2})', '00:\2:\3'), 'DD/MM/YYYY HH24:MI:SS','nls_calendar=''English Hijrah''');

END;
/
/

-- CHANGED PROCEDURE: WS_PENSION_GETFORWARDDETAILS
CREATE OR REPLACE PROCEDURE "WS_PENSION_GETFORWARDDETAILS" 
(
    forwardingid IN INT,
    forwardingtype IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR 
SELECT
io_forwardingdetails.forwardingdetailid,
io_forwardingdetails.forwardingid,
io_forwardingdetails.forwardingtype,
io_forwardingdetails.participantuserid,
io_forwardingdetails.participantdeptid,
io_forwardingdetails.participanttype,
io_employees.fullname AS employeename,
io_departments.departmentname,
io_departmentqueues.departmentnamear AS queuedeptname
FROM io_forwardingdetails LEFT JOIN io_employees
    ON lower(io_forwardingdetails.participantuserid) = lower(io_employees.userid)
                          LEFT JOIN io_departments
    ON io_forwardingdetails.participantdeptid = io_departments.departmentid
                          LEFT JOIN io_departmentqueues
    ON io_forwardingdetails.participantdeptid = io_departmentqueues.departmentid

WHERE (io_forwardingdetails.forwardingid = WS_PENSION_GETFORWARDDETAILS.forwardingid)
AND (WS_PENSION_GETFORWARDDETAILS.forwardingtype = -1 OR io_forwardingdetails.forwardingtype = WS_PENSION_GETFORWARDDETAILS.forwardingtype)

ORDER BY io_forwardingdetails.FORWARDINGID;

END;
/
/

-- CHANGED PROCEDURE: WS_PENSION_GETCORRHISTORY
CREATE OR REPLACE PROCEDURE "WS_PENSION_GETCORRHISTORY" 
(
    correspondenceNumber IN INT,
    hijricYear IN INT,
    typeId IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR 
SELECT DISTINCT
io_forwardingshistory.FORWARDINGID,
io_forwardingshistory.CORRESPONDENCENUMBER,
io_forwardingshistory.HIJRICYEAR,
io_forwardingshistory.TYPEID,
io_forwardingshistory.URGENCYLEVEL,
io_forwardingshistory.IMPORTANCELEVEL,
io_forwardingshistory.FORWARDINGTIME,
io_forwardingshistory.REMINDER,
io_forwardingshistory.DEADLINE,
NVL(Tmp_UserComments.HasRemarks, 0) AS HasRemarks,
io_forwardingshistory.INSTRUCTIONS,
src.participantuserid,
src.participantdeptid,
src.participanttype,
srcEmps.fullname AS fromemployeename,
srcDepts.departmentname AS fromdepartmentname,
srcQueues.departmentnamear AS fromqueuedeptname,
dest.participanttype,
destEmps.fullname AS toEmployeeName,
destEmps.departmentid AS toDepartmentId,
destDepts.departmentname AS toDepartmentName,
destQueues.departmentid AS toQueueDepartmentId,
destQueues.departmentnamear AS toQueueDeptName

FROM  io_forwardingshistory INNER JOIN io_incoming 
      ON io_forwardingshistory.correspondencenumber = io_incoming.correspondencenumber AND io_forwardingshistory.hijricyear = io_incoming.hijricyear AND io_incoming.clone_Id = 2
                            INNER JOIN io_forwardingdetails src
      ON io_forwardingshistory.FORWARDINGID = src.FORWARDINGID AND src.forwardingtype = 1 --join with the "ForwardingType = From" detail...
                            LEFT JOIN io_employees srcEmps
      ON lower(src.participantuserid) = lower(srcEmps.userid)
                            LEFT JOIN io_departments srcDepts
      ON src.participantdeptid = srcDepts.departmentid
                            LEFT JOIN io_departmentqueues srcQueues
      ON src.participantdeptid = srcQueues.departmentid
      
                            LEFT JOIN io_forwardingdetails dest   -- LEFT JOIN because "save action" forwardings do not have a destination
      ON io_forwardingshistory.FORWARDINGID = dest.FORWARDINGID AND dest.forwardingtype in (2,3) --join with the "ForwardingType = To and CC" detail...
                            LEFT JOIN io_employees destEmps
      ON lower(dest.participantuserid) = lower(destEmps.userid)
                            LEFT JOIN io_departments destDepts
      ON destEmps.departmentid = destDepts.departmentid
                            LEFT JOIN io_departmentqueues destQueues
      ON lower(dest.participantuserid) = lower(destQueues.queuename)
      
                            LEFT JOIN (SELECT FORWARDINGID, CAST(COUNT(*) AS NUMBER(2)) HasRemarks FROM io_usercomments WHERE typeid = WS_PENSION_GETCORRHISTORY.typeId GROUP BY FORWARDINGID) Tmp_UserComments
      ON io_forwardingshistory.FORWARDINGID = Tmp_UserComments.FORWARDINGID

WHERE (io_forwardingshistory.CorrespondenceNumber = WS_PENSION_GETCORRHISTORY.correspondenceNumber)
AND (io_forwardingshistory.HijricYear = WS_PENSION_GETCORRHISTORY.hijricYear)
AND (io_forwardingshistory.typeId = WS_PENSION_GETCORRHISTORY.typeId)

--ORDER BY io_forwardingshistory.FORWARDINGID;
--ORDER BY TO_DATE(FORWARDINGTIME, 'DD/MM/YYYY HH24:MI:SS');  -- some hijri dates are invalid as gregorian such as 30-FEB (max days in FEB is 29)
--ORDER BY TO_DATE(FORWARDINGTIME, 'DD/MM/YYYY HH24:MI:SS','nls_calendar=''English Hijrah'''); -- MAY FAIL, BECAUSE FORWARDINGTIME CAN HAVE HOUR 24:00:00 INSTEAD OF 00:00:00, and to_date takes range 0-23
ORDER BY TO_DATE(REGEXP_REPLACE(forwardingtime, '(24)\:([[:digit:]]{2})\:([[:digit:]]{2})', '00:\2:\3'), 'DD/MM/YYYY HH24:MI:SS','nls_calendar=''English Hijrah''');

END;
/
/

-- CHANGED PROCEDURE: WS_ADMIN_UPDATEEMPLOYEE
CREATE OR REPLACE PROCEDURE "WS_ADMIN_UPDATEEMPLOYEE" 
(
pNationalNumber IN INT,
pFullName IN VARCHAR2 DEFAULT NULL,
pUserId IN VARCHAR2 DEFAULT NULL,
pDepartmentId IN INT DEFAULT NULL,
pJobTitle IN VARCHAR2 DEFAULT NULL,
pBackupId IN INT DEFAULT -1,
pBackupStartDate IN INT,
pBackupEndDate IN INT,
pEnabledOptionsMask IN INT DEFAULT 0,
pEmployeeId IN INT,
pIsActive IN INT DEFAULT 1,
pForwardingToList IN INT DEFAULT 1,
pOldNationalNumber IN INT,
pResult OUT INT
)
AS
BEGIN
      pResult := 1;
      
      UPDATE IO_EMPLOYEES SET NATIONALNUMBER = pNationalNumber,
        FULLNAME = pFullName, 
        USERID = pUserId, 
        DEPARTMENTID = pDepartmentId,
        JOBTITLE = pJobTitle,
        ISACTIVE = pIsActive
      WHERE EMPLOYEEID = pOldNationalNumber;
      
      UPDATE IO_EMPLOYEESCONFIGS SET ENABLEDOPTIONSMASK = pEnabledOptionsMask,
      FORWARDINGTOLIST = pForwardingToList
      WHERE EMPLOYEEID = pNationalNumber;
        
      DELETE FROM IO_EMPLOYEEBACKUP WHERE EMPLOYEEID = pNationalNumber;
      
      IF pBackupId > -1 THEN
          INSERT INTO IO_EMPLOYEEBACKUP(EMPLOYEEID, BACKUPID, STARTDATE, ENDDATE) 
            VALUES(pNationalNumber, pBackupId, pBackupStartDate, pBackupEndDate);      
      END IF;
        
      COMMIT;
      
EXCEPTION
  WHEN OTHERS THEN
    pResult := SQLCODE;
    ROLLBACK;
END;
/
/

-- CHANGED PROCEDURE: WS_ADMIN_GETEMPLOYEES
CREATE OR REPLACE PROCEDURE "WS_ADMIN_GETEMPLOYEES" 
(
  DOMAIN_ID IN VARCHAR2 DEFAULT NULL,
  EMP_NO IN INT DEFAULT NULL,
  DEPARTMENT_CODE IN INT DEFAULT -1,
  RCT1 IN OUT GLOBALPKG.RCT1
)
AS
BEGIN 
OPEN RCT1 FOR
SELECT
ROWNUM AS ROWNO,
IO_EMPLOYEES.EMPLOYEEID,
IO_EMPLOYEES.NATIONALNUMBER,
IO_EMPLOYEES.FULLNAME,
IO_EMPLOYEES.USERID,
IO_EMPLOYEES.DEPARTMENTID,
IO_DEPARTMENTS.DEPARTMENTNAME,
IO_EMPLOYEES.JOBTITLE,
IO_EMPLOYEES.ISACTIVE,
BACKUPEMP.EMPLOYEEID AS BACKUPID,
BACKUPEMP.USERID AS BACKUPUSERID,
IO_EMPLOYEEBACKUP.STARTDATE,
IO_EMPLOYEEBACKUP.ENDDATE,
IO_EMPLOYEESCONFIGS.ENABLEDOPTIONSMASK,
IO_EMPLOYEESCONFIGS.FORWARDINGTOLIST,
IO_DEPARTMENTS.EBS_DEPARTMENT_ID

FROM IO_EMPLOYEES INNER JOIN IO_EMPLOYEESCONFIGS ON IO_EMPLOYEES.EMPLOYEEID = IO_EMPLOYEESCONFIGS.EMPLOYEEID
INNER JOIN IO_DEPARTMENTS ON IO_EMPLOYEES.DEPARTMENTID = IO_DEPARTMENTS.DEPARTMENTID
LEFT JOIN io_employeebackup ON IO_EMPLOYEES.EMPLOYEEID = io_employeebackup.EMPLOYEEID
LEFT JOIN IO_EMPLOYEES backupemp ON io_employeebackup.backupid = backupemp.EMPLOYEEID

WHERE (IO_EMPLOYEES.USERID IS NOT NULL)
AND (WS_ADMIN_GETEMPLOYEES.DOMAIN_ID IS NULL OR LOWER(IO_EMPLOYEES.USERID) = LOWER(WS_ADMIN_GETEMPLOYEES.DOMAIN_ID))
AND (WS_ADMIN_GETEMPLOYEES.EMP_NO IS NULL OR LOWER(IO_EMPLOYEES.EMPLOYEEID) = LOWER(WS_ADMIN_GETEMPLOYEES.EMP_NO))
AND (WS_ADMIN_GETEMPLOYEES.DEPARTMENT_CODE = -1 OR IO_EMPLOYEES.DEPARTMENTID = WS_ADMIN_GETEMPLOYEES.DEPARTMENT_CODE)
ORDER BY FULLNAME;
END;
/
/

-- CHANGED PROCEDURE: WCC_GET_SEQUENCE
CREATE OR REPLACE PROCEDURE "WCC_GET_SEQUENCE" 
(
  p_hijricYear IN NUMBER,
  p_sequence_number out NUMBER
 ) 
 
AS
BEGIN 

  BEGIN
    SELECT SEQUENCE_NO INTO p_sequence_number FROM WCC_SEQUENCE
    WHERE hijric_year = p_hijricyear
    FOR UPDATE OF SEQUENCE_NO;

    EXCEPTION WHEN NO_DATA_FOUND THEN p_sequence_number := 0;
  END;

  IF p_sequence_number = 0 THEN
  BEGIN
    p_sequence_number := 1;
    INSERT INTO WCC_SEQUENCE VALUES(p_sequence_number, p_hijricyear);
  END;
  ELSE
  BEGIN
    p_sequence_number := p_sequence_number + 1;
    UPDATE WCC_SEQUENCE SET SEQUENCE_NO = p_sequence_number WHERE hijric_year = p_hijricyear;
  END;
  END IF;

  COMMIT;

END;
/
/

-- CHANGED PROCEDURE: MOF_GET_INCOMING_DR_ITEMS
CREATE OR REPLACE PROCEDURE "MOF_GET_INCOMING_DR_ITEMS" 
 (p_deliveryReportId IN NUMBER,
	p_reportHijriYear IN NUMBER,
  RCT1  IN  OUT GLOBALPKG.RCT1) AS
BEGIN
   OPEN RCT1 FOR
     SELECT   DISTINCT

   IO_INCOMING_DR_TITEMS.CorrespondenceNumber,
   IO_INCOMING_DR_TITEMS.HijricYear,
   NVL(IO_incoming.MINISTEROFFICENUMBER,0) as DummyCorrespondenceNumber,
   IO_INCOMING_DR_TITEMS.HijricYear as DummyHijricYear,

   case when io_incoming.CORRESPONDENCESOURCETYPE = 1 then (IO_ExternalUnits.EXTERNALUNITDESC || nvl(' - ' || io_incoming.SENDERDETAILS,''))
            else ( SoursceDepartment.DEPARTMENTNAME  || nvl(' - ' || io_incoming.SENDERDETAILS,'')) end as EXTERNALUNITDESC,
   io_incoming.CORRESPONDENCESOURCEID,
   io_incoming.CorrespondenceDate,
   io_incoming.CorrespondenceSubject,

   io_correspondencetypes.CORRESPONDENCETYPEDESC,
   io_correspondencetypes.CORRESPONDENCETYPEID,
   ' ' as letterTypeDesc,  --IO_LETTERTYPES.letterdesc as letterTypeDesc,
    1 as letterTypeID,  --IO_INCOMINGDestinations.LETTERTYPEID as letterTypeID,

   io_incoming.CORRESPONDENCEATTACHMENTS as ATTACHMENT,
   nvl(io_incoming.SENDERDETAILS,'') as SourceAddress,
   destinationDepartments.departmentname as destinationDepartment,
   IO_INCOMING_DR_TITEMS.DestinationId,

   io_incoming.EXTERNALNUMBER,
   io_incoming.EXTERNALDATE,

   RECEIVEDBYDEPARTMENT.DEPARTMENTNAME as RECEIVEDBYDEPARTMENT,

   io_incoming.CONFIDENTIALITYID ,

   --IO_INCOMINGDestinations.UNITTYPEID
  -- ,  nvl(REGIONNAME , '??? ????') as REGIONNAME ,
   RANK() OVER (PARTITION BY IO_INCOMING_DR_TITEMS.DestinationId ORDER BY IO_INCOMING_DR_TITEMS.CorrespondenceNumber ) as counter
   FROM
  IO_INCOMING_DR_TITEMS,
	IO_INCOMINGDestinations,
	IO_ExternalUnits,
	io_incoming,
  io_correspondencetypes,
  io_departments destinationDepartments,
  io_departments SoursceDepartment,
  io_departments RECEIVEDBYDEPARTMENT--,
--  IO_LETTERTYPES ,
--  io_regions,
--  io_regionmembers
   WHERE
   IO_INCOMING_DR_TITEMS.CorrespondenceNumber = IO_INCOMINGDestinations.CorrespondenceNumber AND
   IO_INCOMING_DR_TITEMS.HijricYear = IO_INCOMINGDestinations.HijricYear AND
   IO_INCOMING_DR_TITEMS.DestinationId = IO_INCOMINGDestinations.DEPARTMENTID AND
   io_incoming.CORRESPONDENCESOURCEID = IO_ExternalUnits.EXTERNALUNITID(+) AND
   io_incoming.CORRESPONDENCESOURCEID = SoursceDepartment.DEPARTMENTID(+) AND

   --IO_INCOMINGDestinations.ReceiveModeId = IO_ReceiveModes.ReceiveModeId AND
   IO_INCOMING_DR_TITEMS.CorrespondenceNumber = io_incoming.CorrespondenceNumber AND
   IO_INCOMING_DR_TITEMS.HijricYear = io_incoming.HijricYear AND

   IO_INCOMING_DR_TITEMS.DESTINATIONID = destinationDepartments.DEPARTMENTID (+) AND
   --IO_INCOMINGDestinations.LETTERTYPEID = IO_LETTERTYPES.LETTERTYPEID (+) AND
   --io_regions.REGIONID(+) = io_regionmembers.REGIONID and
   --IO_INCOMINGDestinations.CORRESPONDENCEDESTINATIONID = io_regionmembers.MEMBERID(+) and
   io_incoming.RECEIVEDBYDEPARTMENTID = RECEIVEDBYDEPARTMENT.DEPARTMENTID (+) AND
   (IO_INCOMING_DR_TITEMS.ReportNumber = p_deliveryReportId) AND(IO_INCOMING_DR_TITEMS.ReportHijricYear = p_reportHijriYear)
    and    io_incoming.CORRESPONDENCETYPEID = io_correspondencetypes.CORRESPONDENCETYPEID
    ORDER BY --REGIONNAME ,
    IO_INCOMING_DR_TITEMS.DestinationId, counter,
    IO_INCOMING_DR_TITEMS.HijricYear NULLS FIRST,IO_INCOMING_DR_TITEMS.CorrespondenceNumber NULLS FIRST;

end;
/
/

-- CHANGED PROCEDURE: MOF_GET_DR_GROUPBYDESTINATION
CREATE OR REPLACE PROCEDURE "MOF_GET_DR_GROUPBYDESTINATION" (p_deliveryReportId IN NUMBER,
	p_reportHijriYear IN NUMBER, RCT1  IN  OUT GLOBALPKG.RCT1) AS
BEGIN
   OPEN RCT1 FOR
     SELECT   
     
   
   NVL(IO_outgoing.MINISTEROFFICENUMBER,0) as DummyCorrespondenceNumber,
   IO_DeliveryReportItems.HijricYear as DummyHijricYear,
   IO_DeliveryReportItems.DestinationId,
   case when IO_OutgoingDestinations.UNITTYPEID = 1 then IO_ExternalUnits.EXTERNALUNITDESC else DestinationDepartment.DEPARTMENTNAME end as EXTERNALUNITDESC,
   IO_OutgoingDestinations.ReceiveModeId,
   io_outgoingdestinations.nationaladdress,
   IO_ReceiveModes.ReceiveModeDesc, 
   IO_Outgoing.CorrespondenceDate,
   IO_Outgoing.CorrespondenceSubject,
   IO_DeliveryReportItems.CorrespondenceNumber,
   IO_DeliveryReportItems.HijricYear, 
   IO_DeliveryReportItems.WasDelivered,
   IO_DeliveryReportItems.ActionId, 
   IO_DeliveryReportItems.ReasonId,
   IO_Actions.ActionDesc,
   IO_Reasons.ReasonDesc,
   io_correspondencetypes.CORRESPONDENCETYPEDESC,
      io_correspondencetypes.CORRESPONDENCETYPEID,
   IO_OUTGOINGDESTINATIONS.ATTACHMENTS as ATTACHMENT,
   nvl(IO_OutgoingDestinations.COMMENTS,' ') as destinationAddress,
     io_departments.departmentname as creatorDepartment,
   IO_LETTERTYPES.letterdesc as letterTypeDesc,
   IO_OutgoingDestinations.LETTERTYPEID as letterTypeID,
   IO_Outgoing.CONFIDENTIALITYID , 
   IO_OutgoingDestinations.UNITTYPEID
   ,  nvl(REGIONNAME , ' ') as REGIONNAME ,
   RANK() OVER (PARTITION BY IO_DeliveryReportItems.DestinationId ORDER BY IO_DeliveryReportItems.CorrespondenceNumber ) as counter
   FROM              IO_DeliveryReportItems,
	IO_OutgoingDestinations,
	IO_ExternalUnits,
	IO_ReceiveModes,
	IO_Outgoing,
	IO_Actions,
	IO_Reasons, 
  io_correspondencetypes, 
  io_departments,
  io_departments DestinationDepartment,
  IO_LETTERTYPES ,
 io_regions,
 io_regionmembers
   WHERE     IO_DeliveryReportItems.CorrespondenceNumber = IO_OutgoingDestinations.CorrespondenceNumber AND
   IO_DeliveryReportItems.HijricYear = IO_OutgoingDestinations.HijricYear AND
   IO_DeliveryReportItems.DestinationId = IO_OutgoingDestinations.CORRESPONDENCEDESTINATIONID AND
   IO_OutgoingDestinations.CORRESPONDENCEDESTINATIONID = IO_ExternalUnits.EXTERNALUNITID(+) AND
   IO_OutgoingDestinations.CORRESPONDENCEDESTINATIONID = DestinationDepartment.DEPARTMENTID(+) AND
   
   IO_OutgoingDestinations.ReceiveModeId = IO_ReceiveModes.ReceiveModeId AND
   IO_DeliveryReportItems.CorrespondenceNumber = IO_Outgoing.CorrespondenceNumber AND
   IO_DeliveryReportItems.HijricYear = IO_Outgoing.HijricYear AND 
   IO_DeliveryReportItems.ActionId = IO_Actions.ActionId (+) AND 
   IO_DeliveryReportItems.ReasonId = IO_Reasons.ReasonId (+) AND 
   IO_Outgoing.PREPAREDBYDEPARTMENTID = io_departments.DEPARTMENTID (+) AND 
   IO_OutgoingDestinations.LETTERTYPEID = IO_LETTERTYPES.LETTERTYPEID (+) AND 
   io_regions.REGIONID(+) = io_regionmembers.REGIONID and 
   IO_OutgoingDestinations.CORRESPONDENCEDESTINATIONID = io_regionmembers.MEMBERID(+) and
   
   (IO_DeliveryReportItems.ReportNumber = p_deliveryReportId) AND(IO_DeliveryReportItems.ReportHijricYear = p_reportHijriYear)
    and    IO_Outgoing.CORRESPONDENCETYPEID = io_correspondencetypes.CORRESPONDENCETYPEID
    ORDER BY io_regions.REGIONID ,IO_DeliveryReportItems.DestinationId, counter,
    IO_DeliveryReportItems.HijricYear NULLS FIRST,IO_DeliveryReportItems.CorrespondenceNumber NULLS FIRST;

 
  
end;
/
/

-- CHANGED PROCEDURE: MOF_GETNOTDLVRD_OUTGOING_BYUSR
CREATE OR REPLACE PROCEDURE "MOF_GETNOTDLVRD_OUTGOING_BYUSR" 
(
     RCT1 OUT GLOBALPKG.RCT1
    , p_fromReigonID  IN INT
    , p_toReigonID  IN INT
    , p_correspondenceDateFrom  IN INT
    , p_correspondenceDateTo  IN INT

    , p_DestinationID  IN INT
    , p_sendMode  IN INT
    , p_UserId  IN VARCHAR2

    
    , CKLetterType_ALL  IN INT
    , CKLetterType_1  IN INT
    , CKLetterType_2  IN INT
    , CKLetterType_3  IN INT
    , CKLetterType_4  IN INT

    , CKOutgoing_Type_ALL  IN INT
    , CKOutgoing_Type_1  IN INT
    , CKOutgoing_Type_2  IN INT
    , CKOutgoing_Type_3  IN INT
    , CKOutgoing_Type_4  IN INT
    , CKOutgoing_Type_5  IN INT
    , CKOutgoing_Type_6  IN INT
    , CKOutgoing_Type_7  IN INT
    , CKOutgoing_Type_8  IN INT
    , CKOutgoing_Type_9  IN INT
    , CKOutgoing_Type_10  IN INT
    , CKOutgoing_Type_PENSION  IN INT
  )
  AS
  BEGIN

 OPEN RCT1 FOR 
  select 
        CORRESPONDENCENUMBER
        ,MINISTEROFFICENUMBER as DummycorrespondenceNumber
        ,HIJRICYEAR
        ,CORRESPONDENCEDATE
        ,CORRESPONDENCESUBJECT
        ,PREPAREDBYDEPARTMENTNAME
        ,DESTINATIONDESC
        ,DESTINATIONID
        ,DestinationType
        ,sentby
  
  
  from DR_OUTGOING_ITEMS_VIEW 
  where
    
        (  p_fromReigonID  = 0 or (p_fromReigonID <= REGIONID and p_toReigonID = 0 ) 
                               or (p_fromReigonID <= REGIONID and p_toReigonID >= REGIONID ))
                               
    and (  p_correspondenceDateFrom  = 0 
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo = 0 ) 
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo >= CORRESPONDENCEDATE ))
    and ( p_DestinationID = 0 or p_DestinationID = DESTINATIONID )
         
   
    
    and (
      sentby is not NULL-- = p_UserId 
      or (
      (CKOutgoing_Type_ALL = 1 or CKOutgoing_Type_PENSION= 1) and CORRTYPE = 500)  -- type 500 : pension correspondence exported by integration webservice
    )
    
    and rownum <= 200
    
order by CORRESPONDENCENUMBER,HIJRICYEAR;
  
end;
/
/

-- CHANGED PROCEDURE: MOF_GETNOTDLVRD_INCOMING_BYUSR
CREATE OR REPLACE PROCEDURE "MOF_GETNOTDLVRD_INCOMING_BYUSR" 
(
     RCT1 OUT GLOBALPKG.RCT1
    , p_DestinationID  IN INT
    , p_UserId  IN VARCHAR2
    , p_fromReigonID  IN INT
    , p_toReigonID  IN INT
    , p_correspondenceDateFrom  IN INT
    , p_correspondenceDateTo  IN INT
  )
  AS
  BEGIN

 OPEN RCT1 FOR
  select distinct
        CORRESPONDENCENUMBER
        ,MINISTEROFFICENUMBER as DummycorrespondenceNumber
        ,HIJRICYEAR
        ,CORRESPONDENCEDATE
        ,CORRESPONDENCESUBJECT
        ,DESTINATIONDESC
        ,DESTINATIONID
        ,'-1' as EMPLOYEELOGINID  -- removed to preserve uniqueness of records by corrnum, corryear, destinationid (old: ,EMPLOYEELOGINID as EMPLOYEELOGINID)

  from DR_incoming_ITEMS_VIEW
  where

        (  p_fromReigonID  = 0 or (p_fromReigonID <= REGIONID and p_toReigonID = 0 )
                               or (p_fromReigonID <= REGIONID and p_toReigonID >= REGIONID ))

    and (  p_correspondenceDateFrom  = 0
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo = 0 )
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo >= CORRESPONDENCEDATE ))
    and ( p_DestinationID = 0 or p_DestinationID = DESTINATIONID )
    and ( receivedby = p_UserId )

order by CORRESPONDENCENUMBER,HIJRICYEAR;
end;
/
/

-- CHANGED PROCEDURE: MOF_GETNOTDELIVEREDOUTGOINGS
CREATE OR REPLACE PROCEDURE "MOF_GETNOTDELIVEREDOUTGOINGS" 
(
     RCT1 OUT GLOBALPKG.RCT1
    , p_fromReigonID  IN INT
    , p_toReigonID  IN INT
    , p_correspondenceDateFrom  IN INT
    , p_correspondenceDateTo  IN INT

    , p_DestinationID  IN INT
    , p_sendMode  IN INT
    , p_IsCreatorMinisterEmployee  IN INT

    
    , CKLetterType_ALL  IN INT
    , CKLetterType_1  IN INT
    , CKLetterType_2  IN INT
    , CKLetterType_3  IN INT
    , CKLetterType_4  IN INT

    , CKOutgoing_Type_ALL  IN INT
    , CKOutgoing_Type_1  IN INT
    , CKOutgoing_Type_2  IN INT
    , CKOutgoing_Type_3  IN INT
    , CKOutgoing_Type_4  IN INT
    , CKOutgoing_Type_5  IN INT
    , CKOutgoing_Type_6  IN INT
    , CKOutgoing_Type_7  IN INT
    , CKOutgoing_Type_8  IN INT
    , CKOutgoing_Type_9  IN INT
    , CKOutgoing_Type_10  IN INT
  )
  AS
  BEGIN

 OPEN RCT1 FOR 
  select 
        CORRESPONDENCENUMBER
        ,MINISTEROFFICENUMBER as DummycorrespondenceNumber

        ,HIJRICYEAR
        ,CORRESPONDENCEDATE
        ,CORRESPONDENCESUBJECT
        ,PREPAREDBYDEPARTMENTNAME
        ,DESTINATIONDESC
        ,DESTINATIONID
        ,DestinationType
        --,NVL(REGIONNAME,'')
        --,case when CORRTYPE = 7 then '������' else '' end;

  from DR_OUTGOING_ITEMS_VIEW 
  where

        (  p_fromReigonID  = 0 or (p_fromReigonID <= REGIONID and p_toReigonID = 0 ) 
                               or (p_fromReigonID <= REGIONID and p_toReigonID >= REGIONID ))

    and (  p_correspondenceDateFrom  = 0 
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo = 0 ) 
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo >= CORRESPONDENCEDATE ))
    and ( p_DestinationID = 0 or p_DestinationID = DESTINATIONID )   
   -- and ( p_sendMode = DELIVARYMODE )

  --  and ((p_IsCreatorMinisterEmployee =0 and MINISTEROFFICENUMBER =0 ) 
   --      or(p_IsCreatorMinisterEmployee =1 and MINISTEROFFICENUMBER <> 0))

    and (CKLetterType_ALL = 1
           or (CKLetterType_1 = 1 and LETTERTYPE = 1)
           or (CKLetterType_2 = 1 and LETTERTYPE = 2)
           or (CKLetterType_3 = 1 and LETTERTYPE = 3)
           or (CKLetterType_4 = 1 and LETTERTYPE = 4))

    and (CKOutgoing_Type_ALL = 1
          or ( CKOutgoing_Type_1= 1 and CORRTYPE = 1)
          or ( CKOutgoing_Type_2= 1 and CORRTYPE = 2)
          or ( CKOutgoing_Type_3= 1 and CORRTYPE = 3)
          or ( CKOutgoing_Type_4= 1 and CORRTYPE = 4)
          or ( CKOutgoing_Type_5= 1 and CORRTYPE = 5)
          or ( CKOutgoing_Type_6= 1 and CORRTYPE = 6)
          or ( CKOutgoing_Type_7= 1 and CORRTYPE = 7)
          or ( CKOutgoing_Type_8= 1 and CORRTYPE = 8)
          or ( CKOutgoing_Type_9= 1 and CORRTYPE = 9)
          or (CKOutgoing_Type_10= 1 and CORRTYPE = 10))
order by DESTINATIONID
  ;

end;
/
/

-- CHANGED PROCEDURE: MOF_GETNOTDELIVEREDINCOMING
CREATE OR REPLACE PROCEDURE "MOF_GETNOTDELIVEREDINCOMING" 
(
     RCT1 OUT GLOBALPKG.RCT1
    , p_DestinationID  IN INT
    , p_IsCreatorMinisterEmployee  IN INT
    , p_fromReigonID  IN INT
    , p_toReigonID  IN INT
    , p_correspondenceDateFrom  IN INT
    , p_correspondenceDateTo  IN INT

    
  )
  AS
  BEGIN

 OPEN RCT1 FOR 
  select 
        CORRESPONDENCENUMBER
        ,MINISTEROFFICENUMBER as DummycorrespondenceNumber
  
        ,HIJRICYEAR
        ,CORRESPONDENCEDATE
        ,CORRESPONDENCESUBJECT
 --       ,PREPAREDBYDEPARTMENTNAME
        ,DESTINATIONDESC
        ,DESTINATIONID
        ,EMPLOYEELOGINID
 --       ,DestinationType
        --,NVL(REGIONNAME,'')
        --,case when CORRTYPE = 7 then '������' else '' end;
  
  
  from DR_incoming_ITEMS_VIEW 
  where
    
        (  p_fromReigonID  = 0 or (p_fromReigonID <= REGIONID and p_toReigonID = 0 ) 
                               or (p_fromReigonID <= REGIONID and p_toReigonID >= REGIONID ))
                               
    and (  p_correspondenceDateFrom  = 0 
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo = 0 ) 
               or (p_correspondenceDateFrom <= CORRESPONDENCEDATE and p_correspondenceDateTo >= CORRESPONDENCEDATE ))
    and ( p_DestinationID = 0 or p_DestinationID = DESTINATIONID )   
    
--and ((p_IsCreatorMinisterEmployee =0 and MINISTEROFFICENUMBER =0 ) 
 --        or(p_IsCreatorMinisterEmployee =1 and MINISTEROFFICENUMBER <> 0))
 /*        
    and (CKLetterType_ALL = 1
           or (CKLetterType_1 = 1 and LETTERTYPE = 1)
           or (CKLetterType_2 = 1 and LETTERTYPE = 2)
           or (CKLetterType_3 = 1 and LETTERTYPE = 3)
           or (CKLetterType_4 = 1 and LETTERTYPE = 4))
    
    and (CKOutgoing_Type_ALL = 1
          or ( CKOutgoing_Type_1= 1 and CORRTYPE = 1)
          or ( CKOutgoing_Type_2= 1 and CORRTYPE = 2)
          or ( CKOutgoing_Type_3= 1 and CORRTYPE = 3)
          or ( CKOutgoing_Type_4= 1 and CORRTYPE = 4)
          or ( CKOutgoing_Type_5= 1 and CORRTYPE = 5)
          or ( CKOutgoing_Type_6= 1 and CORRTYPE = 6)
          or ( CKOutgoing_Type_7= 1 and CORRTYPE = 7)
          or ( CKOutgoing_Type_8= 1 and CORRTYPE = 8)
          or ( CKOutgoing_Type_9= 1 and CORRTYPE = 9)
          or (CKOutgoing_Type_10= 1 and CORRTYPE = 10))
*/  
order by DESTINATIONDESC
  ;
  
end;
/
/

-- CHANGED PROCEDURE: MOF_GETEMPLOYEE_DEPT_NAME
CREATE OR REPLACE PROCEDURE "MOF_GETEMPLOYEE_DEPT_NAME" 
  (
    p_EMPLOYEEID IN INT ,
    RCT1   IN OUT GLOBALPKG.RCT1 )
AS
BEGIN

  OPEN RCT1 FOR  
    SELECT  IO_DEPARTMENTS.DEPARTMENTNAME
  FROM IO_EMPLOYEES 
  inner join  IO_DEPARTMENTS on IO_EMPLOYEES.DEPARTMENTID = IO_DEPARTMENTS.DEPARTMENTID
  WHERE EMPLOYEEID = p_EMPLOYEEID
     
  ORDER BY  DEPARTMENTNAME;
END;
/
/

-- CHANGED PROCEDURE: IO_S_TRACK
CREATE OR REPLACE PROCEDURE "IO_S_TRACK" 
(
    p_corresType IN INT,
    p_fromLaunchHijriDateAsString IN OUT VARCHAR2,
    p_toLaunchHijriDateAsString IN OUT VARCHAR2,
    p_departmentId IN INT,
    p_selectedUserId IN VARCHAR2,
    p_publicQueueName IN VARCHAR2,
    RCT1 IN OUT GLOBALPKG.RCT1
)
AS

fromLaunchGregDateAsString VARCHAR2(10);
toLaunchGregDateAsString VARCHAR2(10);
fromLaunchGregDate INT;
toLaunchGregDate INT;

BEGIN
    fromLaunchGregDateAsString := '-1';
    toLaunchGregDateAsString := '-1';
   
    DS_GETGREGDATE(HIJRIDATE => p_fromLaunchHijriDateAsString, GREGDATE => fromLaunchGregDateAsString);
    DS_GETGREGDATE(HIJRIDATE => p_toLaunchHijriDateAsString, GREGDATE => toLaunchGregDateAsString);
	
    IF fromLaunchGregDateAsString = '//' THEN
        fromLaunchGregDate := -1;
    ELSE
        fromLaunchGregDate := CAST(REPLACE(fromLaunchGregDateAsString, '/', '') AS INT);
    END IF;
	
    IF toLaunchGregDateAsString = '//' THEN
        toLaunchGregDate := -1;
    ELSE
        toLaunchGregDate := CAST(REPLACE(toLaunchGregDateAsString, '/', '') AS INT);
    END IF;

if p_publicqueuename is null then
BEGIN
    OPEN RCT1 FOR
    SELECT DISTINCT CORRESPONDENCESUBJECT,
                    FROMUNITNAME,
                    CORRESPONDENCEDATE,
                    CORRESPONDENCENUMBER,
                    HIJRICYEAR,
                    EXTERNALNUMBER,
                    F_CLASS,
                    CONFIDENTIALITYID,
                    CORRESPONDENCENUMBER AS DisplayNumber,
                    DECISIONTYPE
                    
    FROM IO_TRACK_CORRESPONDENCES_VIEW tv 
          INNER JOIN peuser.vwuser vwu ON tv.inboxbounduser = vwu.f_userId
          INNER JOIN io_employees e on lower(e.userid) = lower(vwu.f_username)
    WHERE (CORRESPONDENCETYPE = p_corresType)
      AND (fromLaunchGregDate = -1 OR LAUNCHDATE >= fromLaunchGregDate)
      AND (toLaunchGregDate = -1 OR LAUNCHDATE <= toLaunchGregDate)
      AND (p_selectedUserId IS NULL OR lower(e.userid) = lower(p_selectedUserId))
      AND (p_departmentid = -1 OR e.departmentid = p_departmentid)
      AND (
               (p_publicQueueName IS NULL)
            OR 
               (
                     (p_publicQueueName = 'fn_Q01' AND fn_Q01 > -1)
                  OR (p_publicQueueName = 'fn_Q02' AND fn_Q02 > -1)
               )
          )

    order by correspondencedate desc;
end;
else
begin
    OPEN RCT1 FOR
    SELECT DISTINCT CORRESPONDENCESUBJECT,
                    FROMUNITNAME,
                    CORRESPONDENCEDATE,
                    CORRESPONDENCENUMBER,
                    HIJRICYEAR,
                    EXTERNALNUMBER,
                    F_CLASS,
                    CONFIDENTIALITYID,
                    NVL(MONumber, CORRESPONDENCENUMBER) AS DisplayNumber,
                    DECISIONTYPE
                    
    from io_track_correspondences_view tv
    WHERE (CORRESPONDENCETYPE = p_corresType)
      AND (fromLaunchGregDate = -1 OR LAUNCHDATE >= fromLaunchGregDate)
      AND (toLaunchGregDate = -1 OR LAUNCHDATE <= toLaunchGregDate)
      AND (
               (p_publicQueueName IS NULL)
            OR 
               (
                     (p_publicQueueName = 'fn_Q01' AND fn_Q01 > -1)
                  OR (p_publicQueueName = 'fn_Q02' AND fn_Q02 > -1)
               )
          )

    order by correspondencedate desc;
end;
END IF;
      
end;
/
/

-- CHANGED PROCEDURE: IO_S_SEARCH_OUTGOING
CREATE OR REPLACE PROCEDURE "IO_S_SEARCH_OUTGOING" 
(
    p_correstype IN INT,
    p_findin IN INT,
    p_corresstatus IN INT,
    p_corresnumber IN INT,
    p_correshijriyear IN INT,
    p_corressubject IN out VARCHAR2,
    p_fromdate IN out INT,
    p_todate IN out INT,
    p_sender IN VARCHAR2,
    p_fromunitid IN INT,
    p_tounitid IN INT,
    p_currentuserid IN VARCHAR2,
    p_tounittype IN INT,
    p_monumber IN INT,
    p_corrsubtypeid IN INT,
    p_corrcategoryid IN INT,
    p_remarks IN out VARCHAR2,
    p_civilid IN out VARCHAR2,
    rct1 IN out globalpkg.rct1
)
AS

currentuserempid INT;
currentuserdeptid INT;
currentusersectorid INT;

BEGIN
    IF p_corressubject IS NOT NULL THEN
        p_corressubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_corressubject, '??', '??'), '??', '??'), '??', '??'), '??', '??') || '%';
    END IF;
    IF p_remarks IS NOT NULL THEN
      p_remarks := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_remarks, '??', '??'), '??', '??'), '??', '??'), '??', '??') || '%';
    END IF;
    BEGIN
      SELECT employeeid INTO currentuserempid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    BEGIN
      currentuserdeptid := -1;
      SELECT departmentid INTO currentuserdeptid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    BEGIN
      currentusersectorid := 0;
      SELECT sector_id INTO currentusersectorid FROM io_departments WHERE departmentid = currentuserdeptid AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
      OPEN rct1 FOR
      SELECT * FROM (
                      SELECT DISTINCT sview.correspondencenumber,
                                      sview.hijricyear,
                                      sview.correspondencedate,
                                      sview.correspondencesubject,
                                      sview.fromunitname,
                                      sview.f_class,
                                      sview.confidentialityid,
                                      sview.wf_launched,
                                      sview.creator,
                                      nvl(sview.monumber, sview.correspondencenumber) AS displaynumber
                      FROM io_search_outgoing_view sview
                      FULL JOIN io_correspondencesecurity cs ON sview.correspondencenumber = cs.correspondencenumber AND sview.hijricyear = cs.hijricyear AND cs.typeid = p_correstype
                      WHERE
                        (
                          lower(p_currentuserid) = lower(sview.creator)
                          OR lower(p_currentuserid) = lower(sview.participantuserid)
                          OR (

							  sview.confidentialityid = 0 OR lower(cs.userid) = lower(p_currentuserid) or lower(p_currentuserid) = lower('057902') or lower(p_currentuserid) = lower('ccash') or lower(p_currentuserid) = lower('003847') or lower(p_currentuserid) = lower('mom221005')

                              )
                        )
                      AND (sview.correspondencetype = p_correstype)
                      AND (
                                  (p_findin = 3)
                               OR (p_findin = 0 AND (lower(p_currentuserid) = lower(sview.creator) OR lower(p_currentuserid) = lower(sview.participantuserid) ))
                               OR (p_findin = 1 AND (currentuserdeptid = sview.fromunitid OR currentuserdeptid = sview.participantdeptid OR currentuserdeptid = 30 )) -- dept 30 outgoing, temp fix for pension outgoing not having a forwarding history
                               OR (p_findin = 1 AND (sview.fromunitid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                               OR (p_findin = 1 AND (sview.creatordepartmentid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid))) -- temp fix for pension outgoing not having a forwarding history
                               OR (p_findin = 2 AND (sview.participantdeptid IN (SELECT departmentid FROM io_departments WHERE sector_id = currentusersectorid)))
							   OR (p_findin = 2 AND (sview.sector_id = currentusersectorid))
                          )
                      AND (
                              (p_corresstatus = 0)
                           OR (p_corresstatus = 1 AND f_class IS NOT NULL)
                           OR (p_corresstatus = 2 AND f_class IS NULL)
                          )
                      AND (p_corresnumber = -1 OR sview.correspondencenumber = p_corresnumber)
                      AND    (p_correshijriyear = -1 OR sview.hijricyear = p_correshijriyear)
                      AND    (p_fromdate = -1 OR sview.correspondencedate >= p_fromdate)
                      AND    (p_todate = -1 OR sview.correspondencedate <= p_todate)
                      AND (p_fromunitid = -1 OR sview.fromunitid = p_fromunitid)
                      AND (((p_tounitid = -1) OR (p_tounittype = 1 AND sview.toexternalunitid = p_tounitid)) OR ((p_tounitid = -1) OR (p_tounittype = 2 AND sview.tointernalunitid = p_tounitid)))
                      AND    (p_corressubject IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.correspondencesubject, '??', '??'), '??', '??'), '??', '??'), '??', '??') LIKE p_corressubject)
                      AND (p_remarks IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.remarks, '??', '??'), '??', '??'), '??', '??'), '??', '??') LIKE p_remarks)
                      AND (p_civilid IS NULL OR sview.civilid LIKE '%'|| p_civilid ||'%')
                      AND ((p_sender IS NULL) OR (sview.forwardingtype = 1 AND lower(sview.participantuserid) = lower(p_sender)))
                      AND (p_corrsubtypeid = -1 OR sview.correspondencesubtypeid = p_corrsubtypeid)
                      AND (p_corrcategoryid = -1 OR sview.correspondencecategoryid = p_corrcategoryid)
                      ORDER BY sview.correspondencedate DESC, sview.correspondencenumber DESC
                    )
      WHERE ROWNUM <= 5000;
END;
/
/

-- CHANGED PROCEDURE: IO_S_SEARCH_INTERNAL
CREATE OR REPLACE PROCEDURE "IO_S_SEARCH_INTERNAL" 
(
    p_correstype IN INT,
    p_findin IN INT,
    p_corresstatus IN INT,
    p_corresnumber IN INT,
    p_correshijriyear IN INT,
    p_corressubject IN out VARCHAR2,
    p_fromdate IN out INT,
    p_todate IN out INT,
    p_sender IN VARCHAR2,
    p_fromunitid IN INT,
    p_tounitid IN INT,
    p_currentuserid IN VARCHAR2,
    p_monumber IN INT,
    p_corrsubtypeid IN INT,
    p_corrcategoryid IN INT,
    p_remarks IN out VARCHAR2,
    p_civilid IN out VARCHAR2,
    rct1 IN out globalpkg.rct1
)
AS

currentuserempid INT;
currentuserdeptid INT;
currentusersectorid INT;

BEGIN
    IF p_corressubject IS NOT NULL THEN
      p_corressubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_corressubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
    
    IF p_remarks IS NOT NULL THEN
      p_remarks := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_remarks, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
    
    BEGIN
      SELECT employeeid INTO currentuserempid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
    BEGIN
      currentuserdeptid := -1;
      SELECT departmentid INTO currentuserdeptid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
    BEGIN
      currentusersectorid := 0;
      SELECT sector_id INTO currentusersectorid FROM io_departments WHERE departmentid = currentuserdeptid AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
        OPEN rct1 FOR
        SELECT * FROM (
                        SELECT DISTINCT sview.correspondencenumber,
                                        sview.hijricyear,
                                        sview.correspondencedate,
                                        sview.correspondencesubject,
                                        sview.fromunitname,
                                        sview.f_class,
                                        sview.confidentialityid,
                                        sview.wf_launched,
                                        sview.creator,
                                        nvl(sview.monumber, sview.correspondencenumber) AS displaynumber,
                                        sview.correspondencesubtypeid,
                                        sview.is_supply_corr
                                                        
                        FROM io_search_internal_view sview
                        FULL JOIN io_correspondencesecurity cs ON sview.correspondencenumber = cs.correspondencenumber AND sview.hijricyear = cs.hijricyear AND cs.typeid = p_correstype
                        
                        WHERE 
                        (cs.userid IS NULL OR cs.userid = p_currentuserid)
                        AND (sview.correspondencetype = p_correstype)
                        AND (
                                    (p_findin = 3)
                                 OR (p_findin = 0 AND (lower(p_currentuserid) = lower(sview.creator) OR lower(p_currentuserid) = lower(sview.participantuserid) ))
                                 OR (p_findin = 1 AND (currentuserdeptid = sview.fromunitid OR currentuserdeptid = sview.participantdeptid ))
                                 OR (p_findin = 1 AND (sview.fromunitid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                                 OR (p_findin = 1 AND (sview.participantdeptid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                                 OR (p_findin = 2 AND (sview.sector_id = currentusersectorid))
                            )
                        AND (
                                (p_corresstatus = 0)
                             OR (p_corresstatus = 1 AND f_class IS NOT NULL)
                             OR (p_corresstatus = 2 AND f_class IS NULL)
                            )
                        AND (p_corresnumber = -1 OR sview.correspondencenumber = p_corresnumber)
                        AND (p_correshijriyear = -1 OR sview.hijricyear = p_correshijriyear)
                        AND (p_fromdate = -1 OR sview.correspondencedate >= p_fromdate)
                        AND (p_todate = -1 OR sview.correspondencedate <= p_todate)
                        AND (p_fromunitid = -1 OR sview.fromunitid = p_fromunitid)
                        AND (p_tounitid = -1 OR sview.tounitid = p_tounitid)
                        AND (p_corressubject IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.correspondencesubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_corressubject)
                        AND (p_remarks IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.remarks, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_remarks)
                        AND (p_civilid IS NULL OR sview.civilid LIKE '%'|| p_civilid ||'%')
                        AND ((p_sender IS NULL) OR (sview.forwardingtype = 1 AND lower(sview.participantuserid) = lower(p_sender)))
                        AND (p_corrsubtypeid = -1 OR sview.correspondencesubtypeid = p_corrsubtypeid)
                        AND (p_corrcategoryid = -1 OR sview.correspondencecategoryid = p_corrcategoryid)
                        
                        ORDER BY sview.correspondencedate DESC, sview.correspondencenumber DESC
                      )
        WHERE ROWNUM <= 200;

END;
/
/

-- CHANGED PROCEDURE: IO_S_SEARCH_INCOMING
CREATE OR REPLACE PROCEDURE "IO_S_SEARCH_INCOMING" 
(
    p_correstype IN INT,
    p_findin IN INT,
    p_corresstatus IN INT,
    p_corresnumber IN INT,
    p_correshijriyear IN INT,
    p_corressubject IN out VARCHAR2,
    p_fromdate IN out INT,
    p_todate IN out INT,
    p_sender IN VARCHAR2,
    p_fromunitid IN INT,
    p_tounitid IN INT,
    p_currentuserid IN VARCHAR2,
    p_senderdetails IN out VARCHAR2,
    p_receivemodeid IN INT,
    p_externalnumber IN VARCHAR2,
    p_fromunittype IN INT,
    p_monumber IN INT,
    p_corrsubtypeid IN INT,
    p_corrcategoryid IN INT,
    p_remarks IN out VARCHAR2,
    p_civilid IN out VARCHAR2,
    rct1 IN out globalpkg.rct1
)
AS

currentuserempid INT;
currentuserdeptid INT;
currentusersectorid INT;

BEGIN
    IF p_corressubject IS NOT NULL THEN
        p_corressubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_corressubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
    
    IF p_remarks IS NOT NULL THEN
      p_remarks := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_remarks, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
   
    IF p_senderdetails IS NOT NULL THEN
        p_senderdetails := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_senderdetails, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
    
    BEGIN
      SELECT employeeid INTO currentuserempid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
    BEGIN
      currentuserdeptid := -1;
      SELECT departmentid INTO currentuserdeptid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
    BEGIN
      currentusersectorid := 0;
      SELECT sector_id INTO currentusersectorid FROM io_departments WHERE departmentid = currentuserdeptid AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;

    OPEN rct1 FOR
    SELECT * FROM (
                    SELECT DISTINCT sview.correspondencenumber,
                                    sview.hijricyear,
                                    sview.correspondencedate,
                                    sview.correspondencesubject,
                                    sview.fromunitname,
                                    sview.f_class,
                                    sview.confidentialityid,
                                    sview.wf_launched,
                                    sview.creator,
                                    sview.externalnumber,
                                    nvl(sview.monumber, sview.correspondencenumber) AS displaynumber,
                                    sview.senderdetails,
                                    sview.cloneid
                                                    
                    FROM io_search_incoming_view sview
                    FULL JOIN io_correspondencesecurity cs ON sview.correspondencenumber = cs.correspondencenumber AND sview.hijricyear = cs.hijricyear AND cs.typeid = p_correstype
                        
                    WHERE 
                    (cs.userid IS NULL OR cs.userid = p_currentuserid)
                    AND (sview.correspondencetype = p_correstype)
                    AND (
                                (p_findin = 3)
                             OR (p_findin = 0 AND (lower(p_currentuserid) = lower(sview.creator) OR lower(p_currentuserid) = lower(sview.participantuserid) ))
                             OR (p_findin = 1 AND (currentuserdeptid = sview.creatordepartmentid OR currentuserdeptid = sview.participantdeptid ))
                             OR (p_findin = 1 AND (sview.creatordepartmentid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                             OR (p_findin = 1 AND (sview.participantdeptid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                             OR (p_findin = 2 AND (sview.sector_id = currentusersectorid))
                        )
                    AND (
                            (p_corresstatus = 0)
                         OR (p_corresstatus = 1 AND f_class IS NOT NULL)
                         OR (p_corresstatus = 2 AND f_class IS NULL)
                        )
                    AND (p_corresnumber = -1 OR sview.correspondencenumber = p_corresnumber)
                    AND    (p_correshijriyear = -1 OR sview.hijricyear = p_correshijriyear)
                    AND    (p_fromdate = -1 OR sview.correspondencedate >= p_fromdate)
                    AND    (p_todate = -1 OR sview.correspondencedate <= p_todate)
                    AND    (p_receivemodeid = -1 OR sview.receivemodeid = p_receivemodeid)
                    AND (p_fromunitid = -1 OR (sview.fromunittype = p_fromunittype AND sview.fromunitid = p_fromunitid))
                    AND (p_tounitid = -1 OR sview.tounitid = p_tounitid)
                    AND    (p_senderdetails IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.senderdetails, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_senderdetails)
                    AND    (p_externalnumber IS NULL OR lower(sview.externalnumber) = lower(p_externalnumber))
                    AND    (p_corressubject IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.correspondencesubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_corressubject)
                    AND (p_remarks IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.remarks, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_remarks)
                    AND (p_civilid IS NULL OR sview.civilid LIKE '%'|| p_civilid ||'%')
                    AND ((p_sender IS NULL) OR (sview.forwardingtype = 1 AND lower(sview.participantuserid) = lower(p_sender)))
                    AND (p_corrsubtypeid = -1 OR sview.correspondencesubtypeid = p_corrsubtypeid)
                    AND (p_corrcategoryid = -1 OR sview.correspondencecategoryid = p_corrcategoryid)
                
                    ORDER BY sview.correspondencedate DESC, sview.correspondencenumber DESC
                  )
    WHERE ROWNUM <= 200;
END;
/
/

-- CHANGED PROCEDURE: IO_S_SEARCH_DECISION
CREATE OR REPLACE PROCEDURE "IO_S_SEARCH_DECISION" 
(
    p_corresType IN INT,
    p_findIn IN INT,
    p_corresStatus IN INT,
    p_corresNumber IN INT,
    p_corresHijriYear IN INT,
    p_corresSubject IN OUT VARCHAR2,
    p_fromDate IN OUT INT,
    p_toDate IN OUT INT,
    p_sender IN VARCHAR2,
    p_fromUnitId IN INT,
    p_toUnitId IN INT,
    p_currentUserId IN VARCHAR2,
    p_toUnitType IN INT,
    p_remarks IN OUT VARCHAR2,
    RCT1 IN OUT GLOBALPKG.RCT1
)
AS

currentUserDeptId INT;

BEGIN
    IF p_corresSubject IS NOT NULL THEN
    	p_corresSubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_corresSubject, '�', '�'), '�', '�'), '�', '�'), '�', '�') || '%';
    END IF;
    
    IF p_remarks IS NOT NULL THEN
      p_remarks := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_remarks, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
    
    BEGIN
      currentUserDeptId := -1;
      SELECT departmentid into currentUserDeptId from io_employees where lower(userid) = lower(p_currentUserId) and rownum = 1;
      EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;
    
      OPEN RCT1 FOR
      SELECT DISTINCT CORRESPONDENCENUMBER,
                      HIJRICYEAR,
                      CORRESPONDENCEDATE,
                      CORRESPONDENCESUBJECT,
                      FROMUNITNAME,
                      F_CLASS,
                      WF_LAUNCHED,
                      CREATOR,
                      DECISIONTYPE
                                      
      FROM IO_SEARCH_DECISION_VIEW
  
      WHERE (CORRESPONDENCETYPE = p_corresType)
      AND (
                  (p_findIn = 2 OR p_findIn = 3 OR p_findIn = 4)
               OR (p_findIn = 0 AND (LOWER(p_currentUserId) = LOWER(creator) OR LOWER(p_currentUserId) = LOWER(participantuserid) ))
               OR (p_findIn = 1 AND (currentUserDeptId = fromUnitId))
               --OR (p_findIn = 1 AND (currentUserDeptId = fromUnitId OR currentUserDeptId = participantdeptid ))
          )
      AND (
              (p_corresStatus = 0)
           OR (p_corresStatus = 1 AND F_CLASS IS NOT NULL)
           OR (p_corresStatus = 2 AND F_CLASS IS NULL)
          )
      AND (p_corresNumber = -1 OR CORRESPONDENCENUMBER = p_corresNumber)
      AND	(p_corresHijriYear = -1 OR HIJRICYEAR = p_corresHijriYear)
      AND	(p_fromDate = -1 OR CORRESPONDENCEDATE >= p_fromDate)
      AND	(p_toDate = -1 OR CORRESPONDENCEDATE <= p_toDate)
      AND (p_fromUnitId = -1 OR fromUnitId = p_fromUnitId)
      AND ((p_toUnitId = -1) OR (p_toUnitType = 1 AND toExternalUnitId = p_toUnitId))
      AND ((p_toUnitId = -1) OR (p_toUnitType = 2 AND toInternalUnitId = p_toUnitId))      
      AND	(p_corresSubject IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(CorrespondenceSubject, '�', '�'), '�', '�'), '�', '�'), '�', '�') LIKE p_corresSubject)
      AND (p_remarks IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(REMARKS, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_remarks)
      AND ((p_sender IS NULL) OR (forwardingtype = 1 AND lower(participantuserid) = lower(p_sender)))
      AND ROWNUM <= 200
  
      ORDER BY CORRESPONDENCEDATE DESC, CORRESPONDENCENUMBER DESC;
END;
/
/

-- CHANGED PROCEDURE: IO_S_SEARCH_CIRCULAR
CREATE OR REPLACE PROCEDURE "IO_S_SEARCH_CIRCULAR" 
(
    p_correstype IN INT,
    p_findin IN INT,
    p_corresstatus IN INT,
    p_corresnumber IN INT,
    p_correshijriyear IN INT,
    p_corressubject IN out VARCHAR2,
    p_fromdate IN out INT,
    p_todate IN out INT,
    p_sender IN VARCHAR2,
    p_fromunitid IN INT,
    p_tounitid IN INT,
    p_currentuserid IN VARCHAR2,
    p_remarks IN out VARCHAR2,
    rct1 IN out globalpkg.rct1
)
AS

currentuserempid INT;
currentuserdeptid INT;
currentusersectorid INT;

BEGIN
    IF p_corressubject IS NOT NULL THEN
      p_corressubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_corressubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
    
    IF p_remarks IS NOT NULL THEN
      p_remarks := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_remarks, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
    END IF;
    
    BEGIN
      SELECT employeeid INTO currentuserempid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
    BEGIN
      currentuserdeptid := -1;
      SELECT departmentid INTO currentuserdeptid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
     BEGIN
      currentusersectorid := 0;
      SELECT sector_id INTO currentusersectorid FROM io_departments WHERE departmentid = currentuserdeptid AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    
        OPEN rct1 FOR
        SELECT * FROM (
                        SELECT DISTINCT sview.correspondencenumber,
                                        sview.hijricyear,
                                        sview.correspondencedate,
                                        sview.correspondencesubject,
                                        sview.fromunitname,
                                        sview.f_class,
                                        sview.confidentialityid,
                                        sview.wf_launched,
                                        sview.creator,
                                        sview.correspondencesubtypeid
                                                        
                        FROM io_search_circular_view sview
                        FULL JOIN io_correspondencesecurity cs ON sview.correspondencenumber = cs.correspondencenumber AND sview.hijricyear = cs.hijricyear AND cs.typeid = p_correstype
                        
                        WHERE 
                        (
                          lower(p_currentuserid) = lower(sview.creator)
                          OR lower(p_currentuserid) = lower(sview.participantuserid)
                          OR (
                              sview.confidentialityid = 0 OR lower(cs.userid) = lower(p_currentuserid)
                              )
                        )
                        AND (sview.correspondencetype = p_correstype)
                        AND (
                                    (p_findin = 3)
                                 OR (p_findin = 0 AND (lower(p_currentuserid) = lower(sview.creator) OR lower(p_currentuserid) = lower(sview.participantuserid) ))
                                 OR (p_findin = 1 AND (currentuserdeptid = sview.fromunitid OR currentuserdeptid = sview.participantdeptid ))
                                 OR (p_findin = 1 AND (sview.fromunitid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                                 OR (p_findin = 1 AND (sview.participantdeptid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                                 OR (p_findin = 2 AND (sview.sector_id = currentusersectorid))
                            )
                        AND (
                                (p_corresstatus = 0)
                             OR (p_corresstatus = 1 AND f_class IS NOT NULL)
                             OR (p_corresstatus = 2 AND f_class IS NULL)
                            )
                        AND (p_corresnumber = -1 OR sview.correspondencenumber = p_corresnumber)
                        AND (p_correshijriyear = -1 OR sview.hijricyear = p_correshijriyear)
                        AND (p_fromdate = -1 OR sview.correspondencedate >= p_fromdate)
                        AND (p_todate = -1 OR sview.correspondencedate <= p_todate)
                        AND (p_fromunitid = -1 OR sview.fromunitid = p_fromunitid)
                        AND (p_tounitid = -1 OR sview.tounitid = p_tounitid)
                        AND (p_corressubject IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.correspondencesubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_corressubject)
                        AND (p_remarks IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(sview.remarks, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE p_remarks)
                        AND ((p_sender IS NULL) OR (sview.forwardingtype = 1 AND lower(sview.participantuserid) = lower(p_sender)))
                            
                        ORDER BY sview.correspondencedate DESC, sview.correspondencenumber DESC
                      )
        WHERE ROWNUM <= 200;
        

END;
/
/

-- CHANGED PROCEDURE: IO_SEARCH_INTERNAL
CREATE OR REPLACE PROCEDURE "IO_SEARCH_INTERNAL" 
(
    p_findin IN INT,
    p_corresnumber IN INT,
    p_correshijriyear IN INT,
    p_corressubject IN out VARCHAR2,
    p_fromdate IN out INT,
    p_todate IN out INT,
    p_sender IN VARCHAR2,
    p_fromunitid IN INT,
    p_tounitid IN INT,
    p_currentuserid IN VARCHAR2,
    p_corrsubtypeid IN INT,
    p_corrcategoryid IN INT,
    p_remarks IN out VARCHAR2,
    p_civilid IN out VARCHAR2,
    rct1 IN out globalpkg.rct1
)
AS

currentuserempid INT;
currentuserdeptid INT;
currentusersectorid INT;

BEGIN
    IF p_corressubject IS NOT NULL THEN
      p_corressubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_corressubject, '??', '??'), '??', '??'), '??', '??'), '??', '??') || '%';
    END IF;
    IF p_remarks IS NOT NULL THEN
      p_remarks := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_remarks, '??', '??'), '??', '??'), '??', '??'), '??', '??') || '%';
    END IF;
    BEGIN
      SELECT employeeid INTO currentuserempid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    BEGIN
      currentuserdeptid := -1;
      SELECT departmentid INTO currentuserdeptid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    BEGIN
      currentusersectorid := 0;
      SELECT sector_id INTO currentusersectorid FROM io_departments WHERE departmentid = currentuserdeptid AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
        OPEN rct1 FOR
        SELECT * FROM (
                        SELECT          internal.correspondencenumber,
                                        internal.hijricyear,
                                        internal.correspondencedate,
                                        internal.correspondencesubject,
                                        depts.departmentname FromUnitName,
                                        internal.confidentialityid,
                                        internal.wf_launched,
                                        internal.sentby creator,
                                        internal.correspondencenumber DisplayNumber,
                                        internal.correspondencetypeid CorrespondenceSubTypeId,
                                        internal.is_supply_corr,
                                        MAX(CAST(substr(forwardingtime,7,4)
                                          || substr(forwardingtime,4,2)
                                          || substr(forwardingtime,1,2)
                                          || REPLACE(substr(forwardingtime,12,8),':','') AS NUMBER)) last_action_time
                        FROM io_internal internal
                    INNER JOIN io_departments depts ON internal.sentbydepartmentid = depts.departmentid
                    LEFT JOIN io_correspondencesecurity cs ON internal.correspondencenumber = cs.correspondencenumber AND internal.hijricyear = cs.hijricyear AND cs.typeid = 3
                    LEFT JOIN io_forwardingshistory fh ON internal.correspondencenumber = fh.correspondencenumber AND internal.hijricyear = fh.hijricyear AND fh.typeid = 3
                    LEFT JOIN io_forwardingdetails fd ON fh.forwardingid = fd.forwardingid
                    LEFT JOIN io_internaldestinations dests ON internal.correspondencenumber = dests.correspondencenumber AND internal.hijricyear = dests.hijricyear
                        WHERE
                        (
                          lower(p_currentuserid) = lower(internal.sentby)
                          OR lower(p_currentuserid) = lower(fd.participantuserid)
                          OR (
                              internal.confidentialityid = 0 OR lower(cs.userid) = lower(p_currentuserid) or lower(p_currentuserid) = lower('057902') or lower(p_currentuserid) = lower('ccash') or lower(p_currentuserid) = lower('003847') or lower(p_currentuserid) = lower('mom221005')
                              )
                        )
                        AND (
                                    (p_findin = 3)
                                 OR (p_findin = 0 AND (lower(p_currentuserid) = lower(internal.sentby) OR lower(p_currentuserid) = lower(fd.participantuserid)))
                                 OR (p_findin = 1 AND (currentuserdeptid = depts.departmentid OR currentuserdeptid = fd.participantdeptid ))
                                 OR (p_findin = 1 AND (depts.departmentid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                                 OR (p_findin = 1 AND (fd.participantdeptid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                                 OR (p_findin = 2 AND (depts.sector_id = currentusersectorid))
								 OR (p_findin = 2 AND (fd.participantdeptid IN (SELECT departmentid FROM io_departments WHERE sector_id = currentusersectorid)))
                            )
                        AND (p_corresnumber = -1 OR internal.correspondencenumber = p_corresnumber)
                        AND (p_correshijriyear = -1 OR internal.hijricyear = p_correshijriyear)
                        AND (p_fromdate = -1 OR internal.correspondencedate >= p_fromdate)
                        AND (p_todate = -1 OR internal.correspondencedate <= p_todate)
                        AND (p_fromunitid = -1 OR depts.departmentid = p_fromunitid)
                        AND (p_tounitid = -1 OR dests.departmentid = p_tounitid)
                        AND (p_corressubject IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(internal.correspondencesubject, '??', '??'), '??', '??'), '??', '??'), '??', '??') LIKE p_corressubject)
                        AND (p_remarks IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(internal.remarks, '??', '??'), '??', '??'), '??', '??'), '??', '??') LIKE p_remarks)
                        AND (p_civilid IS NULL OR internal.civilid LIKE '%'|| p_civilid ||'%')
                        AND ((p_sender IS NULL) OR (fd.forwardingtype = 1 AND lower(fd.participantuserid) = lower(p_sender)))
                        AND (p_corrsubtypeid = -1 OR internal.correspondencetypeid = p_corrsubtypeid)
                        AND (p_corrcategoryid = -1 OR internal.correspondencecategoryid = p_corrcategoryid)
                        GROUP BY
                                internal.correspondencenumber, internal.hijricyear, internal.correspondencedate, internal.correspondencesubject, depts.departmentname,
                                internal.confidentialityid, internal.wf_launched, internal.sentby, internal.correspondencetypeid, internal.is_supply_corr
                        ORDER BY internal.correspondencedate DESC, internal.correspondencenumber DESC
                      )
        WHERE ROWNUM <= 5000;

END;
/
/

-- CHANGED PROCEDURE: IO_SEARCH_INCOMING
CREATE OR REPLACE PROCEDURE "IO_SEARCH_INCOMING" 
(
    p_findin IN INT,
    p_corresnumber IN INT,
    p_correshijriyear IN INT,
    p_corressubject IN out VARCHAR2,
    p_fromdate IN out INT,
    p_todate IN out INT,
    p_sender IN VARCHAR2,
    p_fromunitid IN INT,
    p_tounitid IN INT,
    p_currentuserid IN VARCHAR2,
    p_senderdetails IN out VARCHAR2,
    p_receivemodeid IN INT,
    p_externalnumber IN VARCHAR2,
    p_corrsubtypeid IN INT,
    p_corrcategoryid IN INT,
    p_remarks IN out VARCHAR2,
    p_civilid IN out VARCHAR2,
    rct1 IN out globalpkg.rct1
)
AS

currentuserempid INT;
currentuserdeptid INT;
currentusersectorid INT;

BEGIN
    IF p_corressubject IS NOT NULL THEN
        p_corressubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_corressubject, '??', '??'), '??', '??'), '??', '??'), '??', '??') || '%';
    END IF;
    IF p_remarks IS NOT NULL THEN
      p_remarks := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_remarks, '??', '??'), '??', '??'), '??', '??'), '??', '??') || '%';
    END IF;
    IF p_senderdetails IS NOT NULL THEN
        p_senderdetails := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_senderdetails, '??', '??'), '??', '??'), '??', '??'), '??', '??') || '%';
    END IF;
    BEGIN
      SELECT employeeid INTO currentuserempid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    BEGIN
      currentuserdeptid := -1;
      SELECT departmentid INTO currentuserdeptid FROM io_employees WHERE lower(userid) = lower(p_currentuserid) AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;
    BEGIN
      currentusersectorid := 0;
      SELECT sector_id INTO currentusersectorid FROM io_departments WHERE departmentid = currentuserdeptid AND ROWNUM = 1;
      exception WHEN no_data_found THEN NULL;
    END;

    OPEN rct1 FOR
    SELECT * FROM (
                    SELECT DISTINCT incoming.correspondencenumber,
                                    incoming.hijricyear,
                                    incoming.correspondencedate,
                                    incoming.correspondencesubject,
                                    eu.externalunitdesc fromunitname,
                                    incoming.confidentialityid,
                                    incoming.wf_launched,
                                    incoming.receivedby creator,
                                    incoming.externalnumber,
                                    incoming.correspondencenumber displaynumber,
                                    incoming.senderdetails,
                                    incoming.clone_id cloneid,
                                    MAX(CAST(substr(forwardingtime,7,4)
                                      || substr(forwardingtime,4,2)
                                      || substr(forwardingtime,1,2)
                                      || REPLACE(substr(forwardingtime,12,8),':','') AS NUMBER)) last_action_time
                    FROM io_incoming incoming
                    INNER JOIN io_departments depts ON incoming.receivedbydepartmentid = depts.departmentid
                    INNER JOIN io_externalunits eu ON incoming.correspondencesourceid = eu.externalunitid
                    LEFT JOIN io_incomingdestinations dests ON incoming.correspondencenumber = dests.correspondencenumber AND incoming.hijricyear = dests.hijricyear
                    LEFT JOIN io_correspondencesecurity cs ON incoming.correspondencenumber = cs.correspondencenumber AND incoming.hijricyear = cs.hijricyear AND cs.typeid = 1
                    LEFT JOIN io_forwardingshistory fh ON incoming.correspondencenumber = fh.correspondencenumber AND incoming.hijricyear = fh.hijricyear AND fh.typeid = 1
                    LEFT JOIN io_forwardingdetails fd ON fh.forwardingid = fd.forwardingid
                    WHERE
                        (
                          lower(p_currentuserid) = lower(incoming.receivedby)
                          OR lower(p_currentuserid) = lower(fd.participantuserid)
                          OR (
						       incoming.confidentialityid = 0 OR lower(cs.userid) = lower(p_currentuserid) or lower(p_currentuserid) = lower('057902') or lower(p_currentuserid) = lower('ccash') or lower(p_currentuserid) = lower('003847') or lower(p_currentuserid) = lower('mom221005')

                              )
                        )
                    AND (
                                (p_findin = 3)
                             OR (p_findin = 0 AND (lower(p_currentuserid) = lower(incoming.receivedby) OR lower(p_currentuserid) = lower(fd.participantuserid) ))
                             OR (p_findin = 1 AND (currentuserdeptid = incoming.receivedbydepartmentid OR currentuserdeptid = fd.participantdeptid ))
                             OR (p_findin = 1 AND (incoming.receivedbydepartmentid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                             OR (p_findin = 1 AND (fd.participantdeptid IN (SELECT departmentid FROM io_departments WHERE managerid = currentuserempid)))
                             OR (p_findin = 2 AND (depts.sector_id = currentusersectorid))
                             OR (p_findin = 2 AND (fd.participantdeptid IN (SELECT departmentid FROM io_departments WHERE sector_id = currentusersectorid)))
                             OR (p_findin = 4 AND (incoming.correspondencetypeid = 500))
                        )
                    AND (p_corresnumber = -1 OR incoming.correspondencenumber = p_corresnumber)
                    AND	(p_correshijriyear = -1 OR incoming.hijricyear = p_correshijriyear)
                    AND	(p_fromdate = -1 OR incoming.correspondencedate >= p_fromdate)
                    AND	(p_todate = -1 OR incoming.correspondencedate <= p_todate)
                    AND	(p_receivemodeid = -1 OR incoming.receivemodeid = p_receivemodeid)
                    AND (p_fromunitid = -1 OR incoming.correspondencesourceid = p_fromunitid)
                    AND (p_tounitid = -1 OR dests.departmentid = p_tounitid)
                    AND	(p_senderdetails IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(incoming.senderdetails, '??', '??'), '??', '??'), '??', '??'), '??', '??') LIKE p_senderdetails)
                    AND	(p_externalnumber IS NULL OR lower(incoming.externalnumber) = lower(p_externalnumber))
                    AND	(p_corressubject IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(incoming.correspondencesubject, '??', '??'), '??', '??'), '??', '??'), '??', '??') LIKE p_corressubject)
                    AND (p_remarks IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(incoming.remarks, '??', '??'), '??', '??'), '??', '??'), '??', '??') LIKE p_remarks)
                    AND (p_civilid IS NULL OR incoming.civilid LIKE '%'|| p_civilid ||'%')
                    AND ((p_sender IS NULL) OR (fd.forwardingtype = 1 AND lower(fd.participantuserid) = lower(p_sender)))
                    AND (p_corrsubtypeid = -1 OR incoming.correspondencetypeid = p_corrsubtypeid)
                    AND (p_corrcategoryid = -1 OR incoming.correspondencecategoryid = p_corrcategoryid)

                    GROUP BY
                        incoming.correspondencenumber, incoming.hijricyear, incoming.correspondencedate, incoming.correspondencesubject, eu.externalunitdesc,
                        incoming.confidentialityid, incoming.wf_launched, incoming.receivedby, incoming.externalnumber, incoming.senderdetails, incoming.clone_id
                    ORDER BY incoming.correspondencedate DESC, incoming.correspondencenumber DESC
                  )
    WHERE ROWNUM <= 5000;
END;
/
/

-- CHANGED PROCEDURE: IO_SEARCHUNITS
CREATE OR REPLACE PROCEDURE "IO_SEARCHUNITS" 
(
    unittype IN INT,
    searchby IN INT,
    searchtype IN INT,
    target IN out VARCHAR2,
    rct1 out globalpkg.rct1
)
AS

startbytarget VARCHAR2(500);
includestarget VARCHAR2(500);

BEGIN

IF searchby = 1 THEN
     target := REPLACE(REPLACE(REPLACE(REPLACE(target, '?', '?'), '?', '?'), '?', '?'), '?', '?');
END IF;
    
startbytarget := target||'%';
includestarget := '%'||target||'%';

IF unittype = 1 THEN
BEGIN
    OPEN rct1 FOR
    SELECT externalunitid AS unitid,
           org_code AS unitcode,
           externalunitdesc AS unitname
    FROM io_externalunits
    WHERE (searchby = 1 AND searchtype = 1 AND REPLACE(REPLACE(REPLACE(REPLACE(externalunitdesc, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE startbytarget)
    OR    (searchby = 1 AND searchtype = 2 AND REPLACE(REPLACE(REPLACE(REPLACE(externalunitdesc, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE includestarget)
    OR    (searchby = 2 AND searchtype = 1 AND CAST(externalunitid AS VARCHAR(50)) LIKE startbytarget)
    OR    (searchby = 2 AND searchtype = 2 AND CAST(externalunitid AS VARCHAR(50)) LIKE includestarget)
    ORDER BY externalunitid;
END;
ELSE
BEGIN
    OPEN rct1 FOR
    SELECT departmentid AS unitid,
           departmentcode AS unitcode,
           departmentname AS unitname
    FROM io_departments
    WHERE (io_departments.canaccesssystem = 1) AND
          ((searchby = 1 AND searchtype = 1 AND REPLACE(REPLACE(REPLACE(REPLACE(departmentname, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE startbytarget)
    OR    (searchby = 1 AND searchtype = 2 AND REPLACE(REPLACE(REPLACE(REPLACE(departmentname, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE includestarget)
    OR    (searchby = 2 AND searchtype = 1 AND departmentcode LIKE startbytarget)
    OR    (searchby = 2 AND searchtype = 2 AND departmentcode LIKE includestarget))
    ORDER BY departmentcode;

END;
END IF;
END;
/
/

-- CHANGED PROCEDURE: IO_SAVE_SIGNATURE_IMAGE
CREATE OR REPLACE PROCEDURE "IO_SAVE_SIGNATURE_IMAGE" 
(
  p_user_id  IN VARCHAR2,
  p_sig_data IN BLOB
) AS
  mycount INT;
BEGIN
  SELECT COUNT(*) INTO mycount FROM IO_SIGNATURES WHERE user_id = p_user_id;

  IF mycount > 0 THEN
    UPDATE IO_SIGNATURES
       SET SIGNATURE_IMAGE = p_sig_data
     WHERE user_id = p_user_id;
  ELSE
    INSERT INTO IO_SIGNATURES (USER_ID, SIGNATURE_IMAGE)
    VALUES (p_user_id, p_sig_data); 
  END IF;
END IO_SAVE_SIGNATURE_IMAGE;
/
/

-- CHANGED PROCEDURE: IO_SAVE_SIGNATURE
CREATE OR REPLACE PROCEDURE "IO_SAVE_SIGNATURE" 
(
  p_user_id  IN VARCHAR2,
  p_sig_data IN CLOB
) AS
  mycount INT;
BEGIN
  SELECT COUNT(*) INTO mycount FROM IO_SIGNATURES WHERE user_id = p_user_id;

  IF mycount > 0 THEN
    UPDATE IO_SIGNATURES
       SET signature = p_sig_data
     WHERE user_id = p_user_id;
  ELSE
    INSERT INTO IO_SIGNATURES (USER_ID, SIGNATURE, INITIALS)
    VALUES (p_user_id, p_sig_data, EMPTY_CLOB());  -- <-- add INITIALS
  END IF;
END IO_SAVE_SIGNATURE;
/
/

-- CHANGED PROCEDURE: IO_SAVE_INITIAL_IMAGE
CREATE OR REPLACE PROCEDURE "IO_SAVE_INITIAL_IMAGE" 
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
END IO_SAVE_INITIAL_IMAGE;
/
/

-- CHANGED PROCEDURE: IO_SAVE_INITIALS
CREATE OR REPLACE PROCEDURE "IO_SAVE_INITIALS" 
(
  p_user_id  IN VARCHAR2,
  p_sig_data IN CLOB
) AS
  mycount INT;
BEGIN
  SELECT COUNT(*) INTO mycount FROM IO_SIGNATURES WHERE user_id = p_user_id;

  IF mycount > 0 THEN
    UPDATE IO_SIGNATURES
       SET initials = p_sig_data
     WHERE user_id = p_user_id;
  ELSE
    INSERT INTO IO_SIGNATURES (USER_ID, INITIALS, SIGNATURE)
    VALUES (p_user_id, p_sig_data, EMPTY_CLOB());  -- <-- add SIGNATURE
  END IF;
END IO_SAVE_INITIALS;
/
/

-- CHANGED PROCEDURE: IO_R_OUTGOING
CREATE OR REPLACE PROCEDURE "IO_R_OUTGOING" 
(
    fromDate IN INT,
    toDate IN INT,
    fromDepartmentId IN INT,
    externalUnitId IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR 
SELECT DISTINCT
       io_departments.departmentname,
       io_outgoing.CORRESPONDENCESUBJECT,
       (io_outgoing.correspondencenumber || '/' || io_outgoing.hijricyear) AS formatedNumber,
       (SUBSTR(CORRESPONDENCEDATE,7,2) || '/' || SUBSTR(CORRESPONDENCEDATE,5,2) || '/' || SUBSTR(CORRESPONDENCEDATE,0,4)) AS FormattedDate,
       io_outgoing.correspondencenumber,
       io_outgoing.hijricyear,
       io_outgoing.CORRESPONDENCEDATE

FROM io_outgoing INNER JOIN io_outgoingdestinations on 
              io_outgoing.correspondencenumber = io_outgoingdestinations.correspondencenumber
          AND io_outgoing.hijricyear = io_outgoingdestinations.hijricyear
                 INNER JOIN io_externalunits on
        io_outgoingdestinations.correspondencedestinationid = io_externalunits.externalunitid
                 INNER JOIN io_departments on io_outgoing.sentbydepartmentid = io_departments.departmentid
      
WHERE (IO_R_Outgoing.fromDepartmentId = -1 OR io_outgoing.sentbydepartmentid = IO_R_Outgoing.fromDepartmentId)
AND   (IO_R_Outgoing.externalUnitId = -1 OR io_externalunits.externalunitid = IO_R_Outgoing.externalUnitId)
AND   (io_outgoing.CORRESPONDENCEDATE BETWEEN IO_R_Outgoing.fromDate AND IO_R_Outgoing.toDate)

ORDER BY io_outgoing.CORRESPONDENCEDATE DESC;

END;
/
/

-- CHANGED PROCEDURE: IO_R_INTERNAL
CREATE OR REPLACE PROCEDURE "IO_R_INTERNAL" 
(
    fromDate IN INT,
    toDate IN INT,
    fromDepartmentId IN INT,
    departmentUsers IN VARCHAR2,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR 
SELECT DISTINCT io_departments.departmentname,
       io_internal.CORRESPONDENCESUBJECT,
       (io_internal.correspondencenumber || '/' || io_internal.hijricyear) AS formatedNumber,
       (SUBSTR(io_internal.CORRESPONDENCEDATE,7,2) || '/' || SUBSTR(io_internal.CORRESPONDENCEDATE,5,2) || '/' || SUBSTR(io_internal.CORRESPONDENCEDATE,0,4)) AS CORRESPONDENCEDATE,
       io_internal.correspondencenumber,
       io_internal.hijricyear,
       io_internal.CORRESPONDENCEDATE

FROM io_internal INNER JOIN io_departments ON
        io_internal.sentbydepartmentid = io_departments.departmentid

        LEFT OUTER JOIN io_forwardingshistory ON
        io_forwardingshistory.typeid = 3
  AND   io_internal.correspondencenumber = io_forwardingshistory.correspondencenumber
  AND   io_internal.hijricyear = io_forwardingshistory.hijricyear
  
        INNER JOIN io_forwardingdetails ON
        io_forwardingshistory.forwardingid = io_forwardingdetails.forwardingid
  
WHERE (IO_R_Internal.fromDepartmentId = -1 OR io_internal.sentbydepartmentid = IO_R_Internal.fromDepartmentId)
AND   (io_internal.CORRESPONDENCEDATE BETWEEN IO_R_Internal.fromDate AND IO_R_Internal.toDate)
AND   (NVL(INSTR(LOWER(departmentUsers), LOWER(sentby)),0) > 0)
AND   (io_forwardingdetails.FORWARDINGTYPE = 2)
AND   (NVL(INSTR(LOWER(departmentUsers), LOWER(PARTICIPANTUSERID)),0) > 0)

ORDER BY io_internal.CORRESPONDENCEDATE DESC;

END;
/
/

-- CHANGED PROCEDURE: IO_R_INCOMING
CREATE OR REPLACE PROCEDURE "IO_R_INCOMING" 
(
    fromDate IN INT,
    toDate IN INT,
    externalUnitId IN INT,
    departmentUsers VARCHAR2,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR 
SELECT DISTINCT
       io_externalunits.externalunitdesc,
       io_incoming.CORRESPONDENCESUBJECT,
       (io_incoming.correspondencenumber || '/' || io_incoming.hijricyear) AS formatedNumber,
       (SUBSTR(io_incoming.CORRESPONDENCEDATE,7,2) || '/' || SUBSTR(io_incoming.CORRESPONDENCEDATE,5,2) || '/' || SUBSTR(io_incoming.CORRESPONDENCEDATE,0,4)) AS CORRESPONDENCEDATE,
       io_incoming.correspondencenumber,
       io_incoming.hijricyear,
       io_incoming.CORRESPONDENCEDATE

FROM io_incoming INNER JOIN io_externalunits ON
        io_incoming.CORRESPONDENCESOURCEID = io_externalunits.EXTERNALUNITID
        
        LEFT OUTER JOIN io_forwardingshistory ON
        io_forwardingshistory.typeid = 1
  AND   io_incoming.correspondencenumber = io_forwardingshistory.correspondencenumber
  AND   io_incoming.hijricyear = io_forwardingshistory.hijricyear
  
        INNER JOIN io_forwardingdetails ON
        io_forwardingshistory.forwardingid = io_forwardingdetails.forwardingid

WHERE (IO_R_Incoming.externalUnitId = -1 OR io_incoming.CORRESPONDENCESOURCEID = IO_R_Incoming.externalUnitId)
AND   (io_incoming.CORRESPONDENCEDATE BETWEEN IO_R_Incoming.fromDate AND IO_R_Incoming.toDate)
AND   (io_forwardingdetails.FORWARDINGTYPE = 2)
AND   (NVL(INSTR(LOWER(departmentUsers), LOWER(receivedby)),0) > 0 OR NVL(INSTR(LOWER(departmentUsers), LOWER(PARTICIPANTUSERID)),0) > 0)

ORDER BY io_incoming.CORRESPONDENCEDATE DESC;

END;
/
/

-- CHANGED PROCEDURE: IO_OUT_INT_REPORT
CREATE OR REPLACE PROCEDURE "IO_OUT_INT_REPORT" 
(
 recievedID IN NUMBER,
 senderID IN NUMBER,
 fromDate IN NUMBER,
 toDate IN NUMBER,
 RCT1 OUT GLOBALPKG.RCT1
)
AS 
BEGIN
open RCT1 for 
    
    SELECT distinct dep.departmentid,dep.departmentname,intr.correspondencenumber
    FROM io_departments DEP , IO_INTERNAL intr, IO_INTERNALDESTINATIONS des

   where 
          INTR.SENTBYDEPARTMENTID=senderid -- sender
          and (des.departmentid=recievedid OR recievedid=-1) --- reciever
          and intr.correspondencenumber= des.correspondencenumber
          and intr.correspondencedate between fromdate and todate
          and intr.hijricyear= des.hijricyear
          and dep.departmentid= des.departmentid
         order by dep.departmentid, intr.correspondencenumber;
  
END IO_OUT_INT_REPORT;
/
/

-- CHANGED PROCEDURE: IO_ISMANAGER
CREATE OR REPLACE PROCEDURE "IO_ISMANAGER" 
( 
USERID IN VARCHAR2 DEFAULT '',
RCT1 IN OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR
SELECT
IO_DEPARTMENTS.DEPARTMENTNAME,
IO_DEPARTMENTS.MANAGERID,
MANAGER.USERID MANAGER_USERID,
IO_DEPARTMENTS.PARENTDEPARTMENTID,
IO_DEPARTMENTSCONFIGS.ENABLEDOPTIONSMASK,
IO_DEPARTMENTS.DEPARTMENTLEVEL

FROM IO_DEPARTMENTS INNER JOIN io_departmentsconfigs ON IO_DEPARTMENTS.departmentid = io_departmentsconfigs.departmentid
                    INNER JOIN IO_EMPLOYEES MANAGER ON IO_DEPARTMENTS.MANAGERID = MANAGER.EMPLOYEEID
                               --  INNER JOIN IO_DEPARTMENTS pDep ON IO_DEPARTMENTS.PARENTDEPARTMENTID = pDep.DEPARTMENTID                                 
WHERE (IO_ISMANAGER.USERID = MANAGER.USERID );

END;
/
/

-- CHANGED PROCEDURE: IO_HASDELEGATINGMANAGER
CREATE OR REPLACE PROCEDURE "IO_HASDELEGATINGMANAGER" 
(
    userName IN VARCHAR2,
    isManager OUT NUMBER
)
AS
strCurrentDate VARCHAR2(10);
currentDate NUMBER;
empId NUMBER;
BEGIN

DS_GETCURRHIJRIDATE(strCurrentDate);

currentDate := CAST(REPLACE(strCurrentDate, '/', '') AS NUMBER);

SELECT employeeid INTO empId FROM io_employees WHERE LOWER(userid) = LOWER(userName);

SELECT COUNT(*) 
INTO isManager
FROM io_departments
WHERE managerid IN (SELECT employeeid FROM io_employeebackup WHERE backupid=empId AND currentDate BETWEEN startdate AND enddate);

END;
/
/

-- CHANGED PROCEDURE: IO_GET_USER_SIGNATURE
CREATE OR REPLACE PROCEDURE "IO_GET_USER_SIGNATURE" 
(
  p_user_id in varchar2,
  rct1 OUT GLOBALPKG.RCT1
) as 
begin

open rct1 for select signature from io_signatures where user_id = p_user_id;

end io_get_user_signature;
/
/

-- CHANGED PROCEDURE: IO_GET_NONDELIVERED_INTERNAL
CREATE OR REPLACE PROCEDURE "IO_GET_NONDELIVERED_INTERNAL" 
(
     rct1 OUT globalpkg.rct1
    , p_correspondencenumber  IN INT
    , p_hijriyear  IN INT
    , p_correspondencedatefrom  IN INT
    , p_correspondencedateto  IN INT
    , p_correspondencesubject IN OUT VARCHAR2
    , p_userid IN VARCHAR2
)
  AS
  BEGIN

  IF p_correspondencesubject IS NOT NULL THEN
      p_correspondencesubject := '%' || REPLACE(REPLACE(REPLACE(REPLACE(p_correspondencesubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') || '%';
  END IF;
    
OPEN rct1 FOR 
  SELECT 
        correspondencenumber,
        hijricyear,
        correspondencedate,
        correspondencesubject,
        destinationType,
        destinationDeptId,
        destinationEmpUserId,
        destinationDeptName,
        destinationEmpName
  
  FROM dr_internal_items_view
  
  WHERE
    
        (  p_correspondencenumber = -1 OR correspondencenumber = p_correspondencenumber )
        AND (  p_hijriyear = -1 OR hijricyear = p_hijriyear )
        AND (  p_correspondencedatefrom  = -1 OR correspondencedate >= p_correspondencedatefrom )
        AND (  p_correspondencedateto  = -1 OR correspondencedate <= p_correspondencedateto )
        AND (  lower(p_correspondencesubject) IS NULL OR REPLACE(REPLACE(REPLACE(REPLACE(correspondencesubject, '?', '?'), '?', '?'), '?', '?'), '?', '?') LIKE lower(p_correspondencesubject) )  -- zero length string is null in oracle
        AND (sentby = p_userid)
        
  ORDER BY hijricyear desc,correspondencenumber asc;
  
END;
/
/

-- CHANGED PROCEDURE: IO_GET_INTERNAL_DR
CREATE OR REPLACE PROCEDURE "IO_GET_INTERNAL_DR" 
(
     rct1 OUT globalpkg.rct1
    , p_report_id  IN INT
    , p_hijri_year  IN INT
)
  AS
  BEGIN
    
OPEN rct1 FOR 
    SELECT  dr.report_id,
            dr.report_hijri_year,
            dr.date_created,
            dr.creator_user_id,
            docs.ce_document_id,
            docs.ce_document_vs_id,
            items.correspondence_number,
            items.hijri_year,
            internal.correspondencesubject,
            internal.correspondencedate,
            ownerDept.departmentname,
            internal.correspondenceattachments,
            subtypes.correspondencetypeid,
            subtypes.correspondencetypedesc,
            cats.correspondencecategoryid,
            cats.correspondencecategorydesc,
            items.participant_type,
            items.department_id,
            destDept.departmentname,
            items.emp_user_id,
            emps.fullname
  FROM io_internal_delivery_reports dr
  LEFT JOIN io_deliveryreports_docids docs ON docs.report_number = dr.report_id AND docs.report_year = dr.report_hijri_year AND docs.report_type = 3
  INNER JOIN io_internal_dr_items items ON items.report_id = dr.report_id AND items.report_hijri_year = dr.report_hijri_year
  INNER JOIN io_internal internal ON internal.correspondencenumber = items.correspondence_number AND internal.hijricyear          = items.hijri_year
  INNER JOIN io_departments destDept ON destDept.departmentid = items.department_id
  INNER JOIN io_departments ownerDept ON ownerDept.departmentid = internal.sentbydepartmentid
  LEFT JOIN io_employees emps ON emps.userid = items.emp_user_id
  LEFT JOIN io_correspondencetypes subtypes ON subtypes.correspondencetypeid = internal.correspondencetypeid
  LEFT JOIN io_correspondencecategories cats ON cats.correspondencecategoryid = internal.correspondencecategoryid
  
  WHERE 
          dr.report_id = p_report_id AND dr.report_hijri_year = p_hijri_year
        
  ORDER BY hijricyear desc,correspondencenumber asc;
  
END;
/
/

-- CHANGED PROCEDURE: IO_GET_DEPARTMENT_SYMBOL
CREATE OR REPLACE PROCEDURE "IO_GET_DEPARTMENT_SYMBOL" 
(
    pDepartmentid IN INT,
    pDepartmentSymbol OUT VARCHAR2
)
AS
BEGIN

 BEGIN
      SELECT io_departments.symbol
      INTO pDepartmentSymbol
      FROM io_departments
      WHERE io_departments.departmentid = pDepartmentid;
      EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
  END;

END;
/
/

-- CHANGED PROCEDURE: IO_GET_DELIVERED_INTERNAL
CREATE OR REPLACE PROCEDURE "IO_GET_DELIVERED_INTERNAL" 
(
     rct1 OUT globalpkg.rct1
    , p_correspondencenumber  IN INT
    , p_hijriyear  IN INT
)
  AS
  BEGIN
    
OPEN rct1 FOR 
  SELECT    dr.report_id,
            dr.report_hijri_year,
            dr.date_created,
            dr.creator_user_id,
            docs.ce_document_id,
            docs.ce_document_vs_id,
            items.correspondence_number,
            items.hijri_year,
            internal.correspondencesubject,
            internal.correspondencedate,
            ownerDept.departmentname,
            internal.correspondenceattachments,
            subtypes.correspondencetypeid,
            subtypes.correspondencetypedesc,
            cats.correspondencecategoryid,
            cats.correspondencecategorydesc,
            items.participant_type,
            items.department_id,
            destDept.departmentname,
            items.emp_user_id,
            emps.fullname
  FROM io_internal_delivery_reports dr
  LEFT JOIN io_deliveryreports_docids docs ON docs.report_number = dr.report_id AND docs.report_year = dr.report_hijri_year AND docs.report_type = 3
  INNER JOIN io_internal_dr_items items ON items.report_id = dr.report_id AND items.report_hijri_year = dr.report_hijri_year
  INNER JOIN io_internal internal ON internal.correspondencenumber = items.correspondence_number AND internal.hijricyear          = items.hijri_year
  INNER JOIN io_departments destDept ON destDept.departmentid = items.department_id
  INNER JOIN io_departments ownerDept ON ownerDept.departmentid = internal.sentbydepartmentid
  LEFT JOIN io_employees emps ON emps.userid = items.emp_user_id
  LEFT JOIN io_correspondencetypes subtypes ON subtypes.correspondencetypeid = internal.correspondencetypeid
  LEFT JOIN io_correspondencecategories cats ON cats.correspondencecategoryid = internal.correspondencecategoryid
  
  WHERE
    
        (  p_correspondencenumber IS NULL OR items.correspondence_number = p_correspondencenumber )
        AND (  p_hijriyear IS NULL OR items.hijri_year = p_hijriyear )
        
  ORDER BY internal.hijricyear desc, internal.correspondencenumber asc;
  
END;
/
/

-- CHANGED PROCEDURE: IO_GET_ALLEMP_UNDER_DEPT
CREATE OR REPLACE PROCEDURE "IO_GET_ALLEMP_UNDER_DEPT" 
(
    RCT1 OUT GLOBALPKG.RCT1,
    departmentId IN INT
)
AS
BEGIN
OPEN RCT1 FOR
SELECT
  io_employees.userId,
  io_employees.fullName,
  io_departments.departmentId,
  io_employees.jobTitle,
  io_departments.departmentName,
  io_employees.employeeId,
  io_employees.nationalNumber,
  io_employeesconfigs.enabledoptionsmask,
  io_departments.departmentCode,
  io_employeesconfigs.forwardingtolist
  
FROM io_employees INNER JOIN io_departments ON io_employees.departmentId = io_departments.departmentId
                  INNER JOIN io_employeesconfigs ON io_employees.employeeId = io_employeesconfigs.employeeId

WHERE io_employees.isactive = 1
AND  io_employees.departmentId in (SELECT Dept.DEPARTMENTID
                                      FROM io_departments Dept
                                      START WITH Dept.DEPARTMENTID       = IO_Get_AllEmp_Under_Dept.departmentId
                                      CONNECT BY PRIOR Dept.DEPARTMENTID = Dept.PARENTDEPARTMENTID)
    

ORDER BY io_employees.fullName;

END;
/
/

-- CHANGED PROCEDURE: IO_GETMULTIUSERINSTRUCTIONSMOBILE
CREATE OR REPLACE PROCEDURE "IO_GETMULTIUSERINSTRUCTIONSMOBILE" (
    CORRESPONDENCE_NUMBER  IN NUMBER ,
    HIJRIC_YEAR            IN NUMBER ,
    CORRESPONDENCE_TYPE_ID IN NUMBER ,
    RCT1 OUT GLOBALPKG.RCT1 )
AS
BEGIN

  OPEN RCT1 FOR 
  
  SELECT 
    instructions.forwarding_history_id,
    instructions.owner_type,
    instructions.owner_id emp_userid,
    -- when type is department or queue get department manager username
    (case when(owner_type in (2,3)) then managers.userid end) as manager_userid,
    -- when type is department or queue get department representative username
    (case when(owner_type in (2,3)) then representatives.userid end) as rep_userid, 
    queues.queuename queue_name,
    instructions.instruction_text ,instructions.procedure
  FROM MOAMALAT.io_multi_user_instructions instructions INNER JOIN MOAMALAT.io_forwardingshistory history
  ON instructions.forwarding_history_id = history.forwardingid
  LEFT JOIN MOAMALAT.io_departments departments ON departments.departmentid = instructions.owner_id and instructions.owner_type in (2,3)
  LEFT JOIN MOAMALAT.io_employees managers ON managers.employeeid = departments.managerid
  LEFT JOIN MOAMALAT.io_employees representatives ON representatives.employeeid = departments.representativeid
  --LEFT JOIN io_departmentqueues queues on queues.departmentid = instructions.owner_id and instructions.owner_type = 3
  LEFT JOIN MOAMALAT.io_departmentqueues queues on (cast (queues.departmentid as varchar(20))) = instructions.owner_id and instructions.owner_type = 3
  WHERE history.correspondencenumber = IO_GETMULTIUSERINSTRUCTIONSMOBILE.correspondence_number 
        AND history.hijricyear = IO_GETMULTIUSERINSTRUCTIONSMOBILE.hijric_year 
        AND history.typeid = IO_GETMULTIUSERINSTRUCTIONSMOBILE.correspondence_type_id
  ORDER BY instructions.owner_type;

END IO_GETMULTIUSERINSTRUCTIONSMOBILE;
/
/

-- CHANGED PROCEDURE: IO_GETMULTIUSERINSTRUCTIONS
CREATE OR REPLACE PROCEDURE "IO_GETMULTIUSERINSTRUCTIONS" (
    CORRESPONDENCE_NUMBER  IN NUMBER ,
    HIJRIC_YEAR            IN NUMBER ,
    CORRESPONDENCE_TYPE_ID IN NUMBER ,
    RCT1 OUT GLOBALPKG.RCT1 )
AS
BEGIN

  OPEN RCT1 FOR 
  
  SELECT 
    instructions.forwarding_history_id,
    instructions.owner_type,
    instructions.owner_id emp_userid,
    -- when type is department or queue get department manager username
    (case when(owner_type in (2,3)) then managers.userid end) as manager_userid,
    -- when type is department or queue get department representative username
    (case when(owner_type in (2,3)) then representatives.userid end) as rep_userid, 
    queues.queuename queue_name,
    instructions.instruction_text 
  FROM io_multi_user_instructions instructions INNER JOIN io_forwardingshistory history
  ON instructions.forwarding_history_id = history.forwardingid
  LEFT JOIN io_departments departments ON departments.departmentid = instructions.owner_id and instructions.owner_type in (2,3)
  LEFT JOIN io_employees managers ON managers.employeeid = departments.managerid
  LEFT JOIN io_employees representatives ON representatives.employeeid = departments.representativeid
  --LEFT JOIN io_departmentqueues queues on queues.departmentid = instructions.owner_id and instructions.owner_type = 3
  LEFT JOIN io_departmentqueues queues on (cast (queues.departmentid as varchar(20))) = instructions.owner_id and instructions.owner_type = 3
  WHERE history.correspondencenumber = IO_GETMULTIUSERINSTRUCTIONS.correspondence_number 
        AND history.hijricyear = IO_GETMULTIUSERINSTRUCTIONS.hijric_year 
        AND history.typeid = IO_GETMULTIUSERINSTRUCTIONS.correspondence_type_id
  ORDER BY instructions.owner_type;

END IO_GETMULTIUSERINSTRUCTIONS;
/
/

-- CHANGED PROCEDURE: IO_GETMANAGEDDEP
CREATE OR REPLACE PROCEDURE "IO_GETMANAGEDDEP" 
(
EMPUSERID IN VARCHAR2,
RCT1 OUT GLOBALPKG.RCT1
)
AS 
BEGIN
 OPEN RCT1 FOR 
    select emp.employeeid,emp.fullname,emp.departmentid,dep.departmentid,dep.departmentname 
    from IO_EMPLOYEES emp left join IO_DEPARTMENTS dep on 
    emp.employeeid= dep.managerid and dep.isactive=1
    where 
    lower(emp.userid)=lower(empuserid);
END IO_GETMANAGEDDEP;
/
/

-- CHANGED PROCEDURE: IO_GETINTERNALUNITSREGIONS
CREATE OR REPLACE PROCEDURE "IO_GETINTERNALUNITSREGIONS" 
(
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT departmentid, nvl(receivemodeid, 1) as receivemodeid, departmentname FROM io_departments
left join io_regionmembers on departmentid = memberid and membertype = 2
left join io_regions on io_regionmembers.regionid = io_regions.regionid
where canaccesssystem=0;
END;
/
/

-- CHANGED PROCEDURE: IO_GETINTERNALDESTINATIONS
CREATE OR REPLACE PROCEDURE "IO_GETINTERNALDESTINATIONS" 
(
    correspondencenumber IN INT,
    hijricyear IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR

SELECT participanttype,
       io_employees.fullname,
       io_departmentqueues.departmentnamear as queuedepartmentname,
       io_departments.departmentname
FROM io_internaldestinations 
      LEFT JOIN io_employees ON io_internaldestinations.employeeloginid = io_employees.userid
      LEFT JOIN io_departments ON io_internaldestinations.departmentid = io_departments.departmentid
      LEFT JOIN io_departmentqueues ON io_internaldestinations.departmentid = io_departmentqueues.departmentid
WHERE (io_internaldestinations.correspondencenumber = IO_GetInternalDestinations.correspondencenumber)
  AND (io_internaldestinations.hijricyear = IO_GetInternalDestinations.hijricyear);

END;
/
/

-- CHANGED PROCEDURE: IO_GETINCOMINGDESTINATIONS
CREATE OR REPLACE PROCEDURE "IO_GETINCOMINGDESTINATIONS" 
(
    correspondencenumber IN INT,
    hijricyear IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR

SELECT participanttype,
       io_employees.fullname,
       io_departmentqueues.departmentnamear as queuedepartmentname,
       io_departments.departmentname,
       io_departments.departmentId,
       io_departments.departmentCode
FROM io_incomingdestinations 
      LEFT JOIN io_employees ON io_incomingdestinations.employeeloginid = io_employees.userid
      LEFT JOIN io_departments ON io_incomingdestinations.departmentid = io_departments.departmentid
      LEFT JOIN io_departmentqueues ON io_incomingdestinations.departmentid = io_departmentqueues.departmentid
WHERE (io_incomingdestinations.correspondencenumber = IO_GetIncomingDestinations.correspondencenumber)
  AND (io_incomingdestinations.hijricyear = IO_GetIncomingDestinations.hijricyear);

END;
/
/

-- CHANGED PROCEDURE: IO_GETGROUPMEMBERS
CREATE OR REPLACE PROCEDURE "IO_GETGROUPMEMBERS" 
(
    GROUPID IN INT,
    MEMBERTYPE IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS

BEGIN

OPEN RCT1 FOR
SELECT 
  GROUPID,
  MEMBERID,
  MEMBERTYPE,
  io_employees.userid as employeeuserid,
  manager.userid as departmentuserid,
  io_externalunits.externalunitdesc
  
FROM io_exportinggroupmembers left join io_departments on MEMBERID = departmentId and membertype = 2
                              left join io_employees on MEMBERID = employeeId and membertype = 3
                              left join io_employees manager on io_departments.managerid = manager.employeeid
                              left join io_externalunits on MEMBERID = externalunitId and membertype = 1
     
WHERE (IO_GETGROUPMEMBERS.GROUPID = io_exportinggroupmembers.GROUPID)
AND   (IO_GETGROUPMEMBERS.MEMBERTYPE = -1 OR IO_GETGROUPMEMBERS.MEMBERTYPE = io_exportinggroupmembers.MEMBERTYPE);

END;
/
/

-- CHANGED PROCEDURE: IO_GETFORWARDINGSHISTORY
CREATE OR REPLACE PROCEDURE "IO_GETFORWARDINGSHISTORY" 
(
    correspondenceNumber IN INT,
    hijricYear IN INT,
    typeId IN INT,
    currentUserId IN VARCHAR2,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR 
SELECT DISTINCT
io_forwardingshistory.FORWARDINGID,
io_forwardingshistory.CORRESPONDENCENUMBER,
io_forwardingshistory.HIJRICYEAR,
io_forwardingshistory.TYPEID,
io_forwardingshistory.URGENCYLEVEL,
io_forwardingshistory.IMPORTANCELEVEL,
io_forwardingshistory.FORWARDINGTIME,
io_forwardingshistory.REMINDER,
io_forwardingshistory.DEADLINE,
NVL(Tmp_UserComments.HasRemarks, 0) AS HasRemarks,
io_forwardingshistory.INSTRUCTIONS,
src.participantuserid,
src.participantdeptid,
src.participanttype,
srcEmps.fullname AS fromemployeename,
srcDepts.departmentname AS fromdepartmentname,
srcQueues.departmentnamear AS fromqueuedeptname,
GETINSTRPERMISSION(io_forwardingshistory.FORWARDINGID, currentUserId) AS permissiontype,
dest.participanttype,
destEmps.departmentid AS toDepartmentId,
destDepts.departmentname AS toDepartmentName,
destQueues.departmentid AS toQueueDepartmentId,
destQueues.departmentnamear AS toQueueDeptName,
src.IS_DELEGATED          AS SRC_IS_DELEGATED, --column number 24
src.DELEGATION_TYPE       AS SRC_DELEGATION_TYPE,
src.DELEGATE_USERID       AS SRC_DELEGATE_USERID,
dest.IS_DELEGATED         AS DEST_IS_DELEGATED,
dest.DELEGATION_TYPE      AS DEST_DELEGATION_TYPE,
dest.DELEGATE_USERID      AS DEST_DELEGATE_USERID

FROM  io_forwardingshistory INNER JOIN io_forwardingdetails src
      ON io_forwardingshistory.FORWARDINGID = src.FORWARDINGID AND src.forwardingtype = 1 --join with the "ForwardingType = From" detail...
                            LEFT JOIN io_employees srcEmps
      ON lower(src.participantuserid) = lower(srcEmps.userid)
                            LEFT JOIN io_departments srcDepts
      ON src.participantdeptid = srcDepts.departmentid
                            LEFT JOIN io_departmentqueues srcQueues
      ON src.participantdeptid = srcQueues.departmentid
      
                            LEFT JOIN io_forwardingdetails dest   -- LEFT JOIN because "save action" forwardings do not have a destination
      ON io_forwardingshistory.FORWARDINGID = dest.FORWARDINGID AND dest.forwardingtype in (2,3) --join with the "ForwardingType = To and CC" detail...
                            LEFT JOIN io_employees destEmps
      ON lower(dest.participantuserid) = lower(destEmps.userid)
                            LEFT JOIN io_departments destDepts
      ON destEmps.departmentid = destDepts.departmentid
                            LEFT JOIN io_departmentqueues destQueues
      ON lower(dest.participantuserid) = lower(destQueues.queuename)
      
                            LEFT JOIN (SELECT FORWARDINGID, CAST(COUNT(*) AS NUMBER(2)) HasRemarks FROM io_usercomments WHERE typeid = IO_GetForwardingsHistory.typeId GROUP BY FORWARDINGID) Tmp_UserComments
      ON io_forwardingshistory.FORWARDINGID = Tmp_UserComments.FORWARDINGID

WHERE (io_forwardingshistory.CorrespondenceNumber = IO_GetForwardingsHistory.correspondenceNumber)
AND (io_forwardingshistory.HijricYear = IO_GetForwardingsHistory.hijricYear)
AND (io_forwardingshistory.typeId = IO_GetForwardingsHistory.typeId)

--ORDER BY io_forwardingshistory.FORWARDINGID;
--ORDER BY TO_DATE(FORWARDINGTIME, 'DD/MM/YYYY HH24:MI:SS');  -- some hijri dates are invalid as gregorian such as 30-FEB (max days in FEB is 29)
--ORDER BY TO_DATE(FORWARDINGTIME, 'DD/MM/YYYY HH24:MI:SS','nls_calendar=''English Hijrah'''); -- MAY FAIL, BECAUSE FORWARDINGTIME CAN HAVE HOUR 24:00:00 INSTEAD OF 00:00:00, and to_date takes range 0-23
ORDER BY TO_DATE(REGEXP_REPLACE(forwardingtime, '(24)\:([[:digit:]]{2})\:([[:digit:]]{2})', '00:\2:\3'), 'DD/MM/YYYY HH24:MI:SS','nls_calendar=''English Hijrah''');

END;
/
/

-- CHANGED PROCEDURE: IO_GETFORWARDINGDETAILS
CREATE OR REPLACE PROCEDURE "IO_GETFORWARDINGDETAILS" 
(
    forwardingid   IN  INT,
    forwardingtype IN  INT,
    RCT1           OUT GLOBALPKG.RCT1
)
AS
BEGIN
    OPEN RCT1 FOR
    SELECT
        io_forwardingdetails.forwardingdetailid,
        io_forwardingdetails.forwardingid,
        io_forwardingdetails.forwardingtype,
        io_forwardingdetails.participantuserid,
        io_forwardingdetails.participantdeptid,
        io_forwardingdetails.participanttype,
        io_employees.fullname                AS employeename,
        io_departments.departmentname,
        io_departmentqueues.departmentnamear AS queuedeptname,
        -- NEW delegation columns (safe to append)
        io_forwardingdetails.is_delegated,
        io_forwardingdetails.delegation_type,
        io_forwardingdetails.delegate_userid
    FROM io_forwardingdetails
         LEFT JOIN io_employees
           ON LOWER(io_forwardingdetails.participantuserid) = LOWER(io_employees.userid)
         LEFT JOIN io_departments
           ON io_forwardingdetails.participantdeptid = io_departments.departmentid
         LEFT JOIN io_departmentqueues
           ON io_forwardingdetails.participantdeptid = io_departmentqueues.departmentid
    WHERE (io_forwardingdetails.forwardingid = IO_GetForwardingDetails.forwardingid)
      AND (IO_GetForwardingDetails.forwardingtype = -1
           OR io_forwardingdetails.forwardingtype = IO_GetForwardingDetails.forwardingtype)
    ORDER BY io_forwardingdetails.FORWARDINGID;
END;
/
/

-- CHANGED PROCEDURE: IO_GETEMPLOYEEMANAGER
CREATE OR REPLACE PROCEDURE "IO_GETEMPLOYEEMANAGER" 
(
    userName IN VARCHAR2,
    RCT1 OUT GLOBALPKG.RCT1
)
AS

m_employeeid INT;
m_managerid INT;
m_managerdepartmentid INT;
m_parentmanagerid INT;

BEGIN

m_parentmanagerid := -1;

select employeeid
into m_employeeid
from io_employees
where lower(IO_GETEMPLOYEEMANAGER.userName)=lower(userid);

select d.managerid, d.departmentid
into m_managerid, m_managerdepartmentid
from io_employees e
inner join io_departments d on e.departmentid = d.departmentid
where lower(userid)=lower(IO_GETEMPLOYEEMANAGER.userName) and rownum = 1;

if m_employeeid = m_managerid then
begin
  select pd.managerid
  into m_parentmanagerid
  from io_departments d
  inner join io_departments pd on d.parentdepartmentid = pd.departmentid
  where d.departmentid = m_managerdepartmentid;
  exception when NO_DATA_FOUND then m_parentmanagerid := m_managerid;
end;
end if;

if m_parentmanagerid <> -1 then
  m_managerid := m_parentmanagerid;
end if;

OPEN RCT1 FOR
SELECT
  io_employees.userId,
  io_employees.fullName,
  io_departments.departmentId,
  io_employees.jobTitle,
  io_departments.departmentName,
  io_employees.employeeId,
  io_employees.nationalNumber,
  io_employeesconfigs.enabledoptionsmask,
  io_departments.departmentCode,
  io_employeesconfigs.forwardingtolist
  
FROM io_employees INNER JOIN io_departments ON io_employees.departmentId = io_departments.departmentId
                  INNER JOIN io_employeesconfigs ON io_employees.employeeId = io_employeesconfigs.employeeId

WHERE (io_employees.employeeid = m_managerid);

END;
/
/

-- CHANGED PROCEDURE: IO_GETEMPLOYEEDEPARTMENT
CREATE OR REPLACE PROCEDURE "IO_GETEMPLOYEEDEPARTMENT" 
(
    userName IN VARCHAR2,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT 
  io_departments.departmentid,
  io_departments.departmentname,
  manager.userid as manageruserid,
  manager.fullname as managerfullname,
  rep.userid as representativeuserid,
  rep.fullname as representativefullname,
  io_departments.parentdepartmentid,
  io_departmentqueues.departmentnamear,
  io_departmentqueues.queuename,
  io_departmentsconfigs.enabledoptionsmask,
  io_departments.departmentlevel,
  io_departments.departmentCode,
  io_departments.archive_page_url,
  io_departments.sector_id

from io_employees inner join io_departments on io_employees.departmentid = io_departments.departmentid
                  INNER JOIN io_departmentsconfigs ON IO_DEPARTMENTS.departmentid = io_departmentsconfigs.departmentid
                  inner join io_employees manager on io_departments.managerid = manager.employeeid
                  left join io_employees rep on io_departments.managerid = rep.employeeid     
                  left join io_departmentqueues on io_departments.departmentid = io_departmentqueues.departmentid
where lower(io_employees.userid) = lower(userName);

END;
/
/

-- CHANGED PROCEDURE: IO_GETDESTINATIONS_INTERNALS
CREATE OR REPLACE PROCEDURE "IO_GETDESTINATIONS_INTERNALS" 
( correspondencenumber  IN INT
, hijricyear IN INT
, RCT1 OUT GLOBALPKG.RCT1
) AS
BEGIN
OPEN RCT1 FOR

SELECT 
       io_employees.fullname,
       io_departmentqueues.departmentnamear as queuedepartmentname,
       io_departments.departmentname,
       io_internal.CORRESPONDENCENUMBER,
       io_internal.HIJRICYEAR,
       io_internal.CORRESPONDENCEDATE,       
       io_internal.CORRESPONDENCESUBJECT,
       io_internal.REMARKS,
       io_internal.CORRESPONDENCEATTACHMENTS,
       io_internal.SENTBY,
       io_internal.SENTBYDEPARTMENTID, PARTICIPANTTYPE
       
FROM io_internaldestinations 
      LEFT JOIN io_employees ON io_internaldestinations.employeeloginid = io_employees.userid
      LEFT JOIN io_departments ON io_internaldestinations.departmentid = io_departments.departmentid
      LEFT JOIN io_departmentqueues ON io_internaldestinations.departmentid = io_departmentqueues.departmentid
      LEFT JOIN io_internal ON io_internaldestinations.CORRESPONDENCENUMBER = io_internal.CORRESPONDENCENUMBER
WHERE (io_internaldestinations.correspondencenumber = IO_GETDESTINATIONS_INTERNALS.correspondencenumber)
  AND (io_internaldestinations.hijricyear = IO_GETDESTINATIONS_INTERNALS.hijricyear);

END IO_GETDESTINATIONS_INTERNALS;
/
/

-- CHANGED PROCEDURE: IO_GETDESTINATIONS_INCOMINGS
CREATE OR REPLACE PROCEDURE "IO_GETDESTINATIONS_INCOMINGS" 
( correspondencenumber  IN INT
, hijricyear IN INT
, RCT1 OUT GLOBALPKG.RCT1
) AS
BEGIN
OPEN RCT1 FOR

SELECT 
       io_employees.fullname,
       io_departmentqueues.departmentnamear as queuedepartmentname,
       io_departments.departmentname,
       io_incoming.CORRESPONDENCENUMBER,
        io_incoming.HIJRICYEAR,
        io_incoming.CORRESPONDENCEDATE,                
        io_incoming.CORRESPONDENCESUBJECT,
        io_incoming.REMARKS,
        io_incoming.EXTERNALNUMBER,        
        io_incoming.CORRESPONDENCEATTACHMENTS,
        io_incoming.RECEIVEDBY,
        PARTICIPANTTYPE
       
FROM io_incomingdestinations
      LEFT JOIN io_employees ON io_incomingdestinations.employeeloginid = io_employees.userid
      LEFT JOIN io_departments ON io_incomingdestinations.departmentid = io_departments.departmentid
      LEFT JOIN io_departmentqueues ON io_incomingdestinations.departmentid = io_departmentqueues.departmentid
      LEFT JOIN io_incoming ON io_incomingdestinations.CORRESPONDENCENUMBER = io_incoming.CORRESPONDENCENUMBER
WHERE (io_incomingdestinations.correspondencenumber = IO_GETDESTINATIONS_INCOMINGS.correspondencenumber)
  AND (io_incomingdestinations.hijricyear = IO_GETDESTINATIONS_INCOMINGS.hijricyear);

END IO_GETDESTINATIONS_INCOMINGS;
/
/

-- CHANGED PROCEDURE: IO_GETDESTINATIONS_CIRCULARS
CREATE OR REPLACE PROCEDURE "IO_GETDESTINATIONS_CIRCULARS" 
( correspondencenumber  IN INT
, hijricyear IN INT
, RCT1 OUT GLOBALPKG.RCT1
) AS
BEGIN
OPEN RCT1 FOR

SELECT 
       io_employees.fullname,
       io_departmentqueues.departmentnamear as queuedepartmentname,
       io_departments.departmentname,
       io_circular.CORRESPONDENCENUMBER,
       io_circular.HIJRICYEAR,
       io_circular.CORRESPONDENCEDATE,       
       io_circular.CORRESPONDENCESUBJECT,
       io_circular.REMARKS,
       io_circular.CORRESPONDENCEATTACHMENTS,
       io_circular.SENTBY,
       io_circular.SENTBYDEPARTMENTID, PARTICIPANTTYPE
       
FROM io_circulardestinations 
      LEFT JOIN io_employees ON io_circulardestinations.employeeloginid = io_employees.userid
      LEFT JOIN io_departments ON io_circulardestinations.departmentid = io_departments.departmentid
      LEFT JOIN io_departmentqueues ON io_circulardestinations.departmentid = io_departmentqueues.departmentid
      LEFT JOIN io_circular ON io_circulardestinations.CORRESPONDENCENUMBER = io_circular.CORRESPONDENCENUMBER
WHERE (io_circulardestinations.correspondencenumber = IO_GETDESTINATIONS_CIRCULARS.correspondencenumber)
  AND (io_circulardestinations.hijricyear = IO_GETDESTINATIONS_CIRCULARS.hijricyear);

END IO_GETDESTINATIONS_CIRCULARS;
/
/

-- CHANGED PROCEDURE: IO_GETDEPARTMENTSREPS
CREATE OR REPLACE PROCEDURE "IO_GETDEPARTMENTSREPS" 
(
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT io_employees.userid,
       io_departments.departmentid,
       io_departments.departmentname,
       io_departmentqueues.departmentnamear,
       io_departmentqueues.queuename,
       io_departments.departmentcode
FROM io_departments INNER JOIN
     io_employees ON io_departments.representativeid = io_employees.employeeid
                    LEFT JOIN
     io_departmentqueues ON io_departments.departmentid = io_departmentqueues.departmentid

WHERE (io_departments.canaccesssystem = 1)

ORDER BY io_departments.departmentname;

END;
/
/

-- CHANGED PROCEDURE: IO_GETDEPARTMENTSMANGERS
CREATE OR REPLACE PROCEDURE "IO_GETDEPARTMENTSMANGERS" 
(
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT 
       io_employees.userid as userid,
       io_departments.departmentid,
       io_departments.departmentname,
       io_departmentqueues.departmentnamear,
       io_departmentqueues.queuename,
       io_departments.departmentcode ,
        bitand(enabledoptionsmask , 16)
       
FROM io_departments 
      INNER JOIN io_departmentsconfigs ON IO_DEPARTMENTS.departmentid = io_departmentsconfigs.departmentid                    
      INNER JOIN io_employees ON io_departments.managerid = io_employees.employeeid
      LEFT outer JOIN io_employees rep ON io_departments.representativeid = rep.employeeid
      LEFT JOIN  io_departmentqueues ON io_departments.departmentid = io_departmentqueues.departmentid

WHERE (io_departments.isactive = 1 AND io_departments.canaccesssystem = 1)

ORDER BY io_departments.departmentname;

END;
/
/

-- CHANGED PROCEDURE: IO_GETDEPARTMENTSBYLEVEL
CREATE OR REPLACE PROCEDURE "IO_GETDEPARTMENTSBYLEVEL" 
(
    departmentLevel IN INT,
    parenetDepartmentId IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT 
  io_departments.departmentid,
  io_departments.departmentname,
  manager.userid as manageruserid,
  manager.fullname as managerfullname,
  rep.userid as representativeuserid, 
  rep.fullname as representativefullname,
  io_departments.parentdepartmentid,
  io_departmentqueues.departmentnamear,
  io_departmentqueues.queuename,
  io_departmentsconfigs.enabledoptionsmask,
  io_departments.departmentLevel,
  io_departments.departmentCode
  
FROM io_departments INNER JOIN io_departmentsconfigs ON IO_DEPARTMENTS.departmentid = io_departmentsconfigs.departmentid
                    INNER JOIN io_employees manager ON io_departments.managerid = manager.employeeid
                    LEFT JOIN io_employees rep ON io_departments.representativeid = rep.employeeid
                    LEFT JOIN io_departmentqueues ON io_departments.departmentid = io_departmentqueues.departmentid
     
WHERE (io_departments.isactive = 1)
AND (io_departments.departmentlevel=IO_GETDEPARTMENTSByLevel.departmentlevel)
And (io_departments.departmentLEVEL != -1)
And (io_departments.parentdepartmentid != IO_GETDEPARTMENTSByLevel.parenetDepartmentId)

ORDER BY io_departments.departmentname;

END;
/
/

-- CHANGED PROCEDURE: IO_GETDEPARTMENTQUEUES
CREATE OR REPLACE PROCEDURE "IO_GETDEPARTMENTQUEUES" 
(
    department_Id IN INT,
    queue_Name IN VARCHAR2,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT 
DEPARTMENTID,
DEPARTMENTNAMEAR,
DEPARTMENTNAMEEN,
QUEUENAME,
QUEUESHORTNAME
  
FROM io_departmentqueues
     
WHERE (department_Id = -1 OR DEPARTMENTID = department_Id)
AND (queue_Name IS NULL OR lower(QUEUENAME) = lower(queue_Name))

ORDER BY QUEUENAME;

END;
/
/

-- CHANGED PROCEDURE: IO_GETDEPARTMENTBYCODE
CREATE OR REPLACE PROCEDURE "IO_GETDEPARTMENTBYCODE" 
(
  debCode IN VARCHAR2,
  depName out VARCHAR2,
  depID out Int
)

AS 
BEGIN
  
    select dep.departmentname, dep.departmentid into depName,depid  from IO_DEPARTMENTS dep
    where dep.departmentcode = debCode;
END IO_GETDEPARTMENTBYCODE;
/
/

-- CHANGED PROCEDURE: IO_GETDEPARTMENTBROTHERS
CREATE OR REPLACE PROCEDURE "IO_GETDEPARTMENTBROTHERS" 
(
DEPID IN  INT,
RCT1 OUT GLOBALPKG.RCT1
)

AS 

BEGIN
OPEN RCT1 FOR
SELECT DEPARTMENTID,DEPARTMENTNAME,dep.parentdepartmentid FROM IO_DEPARTMENTS DEP where DEP.PARENTDEPARTMENTID
in (select AA.PARENTDEPARTMENTID from IO_DEPARTMENTS AA WHERE AA.DEPARTMENTID = DEPID )
ORDER BY DEP.DEPARTMENTID;

END IO_GETDEPARTMENTBROTHERS;
/
/

-- CHANGED PROCEDURE: IO_GETDELEGATINGEMPLOYEES
CREATE OR REPLACE PROCEDURE "IO_GETDELEGATINGEMPLOYEES" 
(
    userName IN VARCHAR2,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
strCurrentDate VARCHAR2(10);
currentDate NUMBER;
empId NUMBER;
BEGIN

DS_GETCURRHIJRIDATE(strCurrentDate);
currentDate:= CAST(REPLACE(strCurrentDate, '/', '') AS NUMBER);

BEGIN
select employeeid into empid from io_employees where lower(userid) = lower(username);
EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
END;

OPEN RCT1 FOR
SELECT  io_employees.userId,
        io_employees.fullName,
        io_departments.departmentId,
        io_employees.jobTitle,
        io_departments.departmentName,
        io_employees.employeeId,
        io_employees.nationalNumber,
        io_employeesconfigs.enabledoptionsmask,
        io_departments.departmentcode,
        io_employeesconfigs.forwardingToList
  
FROM io_employeebackup
INNER JOIN io_employees ON io_employeebackup.employeeid = io_employees.employeeid
INNER JOIN io_departments ON io_employees.departmentId = io_departments.departmentId
INNER JOIN io_employeesconfigs ON io_employeebackup.employeeid = io_employeesconfigs.employeeid

WHERE backupid=empId AND currentDate BETWEEN startdate AND enddate

ORDER BY io_employees.fullName;

END;
/
/

-- CHANGED PROCEDURE: IO_GETDECISION
CREATE OR REPLACE PROCEDURE "IO_GETDECISION" 
(
    decisionNumber IN INT,
    hijricYear IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT 
decisionNumber,
hijricYear,
decisionDate,
decisionType,
decisionSubject,
preparedByDepartmentId,
departmentName,
createdBy,
remarks,
wf_launched,
approvedBy,
approvalDate,
NVL(outgoingNumber, -1) AS outgoingNumber,
NVL(outgoingHijricYear, -1) AS outgoingHijricYear

FROM io_decisions inner join io_departments on io_decisions.PREPAREDBYDEPARTMENTID = io_departments.departmentid
      
WHERE (IO_GetDecision.decisionNumber = -1 OR io_decisions.decisionNumber = IO_GetDecision.decisionNumber)
AND (IO_GetDecision.hijricYear = -1 OR io_decisions.hijricYear = IO_GetDecision.hijricYear);

END;
/
/

-- CHANGED PROCEDURE: IO_GETCUSTOMFORWARDINGTOLIST
CREATE OR REPLACE PROCEDURE "IO_GETCUSTOMFORWARDINGTOLIST" 
(
    employeeid IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN

OPEN RCT1 FOR
select efl.priticipanttype,
       e.userid as employeeUserId,
       dm.userid as managerUserId,
       dq.queuename,
       e.departmentid as employeeDepartmentId,
       d.departmentid as managerDepartmentId,
       e.fullname,
       d.departmentname,
       dq.departmentnamear,
       d.departmentcode
from io_eligibleforwardingtolist efl
left join io_employees e on efl.participantid = e.employeeid and efl.priticipanttype = 1
left join io_departments d on efl.participantid = d.departmentid and (efl.priticipanttype = 2 or efl.priticipanttype = 3)
left join io_employees dm on d.REPRESENTATIVEID = dm.employeeid and efl.priticipanttype = 2
left join io_departmentqueues dq on efl.participantid = dq.departmentid and efl.priticipanttype = 3
where efl.employeeid = IO_GETCUSTOMFORWARDINGTOLIST.employeeid and ((efl.priticipanttype = 1 and e.isactive = 1) or efl.priticipanttype > 1);

END;
/
/

-- CHANGED PROCEDURE: IO_GETCIRCULARDESTINATIONS
CREATE OR REPLACE PROCEDURE "IO_GETCIRCULARDESTINATIONS" 
(
    correspondencenumber IN INT,
    hijricyear IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR

SELECT participanttype,
       io_employees.fullname,
       io_departmentqueues.departmentnamear as queuedepartmentname,
       io_departments.departmentname
FROM io_circulardestinations 
      LEFT JOIN io_employees ON io_circulardestinations.employeeloginid = io_employees.userid
      LEFT JOIN io_departments ON io_circulardestinations.departmentid = io_departments.departmentid
      LEFT JOIN io_departmentqueues ON io_circulardestinations.departmentid = io_departmentqueues.departmentid
WHERE (io_circulardestinations.correspondencenumber = IO_GETCIRCULARDESTINATIONS.correspondencenumber)
  AND (io_circulardestinations.hijricyear = IO_GETCIRCULARDESTINATIONS.hijricyear);

END;
/
/

-- CHANGED PROCEDURE: IO_GETCIRCULAR
CREATE OR REPLACE PROCEDURE "IO_GETCIRCULAR" 
(
    correspondenceNumber IN INT,
    hijricYear IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
OPEN RCT1 FOR
SELECT 
io_circular.CORRESPONDENCENUMBER,
io_circular.HIJRICYEAR,
io_circular.CORRESPONDENCEDATE,
io_circular_types.circular_type_id,
io_circular_types.circular_type_name,
io_circular.CORRESPONDENCESUBJECT,
io_circular.REMARKS,
io_circular.CORRESPONDENCEATTACHMENTS,
io_circular.SENTBY,
io_circular.SOURCE_ID,
io_confidentiality.CONFIDENTIALITYID,
io_confidentiality.confidentialitydesc,
io_circular.WF_LAUNCHED,
io_circular.ISEXPORTED,
io_circular.EXTERNALNUMBER,
io_circular.SOURCE_DETAILS,
io_circular.sentbydepartmentid,
sender_dept.departmentname sentbydepartmentname,
source_dept.departmentname sourcedepartmentname,
io_externalunits.externalunitdesc

FROM io_circular inner join io_circular_types on io_circular.source_type_id = io_circular_types.circular_type_id
      inner join io_confidentiality on io_circular.CONFIDENTIALITYID = io_confidentiality.CONFIDENTIALITYID
      left join io_departments sender_dept on io_circular.sentbydepartmentid = sender_dept.departmentid
      left join io_departments source_dept on io_circular.source_id = source_dept.departmentid
      left join io_externalunits on io_circular.source_id = io_externalunits.externalunitid
      
WHERE (IO_GETCIRCULAR.correspondenceNumber = -1 OR io_circular.correspondenceNumber = IO_GETCIRCULAR.correspondenceNumber)
AND (IO_GETCIRCULAR.hijricYear = -1 OR io_circular.hijricYear = IO_GETCIRCULAR.hijricYear);

END;
/
/

-- CHANGED PROCEDURE: IO_GETCHILDDEPTSREPS
CREATE OR REPLACE PROCEDURE "IO_GETCHILDDEPTSREPS" 
(
    departmentid IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN

OPEN RCT1 FOR
SELECT
  managers.userId,
  managers.fullName,
  childs.departmentId,
  managers.jobTitle,
  childs.departmentName,
  managers.employeeId,
  managers.nationalNumber,
  ec.enabledoptionsmask,
  childs.departmentCode,
  ec.forwardingtolist
from io_departments childs
inner join io_employees managers on childs.representativeid = managers.employeeid
inner join io_employeesconfigs ec on managers.employeeId = ec.employeeId
where (parentdepartmentid = IO_GETCHILDDEPTSREPS.departmentid)
  and (childs.isactive = 1 and managers.isactive = 1);

END;
/
/

-- CHANGED PROCEDURE: IO_GETCHILDDEPTSMANAGERS
CREATE OR REPLACE PROCEDURE "IO_GETCHILDDEPTSMANAGERS" 
(
    departmentid IN INT,
    RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN

OPEN RCT1 FOR
SELECT
  managers.userId,
  managers.fullName,
  childs.departmentId,
  managers.jobTitle,
  childs.departmentName,
  managers.employeeId,
  managers.nationalNumber,
  ec.enabledoptionsmask,
  childs.departmentCode,
  ec.forwardingtolist
from io_departments childs
inner join io_employees managers on childs.managerid = managers.employeeid
inner join io_employeesconfigs ec on managers.employeeId = ec.employeeId
where (parentdepartmentid = IO_GETCHILDDEPTSMANAGERS.departmentid)
  and (childs.isactive = 1 and managers.isactive = 1);

END;
/
/

-- CHANGED PROCEDURE: IO_COM_INT_REPORT
CREATE OR REPLACE PROCEDURE "IO_COM_INT_REPORT" 
(
 recievedID IN NUMBER,
 senderID IN NUMBER,
 fromDate IN NUMBER,
 toDate IN NUMBER,
 RCT1 OUT GLOBALPKG.RCT1
)
AS 
BEGIN
open RCT1 for
    
   SELECT distinct dep.departmentid,dep.departmentname,intr.correspondencenumber 
    FROM io_departments DEP , IO_INTERNAL intr, IO_INTERNALDESTINATIONS des

   where 
          (INTR.SENTBYDEPARTMENTID=senderid OR senderid=-1) -- sender
          and des.departmentid=recievedid --- reciever
          and intr.correspondencenumber= des.correspondencenumber
          and intr.correspondencedate between fromdate and todate
          and intr.hijricyear= des.hijricyear
          and dep.departmentid= intr.sentbydepartmentid 
          order by dep.departmentid, intr.correspondencenumber;
  
END IO_COM_INT_REPORT;
/
/

-- CHANGED PROCEDURE: IO_ADDDEADLINEFORWARDING
CREATE OR REPLACE PROCEDURE "IO_ADDDEADLINEFORWARDING" 
(
forwardingId OUT INT,
correspondenceNumber IN INT,
hijricYear IN INT,
typeId IN INT,
toUsers IN VARCHAR2,
deadlineUser IN VARCHAR2,
forwardingTime IN VARCHAR2
)
AS
BEGIN 

--1: Insert Main Record...
INSERT INTO io_forwardingshistory
(CORRESPONDENCENUMBER,
HIJRICYEAR,
TYPEID,
URGENCYLEVEL,
IMPORTANCELEVEL,
REMINDER,
DEADLINE,
FORWARDINGTIME,
INSTRUCTIONS)
VALUES
(IO_AddDeadlineForwarding.correspondenceNumber,
IO_AddDeadlineForwarding.hijricYear,
IO_AddDeadlineForwarding.typeId,
0,
0,
null,
'1',
IO_AddDeadlineForwarding.forwardingTime,
IO_AddDeadlineForwarding.deadlineUser);

IO_AddDeadlineForwarding.forwardingId := GLOBALPKG.IDENTITY;

--2: Insert "From" Details Record...
INSERT INTO io_forwardingdetails 
(FORWARDINGID,
FORWARDINGTYPE,
PARTICIPANTUSERID,
PARTICIPANTDEPTID,
PARTICIPANTTYPE) 
VALUES 
(IO_AddDeadlineForwarding.forwardingId,
1,
'fntadmin',
GETUSERDEPARTMENTID('fntadmin'),
1);

--3: Insert "To" Details Record...
INSERT INTO io_forwardingdetails 
(FORWARDINGID,
FORWARDINGTYPE,
PARTICIPANTUSERID,
PARTICIPANTDEPTID,
PARTICIPANTTYPE) 
VALUES 
(IO_AddDeadlineForwarding.forwardingId,
2,
IO_AddDeadlineForwarding.toUsers,
GETUSERDEPARTMENTID(IO_AddDeadlineForwarding.toUsers),
1);

END;
/
/

-- CHANGED PROCEDURE: ARCHIVE_INCOMING_SEARCH2_NONCONFIDENTIAL
CREATE OR REPLACE PROCEDURE "ARCHIVE_INCOMING_SEARCH2_NONCONFIDENTIAL" (

    RCT            OUT GLOBALPKG.RCT1,

    p_count        OUT NUMBER,
    p_sort_by      VARCHAR2,
    p_sort_asc_dsc VARCHAR2,
    p_rows_from   NUMBER,
    p_rows_to     NUMBER,
    
    P_CORR_NO IN NUMBER,
    P_CORR_YEAR IN NUMBER,
    P_BACTH_NO IN VARCHAR2,
    P_CORR_SUBJECT IN VARCHAR2,
    P_USERNAME IN VARCHAR2
)

AS
BEGIN

open RCT for 'select t.* from ( select a.*, ROWNUM rnum from  (

  SELECT AC.*, 
  E.FULLNAME,
  CASE  WHEN AI.CORRESPONDENCE_NO IS NOT NULL THEN AI.CORRESPONDENCE_SUBJECT WHEN ACM.CORRESPONDENCE_NO IS NOT NULL THEN ACM.SUBJECT else C.CORRESPONDENCESUBJECT END AS CORRESPONDENCE_SUBJECT,
  CASE  WHEN AI.CORRESPONDENCE_NO IS NOT NULL THEN AI.CORRESPONDENCE_CATEGORY WHEN ACM.CORRESPONDENCE_NO IS NOT NULL THEN ACMC.correspondencecategorydesc  END as correspondencecategorydesc,
  CASE  WHEN AI.CORRESPONDENCE_NO IS NOT NULL THEN AI.FULLNAME  WHEN ACM.CORRESPONDENCE_NO IS NOT NULL THEN ACM.FULLNAME else PENSIONER_INFO.FULLNAME END as PENSIONER_NAME,
  count(*) over(partition by 1) count,
   BATCH_LOCATION.LOCATION,
   BATCH_LOCATION.INITIAL_ENTRY_DATE,
   BATCH_LOCATION.EDIT_TIME,
   BATCH_LOCATION.EDITOR_NAME

  FROM ARCHIVE_INCOMING AC
  INNER JOIN IO_EMPLOYEES E ON E.userid = AC.USER_ID
  LEFT JOIN IO_INCOMING C ON AC.CORRESPONDENCE_NO = C.CORRESPONDENCENUMBER AND AC.HIJRIC_YEAR = C.HIJRICYEAR
  LEFT JOIN ARCHIVE_INCOMING_PENSION_INTEG AI ON AC.CORRESPONDENCE_NO = AI.CORRESPONDENCE_NO AND AC.HIJRIC_YEAR = AI.HIJRIC_YEAR
  LEFT JOIN io_correspondencecategories on io_correspondencecategories.CORRESPONDENCECATEGORYID = C.CORRESPONDENCECATEGORYID
  LEFT JOIN ARCHIVE_INCOMING_PENSION_COMM ACM ON AC.CORRESPONDENCE_NO = ACM.CORRESPONDENCE_NO AND AC.HIJRIC_YEAR = ACM.HIJRIC_YEAR
  LEFT JOIN io_correspondencecategories ACMC on ACMC.CORRESPONDENCECATEGORYID = ACM.CATEGORY_ID
  LEFT JOIN PENSIONER_INFO on PENSIONER_INFO.CORRESPONDENCE_NO = C.CORRESPONDENCENUMBER AND PENSIONER_INFO.HIJRIC_YEAR = C.HIJRICYEAR AND PENSIONER_INFO.CORRESPONDENCE_TYPE = 1
  LEFT JOIN BATCH_LOCATION on BATCH_LOCATION.BATCH_NO = AC.BATCH_NO
    where
    ('||P_CORR_NO||' = 0 OR AC.CORRESPONDENCE_NO = '''|| P_CORR_NO ||''') AND
    ('||P_CORR_YEAR||' = 0 OR AC.HIJRIC_YEAR = '''|| P_CORR_YEAR ||''') AND
    ('''||P_BACTH_NO||''' is null OR AC.BATCH_NO = '''|| P_BACTH_NO ||''') AND
    ('''||P_CORR_SUBJECT||''' is null OR C.CORRESPONDENCESUBJECT = '''|| P_CORR_SUBJECT ||''' OR AI.CORRESPONDENCE_SUBJECT = '''|| P_CORR_SUBJECT ||''' OR ACM.SUBJECT = '''|| P_CORR_SUBJECT ||''') AND
    ('''||P_USERNAME||''' is null OR BATCH_LOCATION.EDITOR_NAME LIKE ''%'||P_USERNAME||'%'') AND
    C.CONFIDENTIALITYID = 0

    ORDER BY '||P_SORT_BY||' '||P_SORT_ASC_DSC||') a

  where ROWNUM <= '||p_rows_to||' )t

where rnum  >=  '||p_rows_from;

END "ARCHIVE_INCOMING_SEARCH2_NONCONFIDENTIAL";
/
/

-- CHANGED PROCEDURE: ARCHIVE_INCOMING_SEARCH2
CREATE OR REPLACE PROCEDURE "ARCHIVE_INCOMING_SEARCH2" (

    RCT            OUT GLOBALPKG.RCT1,

    p_count        OUT NUMBER,
    p_sort_by      VARCHAR2,
    p_sort_asc_dsc VARCHAR2,
    p_rows_from   NUMBER,
    p_rows_to     NUMBER,
    
    P_CORR_NO IN NUMBER,
    P_CORR_YEAR IN NUMBER,
    P_BACTH_NO IN VARCHAR2,
    P_CORR_SUBJECT IN VARCHAR2,
    P_USERNAME IN VARCHAR2
)

AS
BEGIN

open RCT for 'select t.* from ( select a.*, ROWNUM rnum from  (

  SELECT AC.*, 
  E.FULLNAME,
  CASE  WHEN AI.CORRESPONDENCE_NO IS NOT NULL THEN AI.CORRESPONDENCE_SUBJECT WHEN ACM.CORRESPONDENCE_NO IS NOT NULL THEN ACM.SUBJECT else C.CORRESPONDENCESUBJECT END AS CORRESPONDENCE_SUBJECT,
  CASE  WHEN AI.CORRESPONDENCE_NO IS NOT NULL THEN AI.CORRESPONDENCE_CATEGORY WHEN ACM.CORRESPONDENCE_NO IS NOT NULL THEN ACMC.correspondencecategorydesc  END as correspondencecategorydesc,
  CASE  WHEN AI.CORRESPONDENCE_NO IS NOT NULL THEN AI.FULLNAME  WHEN ACM.CORRESPONDENCE_NO IS NOT NULL THEN ACM.FULLNAME else PENSIONER_INFO.FULLNAME END as PENSIONER_NAME,
  count(*) over(partition by 1) count,
   BATCH_LOCATION.LOCATION,
   BATCH_LOCATION.INITIAL_ENTRY_DATE,
   BATCH_LOCATION.EDIT_TIME,
   BATCH_LOCATION.EDITOR_NAME

  FROM ARCHIVE_INCOMING AC
  INNER JOIN IO_EMPLOYEES E ON E.userid = AC.USER_ID
  LEFT JOIN IO_INCOMING C ON AC.CORRESPONDENCE_NO = C.CORRESPONDENCENUMBER AND AC.HIJRIC_YEAR = C.HIJRICYEAR
  LEFT JOIN ARCHIVE_INCOMING_PENSION_INTEG AI ON AC.CORRESPONDENCE_NO = AI.CORRESPONDENCE_NO AND AC.HIJRIC_YEAR = AI.HIJRIC_YEAR
  LEFT JOIN io_correspondencecategories on io_correspondencecategories.CORRESPONDENCECATEGORYID = C.CORRESPONDENCECATEGORYID
  LEFT JOIN ARCHIVE_INCOMING_PENSION_COMM ACM ON AC.CORRESPONDENCE_NO = ACM.CORRESPONDENCE_NO AND AC.HIJRIC_YEAR = ACM.HIJRIC_YEAR
  LEFT JOIN io_correspondencecategories ACMC on ACMC.CORRESPONDENCECATEGORYID = ACM.CATEGORY_ID
  LEFT JOIN PENSIONER_INFO on PENSIONER_INFO.CORRESPONDENCE_NO = C.CORRESPONDENCENUMBER AND PENSIONER_INFO.HIJRIC_YEAR = C.HIJRICYEAR AND PENSIONER_INFO.CORRESPONDENCE_TYPE = 1
  LEFT JOIN BATCH_LOCATION on BATCH_LOCATION.BATCH_NO = AC.BATCH_NO
    where
    ('||P_CORR_NO||' = 0 OR AC.CORRESPONDENCE_NO = '''|| P_CORR_NO ||''') AND
    ('||P_CORR_YEAR||' = 0 OR AC.HIJRIC_YEAR = '''|| P_CORR_YEAR ||''') AND
    ('''||P_BACTH_NO||''' is null OR AC.BATCH_NO = '''|| P_BACTH_NO ||''') AND
    ('''||P_CORR_SUBJECT||''' is null OR C.CORRESPONDENCESUBJECT = '''|| P_CORR_SUBJECT ||''' OR AI.CORRESPONDENCE_SUBJECT = '''|| P_CORR_SUBJECT ||''' OR ACM.SUBJECT = '''|| P_CORR_SUBJECT ||''') AND
    ('''||P_USERNAME||''' is null OR BATCH_LOCATION.EDITOR_NAME LIKE ''%'||P_USERNAME||'%'') AND
    C.CONFIDENTIALITYID > 0

    ORDER BY '||P_SORT_BY||' '||P_SORT_ASC_DSC||') a

  where ROWNUM <= '||p_rows_to||' )t

where rnum  >=  '||p_rows_from;

END;
/
/

-- CHANGED PROCEDURE: ARCHIVE_INCOMING_INBOX_CONFIDENTIAL
CREATE OR REPLACE PROCEDURE "ARCHIVE_INCOMING_INBOX_CONFIDENTIAL" (

    RCT            OUT GLOBALPKG.RCT1,

    p_count        OUT NUMBER,
    p_sort_by      VARCHAR2,
    p_sort_asc_dsc VARCHAR2,
    p_rows_from   NUMBER,
    p_rows_to     NUMBER,
    p_correspondence_date NUMBER,  
    p_search_txt VARCHAR2
)

AS
BEGIN

open rct for 'select t.* from ( select a.*, ROWNUM rnum from  (

  SELECT IO_INCOMING.*, io_correspondencecategories.correspondencecategorydesc, io_departments.DEPARTMENTNAME,PENSIONER_INFO.FULLNAME as PENSIONER_NAME,
  count(*) over(partition by 1) count

  FROM IO_INCOMING
  LEFT JOIN ARCHIVE_INCOMING ON IO_INCOMING.CORRESPONDENCENUMBER = ARCHIVE_INCOMING.CORRESPONDENCE_NO AND IO_INCOMING.HIJRICYEAR = ARCHIVE_INCOMING.HIJRIC_YEAR
  LEFT JOIN io_correspondencecategories on io_correspondencecategories.CORRESPONDENCECATEGORYID = IO_INCOMING.CORRESPONDENCECATEGORYID
  LEFT JOIN io_departments on io_departments.DEPARTMENTID = IO_INCOMING.RECEIVEDBYDEPARTMENTID
  LEFT JOIN PENSIONER_INFO on PENSIONER_INFO.CORRESPONDENCE_NO = IO_INCOMING.CORRESPONDENCENUMBER AND PENSIONER_INFO.HIJRIC_YEAR = IO_INCOMING.HIJRICYEAR AND PENSIONER_INFO.CORRESPONDENCE_TYPE = 1
    WHERE 
    ARCHIVE_INCOMING.CORRESPONDENCE_NO IS NULL AND IO_INCOMING.CORRESPONDENCEDATE >='''||p_correspondence_date||''' AND IO_INCOMING.WF_LAUNCHED = 1 AND CONFIDENTIALITYID != 0
    AND ('''||p_search_txt||''' is null OR IO_INCOMING.CORRESPONDENCENUMBER like ''%'|| p_search_txt ||'%'')

    ORDER BY '||p_sort_by||' '||p_sort_asc_dsc||') a

  where ROWNUM <= '||p_rows_to||' )t

where rnum  >=  '||p_rows_from; 

END "ARCHIVE_INCOMING_INBOX_CONFIDENTIAL";
/
/

-- CHANGED PROCEDURE: ARCHIVE_INCOMING_INBOX
CREATE OR REPLACE PROCEDURE "ARCHIVE_INCOMING_INBOX" (

    RCT            OUT GLOBALPKG.RCT1,

    p_count        OUT NUMBER,
    p_sort_by      VARCHAR2,
    p_sort_asc_dsc VARCHAR2,
    p_rows_from   NUMBER,
    p_rows_to     NUMBER,
    p_correspondence_date NUMBER,  
    p_search_txt VARCHAR2
)

AS
BEGIN

open rct for 'select t.* from ( select a.*, ROWNUM rnum from  (

  SELECT IO_INCOMING.*, io_correspondencecategories.correspondencecategorydesc, io_departments.DEPARTMENTNAME,PENSIONER_INFO.FULLNAME as PENSIONER_NAME,
  count(*) over(partition by 1) count

  FROM IO_INCOMING
  LEFT JOIN ARCHIVE_INCOMING ON IO_INCOMING.CORRESPONDENCENUMBER = ARCHIVE_INCOMING.CORRESPONDENCE_NO AND IO_INCOMING.HIJRICYEAR = ARCHIVE_INCOMING.HIJRIC_YEAR
  LEFT JOIN io_correspondencecategories on io_correspondencecategories.CORRESPONDENCECATEGORYID = IO_INCOMING.CORRESPONDENCECATEGORYID
  LEFT JOIN io_departments on io_departments.DEPARTMENTID = IO_INCOMING.RECEIVEDBYDEPARTMENTID
  LEFT JOIN PENSIONER_INFO on PENSIONER_INFO.CORRESPONDENCE_NO = IO_INCOMING.CORRESPONDENCENUMBER AND PENSIONER_INFO.HIJRIC_YEAR = IO_INCOMING.HIJRICYEAR AND PENSIONER_INFO.CORRESPONDENCE_TYPE = 1
    WHERE 
    ARCHIVE_INCOMING.CORRESPONDENCE_NO IS NULL AND IO_INCOMING.CORRESPONDENCEDATE >='''||p_correspondence_date||''' AND IO_INCOMING.WF_LAUNCHED = 1 AND CONFIDENTIALITYID = 0
    AND ('''||p_search_txt||''' is null OR IO_INCOMING.CORRESPONDENCENUMBER like ''%'|| p_search_txt ||'%'')

    ORDER BY '||p_sort_by||' '||p_sort_asc_dsc||') a

  where ROWNUM <= '||p_rows_to||' )t

where rnum  >=  '||p_rows_from; 

END "ARCHIVE_INCOMING_INBOX";
/
/

-- CHANGED PROCEDURE: ADMIN_UPDATEEMPLOYEE
CREATE OR REPLACE PROCEDURE "ADMIN_UPDATEEMPLOYEE" 
(
pNationalNumber IN INT,
pFullName IN VARCHAR2 DEFAULT NULL,
pUserId IN VARCHAR2 DEFAULT NULL,
pDepartmentId IN INT DEFAULT NULL,
pJobTitle IN VARCHAR2 DEFAULT NULL,
pPhoneNo IN VARCHAR2 DEFAULT NULL,
pBackupId IN INT DEFAULT -1,
pBackupStartDate IN INT,
pBackupEndDate IN INT,
pEnabledOptionsMask IN INT DEFAULT 0,
pEmployeeId IN INT,
pIsActive IN INT DEFAULT 1,
pForwardingToList IN INT DEFAULT 1,
pOldNationalNumber IN INT,
pResult OUT INT
)
AS
BEGIN
      pResult := 1;
      
      UPDATE IO_EMPLOYEES SET NATIONALNUMBER = pNationalNumber,
        FULLNAME = pFullName, 
        USERID = pUserId, 
        JOBTITLE = pJobTitle,
        PHONENO = pPhoneNo,
        ISACTIVE = pIsActive
      WHERE EMPLOYEEID = pOldNationalNumber;
      
      UPDATE IO_EMPLOYEESCONFIGS SET ENABLEDOPTIONSMASK = pEnabledOptionsMask,
      FORWARDINGTOLIST = pForwardingToList
      WHERE EMPLOYEEID = pNationalNumber;
        
      DELETE FROM IO_EMPLOYEEBACKUP WHERE EMPLOYEEID = pNationalNumber;
      
      IF pBackupId > -1 THEN
          INSERT INTO IO_EMPLOYEEBACKUP(EMPLOYEEID, BACKUPID, STARTDATE, ENDDATE) 
            VALUES(pNationalNumber, pBackupId, pBackupStartDate, pBackupEndDate);      
      END IF;
        
      COMMIT;
      
EXCEPTION
  WHEN OTHERS THEN
    pResult := SQLCODE;
    ROLLBACK;
END;
/
/

-- CHANGED PROCEDURE: ADMIN_UPDATEDEPARTMENT
CREATE OR REPLACE PROCEDURE "ADMIN_UPDATEDEPARTMENT" 
(
  pDepartmentCode IN VARCHAR2,
  pDepartmentName IN VARCHAR2,
	pManagerId IN INT,
	pRepresentativeId IN INT,
  pParentDepartmentId IN INT,
  pDepartmentLevel IN INT,
  pCanAccessSystem IN INT,
  pEnabledOptionsMask IN INT DEFAULT 0,
  pDepartmentId IN INT,
  pIsActive IN INT DEFAULT 1,
  pSectorId INT,
  pResult OUT INT
)
AS
BEGIN
      pResult := 1;
      
      UPDATE IO_DEPARTMENTS SET DEPARTMENTCODE = pDepartmentCode,
        DEPARTMENTNAME = pDepartmentName,
        MANAGERID = pManagerId, 
        REPRESENTATIVEID = pRepresentativeId, 
        PARENTDEPARTMENTID = pParentDepartmentId,
        DEPARTMENTLEVEL = pDepartmentLevel,
        --CANACCESSSYSTEM = pCanAccessSystem,
        CANACCESSSYSTEM = pIsActive,
        ISACTIVE = pIsActive,
        SECTOR_ID = pSectorId
        
      WHERE DEPARTMENTID = pDepartmentId;
      
      UPDATE IO_DEPARTMENTSCONFIGS SET ENABLEDOPTIONSMASK = pEnabledOptionsMask 
      WHERE DEPARTMENTID = pDepartmentId;
             
      COMMIT;
      
EXCEPTION
  WHEN OTHERS THEN
    pResult := SQLCODE;
    ROLLBACK;
END;
/
/

-- CHANGED PROCEDURE: ADMIN_GETREGIONMEMBERS
CREATE OR REPLACE PROCEDURE "ADMIN_GETREGIONMEMBERS" 
( 
  pRegionId INT,
  RCT1 OUT GLOBALPKG.RCT1
)
AS
BEGIN
  OPEN RCT1 FOR 
  SELECT r.*, nvl(e.externalunitdesc, d.departmentname) MEMBERNAME
  FROM IO_REGIONMEMBERS r LEFT OUTER JOIN
  IO_EXTERNALUNITS e ON r.MEMBERID = e.EXTERNALUNITID AND r.MEMBERTYPE = 1 LEFT OUTER JOIN
  IO_DEPARTMENTS d ON r.MEMBERID = d.DEPARTMENTID AND r.MEMBERTYPE = 2
  WHERE regionId = pRegionId;
END;
/
/

-- CHANGED PROCEDURE: ADMIN_GETPARTICIPANTS
CREATE OR REPLACE PROCEDURE "ADMIN_GETPARTICIPANTS" 
(
  pEmployeeId IN INT,
  RCT1 IN OUT GLOBALPKG.RCT1
)
AS
BEGIN

OPEN RCT1 FOR
SELECT
IO_ELIGIBLEFORWARDINGTOLIST.PRITICIPANTTYPE,
IO_EMPLOYEES.EMPLOYEEID,
IO_EMPLOYEES.FULLNAME,
IO_EMPLOYEES.USERID,
D.DEPARTMENTID AS DEPARTMENTID,
D.DEPARTMENTNAME AS DEPARTMENTNAME,
Q.DEPARTMENTID AS QDEPARTMENTID,
Q.DEPARTMENTNAME AS QDEPARTMENTNAME,
IO_DEPARTMENTQUEUES.QUEUENAME

FROM IO_ELIGIBLEFORWARDINGTOLIST LEFT OUTER JOIN
IO_EMPLOYEES ON IO_ELIGIBLEFORWARDINGTOLIST.PARTICIPANTID = IO_EMPLOYEES.EMPLOYEEID
AND IO_ELIGIBLEFORWARDINGTOLIST.PRITICIPANTTYPE = 1 LEFT OUTER JOIN
IO_DEPARTMENTS D ON IO_ELIGIBLEFORWARDINGTOLIST.PARTICIPANTID = D.DEPARTMENTID
AND IO_ELIGIBLEFORWARDINGTOLIST.PRITICIPANTTYPE = 2 LEFT OUTER JOIN
IO_DEPARTMENTS Q ON IO_ELIGIBLEFORWARDINGTOLIST.PARTICIPANTID = Q.DEPARTMENTID
AND IO_ELIGIBLEFORWARDINGTOLIST.PRITICIPANTTYPE = 3 LEFT OUTER JOIN
IO_DEPARTMENTQUEUES ON Q.DEPARTMENTID = IO_DEPARTMENTQUEUES.DEPARTMENTID

WHERE (IO_ELIGIBLEFORWARDINGTOLIST.EMPLOYEEID = pEmployeeId);

END;
/
/

-- CHANGED PROCEDURE: ADMIN_GETEMPLOYEES
CREATE OR REPLACE PROCEDURE "ADMIN_GETEMPLOYEES" 
(
  DOMAIN_ID IN VARCHAR2 DEFAULT NULL,
  EMP_NO IN INT DEFAULT NULL,
  DEPARTMENT_CODE IN INT DEFAULT -1,
  RCT1 IN OUT GLOBALPKG.RCT1
)
AS
BEGIN 
OPEN RCT1 FOR
SELECT
ROWNUM AS ROWNO,
IO_EMPLOYEES.EMPLOYEEID,
IO_EMPLOYEES.NATIONALNUMBER,
IO_EMPLOYEES.FULLNAME,
IO_EMPLOYEES.USERID,
IO_EMPLOYEES.DEPARTMENTID,
IO_DEPARTMENTS.DEPARTMENTNAME,
IO_EMPLOYEES.JOBTITLE,
IO_EMPLOYEES.ISACTIVE,
IO_EMPLOYEES.EMAIL,
BACKUPEMP.EMPLOYEEID AS BACKUPID,
BACKUPEMP.USERID AS BACKUPUSERID,
IO_EMPLOYEEBACKUP.STARTDATE,
IO_EMPLOYEEBACKUP.ENDDATE,
IO_EMPLOYEESCONFIGS.ENABLEDOPTIONSMASK,
IO_EMPLOYEESCONFIGS.FORWARDINGTOLIST,
IO_DEPARTMENTS.EBS_DEPARTMENT_ID,
IO_EMPLOYEES.PHONENO

FROM IO_EMPLOYEES INNER JOIN IO_EMPLOYEESCONFIGS ON IO_EMPLOYEES.EMPLOYEEID = IO_EMPLOYEESCONFIGS.EMPLOYEEID
INNER JOIN IO_DEPARTMENTS ON IO_EMPLOYEES.DEPARTMENTID = IO_DEPARTMENTS.DEPARTMENTID
LEFT JOIN io_employeebackup ON IO_EMPLOYEES.EMPLOYEEID = io_employeebackup.EMPLOYEEID
LEFT JOIN IO_EMPLOYEES backupemp ON io_employeebackup.backupid = backupemp.EMPLOYEEID

WHERE (IO_EMPLOYEES.USERID IS NOT NULL)
AND (ADMIN_GETEMPLOYEES.DOMAIN_ID IS NULL OR LOWER(IO_EMPLOYEES.USERID) = LOWER(ADMIN_GETEMPLOYEES.DOMAIN_ID))
AND (ADMIN_GETEMPLOYEES.EMP_NO IS NULL OR LOWER(IO_EMPLOYEES.EMPLOYEEID) = LOWER(ADMIN_GETEMPLOYEES.EMP_NO))
AND (ADMIN_GETEMPLOYEES.DEPARTMENT_CODE = -1 OR IO_EMPLOYEES.DEPARTMENTID = ADMIN_GETEMPLOYEES.DEPARTMENT_CODE)
ORDER BY FULLNAME;
END;
/
/

-- CHANGED PROCEDURE: ADMIN_GETDEPARTMENTS
CREATE OR REPLACE PROCEDURE "ADMIN_GETDEPARTMENTS" 
(
  DEPARTMENT_ID IN INT DEFAULT -1,
  RCT1 IN OUT GLOBALPKG.RCT1
)
AS
BEGIN 

OPEN RCT1 FOR
SELECT
IO_DEPARTMENTS.DEPARTMENTID,
IO_DEPARTMENTS.DEPARTMENTNAME,
IO_DEPARTMENTS.DEPARTMENTCODE,
IO_DEPARTMENTS.MANAGERID,
MANAGER.FULLNAME MANAGER_FULL_NAME_AR,
IO_DEPARTMENTS.REPRESENTATIVEID,
repDep.FULLNAME REP_FULL_NAME,
IO_DEPARTMENTS.PARENTDEPARTMENTID,
IO_DEPARTMENTSCONFIGS.ENABLEDOPTIONSMASK,
IO_DEPARTMENTS.DEPARTMENTLEVEL,
IO_DEPARTMENTS.ISACTIVE,
IO_DEPARTMENTS.SECTOR_ID

FROM IO_DEPARTMENTS INNER JOIN IO_EMPLOYEES MANAGER ON IO_DEPARTMENTS.MANAGERID = MANAGER.EMPLOYEEID
                    INNER JOIN IO_DEPARTMENTSCONFIGS ON IO_DEPARTMENTS.DEPARTMENTID = IO_DEPARTMENTSCONFIGS.DEPARTMENTID
                    INNER JOIN IO_EMPLOYEES repDep ON IO_DEPARTMENTS.REPRESENTATIVEID = repDep.EMPLOYEEID
where (admin_getdepartments.department_id = - 1 or io_departments.parentdepartmentid = admin_getdepartments.department_id and io_departments.parentdepartmentid <>io_departments.departmentid )

order by departmentname;

END;
/
/

-- CHANGED PROCEDURE: ADMIN_FILTEREMPLOYEES
CREATE OR REPLACE PROCEDURE "ADMIN_FILTEREMPLOYEES" 
(
  pUsername IN VARCHAR2 DEFAULT NULL,
  pName IN VARCHAR2 DEFAULT NULL,
  RCT1 IN OUT GLOBALPKG.RCT1
)
AS
BEGIN 
OPEN RCT1 FOR
SELECT
ROWNUM AS ROWNO,
IO_EMPLOYEES.EMPLOYEEID,
IO_EMPLOYEES.NATIONALNUMBER,
IO_EMPLOYEES.FULLNAME,
IO_EMPLOYEES.USERID,
IO_EMPLOYEES.DEPARTMENTID,
IO_DEPARTMENTS.DEPARTMENTNAME,
IO_EMPLOYEES.JOBTITLE,
IO_EMPLOYEES.ISACTIVE,
BACKUPEMP.EMPLOYEEID AS BACKUPID,
BACKUPEMP.USERID AS BACKUPUSERID,
IO_EMPLOYEEBACKUP.STARTDATE,
IO_EMPLOYEEBACKUP.ENDDATE,
IO_EMPLOYEESCONFIGS.ENABLEDOPTIONSMASK,
IO_EMPLOYEESCONFIGS.FORWARDINGTOLIST,
IO_EMPLOYEES.PHONENO

FROM IO_EMPLOYEES INNER JOIN IO_EMPLOYEESCONFIGS ON IO_EMPLOYEES.EMPLOYEEID = IO_EMPLOYEESCONFIGS.EMPLOYEEID
INNER JOIN IO_DEPARTMENTS ON IO_EMPLOYEES.DEPARTMENTID = IO_DEPARTMENTS.DEPARTMENTID
LEFT JOIN io_employeebackup ON IO_EMPLOYEES.EMPLOYEEID = io_employeebackup.EMPLOYEEID
LEFT JOIN IO_EMPLOYEES backupemp ON io_employeebackup.backupid = backupemp.EMPLOYEEID

WHERE (pUsername is NULL OR IO_EMPLOYEES.USERID = pUsername)
AND (pName IS NULL OR IO_EMPLOYEES.FULLNAME LIKE '%' || pName || '%')
ORDER BY FULLNAME;
END;
/
/

-- CHANGED PROCEDURE: ADMIN_ADDEMPLOYEE
CREATE OR REPLACE PROCEDURE "ADMIN_ADDEMPLOYEE" 
(
pEmployeeId IN INT,
pNationalNumber IN INT,
pFullName IN VARCHAR2 DEFAULT NULL,
pUserId IN VARCHAR2 DEFAULT NULL,
pDepartmentId IN INT DEFAULT NULL,
pJobTitle IN VARCHAR2 DEFAULT NULL,
pPhoneNo IN VARCHAR2 DEFAULT NULL,
pBackupId IN INT DEFAULT -1,
pBackupStartDate IN INT,
pBackupEndDate IN INT,
pEnabledOptionsMask IN INT DEFAULT 0,
pIsActive IN INT DEFAULT 1,
pForwardingToList IN INT DEFAULT 1,
pResult OUT INT
)
AS
BEGIN
      pResult := 1;
      
      INSERT INTO IO_EMPLOYEES (EMPLOYEEID, NATIONALNUMBER, FULLNAME, USERID, DEPARTMENTID, JOBTITLE, ISACTIVE, PHONENO) 
        VALUES(pEmployeeId, pNationalNumber, pFullName, pUserId, -1, pJobTitle, pIsActive, pPhoneNo);
      INSERT INTO IO_EMPLOYEESCONFIGS (EMPLOYEEID, ENABLEDOPTIONSMASK, FORWARDINGTOLIST) 
        VALUES(pEmployeeId, pEnabledOptionsMask, pForwardingToList);
        
      IF pBackupId > -1 THEN
          INSERT INTO IO_EMPLOYEEBACKUP(EMPLOYEEID, BACKUPID, STARTDATE, ENDDATE) 
            VALUES(pEmployeeId, pBackupId, pBackupStartDate, pBackupEndDate);      
      END IF;
        
      COMMIT;
      
EXCEPTION
  WHEN OTHERS THEN
    pResult := SQLCODE;
    ROLLBACK;
END;
/
/

-- CHANGED FUNCTION: GETUSERDEPARTMENTID
CREATE OR REPLACE FUNCTION "GETUSERDEPARTMENTID" 
(p_userId IN VARCHAR2)
 RETURN NUMBER
 AS
 deptid NUMBER;
BEGIN

    BEGIN
      deptid := -1;
      SELECT departmentid INTO deptid FROM io_employees WHERE lower(userid) = lower(p_userId) AND ROWNUM = 1;
      EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;
    
    BEGIN
      SELECT departmentid INTO deptid FROM io_departmentqueues WHERE lower(queuename) = lower(p_userId) AND ROWNUM = 1;
      EXCEPTION WHEN NO_DATA_FOUND THEN NULL;
    END;
    
    RETURN deptid;
  
END;
/
/
