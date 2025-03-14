@AbapCatalog.sqlViewName: 'ZCDSPRICEL'
@AbapCatalog.compiler.compareFilter: true
@AbapCatalog.preserveKey: true
@AccessControl.authorizationCheck: #NOT_REQUIRED
@EndUserText.label: 'Listino Prezzi'
@OData.publish: true
define view ZDDLPRICELIST
  as select from    mara         as m
    inner join      mvke         as v   on  v.matnr = m.matnr
                                        and v.vkorg = '1000'
                                        and v.vtweg = '10'
                                        and v.lvorm = ''
    inner join      a004         as cl  on  cl.kappl = 'V'
                                        and cl.kschl = 'ZLIS'
                                        and cl.matnr = v.matnr
                                        and cl.vtweg = v.vtweg
                                        and cl.vkorg = v.vkorg
                                        and cl.datab <= $session.system_date
                                        and cl.datbi >= $session.system_date
    inner join      konp         as l   on  l.knumh    = cl.knumh
                                        and l.loevm_ko = ''
    inner join      marc         as s1  on  s1.matnr = m.matnr
                                        and s1.werks = 'S001'
                                        and s1.lvorm = ''
    inner join      marc         as s2  on  s2.matnr = m.matnr
                                        and s2.werks = 'S002'
                                        and s2.lvorm = ''
    inner join      marc         as s3  on  s3.matnr = m.matnr
                                        and s3.werks = 'S003'
                                        and s3.lvorm = ''
    left outer join eina         as i   on  i.matnr = m.matnr
                                        and i.loekz = ''
                                        and i.relif = 'X'
    left outer join makt         as md  on  md.matnr = m.matnr
                                        and md.spras = 'D'
    left outer join makt         as mi  on  mi.matnr = m.matnr
                                        and mi.spras = 'I'
    left outer join t179t        as gd  on  gd.prodh = m.prdha
                                        and gd.spras = 'D'
    left outer join t179t        as gi  on  gi.prodh = m.prdha
                                        and gi.spras = 'I'
    left outer join wrf_brands_t as bd  on  bd.brand_id = m.brand_id
                                        and bd.language = 'D'
    left outer join wrf_brands_t as bi  on  bi.brand_id = m.brand_id
                                        and bi.language = 'I'

    left outer join t006a        as umd on umd.spras      =  'D'
                                        and(
                                          (
                                            umd.msehi     =  v.vrkme
                                            and v.vrkme   != ' '
                                          )
                                          or(
                                            v.vrkme       =  ' '
                                            and umd.msehi =  m.meins
                                          )
                                        )

    left outer join t006a        as umi on umi.spras      =  'I'
                                        and(
                                          (
                                            umi.msehi     =  v.vrkme
                                            and v.vrkme   != ' '
                                          )
                                          or(
                                            v.vrkme       =  ' '
                                            and umi.msehi =  m.meins
                                          )
                                        )



{
  key  m.matnr        as PRODUCTNR,
       m.prdha,
       gd.vtext       as GROUP_DE,
       gi.vtext       as GROUP_IT,
       md.maktx       as NAME_DE,
       mi.maktx       as NAME_IT,
       i.idnlf        as VENDORNR,
       m.brand_id,
       bd.brand_descr as BRAND_DE,
       bi.brand_descr as BRAND_IT,
       umd.mseh3      as UOMSALE_DE,
       umi.mseh3      as UOMSALE_IT,
       case when v.aumng > 0 and v.vrkme != ''  then
           division(  l.kbetr, l.kpein ,2) * cast( unit_conversion( quantity => v.aumng, source_unit => v.vrkme, target_unit => l.kmein ,error_handling => 'SET_TO_NULL') as abap.dec( 5, 0 ) )
       when v.aumng > 0  then
       division(  l.kbetr, l.kpein,2 ) * cast( unit_conversion( quantity => v.aumng, source_unit => m.meins, target_unit => l.kmein ,error_handling => 'SET_TO_NULL') as abap.dec( 5, 0 ) )
       else
       div(  l.kbetr, l.kpein )
       end            as SELPRICE,
       cl.datab       as VALIDITY_S,
       cl.datbi       as VALIDITY_E,

       l.konwa        as KONWA,
       s1.mmsta       as CLASSBZ,
       s2.mmsta       as CLASSTN,
       s3.mmsta       as CLASSRO,
       m.ean11        as BARCODE,
       m.zzmarcamet   as MARCHIOMETEL,
       v.aumng


}
where
  m.lvorm = ' '
