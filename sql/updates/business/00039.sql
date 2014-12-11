CREATE OR REPLACE VIEW generalledger_search AS
SELECT
        l.id,
        j.id AS journal,
        j.transactdate as date,
        j.description AS narrative,
        a.description || '(' || l.account || ')' as account,
        l.division, l.department,
        l.debit AS debit,
        l.credit AS credit,
        format_accounting(l.debit) AS fdebit,
        format_accounting(l.credit) AS fcredit
FROM ledger l
INNER JOIN journal j ON j.id = l.journal
INNER JOIN account a ON a.id = l.account
;
