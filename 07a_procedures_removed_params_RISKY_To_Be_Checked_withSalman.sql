-- ==================================================================
--  [07a] CHANGED PROCEDURES/FUNCTIONS — ⚠️  REMOVED PARAMETERS  (24)
--  Params exist in MOAMALAT but are REMOVED in REVAMP
--  Target schema : MOAMALAT
--  Run as        : DBA or MOAMALAT user
-- ==================================================================

-- ⚠️  CRITICAL — READ BEFORE RUNNING:
--
--   These procedures have parameters that were REMOVED in REVAMP.
--   If any application / caller passes these params BY NAME,
--   it will get ORA-06552 / PLS-00306 at runtime after you apply.
--
--   If called BY POSITION, arguments will silently misalign → wrong results.
--
--   MANDATORY STEPS before running this file:
--     1. Search application code for each procedure name below
--     2. Confirm how it is called (by name or by position)
--     3. Update all callers to stop passing the removed params
--     4. Only then run this file
--
--   Removed params are listed under each procedure for easy reference.

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: WS_SETINCOMINGLAUNCH
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CORRESPONDENCENUMBER  (NUMBER IN MANDATORY)
--      - HIJRICYEAR  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "WS_SETINCOMINGLAUNCH" 
(
CORRESPONDENCENUMBER IN INT,
HIJRICYEAR IN INT
)
AS
BEGIN

UPDATE MOAMALAT.io_incoming

SET IO_Incoming.WF_LAUNCHED = 1
WHERE (MOAMALAT.IO_Incoming.CORRESPONDENCENUMBER = WS_SETINCOMINGLAUNCH.CORRESPONDENCENUMBER)
  AND (MOAMALAT.IO_Incoming.HIJRICYEAR = WS_SETINCOMINGLAUNCH.HIJRICYEAR);

END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: WS_ADDRELATION
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CORRESPONDENCENUMBER  (NUMBER IN MANDATORY)
--      - CORRESPONDENCETYPE  (NUMBER IN MANDATORY)
--      - HIJRICYEAR  (NUMBER IN MANDATORY)
--      - RELATEDTOHIJRICYEAR  (NUMBER IN MANDATORY)
--      - RELATEDTONUMBER  (NUMBER IN MANDATORY)
--      - RELATEDTOTYPE  (NUMBER IN MANDATORY)
--      - RELATEDTYPEID  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "WS_ADDRELATION" 
(
correspondenceNumber IN INT,
hijricYear IN INT,
correspondenceType IN INT,
relatedToNumber IN INT,
relatedToHijricYear IN INT,
relatedToType IN INT,
relatedTypeId IN INT
)
AS
BEGIN 

INSERT INTO MOAMALAT.io_relations VALUES(WS_ADDRELATION.correspondenceNumber, WS_ADDRELATION.hijricYear, WS_ADDRELATION.correspondenceType, WS_ADDRELATION.relatedToNumber, WS_ADDRELATION.relatedToHijricYear, WS_ADDRELATION.relatedToType, WS_ADDRELATION.relatedTypeId,0);

END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: WS_ADDFORWARDINGSHISTORY
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CORRESPONDENCENUMBER  (NUMBER IN MANDATORY)
--      - DEADLINE  (VARCHAR2 IN MANDATORY)
--      - FORWARDINGID  (NUMBER OUT MANDATORY)
--      - FORWARDINGTIME  (VARCHAR2 IN MANDATORY)
--      - HIJRICYEAR  (NUMBER IN MANDATORY)
--      - IMPORTANCELEVEL  (NUMBER IN MANDATORY)
--      - INSTRUCTIONS  (VARCHAR2 IN MANDATORY)
--      - REMINDER  (VARCHAR2 IN MANDATORY)
--      - TYPEID  (NUMBER IN MANDATORY)
--      - URGENCYLEVEL  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "WS_ADDFORWARDINGSHISTORY" 
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
deadline IN VARCHAR2
)
AS
BEGIN 

INSERT INTO MOAMALAT.io_forwardingshistory 
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
(WS_ADDFORWARDINGSHISTORY.correspondenceNumber,
WS_ADDFORWARDINGSHISTORY.hijricYear,
WS_ADDFORWARDINGSHISTORY.typeId,
WS_ADDFORWARDINGSHISTORY.urgencylevel,
WS_ADDFORWARDINGSHISTORY.importancelevel,
WS_ADDFORWARDINGSHISTORY.reminder,
WS_ADDFORWARDINGSHISTORY.deadline,
WS_ADDFORWARDINGSHISTORY.forwardingTime,
WS_ADDFORWARDINGSHISTORY.instructions);

WS_ADDFORWARDINGSHISTORY.forwardingId := GLOBALPKG.IDENTITY;

END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: WS_ADDFORWARDINGDETAIL
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - FORWARDINGHISTORYID  (NUMBER IN MANDATORY)
--      - FORWARDINGTYPE  (NUMBER IN MANDATORY)
--      - PARTICIPANTDEPTID  (NUMBER IN MANDATORY)
--      - PARTICIPANTTYPE  (NUMBER IN MANDATORY)
--      - PARTICIPANTUSERID  (VARCHAR2 IN MANDATORY)
CREATE OR REPLACE PROCEDURE "WS_ADDFORWARDINGDETAIL" 
(
forwardingHistoryId IN INT,
forwardingType IN INT,
participantUserId IN VARCHAR2,
participantDeptId IN INT,
participantType IN INT
)
AS
BEGIN 

INSERT INTO MOAMALAT.io_forwardingdetails 
(FORWARDINGID,
FORWARDINGTYPE,
PARTICIPANTUSERID,
PARTICIPANTDEPTID,
PARTICIPANTTYPE) 
VALUES 
(WS_ADDFORWARDINGDETAIL.forwardingHistoryId,
WS_ADDFORWARDINGDETAIL.FORWARDINGTYPE,
WS_ADDFORWARDINGDETAIL.PARTICIPANTUSERID,
WS_ADDFORWARDINGDETAIL.PARTICIPANTDEPTID,
WS_ADDFORWARDINGDETAIL.PARTICIPANTTYPE); 

END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: MOF_UPDAT_DR
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - P_CARRIERID  (NUMBER IN MANDATORY)
--      - P_DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - P_DELIVERYREPORTSTYLE  (NUMBER IN MANDATORY)
--      - P_DELIVERYREPORTTYPE  (NUMBER IN MANDATORY)
--      - P_HANDDELIVERYPERSONNELID  (NUMBER IN MANDATORY)
--      - P_ISREPORTCLOSED  (NUMBER IN MANDATORY)
--      - P_MODECODE  (NUMBER IN MANDATORY)
--      - P_MODIFICATIONDATE  (NUMBER IN MANDATORY)
--      - P_MODIFIEDBY  (VARCHAR2 IN MANDATORY)
--      - P_POSTOFFICEID  (NUMBER IN MANDATORY)
--      - P_REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - P_REPORTNUMBER  (NUMBER IN MANDATORY)
--      - P_SHOWSECURESUBJECT  (NUMBER IN MANDATORY)
--      - P_WASPRINTED  (CHAR IN MANDATORY)
CREATE OR REPLACE PROCEDURE "MOF_UPDAT_DR" 
  (
    p_modificationDate        IN NUMBER,
    p_modeCode                IN NUMBER,
    p_handDeliveryPersonnelId IN NUMBER,
    p_postOfficeId            IN NUMBER,
    p_carrierId               IN NUMBER,
    p_modifiedBy              IN VARCHAR2,
    p_wasPrinted              IN CHAR,
    p_deliveryReportItems     IN VARCHAR2,
    p_reportNumber            IN NUMBER,
    p_reportHijriYear         IN NUMBER,
    p_DeliveryReportType      IN NUMBER,
    p_DeliveryReportStyle     IN NUMBER, 
    p_isReportClosed          IN NUMBER,
    p_showSecureSubject       IN Number
    )
AS
  v_resul NUMBER(10,0);
  SWV_err NUMBER(10,0) DEFAULT 0;
