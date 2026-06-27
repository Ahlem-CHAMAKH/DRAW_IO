-- ==================================================================
--  [07b] CHANGED PROCEDURES/FUNCTIONS — NEW OPTIONAL PARAMS  (1)
--  New params have DEFAULT values — existing callers are not affected
--  Target schema : MOAMALAT
--  Run as        : DBA or MOAMALAT user
-- ==================================================================

-- ℹ️  These procedures have new parameters added in REVAMP.
--    All new params have a DEFAULT value (OPTIONAL).
--    Existing callers that don't pass the new param will continue
--    to work — Oracle uses the DEFAULT automatically.
--    Safe to run without updating callers.

-- ──────────────────────────────────────────────────────────────────
-- ✅  PROCEDURE: IO_ADDFORWARDINGDETAIL
--    New OPTIONAL params (safe — has DEFAULT):
--      + DELEGATEUSERID
--      + DELEGATIONTYPE
--      + ISDELEGATED
CREATE OR REPLACE PROCEDURE "IO_ADDFORWARDINGDETAIL" 
(
    forwardingDetailId   OUT INT,
    forwardingHistoryId  IN  INT,
    forwardingType       IN  INT,
    participantUserId    IN  VARCHAR2,
    participantDeptId    IN  INT,
    participantType      IN  INT,
    -- NEW
    isDelegated          IN  INT     DEFAULT 0,
    delegationType       IN  VARCHAR2 DEFAULT NULL,
    delegateUserId       IN  VARCHAR2 DEFAULT NULL
)
AS
BEGIN
    INSERT INTO io_forwardingdetails
    (
        FORWARDINGID,
        FORWARDINGTYPE,
        PARTICIPANTUSERID,
        PARTICIPANTDEPTID,
        PARTICIPANTTYPE,
        IS_DELEGATED,
        DELEGATION_TYPE,
        DELEGATE_USERID
    )
    VALUES
    (
        IO_AddForwardingDetail.forwardingHistoryId,
        IO_AddForwardingDetail.forwardingType,
        IO_AddForwardingDetail.participantUserId,
        IO_AddForwardingDetail.participantDeptId,
        IO_AddForwardingDetail.participantType,
        NVL(IO_AddForwardingDetail.isDelegated, 0),
        IO_AddForwardingDetail.delegationType,
        IO_AddForwardingDetail.delegateUserId
    );

    IO_AddForwardingDetail.forwardingDetailId := GLOBALPKG.IDENTITY;
END;
/
/
