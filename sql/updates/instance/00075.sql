DROP VIEW organisation_current;
CREATE VIEW organisation_current AS
SELECT
        od.organisation AS id,
        od.id AS detailid,
        o.orgcode,
        od.name,
        c.line_1,
        c.line_2,
        c.line_3,
        c.town,
        c.county,
        c.country,
        c.postcode,
        c.email,
        c.phone,
        c.phonealt,
        c.mobile,
        c.fax,
        od.terms,
        od.billcontact,
        od.is_active,
        od.is_suspended,
        od.is_vatreg,
        od.vatnumber,
        od.updated,
        od.authuser,
        od.clientip
FROM organisationdetail od
INNER JOIN organisation o ON o.id = od.organisation
INNER JOIN contact_current c ON c.id = od.billcontact
WHERE od.id IN (
        SELECT MAX(id)
        FROM organisationdetail
        GROUP BY organisation
);
