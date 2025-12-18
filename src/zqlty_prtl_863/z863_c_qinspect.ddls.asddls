@AbapCatalog.sqlViewName: 'Z863VQINSPEC'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AbapCatalog.viewEnhancementCategory: [#NONE]
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Quality Portal Inspection View'
@Metadata.ignorePropagatedAnnotations: true
@OData.publish: true
define view Z863_C_QINSPECT
  as select from qals    // Inspection Lot Table
    left outer join qave      // Usage Decision Table
      on qals.prueflos = qave.prueflos
{
    key qals.prueflos     as InspectionLot,      // Inspection Lot Number
        qals.selmatnr     as MaterialNumber,     // Selected Material
        qals.werk         as Plant,              // Plant
        qals.art          as InspectionType,     // Inspection Type
        qals.enstehdat    as CreatedDate,        // Creation Date
        qals.pastrterm    as StartDate,          // Start of Inspection
        qals.paendterm    as EndDate,            // End of Inspection
        qals.losmenge     as LotQuantity,        // Lot Quantity
        qals.mengeneinh   as UoM,                // Unit of Measure
        qals.ktextmat     as MaterialDesc,       // Material Description
        qave.kzart        as UDType,             // Usage Decision Type
        // **IMPORTANT CHANGE HERE:**
        case
          when qave.vcode is null or qave.vcode = ''
          then 'PENDING'
          else qave.vcode
        end               as UsageDecisionCode   // Usage Decision Code
}
