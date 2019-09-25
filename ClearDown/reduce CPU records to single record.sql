--Used to ensure there was some data initially in the powerBI report so refesh once populated show change

DECLARE @records INT
SELECT @records = COUNT(*) FROM  [Reports].[dbo].[CPU_Usage]

DELETE TOP (@records -1)  FROM  [Reports].[dbo].[CPU_Usage]