BEGIN
--insert into io_test values (p_reportNumber,p_deliveryReportItems);
  
  BEGIN
    UPDATE IO_DeliveryReports
    SET --RECEIVEMODEID         = p_modeCode,
      HANDDELIVERYPERSONNELID = p_handDeliveryPersonnelId,
      PostOfficeID            = p_postOfficeId,
      LastModifiedBy          = p_modifiedBy,
      DateModified            = p_modificationDate,
      WasPrinted              = p_wasPrinted,
      CourierID               = p_carrierId ,
      DeliveryReportTypeID    = p_DeliveryReportType,
      DELEVARYREPORTSTYLE     = p_DeliveryReportStyle,
      isReportClosed          = p_isReportClosed,
      showSecureSubject       = p_showSecureSubject
      
    WHERE DeliveryReportID    = p_reportNumber
    AND ReportHijricYear      = p_reportHijriYear;
  EXCEPTION
  WHEN OTHERS THEN
    SWV_err := SQLCODE;
    NULL;
  END;
  
  IF(SWV_err <> 0) THEN
    GOTO ERR_HANDLER;
  END IF;
     v_resul := MOF_deleteReportItems(p_reportNumber,p_reportHijriYear);
  IF p_deliveryReportItems IS NOT NULL THEN
     v_resul := MOF_addDeliveryReportItems(p_reportNumber,p_reportHijriYear,p_deliveryReportItems);
  END IF;
  COMMIT;
  << ERR_HANDLER >> DBMS_OUTPUT.PUT_LINE('Unexpected error occurred!');
    --ROLLBACK;
