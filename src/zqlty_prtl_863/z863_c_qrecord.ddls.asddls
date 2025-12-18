@AbapCatalog.sqlViewName: 'Z863VQRECRD'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Quality Portal Record View'
@Metadata.ignorePropagatedAnnotations: true
define view Z863_C_QRECORD as select from qamr // Inspection Results Characteristic
  inner join qals          // Inspection Lot
    on qamr.prueflos = qals.prueflos
{
  key qamr.prueflos    as InspectionLot,       // Inspection Lot Number
      qamr.vorglfnr    as OperationNo,         // Operation Number
      qamr.merknr      as CharacteristicNo,    // Characteristic Number
      qamr.mbewertg    as ResultCode,          // Result Code

      qals.werk        as Plant,               // Plant
      qals.art         as InspectionType,      // Inspection Type
      qals.objnr       as ObjectNumber,        // Object Number
      qals.obtyp       as ObjectType,          // Object Type
      qals.stat35      as Status,              // Status
      qals.selmatnr    as MaterialNumber       // Material Number
}
