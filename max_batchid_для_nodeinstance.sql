SELECT
    ni.batchid,
    ni.elementid,
    ni.endtime
FROM
    nodeinstance ni
INNER JOIN (
    SELECT
        batchid,
        MAX(endtime) as max_endtime
    FROM
        nodeinstance
    WHERE
        batchid IN ('725f531ba2aa4a07beeb496ef74f6d35', '0c0a69997f7344c1a43ee531a4356f2a')
    GROUP BY
        batchid
) grouped_ni ON ni.batchid = grouped_ni.batchid AND ni.endtime = grouped_ni.max_endtime