END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: MOF_UPDATE_INCOMING_DR
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CREATIONDATE  (NUMBER IN MANDATORY)
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - P_ISCREATORMINISTER  (NUMBER IN MANDATORY)
--      - P_SHOWSECURESUBJECT  (NUMBER IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTNUMBER  (NUMBER IN MANDATORY)
--      - REPORTSTYLE  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "MOF_UPDATE_INCOMING_DR" 
  (
    reportNumber        IN NUMBER,
    reportHijriYear     IN NUMBER,
    creationDate        IN NUMBER,
    deliveryReportItems IN VARCHAR2 ,
    reportStyle         IN NUMBER ,
    p_showSecureSubject IN NUMBER,
    p_IsCreatorMinister IN NUMBER )
AS
 SWV_err NUMBER(10,0) DEFAULT 0;
BEGIN
  
    
    UPDATE IO_INCOMING_DELIVERYREPORT
    SET DateCreated             = creationDate 
    , DELEVARYREPORTSTYLE = reportStyle
    ,showSecureSubject = p_showSecureSubject
    WHERE deliveryReportId      = MOF_UPDATE_INCOMING_DR.reportNumber AND
      reportHijricYear          = MOF_UPDATE_INCOMING_DR.reportHijriYear and 
      ISCREATORMINISTEREMPLOYEE = p_IsCreatorMinister ;
      
      DELETE
      FROM IO_INCOMING_DR_TITEMS
      WHERE ReportNumber   = MOF_UPDATE_INCOMING_DR.reportNumber
      AND ReportHijricYear = MOF_UPDATE_INCOMING_DR.reportHijriYear;
     SWV_err := mof_ADD_INCOMING_DR_TITEMS ( MOF_UPDATE_INCOMING_DR.reportNumber, MOF_UPDATE_INCOMING_DR.reportHijriYear,
                              MOF_UPDATE_INCOMING_DR.deliveryReportItems);
    COMMIT;
  END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_SETOUTGOINGORIGINALDEST
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - ATTACHMENTS  (VARCHAR2 IN MANDATORY)
--      - COMMENTS  (VARCHAR2 IN MANDATORY)
--      - CORRESPONDENCENUMBER  (NUMBER IN MANDATORY)
--      - EXTERNALUNITID  (NUMBER IN MANDATORY)
--      - HIJRICYEAR  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "IO_SETOUTGOINGORIGINALDEST" 
(
CORRESPONDENCENUMBER IN INT,
HIJRICYEAR IN INT,
EXTERNALUNITID IN INT,
COMMENTS IN VARCHAR2,
ATTACHMENTS IN VARCHAR2,
NATIONALADDRESS IN VARCHAR2
)
AS

RECEIVEMODEID INT;
UNITTYPEID INT;
LETTERTYPEID INT;

BEGIN 

--Unit Type: External
UNITTYPEID := 1;

--Letter Type: Original
LETTERTYPEID := 1;

--Default ReceiveMode
SELECT nvl(receivemodeid, 1)
INTO RECEIVEMODEID
FROM io_externalunits
left join io_regionmembers on externalunitid = memberid and membertype = 1
left join io_regions on io_regionmembers.regionid = io_regions.regionid
where externalunitid = IO_SETOUTGOINGORIGINALDEST.EXTERNALUNITID;

--Delete Old Original Destination if already exisiting...
DELETE FROM IO_OutgoingDestinations
WHERE (IO_OutgoingDestinations.CORRESPONDENCENUMBER = IO_SETOUTGOINGORIGINALDEST.CORRESPONDENCENUMBER)
  AND (IO_OutgoingDestinations.HIJRICYEAR = IO_SETOUTGOINGORIGINALDEST.HIJRICYEAR)
  AND (IO_OutgoingDestinations.LETTERTYPEID = 1);

--Insert New Original Destination...
INSERT INTO IO_OutgoingDestinations(CORRESPONDENCENUMBER, HIJRICYEAR, CORRESPONDENCEDESTINATIONID, RECEIVEMODEID, LETTERTYPEID, COMMENTS, UnitTypeId, ATTACHMENTS,NATIONALADDRESS)
VALUES(IO_SETOUTGOINGORIGINALDEST.CORRESPONDENCENUMBER, IO_SETOUTGOINGORIGINALDEST.HIJRICYEAR,
       IO_SETOUTGOINGORIGINALDEST.EXTERNALUNITID, IO_SETOUTGOINGORIGINALDEST.RECEIVEMODEID,
       IO_SETOUTGOINGORIGINALDEST.LETTERTYPEID, IO_SETOUTGOINGORIGINALDEST.COMMENTS, IO_SETOUTGOINGORIGINALDEST.UnitTypeId,
       IO_SETOUTGOINGORIGINALDEST.ATTACHMENTS, io_addoutgoingdestination.NATIONALADDRESS);

END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_EMP_PERFORMANCE2
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CROSCAT  (NUMBER IN MANDATORY)
--      - CROSTYPE  (NUMBER IN MANDATORY)
--      - DEPID  (NUMBER IN MANDATORY)
--      - FROMDATE  (NUMBER IN MANDATORY)
--      - IDS  (VARRAY IN MANDATORY)
--      - RCT1  (REF CURSOR OUT MANDATORY)
--      - STR  (VARCHAR2 OUT MANDATORY)
--      - TODATE  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "IO_EMP_PERFORMANCE2" 
(
  ids IN VARRAY_TYPE,
  crosType IN number,
  fromdate IN Number,
  todate IN Number,
  crosCat In Number,
  depID IN integer,
  RCT1 OUT GLOBALPKG.RCT1,
  str out varchar2
)
AS
sqlSta varchar2(5000):='';
BEGIN
    -- 
   sqlsta := 'select emp1.EMPLOYEEID,emp1.fullname,inc.correspondencenumber,fd.forwardingtype,rl.relationtypeid,vwu.f_userId
   
          from IO_EMPLOYEES emp1 inner join IO_DEPARTMENTS dep on emp1.departmentid=dep.departmentid
                and dep.departmentid ='||depID;
    
    sqlsta :=sqlsta|| 'and (' ;
      for i in ids.first..ids.last
      loop
           if i=ids.last then
              sqlSta := sqlSta||' emp1.EMPLOYEEID = '||ids(i)||' ) ';
           else
             sqlSta := sqlSta||' emp1.EMPLOYEEID='||ids(i)||' OR ';
           end if;
       end loop;
  
   sqlsta :=sqlsta|| 'left join ( IO_FORWARDINGDETAILS fd 
                      inner join IO_FORWARDINGSHISTORY fh on fd.forwardingid=fh.forwardingid inner join ';
                     
     case crosType
       when 1 THEN sqlSta := sqlSta ||  ' IO_INCOMING   inc ';
       when 3 then sqlSta := sqlSta ||  ' IO_INTERNAL   inc ';
       else  sqlSta := sqlSta ||  ' IO_OUTGOING     inc ';
       end case;                 
                     
       sqlSta := sqlSta ||' on inc.correspondencenumber=fh.correspondencenumber and inc.hijricyear=fh.hijricyear and fh.typeid='||crosType ||'and inc.correspondencedate between '||fromdate ||' and '||todate 
       || ' and ('|| crosCat ||'=-1 OR inc.correspondencecategoryid ='||crosCat ||' ) )on fd.participantuserid=emp1.userid ';
       
       sqlSta := sqlSta ||' left join IO_RELATIONS rl ON rl.correspondencenumber=inc.correspondencenumber 
                             and rl.hijricyear=inc.hijricyear and rl.typeid='||crosType|| 'and rl.relationtypeid=2 
                             left join (IO_TRACK_CORRESPONDENCES_VIEW tv 
                             INNER JOIN peuser.vwuser vwu ON tv.inboxbounduser = vwu.f_userId
                             INNER JOIN io_employees e on lower(e.userid) = lower(vwu.f_username))                            
                             on  tv.correspondencenumber = fh.correspondencenumber and e.departmentid='||depID||' and emp1.EMPLOYEEID=e.EMPLOYEEID and tv.hijricyear=inc.hijricyear and tv.correspondencetype='||crosType; 
      
        
    
    sqlSta := sqlSta ||'order by emp1.EMPLOYEEID,inc.correspondencenumber';
    str:=sqlsta;
      open RCT1 for sqlsta;   
      
END IO_EMP_PERFORMANCE2;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_EMP_PERFORMANCE
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CORRCLONEID  (NUMBER IN MANDATORY)
--      - CROSTYPE  (NUMBER IN MANDATORY)
--      - DEPID  (NUMBER IN MANDATORY)
--      - FROMDATE  (NUMBER IN MANDATORY)
--      - IDS  (VARRAY IN MANDATORY)
--      - RCT1  (REF CURSOR OUT MANDATORY)
--      - STR  (VARCHAR2 OUT MANDATORY)
--      - TODATE  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "IO_EMP_PERFORMANCE" 
(
  ids IN VARRAY_TYPE,
  crosType IN number,
  fromdate IN Number,
  todate IN Number,
  corrCloneId In Number,
  depID IN integer,
  RCT1 OUT GLOBALPKG.RCT1,
  str out varchar2
)
AS
sqlSta varchar2(5000):='';
BEGIN
   -- 
   sqlsta := 'select emp1.EMPLOYEEID,emp1.fullname,inc.correspondencenumber,fd.forwardingtype,rl.relationtypeid,vwu.f_userId
   
          from IO_EMPLOYEES emp1 ' ;
    
  
   sqlsta :=sqlsta|| ' left join ( IO_FORWARDINGDETAILS fd 
                      inner join IO_FORWARDINGSHISTORY fh on fd.forwardingid=fh.forwardingid inner join ';
                     
     case crosType
       when 1 THEN sqlSta := sqlSta ||  ' IO_INCOMING   inc ';
       when 3 then sqlSta := sqlSta ||  ' IO_INTERNAL   inc ';
       else  sqlSta := sqlSta ||  ' IO_OUTGOING     inc ';
       end case;                 
                     
       sqlSta := sqlSta ||' on inc.correspondencenumber=fh.correspondencenumber and inc.hijricyear=fh.hijricyear and fh.typeid='||crosType ||' and CAST(substr(fh.forwardingtime,7,4) || substr(fh.forwardingtime,4,2) || substr(fh.forwardingtime,1,2) AS NUMBER) between '||fromdate ||' and '||todate;
       
       IF crosType = 1 THEN sqlSta := sqlSta ||  ' and ('|| corrCloneId ||' = -1 or inc.clone_id='|| corrCloneId ||') '; END IF;
       
       sqlSta := sqlSta || ') on fd.participantuserid=emp1.userid ';
       
       sqlSta := sqlSta ||' left join IO_RELATIONS rl ON rl.correspondencenumber=inc.correspondencenumber 
                             and rl.hijricyear=inc.hijricyear and rl.typeid='||crosType|| ' and rl.relationtypeid=2 
                             left join (IO_TRACK_CORRESPONDENCES_VIEW tv 
                             INNER JOIN peuser.vwuser vwu ON tv.inboxbounduser = vwu.f_userId
                             INNER JOIN io_employees e on lower(e.userid) = lower(vwu.f_username))                            
                             on  tv.correspondencenumber = fh.correspondencenumber and  emp1.EMPLOYEEID=e.EMPLOYEEID and tv.hijricyear=inc.hijricyear and tv.correspondencetype='||crosType; 
      
        
         sqlsta :=sqlsta|| '  where  (' ;
      for i in ids.first..ids.last
      loop
           if i=ids.last then
              sqlSta := sqlSta||' emp1.EMPLOYEEID = '||ids(i)||' ) ';
           else
             sqlSta := sqlSta||'  emp1.EMPLOYEEID='||ids(i)||' OR ';
           end if;
       end loop;
    
    sqlSta := sqlSta ||' order by emp1.EMPLOYEEID,inc.correspondencenumber';
    str:=sqlsta;
      open RCT1 for sqlsta;   
      
      
END IO_EMP_PERFORMANCE;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_EMPREPORT
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CROSCAT  (NUMBER IN MANDATORY)
--      - CROSTYPE  (NUMBER IN MANDATORY)
--      - FROMDATE  (NUMBER IN MANDATORY)
--      - IDS  (VARRAY IN MANDATORY)
--      - RCT1  (REF CURSOR OUT MANDATORY)
--      - SQLSTR  (VARCHAR2 OUT MANDATORY)
--      - TASDEED  (NUMBER IN MANDATORY)
--      - TODATE  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "IO_EMPREPORT" 
(
  ids IN VARRAY_TYPE ,
  fromdate IN Number,
  todate IN Number,
  tasdeed IN number,
  croscat IN number,
  crosType IN number,
  sqlstr out VARCHAR2,
  RCT1 OUT GLOBALPKG.RCT1
)  

AS
sqlSta varchar2(5000):='';
BEGIN
 sqlSta:=' SELECT  EMP.EMPLOYEEID ,EMP.FULLNAME ,fd.forwardingtype,rl.relationtypeid,inc.correspondencenumber,inc.hijricyear  
          FROM IO_EMPLOYEES EMP inner join IO_FORWARDINGDETAILS fd on EMP.USERID= FD.PARTICIPANTUSERID and ( ';
      --// all send ids for departments
      for i in ids.first..ids.last
      loop
           if i=ids.last then
              sqlSta := sqlSta||' EMP.EMPLOYEEID = '||ids(i)||' ) ';
           else
             sqlSta := sqlSta||' EMP.EMPLOYEEID='||ids(i)||' OR ';
           end if;
       end loop;     
   --===================================================
    sqlSta := sqlSta|| 'inner join IO_FORWARDINGSHISTORY fh on fd.forwardingid=fh.forwardingid  inner join ' ;
     
      case crosType
       when 1 THEN sqlSta := sqlSta ||  ' IO_INCOMING   inc ';
       when 3 then sqlSta := sqlSta ||  ' IO_INTERNAL   inc ';
       else  sqlSta := sqlSta ||  ' IO_OUTGOING     inc ';
       end case;
       sqlSta := sqlSta || ' on inc.correspondencenumber = fh.correspondencenumber and inc.hijricyear = fh.hijricyear   and fh.typeid ='|| crostype;
       
       sqlSta := sqlSta || ' left join  IO_RELATIONS rl ON rl.correspondencenumber=inc.correspondencenumber 
                             and rl.hijricyear=inc.hijricyear and rl.typeid='||crostype ||'  and rl.relationtypeid=2 ';--2 mean tasdeed relation;
                             
        
       sqlSta := sqlSta || ' where inc.correspondencedate between '||fromdate ||' and '||todate ;
       
       if croscat <> -1 and croscat <> 1  then  -- -1 empty and 1 --  for mof DB
        sqlSta := sqlSta || ' and  inc.correspondencecategoryid ='||croscat ;
       end if;
     
     sqlSta := sqlSta || '  order by  EMP.EMPLOYEEID,inc.correspondencenumber,fd.forwardingtype' ;
     sqlstr:=sqlSta;
     
      open RCT1 for  sqlSta ;   
      
END IO_EMPREPORT;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_DEP_PERFOR_REPORT
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CROSCAT  (NUMBER IN MANDATORY)
--      - CROSTYPE  (NUMBER IN MANDATORY)
--      - FROMDATE  (NUMBER IN MANDATORY)
--      - IDS  (VARRAY IN MANDATORY)
--      - RCT1  (REF CURSOR OUT MANDATORY)
--      - SQLSTR  (VARCHAR2 OUT MANDATORY)
--      - TASDEED  (NUMBER IN MANDATORY)
--      - TODATE  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "IO_DEP_PERFOR_REPORT" 
(
  ids IN VARRAY_TYPE ,
  fromdate IN Number,
  todate IN Number,
  tasdeed IN number,
  croscat IN number,
  crosType IN number,
  sqlstr out VARCHAR2,
  RCT1 OUT GLOBALPKG.RCT1
)  

AS
sqlSta varchar2(2000):='';
BEGIN
 sqlSta:=' SELECT  dep.departmentid,dep.departmentname,fd.forwardingtype,rl.relationtypeid,inc.correspondencenumber,inc.hijricyear  
          FROM IO_DEPARTMENTS dep inner join IO_FORWARDINGDETAILS fd on dep.departmentid=fd.participantdeptid   and ( ';
      --// all send ids for departments
      for i in ids.first..ids.last
      loop
           if i=ids.last then
              sqlSta := sqlSta||'  dep.departmentid = '||ids(i)||' )  ';
           else
             sqlSta := sqlSta||'  dep.departmentid= '||ids(i)||' OR  ';
           end if;
       end loop;     
   --===================================================
    sqlSta := sqlSta|| 'inner join IO_FORWARDINGSHISTORY fh on fd.forwardingid=fh.forwardingid  inner join ' ;
     
      case crosType
       when 1 THEN sqlSta := sqlSta ||  ' IO_INCOMING     inc ';
       when 2 then sqlSta := sqlSta ||  ' IO_OUTGOING     inc ';
       else  sqlSta := sqlSta ||  ' IO_INTERNAL    inc ';
       end case;
       sqlSta := sqlSta || 'on inc.correspondencenumber = fh.correspondencenumber and inc.hijricyear = fh.hijricyear 
         and fh.typeid ='|| crostype;
       
       sqlSta := sqlSta || ' left join  IO_RELATIONS rl ON rl.correspondencenumber=inc.correspondencenumber 
                             and rl.hijricyear=inc.hijricyear and rl.typeid='||crostype ||'  and rl.relationtypeid=2';--2 mean tasdeed relation;
          
          sqlSta := sqlSta || ' where inc.correspondencedate between '||fromdate ||' and '||todate ;                   
       if croscat <> -1 and croscat <> 1  then  -- -1 empty and 1 --  for mof DB
        sqlSta := sqlSta || ' and  inc.correspondencecategoryid ='||croscat;
       end if;
     
     sqlSta := sqlSta || '  order by dep.departmentid,inc.correspondencenumber,fd.forwardingtype' ;
     sqlstr:=sqlSta;
     
      open RCT1 for  sqlSta ;   
END IO_DEP_PERFOR_REPORT;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_CREATIONREPORT_EMP2
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CROSCAT  (NUMBER IN MANDATORY)
--      - CROSTYPE  (NUMBER IN MANDATORY)
--      - DEPID  (NUMBER IN MANDATORY)
--      - FROMDATE  (NUMBER IN MANDATORY)
--      - IDS  (VARRAY IN MANDATORY)
--      - RCT1  (REF CURSOR OUT MANDATORY)
--      - SQLSTR  (VARCHAR2 OUT MANDATORY)
--      - TODATE  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "IO_CREATIONREPORT_EMP2" 
(
  depID IN NUMBER,
  crosType IN Number,
  fromDate in Number,
  toDate IN NUMBER,
  crosCat In number,
  RCT1 OUT GLOBALPKG.RCT1,
  sqlstr out varchar2,
  ids IN VARRAY_TYPE
)
AS
sqlSta varchar2(5000):='';
BEGIN

  sqlSta:=' select emp.employeeid,emp.fullname,inc.correspondencenumber
            from   IO_EMPLOYEES emp inner join IO_DEPARTMENTS dep on emp.departmentid=dep.departmentid
            and emp.isactive=1 and dep.departmentid='||depID;

 sqlsta :=sqlsta|| ' and (' ;
      for i in ids.first..ids.last
      loop
           if i=ids.last then
              sqlSta := sqlSta||' emp.EMPLOYEEID = '||ids(i)||' ) ';
           else
             sqlSta := sqlSta||' emp.EMPLOYEEID='||ids(i)||' OR ';
           end if;
       end loop;

  case crosType
       when 1 THEN sqlSta := sqlSta ||  ' left join IO_INCOMING   inc on emp.userid=inc.RECEIVEDBY ';
       when 3 then sqlSta := sqlSta ||  ' left join  IO_INTERNAL   inc on emp.userid=inc.sentby ';
       else  sqlSta := sqlSta ||  ' left join IO_OUTGOING inc on emp.userid=inc.sentby ';
  end case;
     
   sqlsta :=sqlsta||' and ( '||crosCat||'=-1  OR inc.correspondencecategoryid='||crosCat||' ) and inc.correspondencedate between '||fromDate ||' and '||toDate;
  sqlsta :=sqlsta||' order by emp.employeeid,inc.correspondencenumber'; 
 
  sqlstr:=sqlsta;
  open RCT1 for sqlSta;

END IO_CREATIONREPORT_EMP2;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_CREATIONREPORT_EMP
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CORRCLONEID  (NUMBER IN MANDATORY)
--      - CROSTYPE  (NUMBER IN MANDATORY)
--      - DEPID  (NUMBER IN MANDATORY)
--      - FROMDATE  (NUMBER IN MANDATORY)
--      - IDS  (VARRAY IN MANDATORY)
--      - RCT1  (REF CURSOR OUT MANDATORY)
--      - SQLSTR  (VARCHAR2 OUT MANDATORY)
--      - TODATE  (NUMBER IN MANDATORY)
CREATE OR REPLACE PROCEDURE "IO_CREATIONREPORT_EMP" 
(
  depID IN NUMBER,
  crosType IN Number,
  fromDate in Number,
  toDate IN NUMBER,
  corrCloneId In number,
  RCT1 OUT GLOBALPKG.RCT1,
  sqlstr out varchar2,
  ids IN VARRAY_TYPE
)
AS
sqlSta varchar2(5000):='';
BEGIN

  sqlSta:=' select emp.employeeid,emp.fullname,inc.correspondencenumber
            from   IO_EMPLOYEES emp ';

 

  case crosType
       when 1 THEN sqlSta := sqlSta ||  ' left join IO_INCOMING   inc on emp.userid=inc.RECEIVEDBY and ( ' || corrCloneId|| '=-1 or inc.clone_Id = ' || corrCloneId || ')';
       when 3 then sqlSta := sqlSta ||  ' left join  IO_INTERNAL   inc on emp.userid=inc.sentby ';
       else  sqlSta := sqlSta ||  ' left join IO_OUTGOING inc on emp.userid=inc.sentby ';
  end case;
     
   sqlsta :=sqlsta||' and inc.correspondencedate between '||fromDate ||' and '||toDate||' and inc.wf_launched = 1';
   
   sqlsta :=sqlsta|| ' where  (' ;
      for i in ids.first..ids.last
      loop
           if i=ids.last then
              sqlSta := sqlSta||' emp.EMPLOYEEID = '||ids(i)||' )  ';
           else
             sqlSta := sqlSta||' emp.EMPLOYEEID='||ids(i)||' OR ';
           end if;
       end loop;
       
  sqlsta :=sqlsta||' order by emp.employeeid,inc.correspondencenumber'; 
 
  sqlstr:=sqlsta;
  open RCT1 for sqlSta;

END IO_CREATIONREPORT_EMP;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  PROCEDURE: IO_ADDMULTIUSERINSTRUCTIONSMOBILE
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - DIRECTPROCEDURE  (VARCHAR2 IN MANDATORY)
--      - FORWARDING_HISTORY_ID  (NUMBER IN MANDATORY)
--      - INSTRUCTION_TEXT  (VARCHAR2 IN MANDATORY)
--      - OWNER_ID  (VARCHAR2 IN OPTIONAL)
--      - OWNER_TYPE  (NUMBER IN OPTIONAL)
CREATE OR REPLACE PROCEDURE "IO_ADDMULTIUSERINSTRUCTIONSMOBILE" (
    FORWARDING_HISTORY_ID IN NUMBER ,
    OWNER_TYPE            IN NUMBER DEFAULT -999 ,
    OWNER_ID              IN VARCHAR2 DEFAULT -999 ,
    INSTRUCTION_TEXT      IN VARCHAR2 ,
    DIRECTPROCEDURE IN VARCHAR2 
    )
AS
BEGIN
  INSERT
  INTO MOAMALAT.io_multi_user_instructions
    (
      forwarding_history_id,
      owner_type,
      owner_id,
      instruction_text,
      procedure
    )
    VALUES
    (
      IO_ADDMULTIUSERINSTRUCTIONSMOBILE.forwarding_history_id,
      IO_ADDMULTIUSERINSTRUCTIONSMOBILE.owner_type,
      IO_ADDMULTIUSERINSTRUCTIONSMOBILE.owner_id,
      IO_ADDMULTIUSERINSTRUCTIONSMOBILE.instruction_text,
      IO_ADDMULTIUSERINSTRUCTIONSMOBILE.DIRECTPROCEDURE
    );
END IO_ADDMULTIUSERINSTRUCTIONSMOBILE;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: MOF_UPDATEDELIVERYREPORT
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CARRIERID  (NUMBER IN MANDATORY)
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - HANDDELIVERYPERSONNELID  (NUMBER IN MANDATORY)
--      - ISREPORTCLOSED  (NUMBER IN MANDATORY)
--      - MODECODE  (NUMBER IN MANDATORY)
--      - MODIFICATIONDATE  (NUMBER IN MANDATORY)
--      - MODIFIEDBY  (VARCHAR2 IN MANDATORY)
--      - POSTOFFICEID  (NUMBER IN MANDATORY)
--      - P_SHOWSECURESUBJECT  (NUMBER IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTNUMBER  (NUMBER IN MANDATORY)
--      - REPORTSTYLE  (NUMBER IN MANDATORY)
--      - REPORTTYPEID  (NUMBER IN MANDATORY)
--      - WASPRINTED  (CHAR IN MANDATORY)
CREATE OR REPLACE FUNCTION "MOF_UPDATEDELIVERYREPORT" 
    (
      modificationDate        IN NUMBER,
      modeCode                IN NUMBER,
      handDeliveryPersonnelId IN NUMBER,
      postOfficeId            IN NUMBER,
      carrierId               IN NUMBER,

      modifiedBy              IN VARCHAR2,
      wasPrinted              IN CHAR,
      deliveryReportItems     IN VARCHAR2,
      reportNumber            IN NUMBER,
      reportHijriYear         IN NUMBER,
      
      REPORTTYPEID            IN NUMBER,
      REPORTSTYLE             IN NUMBER,
      isReportClosed          IN NUMBER,
      p_showSecureSubject     IN NUMBER
      )
    RETURN NUMBER
  AS
    v_resul NUMBER(10,0);
    SWV_err NUMBER(10,0) DEFAULT 0;
  BEGIN
    SWV_err := 0;
    BEGIN
      UPDATE IO_DeliveryReports
      SET RECEIVEMODEID         = MOF_UPDATEDELIVERYREPORT.modeCode,
        HANDDELIVERYPERSONNELID = MOF_UPDATEDELIVERYREPORT.handDeliveryPersonnelId,
        PostOfficeID            = MOF_UPDATEDELIVERYREPORT.postOfficeId,
        LastModifiedBy          = MOF_UPDATEDELIVERYREPORT.modifiedBy,
        DateModified            = MOF_UPDATEDELIVERYREPORT.modificationDate,
        WasPrinted              = MOF_UPDATEDELIVERYREPORT.wasPrinted,
        CourierID               = MOF_UPDATEDELIVERYREPORT.carrierId ,
        DELIVERYREPORTTYPEID    = MOF_UPDATEDELIVERYREPORT.REPORTTYPEID,
        DELEVARYREPORTSTYLE     = MOF_UPDATEDELIVERYREPORT.REPORTSTYLE ,
        isReportClosed          = MOF_UPDATEDELIVERYREPORT.isReportClosed,
        showSecureSubject       = p_showsecuresubject
      WHERE DeliveryReportID    = MOF_UPDATEDELIVERYREPORT.reportNumber
      AND ReportHijricYear      = MOF_UPDATEDELIVERYREPORT.reportHijriYear;
    EXCEPTION
    WHEN OTHERS THEN
      SWV_err := SQLCODE;
    END;
    IF(SWV_err <> 0) THEN
      GOTO ERR_HANDLER;
    END IF;
    v_resul   := MOF_deleteReportItems(MOF_UPDATEDELIVERYREPORT.reportNumber,MOF_UPDATEDELIVERYREPORT.reportHijriYear);
    IF(v_resul = -1) THEN
      GOTO ERR_HANDLER;
    END IF;
    IF deliveryReportItems IS NOT NULL THEN
      v_resul := MOF_addDeliveryReportItems(MOF_UPDATEDELIVERYREPORT.reportNumber,MOF_UPDATEDELIVERYREPORT.reportHijriYear,MOF_UPDATEDELIVERYREPORT.deliveryReportItems);
      IF(v_resul            = -1) THEN
        GOTO ERR_HANDLER;
      END IF;
    END IF;
    COMMIT;
    RETURN 1;
    << ERR_HANDLER >> DBMS_OUTPUT.PUT_LINE('Unexpected error occurred!');
    ROLLBACK;
    RETURN -1;
  END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: MOF_GETVALUES
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - V_LIST  (VARCHAR2 IN MANDATORY)
CREATE OR REPLACE FUNCTION "MOF_GETVALUES" (
      v_list IN VARCHAR2)
    RETURN VALUES_TABLE PIPELINED
  AS
    v_recor  NUMBER(10,0);
    v_colum  NUMBER(10,0);
    v_dashP  NUMBER(10,0);
    v_commP  NUMBER(10,0);
    v_recor2 VARCHAR2(2000);
    v_colum2 VARCHAR2(500);
    SWV_lis  VARCHAR2(8000);
    v_value VALUES_LIST := VALUES_LIST(NULL,NULL,NULL);
  BEGIN
    SWV_lis       := v_list;
    v_recor       := -1;
    v_colum       := -1;
    v_dashP       := INSTR(SWV_lis,'@',1);
    WHILE v_dashP >= 0 AND LENGTH(SWV_lis) > 0
    LOOP
      v_recor    := v_recor+1;
      v_colum    :=        -1;
      IF v_dashP  > 0 THEN
        v_recor2 := LTRIM(RTRIM(SUBSTR(SWV_lis,1,v_dashP -1)));
        SWV_lis  := SUBSTR(SWV_lis,                      -(LENGTH(SWV_lis) -v_dashP));
        v_dashP  := INSTR(SWV_lis,'@',1);
      ELSE
        v_recor2 := SWV_lis;
        SWV_lis  := '';
        v_dashP  := -1;
      END IF;
      v_commP       := INSTR(v_recor2,',',1);
      WHILE v_commP >= 0 AND LENGTH(v_recor2) > 0
      LOOP
        IF v_commP  > 0 THEN
          v_colum2 := LTRIM(RTRIM(SUBSTR(v_recor2,1,v_commP -1)));
          v_recor2 := SUBSTR(v_recor2,                      -(LENGTH(v_recor2) -v_commP));
          v_commP  := INSTR(v_recor2,',',1);
        ELSE
          v_colum2 := v_recor2;
          v_recor2 := '';
          v_commP  := -1;
        END IF;
        IF LENGTH(v_colum2) > 0 THEN
          v_colum          := v_colum+1;
          FOR RetRow                IN
          (SELECT v_recor,v_colum,v_colum2 FROM dual
          )
          LOOP
            v_value := VALUES_LIST(RetRow.v_recor,RetRow.v_colum,RetRow.v_colum2);
            PIPE ROW(v_value);
          END LOOP;
        END IF;
      END LOOP;
    END LOOP;
    RETURN;
  END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: MOF_ADD_INCOMING_DR_TITEMS
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTNUMBER  (NUMBER IN MANDATORY)
CREATE OR REPLACE FUNCTION "MOF_ADD_INCOMING_DR_TITEMS" 
    (
      reportNumber        IN NUMBER,
      reportHijriYear     IN NUMBER,
      deliveryReportItems IN VARCHAR2)
    RETURN NUMBER
  AS
    SWV_err NUMBER(10,0) DEFAULT 0;
  BEGIN
    INSERT INTO tt_VALUES
    SELECT recordI,
      columnI,
      value
    FROM TABLE(CAST(MOF_getValues(deliveryReportItems) AS VALUES_TABLE));
    

      INSERT INTO IO_INCOMING_DR_TITEMS
      SELECT reportNumber,
        reportHijriYear,
        correspondenceNumber.value ,
        CAST(correspondenceHijriYear.value AS          NUMBER),
        CAST(destinationId.value AS                    NUMBER),
        CAST(NULLIF(UNITTYPEID.value,'$') AS NUMBER)
      FROM
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 0
        ) correspondenceNumber,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 1
        ) correspondenceHijriYear,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 2
        ) destinationId,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 3
        ) UNITTYPEID
      WHERE correspondenceNumber.recordI  = correspondenceHijriYear.recordI
      AND correspondenceHijriYear.recordI = destinationId.recordI
      AND destinationId.recordI           = UNITTYPEID.recordI
     ;
