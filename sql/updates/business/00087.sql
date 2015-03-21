CREATE VIEW ageddebtors AS
SELECT
        si.organisation,
        COALESCE(sic.unpaid, '0.00') AS current,
        COALESCE(s30.unpaid, '0.00') AS days30,
        COALESCE(s60.unpaid, '0.00') AS days60,
        COALESCE(s90.unpaid, '0.00') AS days90,
        COALESCE(s120.unpaid, '0.00') AS days120
FROM salesinvoice_unpaid si
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid 
        FROM salesinvoice_unpaid 
        WHERE age <= 0 GROUP BY organisation
) sic ON si.organisation = sic.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid 
        FROM salesinvoice_unpaid 
        WHERE age BETWEEN 1 AND 30
        GROUP BY organisation
) s30 ON si.organisation = s30.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid 
        FROM salesinvoice_unpaid 
        WHERE age BETWEEN 31 AND 60
        GROUP BY organisation
) s60 ON si.organisation = s60.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid 
        FROM salesinvoice_unpaid 
        WHERE age BETWEEN 61 AND 90
        GROUP BY organisation
) s90 ON si.organisation = s90.organisation
LEFT JOIN (
        SELECT organisation, SUM(total) - SUM(paid) AS unpaid 
        FROM salesinvoice_unpaid 
        WHERE age BETWEEN 91 AND 120
        GROUP BY organisation
) s120 ON si.organisation = s120.organisation
GROUP BY si.organisation, sic.unpaid, s30.unpaid, s60.unpaid, s90.unpaid, s120.unpaid
;
