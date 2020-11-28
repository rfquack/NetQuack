CREATE EXTERNAL TABLE IF NOT EXISTS \`${DATABASE}\`.\`${TABLE}\`(
  \`timestamp\` string,
  \`latitude\` float,  
  \`longitude\` float,
  \`carrierFreq\` float,  
  \`bitRate\` float,  
  \`modulation\` string,  
  \`syncWords\` string,  
  \`frequencyDeviation\` float,  
  \`RSSI\` float,  
  \`model\` string,  
  \`dongle\` string,  
  \`data\` string)
PARTITIONED BY (\`date\` date)
STORED AS PARQUET
LOCATION 's3://${BUCKET}/'
TBLPROPERTIES (\"parquet.compression\"=\"SNAPPY\");
