@AbapCatalog.sqlViewName: 'Z863VQUSAG'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Quality Portal Usage View'
@Metadata.ignorePropagatedAnnotations: true
define view Z863_C_QUSAGE as select from qave // Usage Decision Table
{
  key prueflos        as InspectionLotNo,      // Inspection Lot Number
      kzart           as InspectionLotType,    // Usage Decision Type
      vkatart         as UsageCatalog,         // Catalog Type
      vwerks          as Plant,                // Plant
      vauswahlmg      as SelectedSet,          // Selected Set
      vcodegrp        as CodeGroup,            // Code Group
      vcode           as UsageDecisionCode,    // Usage Decision Code
      qkennzahl       as QualityScore,         // Quality Score
      vname           as DecisionBy,           // Decision Made By
      vdatum          as DecisionDate,         // Date of Decision
      vezeiterf       as DecisionTime,         // Time of Decision
      vfolgeakti      as FollowUpAction,       // Follow-Up Action
      vbewertung      as CodeValuation         // Valuation Result
}

