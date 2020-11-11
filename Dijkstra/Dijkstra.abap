FUNCTION Z_DIJKSTRA.
*"----------------------------------------------------------------------
*"*"Локальный интерфейс:
*"  IMPORTING
*"     REFERENCE(START_NODE) TYPE  /BIC/OISTBEG
*"     REFERENCE(END_NODE) TYPE  /BIC/OISTBEG
*"  EXPORTING
*"     REFERENCE(OUTPUT) TYPE  ZROUSTE_T
*"  CHANGING
*"     REFERENCE(EDGES) TYPE  ZEDGES_T OPTIONAL
*"     REFERENCE(ITERATOR) TYPE  INT4 OPTIONAL
*"----------------------------------------------------------------------

  constants int_max type i value 2147483647.

  types: begin of path_s_t,
           name     type /bic/oistbeg,
           distance type /bic/oilengthm,
         end of path_s_t,
         path_s type standard table of path_s_t with non-unique default key,

         begin of node_s,
           name     type /bic/oistbeg,
           path     type path_s, " кратчайший путь до узла
           distance type /bic/oilengthm, "общее растояние до узла
         end of node_s.

  if edges is initial.
    select station_beg station_end weight
    from zstation_edges
    into table edges.
  endif.

  data: uncheckedNodes type sorted table of node_s with non-unique key primary_key components distance,
        checkedNodes   type sorted table of node_s with unique key primary_key components name,
        startNode      type node_s,
        newNode        type node_s.

  startNode-name = start_node.
  insert startNode into table uncheckedNodes.

  data lowestDistanceNode type node_s.

  while lines( uncheckedNodes ) > 0.
    clear: lowestDistanceNode.

*    возвращает узел с наименьшей дистанцией
    lowestDistanceNode = uncheckedNodes[ 1 ].
    delete table uncheckedNodes from lowestDistanceNode.

*    обходим все смежные узлы
    loop at edges assigning field-symbol(<edge>) where stbeg = lowestDistanceNode-name.

      clear newNode.
      if line_exists( checkedNodes[ name = <edge>-stend ] ).
        newNode = checkedNodes[ name = <edge>-stend ].
      else.
        newNode-name = <edge>-stend.
        newNode-distance = int_max.
      endif.

******************
* вычисление наименьшей дистанции до начального узла
      if lowestDistanceNode-distance + <edge>-lengthm < newnode-distance.
        newNode-distance = lowestDistanceNode-distance + <edge>-lengthm.
        data(lowPath) = lowestDistanceNode-path.
        append initial line to lowPath assigning field-symbol(<patch_line>).
        <patch_line>-name = lowestDistanceNode-name.
        <patch_line>-distance = <edge>-lengthm.
        newNode-path = lowPath.
      endif.
******************
*      если нашли путь до уже проверенного узла и он меньше
      if line_exists( checkedNodes[ name = newNode-name ] ).
        assign checkedNodes[ name = newNode-name ] to field-symbol(<choice_shortest>).
        if newNode-distance < <choice_shortest>-distance.
          delete table uncheckedNodes from <choice_shortest>.
          insert newNode into table checkedNodes.
        endif.
      else.
        insert newNode into table uncheckedNodes.
      endif.
****
    endloop.

    insert lowestDistanceNode into table checkedNodes.

  endwhile.
************************** конец расчета
  lowestDistanceNode = checkedNodes[ name = end_node ].

  check lines( lowestDistanceNode-path ) > 0.

  data: out_lines type zrouste_s.

  loop at lowestDistanceNode-path assigning field-symbol(<path>).

    if sy-tabix = 1.
      out_lines-st_beg = <path>-name.
      out_lines-length = <path>-distance.
    else.
      out_lines-st_end = <path>-name.
      out_lines-number = ITERATOR.
      append out_lines to output.

      iterator = iterator + 1.

      out_lines-st_beg = out_lines-st_end.
      out_lines-length = <path>-distance.
    endif.

  endloop.
  out_lines-number = iterator.
  out_lines-st_end = lowestdistancenode-name.
  out_lines-length = lowestdistancenode-path[ lines( lowestdistancenode-path ) ]-distance.
  append out_lines to output.

ENDFUNCTION.