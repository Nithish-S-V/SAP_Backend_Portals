@AbapCatalog.sqlViewName: 'Z863VQLOGIN'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Login Check View'
@Metadata.ignorePropagatedAnnotations: true
@OData.publish: true // Publish this view
define view Z863_C_QLOGIN
  as select from z863_t_qemp as login
{
    key login.employid     as EmpID,
        login.password     as Password
}
