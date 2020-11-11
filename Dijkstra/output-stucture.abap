* ZROUSTE_T
  types: begin of output_s,
           number     type  int4,
           st_beg(6)  type  n,
           st_end(6)  type  n,
           length(16) type  p decimals 3,
         end of output_s.

* zstation_edges
  types: begin of zstation_edges_s,
           mandt          type	mandt,
           key_i          type	int4,
           station_beg(6) type n,
           station_end(6) type n,
           weight         type p length 16 decimals 3,
         end of zstation_edges_s.