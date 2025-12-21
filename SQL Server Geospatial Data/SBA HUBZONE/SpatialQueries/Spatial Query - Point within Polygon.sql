
-- Check for existence of a POINT (LAT, LONG) within a polygon/multipolygon

SELECT top 5 [gid]
      ,[tract_fips]
      ,[county]
      ,[state]
      ,[omb_delineation]
      ,[prior_status]
      ,[current_status]
      ,[status_change]
      ,[redesignated]
      ,[expires]
      ,[effective]
	  ,coordinates
      ,[AUD_FILENAME]
	  ,a.AUD_SEQ_ID
	  ,b.*
  FROM [dbo].[SBA_HUBZONE_GEOGRAPHY] a,
  [gsa_sam_alaska_coords] b
  where a.coordinates.STContains(b.address_coords) = 1