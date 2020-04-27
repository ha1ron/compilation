*&---------------------------------------------------------------------*
*& Report Z92_WHERE_USED
*&---------------------------------------------------------------------*
*&
*&---------------------------------------------------------------------*
REPORT Z92_WHERE_USED.

types: begin of res_type_s,
         base_schema           type string,
         base_object_name      type string,
         base_object_type      type string,
         dependent_schema_name type string,
         dependent_object_name type string,
         dependent_object_type type string,
         lvl                   type i,
       end of res_type_s.

data: data_tab    type ref to data,
      sql         type string,
      result_tree type table of res_type_s,

      ref_tree    TYPE REF TO cl_column_tree_model.

parameters: object  type string lower case. "<-- table / model view

field-symbols: <tab> type any table.

start-of-selection.

  sql = |select BASE_SCHEMA_NAME, BASE_OBJECT_NAME, BASE_OBJECT_TYPE, DEPENDENT_SCHEMA_NAME, DEPENDENT_OBJECT_NAME, DEPENDENT_OBJECT_TYPE, '1'| &&
        | from "SYS"."OBJECT_DEPENDENCIES" where BASE_OBJECT_NAME = '{ object }' and | &&
        | DEPENDENT_SCHEMA_NAME = '_SYS_BIC' and DEPENDENT_OBJECT_NAME not like '%hier%' and DEPENDENCY_TYPE = '1'|.

  create data data_tab type table of res_type_s.
  zcl_sql_executor=>result( exporting i_query = sql changing c_data_table = data_tab ).
  assign data_tab->* to <tab>.

  append lines of <tab> to result_tree.

  perform cascade_search.
  perform normalize_tree.

  call screen 100.

  INCLUDE z92_where_used_init_treef01.
*&---------------------------------------------------------------------*
*&      Form  ADD_NODES
*&---------------------------------------------------------------------*
FORM ADD_NODES  USING P_REF_TREE TYPE REF TO cl_column_tree_model.

   data: tab_item type treemcitab,
        node_key type tm_nodekey.

  node_key = object.

  perform add_field using '2' 'BASE_OBJECT' object changing tab_item.

  p_ref_tree->add_node( exporting node_key       = node_key
                                  isfolder       = 'X'
                                  item_table     = tab_item ).

  perform next_node using p_ref_tree node_key.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  NEW_COL
*&---------------------------------------------------------------------*
form NEW_COL  using  p_name type TV_ITMNAME
                     p_width
                     p_text type TV_HEADING.

  ref_tree->add_column( exporting name        = p_name
                                  width       = p_width
                                  header_text = p_text ).
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  ADD_FIELD
*&---------------------------------------------------------------------*
form ADD_FIELD  using p_class p_name p_value changing p_tab_item type standard table.
  data: wa_item type treemcitem.

  wa_item-class = p_class.
  wa_item-item_name = p_name.

  if p_name = 'BASE_OBJECT' and p_value cs '@'.
    split p_value at '@' into wa_item-text data(trash).
  else.
    wa_item-text = p_value.
  endif.

  append wa_item to p_tab_item.
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  NEXT_NODE
*&---------------------------------------------------------------------*
form NEXT_NODE  using P_P_REF_TREE type ref to cl_column_tree_model
                      P_NODE_KEY.

  data: tab_item   type treemcitab,
        node_key   type tm_nodekey,
        parent_key type tm_nodekey,
        where      type string.

  where = |OBJ_NAME = '{ p_node_key }'|.
  loop at result_tree assigning field-symbol(<line>) where BASE_OBJECT_NAME = P_NODE_KEY.
    refresh tab_item.

    perform add_field using '2' 'LVL' <line>-LVL changing tab_item.

    perform add_field using '2' 'BASE_OBJECT' <line>-DEPENDENT_OBJECT_NAME changing tab_item.
    node_key = <line>-DEPENDENT_OBJECT_NAME.

    perform add_field using '2' 'BASE_SCHEMA'  <line>-DEPENDENT_SCHEMA_NAME changing tab_item.

    parent_key = <line>-BASE_OBJECT_NAME.

    perform add_field using '2' 'DEP_OBJ_TYPE'  <line>-dependent_object_type   changing tab_item.

    p_p_ref_tree->add_node( exporting node_key          = node_key
                                      relative_node_key = parent_key
                                      relationship      = cl_column_tree_model=>relat_last_child
                                      isfolder          = ' '
                                      item_table        = tab_item ).

    perform next_node using p_p_ref_tree node_key.

  endloop.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  NORMALIZE_TREE
*&---------------------------------------------------------------------*
FORM NORMALIZE_TREE .

  sort result_tree by base_object_name dependent_object_name.
  delete adjacent duplicates from result_tree comparing base_object_name dependent_object_name.

  sort result_tree by dependent_object_name.

* избавляемся от циклов
  data: previos_obj type string,
        recurrence  type i.
  loop at result_tree assigning field-symbol(<line>).
    if sy-tabix = 1.
      previos_obj = <line>-dependent_object_name.
      continue.
    endif.

    if <line>-dependent_object_name = previos_obj.
      <line>-dependent_object_name = <line>-dependent_object_name && '@' && recurrence.
      recurrence = recurrence + 1.
      continue.
    else.
      clear recurrence.
    endif.

    previos_obj = <line>-dependent_object_name.
  endloop.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  CASCADE_SEARCH
*&---------------------------------------------------------------------*
FORM CASCADE_SEARCH .

  data: objects_string type string,
        iterator       type i value 2.

  loop at result_tree into data(line).
    if sy-tabix = lines( result_tree ).

      refresh <tab>.
      sql = |select BASE_SCHEMA_NAME, BASE_OBJECT_NAME, BASE_OBJECT_TYPE, DEPENDENT_SCHEMA_NAME, DEPENDENT_OBJECT_NAME, DEPENDENT_OBJECT_TYPE, '{ iterator }'| &&
      | from "SYS"."OBJECT_DEPENDENCIES" where ({ objects_string }) and DEPENDENT_SCHEMA_NAME = '_SYS_BIC' and | &&
      | DEPENDENT_OBJECT_NAME not like '%hier%' and DEPENDENCY_TYPE = '1'|.
      zcl_sql_executor=>result( exporting i_query = sql changing c_data_table = data_tab ).
      append lines of <tab> to result_tree.
      clear objects_string.
      iterator = iterator + 1.
    else.
      if strlen( objects_string ) = 0.
        objects_string = |BASE_OBJECT_NAME = '{ line-dependent_object_name }' |.
      else.
        objects_string = |{ objects_string } or BASE_OBJECT_NAME = '{ line-dependent_object_name }' |.
      endif.
    endif.
  endloop.

ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  EXPAND_ALL_NODES
*&---------------------------------------------------------------------*
FORM EXPAND_ALL_NODES.
  data: key_table      type table of tm_nodekey.
  ref_tree->get_all_node_keys( importing node_key_table = key_table ).
  ref_tree->expand_nodes( exporting node_key_table = key_table ).
ENDFORM.
*&---------------------------------------------------------------------*
*&      Form  COLLAPSE_ALL_NODES
*&---------------------------------------------------------------------*
FORM COLLAPSE_ALL_NODES .
  ref_tree->COLLAPSE_ALL_NODES( ).
ENDFORM.