return 1;
  END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: MOF_ADD_INCOMING_DR
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CREATIONDATE  (NUMBER IN MANDATORY)
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - P_ISCREATORMINISTER  (NUMBER IN MANDATORY)
--      - P_SHOWSECURESUBJECT  (NUMBER IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTSTYLE  (NUMBER IN MANDATORY)
CREATE OR REPLACE FUNCTION "MOF_ADD_INCOMING_DR" 
    (
    
      reportHijriYear         IN NUMBER,
      creationDate            IN NUMBER,
     
      deliveryReportItems     IN VARCHAR2 , 
      reportStyle             IN NUMBER ,
      p_showSecureSubject     IN NUMBER,
      p_IsCreatorMinister     IN NUMBER
      
      )
      
    RETURN NUMBER
  AS
    v_currV NUMBER(10,0);
    v_nextV NUMBER(10,0);
    v_resul NUMBER(10,0);
    SWV_err NUMBER(10,0) DEFAULT 0;
  BEGIN
    BEGIN
      SELECT MAX(deliveryReportId)
      INTO v_currV
      FROM IO_INCOMING_DELIVERYREPORT
      WHERE reportHijricYear = MOF_ADD_INCOMING_DR.reportHijriYear;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
    END;
    IF v_currV IS NOT NULL THEN
      v_nextV  := v_currV+1;
    ELSE
      v_nextV := 1;
    END IF;
    IF(SQLCODE <> 0) THEN
      GOTO ERR_HANDLER;
    END IF;
    SWV_err := 0;
    BEGIN
    
      INSERT
      INTO IO_INCOMING_DELIVERYREPORT
        (
          deliveryReportId,
          reportHijricYear,
          DateCreated,
         
          DELEVARYREPORTSTYLE,
          showSecureSubject,
          ISCREATORMINISTEREMPLOYEE
        )
        VALUES
        (
          v_nextV,
          MOF_ADD_INCOMING_DR.reportHijriYear,
          MOF_ADD_INCOMING_DR.creationDate,
         
          MOF_ADD_INCOMING_DR.reportStyle,
          p_showSecureSubject, 
          p_IsCreatorMinister
        );
        
    EXCEPTION
    WHEN OTHERS THEN
      SWV_err := SQLCODE;
    END;
    IF
      (
        SWV_err <> 0
      )
      THEN
      GOTO ERR_HANDLER;
    END IF;
    IF deliveryReportItems IS NOT NULL THEN
      v_resul              := mof_ADD_INCOMING_DR_TITEMS
      (
        v_nextV, MOF_ADD_INCOMING_DR.reportHijriYear, MOF_ADD_INCOMING_DR.deliveryReportItems
      )
      ;
      IF
        (
          v_resul = -1
        )
        THEN
        GOTO ERR_HANDLER;
      END IF;
    END IF;
    COMMIT;
    RETURN v_nextV;
    << ERR_HANDLER >> DBMS_OUTPUT.PUT_LINE
    (
      'Unexpected error occurred!' || SWV_err
    )
    ;
    ROLLBACK;
    RETURN -1;
  END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: MOF_ADDDELIVERYREPORTITEMS
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTNUMBER  (NUMBER IN MANDATORY)
CREATE OR REPLACE FUNCTION "MOF_ADDDELIVERYREPORTITEMS" 
    (
      reportNumber        IN NUMBER,
      reportHijriYear     IN NUMBER,
      deliveryReportItems IN VARCHAR2)
    RETURN NUMBER
  AS
    SWV_err NUMBER(10,0) DEFAULT 0;
  BEGIN
    INSERT INTO tt_VALUES
    SELECT recordI,
      columnI,
      value
    FROM TABLE(CAST(MOF_getValues(deliveryReportItems) AS VALUES_TABLE));
    
    SWV_err := 0;
    BEGIN
      INSERT INTO IO_DeliveryReportItems
      SELECT reportNumber,
        reportHijriYear,
        correspondenceNumber.value ,
        CAST(correspondenceHijriYear.value AS          NUMBER),
        CAST(destinationId.value AS                    NUMBER),
        CAST(wasDelivered.value AS                     CHAR(1)),
        CAST(NULLIF(notDeliveredActionId.value,'$') AS NUMBER),
        CAST(NULLIF(notDeliveredReasonId.value,'$') AS NUMBER),
        CAST(NULLIF(UNITTYPEID.value,'$') AS NUMBER)
      FROM
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 0
        ) correspondenceNumber,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 1
        ) correspondenceHijriYear,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 2
        ) destinationId,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 3
        ) wasDelivered,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 4
        ) notDeliveredReasonId,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 5
        ) notDeliveredActionId
        ,
        (SELECT value,recordI FROM tt_VALUES WHERE columnI = 6
        ) UNITTYPEID
      WHERE correspondenceNumber.recordI  = correspondenceHijriYear.recordI
      AND correspondenceHijriYear.recordI = destinationId.recordI
      AND destinationId.recordI           = wasDelivered.recordI
      AND wasDelivered.recordI            = notDeliveredReasonId.recordI
      AND notDeliveredReasonId.recordI    = notDeliveredActionId.recordI
      AND notDeliveredActionId.recordI              = UNITTYPEID.recordI
     ;
    EXCEPTION
    WHEN OTHERS THEN
      SWV_err := SQLCODE;
    END;
    IF(SWV_err <> 0) THEN
      GOTO ERR_HANDLER;
    END IF;
    DELETE FROM tt_VALUES;
    RETURN 1;
    << ERR_HANDLER >> DBMS_OUTPUT.PUT_LINE('Unexpected error occurred! ' || SWV_err);
    
    RETURN -1;
  END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: MOF_ADDDELIVERYREPORT
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CARRIERID  (NUMBER IN MANDATORY)
--      - CREATEDBY  (VARCHAR2 IN MANDATORY)
--      - CREATIONDATE  (NUMBER IN MANDATORY)
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - HANDDELIVERYPERSONNELID  (NUMBER IN MANDATORY)
--      - MODECODE  (NUMBER IN MANDATORY)
--      - MODIFICATIONDATE  (NUMBER IN MANDATORY)
--      - MODIFIEDBY  (VARCHAR2 IN MANDATORY)
--      - POSTOFFICEID  (NUMBER IN MANDATORY)
--      - P_ISCREATORMINISTER  (NUMBER IN MANDATORY)
--      - P_SHOWSECURESUBJECT  (NUMBER IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTSTYLE  (NUMBER IN MANDATORY)
--      - REPORTTYPE  (NUMBER IN MANDATORY)
--      - WASPRINTED  (CHAR IN MANDATORY)
CREATE OR REPLACE FUNCTION "MOF_ADDDELIVERYREPORT" 
    (
    
      reportHijriYear         IN NUMBER,
      creationDate            IN NUMBER,
      modificationDate        IN NUMBER,
      modeCode                IN NUMBER,
      handDeliveryPersonnelId IN NUMBER,
      
      postOfficeId            IN NUMBER,
      carrierId               IN NUMBER,
      createdBy               IN VARCHAR2,
      modifiedBy              IN VARCHAR2,
      wasPrinted              IN CHAR,
      
      deliveryReportItems     IN VARCHAR2 , 
      reportType              IN NUMBER , 
      reportStyle             IN NUMBER ,
      p_showSecureSubject     IN NUMBER,
      p_IsCreatorMinister     IN NUMBER
      
      )
      
    RETURN NUMBER
  AS
    v_currV NUMBER(10,0);
    v_nextV NUMBER(10,0);
    v_resul NUMBER(10,0);
    SWV_err NUMBER(10,0) DEFAULT 0;
  BEGIN
    BEGIN
      SELECT MAX(deliveryReportId)
      INTO v_currV
      FROM IO_DeliveryReports
      WHERE reportHijricYear = MOF_ADDDELIVERYREPORT.reportHijriYear;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
    END;
    IF v_currV IS NOT NULL THEN
      v_nextV  := v_currV+1;
    ELSE
      v_nextV := 1;
    END IF;
    IF(SQLCODE <> 0) THEN
      GOTO ERR_HANDLER;
    END IF;
    SWV_err := 0;
    BEGIN
    
      INSERT
      INTO IO_DELIVERYREPORTS
        (
          deliveryReportId,
          reportHijricYear,
          DateCreated,
          RECEIVEMODEID,
          HANDDELIVERYPERSONNELID,
          PostOfficeID,
          CreatedBy,
          LastModifiedBy,
          DateModified,
          WasPrinted,
          CourierID ,
          DELIVERYREPORTTYPEID,
          DELEVARYREPORTSTYLE,
          showSecureSubject,
          ISCREATORMINISTEREMPLOYEE
        )
        VALUES
        (
          v_nextV,
          MOF_ADDDELIVERYREPORT.reportHijriYear,
          MOF_ADDDELIVERYREPORT.creationDate,
          MOF_ADDDELIVERYREPORT.modeCode,
          MOF_ADDDELIVERYREPORT.handDeliveryPersonnelId,
          MOF_ADDDELIVERYREPORT.postOfficeId,
          MOF_ADDDELIVERYREPORT.createdBy   ,
          MOF_ADDDELIVERYREPORT.modifiedBy  ,
          MOF_ADDDELIVERYREPORT.modificationDate,
          MOF_ADDDELIVERYREPORT.wasPrinted ,
          MOF_ADDDELIVERYREPORT.carrierId  ,
          MOF_ADDDELIVERYREPORT.ReportType ,
          MOF_ADDDELIVERYREPORT.reportStyle,
          p_showSecureSubject, 
          p_IsCreatorMinister
        );
        
    EXCEPTION
    WHEN OTHERS THEN
      SWV_err := SQLCODE;
    END;
    IF
      (
        SWV_err <> 0
      )
      THEN
      GOTO ERR_HANDLER;
    END IF;
    IF deliveryReportItems IS NOT NULL THEN
      v_resul              := MOF_addDeliveryReportItems
      (
        v_nextV, MOF_ADDDELIVERYREPORT.reportHijriYear, MOF_ADDDELIVERYREPORT.deliveryReportItems
      )
      ;
      IF
        (
          v_resul = -1
        )
        THEN
        GOTO ERR_HANDLER;
      END IF;
    END IF;
    COMMIT;
    RETURN v_nextV;
    << ERR_HANDLER >> DBMS_OUTPUT.PUT_LINE
    (
      'Unexpected error occurred!' || SWV_err
    )
    ;
    ROLLBACK;
    RETURN -1;
  END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: DS_UPDATEDELIVERYREPORT
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CARRIERID  (NUMBER IN MANDATORY)
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - HANDDELIVERYPERSONNELID  (NUMBER IN MANDATORY)
--      - MODECODE  (NUMBER IN MANDATORY)
--      - MODIFICATIONDATE  (NUMBER IN MANDATORY)
--      - MODIFIEDBY  (VARCHAR2 IN MANDATORY)
--      - POSTOFFICEID  (NUMBER IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTNUMBER  (NUMBER IN MANDATORY)
--      - WASPRINTED  (CHAR IN MANDATORY)
CREATE OR REPLACE FUNCTION "DS_UPDATEDELIVERYREPORT" (modificationDate IN NUMBER, modeCode IN NUMBER, 
	handDeliveryPersonnelId IN NUMBER, postOfficeId IN NUMBER, carrierId IN NUMBER,
	modifiedBy IN VARCHAR2, wasPrinted IN CHAR,
	deliveryReportItems IN varchar2,
	reportNumber IN NUMBER, reportHijriYear IN NUMBER)
RETURN NUMBER
   AS
   v_resul  NUMBER(10,0);
   SWV_err NUMBER(10,0) DEFAULT 0;
BEGIN
   SWV_err := 0;
   begin
      UPDATE IO_DeliveryReports  SET RECEIVEMODEID = DS_updateDeliveryReport.modeCode,HANDDELIVERYPERSONNELID = DS_updateDeliveryReport.handDeliveryPersonnelId,PostOfficeID = DS_updateDeliveryReport.postOfficeId, 
      LastModifiedBy = DS_updateDeliveryReport.modifiedBy,DateModified = DS_updateDeliveryReport.modificationDate,WasPrinted = DS_updateDeliveryReport.wasPrinted,CourierID = DS_updateDeliveryReport.carrierId
      WHERE DeliveryReportID = DS_updateDeliveryReport.reportNumber AND ReportHijricYear = DS_updateDeliveryReport.reportHijriYear;
      EXCEPTION
      WHEN OTHERS THEN
         SWV_err := SQLCODE;
   end;
    	
   IF(SWV_err <> 0) then
      GOTO ERR_HANDLER;
   END IF;
   
   v_resul := DS_deleteReportItems(DS_updateDeliveryReport.reportNumber,DS_updateDeliveryReport.reportHijriYear);
   IF(v_resul = -1) then
      GOTO ERR_HANDLER;
   END IF;
   
   IF deliveryReportItems IS NOT NULL then
      v_resul := MOF_addDeliveryReportItems(DS_updateDeliveryReport.reportNumber,DS_updateDeliveryReport.reportHijriYear,DS_updateDeliveryReport.deliveryReportItems);
      IF(v_resul = -1) then
         GOTO ERR_HANDLER;
      END IF;
   END IF;
   
   COMMIT;
   RETURN 1;
   
   << ERR_HANDLER >>
   DBMS_OUTPUT.PUT_LINE('Unexpected error occurred!');
   ROLLBACK;
   RETURN -1;
END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: DS_GETVALUES
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - V_LIST  (VARCHAR2 IN MANDATORY)
CREATE OR REPLACE FUNCTION "DS_GETVALUES" (v_list IN varchar2)
RETURN VALUES_TABLE PIPELINED
   AS
   v_recor  NUMBER(10,0);
   v_colum  NUMBER(10,0);
   v_dashP  NUMBER(10,0);
   v_commP  NUMBER(10,0);
   v_recor2  VARCHAR2(2000);
   v_colum2  VARCHAR2(500);
   SWV_lis VARCHAR2(8000);
   v_value VALUES_LIST := VALUES_LIST(null,null,null);
BEGIN
   SWV_lis := v_list;
   v_recor := -1;
   v_colum := -1;
   v_dashP := INSTR(SWV_lis,'@',1);
   
   WHILE v_dashP >= 0 AND LENGTH(SWV_lis) > 0 LOOP
      v_recor := v_recor+1;
      v_colum := -1;
      IF v_dashP > 0 then
         v_recor2 := LTRIM(RTRIM(SUBSTR(SWV_lis,1,v_dashP -1)));
         SWV_lis := SUBSTR(SWV_lis,-(LENGTH(SWV_lis) -v_dashP));
         v_dashP := INSTR(SWV_lis,'@',1);
         
      ELSE
         v_recor2 := SWV_lis;
         SWV_lis := '';
         v_dashP := -1;
      END IF;
      v_commP := INSTR(v_recor2,',',1);
      WHILE v_commP >= 0 AND LENGTH(v_recor2) > 0 LOOP
         IF v_commP > 0 then
            v_colum2 := LTRIM(RTRIM(SUBSTR(v_recor2,1,v_commP -1)));
            v_recor2 := SUBSTR(v_recor2,-(LENGTH(v_recor2) -v_commP));
            v_commP := INSTR(v_recor2,',',1);
            
         ELSE
            v_colum2 := v_recor2;
            v_recor2 := '';
            v_commP := -1;
         END IF;
         IF LENGTH(v_colum2) > 0 then
            v_colum := v_colum+1;
            
            FOR RetRow IN(SELECT v_recor,v_colum,v_colum2  from dual) LOOP
               v_value := VALUES_LIST(RetRow.v_recor,RetRow.v_colum,RetRow.v_colum2);
               PIPE ROW(v_value);
            END LOOP;
         END IF;
      END LOOP;
   END LOOP;
   RETURN;
END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: DS_ADDDELIVERYREPORTITEMS
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - REPORTNUMBER  (NUMBER IN MANDATORY)
CREATE OR REPLACE FUNCTION "DS_ADDDELIVERYREPORTITEMS" (reportNumber IN NUMBER,
	reportHijriYear IN NUMBER,
	deliveryReportItems IN VARCHAR2)
RETURN NUMBER
   AS
   SWV_err NUMBER(10,0) DEFAULT 0;
BEGIN 
   INSERT
   INTO    tt_VALUES
   SELECT recordI,columnI,value FROM TABLE(CAST(DS_getValues(deliveryReportItems) AS VALUES_TABLE));
   SWV_err := 0;
   begin
      
      INSERT
      INTO	IO_DeliveryReportItems
      SELECT reportNumber, reportHijriYear,CAST(correspondenceNumber.value AS NUMBER),CAST(correspondenceHijriYear.value AS NUMBER), 
      CAST(destinationId.value AS NUMBER), 
      CAST(wasDelivered.value AS CHAR(1)), CAST(NULLIF(notDeliveredActionId.value,'$') AS NUMBER), 
      CAST(NULLIF(notDeliveredReasonId.value,'$') AS NUMBER),1
      FROM(SELECT value,recordI FROM tt_VALUES
         WHERE columnI = 0) correspondenceNumber,(SELECT value,recordI FROM tt_VALUES
         WHERE columnI = 1) correspondenceHijriYear,(SELECT value,recordI FROM tt_VALUES
         WHERE columnI = 2) destinationId,(SELECT value,recordI FROM tt_VALUES
         WHERE columnI = 3) wasDelivered,(SELECT value,recordI FROM tt_VALUES
         WHERE columnI = 4) notDeliveredReasonId,(SELECT value,recordI FROM tt_VALUES
         WHERE columnI = 5) notDeliveredActionId 
      WHERE correspondenceNumber.recordI = correspondenceHijriYear.recordI 
      and correspondenceHijriYear.recordI = destinationId.recordI 
      and destinationId.recordI = wasDelivered.recordI 
      and wasDelivered.recordI = notDeliveredReasonId.recordI 
      and notDeliveredReasonId.recordI = notDeliveredActionId.recordI;
      
      EXCEPTION
      WHEN OTHERS THEN
         SWV_err := SQLCODE;
   end;
   IF(SWV_err <> 0) then
      GOTO ERR_HANDLER;
   END IF;
   
   DELETE FROM tt_VALUES;
   
   RETURN 1;
   << ERR_HANDLER >>
   DBMS_OUTPUT.PUT_LINE('Unexpected error occurred! ' || SWV_err);
   RETURN -1;
END;
/
/

-- ──────────────────────────────────────────────────────────────────
-- ⚠️  FUNCTION: DS_ADDDELIVERYREPORT
--    Params REMOVED from REVAMP (callers must stop passing these):
--      - CARRIERID  (NUMBER IN MANDATORY)
--      - CREATEDBY  (VARCHAR2 IN MANDATORY)
--      - CREATIONDATE  (NUMBER IN MANDATORY)
--      - DELIVERYREPORTITEMS  (VARCHAR2 IN MANDATORY)
--      - HANDDELIVERYPERSONNELID  (NUMBER IN MANDATORY)
--      - MODECODE  (NUMBER IN MANDATORY)
--      - MODIFICATIONDATE  (NUMBER IN MANDATORY)
--      - MODIFIEDBY  (VARCHAR2 IN MANDATORY)
--      - POSTOFFICEID  (NUMBER IN MANDATORY)
--      - P_ISCREATORMINISTER  (NUMBER IN MANDATORY)
--      - REPORTHIJRIYEAR  (NUMBER IN MANDATORY)
--      - WASPRINTED  (CHAR IN MANDATORY)
CREATE OR REPLACE FUNCTION "DS_ADDDELIVERYREPORT" 
    (
      reportHijriYear         IN NUMBER,
      creationDate            IN NUMBER,
      modificationDate        IN NUMBER,
      modeCode                IN NUMBER,
      handDeliveryPersonnelId IN NUMBER,
      postOfficeId            IN NUMBER,
      carrierId               IN NUMBER,
      createdBy               IN VARCHAR2,
      modifiedBy              IN VARCHAR2,
      wasPrinted              IN CHAR,
      deliveryReportItems     IN VARCHAR2,
      p_IsCreatorMinister     IN NUMBER)
    RETURN NUMBER
  AS
    v_currV NUMBER(10,0);
    v_nextV NUMBER(10,0);
    v_resul NUMBER(10,0);
    SWV_err NUMBER(10,0) DEFAULT 0;
  BEGIN
    BEGIN
      SELECT MAX(deliveryReportId)
      INTO v_currV
      FROM IO_DeliveryReports
      WHERE reportHijricYear = DS_ADDDELIVERYREPORT.reportHijriYear;
    EXCEPTION
    WHEN NO_DATA_FOUND THEN
      NULL;
    END;
    IF v_currV IS NOT NULL THEN
      v_nextV  := v_currV+1;
    ELSE
      v_nextV := 1;
    END IF;
    IF(SQLCODE <> 0) THEN
      GOTO ERR_HANDLER;
    END IF;
    SWV_err := 0;
    BEGIN
      INSERT
      INTO IO_DeliveryReports
        (
          deliveryReportId,
          reportHijricYear,
          DateCreated,
          RECEIVEMODEID,
          HANDDELIVERYPERSONNELID,
          PostOfficeID,
          CreatedBy,
          LastModifiedBy,
          DateModified,
          WasPrinted,
          CourierID,
          ISCREATORMINISTEREMPLOYEE
        )
        VALUES
        (
          v_nextV,
          DS_ADDDELIVERYREPORT.reportHijriYear,
          DS_ADDDELIVERYREPORT.creationDate,
          DS_ADDDELIVERYREPORT.modeCode,
          DS_ADDDELIVERYREPORT.handDeliveryPersonnelId,
          DS_ADDDELIVERYREPORT.postOfficeId,
          DS_ADDDELIVERYREPORT.createdBy,
          DS_ADDDELIVERYREPORT.modifiedBy,
          DS_ADDDELIVERYREPORT.modificationDate,
          DS_ADDDELIVERYREPORT.wasPrinted,
          DS_ADDDELIVERYREPORT.carrierId,
          p_IsCreatorMinister
        );
    EXCEPTION
    WHEN OTHERS THEN
      SWV_err := SQLCODE;
    END;
    IF
      (
        SWV_err <> 0
      )
      THEN
      GOTO ERR_HANDLER;
    END IF;
    IF deliveryReportItems IS NOT NULL THEN
      v_resul              := DS_addDeliveryReportItems
      (
        v_nextV, DS_ADDDELIVERYREPORT.reportHijriYear, DS_ADDDELIVERYREPORT.deliveryReportItems
      )
      ;
      IF
        (
          v_resul = -1
        )
        THEN
        GOTO ERR_HANDLER;
      END IF;
    END IF;
    COMMIT;
    RETURN v_nextV;
    << ERR_HANDLER >> DBMS_OUTPUT.PUT_LINE
    (
      'Unexpected error occurred!' || SWV_err
    )
    ;
    ROLLBACK;
    RETURN -1;
  END;
/
/
